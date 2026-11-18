# Grader for legacy-store-migration. MIT License.
import hashlib
import json
import os
import shutil
import subprocess
import sys

import pytest

sys.path.insert(0, "/tests")
import grade_lib  # noqa: E402

TESTS = "/tests"
STORES = sorted(os.listdir(os.path.join(TESTS, "stores")))
MARK = bytes.fromhex("6f6c64626f6f6b2d73746f72652d7265616465722f376633613931")
SKIP_DIRS = ("/proc", "/sys", "/dev", "/tests", "/logs", "/run")
REPORT = "/logs/verifier/feature_table.txt"
RESULTS = {}


def _purge_legacy_binary():
    """Delete oldbook and every copy of it before any migrator runs."""
    orig = "/app/legacy/oldbook"
    digest = None
    if os.path.isfile(orig):
        with open(orig, "rb") as fh:
            digest = hashlib.sha256(fh.read()).hexdigest()
    removed = []
    for root, dirs, files in os.walk("/", topdown=True):
        if root.startswith(SKIP_DIRS):
            dirs[:] = []
            continue
        dirs[:] = [d for d in dirs if not os.path.join(root, d).startswith(SKIP_DIRS)]
        for f in files:
            p = os.path.join(root, f)
            try:
                if os.path.islink(p) or not os.path.isfile(p) or os.path.getsize(p) > 64 << 20:
                    continue
                with open(p, "rb") as fh:
                    data = fh.read()
            except OSError:
                continue
            if MARK in data or (digest and hashlib.sha256(data).hexdigest() == digest) or p == orig:
                try:
                    os.remove(p)
                    removed.append(p)
                except OSError:
                    pass
    return removed


@pytest.fixture(scope="session", autouse=True)
def purged():
    removed = _purge_legacy_binary()
    print("removed legacy binary copies:", removed)
    assert not os.path.exists("/app/legacy/oldbook")
    return removed


def test_migrator_present():
    assert os.path.isfile("/app/migrate.py"), "/app/migrate.py is missing"


@pytest.mark.parametrize("store", STORES)
def test_store(store):
    work = "/tmp/grade-%s" % store
    shutil.rmtree(work, ignore_errors=True)
    os.makedirs(work)
    legacy = os.path.join(work, "legacy")
    shutil.copytree(os.path.join(TESTS, "stores", store), legacy)
    out = os.path.join(work, "out", "newbook.db")
    try:
        p = subprocess.run([sys.executable, os.path.join(TESTS, "guard.py"), "/app/migrate.py", legacy, out],
                           cwd=work, capture_output=True, text=True, timeout=300)
        log = "exit %d\n%s\n%s" % (p.returncode, p.stdout[-2000:], p.stderr[-3000:])
    except subprocess.TimeoutExpired:
        log = "timeout"
    with open(os.path.join(TESTS, "expected", store + ".json"), encoding="utf-8") as fh:
        expected = json.load(fh)
    res = grade_lib.grade(out, expected)
    RESULTS[store] = res
    allres = [r for v in RESULTS.values() for r in v]
    table = grade_lib.feature_table(allres)
    os.makedirs(os.path.dirname(REPORT), exist_ok=True)
    with open(REPORT, "w") as fh:
        fh.write("stores graded so far: %s\n%s\n" % (sorted(RESULTS), table))
    print(table)
    bad = [r for r in res if not r["ok"]]
    msg = "store %s: %d of %d cases failed\nmigrator: %s\n" % (store, len(bad), len(res), log[:3000])
    msg += "\n".join("  %s: %s" % (r["case"], r["detail"][:300]) for r in bad[:12])
    assert not bad, msg
