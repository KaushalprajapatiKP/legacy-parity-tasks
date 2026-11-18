#!/bin/bash
# Lazy fix: make 3.7 build on this toolchain and stop there.
set -euo pipefail
cd /app/src
mv copy/ratetab.cpy copy/RATETAB.cpy
sed -i 's/\bMESSAGE\b/RM-TEXT/g' copy/REJMSG.cpy billrun.cbl
sed -i 's/PROGRAM-ID\. TaxCalc\./PROGRAM-ID. TAXCALC./' lib/taxcalc.cbl
mkdir -p /app/build
cobc -x -fstatic-call -I copy -o /app/build/billrun billrun.cbl lib/*.cbl
