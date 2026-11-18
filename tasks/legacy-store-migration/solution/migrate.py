#!/usr/bin/env python3
"""Reference migrator: oldbook store directory -> newbook SQLite database.

Usage: python3 /app/migrate.py LEGACY_DIR OUTPUT_DB
MIT License. Copyright (c) 2026 the task author.
"""
import datetime
import hashlib
import os
import sqlite3
import struct
import sys
import zlib

SCHEMA = "/app/newbook/schema.sql"
TABLE = "€çÊÑßñÌÒêÙäéÀÇ£ÕÜþáùËÄüÔæíÆÏûÖÓÚåúôÞóëàÍÝâÁõòìÉîöãøÐÎÈðèÂÿØÅýÃïÛ"
EPOCH = datetime.date(1970, 1, 1)
V2_BASE = (datetime.date(1900, 1, 1) - EPOCH).days
KINDS = {0x11: "person", 0x12: "org", 0x13: "event", 0x14: "recurring", 0x15: "task", 0x16: "note"}
TOMB, BLOB = 0x1D, 0x1B
FREQ = ["daily", "weekly", "monthly", "yearly"]


class Reader:
    def __init__(self, data, pos=0, end=None):
        self.d, self.p = data, pos
        self.end = len(data) if end is None else end

    def uv(self):
        v = sh = 0
        while True:
            if self.p >= self.end:
                raise ValueError("truncated varint")
            b = self.d[self.p]
            self.p += 1
            v |= (b & 0x7F) << sh
            sh += 7
            if not b & 0x80:
                return v

    def take(self, n):
        if self.p + n > self.end:
            raise ValueError("truncated")
        b = self.d[self.p:self.p + n]
        self.p += n
        return b


def unzz(v):
    return (v >> 1) ^ -(v & 1)


def text(b, version):
    if version == 2:
        return b.decode("latin-1")
    out = []
    r = Reader(b)
    while r.p < r.end:
        c = b[r.p]
        r.p += 1
        if c == 0x1E:
            out.append("\n")
        elif c < 0x80:
            out.append(chr(c))
        elif c < 0xC0:
            out.append(TABLE[c - 0x80])
        elif c == 0xC0:
            cp = r.uv()
            out.append(chr(cp) if cp <= 0x10FFFF else "?")
        else:
            out.append("?")
    return "".join(out)


def day_str(d):
    return (EPOCH + datetime.timedelta(days=d)).isoformat()


class Store:
    def __init__(self, path):
        self.files = []
        self.cells = []   # (id, rev, kind, fileinfo, body bytes)
        self.blobs = {}
        self.issues = []
        for name in sorted(n for n in os.listdir(path) if n.endswith(".obk") and len(n) > 4):
            with open(os.path.join(path, name), "rb") as fh:
                self.load(name, fh.read())

    def load(self, name, d):
        if len(d) < 20 or d[:4] != b"OBK\x1a":
            self.issues.append((name, "format"))
            return
        if zlib.crc32(d[:-4]) & 0xFFFFFFFF != struct.unpack_from("<I", d, len(d) - 4)[0]:
            self.issues.append((name, "checksum"))
            return
        ver = d[4]
        free = {}
        if ver == 2:
            info = {"version": 2, "base": V2_BASE, "tz": 0}
            cs, ce = struct.unpack_from("<II", d, 8)
        elif ver == 3 and len(d) >= 28:
            tz, base, fto, cs, ce = struct.unpack_from("<hiIII", d, 6)
            info = {"version": 3, "base": base, "tz": tz if d[5] & 1 else 0}
            if fto:
                r = Reader(d, fto, len(d) - 4)
                for _ in range(r.uv()):
                    o = r.uv()
                    free[o] = r.uv()
        else:
            self.issues.append((name, "format"))
            return
        if cs > len(d) - 4 or ce > len(d) - 4 or cs > ce:
            self.issues.append((name, "format"))
            return
        pos = cs
        while pos < ce:
            if free.get(pos):
                pos += free[pos]
                continue
            kind = d[pos]
            r = Reader(d, pos + 1, ce)
            ln = r.uv()
            body = r.take(ln)
            pos = r.p
            b = Reader(body)
            if kind == BLOB:
                bid = b.uv()
                self.blobs[bid] = body[b.p:]
            elif kind in KINDS or kind == TOMB:
                rid = b.uv()
                rev = b.uv()
                self.cells.append((rid, rev, kind, info, body[b.p:]))


def fields(body):
    r = Reader(body)
    while r.p < r.end:
        key = r.uv()
        fno, wt = key >> 3, key & 7
        if wt in (2, 3, 6):
            yield fno, wt, r.take(r.uv())
        elif wt <= 5:
            yield fno, wt, r.uv()
        else:
            return


def decode(kind, info, body, blobs):
    ver, base = info["version"], info["base"]
    rec = {"tz": info["tz"], "dur": 60, "interval": 1, "emails": [], "refs": [], "exc": [], "atts": [],
           "state": 0}
    for fno, wt, v in fields(body):
        if fno == 7 and wt == 6:
            rec["atts"].append(attachment(v, ver, blobs))
            continue
        t = text(v, ver) if wt == 2 else None
        dv = base + unzz(v) if wt == 4 else None
        if kind == "person":
            if fno == 1 and wt == 2:
                rec["label"] = t
            elif fno == 2 and wt == 2:
                rec["emails"].append(t)
            elif fno == 3 and wt == 2:
                rec["phone"] = t
            elif fno == 4 and wt == 4:
                rec["date"] = dv
            elif fno == 5 and wt == 0:
                rec["ref"] = v
        elif kind == "org":
            if fno == 1 and wt == 2:
                rec["label"] = t
            elif fno == 2 and wt == 2:
                rec["website"] = t
            elif fno == 3 and wt == 2:
                rec["address"] = t
            elif fno == 4 and wt == 0:
                rec["ref"] = v
        elif kind in ("event", "recurring"):
            if fno == 1 and wt == 2:
                rec["label"] = t
            elif fno == 2 and wt == 5:
                rec["sday"] = base + unzz(v >> 11)
                rec["smin"] = v & 0x7FF
            elif fno == 3 and wt == 0:
                rec["dur"] = v
            elif fno == 4 and wt == 1:
                rec["tz"] = unzz(v) * 15
            elif fno == 5 and wt == 2:
                rec["location"] = t
            elif fno == 6 and wt == 0:
                rec["refs"].append(v)
            elif kind == "recurring":
                if fno == 8 and wt == 0:
                    rec["freq"] = v
                elif fno == 9 and wt == 0:
                    rec["interval"] = v or 1
                elif fno == 10 and wt == 0:
                    rec["count"] = v
                elif fno == 11 and wt == 4:
                    rec["until"] = dv
                elif fno == 12 and wt == 4:
                    rec["exc"].append(dv)
        elif kind == "task":
            if fno == 1 and wt == 2:
                rec["label"] = t
            elif fno == 2 and wt == 4:
                rec["date"] = dv
            elif fno == 3 and wt == 0:
                rec["state"] = v
            elif fno == 4 and wt == 0:
                rec["ref"] = v
        elif kind == "note":
            if fno == 1 and wt == 2:
                rec["body"] = t
            elif fno == 2 and wt == 0:
                rec["refs"].append(v)
            elif fno == 3 and wt == 2:
                rec["label"] = t
    return rec


def attachment(body, ver, blobs):
    a = {"fname": None, "mime": None, "flags": 0}
    raw = blob = None
    for fno, wt, v in fields(body):
        if fno == 1 and wt == 2:
            a["fname"] = text(v, ver)
        elif fno == 2 and wt == 2:
            a["mime"] = text(v, ver)
        elif fno == 3 and wt == 3:
            raw = v
        elif fno == 4 and wt == 0:
            blob = v
        elif fno == 5 and wt == 0:
            a["flags"] = v
    data = None
    if raw is not None:
        if a["flags"] & 1:
            data = b"".join(bytes([raw[i + 1]]) * raw[i] for i in range(0, len(raw) - 1, 2))
        else:
            data = bytes(raw)
    elif blob is not None:
        data = blobs.get(blob)
    a["data"] = data
    a["fname"] = a["fname"] if a["fname"] is not None else "(unnamed)"
    a["mime"] = a["mime"] if a["mime"] is not None else "application/octet-stream"
    return a


def main(legacy_dir, out_db):
    st = Store(legacy_dir)
    by_id = {}
    for c in st.cells:
        by_id.setdefault(c[0], []).append(c)
    for v in by_id.values():
        v.sort(key=lambda c: c[1])
    current = {rid: v[-1] for rid, v in by_id.items()}
    live = {rid: c for rid, c in current.items() if c[2] != TOMB}

    if os.path.exists(out_db):
        os.remove(out_db)
    os.makedirs(os.path.dirname(os.path.abspath(out_db)), exist_ok=True)
    db = sqlite3.connect(out_db)
    with open(SCHEMA) as fh:
        db.executescript(fh.read())

    def ref(v):
        return v if v in live else None

    for rid, (_, rev, kc, info, body) in sorted(live.items()):
        kind = KINDS[kc]
        r = decode(kind, info, body, st.blobs)
        db.execute("INSERT INTO records VALUES (?,?,?)", (rid, "event" if kind == "recurring" else kind, rev))
        if kind == "person":
            db.execute("INSERT INTO people VALUES (?,?,?,?,?)",
                       (rid, r.get("label"), r.get("phone"),
                        day_str(r["date"]) if "date" in r else None, ref(r.get("ref"))))
            for i, e in enumerate(r["emails"]):
                db.execute("INSERT INTO person_emails VALUES (?,?,?)", (rid, i, e))
        elif kind == "org":
            db.execute("INSERT INTO orgs VALUES (?,?,?,?,?)",
                       (rid, r.get("label"), r.get("website"), r.get("address"), ref(r.get("ref"))))
        elif kind in ("event", "recurring"):
            start = "%s %02d:%02d" % (day_str(r["sday"]), r["smin"] // 60, r["smin"] % 60)
            rec = kind == "recurring"
            db.execute("INSERT INTO events VALUES (?,?,?,?,?,?,?,?,?,?)",
                       (rid, r.get("label"), start, r["tz"], r["dur"], r.get("location"),
                        FREQ[r["freq"]] if rec else None, r["interval"] if rec else None,
                        r.get("count") if rec else None,
                        day_str(r["until"]) if rec and "until" in r else None))
            if rec:
                for e in sorted(set(r["exc"])):
                    db.execute("INSERT INTO event_exceptions VALUES (?,?)", (rid, day_str(e)))
            for i, p in enumerate(x for x in r["refs"] if x in live):
                db.execute("INSERT INTO event_attendees VALUES (?,?,?)", (rid, i, p))
        elif kind == "task":
            db.execute("INSERT INTO tasks VALUES (?,?,?,?,?,?)",
                       (rid, r.get("label"), day_str(r["date"]) if "date" in r else None,
                        (r["state"] >> 1) & 3, r["state"] & 1, ref(r.get("ref"))))
        elif kind == "note":
            db.execute("INSERT INTO notes VALUES (?,?,?)", (rid, r.get("label"), r.get("body")))
            for i, t in enumerate(x for x in r["refs"] if x in live):
                db.execute("INSERT INTO note_links VALUES (?,?,?)", (rid, i, t))
        for i, a in enumerate(r["atts"]):
            d = a["data"]
            db.execute("INSERT INTO attachments VALUES (?,?,?,?,?,?,?)",
                       (rid, i, a["fname"], a["mime"], len(d) if d is not None else None,
                        hashlib.sha256(d).hexdigest() if d is not None else None, d))

    for rid, cells in by_id.items():
        cur = current[rid]
        for c in cells:
            if c is not cur and c[2] != TOMB:
                db.execute("INSERT INTO history VALUES (?,?)", (rid, c[1]))
        if cur[2] == TOMB:
            prior = [c for c in cells if c[2] != TOMB]
            k = KINDS[prior[-1][2]] if prior else "unknown"
            db.execute("INSERT INTO deleted VALUES (?,?,?)", (rid, "event" if k == "recurring" else k, cur[1]))
    for name, reason in st.issues:
        db.execute("INSERT INTO import_issues VALUES (?,?)", (name, reason))
    db.commit()
    db.close()


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    main(sys.argv[1], sys.argv[2])
