#!/usr/bin/env python3
"""Seeded input-set generator for the billrun parity suite (authoring time only)."""
import datetime as dt
import json
import random
import sys

CATEGORIES = ["basic", "tiers", "rounding", "proration", "discounts",
              "acct_rejects", "act_rejects", "dates", "signs", "ordering",
              "charges", "mixed"]

NAMES = ["ADAMS", "BAKER", "CHEN", "DIAZ", "EVANS", "FOX", "GARCIA", "HILL",
         "IYER", "JONES", "KHAN", "LOPEZ", "MILLER", "NOVAK", "OKAFOR", "PATEL",
         "QUINN", "ROSSI", "SATO", "TAYLOR", "URBAN", "VARGA", "WONG", "YOUNG"]
FIRST = ["ANA", "BEN", "CARL", "DORA", "ELI", "FAY", "GUS", "HANA", "IVY",
         "JON", "KIM", "LEO", "MIA", "NED", "OLA", "PIA", "RAJ", "SUE"]
REGIONS = ["NE", "SW", "MW", "SE", "NW", "CE"]
CH_CODES = ["EQUP", "INST", "LATE", "DEPO", "MISC"]
CH_DESC = {"EQUP": ["HANDSET", "ROUTER", "SIM KIT", "CHARGER"],
           "INST": ["INSTALL VISIT", "SETUP", "TECH CALLOUT"],
           "LATE": ["LATE PAYMENT FEE", "LATE FEE"],
           "DEPO": ["SECURITY DEPOSIT", "DEPOSIT"],
           "MISC": ["PAPER BILL", "NUMBER CHANGE", "GOODWILL CREDIT", ""]}
AD_DESC = ["BILLING CORRECTION", "SERVICE OUTAGE", "GOODWILL", "REBATE", ""]


def d2s(d):
    return d.strftime("%Y%m%d")


def amt(v, sign=None):
    """Signed amount field: sign + 9 digits (7.2 implied)."""
    cents = int(round(v * 100))
    s = sign if sign is not None else ("-" if cents < 0 else "+")
    return s + "%09d" % abs(cents)


def qty(v):
    return "%09d" % int(round(v * 100))


def pad(s, n):
    return (s + " " * n)[:n]


def ctl(start, end, run, company):
    return pad(start, 8) + pad(end, 8) + pad(run, 6) + pad(company, 30)


def acct(aid, name, plan, open_, close, tax, region, bal, loy):
    return (pad(aid, 8) + pad(name, 24) + pad(plan, 1) + pad(open_, 8) +
            pad(close, 8) + pad(tax, 1) + pad(region, 2) + pad(bal, 10) +
            pad(loy, 2))


def act(typ, aid, date, data):
    return pad(typ, 2) + pad(aid, 8) + pad(date, 8) + data


def us(aid, date, svc, q):
    return act("US", aid, date, pad(svc, 4) + q)


def ch(aid, date, code, a, desc):
    return act("CH", aid, date, pad(code, 4) + a + pad(desc, 20))


def py(aid, date, a):
    return act("PY", aid, date, "CARD" + a)


def ad(aid, date, a, desc):
    return act("AD", aid, date, "    " + a + pad(desc, 20))


def pc(aid, date, plan):
    return act("PC", aid, date, plan)


def ds(aid, date, kind, a):
    return act("DS", aid, date, kind + "   " + a)


def su(aid, date, end):
    return act("SU", aid, date, end)


class Gen:
    def __init__(self, seed, cat):
        self.r = random.Random(seed)
        self.cat = cat
        self.ids = set()

    # ---------------------------------------------------------------- cycle
    def cycle(self):
        r = self.r
        if self.cat == "dates":
            choice = r.choice(["feb_leap", "feb_noleap", "m30", "m31", "mid",
                               "y2000", "y1900", "short", "dec"])
        else:
            choice = r.choice(["m31", "m30", "feb_leap", "feb_noleap", "mid"])
        y = r.choice([2023, 2024, 2025, 2026])
        if choice == "feb_leap":
            y = r.choice([2024, 2028, 2000])
            s, e = dt.date(y, 2, 1), dt.date(y, 2, 29)
        elif choice == "feb_noleap":
            y = r.choice([2023, 2025, 2026])
            s, e = dt.date(y, 2, 1), dt.date(y, 2, 28)
        elif choice == "y2000":
            s, e = dt.date(2000, 2, 1), dt.date(2000, 2, 29)
        elif choice == "y1900":
            s, e = dt.date(2100, 2, 1), dt.date(2100, 2, 28)
        elif choice == "m30":
            m = r.choice([4, 6, 9, 11])
            s, e = dt.date(y, m, 1), dt.date(y, m, 30)
        elif choice == "m31":
            m = r.choice([1, 3, 5, 7, 8, 10, 12])
            s, e = dt.date(y, m, 1), dt.date(y, m, 31)
        elif choice == "dec":
            s, e = dt.date(y, 12, 15), dt.date(y + 1, 1, 14)
        elif choice == "short":
            s = dt.date(y, r.randint(1, 12), r.randint(1, 10))
            e = s + dt.timedelta(days=r.randint(0, 13))
        else:
            s = dt.date(y, r.randint(1, 12), r.randint(2, 28))
            e = s + dt.timedelta(days=r.randint(27, 30))
        return s, e

    def new_id(self):
        while True:
            aid = "%s%06d" % (self.r.choice(["AC", "BX", "CM", "AC"]),
                              self.r.randint(1, 999999))
            if aid not in self.ids:
                self.ids.add(aid)
                return aid

    def name(self):
        return "%s %s" % (self.r.choice(FIRST), self.r.choice(NAMES))

    def day_in(self, s, e):
        return s + dt.timedelta(days=self.r.randint(0, (e - s).days))

    # ---------------------------------------------------------------- build
    def build(self):
        r = self.r
        cat = self.cat
        s, e = self.cycle()
        run = "%06d" % r.randint(1, 999999)
        company = r.choice(["NORTHWIND TELECOM", "LAKESIDE MOBILE CO",
                            "PINE VALLEY COMMS", "HARBOR WIRELESS"])
        control = ctl(d2s(s), d2s(e), run, company)
        if cat == "dates" and r.random() < 0.3:
            control = self.bad_control(s, e, run, company)
        nacct = r.randint(2, 7) if cat != "ordering" else r.randint(5, 12)
        accounts, actlines, live = [], [], []
        for _ in range(nacct):
            a = self.make_account(s, e)
            accounts.append(a[0])
            if a[1]:
                live.append(a[1])
        if cat == "acct_rejects":
            for _ in range(r.randint(2, 6)):
                accounts.insert(r.randint(0, len(accounts)),
                                self.bad_account(s, e, live))
        if cat == "ordering" or r.random() < 0.3:
            r.shuffle(accounts)
        for info in live:
            actlines.extend(self.activity_for(info, s, e))
        if cat == "act_rejects" or (cat in ("dates", "mixed") and r.random() < 0.6):
            for _ in range(r.randint(3, 9)):
                actlines.append(self.bad_activity(s, e, live))
        if cat in ("ordering", "mixed") or r.random() < 0.5:
            r.shuffle(actlines)
        if live and r.random() < (0.5 if cat in ("act_rejects", "mixed") else 0.1):
            dup = r.choice(actlines) if actlines else None
            if dup:
                actlines.insert(r.randint(0, len(actlines)), dup)
        if r.random() < 0.15:
            actlines = [x.rstrip() for x in actlines]
        return {"CONTROL.DAT": control + "\n",
                "ACCOUNTS.DAT": "".join(x + "\n" for x in accounts),
                "ACTIVITY.DAT": "".join(x + "\n" for x in actlines)}

    def bad_control(self, s, e, run, company):
        r = self.r
        k = r.choice(["feb29", "rev", "long", "long", "nonnum", "badday",
                      "y1899", "long32"])
        if k == "long32":
            return ctl(d2s(s), d2s(s + dt.timedelta(days=r.choice([31, 33, 40]))), run, company)
        if k == "feb29":
            return ctl("20230201", "20230229", run, company)
        if k == "rev":
            return ctl(d2s(e), d2s(s - dt.timedelta(days=1)), run, company)
        if k == "long":
            return ctl(d2s(s), d2s(s + dt.timedelta(days=31)), run, company)
        if k == "nonnum":
            return ctl("2024-3-1", d2s(e), run, company)
        if k == "badday":
            return ctl(d2s(s), "%04d0431" % e.year, run, company)
        return ctl("18990201", "18990228", run, company)

    def make_account(self, s, e):
        r = self.r
        cat = self.cat
        aid = self.new_id()
        plan = r.choice("BSP")
        tax = r.choice("NNNRE")
        region = r.choice(REGIONS)
        loy = r.choice(["  ", "  ", "L1", "L2", "L3"] if cat != "discounts"
                       else ["L1", "L2", "L3", "  ", "L4", "X1"])
        bal = r.choice([0, 0, r.randint(1, 50000) / 100.0,
                        -r.randint(1, 20000) / 100.0])
        if cat == "signs":
            bal = r.choice([-r.randint(1, 99999) / 100.0, r.randint(0, 9999) / 100.0, 0.0])
        bal_s = amt(bal)
        open_ = s - dt.timedelta(days=r.randint(30, 900))
        close = None
        if cat in ("proration", "mixed", "dates") or r.random() < 0.15:
            k = r.random()
            if k < 0.3:
                open_ = self.day_in(s, e)
            elif k < 0.5:
                close = self.day_in(s, e)
            elif k < 0.6:
                open_ = self.day_in(s, e)
                close = open_ + dt.timedelta(days=r.randint(0, (e - open_).days))
            elif k < 0.7 and cat != "basic":
                # outside the cycle entirely
                if r.random() < 0.5:
                    open_ = e + dt.timedelta(days=r.randint(1, 40))
                else:
                    close = s - dt.timedelta(days=r.randint(1, 40))
            elif k < 0.75:
                open_, close = s, e
        close_s = d2s(close) if close else r.choice(["        ", "00000000"])
        line = acct(aid, self.name(), plan, d2s(open_), close_s, tax, region,
                    bal_s, loy)
        lo = max(open_, s)
        hi = min(close, e) if close else e
        info = None
        if lo <= hi:
            info = {"id": aid, "lo": lo, "hi": hi, "plan": plan,
                    "open": open_, "close": close}
        elif r.random() < 0.6:
            info = {"id": aid, "lo": s, "hi": e, "plan": plan, "open": open_,
                    "close": close, "dead": True}
        return line, info

    def activity_for(self, info, s, e):
        r = self.r
        cat = self.cat
        aid = info["id"]
        lo, hi = info["lo"], info["hi"]
        out = []
        if info.get("dead"):
            for _ in range(r.randint(1, 3)):
                out.append(us(aid, d2s(self.day_in(s, e)), "DATA", qty(r.randint(1, 900) / 100)))
            return out
        if r.random() < (0.12 if cat != "basic" else 0.2):
            return out
        def day():
            return d2s(self.day_in(lo, hi))
        n_us = r.randint(0, 6)
        if cat in ("tiers", "rounding"):
            n_us += 4
        for _ in range(n_us):
            svc = r.choice(["DATA", "VOIC", "SMS ", "ROAM"])
            if cat == "tiers":
                svc = r.choice(["DATA", "DATA", "SMS ", "VOIC"])
            out.append(us(aid, day(), svc, qty(self.usage_qty(svc))))
        if cat == "tiers" and r.random() < 0.6:
            target = r.choice([2, 5, 10, 12, 15, 40, 42, 45, 50, 52, 55, 7, 0.01])
            target += r.choice([0, 0, 0.01, -0.01, 0.005])
            out.append(us(aid, day(), "DATA", qty(max(target, 0.01))))
        if cat in ("charges", "mixed", "signs") or r.random() < 0.4:
            for _ in range(r.randint(1, 4 if cat == "charges" else 2)):
                code = r.choice(CH_CODES if cat != "charges" else CH_CODES + ["LATE", "LATE"])
                v = r.choice([r.randint(100, 2500) / 100, r.randint(500, 1500) / 100,
                              r.randint(1, 99999) / 100])
                if cat == "signs" and r.random() < 0.4:
                    v = -v
                if code in ("MISC", "LATE") and r.random() < 0.25:
                    v = -abs(v)
                out.append(ch(aid, day(), code, amt(v), r.choice(CH_DESC[code])))
        if cat in ("proration", "mixed", "dates") or r.random() < 0.2:
            for _ in range(r.randint(1, 3)):
                out.append(pc(aid, day(), r.choice("BSP")))
            if r.random() < 0.6:
                d1 = self.day_in(lo, hi)
                d2 = d1 + dt.timedelta(days=r.randint(0, 20))
                out.append(su(aid, d2s(d1), d2s(d2)))
        if cat in ("discounts", "mixed") or r.random() < 0.15:
            for _ in range(r.randint(1, 4)):
                if r.random() < 0.5:
                    out.append(ds(aid, day(), "F", amt(r.choice([5, 10, 25, 3.5, r.randint(1, 9000) / 100]))))
                else:
                    out.append(ds(aid, day(), "P", amt(r.choice([10, 15, 20, 50, 12.5, 33.33, r.randint(1, 10000) / 100]))))
        if r.random() < 0.6 or cat == "signs":
            for _ in range(r.randint(1, 2)):
                v = r.choice([r.randint(500, 9000) / 100, r.randint(1, 30000) / 100])
                out.append(py(aid, day(), amt(v)))
        if r.random() < 0.3 or cat == "signs":
            v = r.randint(-5000, 3000) / 100
            out.append(ad(aid, day(), amt(v), r.choice(AD_DESC)))
        return out

    def usage_qty(self, svc):
        r = self.r
        cat = self.cat
        if svc == "DATA":
            return r.choice([r.randint(1, 1500) / 100, r.randint(1, 6000) / 100, r.randint(0, 20)])
        if svc == "VOIC":
            if cat == "rounding":
                return r.choice([r.randint(1, 600) / 100, r.randint(1, 120), r.randint(1, 99) / 100 + r.randint(0, 30)])
            return r.choice([r.randint(1, 30000) / 100, r.randint(1, 200)])
        if svc == "SMS ":
            return r.choice([r.randint(1, 150), r.randint(50, 400), r.randint(1, 9999) / 100])
        if cat == "rounding":
            return r.choice([r.randint(1, 400) / 100 + 0.02, r.randint(1, 4000) / 100, r.randint(0, 99) + 0.06, r.randint(0, 99) + 0.02])
        return r.choice([r.randint(1, 50000) / 100, r.randint(1, 300)])

    def bad_account(self, s, e, live):
        r = self.r
        aid = self.new_id()
        base = dict(aid=aid, name=self.name(), plan=r.choice("BSP"),
                    open_=d2s(s - dt.timedelta(days=100)), close="        ",
                    tax="N", region=r.choice(REGIONS), bal=amt(12.5), loy="  ")
        k = r.choice(["blank", "dup", "plan", "open", "open_feb", "close",
                      "close_before", "tax", "bal_sign", "bal_digits",
                      "bal_space", "multi", "plan_lower", "open_1899"])
        if k == "blank":
            base["aid"] = "        "
        elif k == "dup" and live:
            base["aid"] = r.choice(live)["id"]
        elif k == "plan":
            base["plan"] = r.choice("XQ 1")
        elif k == "plan_lower":
            base["plan"] = r.choice("bsp")
        elif k == "open":
            base["open_"] = r.choice(["2024130A", "20241301", "20240000", "        "])
        elif k == "open_feb":
            base["open_"] = r.choice(["20230229", "21000229", "20220431"])
        elif k == "open_1899":
            base["open_"] = "18991231"
        elif k == "close":
            base["close"] = r.choice(["20240631", "2024XX01", "20230229"])
        elif k == "close_before":
            base["close"] = d2s(s - dt.timedelta(days=200))
        elif k == "tax":
            base["tax"] = r.choice("XZ 1n")
        elif k == "bal_sign":
            base["bal"] = "*000001250"
        elif k == "bal_space":
            base["bal"] = " 000001250"
        elif k == "bal_digits":
            base["bal"] = "+00001 250"
        elif k == "multi":
            base["plan"] = "Z"
            base["tax"] = "Q"
            base["bal"] = "+ABCDEFGHI"
        return acct(base["aid"], base["name"], base["plan"], base["open_"],
                    base["close"], base["tax"], base["region"], base["bal"],
                    base["loy"])

    def bad_activity(self, s, e, live):
        r = self.r
        aid = r.choice(live)["id"] if live else "ZZ000000"
        good = d2s(self.day_in(s, e))
        k = r.choice(["type", "type_lower", "acct", "date", "feb29", "outside",
                      "svc", "qty", "chcode", "chamt", "chsign", "pcplan",
                      "pynonpos", "pyneg", "adamt", "dskind", "dsval",
                      "dsover", "suend", "suback", "blank", "before_open",
                      "multi", "svc_qty", "acct_date", "out_inactive",
                      "ch_code_amt", "ds_kind_val", "py_nonnum", "su_out",
                      "pc_out"])
        if k == "type":
            return act(r.choice(["XX", "RF", "UZ", "  "]), aid, good, "DATA" + qty(1))
        if k == "type_lower":
            return act("us", aid, good, "DATA" + qty(1))
        if k == "acct":
            return us("QQ" + "%06d" % r.randint(0, 999999), good, "VOIC", qty(5))
        if k == "date":
            return us(aid, r.choice(["2024013X", "20241232", "        ", "20240100"]), "SMS ", qty(3))
        if k == "feb29":
            return us(aid, "%04d0229" % r.choice([2023, 2025, 2100]), "DATA", qty(2))
        if k == "outside":
            d = r.choice([s - dt.timedelta(days=r.randint(1, 60)), e + dt.timedelta(days=r.randint(1, 60))])
            return us(aid, d2s(d), "DATA", qty(4))
        if k == "svc":
            return us(aid, good, r.choice(["DAT ", "VOICE", "MMS ", "data"]), qty(3))
        if k == "qty":
            return us(aid, good, "DATA", r.choice(["00000012X", "    12.50", "-00000100"]))
        if k == "chcode":
            return ch(aid, good, r.choice(["FEE ", "late", "XXXX"]), amt(5), "BAD")
        if k == "chamt":
            return ch(aid, good, "MISC", r.choice(["+0000A0100", "+00001 00 "]), "BAD AMT")
        if k == "chsign":
            return ch(aid, good, "EQUP", r.choice([" 000001000", "0000010000"]), "NOSIGN")
        if k == "pcplan":
            return pc(aid, good, r.choice("XZ b"))
        if k == "pynonpos":
            return py(aid, good, amt(0))
        if k == "pyneg":
            return py(aid, good, amt(-r.randint(100, 5000) / 100))
        if k == "adamt":
            return ad(aid, good, "+00000ABCD", "BAD")
        if k == "dskind":
            return ds(aid, good, r.choice("XZ p"), amt(10))
        if k == "dsval":
            return ds(aid, good, r.choice("PF"), r.choice([amt(0), amt(-5), "+0000X0000"]))
        if k == "dsover":
            return ds(aid, good, "P", amt(r.choice([100.01, 150, 250])))
        if k == "suend":
            return su(aid, good, r.choice(["20240230", "XXXXXXXX", "        "]))
        if k == "suback":
            d = self.day_in(s, e)
            return su(aid, d2s(d), d2s(d - dt.timedelta(days=r.randint(1, 5))))
        if k == "blank":
            return ""
        if k == "before_open":
            for info in live:
                if info["open"] > s:
                    return us(info["id"], d2s(s), "DATA", qty(1))
            return us(aid, d2s(s - dt.timedelta(days=1)), "DATA", qty(1))
        if k == "svc_qty":
            return us(aid, good, "MMS ", "0000ABC00")
        if k == "acct_date":
            return us("QQ000001", "20241399", "DATA", qty(1))
        if k == "out_inactive":
            for info in live:
                if info["close"] or info.get("dead"):
                    return us(info["id"], d2s(e + dt.timedelta(days=3)), "VOIC", qty(2))
            return us(aid, d2s(e + dt.timedelta(days=3)), "VOIC", qty(2))
        if k == "ch_code_amt":
            return ch(aid, good, "FEES", "+00000XX00", "BOTH BAD")
        if k == "ds_kind_val":
            return ds(aid, good, "X", "+00000XX00")
        if k == "py_nonnum":
            return py(aid, good, "-0000A0000")
        if k == "su_out":
            return su(aid, d2s(e + dt.timedelta(days=1)), d2s(e + dt.timedelta(days=4)))
        if k == "pc_out":
            return pc(aid, d2s(s - dt.timedelta(days=2)), "Q")
        return act("ZZ", "NOPE0001", "2024XXXX", "????")


def generate(seed, cat):
    return Gen(seed, cat).build()


if __name__ == "__main__":
    out = []
    n = int(sys.argv[1]) if len(sys.argv) > 1 else 30
    base = int(sys.argv[2]) if len(sys.argv) > 2 else 1000
    for ci, cat in enumerate(CATEGORIES):
        for k in range(n):
            seed = base + ci * 1000 + k
            out.append({"id": "%s_%03d" % (cat, k), "category": cat,
                        "seed": seed, "files": generate(seed, cat)})
    json.dump(out, sys.stdout)
