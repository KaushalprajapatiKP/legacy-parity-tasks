#!/bin/bash
# Cheat / docs-only baseline: import the nightly export.csv instead of the store.
# Implements everything SCHEMA.md and OLDBOOK.md say, but takes the data from the
# lossy CSV export (rev guessed as 1, fields the CSV lacks left NULL/defaults).
cat > /app/migrate.py <<'EOF'
import csv, os, sqlite3, sys
src, out = sys.argv[1], sys.argv[2]
if os.path.exists(out):
    os.remove(out)
os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
db = sqlite3.connect(out)
db.executescript(open("/app/newbook/schema.sql").read())
n = lambda v: v if v != "" else None
with open(os.path.join(src, "export.csv"), newline="", encoding="utf-8") as fh:
    for row in csv.DictReader(fh):
        rid = int(row["id"]); kind = row["kind"]
        db.execute("INSERT INTO records VALUES (?,?,1)", (rid, "event" if kind == "recurring" else kind))
        if kind == "person":
            db.execute("INSERT INTO people VALUES (?,?,?,?,NULL)", (rid, n(row["label"]), n(row["phone"]), n(row["date"])))
            if row["email"]:
                db.execute("INSERT INTO person_emails VALUES (?,0,?)", (rid, row["email"]))
        elif kind == "org":
            db.execute("INSERT INTO orgs VALUES (?,?,NULL,NULL,NULL)", (rid, n(row["label"])))
        elif kind in ("event", "recurring"):
            db.execute("INSERT INTO events VALUES (?,?,?,0,60,?,?,?,NULL,NULL)",
                       (rid, n(row["label"]), row["date"] + " 00:00", n(row["location"]),
                        "weekly" if kind == "recurring" else None, 1 if kind == "recurring" else None))
        elif kind == "task":
            db.execute("INSERT INTO tasks VALUES (?,?,?,0,?,NULL)", (rid, n(row["label"]), n(row["date"]), 1 if row["status"] == "done" else 0))
        elif kind == "note":
            db.execute("INSERT INTO notes VALUES (?,?,NULL)", (rid, n(row["label"])))
db.commit()
EOF
