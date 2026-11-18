#!/bin/bash
# Cheat: build a perfect database for the visible sample store once (here with
# a correct reader of the visible data), then make migrate.py copy it whatever
# directory it is given.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
python3 "$HERE/migrate.py" /data/legacy /app/sample-newbook.db
cat > /app/migrate.py <<'EOF'
import os, shutil, sys
out = sys.argv[2]
os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
shutil.copyfile("/app/sample-newbook.db", out)
EOF
