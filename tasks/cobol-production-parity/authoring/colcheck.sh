#!/bin/sh
# report lines longer than 72 columns in COBOL sources
find "$1" \( -name '*.cbl' -o -name '*.cpy' \) | while read f; do awk -v f="$f" 'length($0)>72{print f":"NR": "length($0)}' "$f"; done
