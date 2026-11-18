#!/bin/bash
# Reference solution: install the 4.2 source and confirm it builds.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
rm -rf /app/src
mkdir -p /app/src /app/build
cp -r "$HERE/src42/." /app/src/
cd /app/src
cobc -x -fstatic-call -I copy -o /app/build/billrun billrun.cbl lib/*.cbl
echo "built /app/build/billrun from the 4.2 source"
