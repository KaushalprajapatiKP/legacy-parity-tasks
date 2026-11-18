"""Build the docs-only baseline tree: 4.2 report layouts, but every rule the
release note leaves open is filled with the most natural guess (3.7 value or
a round number)."""
import os, shutil, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from mutants import M
src, dst = sys.argv[1], sys.argv[2]
shutil.rmtree(dst, ignore_errors=True); shutil.copytree(src, dst)
use = ["data_t2_limit_50", "data_t3_rate_090", "roam_half_up", "susp_free",
       "loyalty_on_base_usage", "coupon_pct_first", "late_cap_25",
       "no_activity_line", "a07_space_sign_ok", "no_year_floor"]
extra = [
 ("lib/ratecalc.cbl", "INCL-S          PIC 9V99    VALUE 2.00", "INCL-S          PIC 9V99    VALUE 1.00"),
 ("lib/ratecalc.cbl", "INCL-P          PIC 9V99    VALUE 5.00", "INCL-P          PIC 9V99    VALUE 3.00"),
 ("lib/ratecalc.cbl", "RATE-P          PIC 9V99    VALUE 0.03", "RATE-P          PIC 9V99    VALUE 0.04"),
 ("lib/ratecalc.cbl", "FREE-P           PIC 9(3)    VALUE 100", "FREE-P           PIC 9(3)    VALUE 50"),
 ("lib/ratecalc.cbl", "           IF RC-QTY > WS-WHOLE\n               ADD 1 TO WS-WHOLE\n           END-IF\n",
                      "           IF RC-QTY - WS-WHOLE NOT < 0.50\n               ADD 1 TO WS-WHOLE\n           END-IF\n"),
 ("billrun.cbl", "           MOVE 16 TO WS-RC.", "           MOVE 8 TO WS-RC."),
]
msgs = {"A01MISSING ACCOUNT ID": "A01NO ACCOUNT ID", "A03INVALID PLAN": "A03BAD PLAN CODE",
        "A04INVALID OPEN DATE": "A04BAD OPEN DATE", "A05INVALID CLOSE DATE": "A05BAD CLOSE DATE",
        "A07INVALID BALANCE": "A07BAD BALANCE", "C01INVALID CONTROL RECORD": "C01CONTROL CARD ERROR",
        "R01UNKNOWN RECORD TYPE": "R01INVALID RECORD TYPE", "R02UNKNOWN ACCOUNT": "R02ACCOUNT NOT FOUND",
        "R03INVALID DATE": "R03BAD DATE", "R05INVALID AMOUNT": "R05BAD AMOUNT", "R06INVALID CODE": "R06BAD CODE"}
for name, f, old, new in M:
    if name in use: extra.append((f, old, new))
for k, v in msgs.items(): extra.append(("copy/REJMSG.cpy", '"%s"' % k, '"%s"' % v))
for f, old, new in extra:
    p = os.path.join(dst, f); s = open(p).read()
    assert s.count(old) == 1, (f, old)
    open(p, "w").write(s.replace(old, new))
print("baseline tree written:", dst)
