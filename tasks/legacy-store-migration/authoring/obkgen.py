#!/usr/bin/env python3
# obkgen.py - authoring-time generator of oldbook stores.
# MIT License. Copyright (c) 2026 the task author.
#
# Writes a directory of *.obk files from a seeded random content model plus
# features.json (which legacy features each record id exercises). The grader
# never uses this file; expected rows are recorded from the oldbook binary.
import datetime
import json
import os
import random
import struct
import sys
import unicodedata
import zlib

TABLE = "€çÊÑßñÌÒêÙäéÀÇ£ÕÜþáùËÄüÔæíÆÏûÖÓÚåúôÞóëàÍÝâÁõòìÉîöãøÐÎÈðèÂÿØÅýÃïÛ"
assert len(TABLE) == 64
KIND_CODE = {"person": 0x11, "org": 0x12, "event": 0x13, "recurring": 0x14,
             "task": 0x15, "note": 0x16}
TOMB, BLOB = 0x1D, 0x1B
WT_UV, WT_SV, WT_TEXT, WT_BYTES, WT_DATE, WT_DT, WT_MSG = range(7)
EPOCH = datetime.date(1970, 1, 1)
V2_BASE = (datetime.date(1900, 1, 1) - EPOCH).days


def days(d):
    return (d - EPOCH).days


def uv(n):
    assert n >= 0
    out = bytearray()
    while True:
        b = n & 0x7F
        n >>= 7
        if n:
            out.append(b | 0x80)
        else:
            out.append(b)
            return bytes(out)


def zz(n):
    return n << 1 if n >= 0 else ((-n) << 1) - 1


def sv(n):
    return uv(zz(n))


def enc_text(s, version):
    out = bytearray()
    for ch in s:
        o = ord(ch)
        if version == 2:
            assert o <= 0xFF, s
            out.append(o)
        elif ch == "\n":
            out.append(0x1E)
        elif o < 0x80:
            out.append(o)
        elif ch in TABLE:
            out.append(0x80 + TABLE.index(ch))
        else:
            out.append(0xC0)
            out += uv(o)
    return bytes(out)


def rle(data):
    out = bytearray()
    i = 0
    while i < len(data):
        j = i
        while j < len(data) and data[j] == data[i] and j - i < 255:
            j += 1
        out += bytes([j - i, data[i]])
        i = j
    return bytes(out)


# ---------------------------------------------------------------- text pools
FIRST = ["Anna", "Bruno", "Carla", "Dmitri", "Elena", "Farid", "Greta", "Hugo",
         "Ines", "Jonas", "Karin", "Lars", "Mia", "Nils", "Olga", "Pablo",
         "Rosa", "Sven", "Tomas", "Ulla", "Victor", "Wanda", "Yusuf", "Zoe",
         "Celine", "Andre", "Renee", "Noel", "Aurelie", "Joao", "Agnes"]
LAST = ["Andersen", "Becker", "Costa", "Dupont", "Eriksen", "Fischer", "Garcia",
        "Hansen", "Ibarra", "Jensen", "Keller", "Lopez", "Moreau", "Nunez",
        "Olsen", "Petit", "Quiroga", "Rossi", "Schmidt", "Torres", "Ulrich",
        "Vidal", "Weber", "Yilmaz", "Zeller", "Muller", "Gomez", "Lefevre"]
RARE_LATIN1 = ["Straße", "Þórshöfn", "Ðakovo", "Ærø", "Øresund", "Æsir", "Þóra",
               "Ýmir", "Ðuro", "Søren", "smørrebrød", "þorp", "Ìschia", "Ùrsula",
               "Ãngela", "Ëlise", "Ïsolde", "Ûrsine", "Ìñigo", "Ålesund"]
ESCAPES = ["Łukasz", "Žižek", "Dvořák", "Erdős", "山田", "東京", "Ωmega", "🎉",
           "→", "Ğül", "Čapek", "Œuvre", "Ελλάδα", "🚀", "Ä‰"]
ORG_WORDS = ["Acme", "Nordlicht", "Bureau", "Atelier", "Konsult", "Logistik",
             "Studio", "Garten", "Kaffee", "Verlag", "Mobilite", "Societe"]
ORG_SUFFIX = ["GmbH", "AB", "SARL", "Ltd", "Oy", "AS", "S.L.", "Inc"]
TITLES = ["Standup", "Review", "Lunch with client", "Board meeting", "Dentist",
          "Yoga", "Quarterly planning", "Call supplier", "Team retro",
          "Kickoff", "Budget sync", "Visit to factory", "Book club", "Interview"]
TASKS = ["Send invoice", "Renew passport", "Order toner", "Call back",
         "Update CRM", "Pay rent", "File taxes", "Fix bike", "Buy gift",
         "Write report", "Book flights", "Clean inbox"]
STREETS = ["Hauptstraße", "Rue de la Paix", "Calle Mayor", "Storgatan",
           "Via Roma", "Main Street", "Kungsgatan", "Bahnhofstraße"]
CITIES = ["Zürich", "Göteborg", "Málaga", "Kraków", "Århus", "Reykjavík",
          "Genève", "Lisboa", "Köln", "São Paulo", "Montréal", "Oslo"]
NOTE_LINES = ["Discussed the renewal terms.", "Follow up next week.",
              "Prefers email over phone.", "Allergic to nuts.",
              "Price agreed: €40 per unit, £35 in UK.", "Met at the conference.",
              "Needs the signed copy.", "Café meeting went well.",
              "Remember the déjà vu story.", "Owes us 3 boxes."]
LOCATIONS = ["Room 4", "HQ lobby", "Café Central", "Online", "Conference room B",
             "Biergarten", "Hôtel de Ville", "Building 7"]
MIMES = [("photo.png", "image/png"), ("scan.pdf", "application/pdf"),
         ("notes.txt", "text/plain"), ("avatar.jpg", "image/jpeg"),
         ("agenda.pdf", "application/pdf"), ("map.gif", "image/gif")]

ACCENTS = {}
for ch in TABLE:
    base = unicodedata.normalize("NFD", ch)[0]
    if base != ch and base.isalpha():
        ACCENTS.setdefault(base, []).append(ch)


class Gen:
    def __init__(self, seed, n_records, profile):
        self.r = random.Random(seed)
        self.seed = seed
        self.n = n_records
        self.profile = profile

    # ------------------------------------------------------------ text helpers
    def accent(self, word, latin1, p=0.12):
        r = self.r
        out = []
        for ch in word:
            opts = [c for c in ACCENTS.get(ch, []) if not latin1 or ord(c) <= 0xFF]
            if opts and r.random() < p:
                out.append(r.choice(opts))
            else:
                out.append(ch)
        return "".join(out)

    def word_extra(self, latin1):
        r = self.r
        x = r.random()
        if x < 0.12:
            return r.choice(RARE_LATIN1)
        if x < 0.2 and not latin1:
            return r.choice(ESCAPES)
        return None

    def person_name(self, latin1):
        r = self.r
        f = self.accent(r.choice(FIRST), latin1)
        last = self.accent(r.choice(LAST), latin1)
        ex = self.word_extra(latin1)
        if ex and r.random() < 0.5:
            last = ex
        return f + " " + last

    def org_name(self, latin1):
        r = self.r
        w = self.accent(r.choice(ORG_WORDS), latin1, 0.3)
        ex = self.word_extra(latin1)
        if ex:
            w = w + " " + ex
        return w + " " + r.choice(ORG_SUFFIX)

    def free_line(self, latin1):
        r = self.r
        s = r.choice(NOTE_LINES)
        if latin1:
            s = s.replace("€", "EUR")
        ex = self.word_extra(latin1)
        if ex:
            s = s + " " + ex
        return self.accent(s, latin1, 0.05)

    def text_title(self, pool, latin1):
        s = self.accent(self.r.choice(pool), latin1, 0.15)
        ex = self.word_extra(latin1)
        if ex and self.r.random() < 0.6:
            s += " " + ex
        return s

    def email(self, name):
        base = "".join(c for c in unicodedata.normalize("NFD", name.split()[0].lower())
                       if c.isascii() and c.isalpha()) or "user"
        dom = self.r.choice(["example.com", "mail.example.org", "corp.example.net"])
        return "%s.%d@%s" % (base, self.r.randint(1, 99), dom)

    def date_between(self, a, b):
        return EPOCH + datetime.timedelta(days=self.r.randint(days(a), days(b)))

    # --------------------------------------------------------- content builders
    def make_att(self):
        r = self.r
        fname, mime = r.choice(MIMES)
        mode = r.choices(["raw", "rle", "blob"], [4, 3, 4])[0]
        if mode == "blob":
            bid = r.choice(self.blob_ids)
            return {"fname": fname, "mime": mime, "mode": "blob", "blob": bid}
        return {"fname": fname, "mime": mime, "mode": mode, "data": self.rand_data()}

    def rand_data(self):
        r = self.r
        out = bytearray()
        target = r.randint(24, 420)
        while len(out) < target:
            if r.random() < 0.5:
                out += bytes([r.randrange(256)]) * r.randint(2, 40)
            else:
                out += bytes(r.randrange(256) for _ in range(r.randint(1, 12)))
        return bytes(out[:target])

    def content(self, kind, latin1):
        r = self.r
        c = {}
        if kind == "person":
            c["name"] = self.person_name(latin1)
            c["emails"] = [self.email(c["name"]) for _ in range(r.choices([0, 1, 2, 3], [2, 5, 3, 1])[0])]
            if r.random() < 0.7:
                c["phone"] = "+%d %d %04d %04d" % (r.choice([1, 33, 44, 46, 49, 91]),
                                                   r.randint(10, 99), r.randint(0, 9999), r.randint(0, 9999))
            if r.random() < 0.6:
                c["birthday"] = self.date_between(datetime.date(1940, 1, 1), datetime.date(2006, 12, 31))
            if r.random() < 0.55:
                c["org"] = "REF:org"
            c["atts"] = [self.make_att() for _ in range(r.choices([0, 1, 2], [7, 2, 1])[0])]
        elif kind == "org":
            c["name"] = self.org_name(latin1)
            if r.random() < 0.6:
                c["website"] = "https://www.%s.example" % r.choice(ORG_WORDS).lower()
            if r.random() < 0.6:
                lines = ["%s %d" % (self.accent(r.choice(STREETS), latin1, 0.1), r.randint(1, 200)),
                         "%05d %s" % (r.randint(1000, 99999), r.choice([c2 for c2 in CITIES if not latin1 or all(ord(x) <= 255 for x in c2)]))]
                if r.random() < 0.4:
                    lines.insert(1, "Floor %d" % r.randint(1, 30))
                c["address"] = "\n".join(lines)
            if r.random() < 0.3:
                c["parent"] = "REF:org"
        elif kind in ("event", "recurring"):
            if r.random() < 0.95:
                c["title"] = self.text_title(TITLES, latin1)
            d = self.date_between(datetime.date(2024, 9, 1), datetime.date(2027, 3, 1))
            if kind == "recurring" and r.random() < 0.25:
                for dd in r.sample([29, 30, 31], 3):
                    try:
                        d = d.replace(day=dd)
                        break
                    except ValueError:
                        pass
                if r.random() < 0.3:
                    d = datetime.date(2024, 2, 29)
            c["start"] = (d, r.randrange(0, 1440, 5))
            if r.random() < 0.7:
                c["dur"] = r.choice([0, 15, 30, 45, 60, 90, 120, 240, 600])
            if r.random() < 0.65:
                c["tz"] = r.choice([0, 60, 120, -300, -240, 330, 345, -210, 540, -600, 600, 525])
            if r.random() < 0.6:
                c["location"] = self.accent(r.choice(LOCATIONS), latin1, 0.1)
            c["attendees"] = ["REF:person"] * r.choices([0, 1, 2, 3, 4], [3, 3, 3, 2, 1])[0]
            c["atts"] = [self.make_att() for _ in range(r.choices([0, 1], [8, 2])[0])]
            if kind == "recurring":
                c["freq"] = r.choice([0, 1, 1, 2, 2, 3])
                if r.random() < 0.55:
                    c["interval"] = r.choice([1, 1, 2, 3])
                x = r.random()
                if x < 0.4:
                    c["count"] = r.randint(2, 14)
                elif x < 0.8:
                    c["until"] = d + datetime.timedelta(days=r.randint(20, 900))
                elif x < 0.9:
                    c["count"] = r.randint(2, 14)
                    c["until"] = d + datetime.timedelta(days=r.randint(20, 500))
                c["exc"] = []
                for _ in range(r.choices([0, 1, 2, 3], [3, 3, 2, 1])[0]):
                    occ = self.some_occurrence(c)
                    if occ and occ not in c["exc"]:
                        c["exc"].append(occ)
        elif kind == "task":
            c["title"] = self.text_title(TASKS, latin1)
            if r.random() < 0.7:
                c["due"] = self.date_between(datetime.date(2023, 1, 1), datetime.date(2027, 12, 31))
            if r.random() < 0.8:
                c["state"] = (r.random() < 0.35) | (r.randint(0, 3) << 1)
            if r.random() < 0.4:
                c["person"] = "REF:person"
        elif kind == "note":
            if r.random() < 0.6:
                c["title"] = self.text_title(["Call notes", "Ideas", "Meeting notes", "Reminder", "Gift list"], latin1)
            if r.random() < 0.92 or "title" not in c:
                c["body"] = "\n".join(self.free_line(latin1) for _ in range(r.choices([1, 2, 3, 4], [3, 3, 2, 1])[0]))
            c["links"] = ["REF:any"] * r.choices([0, 1, 2, 3], [3, 3, 2, 1])[0]
            c["atts"] = [self.make_att() for _ in range(r.choices([0, 1, 2], [5, 3, 1])[0])]
        return c

    def some_occurrence(self, c):
        d0 = c["start"][0]
        iv = c.get("interval", 1)
        k = self.r.randint(1, 6)
        f = c["freq"]
        try:
            if f == 0:
                d = d0 + datetime.timedelta(days=k * iv)
            elif f == 1:
                d = d0 + datetime.timedelta(days=7 * k * iv)
            elif f == 2:
                m = d0.month - 1 + k * iv
                d = d0.replace(year=d0.year + m // 12, month=m % 12 + 1)
            else:
                d = d0.replace(year=d0.year + k * iv)
        except ValueError:
            return None
        return d

    # ------------------------------------------------------------------ build
    def build(self):
        r = self.r
        prof = self.profile
        files = []
        for fs in prof["files"]:
            f = dict(fs)
            f.setdefault("corrupt", False)
            if f["version"] == 3:
                f["base_day"] = r.randint(days(datetime.date(2008, 1, 1)), days(datetime.date(2021, 1, 1)))
                ff = r.random() < 0.5
                f["free_first"] = fs.get("free_first", ff)
            else:
                f["base_day"] = V2_BASE
            files.append(f)
        self.files = files
        good = [f for f in files if not f["corrupt"]]
        v3good = [f for f in good if f["version"] == 3]
        v2files = [f for f in good if f["version"] == 2]
        corrupt = [f for f in files if f["corrupt"]]

        self.blob_ids = r.sample(range(1, 900), prof.get("blobs", 8))
        ids = r.sample(range(1, 5000), self.n)
        kinds = r.choices(list(KIND_CODE), [5, 2, 3, 2, 3, 3], k=self.n)
        # make sure every kind occurs
        for i, k in enumerate(KIND_CODE):
            kinds[i] = k
        self.cells = []
        self.recs = {}
        for rid, kind in zip(ids, kinds):
            nrev = r.choices([1, 2, 3, 4], [5, 3, 2, 1])[0]
            revs = []
            rv = r.randint(1, 3)
            for i in range(nrev):
                final = i == nrev - 1
                if v2files and r.random() < (0.08 if final else 0.35):
                    f = r.choice(v2files)
                else:
                    f = r.choice(v3good)
                revs.append(rv)
                self.cells.append({"type": "rec", "id": rid, "rev": rv, "kind": kind,
                                   "file": f["name"], "c": self.content(kind, f["version"] == 2),
                                   "free": False})
                rv += r.randint(1, 4)
            self.recs[rid] = {"kind": kind, "next": rv}
        rec_ids = list(self.recs)
        # tombstones and resurrections
        for rid in r.sample(rec_ids, max(3, self.n // 10)):
            rv = self.recs[rid]["next"]
            f = r.choice(good)
            self.cells.append({"type": "tomb", "id": rid, "rev": rv, "file": f["name"], "free": False})
            rv += r.randint(1, 3)
            if r.random() < 0.35:
                f = r.choice(v3good)
                self.cells.append({"type": "rec", "id": rid, "rev": rv, "kind": self.recs[rid]["kind"],
                                   "file": f["name"], "c": self.content(self.recs[rid]["kind"], False),
                                   "free": False})
                rv += r.randint(1, 3)
            self.recs[rid]["next"] = rv
        # corrupt file: shadows, a tombstone, records only there
        self.corrupt_only = []
        if corrupt:
            cf = corrupt[0]
            for rid in r.sample(rec_ids, 6):
                rv = self.recs[rid]["next"]
                self.cells.append({"type": "rec", "id": rid, "rev": rv, "kind": self.recs[rid]["kind"],
                                   "file": cf["name"], "c": self.content(self.recs[rid]["kind"], False),
                                   "free": False})
                self.recs[rid]["next"] = rv + 1
            rid = r.choice(rec_ids)
            self.cells.append({"type": "tomb", "id": rid, "rev": self.recs[rid]["next"],
                               "file": cf["name"], "free": False})
            self.recs[rid]["next"] += 1
            for _ in range(2):
                rid = r.choice([i for i in range(5000, 6000) if i not in self.recs])
                kind = r.choice(["person", "org"])
                self.recs[rid] = {"kind": kind, "next": 3}
                self.corrupt_only.append(rid)
                self.cells.append({"type": "rec", "id": rid, "rev": 2, "kind": kind, "file": cf["name"],
                                   "c": self.content(kind, False), "free": False})
        # ghosts in free extents
        for rid in r.sample(rec_ids, prof.get("ghosts", 6)):
            f = r.choice(v3good)
            rv = self.recs[rid]["next"] + r.randint(0, 2)
            self.recs[rid]["next"] = rv + 1
            if r.random() < 0.2:
                self.cells.append({"type": "tomb", "id": rid, "rev": rv, "file": f["name"], "free": True})
            else:
                self.cells.append({"type": "rec", "id": rid, "rev": rv, "kind": self.recs[rid]["kind"],
                                   "file": f["name"], "c": self.content(self.recs[rid]["kind"], False),
                                   "free": True})
        for _ in range(prof.get("junk", 3)):
            f = r.choice(v3good)
            self.cells.append({"type": "junk", "file": f["name"], "free": True,
                               "data": bytes(r.randrange(256) for _ in range(r.randint(5, 60)))})
        # blobs
        self.blobs = {}
        for i, bid in enumerate(self.blob_ids):
            f = corrupt[0] if (corrupt and i == 0) else r.choice(good)
            data = self.rand_data()
            self.blobs[bid] = data
            self.cells.append({"type": "blob", "bid": bid, "data": data, "file": f["name"], "free": False})
        # make sure the corrupt-file blob is referenced by a live record
        if corrupt:
            for cell in sorted(self.live_view().values(), key=lambda c: c["id"]):
                if cell["type"] == "rec" and cell["kind"] in ("person", "note"):
                    cell["c"].setdefault("atts", []).append(
                        {"fname": "lost.bin", "mime": "application/octet-stream", "mode": "blob",
                         "blob": self.blob_ids[0]})
                    break
        # unknown fields
        for cell in self.cells:
            if cell["type"] == "rec":
                cell["unknown"] = r.random() < 0.25
        self.resolve_refs()
        if prof.get("cover_table"):
            self.cover_table()
        return self

    def files_by(self, name):
        return [f for f in self.files if f["name"] == name][0]

    def live_view(self):
        """Current state as oldbook will see it: (id -> winning cell or None)."""
        best = {}
        for c in self.cells:
            if c["type"] not in ("rec", "tomb") or c["free"] or self.files_by(c["file"])["corrupt"]:
                continue
            b = best.get(c["id"])
            if b is None or c["rev"] > b["rev"]:
                best[c["id"]] = c
        return best

    def resolve_refs(self):
        r = self.r
        best = self.live_view()
        live = {i: c for i, c in best.items() if c["type"] == "rec"}
        by_kind = {}
        for i, c in live.items():
            by_kind.setdefault("event" if c["kind"] == "recurring" else c["kind"], []).append(i)
        dead = [i for i, c in best.items() if c["type"] == "tomb"] + self.corrupt_only + \
            [r.randint(6000, 9000) for _ in range(5)]

        def pick(kind):
            if r.random() < 0.15:
                return r.choice(dead)
            if kind == "any":
                return r.choice(list(live))
            pool = by_kind.get(kind) or list(live)
            return r.choice(pool)

        for c in self.cells:
            if c["type"] != "rec":
                continue
            cc = c["c"]
            for k in ("org", "parent", "person"):
                if isinstance(cc.get(k), str):
                    cc[k] = pick(cc[k].split(":")[1])
            for k in ("attendees", "links"):
                if k in cc:
                    cc[k] = [pick(x.split(":")[1]) for x in cc[k]]

    def cover_table(self):
        best = self.live_view()
        seen = set()
        notes = []
        for c in best.values():
            if c["type"] != "rec":
                continue
            if c["kind"] == "note" and self.files_by(c["file"])["version"] == 3:
                notes.append(c)
            for v in c["c"].values():
                if isinstance(v, str):
                    seen.update(v)
                elif isinstance(v, list):
                    for x in v:
                        if isinstance(x, str):
                            seen.update(x)
        missing = [ch for ch in TABLE if ch not in seen]
        for i in range(0, len(missing), 4):
            n = self.r.choice(notes)
            chunk = "".join(missing[i:i + 4])
            n["c"]["body"] = (n["c"].get("body", "") + "\nSpelling check: " + chunk).lstrip("\n")

    # --------------------------------------------------------------- encoding
    def enc_fields(self, c, kind, f, unknown):
        ver = f["version"]
        base = f["base_day"]
        items = []

        def key(fno, wt):
            return uv(fno << 3 | wt)

        def T(fno, s):
            b = enc_text(s, ver)
            items.append((fno, key(fno, WT_TEXT) + uv(len(b)) + b))

        def U(fno, n):
            items.append((fno, key(fno, WT_UV) + uv(n)))

        def S(fno, n):
            items.append((fno, key(fno, WT_SV) + sv(n)))

        def D(fno, d):
            items.append((fno, key(fno, WT_DATE) + sv(days(d) - base)))

        def DT(fno, d, minute):
            items.append((fno, key(fno, WT_DT) + uv(zz(days(d) - base) << 11 | minute)))

        def att(fno, a):
            sub = []
            b = enc_text(a["fname"], ver)
            sub.append(key(1, WT_TEXT) + uv(len(b)) + b)
            b = enc_text(a["mime"], ver)
            sub.append(key(2, WT_TEXT) + uv(len(b)) + b)
            if a["mode"] == "blob":
                sub.append(key(4, WT_UV) + uv(a["blob"]))
            elif a["mode"] == "rle":
                d = rle(a["data"])
                sub.append(key(5, WT_UV) + uv(1))
                sub.append(key(3, WT_BYTES) + uv(len(d)) + d)
            else:
                if self.r.random() < 0.3:
                    sub.append(key(5, WT_UV) + uv(0))
                sub.append(key(3, WT_BYTES) + uv(len(a["data"])) + a["data"])
            if self.r.random() < 0.2:
                sub.append(key(9, WT_UV) + uv(self.r.randint(0, 999)))
            self.r.shuffle(sub)
            body = b"".join(sub)
            items.append((fno, key(fno, WT_MSG) + uv(len(body)) + body))

        if kind == "person":
            T(1, c["name"])
            for e in c["emails"]:
                T(2, e)
            if "phone" in c:
                T(3, c["phone"])
            if "birthday" in c:
                D(4, c["birthday"])
            if "org" in c:
                U(5, c["org"])
        elif kind == "org":
            T(1, c["name"])
            if "website" in c:
                T(2, c["website"])
            if "address" in c:
                T(3, c["address"])
            if "parent" in c:
                U(4, c["parent"])
        elif kind in ("event", "recurring"):
            if "title" in c:
                T(1, c["title"])
            DT(2, *c["start"])
            if "dur" in c:
                U(3, c["dur"])
            if "tz" in c:
                S(4, c["tz"] // 15)
            if "location" in c:
                T(5, c["location"])
            for a in c["attendees"]:
                U(6, a)
            if kind == "recurring":
                U(8, c["freq"])
                if "interval" in c:
                    U(9, c["interval"])
                if "count" in c:
                    U(10, c["count"])
                if "until" in c:
                    D(11, c["until"])
                for e in c["exc"]:
                    D(12, e)
        elif kind == "task":
            T(1, c["title"])
            if "due" in c:
                D(2, c["due"])
            if "state" in c:
                U(3, c["state"])
            if "person" in c:
                U(4, c["person"])
        elif kind == "note":
            if "body" in c:
                T(1, c["body"])
            for l in c["links"]:
                U(2, l)
            if "title" in c:
                T(3, c["title"])
        for a in c.get("atts", []):
            att(7, a)
        if unknown:
            for _ in range(self.r.randint(1, 2)):
                fno = self.r.randint(13, 15)
                wt = self.r.choice([WT_UV, WT_SV, WT_TEXT, WT_BYTES, WT_DATE, WT_DT])
                if wt in (WT_TEXT, WT_BYTES):
                    payload = bytes(self.r.randrange(256) for _ in range(self.r.randint(0, 9)))
                    items.append((fno, key(fno, wt) + uv(len(payload)) + payload))
                else:
                    items.append((fno, key(fno, wt) + uv(self.r.randrange(1 << self.r.choice([5, 12, 30])))))
        # random interleave keeping the order of repeated fields
        ks = [self.r.random() for _ in items]
        groups = {}
        for i, (fno, _) in enumerate(items):
            groups.setdefault(fno, []).append(i)
        order = [None] * len(items)
        for fno, idxs in groups.items():
            sk = sorted(ks[i] for i in idxs)
            for i, k in zip(idxs, sk):
                order[i] = k
        items = [b for _, (_, b) in sorted(zip(order, items), key=lambda t: t[0])]
        return b"".join(items)

    def enc_cell(self, cell, f):
        t = cell["type"]
        if t == "junk":
            return cell["data"]
        if t == "blob":
            body = uv(cell["bid"]) + cell["data"]
            return bytes([BLOB]) + uv(len(body)) + body
        if t == "tomb":
            body = uv(cell["id"]) + uv(cell["rev"])
            return bytes([TOMB]) + uv(len(body)) + body
        body = uv(cell["id"]) + uv(cell["rev"]) + self.enc_fields(cell["c"], cell["kind"], f, cell.get("unknown"))
        return bytes([KIND_CODE[cell["kind"]]]) + uv(len(body)) + body

    def write(self, outdir):
        os.makedirs(outdir, exist_ok=True)
        for f in self.files:
            mine = [c for c in self.cells if c["file"] == f["name"]]
            self.r.shuffle(mine)
            blobs = [self.enc_cell(c, f) for c in mine]
            if f["version"] == 2:
                hdr_len = 16
                body = b"".join(blobs)
                hdr = b"OBK\x1a" + bytes([2, 0]) + b"\0\0" + struct.pack("<II", hdr_len, hdr_len + len(body))
                data = hdr + body
            else:
                hdr_len = 24
                extents_rel = []
                pos = 0
                for c, b in zip(mine, blobs):
                    if c["free"]:
                        extents_rel.append((pos, len(b)))
                    pos += len(b)
                body = b"".join(blobs)

                def ftab(start):
                    t = uv(len(extents_rel))
                    for o, l in extents_rel:
                        t += uv(start + o) + uv(l)
                    return t
                if not extents_rel:
                    cs = hdr_len
                    tail = b""
                    fto = 0
                elif f["free_first"]:
                    # table length depends on offsets; iterate to a fixed point
                    tl = 0
                    while True:
                        t = ftab(hdr_len + tl)
                        if len(t) == tl:
                            break
                        tl = len(t)
                    fto = hdr_len
                    cs = hdr_len + tl
                    body = t + body
                    tail = b""
                else:
                    cs = hdr_len
                    fto = hdr_len + len(body)
                    tail = ftab(cs)
                flags = 1 if f.get("tz") is not None else 0
                tzv = f.get("tz") or 0
                hdr = b"OBK\x1a" + bytes([3, flags]) + struct.pack("<hiIII", tzv, f["base_day"], fto, cs,
                                                                     cs + len(body) - (cs - hdr_len))
                data = hdr + body + tail
            crc = zlib.crc32(data) & 0xFFFFFFFF
            if f["corrupt"]:
                crc ^= 0x5A5A0001
            data += struct.pack("<I", crc)
            with open(os.path.join(outdir, f["name"]), "wb") as fh:
                fh.write(data)
        self.write_features(outdir)

    def write_features(self, outdir):
        best = self.live_view()
        feats = {}

        def add(i, t):
            feats.setdefault(str(i), set()).add(t)
        for c in self.cells:
            if c["type"] not in ("rec", "tomb"):
                continue
            i = c["id"]
            add(i, "kind_" + self.recs[i]["kind"])
            if c["free"]:
                add(i, "free_list_ghost")
            if self.files_by(c["file"])["corrupt"]:
                add(i, "checksum_skipped_file")
        for i, b in best.items():
            revs = [c for c in self.cells if c.get("id") == i and c["type"] == "rec" and not c["free"]
                    and not self.files_by(c["file"])["corrupt"]]
            if len(revs) > 1:
                add(i, "revisions_latest_wins")
                if len({c["file"] for c in revs}) > 1:
                    add(i, "revisions_across_files")
            if b["type"] == "tomb":
                add(i, "tombstone")
                continue
            if any(c["type"] == "tomb" and not c["free"] and not self.files_by(c["file"])["corrupt"]
                   for c in self.cells if c.get("id") == i):
                add(i, "resurrected")
            f = self.files_by(b["file"])
            cc = b["c"]
            if f["version"] == 2:
                add(i, "v2_file")
            if b.get("unknown"):
                add(i, "unknown_fields")
            txt = "".join(v for v in cc.values() if isinstance(v, str)) + \
                "".join(x for v in cc.values() if isinstance(v, list) for x in v if isinstance(x, str))
            if any(ch in TABLE for ch in txt) and f["version"] == 3:
                add(i, "text_table_chars")
            if any(ord(ch) > 0x7F and ch not in TABLE for ch in txt):
                add(i, "text_escaped_codepoints")
            if any(ord(ch) > 0x7F for ch in txt) and f["version"] == 2:
                add(i, "text_v2_latin1")
            if "\n" in txt:
                add(i, "text_multiline")
            for k in ("birthday", "due", "start", "until"):
                if k in cc:
                    add(i, "dates_packed")
            if b["kind"] in ("event", "recurring"):
                if "tz" not in cc:
                    add(i, "tz_file_default")
                else:
                    add(i, "tz_explicit")
                if "dur" not in cc:
                    add(i, "duration_default")
            if b["kind"] == "recurring":
                add(i, "recurrence_rule")
                if cc["exc"]:
                    add(i, "recurrence_exceptions")
            if b["kind"] == "task":
                add(i, "task_state_bits")
            refs = [cc[k] for k in ("org", "parent", "person") if k in cc] + cc.get("attendees", []) + cc.get("links", [])
            if refs:
                add(i, "cross_references")
            if any(r not in best or best[r]["type"] == "tomb" for r in refs):
                add(i, "dangling_references")
            for a in cc.get("atts", []):
                add(i, "attachment_" + a["mode"])
                if a["mode"] == "blob":
                    bc = [c for c in self.cells if c["type"] == "blob" and c["bid"] == a["blob"]][0]
                    if self.files_by(bc["file"])["corrupt"]:
                        add(i, "attachment_blob_unavailable")
            if b["kind"] == "person" and len(cc["emails"]) > 1:
                add(i, "multi_value_order")
        with open(os.path.join(outdir, "..", os.path.basename(outdir) + ".features.json"), "w") as fh:
            json.dump({k: sorted(v) for k, v in sorted(feats.items(), key=lambda t: int(t[0]))}, fh, indent=0)


PROFILES = {
    "sample": {"files": [{"name": "archive-2019.obk", "version": 2},
                         {"name": "book.obk", "version": 3, "tz": 60},
                         {"name": "calendar.obk", "version": 3, "tz": -300},
                         {"name": "sync-0007.obk", "version": 3, "free_first": True},
                         {"name": "sync-0008.obk", "version": 3, "tz": 120, "corrupt": True}],
               "cover_table": True},
    "h1": {"files": [{"name": "old-2018.obk", "version": 2},
                     {"name": "contacts.obk", "version": 3, "tz": 330},
                     {"name": "events.obk", "version": 3},
                     {"name": "sync-0101.obk", "version": 3, "tz": -240},
                     {"name": "sync-0102.obk", "version": 3, "corrupt": True}]},
    "h2": {"files": [{"name": "a.obk", "version": 3, "tz": -600},
                     {"name": "b.obk", "version": 2},
                     {"name": "c.obk", "version": 3, "corrupt": True},
                     {"name": "d.obk", "version": 3, "tz": 345}], "ghosts": 9, "junk": 4},
    "h3": {"files": [{"name": "legacy.obk", "version": 2},
                     {"name": "legacy-2.obk", "version": 2},
                     {"name": "main.obk", "version": 3, "tz": 0},
                     {"name": "zz-journal.obk", "version": 3, "tz": 540},
                     {"name": "aa-broken.obk", "version": 3, "tz": 60, "corrupt": True}], "blobs": 12},
    "h4": {"files": [{"name": "store.obk", "version": 3, "tz": -210},
                     {"name": "store-old.obk", "version": 2},
                     {"name": "store-sync.obk", "version": 3},
                     {"name": "store-sync2.obk", "version": 3, "tz": 525, "corrupt": True}], "ghosts": 8},
}

if __name__ == "__main__":
    name, seed, n, outdir = sys.argv[1], int(sys.argv[2]), int(sys.argv[3]), sys.argv[4]
    g = Gen(seed, n, PROFILES[name]).build()
    g.write(outdir)
