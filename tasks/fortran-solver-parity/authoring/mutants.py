#!/usr/bin/env python3
"""Mutation check of the hidden suite (authoring aid, runs inside the image).

Each mutant reverts or perturbs ONE 2.3 behaviour in a copy of the 2.3
source.  The suite should reject every mutant (at least one deck differs).
Usage: mutants.py SRC23 TESTSDIR
"""
import json
import os
import shutil
import subprocess
import sys
import tempfile

SRC, TESTS = sys.argv[1], sys.argv[2]
sys.path.insert(0, TESTS)
from compare import compare  # noqa: E402

COLEBROOK = """      X = 1D0/SQRT(0.02D0)
      DO 10 I = 1, 8
         X = -2D0*LOG10(E/3.7D0 + 2.51D0*X/RE)
   10 CONTINUE
      SJF = 1D0/(X*X)
"""

MUTANTS = [
    ("g = 9.81", "hydro.inc", "GRAV=9.80665D0", "GRAV=9.81D0"),
    ("Colebrook instead of Swamee-Jain", "fric.f",
     "      X = LOG10(E/3.7D0 + 5.74D0/RE**0.9D0)\n      SJF = 0.25D0/(X*X)\n", COLEBROOK),
    ("no transition interpolation", "fric.f", "ELSE IF (RE .GE. 4000D0) THEN", "ELSE IF (RE .GE. 2000D0) THEN"),
    ("minor losses ignored", "fric.f", "CM = LKM(K)/(2D0*GRAV*A*A)", "CM = 0D0*LKM(K)"),
    ("kPa factor 9.80665", "network.f", "UP = 9.79D0", "UP = 9.80665D0"),
    ("psi factor 0.433", "network.f", "UP = 0.4335D0", "UP = 0.433D0"),
    ("gpm factor 6.31E-5", "network.f", "UQ = 6.30901964D-5", "UQ = 6.31D-5"),
    ("HW constant 10.67", "fric.f", "R = 10.667D0*LLEN(K)/", "R = 10.67D0*LLEN(K)/"),
    ("nodes in input order", "network.f", "      DO 30 I = 2, NNODE", "      DO 30 I = 2, 1"),
    ("default TOL 1E-6", "hydro.f", "TOL    = 1.0D-5", "TOL    = 1.0D-6"),
    ("default MAXIT 40", "hydro.f", "MAXIT  = 50", "MAXIT  = 40"),
    ("no MAXIT clamp", "input.f", "IF (X .GT. 200D0) THEN", "IF (X .GT. 2000D0) THEN"),
    ("no W209", "input.f", "      IF (NTOK .GT. NMAX)\n", "      IF (NTOK .GT. 99)\n"),
    ("case-sensitive keywords", "input.f", "      CALL UPCASE(KW)\n", "\n"),
    ("no inline comments", "input.f", "      CALL STRIPC(LINE)\n", "\n"),
    ("40-character title", "hydro.inc", "CHARACTER*60 TITLE", "CHARACTER*40 TITLE"),
    ("cold start every step", "hydro.f", "         CALL SETDEM(K)\n", "         CALL SETDEM(K)\n         CALL INITQ\n"),
    ("pump start flow 0.03", "network.f", "Q(K) = 0.5D0*PQM(K)", "Q(K) = 0.03D0"),
    ("signed head loss", "report.f", "HLS = ABS(HEAD(LN1(K)) - HEAD(LN2(K)))/UH", "HLS = (HEAD(LN1(K)) - HEAD(LN2(K)))/UH"),
    ("exit 0 when not converged", "hydro.f", "      IF (NOCONV .GT. 0) STOP 2\n", "\n"),
    ("zero-flow threshold 1E-5", "hydro.inc", "QZERO=1.0D-6", "QZERO=1.0D-5"),
    ("velocity warning at 2.5", "report.f", "IF (ABS(Q(K))/A .GT. 3.0D0)", "IF (ABS(Q(K))/A .GT. 2.5D0)"),
    ("W204 in input order", "network.f", "         I = NORD(J)\n         IF (NISO(I))", "         I = J\n         IF (NISO(I))"),
    ("laminar gradient doubled", "fric.f", "                  G = G + R\n", "                  G = G + 2D0*R\n"),
    ("absolute convergence test", "solver.f", "IF (SDQ .LE. TOL*MAX(SQ, QZERO)) THEN", "IF (SDQ .LE. TOL) THEN"),
    ("no W210", "report.f", "IF (Q(K) .LE. -QZERO) CALL WARNMS", "IF (Q(K) .LE. -1D99) CALL WARNMS"),
]


def main():
    man = json.load(open(os.path.join(TESTS, "manifest.json")))
    exp = {m["name"]: (open(os.path.join(TESTS, "expected", m["name"] + ".out")).read(),
                       int(open(os.path.join(TESTS, "expected", m["name"] + ".rc")).read()))
           for m in man}
    rows = []
    for label, fn, old, new in MUTANTS:
        d = tempfile.mkdtemp()
        for f in os.listdir(SRC):
            shutil.copy(os.path.join(SRC, f), d)
        p = os.path.join(d, fn)
        s = open(p).read()
        assert s.count(old) == 1, (label, s.count(old))
        open(p, "w").write(s.replace(old, new))
        r = subprocess.run("gfortran -O2 -o hydro *.f", shell=True, cwd=d, capture_output=True)
        assert r.returncode == 0, (label, r.stderr)
        bad = {}
        for m in man:
            deck = open(os.path.join(TESTS, "decks", m["name"] + ".dat"), "rb").read()
            r = subprocess.run([os.path.join(d, "hydro")], input=deck, capture_output=True, timeout=20)
            eo, er = exp[m["name"]]
            if compare(eo, r.stdout.decode("latin-1")) is not None or r.returncode != er:
                bad[m["cat"]] = bad.get(m["cat"], 0) + 1
        tot = sum(bad.values())
        rows.append((label, tot, ", ".join(f"{k} {v}" for k, v in sorted(bad.items()))))
        print(f"{label:<34} {tot:4d}  {rows[-1][2]}", flush=True)
    print("mutants caught:", sum(1 for r in rows if r[1] > 0), "of", len(rows))


main()
