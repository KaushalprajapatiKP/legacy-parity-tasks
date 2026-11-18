#!/bin/sh
# Record production 2.3 output for every deck.  Run inside the task image:
#   record.sh DECKDIR OUTDIR
mkdir -p "$2"
for f in "$1"/*.dat; do
  b=$(basename "$f" .dat)
  /app/prod/hydro < "$f" > "$2/$b.out" 2>/dev/null
  echo $? > "$2/$b.rc"
done
