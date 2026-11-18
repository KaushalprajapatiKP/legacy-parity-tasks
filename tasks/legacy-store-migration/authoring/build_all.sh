#!/bin/bash
# Authoring pipeline (run on the author's machine, needs Docker). MIT License.
#  1. compile oldbook exactly as environment/Dockerfile does
#  2. generate the visible sample store and the hidden grading stores (seeded)
#  3. record expected rows + export.csv from the real oldbook binary
#  4. cross-check: the reference migrator must pass every recorded case
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
TASK="$(dirname "$HERE")"
WORK="${WORK:-$(mktemp -d)}"
echo "work dir: $WORK"
mkdir -p "$WORK/stores" "$WORK/expected"
cp "$TASK/environment/oldbook-src/oldbook.c" "$WORK/"
docker run --rm -v "$WORK":/w -w /w gcc:12.4.0-bookworm \
  sh -c 'gcc -O2 -static -Wl,--build-id=none -o oldbook oldbook.c && strip oldbook'

gen() { python3 "$HERE/obkgen.py" "$1" "$2" "$3" "$WORK/stores/$1"; }
gen sample 7 110
gen h1 101 150
gen h2 202 140
gen h3 303 160
gen h4 404 150

for s in sample h1 h2 h3 h4; do
  docker run --rm -v "$WORK":/w -v "$HERE":/a:ro -w /w python:3.12-slim-bookworm \
    python3 /a/record.py /w/oldbook /w/stores/$s /w/stores/$s.features.json /w/expected/$s.json
done

# install into the task
rm -rf "$TASK/environment/data/legacy" "$TASK/tests/stores" "$TASK/tests/expected"
mkdir -p "$TASK/environment/data/legacy" "$TASK/tests/stores" "$TASK/tests/expected"
cp "$WORK"/stores/sample/* "$TASK/environment/data/legacy/"
for s in h1 h2 h3 h4; do
  cp -r "$WORK/stores/$s" "$TASK/tests/stores/$s"
  cp "$WORK/expected/$s.json" "$TASK/tests/expected/$s.json"
done

# cross-check with the reference migrator (sample + hidden)
docker run --rm -v "$WORK":/w -v "$TASK":/t:ro -w /w python:3.12-slim-bookworm sh -c '
  mkdir -p /app/newbook && cp /t/environment/app/newbook/* /app/newbook/ &&
  for s in sample h1 h2 h3 h4; do
    python3 /t/solution/migrate.py /w/stores/$s /w/$s.db || exit 1
    python3 - "$s" <<EOF || exit 1
import json, sys
sys.path.insert(0, "/t/tests")
import grade_lib
s = sys.argv[1]
res = grade_lib.grade("/w/%s.db" % s, json.load(open("/w/expected/%s.json" % s)))
bad = [r for r in res if not r["ok"]]
print(s, "cases", len(res), "failed", len(bad))
for r in bad[:10]:
    print("  ", r["case"], r["detail"])
sys.exit(1 if bad else 0)
EOF
  done'
echo "authoring OK"
