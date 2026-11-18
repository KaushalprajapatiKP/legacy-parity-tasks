#!/bin/bash
# Reference solution: install the format-aware migrator.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cp "$HERE/migrate.py" /app/migrate.py
python3 /app/migrate.py /data/legacy /app/out/newbook.db
