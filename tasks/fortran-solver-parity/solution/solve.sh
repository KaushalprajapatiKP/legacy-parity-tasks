#!/bin/bash
# Reference solution: replace the 1.8 source tree with the 2.3 source.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
rm -f /app/src/*.f /app/src/*.inc /app/src/*.INC
cp "$HERE"/src/*.f "$HERE"/src/hydro.inc /app/src/
cd /app/src
gfortran -O2 -o /tmp/hydro-check *.f
/tmp/hydro-check < /app/examples/two-loops.dat > /dev/null
rm -f /tmp/hydro-check
echo "2.3 source installed in /app/src"
