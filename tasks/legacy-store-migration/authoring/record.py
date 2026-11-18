#!/usr/bin/env python3
# record.py - authoring-time recorder. Runs the real oldbook binary on a store
# and turns what it prints (list, list --deleted, show, show --history,
# show --attachment, agenda) into the rows newbook's SCHEMA.md asks for.
# MIT License. Copyright (c) 2026 the task author.
#
# usage: record.py OLDBOOK STORE_DIR FEATURES_JSON OUT_JSON
import datetime
import hashlib
import json
import re
import subprocess
import sys

OB = sys.argv[1]
STORE = sys.argv[2]
PRIO = {"none": 0, "low": 1, "normal": 2, "high": 3}
REF_OK = re.compile(r"^(.*) \(#(\d+)\)$")
REF_BAD = re.compile(r"^#(\d+) \(unavailable\)$")
ATT_OK = re.compile(r"^(.*) \((.*), (\d+) bytes, sha256 ([0-9a-f]{64})\)$")
ATT_BAD = re.compile(r"^(.*) \((.*), data unavailable\)$")
WINDOWS = [("2020-01-01", "2030-12-31"), ("2025-03-01", "2025-06-30"), ("2026-01-01", "2026-01-31"),
           ("2027-01-01", "2027-12-31"), ("2026-07-01", "2027-02-28")]


def run(*args, binary=False):
    p = subprocess.run([OB, "-d", STORE] + list(args), capture_output=True)
    if binary:
        return p.returncode, p.stdout
    return p.returncode, p.stdout.decode("utf-8"), p.stderr.decode("utf-8")


def ref_value(v):
    m = REF_BAD.match(v)
    if m:
        return None
    m = REF_OK.match(v)
    assert m, v
    return int(m.group(2))


def parse_show(rid, text):
    lines = text.rstrip("\n").split("\n")
    m = re.match(r"^#(\d+) (\w+) \(rev (\d+)\)$", lines[0])
    assert m and int(m.group(1)) == rid, lines[0]
    kind, rev = m.group(2), int(m.group(3))
    fields = []
    for ln in lines[1:]:
        if ln.startswith("  | "):
            k, v = fields[-1]
            fields[-1] = (k, v + "\n" + ln[4:])
        else:
            k, v = ln.split(": ", 1)
            fields.append((k, v))
    get = lambda k: next((v for kk, v in fields if kk == k), None)  # noqa: E731
    alls = lambda k: [v for kk, v in fields if kk == k]  # noqa: E731
    rows = {t: [] for t in ("records", "people", "person_emails", "orgs", "events", "event_exceptions",
                            "event_attendees", "tasks", "notes", "note_links", "attachments")}
    rows["records"].append([rid, "event" if kind == "recurring" else kind, rev])
    if kind == "person":
        o = get("Org")
        rows["people"].append([rid, get("Name"), get("Phone"), get("Birthday"), ref_value(o) if o else None])
        for i, e in enumerate(alls("Email")):
            rows["person_emails"].append([rid, i, e])
    elif kind == "org":
        p = get("Parent")
        rows["orgs"].append([rid, get("Name"), get("Website"), get("Address"), ref_value(p) if p else None])
    elif kind in ("event", "recurring"):
        s, e = get("Start"), get("End")
        sdt = datetime.datetime.strptime(s[:16], "%Y-%m-%d %H:%M")
        edt = datetime.datetime.strptime(e[:16], "%Y-%m-%d %H:%M")
        off = s[17:]
        assert off == e[17:]
        offmin = (1 if off[0] == "+" else -1) * (int(off[1:3]) * 60 + int(off[4:6]))
        freq = interval = count = until = None
        if kind == "recurring":
            parts = get("Repeats").split(", ")
            freq = parts[0]
            interval = int(parts[1].split()[1])
            for p in parts[2:]:
                if p.endswith(" times"):
                    count = int(p.split()[0])
                elif p.startswith("until "):
                    until = p[6:]
            for d in sorted(set(alls("Except"))):
                rows["event_exceptions"].append([rid, d])
        rows["events"].append([rid, get("Title"), s[:16], offmin, int((edt - sdt).total_seconds() // 60),
                               get("Location"), freq, interval, count, until])
        pos = 0
        for a in alls("Attendee"):
            t = ref_value(a)
            if t is not None:
                rows["event_attendees"].append([rid, pos, t])
                pos += 1
    elif kind == "task":
        p = get("Person")
        rows["tasks"].append([rid, get("Title"), get("Due"), PRIO[get("Priority")],
                              1 if get("Status") == "done" else 0, ref_value(p) if p else None])
    elif kind == "note":
        rows["notes"].append([rid, get("Title"), get("Body")])
        pos = 0
        for a in alls("Link"):
            t = ref_value(a)
            if t is not None:
                rows["note_links"].append([rid, pos, t])
                pos += 1
    for i, a in enumerate(alls("Attachment")):
        m = ATT_OK.match(a)
        if m:
            code, data = run("show", str(rid), "--attachment", str(i + 1), binary=True)
            assert code == 0 and hashlib.sha256(data).hexdigest() == m.group(4) and len(data) == int(m.group(3))
            rows["attachments"].append([rid, i, m.group(1), m.group(2), int(m.group(3)), m.group(4)])
        else:
            m = ATT_BAD.match(a)
            assert m, a
            rows["attachments"].append([rid, i, m.group(1), m.group(2), None, None])
    return rows


def main():
    feats = json.load(open(sys.argv[3]))
    _, out, err = run("list")
    issues = []
    for ln in err.splitlines():
        m = re.match(r"^oldbook: skipping (.*): (.*)$", ln)
        if m:
            issues.append([m.group(1), "checksum" if m.group(2) == "integrity check failed" else "format"])
    live = [int(re.match(r"^#(\d+) ", ln).group(1)) for ln in out.splitlines()]
    _, out, _ = run("list", "--deleted")
    deleted = {}
    for ln in out.splitlines():
        m = re.match(r"^#(\d+) (\w+) deleted at rev (\d+)$", ln)
        deleted[int(m.group(1))] = ["event" if m.group(2) == "recurring" else m.group(2), int(m.group(3))]
    ids = sorted(set(int(k) for k in feats) | set(live) | set(deleted))
    cases = {}
    for rid in ids:
        rows = {"records": [], "people": [], "person_emails": [], "orgs": [], "events": [],
                "event_exceptions": [], "event_attendees": [], "tasks": [], "notes": [], "note_links": [],
                "attachments": []}
        if rid in live:
            _, out, _ = run("show", str(rid))
            rows = parse_show(rid, out)
        rows["deleted"] = [[rid] + deleted[rid]] if rid in deleted else []
        rows["history"] = []
        code, out, _ = run("show", str(rid), "--history")
        if code == 0:
            for ln in out.splitlines()[1:]:
                p = ln.split()
                if "current" not in p and "tombstone" not in p:
                    rows["history"].append([rid, int(p[1])])
        cases[str(rid)] = {"features": feats.get(str(rid), []), "rows": rows}
    agenda = []
    for lo, hi in WINDOWS:
        _, out, _ = run("agenda", lo, hi)
        agenda.append({"from": lo, "to": hi, "lines": out.rstrip("\n").split("\n")})
    with open(sys.argv[4], "w") as fh:
        json.dump({"issues": issues, "cases": cases, "agenda": agenda}, fh, ensure_ascii=False, indent=0)
    _, csv, _ = run("export-csv")
    with open(STORE + "/export.csv", "w") as fh:
        fh.write(csv)
    print("recorded %d ids, %d live, %d deleted, issues %s" % (len(ids), len(live), len(deleted), issues))


main()
