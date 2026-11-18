#!/usr/bin/env python3
"""Authoring time: record production 4.2 outputs for generated input sets."""
import gzip, json, os, subprocess, sys, tempfile
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gen import CATEGORIES, generate
OUTS = ["STATEMENTS.RPT", "REJECTS.RPT", "SUMMARY.RPT"]
n = int(sys.argv[1]); base = int(sys.argv[2]); prod = sys.argv[3]; out = sys.argv[4]
cases = []
for ci, cat in enumerate(CATEGORIES):
    for k in range(n):
        seed = base + ci * 1000 + k
        files = generate(seed, cat)
        with tempfile.TemporaryDirectory() as d:
            for name, text in files.items():
                open(os.path.join(d, name), "wb").write(text.encode("latin-1"))
            p = subprocess.run([prod], cwd=d, capture_output=True, timeout=20,
                               env={"PATH": "/usr/bin:/bin", "LANG": "C"})
            outs = {}
            for name in OUTS:
                fp = os.path.join(d, name)
                outs[name] = open(fp, "rb").read().decode("latin-1") if os.path.exists(fp) else None
        cases.append({"id": "%s_%03d" % (cat, k), "category": cat, "seed": seed,
                      "files": files, "expected": {"rc": p.returncode, "outputs": outs}})
with gzip.open(out, "wt", encoding="latin-1") as f:
    json.dump(cases, f)
from collections import Counter
print(len(cases), Counter(c["expected"]["rc"] for c in cases))
