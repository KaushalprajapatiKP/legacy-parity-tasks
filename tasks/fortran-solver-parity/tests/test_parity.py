"""Grader for the HYDRO 2.3 parity task.

1. The production executable is fingerprinted and removed, together with any
   copy of it found on the file system.
2. The Fortran source in /app/src is checked for process-spawning or C
   interoperability features.
3. A fresh copy of /app/src is built with the stated command.
4. Every hidden deck is run through the new build and compared with the
   output and exit status recorded from production 2.3 when the task was
   authored.  A per-category table is printed; every deck must match.
"""
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile

import pytest

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from compare import compare  # noqa: E402

SRC = "/app/src"
PROD = "/app/prod"
DECKS = os.path.join(HERE, "decks")
EXPECTED = os.path.join(HERE, "expected")
SCAN_ROOTS = ["/app", "/tmp", "/root", "/home", "/usr/local", "/opt", "/srv",
              "/var/tmp", "/logs"]

FORBIDDEN = [
    r"EXECUTE_COMMAND_LINE", r"\bSYSTEM\b", r"\bBIND\b", r"ISO_C_BINDING",
    r"\bEXECL\w*", r"\bEXECV\w*", r"\bPOPEN\b", r"\bFORK\b", r"\bDLOPEN\b",
    r"\bDLSYM\b",
]

_state = {}


def _sha(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def _strip_code(line):
    """Return the code part of a source line, without comments or strings."""
    if line[:1] in ("C", "c", "*", "!"):
        return ""
    out, q = [], None
    for ch in line:
        if q:
            if ch == q:
                q = None
            continue
        if ch in ("'", '"'):
            q = ch
            continue
        if ch == "!":
            break
        out.append(ch)
    return "".join(out)


@pytest.fixture(scope="session", autouse=True)
def remove_production():
    """Fingerprint and delete the production build before anything runs."""
    hashes = set()
    if os.path.isdir(PROD):
        for name in os.listdir(PROD):
            p = os.path.join(PROD, name)
            if os.path.isfile(p):
                hashes.add((os.path.getsize(p), _sha(p)))
        shutil.rmtree(PROD, ignore_errors=True)
    copies = []
    sizes = {s for s, _ in hashes}
    for root in SCAN_ROOTS:
        for dp, dns, fns in os.walk(root):
            if dp.startswith("/tests"):
                continue
            for fn in fns:
                p = os.path.join(dp, fn)
                try:
                    if os.path.islink(p) or os.path.getsize(p) not in sizes:
                        continue
                    if any(_sha(p) == h for _, h in hashes):
                        copies.append(p)
                        os.remove(p)
                except OSError:
                    pass
    _state["copies"] = copies
    yield


def test_no_copy_of_production_binary():
    assert not _state["copies"], f"copies of the production binary: {_state['copies']}"


def test_source_has_no_process_or_c_calls():
    bad = []
    for fn in sorted(os.listdir(SRC)):
        p = os.path.join(SRC, fn)
        if not os.path.isfile(p):
            continue
        with open(p, "r", errors="replace") as f:
            for i, line in enumerate(f, 1):
                code = _strip_code(line.rstrip("\n")).upper()
                for pat in FORBIDDEN:
                    if re.search(pat, code):
                        bad.append(f"{fn}:{i}: {line.strip()}")
    assert not bad, "forbidden constructs:\n" + "\n".join(bad[:20])


@pytest.fixture(scope="session")
def built():
    work = tempfile.mkdtemp(prefix="hydro-build-")
    dst = os.path.join(work, "src")
    shutil.copytree(SRC, dst, symlinks=False)
    for fn in os.listdir(dst):
        if not (fn.endswith(".f") or fn.endswith(".inc") or fn.endswith(".INC")):
            p = os.path.join(dst, fn)
            if os.path.isfile(p) or os.path.islink(p):
                os.remove(p)
    r = subprocess.run("gfortran -O2 -o hydro *.f", shell=True, cwd=dst,
                       capture_output=True, text=True, timeout=300)
    exe = os.path.join(dst, "hydro")
    if r.returncode != 0 or not os.path.isfile(exe):
        pytest.fail("build failed:\n" + r.stdout + r.stderr)
    return exe


def test_hidden_decks(built):
    with open(os.path.join(HERE, "manifest.json")) as f:
        manifest = json.load(f)
    table = {}
    failures = []
    for item in manifest:
        name, cat = item["name"], item["cat"]
        with open(os.path.join(DECKS, name + ".dat"), "rb") as f:
            deck = f.read()
        with open(os.path.join(EXPECTED, name + ".out")) as f:
            exp_out = f.read()
        with open(os.path.join(EXPECTED, name + ".rc")) as f:
            exp_rc = int(f.read().strip())
        try:
            r = subprocess.run([built], input=deck, capture_output=True,
                               timeout=20, cwd="/tmp", env={"PATH": "/usr/bin:/bin"})
            out = r.stdout.decode("latin-1")
            rc = r.returncode
            diff = compare(exp_out, out)
            if diff is None and rc != exp_rc:
                diff = f"exit status {rc}, expected {exp_rc}"
        except subprocess.TimeoutExpired:
            diff = "timeout"
        ok, tot = table.get(cat, (0, 0))
        table[cat] = (ok + (diff is None), tot + 1)
        if diff is not None:
            failures.append(f"{name}: {diff}")
    print("\nCATEGORY        PASS / TOTAL")
    tp = tt = 0
    for cat in sorted(table):
        ok, tot = table[cat]
        tp += ok
        tt += tot
        print(f"{cat:<15} {ok:4d} / {tot:4d}")
    print(f"{'ALL':<15} {tp:4d} / {tt:4d}")
    for line in failures[:25]:
        print("  " + line)
    assert not failures, f"{len(failures)} of {tt} decks differ"
