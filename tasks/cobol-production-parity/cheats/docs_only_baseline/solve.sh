#!/bin/bash
# Docs-only baseline: 4.2 report layouts, but every rule the release note leaves
# open is filled with the most natural guess (3.7 value or a round number).
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
rm -rf /app/src && mkdir -p /app/src /app/build
cp -r "$HERE/src/." /app/src/
cd /app/src && cobc -x -fstatic-call -I copy -o /app/build/billrun billrun.cbl lib/*.cbl
