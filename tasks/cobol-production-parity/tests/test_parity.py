"""Grader for cobol-production-parity.

Builds /app/src with the documented cobc command, removes the production
binary, then replays hidden input sets recorded from production 4.2 and
compares every output file and the return code byte for byte.
"""
import gzip
import hashlib
import json
import os
import re
import shutil
import subprocess
import tempfile
from collections import OrderedDict
from pathlib import Path

import pytest

HERE = Path(__file__).resolve().parent
SRC = Path("/app/src")
PROD = Path("/app/prod/billrun")
WORK = Path(tempfile.mkdtemp(prefix="grade-"))
BINARY = WORK / "billrun"
OUTPUTS = ["STATEMENTS.RPT", "REJECTS.RPT", "SUMMARY.RPT"]
ALLOWED_FILES = {"CONTROL.DAT", "ACCOUNTS.DAT", "ACTIVITY.DAT",
                 "STATEMENTS.RPT", "REJECTS.RPT", "SUMMARY.RPT"}
CLEAN_ENV = {"PATH": "/usr/bin:/bin", "LANG": "C", "LC_ALL": "C",
             "HOME": str(WORK),
             "COB_RUNTIME_CONFIG": str(HERE / "runtime_clean.cfg")}
SCAN_ROOTS = ["/app", "/tmp", "/root", "/home", "/opt", "/srv", "/usr/local",
              "/var/tmp", "/var/lib", "/etc", "/mnt", "/media"]
TABLE_PATH = Path("/logs/verifier/parity_table.txt")


def _sha(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def _remove_production_binary():
    """Delete /app/prod and any byte-identical copy of the binary."""
    if not PROD.is_file():
        shutil.rmtree("/app/prod", ignore_errors=True)
        return 0
    size = PROD.stat().st_size
    digest = _sha(PROD)
    shutil.rmtree("/app/prod", ignore_errors=True)
    removed = 0
    for root in SCAN_ROOTS:
        for dirpath, dirnames, filenames in os.walk(root, followlinks=False):
            if dirpath.startswith(str(WORK)):
                continue
            for name in filenames:
                p = os.path.join(dirpath, name)
                try:
                    if os.path.islink(p) or not os.path.isfile(p):
                        continue
                    if os.path.getsize(p) != size:
                        continue
                    if _sha(p) == digest:
                        os.remove(p)
                        removed += 1
                except OSError:
                    continue
    return removed


COPIES_REMOVED = _remove_production_binary()


def _strip_cobol(text, free):
    """Drop fixed-format comment lines and inline *> comments.

    Whole lines are kept (no column truncation) so nothing can hide in the
    sequence or indicator areas; free-format files keep every line.
    """
    lines = []
    for line in text.splitlines():
        if not free and len(line) >= 7 and line[6] in "*/":
            continue
        lines.append(re.sub(r"\*>.*$", "", line))
    return "\n".join(lines)


def _sources():
    files = [p for p in SRC.rglob("*") if p.is_file()
             and p.suffix.lower() in (".cbl", ".cob", ".cpy", ".cob85")]
    raw = {p: p.read_text(errors="replace") for p in files}
    free = any(re.search(r">>\s*SOURCE|\$\s*SET", t, re.I) for t in raw.values())
    return {p: _strip_cobol(t, free) for p, t in raw.items()}


def test_01_production_binary_removed():
    assert not Path("/app/prod").exists()
    print("copies of the production binary removed elsewhere:", COPIES_REMOVED)


def test_02_source_guard():
    srcs = _sources()
    assert srcs, "no COBOL sources under /app/src"
    text = "\n".join(srcs.values()).upper()
    program_ids = set(re.findall(r'PROGRAM-ID\.\s*"?([A-Z0-9_-]+)"?', text))
    problems = []
    for m in re.finditer(r"\bCALL\s+(?:STATIC\s+)?(\S+)", text):
        target = m.group(1)
        lit = re.fullmatch(r"[\"']([A-Z0-9_-]+)[\"']\.?", target)
        if not lit:
            problems.append("CALL with non-literal or unusual target: %s" % target)
        elif lit.group(1) not in program_ids:
            problems.append("CALL to a program not defined in /app/src: %s" % lit.group(1))
    for bad in [r"\bTO\s+ENTRY\b", r"\bC\$", r"\bCBL_", r"\bCHAIN\b",
                r"\bEXEC\b", r"\bFUNCTION-POINTER\b", r"\bPROGRAM-POINTER\b",
                r"\bPROCEDURE-POINTER\b", r">>\s*CALL"]:
        if re.search(bad, text):
            problems.append("forbidden construct: %s" % bad)
    for m in re.finditer(r"\bASSIGN\s+(?:TO\s+)?(?:USING\s+)?(\S+)", text):
        target = m.group(1).rstrip(".")
        lit = re.fullmatch(r"[\"']([^\"']+)[\"']", target)
        if not lit or lit.group(1) not in ALLOWED_FILES:
            problems.append("file assignment not allowed: %s" % target)
    assert not problems, "\n".join(problems)


def test_03_toolchain_untouched():
    out = subprocess.run(["dpkg", "-V"], capture_output=True, text=True).stdout
    changed = []
    for line in out.splitlines():
        flags = line[:9]
        if len(flags) == 9 and flags[2] == "5" and " c /" not in line:
            changed.append(line)
    q = subprocess.run(["dpkg-query", "-W", "-f=${Conffiles}\n",
                        "gnucobol3", "libcob4"], capture_output=True,
                       text=True).stdout
    for line in q.splitlines():
        parts = line.split()
        if len(parts) >= 2 and os.path.isfile(parts[0]):
            if hashlib.md5(open(parts[0], "rb").read()).hexdigest() != parts[1]:
                changed.append("conffile " + parts[0])
    assert not changed, "toolchain files modified:\n" + "\n".join(changed)
    assert not Path("/etc/ld.so.preload").exists(), "/etc/ld.so.preload present"
    for tool in ["cobc", "gcc", "as", "ld"]:
        real = os.path.realpath("/usr/bin/" + tool)
        r = subprocess.run(["dpkg", "-S", real], capture_output=True, text=True)
        assert r.returncode == 0, "/usr/bin/%s is not a packaged file" % tool
    for specs in Path("/usr/lib/gcc").glob("*/*/specs"):
        pytest.fail("unexpected gcc specs file: %s" % specs)


def test_04_build():
    lib = sorted(str(p.relative_to(SRC)) for p in (SRC / "lib").glob("*.cbl"))
    cmd = ["/usr/bin/cobc", "-x", "-fstatic-call", "-I", "copy",
           "-o", str(BINARY), "billrun.cbl"] + lib
    r = subprocess.run(cmd, cwd=SRC, capture_output=True, text=True,
                       env=CLEAN_ENV, timeout=600)
    assert r.returncode == 0 and BINARY.is_file(), \
        "build failed:\n" + r.stdout + r.stderr


def _run_case(case):
    d = Path(tempfile.mkdtemp(prefix="case-", dir=WORK))
    try:
        for name, text in case["files"].items():
            (d / name).write_bytes(text.encode("latin-1"))
        try:
            p = subprocess.run([str(BINARY)], cwd=d, capture_output=True,
                               env=CLEAN_ENV, timeout=15)
            rc = p.returncode
        except subprocess.TimeoutExpired:
            rc = "timeout"
        outs = {}
        for name in OUTPUTS:
            fp = d / name
            outs[name] = fp.read_bytes().decode("latin-1") if fp.exists() else None
        return rc, outs
    finally:
        shutil.rmtree(d, ignore_errors=True)


def test_05_parity_with_production():
    assert BINARY.is_file(), "no build"
    cases = json.load(gzip.open(HERE / "cases.json.gz", "rt",
                                encoding="latin-1"))
    per_cat = OrderedDict()
    first_failures = []
    cols = ["rc"] + OUTPUTS
    for case in cases:
        rc, outs = _run_case(case)
        exp = case["expected"]
        hits = {"rc": rc == exp["rc"]}
        for name in OUTPUTS:
            hits[name] = outs[name] == exp["outputs"][name]
        row = per_cat.setdefault(case["category"],
                                 {"total": 0, "pass": 0, **{c: 0 for c in cols}})
        row["total"] += 1
        row["pass"] += all(hits.values())
        for c in cols:
            row[c] += hits[c]
        if not all(hits.values()) and len(first_failures) < 15:
            first_failures.append("%s: %s" % (case["id"], ", ".join(
                c for c in cols if not hits[c])))
    fmt = "%-14s %5s %5s | %5s %10s %8s %8s"
    lines = [fmt % ("category", "pass", "total", "rc", "STATEMENTS", "REJECTS",
                    "SUMMARY")]
    tot = {"total": 0, "pass": 0, **{c: 0 for c in cols}}
    for cat, row in per_cat.items():
        lines.append(fmt % (cat, row["pass"], row["total"], row["rc"],
                            row["STATEMENTS.RPT"], row["REJECTS.RPT"],
                            row["SUMMARY.RPT"]))
        for k in tot:
            tot[k] += row[k]
    lines.append(fmt % ("ALL", tot["pass"], tot["total"], tot["rc"],
                        tot["STATEMENTS.RPT"], tot["REJECTS.RPT"],
                        tot["SUMMARY.RPT"]))
    all_ok, all_tot = tot["pass"], tot["total"]
    table = "\n".join(lines)
    print("\n" + table)
    try:
        TABLE_PATH.parent.mkdir(parents=True, exist_ok=True)
        TABLE_PATH.write_text(table + "\n")
    except OSError:
        pass
    assert all_ok == all_tot, ("%d of %d input sets differ from production. "
                               "First failures:\n%s" % (all_tot - all_ok,
                                                       all_tot,
                                                       "\n".join(first_failures)))
