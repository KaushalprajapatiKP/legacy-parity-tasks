# Grading helpers for legacy-store-migration. MIT License.
import hashlib
import json
import os
import sqlite3
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import newbook_ref  # noqa: E402  (grader-owned copy of /app/newbook/newbook.py)

ID_COL = {"records": "id", "people": "id", "person_emails": "person_id", "orgs": "id", "events": "id",
          "event_exceptions": "event_id", "event_attendees": "event_id", "tasks": "id", "notes": "id",
          "note_links": "note_id", "attachments": "owner_id", "history": "record_id",
          "deleted": "record_id"}
COLUMNS = {
    "records": ["id", "kind", "rev"],
    "people": ["id", "name", "phone", "birthday", "org_id"],
    "person_emails": ["person_id", "pos", "email"],
    "orgs": ["id", "name", "website", "address", "parent_id"],
    "events": ["id", "title", "start_local", "utc_offset_min", "duration_min", "location", "freq",
               "interval", "count", "until"],
    "event_exceptions": ["event_id", "date"],
    "event_attendees": ["event_id", "pos", "person_id"],
    "tasks": ["id", "title", "due", "priority", "done", "person_id"],
    "notes": ["id", "title", "body"],
    "note_links": ["note_id", "pos", "target_id"],
    "attachments": ["owner_id", "pos", "filename", "mime", "size", "sha256"],
    "history": ["record_id", "rev"],
    "deleted": ["record_id", "kind", "rev"],
    "import_issues": ["file", "reason"],
}


def _norm(v):
    if isinstance(v, bytes):
        return "<bytes>"
    if isinstance(v, float) and v.is_integer():
        return int(v)
    return v


def load_db(path):
    """Return ({table: {id: [rows]}}, problems)."""
    problems = []
    conn = sqlite3.connect("file:%s?mode=ro" % path, uri=True)
    have = {r[0] for r in conn.execute("SELECT name FROM sqlite_master WHERE type='table'")}
    out = {}
    for t, cols in COLUMNS.items():
        if t not in have:
            problems.append("missing table %s" % t)
            out[t] = {}
            continue
        names = [r[1] for r in conn.execute("PRAGMA table_info(%s)" % t)]
        miss = [c for c in cols if c not in names]
        if miss:
            problems.append("table %s lacks columns %s" % (t, miss))
            out[t] = {}
            continue
        sel = list(cols) + (["data"] if t == "attachments" and "data" in names else [])
        rows = conn.execute("SELECT %s FROM %s" % (", ".join('"%s"' % c for c in sel), t)).fetchall()
        grouped = {}
        for row in rows:
            row = list(row)
            if t == "attachments":
                data = row.pop() if len(row) > len(cols) else None
                if data is None:
                    if row[5] is not None or row[4] is not None:
                        row[5] = "<sha256 set but data NULL>"
                else:
                    if isinstance(data, str):
                        data = data.encode("utf-8", "surrogateescape")
                    if hashlib.sha256(bytes(data)).hexdigest() != row[5] or len(data) != row[4]:
                        row[5] = "<data does not match size/sha256: %s>" % hashlib.sha256(bytes(data)).hexdigest()
            key = row[0] if t != "import_issues" else 0
            grouped.setdefault(key, []).append([_norm(v) for v in row])
        out[t] = grouped
    return out, problems, conn


def _key(row):
    return json.dumps(row, sort_keys=True, ensure_ascii=False)


def grade(db_path, expected):
    """Return a list of case results: dict(case, features, ok, detail)."""
    results = []
    if not os.path.exists(db_path):
        for cid, case in expected["cases"].items():
            results.append({"case": "record #" + cid, "features": case["features"], "ok": False,
                            "detail": "no database produced"})
        results.append({"case": "import_issues", "features": ["checksum_skipped_file"], "ok": False,
                        "detail": "no database"})
        for w in expected["agenda"]:
            results.append({"case": "agenda %s..%s" % (w["from"], w["to"]), "features": ["agenda"],
                            "ok": False, "detail": "no database"})
        return results
    db, problems, conn = load_db(db_path)
    results.append({"case": "schema", "features": ["schema"], "ok": not problems, "detail": "; ".join(problems)})
    for cid, case in expected["cases"].items():
        rid = int(cid)
        bad = []
        for t, exp_rows in case["rows"].items():
            got = sorted((_key(r) for r in db.get(t, {}).get(rid, [])))
            exp = sorted(_key(r) for r in exp_rows)
            if got != exp:
                bad.append("%s: expected %s got %s" % (t, exp, got))
        results.append({"case": "record #" + cid, "features": case["features"] or ["other"], "ok": not bad,
                        "detail": " | ".join(bad)[:600]})
    known = {int(c) for c in expected["cases"]}
    extra = sorted({i for t in ID_COL for i in db.get(t, {}) if i not in known})
    results.append({"case": "no unexpected records", "features": ["free_list_ghost", "checksum_skipped_file"],
                    "ok": not extra, "detail": "unexpected ids %s" % extra[:20] if extra else ""})
    got = sorted(_key(r) for r in db.get("import_issues", {}).get(0, []))
    exp = sorted(_key(r) for r in expected["issues"])
    results.append({"case": "import_issues", "features": ["checksum_skipped_file"], "ok": got == exp,
                    "detail": "" if got == exp else "expected %s got %s" % (exp, got)})
    for w in expected["agenda"]:
        try:
            lines = newbook_ref.agenda_lines(conn, w["from"], w["to"])
            ok = lines == w["lines"]
            detail = ""
            if not ok:
                diff = [x for x in w["lines"] if x not in lines][:3] + ["--extra:"] + \
                    [x for x in lines if x not in w["lines"]][:3]
                detail = "; ".join(diff)
        except Exception as e:  # noqa: BLE001
            ok, detail = False, "agenda failed: %r" % (e,)
        results.append({"case": "agenda %s..%s" % (w["from"], w["to"]), "features": ["agenda"], "ok": ok,
                        "detail": detail[:600]})
    return results


def feature_table(all_results):
    stats = {}
    for r in all_results:
        for f in r["features"]:
            s = stats.setdefault(f, [0, 0])
            s[1] += 1
            s[0] += 1 if r["ok"] else 0
    lines = ["%-32s %7s %7s" % ("feature", "passed", "total")]
    for f in sorted(stats):
        lines.append("%-32s %7d %7d" % (f, stats[f][0], stats[f][1]))
    npass = sum(1 for r in all_results if r["ok"])
    lines.append("%-32s %7d %7d" % ("ALL CASES", npass, len(all_results)))
    return "\n".join(lines)
