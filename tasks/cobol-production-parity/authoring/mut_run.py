#!/usr/bin/env python3
"""Inside container: build reference + each mutant, report killed cases per mutant."""
import json, os, shutil, subprocess, sys, tempfile
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from mutants import M
cases = json.load(open(sys.argv[1]))
src = sys.argv[2]
only = sys.argv[3:]  # optional mutant names
OUTS = ["STATEMENTS.RPT", "REJECTS.RPT", "SUMMARY.RPT"]
def build(tree, out):
    r = subprocess.run("cobc -x -fstatic-call -I copy -o %s billrun.cbl lib/*.cbl" % out, shell=True, cwd=tree, capture_output=True, text=True)
    return r.returncode == 0, r.stderr
def run(binary):
    res = {}
    for c in cases:
        with tempfile.TemporaryDirectory() as d:
            for n, t in c["files"].items():
                open(os.path.join(d, n), "w").write(t)
            p = subprocess.run([binary], cwd=d, capture_output=True, timeout=20)
            outs = tuple(open(os.path.join(d, n), "rb").read() if os.path.exists(os.path.join(d, n)) else None for n in OUTS)
            res[c["id"]] = (p.returncode, outs)
    return res
ok, err = build(src, "/tmp/ref"); assert ok, err
ref = run("/tmp/ref")
for name, f, old, new in M:
    if only and name not in only: continue
    t = "/tmp/mut"; shutil.rmtree(t, ignore_errors=True); shutil.copytree(src, t)
    p = os.path.join(t, f); s = open(p).read()
    if s.count(old) != 1:
        print("%-32s BAD-PATCH count=%d" % (name, s.count(old))); continue
    open(p, "w").write(s.replace(old, new))
    ok, err = build(t, "/tmp/mbin")
    if not ok:
        print("%-32s BUILD-FAIL %s" % (name, err[:300])); continue
    res = run("/tmp/mbin")
    killed = [k for k in ref if res[k] != ref[k]]
    cats = {}
    for k in killed: cats[k.rsplit("_",1)[0]] = cats.get(k.rsplit("_",1)[0],0)+1
    print("%-32s killed %3d/%d  %s" % (name, len(killed), len(ref), dict(sorted(cats.items()))), flush=True)
