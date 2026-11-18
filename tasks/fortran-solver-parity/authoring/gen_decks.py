#!/usr/bin/env python3
"""Generate the hidden HYDRO input decks (seeded, deterministic).

Usage: gen_decks.py OUTDIR
Writes OUTDIR/<category>_<nnn>.dat and OUTDIR/manifest.json.
"""
import json
import os
import random
import sys

SEED = 20261118
DIAMS_MM = [50, 75, 100, 150, 200, 250, 300, 400]
DIAMS_IN = [2, 3, 4, 6, 8, 10, 12, 16]
ROUGH_MM = [0.0015, 0.01, 0.05, 0.1, 0.26, 0.5, 1.0]
ROUGH_MFT = [0.005, 0.03, 0.15, 0.3, 0.85, 1.5, 3.0]
HW_C = [80, 90, 100, 110, 120, 130, 140, 150]


def fmt(x, nd=3):
    s = f"{x:.{nd}f}".rstrip("0").rstrip(".")
    return s if s not in ("", "-0") else "0"


class Net:
    """A random looped network description, rendered to cards later."""

    def __init__(self, rng, nrow, ncol, nres=1, units="SI", fric="DW",
                 idstyle=None, dem_scale=1.0, loops=0.4, minor=0.0):
        self.rng = rng
        self.units = units
        self.fric = fric
        self.junctions = []  # (id, elev, demand, pattern)
        self.reservoirs = []  # (id, head)
        self.links = []  # card strings without keyword handled in render
        style = idstyle or rng.choice(["J", "N", "mixed", "word"])
        ids = {}
        k = 0
        order = [(r, c) for r in range(nrow) for c in range(ncol)]
        for (r, c) in order:
            k += 1
            if style == "J":
                nid = f"J{k}"
            elif style == "N":
                nid = f"N{r+1}{c+1}"
            elif style == "word":
                nid = rng.choice(["A", "B", "C", "X", "Y", "Z", "M", "K"]) + f"{k}"
            else:
                nid = rng.choice(["J", "n", "Hy", "j"]) + f"{k:02d}" if rng.random() < 0.5 else f"J{k}"
            while nid in ids.values():
                nid = nid + "x"
            ids[(r, c)] = nid
        self.ids = ids
        lf = 1.0 if units == "SI" else 3.28084
        qf = 1.0 if units == "SI" else 15.8503
        base_e = rng.uniform(0, 40)
        for (r, c) in order:
            e = base_e + rng.uniform(-10, 15)
            d = rng.choice([0, 0, 1, 1, 1]) * rng.uniform(0.5, 8.0) * dem_scale
            self.junctions.append([ids[(r, c)], round(e * lf, 2), round(d * qf, 2), None])
        emax = max(j[1] for j in self.junctions) / lf
        # spanning tree over the grid plus extra edges
        edges = []
        for (r, c) in order:
            if c + 1 < ncol:
                edges.append(((r, c), (r, c + 1)))
            if r + 1 < nrow:
                edges.append(((r, c), (r + 1, c)))
        rng.shuffle(edges)
        parent = {p: p for p in order}

        def find(p):
            while parent[p] != p:
                parent[p] = parent[parent[p]]
                p = parent[p]
            return p
        chosen = []
        rest = []
        for a, b in edges:
            ra, rb = find(a), find(b)
            if ra != rb:
                parent[ra] = rb
                chosen.append((a, b))
            else:
                rest.append((a, b))
        for e in rest:
            if rng.random() < loops:
                chosen.append(e)
        rng.shuffle(chosen)
        self.pipes = []
        pk = 0
        for a, b in chosen:
            if rng.random() < 0.5:
                a, b = b, a
            pk += 1
            self.add_pipe(f"P{pk}", ids[a], ids[b], minor)
        for i in range(nres):
            rid = rng.choice(["R", "RES", "T", "SRC"]) + str(i + 1)
            head = emax + rng.uniform(30, 90)
            self.reservoirs.append([rid, round(head * lf, 2)])
            tgt = ids[rng.choice(order)]
            pk += 1
            self.add_pipe(f"P{pk}", rid, tgt, minor, big=True)
        self.pk = pk

    def add_pipe(self, pid, a, b, minor=0.0, big=False, diam=None):
        rng = self.rng
        if self.units == "SI":
            L = round(rng.uniform(50, 1500), 1)
            D = diam or (rng.choice(DIAMS_MM[3:]) if big else
                         rng.choice(DIAMS_MM[2:] if rng.random() < 0.85 else DIAMS_MM))
            R = rng.choice(ROUGH_MM) if self.fric == "DW" else rng.choice(HW_C)
        else:
            L = round(rng.uniform(150, 4500), 1)
            D = diam or (rng.choice(DIAMS_IN[3:]) if big else
                         rng.choice(DIAMS_IN[2:] if rng.random() < 0.85 else DIAMS_IN))
            R = rng.choice(ROUGH_MFT) if self.fric == "DW" else rng.choice(HW_C)
        K = None
        if minor and rng.random() < minor:
            K = rng.choice([0.5, 1.0, 2.5, 5.0, 10.0])
        self.pipes.append(["PIPE", pid, a, b, L, D, R, K])

    def render(self, kw=str, extra_cards=(), head_cards=(), node_first=True,
               title=None, end=True, shuffle=False):
        lines = []
        if title is not None:
            lines.append(f"{kw('TITLE')} {title}")
        lines.extend(head_cards)
        node_lines = []
        for rid, h in self.reservoirs:
            node_lines.append(f"{kw('RESERVOIR')} {rid} {fmt(h, 2)}")
        for nid, e, d, pat in self.junctions:
            s = f"{kw('JUNCTION')} {nid} {fmt(e, 2)} {fmt(d, 3)}"
            if pat:
                s += f" {pat}"
            node_lines.append(s)
        link_lines = []
        for p in self.pipes:
            if p[0] == "PIPE":
                _, pid, a, b, L, D, R, K = p
                s = f"{kw('PIPE')} {pid} {a} {b} {fmt(L, 1)} {fmt(D)} {fmt(R, 4)}"
                if K is not None:
                    s += f" {fmt(K, 2)}"
            else:
                s = " ".join([kw(p[0])] + [str(x) for x in p[1:]])
            link_lines.append(s)
        if shuffle:
            self.rng.shuffle(node_lines)
            self.rng.shuffle(link_lines)
        if node_first:
            lines += node_lines + link_lines
        else:
            lines += link_lines + node_lines
        lines.extend(extra_cards)
        if end:
            lines.append(kw("END"))
        return "\n".join(lines) + "\n"


def units_card(net):
    return [] if net.units == "SI" and random.random() < 0.5 else [f"UNITS {net.units}"]


def gen(outdir):
    rng = random.Random(SEED)
    decks = []

    def add(cat, text):
        n = sum(1 for d in decks if d["cat"] == cat) + 1
        name = f"{cat}_{n:03d}"
        decks.append({"name": name, "cat": cat, "text": text})

    def net(**kw):
        return Net(rng, **kw)

    # 1 basic: SI, Darcy-Weisbach, small looped networks
    for i in range(40):
        n = net(nrow=rng.randint(1, 4), ncol=rng.randint(2, 4), nres=rng.choice([1, 1, 2]))
        add("basic", n.render(title=rng.choice([None, f"Network {i}", "District main"])))
    # 2 large networks
    for i in range(15):
        n = net(nrow=rng.randint(5, 8), ncol=rng.randint(5, 10), nres=rng.randint(1, 3), loops=0.5)
        add("large", n.render(title=f"Large grid {i}"))
    # 3 friction regimes: laminar / transition / low turbulent
    for i in range(25):
        n = net(nrow=1, ncol=rng.randint(1, 3))
        for p in n.pipes:
            p[5] = rng.choice([25, 50, 75])
        for j in n.junctions:
            j[2] = round(rng.uniform(0.02, 0.6), 3)
        add("regime", n.render(title="Low flow"))
    # 3b trickle flows around the zero-flow threshold
    for i in range(6):
        n = net(nrow=1, ncol=rng.randint(2, 3))
        for j in n.junctions:
            j[2] = round(rng.uniform(0.001, 0.012), 3)
        add("regime", n.render(title="Trickle"))
    # 4 Hazen-Williams
    for i in range(20):
        n = net(nrow=rng.randint(1, 4), ncol=rng.randint(2, 4), fric="HW", nres=rng.choice([1, 2]))
        add("hazen", n.render(head_cards=["OPTION FRICTION HW"], title="HW network"))
    # 5 minor losses
    for i in range(20):
        n = net(nrow=rng.randint(1, 3), ncol=rng.randint(2, 4), minor=0.7)
        add("minor", n.render(title="Fittings"))
    # 6 pumps
    for i in range(25):
        n = net(nrow=rng.randint(1, 3), ncol=rng.randint(2, 3))
        # sump feeding the network through a pump
        sump = f"S{i}"
        sh = round(rng.uniform(-5, 5), 2)
        tgt = n.junctions[rng.randrange(len(n.junctions))][0]
        top = max(r[1] for r in n.reservoirs)
        h0 = round(top - sh + rng.uniform(5, 40), 1)
        mode = i % 5
        if mode == 3:
            # the pump is the only source and the demand exceeds QMAX
            n.reservoirs = []
            for p in list(n.pipes):
                if not (p[2] in n.ids.values() and p[3] in n.ids.values()):
                    n.pipes.remove(p)
            tot = sum(j[2] for j in n.junctions)
            for j in n.junctions:
                j[1] = round(j[1] - 40, 2)
            qmax = round(max(tot * rng.uniform(0.5, 0.9), 0.5), 1)
            pcard = f"PUMP PU1 {sump} {tgt} {fmt(h0, 1)} {fmt(qmax, 1)}"
        elif mode == 0:
            pcard = f"PUMP PU1 {sump} {tgt} {fmt(h0, 1)}"
        elif mode in (1, 2):
            qmax = round(rng.uniform(20, 120), 1)
            pcard = f"PUMP PU1 {sump} {tgt} {fmt(h0, 1)} {fmt(qmax, 1)}"
        else:
            # weak pump against a high reservoir: reverse flow
            pcard = f"PUMP PU1 {sump} {tgt} {fmt(rng.uniform(1, 4), 1)} {fmt(rng.uniform(10, 40), 1)}"
        n.reservoirs.append([sump, sh])
        add("pump", n.render(extra_cards=[pcard], title="Pumped"))
    # 7 valves
    for i in range(20):
        n = net(nrow=rng.randint(1, 3), ncol=rng.randint(2, 4))
        a = n.junctions[rng.randrange(len(n.junctions))][0]
        vid = f"V{i}"
        st = rng.choice(["", " OPEN", " CLOSED", " closed", " open"])
        extra = []
        newj = f"VJ{i}"
        extra.append(f"JUNCTION {newj} {fmt(rng.uniform(0, 30), 1)} {fmt(rng.uniform(0, 5), 2)}")
        extra.append(f"VALVE {vid} {a} {newj} {rng.choice([50, 100, 150, 200])} {fmt(rng.choice([0, 0.2, 2, 8]), 2)}{st}")
        if rng.random() < 0.5:
            extra.append(f"PIPE PX{i} {newj} VK{i} {rng.randint(50, 500)} 100 0.1")
            extra.append(f"JUNCTION VK{i} 5 {fmt(rng.uniform(0, 3), 2)}")
        add("valve", n.render(extra_cards=extra, title="Valves"))
    # 8 US units
    for i in range(20):
        fr = "HW" if i % 2 else "DW"
        n = net(nrow=rng.randint(1, 4), ncol=rng.randint(2, 4), units="US", fric=fr)
        hc = ["UNITS US"] + (["OPTION FRICTION HW"] if fr == "HW" else [])
        extra = []
        if i % 4 == 3:
            sump = "WELL"
            n.reservoirs.append([sump, 0])
            extra.append(f"PUMP PU9 WELL {n.junctions[0][0]} 150 {fmt(rng.uniform(300, 1500), 0)}")
        add("us_units", n.render(head_cards=hc, extra_cards=extra, title="US customary"))
    # 9 patterns and time steps
    for i in range(25):
        n = net(nrow=rng.randint(1, 3), ncol=rng.randint(2, 3))
        steps = rng.randint(2, 7)
        hstep = rng.choice([0.25, 0.5, 1, 1.5, 2, 3])
        pats = []
        npat = rng.randint(1, 2)
        for p in range(npat):
            pid = f"PAT{p+1}"
            mult = [fmt(rng.uniform(0.2, 1.8), 2) for _ in range(rng.randint(1, 5))]
            if len(mult) > 2 and rng.random() < 0.5:
                pats.append(f"PATTERN {pid} " + " ".join(mult[:2]))
                pats.append(f"PATTERN {pid} " + " ".join(mult[2:]))
            else:
                pats.append(f"PATTERN {pid} " + " ".join(mult))
        for j in n.junctions:
            if j[2] and rng.random() < 0.7:
                j[3] = f"PAT{rng.randint(1, npat)}"
        hc = [f"OPTION STEPS {steps}"]
        if hstep != 1 or rng.random() < 0.3:
            hc.append(f"OPTION HSTEP {fmt(hstep, 2)}")
        add("pattern", n.render(head_cards=pats + hc, title="Daily cycle"))
    # 10 parsing variations (valid decks)
    for i in range(25):
        n = net(nrow=rng.randint(1, 3), ncol=rng.randint(2, 3))
        v = i % 10
        if v == 0:
            text = n.render(kw=str.lower, title="lower case keywords")
        elif v == 1:
            text = n.render(kw=lambda s: s.capitalize(), title="Mixed Case")
        elif v == 2:
            text = n.render(title="Inline comments ! this part is dropped")
            text = text.replace("\nPIPE", "\nPIPE").replace("\n", " ! note\n", 3)
        elif v == 3:
            text = n.render(node_first=False, title="Links before nodes")
        elif v == 4:
            text = n.render(title="X" * 30 + " a long title that goes past sixty characters easily")
        elif v == 5:
            text = n.render(end=False, title="No end card")
        elif v == 6:
            text = n.render(title="Tabs").replace(" ", "\t", 40)
        elif v == 7:
            text = n.render(shuffle=True, title="Shuffled",
                            extra_cards=["OPTION TOL 1E-7", "OPTION MAXIT 80"])
            text += "PIPE NEVER READ AFTER END 1 1 1\n"
        elif v == 8:
            text = "* header comment\n\n" + n.render(title="Extra fields")
            text = text.replace("JUNCTION", "JUNCTION", 1)
            lines = text.split("\n")
            for k, ln in enumerate(lines):
                if ln.startswith("RESERVOIR"):
                    lines[k] = ln + " 99"
                    break
            text = "\n".join(lines)
        else:
            text = "TITLE first title\n" + n.render(title="second title wins")
            text = text.replace("END\n", "UNITS si\nOPTION friction dw\nEND\n")
        add("parsing", text)
    # 11 errors
    err_cases = [
        "FOO BAR",
        "JUNCTION JX 10 abc",
        "JUNCTION JX 10 1.5.2",
        "JUNCTION TOOLONGID 10 1",
        "PIPE PX {a} {a} 100 100 0.1",
        "PIPE PX {a} NOWHERE 100 100 0.1",
        "PIPE PX {a} {b} -100 100 0.1",
        "PIPE PX {a} {b} 100 0 0.1",
        "PIPE PX {a} {b} 100 100 -0.1",
        "PIPE PX {a} {b} 100 100 0.1 -2",
        "PIPE PX {a} {b} 100 100",
        "PIPE P1 {a} {b} 100 100 0.1",
        "OPTION BOGUS 3",
        "OPTION MAXIT 2.5",
        "OPTION MAXIT 0",
        "OPTION TOL -1",
        "OPTION TOL abc",
        "OPTION FRICTION XX",
        "OPTION STEPS 25",
        "OPTION HSTEP 0",
        "OPTION METHOD HC",
        "UNITS METRIC",
        "UNITS",
        "JUNCTION {a} 5 1",
        "RESERVOIR {a} 50",
        "RESERVOIR RZ",
        "JUNCTION JZ 5 1 NOPAT",
        "PATTERN PZ 1 -1",
        "PATTERN PZ 1 1 1 1 1 1 1 1 1 1 1 1 1 1\nPATTERN PZ 1 1 1 1 1 1 1 1 1 1 1",
        "PUMP PU {a} {b} 0",
        "PUMP PU {a} {b} 10 -5",
        "VALVE VZ {a} {b} 100 1 SHUT",
        "VALVE VZ {a} {b} 100",
        "PIPE PX {a} {b} 1e2 1d2 0.1 1 2 3",
        "JUNCTION JX 10 1 P1 extra",
        "foo bar",
        "PIPE LONGPIPEID {a} {b} 100 100 0.1",
        "PIPE PX {a} LONGNODEID 100 100 0.1",
        "JUNCTION JX 10 1 LONGPATTERN",
        "PATTERN LONGPATTERN 1 2",
        "JUNCTION",
        "PUMP PU {a}",
        "OPTION TOL",
        "OPTION STEPS 2.5",
        "OPTION HSTEP 30",
        "VALVE VZ {a} {a} 100 1",
        "VALVE VZ {a} {b} 0 1",
        "RESERVOIR RZ high",
    ]
    for i, case in enumerate(err_cases):
        n = net(nrow=1, ncol=rng.randint(2, 3))
        a, b = n.junctions[0][0], n.junctions[1][0]
        card = case.format(a=a, b=b)
        if rng.random() < 0.5:
            text = n.render(extra_cards=[card], title="Error case")
        else:
            text = n.render(head_cards=[card], title="Error case")
        add("errors", text)
    for i in range(10):
        n = net(nrow=1, ncol=3)
        a, b = n.junctions[0][0], n.junctions[1][0]
        picks = rng.sample(err_cases, 3)
        cards = [c.format(a=a, b=b) for c in picks]
        add("errors", n.render(extra_cards=cards, head_cards=cards[:1], title="Many errors"))
    # HW with zero C, no reservoir at all, links to undefined nodes after the fact
    n = net(nrow=1, ncol=3, fric="HW")
    n.pipes[0][6] = 0
    add("errors", n.render(head_cards=["OPTION FRICTION HW"], title="zero C"))
    n = net(nrow=2, ncol=2)
    n.reservoirs = []
    add("errors", n.render(title="no source"))
    big = ["RESERVOIR R0 100"] + [f"JUNCTION J{k} 10 1" for k in range(1, 101)]
    add("errors", "TITLE too many\n" + "\n".join(big) + "\nPIPE P1 R0 J1 100 100 0.1\nEND\n")
    pats = [f"PATTERN Q{k} 1" for k in range(1, 12)]
    n = net(nrow=1, ncol=2)
    add("errors", n.render(head_cards=pats, title="too many patterns"))
    # 12 warnings and solver control
    for i in range(30):
        v = i % 6
        n = net(nrow=rng.randint(1, 3), ncol=rng.randint(2, 4))
        hc = []
        if v == 0:  # negative pressure
            for j in n.junctions:
                j[1] = round(j[1] + rng.uniform(40, 90), 2)
        elif v == 1:  # high velocity
            for p in n.pipes:
                p[5] = 100
            for j in n.junctions:
                j[2] = round(j[2] * 1.5 + 4, 2)
        elif v == 2:  # dead ends, zero flow
            n.junctions.append([f"DE{i}", 3.0, 0.0, None])
            n.add_pipe(f"PD{i}", n.junctions[0][0], f"DE{i}")
        elif v == 3:  # not converged
            hc = [f"OPTION MAXIT {rng.randint(1, 3)}"]
        elif v == 4:  # maxit clamp and tight tolerance
            hc = [f"OPTION MAXIT {rng.choice([201, 500, 1000])}", "OPTION TOL 1E-9"]
        else:  # loose tolerance
            hc = [f"OPTION TOL {rng.choice(['0.01', '0.05', '1E-3'])}"]
        add("warnings", n.render(head_cards=hc, title="Warnings"))
    # 13 topology
    for i in range(15):
        v = i % 5
        n = net(nrow=rng.randint(1, 3), ncol=rng.randint(2, 3), nres=rng.choice([1, 2]))
        extra = []
        if v == 0:  # disconnected island
            extra = [f"JUNCTION I{i}A 10 2", f"JUNCTION I{i}B 12 1",
                     f"PIPE PI{i} I{i}A I{i}B 200 100 0.1"]
        elif v == 1:  # lone junction
            extra = [f"JUNCTION LONE{i} 10 0"]
        elif v == 2:  # reservoir to reservoir
            extra = [f"RESERVOIR RR{i} 20", f"PIPE PR{i} {n.reservoirs[0][0]} RR{i} 800 200 0.1"]
        elif v == 3:  # isolated by closed valve with demand downstream
            extra = [f"JUNCTION Z{i} 5 4", f"VALVE VC{i} {n.junctions[0][0]} Z{i} 100 1 CLOSED",
                     f"PIPE PZ{i} Z{i} ZZ{i} 100 100 0.1", f"JUNCTION ZZ{i} 4 1"]
        else:  # reservoirs only network
            n.junctions = []
            n.pipes = []
            extra = [f"RESERVOIR RB{i} 10", f"PIPE PA{i} {n.reservoirs[0][0]} RB{i} 500 150 0.05",
                     f"PIPE PB{i} RB{i} {n.reservoirs[0][0]} 900 100 0.05 3"]
        add("topology", n.render(extra_cards=extra, title="Topology"))

    # isolated groups declared in reverse name order
    for i in range(5):
        n = net(nrow=1, ncol=rng.randint(2, 3))
        names = sorted(rng.sample(["ZED", "Q7", "M2", "B9", "K1", "W4", "D3"], 4), reverse=True)
        extra = []
        for k, nm in enumerate(names):
            extra.append(f"JUNCTION {nm} {rng.randint(0, 20)} {fmt(rng.uniform(0, 3), 2)}")
        extra.append(f"PIPE PQ{i} {names[0]} {names[1]} 300 100 0.1")
        if i % 2:
            extra.append(f"VALVE VQ{i} {n.junctions[0][0]} {names[2]} 100 1 CLOSED")
        add("topology", n.render(extra_cards=extra, title="Islands"))

    os.makedirs(outdir, exist_ok=True)
    man = []
    for d in decks:
        with open(os.path.join(outdir, d["name"] + ".dat"), "w") as f:
            f.write(d["text"])
        man.append({"name": d["name"], "cat": d["cat"]})
    with open(os.path.join(outdir, "manifest.json"), "w") as f:
        json.dump(man, f, indent=1)
    print(len(decks), "decks")


if __name__ == "__main__":
    gen(sys.argv[1])
