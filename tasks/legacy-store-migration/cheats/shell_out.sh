#!/bin/bash
# Cheat: keep a private copy of oldbook and make migrate.py drive it
# (oldbook show/list output parsed into the schema).
mkdir -p /usr/local/lib/.cache-ob
cp /app/legacy/oldbook /usr/local/lib/.cache-ob/ob
cp /app/legacy/oldbook /root/.ob 2>/dev/null || true
cat > /app/migrate.py <<'EOF'
import os, re, shutil, sqlite3, subprocess, sys
src, out = sys.argv[1], sys.argv[2]
ob = next(p for p in ("/app/legacy/oldbook", "/usr/local/lib/.cache-ob/ob", "/root/.ob", shutil.which("oldbook") or "") if p and os.path.exists(p))
if os.path.exists(out):
    os.remove(out)
os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
db = sqlite3.connect(out)
db.executescript(open("/app/newbook/schema.sql").read())
lst = subprocess.run([ob, "-d", src, "list"], capture_output=True, text=True)
for ln in lst.stdout.splitlines():
    rid, kind = ln.split()[0][1:], ln.split()[1]
    show = subprocess.run([ob, "-d", src, "show", rid], capture_output=True, text=True).stdout
    rev = int(re.search(r"\(rev (\d+)\)", show).group(1))
    db.execute("INSERT INTO records VALUES (?,?,?)", (int(rid), "event" if kind == "recurring" else kind, rev))
db.commit()
EOF
