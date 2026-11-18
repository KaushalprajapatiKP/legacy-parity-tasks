#!/usr/bin/env python3
# newbook - the replacement contacts and calendar tool (read-only viewer).
# MIT License. Copyright (c) 2026 the task author.
"""Usage:
    newbook.py DB list
    newbook.py DB show ID
    newbook.py DB agenda FROM TO      (dates YYYY-MM-DD, inclusive)
"""
import calendar
import datetime
import sqlite3
import sys

FREQS = {"daily": 0, "weekly": 1, "monthly": 2, "yearly": 3}


def _d(s):
    return datetime.date.fromisoformat(s)


def occurrences(start, freq, interval, count, until, exceptions, lo, hi):
    """Local dates on which an event starting on `start` occurs within [lo, hi].

    Candidates that do not exist (the 31st in a short month, 29 February in a
    common year) are skipped and not counted. `count` limits the number of
    candidates generated; excepted dates are counted but not returned.
    """
    if freq is None:
        return [start] if lo <= start <= hi else []
    f = FREQS[freq]
    out = []
    n = 0
    for k in range(200000):
        step = k * interval
        if f == 0:
            day = start + datetime.timedelta(days=step)
        elif f == 1:
            day = start + datetime.timedelta(days=7 * step)
        elif f == 2:
            mi = start.month - 1 + step
            y, m = start.year + mi // 12, mi % 12 + 1
            if start.day > calendar.monthrange(y, m)[1]:
                continue
            day = datetime.date(y, m, start.day)
        else:
            y = start.year + step
            if start.day > calendar.monthrange(y, start.month)[1]:
                continue
            day = datetime.date(y, start.month, start.day)
        if until is not None and day > until:
            break
        if day > hi:
            break
        n += 1
        if count is not None and n > count:
            break
        if day in exceptions:
            continue
        if day >= lo:
            out.append(day)
    return out


def agenda_lines(conn, lo, hi):
    lo, hi = _d(lo), _d(hi)
    occ = []
    rows = conn.execute("SELECT id, title, start_local, utc_offset_min, duration_min, freq, interval, count, until "
                        "FROM events").fetchall()
    for (eid, title, start, off, dur, freq, interval, count, until) in rows:
        sd = _d(start[:10])
        hh, mm = int(start[11:13]), int(start[14:16])
        exc = {_d(r[0]) for r in conn.execute("SELECT date FROM event_exceptions WHERE event_id=?", (eid,))}
        for day in occurrences(sd, freq, interval or 1, count, _d(until) if until else None, exc, lo, hi):
            utc = (day.toordinal() * 1440) + hh * 60 + mm - off
            sign = "-" if off < 0 else "+"
            a = abs(off)
            line = "%s %02d:%02d %s%02d:%02d  #%d %s (%d min)" % (
                day.isoformat(), hh, mm, sign, a // 60, a % 60, eid, title if title is not None else "(untitled)", dur)
            occ.append((utc, eid, line))
    occ.sort()
    return [o[2] for o in occ] or ["nothing scheduled"]


def show(conn, rid):
    rec = conn.execute("SELECT kind, rev FROM records WHERE id=?", (rid,)).fetchone()
    if not rec:
        d = conn.execute("SELECT kind, rev FROM deleted WHERE record_id=?", (rid,)).fetchone()
        print("record %d %s" % (rid, "was deleted at revision %d" % d[1] if d else "not found"))
        return
    kind, rev = rec
    print("[%s %d, revision %d]" % (kind, rid, rev))
    table = {"person": "people", "org": "orgs", "event": "events", "task": "tasks", "note": "notes"}[kind]
    cur = conn.execute("SELECT * FROM %s WHERE id=?" % table, (rid,))
    names = [c[0] for c in cur.description]
    for k, v in zip(names, cur.fetchone() or []):
        if k != "id" and v is not None:
            print("  %-15s %s" % (k, str(v).replace("\n", "\n" + " " * 18)))
    for q, label in (("SELECT email FROM person_emails WHERE person_id=? ORDER BY pos", "email"),
                     ("SELECT person_id FROM event_attendees WHERE event_id=? ORDER BY pos", "attendee"),
                     ("SELECT date FROM event_exceptions WHERE event_id=? ORDER BY date", "except"),
                     ("SELECT target_id FROM note_links WHERE note_id=? ORDER BY pos", "link"),
                     ("SELECT filename || ' ' || mime || ' ' || coalesce(size, '?') FROM attachments "
                      "WHERE owner_id=? ORDER BY pos", "attachment")):
        for (v,) in conn.execute(q, (rid,)):
            print("  %-15s %s" % (label, v))


def main(argv):
    if len(argv) < 3:
        print(__doc__)
        return 2
    conn = sqlite3.connect("file:%s?mode=ro" % argv[1], uri=True)
    cmd = argv[2]
    if cmd == "list":
        for rid, kind in conn.execute("SELECT id, kind FROM records ORDER BY id"):
            print("%d %s" % (rid, kind))
    elif cmd == "show" and len(argv) > 3:
        show(conn, int(argv[3]))
    elif cmd == "agenda" and len(argv) > 4:
        print("\n".join(agenda_lines(conn, argv[3], argv[4])))
    else:
        print(__doc__)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
