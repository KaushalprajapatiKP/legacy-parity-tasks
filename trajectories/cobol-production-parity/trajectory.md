# Agent trajectory: cobol-production-parity

One cold attempt by the agent under test. Only the task prompt, the agent's visible
messages, its tool calls and truncated tool outputs are kept.
Tool calls: 83


## Task prompt given to the agent

```
You are an AI agent solving a terminal task inside a Docker container. The container is already running and named `sn-cobol-production-parity`. Work ONLY inside it, by running commands through Bash as: docker exec sn-cobol-production-parity bash -lc '<command>' (for multi-line file edits, use heredocs inside the bash -lc string, or `docker exec -i ... bash -c 'cat > /path' <<'EOF' ... EOF`).

Rules: do not read, list or search any file on the host machine (no Read/Grep/Glob on host paths, no ls of host dirs); everything you need is in the container. No web access. Do not copy files out of the container.

Start with: docker exec sn-cobol-production-parity cat /instruction.md . That file is your task. Solve it as well as you can, test your work inside the container, and stop when you believe it is complete. Then reply with a short summary of what you changed and how confident you are.
```

### Step 1: Bash

```bash
docker exec sn-cobol-production-parity cat /instruction.md
```

<details><summary>output</summary>

```
# Bring the billing batch source back to production parity

BILLRUN is a COBOL batch program that bills one cycle of customer accounts. Production runs version 4.2, installed at `/app/prod/billrun`. The 4.2 source has been lost. `/app/src` holds the last surviving source, version 3.7. `/app/docs` has the 3.7 user guide and the 4.2 release notes, and `/app/samples` has an example input set.

Update the source in `/app/src` so that the program built with

'''
cd /app/src && cobc -x -fstatic-call -I copy -o /app/build/billrun billrun.cbl lib/*.cbl
'''

behaves exactly like production 4.2.

## Requirements

1. For any input set in the record formats documented in `/app/docs`, with valid or invalid field values, the built program, run with the input set in its current working directory, must write `STATEMENTS.RPT`, `REJECTS.RPT` and `SUMMARY.RPT` byte-identical to the files production 4.2 writes for the same input, and must exit with the same return code. Graded input sets contain a `CONTROL.DAT`, an `ACCOUNTS.DAT` and an `ACTIVITY.DAT`, with at most 50 accounts and 200 activity records, lines of at most 80 characters and LF line endings.
2. Production 4.2 is the reference for its own behaviour. You may run it as often as you like on inputs you create. Treat it as execute-only: do not disassemble, decompile, dump, read or copy the binary.
3. The program must compute its outputs itself:
   - it may only open the six documented files, assigned by their literal names (`CONTROL.DAT`, `ACCOUNTS.DAT`, `ACTIVITY.DAT`, `STATEMENTS.RPT`, `REJECTS.RPT`, `SUMMARY.RPT`);
   - every `CALL` must name, as a literal, a program whose source is in `/app/src`;
   - no `SYSTEM`, `C$` or `CBL_` routines, `CHAIN`, `EXEC`, or procedure, program or function pointers.
4. Keep the build layout: main program `billrun.cbl`, subprograms in `/app/src/lib/*.cbl`, copybooks in `/app/src/copy`. Do not modify the compiler, toolchain or runtime configuration.

## Grading

The grader removes `/app/prod/billrun` and any copy of it, builds `/app/src` with the command above, replays several hundred hidden input sets that were recorded from production 4.2, and compares the three report files and the return code byte for byte. Every input set must match.
```
</details>

### Step 2: Bash

```bash
docker exec sn-cobol-production-parity bash -lc 'cd /app; find . -path ./prod -prune -o -type f -print | head -100; wc -l src/*.cbl src/lib/*.cbl src/copy/*; cat docs/*release* ; ls prod'
```

<details><summary>output</summary>

```
./src/LICENSE
./src/copy/CTLREC.cpy
./src/copy/DUPARM.cpy
./src/copy/TXPARM.cpy
./src/copy/ACCTREC.cpy
./src/copy/ACTREC.cpy
./src/copy/PRPARM.cpy
./src/copy/RCPARM.cpy
./src/copy/DSPARM.cpy
./src/copy/REJMSG.cpy
./src/copy/ratetab.cpy
./src/billrun.cbl
./src/lib/discount.cbl
./src/lib/ratecalc.cbl
./src/lib/dateutil.cbl
./src/lib/prorate.cbl
./src/lib/taxcalc.cbl
./samples/basic/CONTROL.DAT
./samples/basic/ACTIVITY.DAT
./samples/basic/ACCOUNTS.DAT
./docs/USER_GUIDE_3.7.txt
./docs/RELEASE_NOTES_4.2.txt
./LICENSE
  951 src/billrun.cbl
   34 src/lib/dateutil.cbl
   19 src/lib/discount.cbl
   49 src/lib/prorate.cbl
   59 src/lib/ratecalc.cbl
   26 src/lib/taxcalc.cbl
   19 src/copy/ACCTREC.cpy
   29 src/copy/ACTREC.cpy
    9 src/copy/CTLREC.cpy
    9 src/copy/DSPARM.cpy
    9 src/copy/DUPARM.cpy
   14 src/copy/PRPARM.cpy
   10 src/copy/RCPARM.cpy
   19 src/copy/REJMSG.cpy
    8 src/copy/TXPARM.cpy
   11 src/copy/ratetab.cpy
 1275 total
cat: 'docs/*release*': No such file or directory
billrun
```
</details>

### Step 3: Bash

```bash
docker exec sn-cobol-production-parity bash -lc 'cd /app; cat docs/RELEASE_NOTES_4.2.txt docs/USER_GUIDE_3.7.txt; for f in samples/basic/*; do echo == $f; cat $f; done'
```

### Step 4: Bash

```bash
docker exec sn-cobol-production-parity bash -lc 'cd /app/src; cat copy/* lib/*.cbl'
```

<details><summary>output</summary>

```
BILLRUN 4.2 RELEASE NOTES (production)
======================================

Summary of changes since 3.7. This note lists features; it is not a
specification.

New activity record types

  DS  discount coupon
    19      1   Kind: P percentage, F fixed amount
    23-32  10   Value, signed amount format (a percentage is written the
                same way, for example +000001500 is 15.00 percent)

  SU  service suspension (the activity date is the first suspended day)
    19-26   8   Last suspended day, YYYYMMDD

Billing

  - Monthly fees are prorated for part-cycle service: accounts opening
    or closing during the cycle, mid-cycle plan changes and suspensions.
  - Usage pricing revised: data tiers rebalanced and plan data
    allowances introduced, voice billed in whole minutes, a premium SMS
    allowance, cheaper premium voice, basic SMS repriced, roaming
    rounding changed.
  - Coupons stack with the loyalty discount. New loyalty tier L3. Total
    discounts are capped.
  - Late fees are capped per cycle. Deposits are no longer taxed.
  - Tax rounding changed.

Validation

  - Calendar-accurate date checks.
  - New reject codes for duplicate accounts, invalid tax class, records
    outside the cycle, duplicate activity, inactive accounts, plan
    change, payment, coupon and suspension errors. Reject messages were
    reworded. The reject report shows the record's sequence number and
    source file.
  - Accounts with no service in the cycle are not billed.
  - Billing cycles longer than 31 days are refused.

Reports

  - Statements are ordered by region and account id; statement lines are
    listed in date order; new quantity column; credits are shown with CR.
  - The run summary has new counts, rejects by code and amount due by
    region.

Return code

  - 4 when any record was rejected; the control record error code changed.
BILLRUN 3.7 USER GUIDE
======================

1. PURPOSE

BILLRUN is the monthly billing batch. One run bills one billing cycle. It
reads a control record, the account master and the activity file for the
cycle, and writes customer statements, a reject listing and run control
totals.

2. RUNNING

The program takes no arguments. It reads and writes fixed file names in
the current working directory:

  CONTROL.DAT     input   one control record
  ACCOUNTS.DAT    input   account master, one record per line
  ACTIVITY.DAT    input   cycle activity, one record per line
  STATEMENTS.RPT  output  customer statements
  REJECTS.RPT     output  reject listing
  SUMMARY.RPT     output  run control totals

All files are text files with one record per line (LF line ends). Input
records are fixed column; a line shorter than its record length is read
as if padded with spaces. A missing ACCOUNTS.DAT or ACTIVITY.DAT is read
as an empty file. The program sets a process return code at the end of
the run.

3. CONTROL RECORD (CONTROL.DAT)

  Cols   Len  Field
  1-8     8   Cycle start date, YYYYMMDD
  9-16    8   Cycle end date, 
... [3632 more chars truncated]
```
</details>

<details><summary>output</summary>

```
      *----------------------------------------------------------------
      * ACCTREC - ACCOUNT MASTER RECORD (ACCOUNTS.DAT), 80 BYTES
      *----------------------------------------------------------------
       01  ACCT-RECORD.
           05  AR-ACCT-ID              PIC X(8).
           05  AR-NAME                 PIC X(24).
           05  AR-PLAN                 PIC X.
           05  AR-OPEN-DATE            PIC X(8).
           05  AR-CLOSE-DATE           PIC X(8).
           05  AR-TAX-CLASS            PIC X.
           05  AR-REGION               PIC X(2).
           05  AR-PRIOR-BAL-X.
               10  AR-BAL-SIGN         PIC X.
               10  AR-BAL-DIGITS       PIC X(9).
           05  AR-PRIOR-BAL-N REDEFINES AR-PRIOR-BAL-X
                                       PIC S9(7)V99
                                       SIGN LEADING SEPARATE.
           05  AR-LOYALTY              PIC X(2).
           05  FILLER                  PIC X(16).
      *----------------------------------------------------------------
      * ACTREC - ACTIVITY RECORD (ACTIVITY.DAT), 80 BYTES
      *   US USAGE  CH CHARGE  PC PLAN CHANGE  PY PAYMENT
      *   AD ADJUSTMENT
      *----------------------------------------------------------------
       01  ACT-RECORD.
           05  XR-TYPE                 PIC XX.
           05  XR-ACCT-ID              PIC X(8).
           05  XR-DATE                 PIC X(8).
           05  XR-DATA                 PIC X(62).
           05  XR-US-DATA REDEFINES XR-DATA.
               10  XR-US-SERVICE       PIC X(4).
               10  XR-US-QTY           PIC X(9).
               10  XR-US-QTY-N REDEFINES XR-US-QTY
                                       PIC 9(7)V99.
               10  FILLER              PIC X(49).
           05  XR-CH-DATA REDEFINES XR-DATA.
               10  XR-CH-CODE          PIC X(4).
               10  XR-CH-AMOUNT.
                   15  XR-CH-SIGN      PIC X.
                   15  XR-CH-DIGITS    PIC X(9).
               10  XR-CH-DIGITS-N REDEFINES XR-CH-AMOUNT.
                   15  FILLER          PIC X.
                   15  XR-CH-VALUE     PIC 9(7)V99.
               10  XR-CH-DESC          PIC X(20).
               10  FILLER              PIC X(28).
           05  XR-PC-DATA REDEFINES XR-DATA.
               10  XR-PC-PLAN          PIC X.
               10  FILLER              PIC X(61).
      *----------------------------------------------------------------
      * CTLREC - RUN CONTROL RECORD (CONTROL.DAT), 80 BYTES
      *----------------------------------------------------------------
       01  CTL-RECORD.
           05  CTL-START-DATE          PIC X(8).
           05  CTL-END-DATE            PIC X(8).
           05  CTL-RUN-NO              PIC X(6).
           05  CTL-COMPANY             PIC X(30).
           05  FILLER                  PIC X(28).
      *----------------------------------------------------------------
      * DSPARM - PARAMETERS FOR DISCOUNT
      *------------------------
... [11487 more chars truncated]
```
</details>

### Step 5: Bash

```bash
docker exec sn-cobol-production-parity bash -lc 'cd /app/src; cat billrun.cbl'
```

<details><summary>output</summary>

```
<persisted-output>
Output too large (37.6KB). Full output saved to: <host-path>

Preview (first 2KB):
      *================================================================
      * BILLRUN - MONTHLY BILLING AND STATEMENT BATCH
      * VERSION 3.7
      * COPYRIGHT (C) THE BILLRUN AUTHORS.  MIT LICENSE, SEE LICENSE.
      *
      * INPUT  : CONTROL.DAT  ACCOUNTS.DAT  ACTIVITY.DAT
      * OUTPUT : STATEMENTS.RPT  REJECTS.RPT  SUMMARY.RPT
      *
      * CHANGE LOG
      *   3.0  STATEMENT REWRITE, SUBPROGRAMS SPLIT OUT
      *   3.4  PLAN CHANGE RECORDS (PC)
      *   3.6  LOYALTY DISCOUNTS L1/L2
      *   3.7  REDUCED TAX CLASS R
      *================================================================
       IDENTIFICATION DIVISION.
       PROGRAM-ID. BILLRUN.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT CTL-FILE ASSIGN TO "CONTROL.DAT"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-CTL-STAT.
           SELECT ACCT-FILE ASSIGN TO "ACCOUNTS.DAT"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-ACCT-STAT.
           SELECT ACT-FILE ASSIGN TO "ACTIVITY.DAT"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-ACT-STAT.
           SELECT STMT-FILE ASSIGN TO "STATEMENTS.RPT"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-STMT-STAT.
           SELECT REJ-FILE ASSIGN TO "REJECTS.RPT"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-REJ-STAT.
           SELECT SUM-FILE ASSIGN TO "SUMMARY.RPT"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-SUM-STAT.
       DATA DIVISION.
       FILE SECTION.
       FD  CTL-FILE.
           COPY CTLREC.
       FD  ACCT-FILE.
           COPY ACCTREC.
       FD  ACT-FILE.
           COPY ACTREC.
       FD  STMT-FILE.
       01  STMT-LINE                   PIC X(80).
       FD  REJ-FILE.
       01  REJ-LINE                    PIC X(100).
       FD  SUM-FILE.
       01  SUM-LINE                    PIC X(80).

...
</persisted-output>
```
</details>

### Step 6: Bash

```bash
cd <host-path> echo skip; docker exec sn-cobol-production-parity bash -lc 'cd /app/src; sed -n 50,520p billrun.cbl'
```

<details><summary>output</summary>

```
skip
       FD  SUM-FILE.
       01  SUM-LINE                    PIC X(80).

       WORKING-STORAGE SECTION.
       01  WS-FILE-STATUS.
           05  WS-CTL-STAT             PIC XX.
           05  WS-ACCT-STAT            PIC XX.
           05  WS-ACT-STAT             PIC XX.
           05  WS-STMT-STAT            PIC XX.
           05  WS-REJ-STAT             PIC XX.
           05  WS-SUM-STAT             PIC XX.
       01  WS-SWITCHES.
           05  WS-EOF                  PIC X.
           05  WS-CTL-OK               PIC X.
           05  WS-AMT-OK               PIC X.
       01  WS-VERSION                  PIC X(3) VALUE "3.7".
       01  WS-RC                       PIC 99 VALUE 0.

       COPY REJMSG.

       COPY DUPARM.
       COPY RCPARM.
       COPY PRPARM.
       COPY DSPARM.
       COPY TXPARM.

      *    RUN CONTROL
       01  WS-CONTROL.
           05  WS-CYC-START            PIC 9(8).
           05  WS-CYC-END              PIC 9(8).
           05  WS-CYC-START-DN         PIC 9(9).
           05  WS-CYC-END-DN           PIC 9(9).
           05  WS-CYC-DAYS             PIC 999.
           05  WS-RUN-NO               PIC X(6).
           05  WS-COMPANY              PIC X(30).

      *    COUNTERS
       01  WS-COUNTERS.
           05  WS-ACCT-READ            PIC 9(5) VALUE 0.
           05  WS-ACCT-REJECTED        PIC 9(5) VALUE 0.
           05  WS-STMT-COUNT           PIC 9(5) VALUE 0.
           05  WS-ACT-READ             PIC 9(5) VALUE 0.
           05  WS-ACT-REJECTED         PIC 9(5) VALUE 0.
           05  WS-REJ-TOTAL            PIC 9(5) VALUE 0.

      *    RUN TOTALS
       01  WS-RUN-TOTALS.
           05  WT-BASE                 PIC S9(9)V99 VALUE 0.
           05  WT-USAGE                PIC S9(9)V99 VALUE 0.
           05  WT-CHARGES              PIC S9(9)V99 VALUE 0.
           05  WT-DISC                 PIC S9(9)V99 VALUE 0.
           05  WT-TAX                  PIC S9(9)V99 VALUE 0.
           05  WT-ADJ                  PIC S9(9)V99 VALUE 0.
           05  WT-PAY                  PIC S9(9)V99 VALUE 0.
           05  WT-DUE                  PIC S9(9)V99 VALUE 0.

      *    ACCOUNT TABLE
       01  ACCT-TABLE.
           05  AT-COUNT                PIC 9(4) COMP VALUE 0.
           05  AT-ENTRY OCCURS 500 TIMES.
               10  AT-REGION           PIC XX.
               10  AT-ACCT-ID          PIC X(8).
               10  AT-NAME             PIC X(24).
               10  AT-PLAN             PIC X.
               10  AT-OPEN-DATE        PIC 9(8).
               10  AT-CLOSE-DATE       PIC 9(8).
               10  AT-TAX-CLASS        PIC X.
               10  AT-PRIOR-BAL        PIC S9(7)V99.
               10  AT-LOYALTY          PIC XX.

      *    ACTIVITY TABLE (ACCEPTED RECORDS)
       01  ACT-TABLE.
           05  XT-COUNT                PIC 9(4) COMP VALUE 0.
           05  XT-ENTRY OCCURS 3000 TIMES.
               10  XT-TYPE             PIC XX.
               10  XT-ACCT-IX          PIC 9(4) COMP.
     
... [15837 more chars truncated]
```
</details>

### Step 7: Bash

```bash
docker exec sn-cobol-production-parity bash -lc 'cd /app/src; sed -n 520,951p billrun.cbl'
```

<details><summary>output</summary>

```
       3300-CHECK-CHARGE.
           IF XR-CH-CODE NOT = "EQUP" AND XR-CH-CODE NOT = "INST"
              AND XR-CH-CODE NOT = "LATE" AND XR-CH-CODE NOT = "DEPO"
              AND XR-CH-CODE NOT = "MISC"
               MOVE "R06" TO WS-REJ-CODE
           ELSE
               PERFORM 3150-CHECK-AMOUNT
           END-IF.

      *----------------------------------------------------------------
      * PLAN CHANGE: NEW PLAN MUST BE B, S OR P.
      *----------------------------------------------------------------
       3400-CHECK-PLAN-CHANGE.
           IF XR-PC-PLAN NOT = "B" AND XR-PC-PLAN NOT = "S"
              AND XR-PC-PLAN NOT = "P"
               MOVE "R06" TO WS-REJ-CODE
           END-IF.

      *----------------------------------------------------------------
      * KEEP AN ACCEPTED ACTIVITY RECORD.
      *----------------------------------------------------------------
       3900-STORE-ACTIVITY.
           ADD 1 TO XT-COUNT
           MOVE XT-COUNT TO WX
           MOVE XR-TYPE TO XT-TYPE(WX)
           MOVE WA TO XT-ACCT-IX(WX)
           MOVE XR-DATE TO XT-DATE(WX)
           MOVE SPACES TO XT-CODE(WX) XT-DESC(WX)
           MOVE 0 TO XT-QTY(WX) XT-AMOUNT(WX)
           EVALUATE XR-TYPE
               WHEN "US"
                   MOVE XR-US-SERVICE TO XT-CODE(WX)
                   MOVE XR-US-QTY-N TO XT-QTY(WX)
               WHEN "PC"
                   MOVE XR-PC-PLAN TO XT-CODE(WX)
               WHEN OTHER
                   MOVE XR-CH-CODE TO XT-CODE(WX)
                   MOVE XR-CH-DESC TO XT-DESC(WX)
                   MOVE XR-CH-SIGN TO WS-AMT-SIGN
                   MOVE XR-CH-DIGITS TO WS-AMT-DIGITS
                   PERFORM 3160-SIGNED-VALUE
                   MOVE WS-AMOUNT TO XT-AMOUNT(WX)
           END-EVALUATE.

      *----------------------------------------------------------------
      * STATEMENT PRODUCTION (ACCOUNT FILE ORDER)
      *----------------------------------------------------------------
      *----------------------------------------------------------------
      * ONE STATEMENT PER ACCEPTED ACCOUNT, ACCOUNT FILE ORDER.
      *----------------------------------------------------------------
       5000-PRODUCE-STATEMENTS.
           PERFORM VARYING WP FROM 1 BY 1 UNTIL WP > AT-COUNT
               MOVE WP TO WB-AX
               PERFORM 5100-BILL-ACCOUNT
           END-PERFORM.

      *----------------------------------------------------------------
      * BILL ONE ACCOUNT AND PRINT ITS STATEMENT.
      *----------------------------------------------------------------
       5100-BILL-ACCOUNT.
           ADD 1 TO WS-STMT-COUNT
           MOVE 0 TO WB-BASE WB-USAGE WB-CHARGES WB-DISC WB-SUBTOTAL
                     WB-TAX WB-ADJ WB-CURRENT WB-PAY WB-DUE
                     WB-DATA-QTY WB-VOIC-QTY WB-SMS-QTY WB-ROAM-QTY
           MOVE "N" TO WB-HAS-DATA WB-HAS-VOIC WB-HAS-SMS WB-HAS-ROAM
           PERFORM 5200-BUILD-LIST
           PERFORM 5300-FINAL-PLAN
           PERFORM 5400-STATEMENT-HEADER

... [14811 more chars truncated]
```
</details>

### Step 8: Bash

```bash
docker exec sn-cobol-production-parity bash -lc 'mkdir -p /app/build /w/s1; cd /w/s1; cp /app/samples/basic/* .; /app/prod/billrun; echo rc=$?; cat -A STATEMENTS.RPT | head -80; cat REJECTS.RPT SUMMARY.RPT'
```

<details><summary>output</summary>

```
rc=0
========================================================================$
NORTHWIND TELECOM               BILLING STATEMENT  RUN 000417$
ACCOUNT AC100001  ANA ADAMS                 REGION NE$
PERIOD 2025-03-01 TO 2025-03-31  DAYS 31  PLAN B$
------------------------------------------------------------------------$
DATE       DESCRIPTION                            QTY          AMOUNT$
------------------------------------------------------------------------$
2025-03-01 BASE FEE PLAN B                     31.00         10.00$
           USAGE VOICE MIN                     42.00          2.10$
           USAGE SMS MSG                       30.00          0.90$
           SUBTOTAL                                          13.00$
           TAX N 8.25%                                        1.07$
           CURRENT CHARGES                                   14.07$
           PRIOR BALANCE                                      0.00$
------------------------------------------------------------------------$
           AMOUNT DUE                                        14.07$
========================================================================$
NORTHWIND TELECOM               BILLING STATEMENT  RUN 000417$
ACCOUNT AC100002  BEN BAKER                 REGION NE$
PERIOD 2025-03-01 TO 2025-03-31  DAYS 31  PLAN S$
------------------------------------------------------------------------$
DATE       DESCRIPTION                            QTY          AMOUNT$
------------------------------------------------------------------------$
2025-03-01 BASE FEE PLAN S                     31.00         25.00$
           USAGE DATA GB                        1.50          0.00$
2025-03-12 EQUP HANDSET CASE                                 39.99$
           LOYALTY DISCOUNT L1  5%                            1.25CR$
           SUBTOTAL                                          63.74$
           TAX N 8.25%                                        5.26$
           CURRENT CHARGES                                   69.00$
           PRIOR BALANCE                                     42.10$
2025-03-14 PAYMENT RECEIVED                                  42.10CR$
------------------------------------------------------------------------$
           AMOUNT DUE                                        69.00$
========================================================================$
NORTHWIND TELECOM               BILLING STATEMENT  RUN 000417$
ACCOUNT AC100003  CARL CHEN                 REGION NE$
PERIOD 2025-03-01 TO 2025-03-31  DAYS 31  PLAN P$
------------------------------------------------------------------------$
DATE       DESCRIPTION                            QTY          AMOUNT$
------------------------------------------------------------------------$
2025-03-01 BASE FEE PLAN P                     31.00         60.00$
           USAGE VOICE MIN                    120.00          3.60$
           SUBTOTAL                                          63.60$
           TAX R 4.00%          
... [1244 more chars truncated]
```
</details>

### Step 9: Bash

```bash
docker exec sn-cobol-production-parity bash -lc 'which python3 perl; cobc --version | head -1; nproc'
```

<details><summary>output</summary>

```
/usr/bin/python3
/usr/bin/perl
cobc (GnuCOBOL) 3.1.2.0
10
```
</details>

### Step 10: Bash

```bash
docker exec -i sn-cobol-production-parity bash -c 'cat > /w/h.py' <<'EOF'
import subprocess,os,tempfile,shutil,sys
def run(ctl,acc,act,binp="/app/prod/billrun",show=True):
    d=tempfile.mkdtemp(dir="/w")
    for n,c in (("CONTROL.DAT",ctl),("ACCOUNTS.DAT",acc),("ACTIVITY.DAT",act)):
        if c is not None:
            if isinstance(c,list): c="\n".join(c)+"\n"
            open(d+"/"+n,"w").write(c)
    p=subprocess.run([binp],cwd=d,capture_output=True)
    out={}
    for n in ("STATEMENTS.RPT","REJECTS.RPT","SUMMARY.RPT"):
        try: out[n]=open(d+"/"+n).read()
        except Exception as e: out[n]=None
    out["rc"]=p.returncode; out["stderr"]=p.stderr.decode()
    shutil.rmtree(d)
    return out
def show(o):
    for k in ("STATEMENTS.RPT","REJECTS.RPT","SUMMARY.RPT"):
        print("=="+k); print(o[k] if o[k] is None else o[k].replace(" ","."))
    print("rc",o["rc"],o["stderr"])
def acct(id="AC000001",name="TEST CUSTOMER",plan="B",op="20200101",cl="        ",tc="N",reg="NE",bal="+000000000",loy="  "):
    return f"{id:<8}{name:<24}{plan}{op:<8}{cl:<8}{tc}{reg:<2}{bal:<10}{loy:<2}"
def ctl(s="20250301",e="20250331",run="000001",co="ACME"):
    return f"{s:<8}{e:<8}{run:<6}{co:<30}"
EOF
docker exec sn-cobol-production-parity bash -lc 'cd /w; python3 - <<EOF
from h import *
for c in [None,"",ctl(s="20250332"),ctl(e="20250201"),ctl(s="2025030"),"X"*60, ctl(s="20250301",e="20250501"), ctl(s="20250301",e="20250401"),ctl(s="20250301",e="20250301")]:
    print("#####",repr(c)); show(run(c,[acct()],[]))
EOF'
```

<details><summary>output</summary>

```
##### None
==STATEMENTS.RPT

==REJECTS.RPT
BILLRUN.4.2.REJECT.REPORT..........RUN
SEQ....SRC..CODE.MESSAGE................RECORD
000001.CTL..C01..INVALID.CONTROL.RECORD
TOTAL.REJECTS.....1

==SUMMARY.RPT
BILLRUN.4.2.RUN.SUMMARY..........RUN
RUN.ABORTED.-.INVALID.CONTROL.RECORD

rc 16 
##### ''
==STATEMENTS.RPT

==REJECTS.RPT
BILLRUN.4.2.REJECT.REPORT..........RUN
SEQ....SRC..CODE.MESSAGE................RECORD
000001.CTL..C01..INVALID.CONTROL.RECORD
TOTAL.REJECTS.....1

==SUMMARY.RPT
BILLRUN.4.2.RUN.SUMMARY..........RUN
RUN.ABORTED.-.INVALID.CONTROL.RECORD

rc 16 
##### '2025033220250331000001ACME                          '
==STATEMENTS.RPT

==REJECTS.RPT
BILLRUN.4.2.REJECT.REPORT..........RUN.000001
SEQ....SRC..CODE.MESSAGE................RECORD
000001.CTL..C01..INVALID.CONTROL.RECORD.2025033220250331000001ACME
TOTAL.REJECTS.....1

==SUMMARY.RPT
BILLRUN.4.2.RUN.SUMMARY..........RUN.000001
RUN.ABORTED.-.INVALID.CONTROL.RECORD

rc 16 
##### '2025030120250201000001ACME                          '
==STATEMENTS.RPT

==REJECTS.RPT
BILLRUN.4.2.REJECT.REPORT..........RUN.000001
SEQ....SRC..CODE.MESSAGE................RECORD
000001.CTL..C01..INVALID.CONTROL.RECORD.2025030120250201000001ACME
TOTAL.REJECTS.....1

==SUMMARY.RPT
BILLRUN.4.2.RUN.SUMMARY..........RUN.000001
RUN.ABORTED.-.INVALID.CONTROL.RECORD

rc 16 
##### '2025030 20250331000001ACME                          '
==STATEMENTS.RPT

==REJECTS.RPT
BILLRUN.4.2.REJECT.REPORT..........RUN.000001
SEQ....SRC..CODE.MESSAGE................RECORD
000001.CTL..C01..INVALID.CONTROL.RECORD.2025030.20250331000001ACME
TOTAL.REJECTS.....1

==SUMMARY.RPT
BILLRUN.4.2.RUN.SUMMARY..........RUN.000001
RUN.ABORTED.-.INVALID.CONTROL.RECORD

rc 16 
##### 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
==STATEMENTS.RPT

==REJECTS.RPT
BILLRUN.4.2.REJECT.REPORT..........RUN.XXXXXX
SEQ....SRC..CODE.MESSAGE................RECORD
000001.CTL..C01..INVALID.CONTROL.RECORD.XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
TOTAL.REJECTS.....1

==SUMMARY.RPT
BILLRUN.4.2.RUN.SUMMARY..........RUN.XXXXXX
RUN.ABORTED.-.INVALID.CONTROL.RECORD

rc 16 
##### '2025030120250501000001ACME                          '
==STATEMENTS.RPT

==REJECTS.RPT
BILLRUN.4.2.REJECT.REPORT..........RUN.000001
SEQ....SRC..CODE.MESSAGE................RECORD
000001.CTL..C01..INVALID.CONTROL.RECORD.2025030120250501000001ACME
TOTAL.REJECTS.....1

==SUMMARY.RPT
BILLRUN.4.2.RUN.SUMMARY..........RUN.000001
RUN.ABORTED.-.INVALID.CONTROL.RECORD

rc 16 
##### '2025030120250401000001ACME                          '
==STATEMENTS.RPT

==REJECTS.RPT
BILLRUN.4.2.REJECT.REPORT..........RUN.000001
SEQ....SRC..CODE.MESSAGE................RECORD
000001.CTL..C01..INVALID.CONTROL.RECORD.2025030120250401000001ACME
TOTAL.REJECTS.....1

==SUMMARY.RPT
BILLRUN.4.2.RUN.SUMMARY..........RUN.000001
RUN.ABORTED.-.INVALID.CONTROL.RECORD

rc 16 
##### '2025030120250301000001ACME                          '
==STATEMENTS.RPT
====================================================================
... [1868 more chars truncated]
```
</details>

### Step 11: Bash

```bash
cd /w 2>/dev/null; docker exec sn-cobol-production-parity bash -lc 'cd /w; sed -i "s/if isinstance(c,list): c=\"\\\\n\".join(c)+\"\\\\n\"/if isinstance(c,list): c=\"\".join(x+\"\\\\n\" for x in c)/" h.py; grep -n isinstance h.py; python3 - <<EOF
from h import *
def rej(c):
    o=run(c,[],[]); print(repr(c), o["rc"], repr(o["REJECTS.RPT"]), repr((o["SUMMARY.RPT"] or "")[:60]), len(o["STATEMENTS.RPT"] or "-"))
for c in [ctl(s="20240229",e="20240229"),ctl(s="20230229",e="20230301"),ctl(s="19000229",e="19000301"),ctl(s="20000229",e="20000229"),ctl(s="21000229",e="21000301"),ctl(s="00000101",e="00000101"),ctl(s="16000101",e="16000101"),ctl(s="15991231",e="16000101"),ctl(s="99991231",e="99991231"),
 ctl(run="ABC"),ctl(run=""),ctl(co=""), ctl(s="2025-3-1"),
 "20250301202503010000ZZ", "20250301202503010", "X"*80, ctl()+"Z"*20, ctl(s="20250301",e="20250331"), ctl(s="20250301",e="20250401"), ctl(s="20250301",e="20250331")+"\n"+ctl()]:
    rej(c)
EOF'
```

<details><summary>output</summary>

```
6:            if isinstance(c,list): c="".join(x+"\n" for x in c)
'2024022920240229000001ACME                          ' 0 'BILLRUN 4.2 REJECT REPORT          RUN 000001\nSEQ    SRC  CODE MESSAGE                RECORD\nTOTAL REJECTS     0\n' 'BILLRUN 4.2 RUN SUMMARY          RUN 000001\nCOMPANY ACME\nACC' 1
'2023022920230301000001ACME                          ' 16 'BILLRUN 4.2 REJECT REPORT          RUN 000001\nSEQ    SRC  CODE MESSAGE                RECORD\n000001 CTL  C01  INVALID CONTROL RECORD 2023022920230301000001ACME\nTOTAL REJECTS     1\n' 'BILLRUN 4.2 RUN SUMMARY          RUN 000001\nRUN ABORTED - IN' 1
'1900022919000301000001ACME                          ' 16 'BILLRUN 4.2 REJECT REPORT          RUN 000001\nSEQ    SRC  CODE MESSAGE                RECORD\n000001 CTL  C01  INVALID CONTROL RECORD 1900022919000301000001ACME\nTOTAL REJECTS     1\n' 'BILLRUN 4.2 RUN SUMMARY          RUN 000001\nRUN ABORTED - IN' 1
'2000022920000229000001ACME                          ' 0 'BILLRUN 4.2 REJECT REPORT          RUN 000001\nSEQ    SRC  CODE MESSAGE                RECORD\nTOTAL REJECTS     0\n' 'BILLRUN 4.2 RUN SUMMARY          RUN 000001\nCOMPANY ACME\nACC' 1
'2100022921000301000001ACME                          ' 16 'BILLRUN 4.2 REJECT REPORT          RUN 000001\nSEQ    SRC  CODE MESSAGE                RECORD\n000001 CTL  C01  INVALID CONTROL RECORD 2100022921000301000001ACME\nTOTAL REJECTS     1\n' 'BILLRUN 4.2 RUN SUMMARY          RUN 000001\nRUN ABORTED - IN' 1
'0000010100000101000001ACME                          ' 16 'BILLRUN 4.2 REJECT REPORT          RUN 000001\nSEQ    SRC  CODE MESSAGE                RECORD\n000001 CTL  C01  INVALID CONTROL RECORD 0000010100000101000001ACME\nTOTAL REJECTS     1\n' 'BILLRUN 4.2 RUN SUMMARY          RUN 000001\nRUN ABORTED - IN' 1
'1600010116000101000001ACME                          ' 16 'BILLRUN 4.2 REJECT REPORT          RUN 000001\nSEQ    SRC  CODE MESSAGE                RECORD\n000001 CTL  C01  INVALID CONTROL RECORD 1600010116000101000001ACME\nTOTAL REJECTS     1\n' 'BILLRUN 4.2 RUN SUMMARY          RUN 000001\nRUN ABORTED - IN' 1
'1599123116000101000001ACME                          ' 16 'BILLRUN 4.2 REJECT REPORT          RUN 000001\nSEQ    SRC  CODE MESSAGE                RECORD\n000001 CTL  C01  INVALID CONTROL RECORD 1599123116000101000001ACME\nTOTAL REJECTS     1\n' 'BILLRUN 4.2 RUN SUMMARY          RUN 000001\nRUN ABORTED - IN' 1
'9999123199991231000001ACME                          ' 0 'BILLRUN 4.2 REJECT REPORT          RUN 000001\nSEQ    SRC  CODE MESSAGE                RECORD\nTOTAL REJECTS     0\n' 'BILLRUN 4.2 RUN SUMMARY          RUN 000001\nCOMPANY ACME\nACC' 1
'2025030120250331ABC   ACME                          ' 0 'BILLRUN 4.2 REJECT REPORT          RUN ABC\nSEQ    SRC  CODE MESSAGE                RECORD\nTOTAL REJECTS     0\n' 'BILLRUN 4.2 RUN SUMMARY          RUN ABC\nCOMPANY ACME\nACCOUN' 1
'2025030120250331      ACME                          ' 0 'BILLRUN 4.2 REJECT REPORT          RUN\nS
... [2573 more chars truncated]
```
</details>

### Step 12: Bash

```bash
cd /w; docker exec sn-cobol-production-parity bash -lc 'cd /w; python3 - <<EOF
from h import *
A=[acct(id="OK000001"),
acct(id="        "),
acct(id="OK000001"),
acct(id="OK000002",plan="X"),
acct(id="OK000003",plan=" "),
acct(id="OK000004",op="20250230"),
acct(id="OK000005",op="        "),
acct(id="OK000006",op="20260101"),
acct(id="OK000007",cl="20250230"),
acct(id="OK000008",cl="00000000"),
acct(id="OK000009",cl="20240101"),
acct(id="OK000010",cl="20250315"),
acct(id="OK000011",tc="X"),
acct(id="OK000012",tc=" "),
acct(id="OK000013",bal="+00000000A"),
acct(id="OK000014",bal="x000000100"),
acct(id="OK000015",bal="000000100 "),
acct(id="OK000016",bal="          "),
acct(id="OK000017",loy="L3"),
acct(id="OK000018",loy="L9"),
acct(id="OK000019",loy="L1"),
acct(id="OK000020",reg="  "),
acct(id="OK000021",reg="1x"),
acct(id="ok000022"),
acct(id="OK 00023"),
acct(id="OK000024",op="20250315",cl="20250310"),
acct(id="OK000025",plan="b"),
]
show(run(ctl(),A,[]))
EOF'
```

<details><summary>output</summary>

```
(eval):cd:1: no such file or directory: /w
==STATEMENTS.RPT
========================================================================
ACME............................BILLING.STATEMENT..RUN.000001
ACCOUNT.OK000020..TEST.CUSTOMER.............REGION
PERIOD.2025-03-01.TO.2025-03-31..DAYS.31..PLAN.B
------------------------------------------------------------------------
DATE.......DESCRIPTION............................QTY..........AMOUNT
------------------------------------------------------------------------
...........NO.ACTIVITY.THIS.PERIOD
2025-03-01.BASE.FEE.PLAN.B.....................31.00.........10.00
...........SUBTOTAL..........................................10.00
...........TAX.N.8.25%........................................0.83
...........CURRENT.CHARGES...................................10.83
...........PRIOR.BALANCE......................................0.00
------------------------------------------------------------------------
...........AMOUNT.DUE........................................10.83
========================================================================
ACME............................BILLING.STATEMENT..RUN.000001
ACCOUNT.OK000021..TEST.CUSTOMER.............REGION.1x
PERIOD.2025-03-01.TO.2025-03-31..DAYS.31..PLAN.B
------------------------------------------------------------------------
DATE.......DESCRIPTION............................QTY..........AMOUNT
------------------------------------------------------------------------
...........NO.ACTIVITY.THIS.PERIOD
2025-03-01.BASE.FEE.PLAN.B.....................31.00.........10.00
...........SUBTOTAL..........................................10.00
...........TAX.N.8.25%........................................0.83
...........CURRENT.CHARGES...................................10.83
...........PRIOR.BALANCE......................................0.00
------------------------------------------------------------------------
...........AMOUNT.DUE........................................10.83
========================================================================
ACME............................BILLING.STATEMENT..RUN.000001
ACCOUNT.OK.00023..TEST.CUSTOMER.............REGION.NE
PERIOD.2025-03-01.TO.2025-03-31..DAYS.31..PLAN.B
------------------------------------------------------------------------
DATE.......DESCRIPTION............................QTY..........AMOUNT
------------------------------------------------------------------------
...........NO.ACTIVITY.THIS.PERIOD
2025-03-01.BASE.FEE.PLAN.B.....................31.00.........10.00
...........SUBTOTAL..........................................10.00
...........TAX.N.8.25%........................................0.83
...........CURRENT.CHARGES...................................10.83
...........PRIOR.BALANCE......................................0.00
------------------------------------------------------------------------
...........AMOUNT.DUE........................................10.83
===================================================
... [9276 more chars truncated]
```
</details>

### Step 13: Bash

```bash
cd /w; docker exec sn-cobol-production-parity bash -lc 'cd /w; python3 - <<EOF
from h import *
import itertools
defs={"A01":dict(id="        "),"A03":dict(plan="X"),"A04":dict(op="2025023x"),"A05":dict(cl="2025023x"),"A06":dict(tc="X"),"A07":dict(bal="+0000000x0")}
# dup needs a prior; do separately
codes=list(defs)
for n in (2,3):
  for combo in itertools.combinations(codes,n):
    kw={}
    for c in combo: kw.update(defs[c])
    A=[acct(id="DUP00001")]
    kw2=dict(kw); 
    o=run(ctl(),[acct(**{**dict(id="Q0000001"),**kw2})],[])
    import re
    m=re.findall(r"^\d+ ACC  (A\d\d)",o["REJECTS.RPT"],re.M)
    print(combo,m)
# dup
for c in codes:
    if c=="A01": continue
    kw=dict(defs[c]); kw["id"]="DUP00001"
    o=run(ctl(),[acct(id="DUP00001"),acct(**kw)],[])
    print("dup+",c,re.findall(r"^\d+ ACC  (A\d\d)",o["REJECTS.RPT"],re.M))
# dup where the first is rejected
o=run(ctl(),[acct(id="DUP00001",plan="X"),acct(id="DUP00001")],[]);print(o["REJECTS.RPT"])
o=run(ctl(),[acct(id="DUP00001",cl="20240101"),acct(id="DUP00001")],[]);print(o["REJECTS.RPT"])
o=run(ctl(),[acct(id="DUP00001"),acct(id="DUP00001 ")],[]);print(o["REJECTS.RPT"])
EOF'
```

<details><summary>output</summary>

```
(eval):cd:1: no such file or directory: /w
('A01', 'A03') ['A01']
('A01', 'A04') ['A01']
('A01', 'A05') ['A01']
('A01', 'A06') ['A01']
('A01', 'A07') ['A01']
('A03', 'A04') ['A03']
('A03', 'A05') ['A03']
('A03', 'A06') ['A03']
('A03', 'A07') ['A03']
('A04', 'A05') ['A04']
('A04', 'A06') ['A04']
('A04', 'A07') ['A04']
('A05', 'A06') ['A05']
('A05', 'A07') ['A05']
('A06', 'A07') ['A06']
('A01', 'A03', 'A04') ['A01']
('A01', 'A03', 'A05') ['A01']
('A01', 'A03', 'A06') ['A01']
('A01', 'A03', 'A07') ['A01']
('A01', 'A04', 'A05') ['A01']
('A01', 'A04', 'A06') ['A01']
('A01', 'A04', 'A07') ['A01']
('A01', 'A05', 'A06') ['A01']
('A01', 'A05', 'A07') ['A01']
('A01', 'A06', 'A07') ['A01']
('A03', 'A04', 'A05') ['A03']
('A03', 'A04', 'A06') ['A03']
('A03', 'A04', 'A07') ['A03']
('A03', 'A05', 'A06') ['A03']
('A03', 'A05', 'A07') ['A03']
('A03', 'A06', 'A07') ['A03']
('A04', 'A05', 'A06') ['A04']
('A04', 'A05', 'A07') ['A04']
('A04', 'A06', 'A07') ['A04']
('A05', 'A06', 'A07') ['A05']
dup+ A03 ['A02']
dup+ A04 ['A02']
dup+ A05 ['A02']
dup+ A06 ['A02']
dup+ A07 ['A02']
BILLRUN 4.2 REJECT REPORT          RUN 000001
SEQ    SRC  CODE MESSAGE                RECORD
000001 ACC  A03  INVALID PLAN           DUP00001TEST CUSTOMER           X2020010
TOTAL REJECTS     1

BILLRUN 4.2 REJECT REPORT          RUN 000001
SEQ    SRC  CODE MESSAGE                RECORD
000002 ACC  A02  DUPLICATE ACCOUNT      DUP00001TEST CUSTOMER           B2020010
TOTAL REJECTS     1

BILLRUN 4.2 REJECT REPORT          RUN 000001
SEQ    SRC  CODE MESSAGE                RECORD
000002 ACC  A02  DUPLICATE ACCOUNT      DUP00001 TEST CUSTOMER           B202001
TOTAL REJECTS     1
```
</details>

### Step 14: Bash

```bash
cd /w; docker exec sn-cobol-production-parity bash -lc 'cd /w; python3 - <<EOF
from h import *
import re
def codes(a,act=[],c=None):
    o=run(c or ctl(),a,act)
    return re.findall(r"^(\d+) (ACC|ACT|CTL)  (\S+)",o["REJECTS.RPT"],re.M), o
for d in ["16000101","16010101","16010102","18991231","19000101","00000000","99991231","20250229","20240229","20000229","19000229","20251301","20250001","20250100","20250431","20250132"]:
    r,o=codes([acct(op=d)]); print("open",d,r, "billed" if "BASE FEE" in o["STATEMENTS.RPT"] else "nostmt")
for cl in ["20250228","20250301","20250302","20250331","20250401","00000000","        ","0000000 ","2025    ","20200101","20190101"]:
    r,o=codes([acct(op="20200101",cl=cl)]); 
    m=re.search(r"ACCOUNTS NOT IN CYCLE\s+(\d)",o["SUMMARY.RPT"]); print("close",repr(cl),r, "billed" if "BASE FEE" in o["STATEMENTS.RPT"] else "nostmt", m and m.group(1))
for op in ["20250301","20250302","20250331","20250401","20250228"]:
    r,o=codes([acct(op=op)]); 
    print("open",op,r, "billed" if "BASE FEE" in o["STATEMENTS.RPT"] else "nostmt", re.findall(r"BASE FEE.*",o["STATEMENTS.RPT"]))
for op,cl in [("20250310","20250310"),("20250310","20250309"),("20250310","20250311")]:
    r,o=codes([acct(op=op,cl=cl)]); 
    print("open",op,cl,r, re.findall(r"BASE FEE.*",o["STATEMENTS.RPT"]))
EOF'
```

<details><summary>output</summary>

```
(eval):cd:1: no such file or directory: /w
open 16000101 [('000001', 'ACC', 'A04')] nostmt
open 16010101 [('000001', 'ACC', 'A04')] nostmt
open 16010102 [('000001', 'ACC', 'A04')] nostmt
open 18991231 [('000001', 'ACC', 'A04')] nostmt
open 19000101 [] billed
open 00000000 [('000001', 'ACC', 'A04')] nostmt
open 99991231 [] nostmt
open 20250229 [('000001', 'ACC', 'A04')] nostmt
open 20240229 [] billed
open 20000229 [] billed
open 19000229 [('000001', 'ACC', 'A04')] nostmt
open 20251301 [('000001', 'ACC', 'A04')] nostmt
open 20250001 [('000001', 'ACC', 'A04')] nostmt
open 20250100 [('000001', 'ACC', 'A04')] nostmt
open 20250431 [('000001', 'ACC', 'A04')] nostmt
open 20250132 [('000001', 'ACC', 'A04')] nostmt
close '20250228' [] nostmt 1
close '20250301' [] billed 0
close '20250302' [] billed 0
close '20250331' [] billed 0
close '20250401' [] billed 0
close '00000000' [] billed 0
close '        ' [] billed 0
close '0000000 ' [('000001', 'ACC', 'A05')] nostmt 0
close '2025    ' [('000001', 'ACC', 'A05')] nostmt 0
close '20200101' [] nostmt 1
close '20190101' [('000001', 'ACC', 'A05')] nostmt 0
open 20250301 [] billed ['BASE FEE PLAN B                     31.00         10.00']
open 20250302 [] billed ['BASE FEE PLAN B                     30.00          9.68']
open 20250331 [] billed ['BASE FEE PLAN B                      1.00          0.32']
open 20250401 [] nostmt []
open 20250228 [] billed ['BASE FEE PLAN B                     31.00         10.00']
open 20250310 20250310 [] ['BASE FEE PLAN B                      1.00          0.32']
open 20250310 20250309 [('000001', 'ACC', 'A05')] []
open 20250310 20250311 [] ['BASE FEE PLAN B                      2.00          0.65']
```
</details>

### Step 15: Bash

```bash
cd /w; docker exec sn-cobol-production-parity bash -lc 'cd /w; cat >> h.py <<EOF
def us(a="AC000001",d="20250310",svc="VOIC",q="000001000",t="US"): return f"{t:<2}{a:<8}{d:<8}{svc:<4}{q:<9}"
def ch(a="AC000001",d="20250310",code="MISC",amt="+000001000",desc="SOME CHARGE",t="CH"): return f"{t:<2}{a:<8}{d:<8}{code:<4}{amt:<10}{desc:<20}"
def pc(a="AC000001",d="20250310",p="S"): return f"PC{a:<8}{d:<8}{p}"
def py(a="AC000001",d="20250310",m="CARD",amt="+000001000"): return f"PY{a:<8}{d:<8}{m:<4}{amt:<10}"
def ad(a="AC000001",d="20250310",amt="+000001000",reason="REASON"): return f"AD{a:<8}{d:<8}    {amt:<10}{reason:<20}"
def ds(a="AC000001",d="20250310",k="P",v="+000001500"): return f"DS{a:<8}{d:<8}{k}   {v:<10}"
def su(a="AC000001",d="20250310",e="20250312"): return f"SU{a:<8}{d:<8}{e:<8}"
import re
def rj(o):
    print(o["REJECTS.RPT"]); 
EOF
python3 - <<EOF
from h import *
A=[acct(id="AC000001")]
act=[us(t="XX"),us(t="  "),us(a="NOACCT01"),us(d="20250230"),us(d="        "),us(d="20250228"),us(d="20250401"),us(d="20250301"),us(d="20250331"),
us(svc="XXXX"),us(q="00000x000"),us(q="         "),ch(code="XXXX"),ch(amt="+00000000x"),ch(amt="          "),ch(amt="1000000000"),
pc(p="X"),pc(p=" "),py(amt="+00000000x"),py(m="    "),py(m="XXXX"),ad(amt="+00000000x"),ad(reason=""),
ds(k="X"),ds(v="+00000x000"),ds(k="P",v="+000010001"),ds(k="F",v="-000001000"),ds(k="P",v="-000000100"),su(e="20250230"),su(e="20250301",d="20250310"),su(e="20250310",d="20250310"),su(e="20250401"),su(e="20250200",d="20250301")]
o=run(ctl(),A,act); rj(o); print(o["SUMMARY.RPT"])
EOF'
```

<details><summary>output</summary>

```
(eval):cd:1: no such file or directory: /w
BILLRUN 4.2 REJECT REPORT          RUN 000001
SEQ    SRC  CODE MESSAGE                RECORD
000001 ACT  R01  UNKNOWN RECORD TYPE    XXAC00000120250310VOIC000001000
000002 ACT  R01  UNKNOWN RECORD TYPE      AC00000120250310VOIC000001000
000003 ACT  R02  UNKNOWN ACCOUNT        USNOACCT0120250310VOIC000001000
000004 ACT  R03  INVALID DATE           USAC00000120250230VOIC000001000
000005 ACT  R03  INVALID DATE           USAC000001        VOIC000001000
000006 ACT  R04  DATE OUTSIDE CYCLE     USAC00000120250228VOIC000001000
000007 ACT  R04  DATE OUTSIDE CYCLE     USAC00000120250401VOIC000001000
000010 ACT  R06  INVALID CODE           USAC00000120250310XXXX000001000
000011 ACT  R05  INVALID AMOUNT         USAC00000120250310VOIC00000x000
000012 ACT  R05  INVALID AMOUNT         USAC00000120250310VOIC
000013 ACT  R06  INVALID CODE           CHAC00000120250310XXXX+000001000SOME CHA
000014 ACT  R05  INVALID AMOUNT         CHAC00000120250310MISC+00000000xSOME CHA
000015 ACT  R05  INVALID AMOUNT         CHAC00000120250310MISC          SOME CHA
000016 ACT  R05  INVALID AMOUNT         CHAC00000120250310MISC1000000000SOME CHA
000017 ACT  R09  INVALID PLAN CHANGE    PCAC00000120250310X
000018 ACT  R09  INVALID PLAN CHANGE    PCAC00000120250310
000019 ACT  R05  INVALID AMOUNT         PYAC00000120250310CARD+00000000x
000022 ACT  R05  INVALID AMOUNT         ADAC00000120250310    +00000000xREASON
000024 ACT  R11  INVALID DISCOUNT       DSAC00000120250310X   +000001500
000025 ACT  R05  INVALID AMOUNT         DSAC00000120250310P   +00000x000
000026 ACT  R11  INVALID DISCOUNT       DSAC00000120250310P   +000010001
000027 ACT  R11  INVALID DISCOUNT       DSAC00000120250310F   -000001000
000028 ACT  R11  INVALID DISCOUNT       DSAC00000120250310P   -000000100
000029 ACT  R12  INVALID SUSPENSION     SUAC0000012025031020250230
000030 ACT  R12  INVALID SUSPENSION     SUAC0000012025031020250301
000033 ACT  R12  INVALID SUSPENSION     SUAC0000012025030120250200
TOTAL REJECTS    26

BILLRUN 4.2 RUN SUMMARY          RUN 000001
COMPANY ACME
ACCOUNTS READ                     1
ACCOUNTS BILLED                   1
ACCOUNTS NOT IN CYCLE             0
ACCOUNTS REJECTED                 0
ACTIVITY READ                    33
ACTIVITY ACCEPTED                 7
ACTIVITY REJECTED                26
STATEMENTS PRODUCED               1
REJECTS BY CODE
  R01 UNKNOWN RECORD TYPE         2
  R02 UNKNOWN ACCOUNT             1
  R03 INVALID DATE                2
  R04 DATE OUTSIDE CYCLE          2
  R05 INVALID AMOUNT              8
  R06 INVALID CODE                2
  R09 INVALID PLAN CHANGE         2
  R11 INVALID DISCOUNT            4
  R12 INVALID SUSPENSION          3
TOTAL BASE FEES                     6.45
TOTAL USAGE                         1.00
TOTAL CHARGES                       0.00
TOTAL DISCOUNTS                     0.00
TOTAL TAX                           0.61
TOTAL ADJUSTMENTS                  10.00
TOTAL PAYMENTS                     20.00
... [103 more chars truncated]
```
</details>

### Step 16: Bash

```bash
cd /w; docker exec sn-cobol-production-parity bash -lc 'cd /w; python3 - <<EOF
from h import *
A=[acct(id="AC000001"),acct(id="AC000002",cl="20250228"),acct(id="AC000003",op="20250401"),acct(id="AC000004",op="20250315",cl="20250320")]
act=[us(),us(),us(q="000002000"),ch(),ch(),ch(desc="OTHER"),py(),py(),py(m="CASH"),ad(),ad(),ad(reason="X"),pc(),pc(),pc(p="B"),ds(),ds(),su(),su(),
 py(amt="-000001000"),py(amt="+000000000"),py(amt="+000000001"),py(amt="-000000000"),
 us(a="AC000002",d="20250301"),us(a="AC000002"),us(a="AC000003",d="20250401"), us(a="AC000003"),
 us(a="AC000004",d="20250314"),us(a="AC000004",d="20250315"),us(a="AC000004",d="20250320"),us(a="AC000004",d="20250321"),
 ]
o=run(ctl(),A,act); rj(o); print(o["SUMMARY.RPT"])
EOF'
```

<details><summary>output</summary>

```
(eval):cd:1: no such file or directory: /w
BILLRUN 4.2 REJECT REPORT          RUN 000001
SEQ    SRC  CODE MESSAGE                RECORD
000002 ACT  R07  DUPLICATE ACTIVITY     USAC00000120250310VOIC000001000
000005 ACT  R07  DUPLICATE ACTIVITY     CHAC00000120250310MISC+000001000SOME CHA
000008 ACT  R07  DUPLICATE ACTIVITY     PYAC00000120250310CARD+000001000
000011 ACT  R07  DUPLICATE ACTIVITY     ADAC00000120250310    +000001000REASON
000014 ACT  R07  DUPLICATE ACTIVITY     PCAC00000120250310S
000017 ACT  R07  DUPLICATE ACTIVITY     DSAC00000120250310P   +000001500
000019 ACT  R07  DUPLICATE ACTIVITY     SUAC0000012025031020250312
000020 ACT  R10  INVALID PAYMENT        PYAC00000120250310CARD-000001000
000021 ACT  R10  INVALID PAYMENT        PYAC00000120250310CARD+000000000
000023 ACT  R10  INVALID PAYMENT        PYAC00000120250310CARD-000000000
000024 ACT  R08  ACCOUNT NOT ACTIVE     USAC00000220250301VOIC000001000
000025 ACT  R08  ACCOUNT NOT ACTIVE     USAC00000220250310VOIC000001000
000026 ACT  R04  DATE OUTSIDE CYCLE     USAC00000320250401VOIC000001000
000027 ACT  R08  ACCOUNT NOT ACTIVE     USAC00000320250310VOIC000001000
000028 ACT  R08  ACCOUNT NOT ACTIVE     USAC00000420250314VOIC000001000
000031 ACT  R08  ACCOUNT NOT ACTIVE     USAC00000420250321VOIC000001000
TOTAL REJECTS    16

BILLRUN 4.2 RUN SUMMARY          RUN 000001
COMPANY ACME
ACCOUNTS READ                     4
ACCOUNTS BILLED                   2
ACCOUNTS NOT IN CYCLE             2
ACCOUNTS REJECTED                 0
ACTIVITY READ                    31
ACTIVITY ACCEPTED                15
ACTIVITY REJECTED                16
STATEMENTS PRODUCED               2
REJECTS BY CODE
  R04 DATE OUTSIDE CYCLE          1
  R07 DUPLICATE ACTIVITY          7
  R08 ACCOUNT NOT ACTIVE          5
  R10 INVALID PAYMENT             3
TOTAL BASE FEES                    11.46
TOTAL USAGE                         2.50
TOTAL CHARGES                      20.00
TOTAL DISCOUNTS                     4.65
TOTAL TAX                           2.42
TOTAL ADJUSTMENTS                  20.00
TOTAL PAYMENTS                     20.01
TOTAL AMOUNT DUE                   31.72
AMOUNT DUE BY REGION
  REGION NE                        31.72
```
</details>

### Step 17: Bash

```bash
cd /w; docker exec sn-cobol-production-parity bash -lc 'cd /w; python3 - <<EOF
from h import *
import re
def dups(recs,tag):
    o=run(ctl(),[acct(id="AC000001")],recs)
    r=re.findall(r"^(\d+) ACT  (R\d\d)",o["REJECTS.RPT"],re.M)
    print(tag,r)
# each pair; second record differs from the first
def pair(a,b,tag): dups([a,b],tag)
pair(us(),us()+"GARBAGE","US trailing garbage")
pair(us(q="000001000"),us(q="000001000").replace("US","US"),"same")
pair(ch(),ch()+"TRAIL","CH trailing")
pair(ch(amt="+000001000"),ch(amt=" 000001000"),"CH sign blank vs +")
pair(ch(amt="+000001000"),ch(amt="*000001000"),"CH sign * vs +")
pair(ch(amt="+000000000"),ch(amt="-000000000"),"CH -0 vs +0")
pair(ch(desc="ABC"),ch(desc="ABC "),"desc trailing space")
pair(ch(desc="abc"),ch(desc="ABC"),"desc case")
pair(py(),py()+"TRAIL","PY trailing")
pair(py(),py(m="XXXX"),"PY method")
pair(py(amt="+000001000"),py(amt=" 000001000"),"PY sign")
pair(ad(),ad()+"TRAIL","AD trailing")
pair(ad(),"AD"+"AC000001"+"20250310"+"XXXX"+"+000001000"+"REASON","AD cols19-22")
pair(pc(),pc()+"TRAIL","PC trailing")
pair(ds(),ds()+"TRAIL","DS trailing")
pair(ds(),"DS"+"AC000001"+"20250310"+"P"+"XXX"+"+000001500","DS cols 20-22")
pair(ds(k="P",v="+000001500"),ds(k="P",v=" 000001500"),"DS sign")
pair(su(),su()+"TRAIL","SU trailing")
pair(ds(k="F",v="+000001500"),ds(k="P",v="+000001500"),"DS kind")
pair(su(e="20250312"),su(e="20250313"),"SU end")
pair(su(d="20250310",e="20250312"),su(d="20250310",e="20250312"),"SU same")
# type mismatch same key
pair(us(),ch(),"us vs ch")
EOF'
```

<details><summary>output</summary>

```
(eval):cd:1: no such file or directory: /w
US trailing garbage []
same [('000002', 'R07')]
CH trailing []
CH sign blank vs + [('000002', 'R05')]
CH sign * vs + [('000002', 'R05')]
CH -0 vs +0 []
desc trailing space [('000002', 'R07')]
desc case []
PY trailing []
PY method []
PY sign [('000002', 'R05')]
AD trailing []
AD cols19-22 []
PC trailing []
DS trailing []
DS cols 20-22 []
DS sign [('000002', 'R05')]
SU trailing []
DS kind []
SU end []
SU same [('000002', 'R07')]
us vs ch []
```
</details>

### Step 18: Bash

```bash
cd /w; docker exec sn-cobol-production-parity bash -lc 'cd /w; python3 - <<EOF
from h import *
import re
def t(recs,tag,accts=None):
    o=run(ctl(),accts or [acct(id="AC000001")],recs)
    r=re.findall(r"^(\d+) ACT  (R\d\d)",o["REJECTS.RPT"],re.M)
    print(tag,r)
b=us(q="00000x000"); t([b,b],"R05 pair")
b=us(d="20250230"); t([b,b],"R03 pair")
b=us(d="20250401"); t([b,b],"R04 pair")
b=us(svc="XXXX"); t([b,b],"R06 pair")
b=pc(p="X"); t([b,b],"R09")
b=py(amt="-000001000"); t([b,b],"R10")
b=ds(k="X"); t([b,b],"R11")
b=su(e="20250230"); t([b,b],"R12")
b=us(a="AC000002"); t([b,b],"R08",[acct(id="AC000001"),acct(id="AC000002",cl="20250101")])
b=us(a="NOACCT01"); t([b,b],"R02")
b="ZZ"+us()[2:]; t([b,b],"R01")
EOF'
```

<details><summary>output</summary>

```
(eval):cd:1: no such file or directory: /w
R05 pair [('000001', 'R05'), ('000002', 'R05')]
R03 pair [('000001', 'R03'), ('000002', 'R03')]
R04 pair [('000001', 'R04'), ('000002', 'R04')]
R06 pair [('000001', 'R06'), ('000002', 'R06')]
R09 [('000001', 'R09'), ('000002', 'R09')]
R10 [('000001', 'R10'), ('000002', 'R10')]
R11 [('000001', 'R11'), ('000002', 'R11')]
R12 [('000001', 'R12'), ('000002', 'R12')]
R08 [('000001', 'R08'), ('000002', 'R08')]
R02 [('000001', 'R02'), ('000002', 'R02')]
R01 [('000001', 'R01'), ('000002', 'R01')]
```
</details>

### Step 19: Bash

```bash
cd /w; docker exec sn-cobol-production-parity bash -lc 'cd /w; python3 - <<EOF
from h import *
import re
AC=[acct(id="AC000001"),acct(id="AC000002",cl="20250101")]
def t(recs,tag):
    o=run(ctl(),AC,recs)
    r=re.findall(r"^(\d+) ACT  (R\d\d)",o["REJECTS.RPT"],re.M)
    print(tag,r)
t([us(a="NOACCT01",d="20250230")],"R02+R03")
t([us(a="NOACCT01",svc="XXXX")],"R02+R06")
t([us(a="NOACCT01",d="20250401")],"R02+R04")
t([us(d="20250401",svc="XXXX")],"R04+R06")
t([us(d="20250401",q="0000x0000")],"R04+R05")
t([us(a="AC000002",svc="XXXX")],"R08+R06")
t([us(a="AC000002",q="0000x0000")],"R08+R05")
t([us(a="AC000002",d="20250401",q="0000x0000")],"R08+R04+R05")
t([ch(a="AC000002",code="XXXX",amt="+0000x0000")],"R08+R06+R05")
t([ch(code="XXXX",amt="+0000x0000")],"R06+R05")
t([ch(amt="*000000000")],"bad sign")
t([py(a="AC000002",amt="-000001000")],"R08+R10")
t([py(amt="-0000x0000")],"R10+R05?")
t([py(amt="+0000x0000")],"R05")
t([py(amt="*000001000")],"bad sign PY")
t([pc(a="AC000002",p="X")],"R08+R09")
t([ds(a="AC000002",k="X")],"R08+R11")
t([ds(k="X",v="+0000x0000")],"R11+R05")
t([ds(k="P",v="-0000x0000")],"R11neg+R05")
t([ds(k="P",v="+0000x0000")],"R05")
t([ds(k="X",v="*000001000")],"Xsign")
t([ds(k="P",v="*000001000")],"Psign")
t([su(a="AC000002",e="20250230")],"R08+R12")
t([su(d="20250401",e="20250230")],"R04+R12")
t([ad(amt="*000001000")],"AD sign")
t([ad(amt="-000001000")],"AD neg ok")
EOF'
```

<details><summary>output</summary>

```
(eval):cd:1: no such file or directory: /w
R02+R03 [('000001', 'R02')]
R02+R06 [('000001', 'R02')]
R02+R04 [('000001', 'R02')]
R04+R06 [('000001', 'R04')]
R04+R05 [('000001', 'R04')]
R08+R06 [('000001', 'R08')]
R08+R05 [('000001', 'R08')]
R08+R04+R05 [('000001', 'R04')]
R08+R06+R05 [('000001', 'R08')]
R06+R05 [('000001', 'R06')]
bad sign [('000001', 'R05')]
R08+R10 [('000001', 'R08')]
R10+R05? [('000001', 'R05')]
R05 [('000001', 'R05')]
bad sign PY [('000001', 'R05')]
R08+R09 [('000001', 'R08')]
R08+R11 [('000001', 'R08')]
R11+R05 [('000001', 'R11')]
R11neg+R05 [('000001', 'R05')]
R05 [('000001', 'R05')]
Xsign [('000001', 'R11')]
Psign [('000001', 'R05')]
R08+R12 [('000001', 'R08')]
R04+R12 [('000001', 'R04')]
AD sign [('000001', 'R05')]
AD neg ok []
```
</details>

### Step 20: Bash

```bash
cd /w; docker exec sn-cobol-production-parity bash -lc 'cd /w; python3 - <<EOF
from h import *
import re
def t(recs,tag):
    o=run(ctl(),[acct(id="AC000001",plan="B")],recs)
    r=re.findall(r"^(\d+) ACT  (R\d\d)",o["REJECTS.RPT"],re.M)
    print(tag,r)
for q in ["000000000","999999999"]: t([us(q=q)],"us qty "+q)
t([ch(amt="+000000000")],"ch zero"); t([ch(amt="-000000000")],"ch -zero");t([ch(amt="+999999999")],"ch max")
t([ad(amt="+000000000")],"ad zero")
for k,v in [("P","+000000000"),("P","+000000001"),("P","+000009999"),("P","+000010000"),("P","+000010001"),("F","+000000000"),("F","+000000001"),("F","+999999999"),("P","-000000000"),("F","-000000000"),("p","+000001000"),(" ","+000001000")]:
    t([ds(k=k,v=v)],f"ds {k} {v}")
t([pc(p="B")],"pc to same plan"); t([pc(p="S")],"pc S"); t([pc(p="P")],"pc P");t([pc(p="s")],"pc s")
t([su(d="20250310",e="20250309")],"su e<d"); t([su(d="20250310",e="20250310")],"su e==d");t([su(d="20250310",e="20250401")],"su e>end");t([su(d="20250310",e="99991231")],"su e 9999");t([su(d="20250310",e="18991231")],"su e 1899");t([su(d="20250310",e="        ")],"su e blank");t([su(d="20250310",e="00000000")],"su e zero")
t([su(d="20250310",e="2025031 ")],"su e 7digits")
EOF'
```

<details><summary>output</summary>

```
(eval):cd:1: no such file or directory: /w
us qty 000000000 []
us qty 999999999 []
ch zero []
ch -zero []
ch max []
ad zero []
ds P +000000000 [('000001', 'R11')]
ds P +000000001 []
ds P +000009999 []
ds P +000010000 []
ds P +000010001 [('000001', 'R11')]
ds F +000000000 [('000001', 'R11')]
ds F +000000001 []
ds F +999999999 []
ds P -000000000 [('000001', 'R11')]
ds F -000000000 [('000001', 'R11')]
ds p +000001000 [('000001', 'R11')]
ds   +000001000 [('000001', 'R11')]
pc to same plan []
pc S []
pc P []
pc s [('000001', 'R09')]
su e<d [('000001', 'R12')]
su e==d []
su e>end []
su e 9999 []
su e 1899 [('000001', 'R12')]
su e blank [('000001', 'R12')]
su e zero [('000001', 'R12')]
su e 7digits [('000001', 'R12')]
```
</details>

### Step 21: Bash

```bash
cd /w; docker exec sn-cobol-production-parity bash -lc 'cd /w; python3 - <<EOF
from h import *
A=[acct(id="AC000001",plan="B",loy="L1")]
act=[us(d="20250305",svc="DATA",q="000001500"),us(d="20250306",svc="DATA",q="000002500"),us(d="20250307",svc="VOIC",q="000010030"),us(d="20250308",svc="SMS ",q="000005000"),us(d="20250309",svc="ROAM",q="000010000"),
 ch(d="20250320",code="EQUP",amt="+000001999",desc="PHONE"),ch(d="20250312",code="LATE",amt="+000000500",desc="LATE FEE"),ch(d="20250312",code="DEPO",amt="+000005000",desc="DEPOSIT"),
 pc(d="20250315",p="P"),pc(d="20250322",p="S"),
 ds(d="20250311",k="P",v="+000001500"),ds(d="20250316",k="F",v="+000000250"),
 su(d="20250324",e="20250326"),
 py(d="20250328",amt="+000000500"),ad(d="20250327",amt="-000000300",reason="GOODWILL")]
o=run(ctl(),A,act); show(o)
EOF'
```

<details><summary>output</summary>

```
(eval):cd:1: no such file or directory: /w
==STATEMENTS.RPT
========================================================================
ACME............................BILLING.STATEMENT..RUN.000001
ACCOUNT.AC000001..TEST.CUSTOMER.............REGION.NE
PERIOD.2025-03-01.TO.2025-03-31..DAYS.31..PLAN.S
------------------------------------------------------------------------
DATE.......DESCRIPTION............................QTY..........AMOUNT
------------------------------------------------------------------------
2025-03-01.BASE.FEE.PLAN.B.....................14.00..........4.52
2025-03-15.BASE.FEE.PLAN.P......................7.00.........13.55
2025-03-22.BASE.FEE.PLAN.S.....................10.00..........6.85
...........USAGE.DATA.GB.......................40.00.........48.60
...........USAGE.VOICE.MIN....................101.00..........5.05
...........USAGE.SMS.MSG.......................50.00..........1.00
...........USAGE.ROAMING.MB...................100.00.........25.00
2025-03-12.LATE.LATE.FEE......................................5.00
2025-03-12.DEPO.DEPOSIT......................................50.00
2025-03-20.EQUP.PHONE........................................19.99
...........LOYALTY.DISCOUNT.L1..5%............................1.25CR
2025-03-16.COUPON.FIXED.......................................2.50CR
2025-03-11.COUPON.15.00%.....................................18.87CR
...........SUBTOTAL.........................................156.94
...........TAX.N.8.25%........................................8.82
2025-03-27.ADJ.GOODWILL.......................................3.00CR
...........CURRENT.CHARGES..................................162.76
...........PRIOR.BALANCE......................................0.00
2025-03-28.PAYMENT.RECEIVED...................................5.00CR
------------------------------------------------------------------------
...........AMOUNT.DUE.......................................157.76

==REJECTS.RPT
BILLRUN.4.2.REJECT.REPORT..........RUN.000001
SEQ....SRC..CODE.MESSAGE................RECORD
TOTAL.REJECTS.....0

==SUMMARY.RPT
BILLRUN.4.2.RUN.SUMMARY..........RUN.000001
COMPANY.ACME
ACCOUNTS.READ.....................1
ACCOUNTS.BILLED...................1
ACCOUNTS.NOT.IN.CYCLE.............0
ACCOUNTS.REJECTED.................0
ACTIVITY.READ....................15
ACTIVITY.ACCEPTED................15
ACTIVITY.REJECTED.................0
STATEMENTS.PRODUCED...............1
TOTAL.BASE.FEES....................24.92
TOTAL.USAGE........................79.65
TOTAL.CHARGES......................74.99
TOTAL.DISCOUNTS....................22.62
TOTAL.TAX...........................8.82
TOTAL.ADJUSTMENTS..................-3.00
TOTAL.PAYMENTS......................5.00
TOTAL.AMOUNT.DUE..................157.76
AMOUNT.DUE.BY.REGION
..REGION.NE.......................157.76

rc 0
```
</details>

### Step 22: Bash

```bash
cd /w; docker exec sn-cobol-production-parity bash -lc 'cd /w; python3 - <<EOF
from h import *
A=[acct(id="AC000001",plan="P")]
act=[ch(d="20250320",code="EQUP",amt="+000123456",desc="PHONE"),ch(d="20250321",code="MISC",amt="+999999999",desc="BIG"),ch(d="20250322",code="MISC",amt="-001234567",desc="N"),ch(d="20250323",code="MISC",amt="-000000001",desc="N")]
o=run(ctl(),A,act); 
for l in o["STATEMENTS.RPT"].split("\n"): print(len(l),repr(l))
show(o)
EOF'
```

<details><summary>output</summary>

```
(eval):cd:1: no such file or directory: /w
72 '========================================================================'
61 'ACME                            BILLING STATEMENT  RUN 000001'
53 'ACCOUNT AC000001  TEST CUSTOMER             REGION NE'
48 'PERIOD 2025-03-01 TO 2025-03-31  DAYS 31  PLAN P'
72 '------------------------------------------------------------------------'
69 'DATE       DESCRIPTION                            QTY          AMOUNT'
72 '------------------------------------------------------------------------'
66 '2025-03-01 BASE FEE PLAN P                     31.00         60.00'
66 '2025-03-20 EQUP PHONE                                     1,234.56'
66 '2025-03-21 MISC BIG                                   9,999,999.99'
68 '2025-03-22 MISC N                                        12,345.67CR'
68 '2025-03-23 MISC N                                             0.01CR'
68 '           SUBTOTAL                                      11,051.13CR'
66 '           TAX N 8.25%                                        0.00'
68 '           CURRENT CHARGES                               11,051.13CR'
66 '           PRIOR BALANCE                                      0.00'
72 '------------------------------------------------------------------------'
68 '           AMOUNT DUE                                    11,051.13CR'
0 ''
==STATEMENTS.RPT
========================================================================
ACME............................BILLING.STATEMENT..RUN.000001
ACCOUNT.AC000001..TEST.CUSTOMER.............REGION.NE
PERIOD.2025-03-01.TO.2025-03-31..DAYS.31..PLAN.P
------------------------------------------------------------------------
DATE.......DESCRIPTION............................QTY..........AMOUNT
------------------------------------------------------------------------
2025-03-01.BASE.FEE.PLAN.P.....................31.00.........60.00
2025-03-20.EQUP.PHONE.....................................1,234.56
2025-03-21.MISC.BIG...................................9,999,999.99
2025-03-22.MISC.N........................................12,345.67CR
2025-03-23.MISC.N.............................................0.01CR
...........SUBTOTAL......................................11,051.13CR
...........TAX.N.8.25%........................................0.00
...........CURRENT.CHARGES...............................11,051.13CR
...........PRIOR.BALANCE......................................0.00
------------------------------------------------------------------------
...........AMOUNT.DUE....................................11,051.13CR

==REJECTS.RPT
BILLRUN.4.2.REJECT.REPORT..........RUN.000001
SEQ....SRC..CODE.MESSAGE................RECORD
TOTAL.REJECTS.....0

==SUMMARY.RPT
BILLRUN.4.2.RUN.SUMMARY..........RUN.000001
COMPANY.ACME
ACCOUNTS.READ.....................1
ACCOUNTS.BILLED...................1
ACCOUNTS.NOT.IN.CYCLE.............0
ACCOUNTS.REJECTED.................0
ACTIVITY.READ.....................4
ACTIVITY.ACCEPTED.................4
ACTIVITY.REJECT
... [452 more chars truncated]
```
</details>

### Step 23: Bash

```bash
cd /w; docker exec sn-cobol-production-parity bash -lc 'cd /w; python3 - <<EOF
l="2025-03-01 BASE FEE PLAN P                     31.00         60.00"
print(l.index("31.00")+1, l.index("31.00")+5, len(l))
h="DATE       DESCRIPTION                            QTY          AMOUNT"
print(h.index("QTY")+1,h.index("AMOUNT")+1,h.index("DESC")+1)
l="2025-03-22 MISC N                                        12,345.67CR"
print(l.index("12,")+1, len(l))
EOF'
```

<details><summary>output</summary>

```
(eval):cd:1: no such file or directory: /w
48 52 66
51 64 12
58 68
```
</details>

### Step 24: Bash

```bash
cd /w; cat >> /dev/null; docker exec sn-cobol-production-parity bash -lc 'cd /w; cat >> h.py <<EOF
def usage(plan,svc,qty,extra=None,**ak):
    # qty in hundredths
    a=acct(id="AC000001",plan=plan,**ak)
    recs=[us(svc=svc,q="%09d"%qty)]+(extra or [])
    o=run(ctl(),[a],recs)
    m=re.search(r"^ {11}USAGE .{18}(.{12})(.{14})",o["STATEMENTS.RPT"] or "",re.M)
    return m and (m.group(1).strip(),m.group(2).strip()) 
EOF
python3 - <<EOF
from h import *
for plan in "BSP":
    print(plan,[ (q/100,usage(plan,"DATA",q)) for q in [50,100,500,1000,1001,1500,2000,2500,3000,4000,5000,5001,6000,8000,10000,20000]])
EOF'
```

<details><summary>output</summary>

```
(eval):cd:1: no such file or directory: /w
Command did not complete within its 120s timeout and was moved to the background (ID: bp3wdby3z). Output is being written to: <tmp> You will be notified when it completes. It is running now: do not start a second copy while it runs. If it is no longer needed, stop it with TaskStop. To check interim output, use Read on that file path.
Session cwd remains <host-path> directory changes made by the backgrounded command do not apply to subsequent commands.
```
</details>

### Step 25: Bash

```bash
docker exec sn-cobol-production-parity bash -lc 'cd /w/s1; time /app/prod/billrun; nproc; ls /w | head'
```

<details><summary>output</summary>

```
real	0m0.054s
user	0m0.033s
sys	0m0.021s
10
__pycache__
h.py
s1
```
</details>

### Step 26: Bash

```bash
sleep 20; cat <tmp> | head; docker exec sn-cobol-production-parity bash -lc 'ps aux | grep -E "billrun|python" | head'
```

<details><summary>output</summary>

```
(eval):cd:1: no such file or directory: /w
bash: line 1: ps: command not found
```
</details>

### Step 27: Bash

```bash
docker exec sn-cobol-production-parity bash -lc 'cd /w; pkill -f h.py; pkill -f billrun; sed -i "s/capture_output=True)/capture_output=True,timeout=10)/" h.py; timeout 60 python3 - <<EOF
from h import *
print(usage("B","DATA",50))
print(usage("B","DATA",1000))
EOF'
```

<details><summary>output</summary>

```
Exit code 1
bash: line 1: pkill: command not found
bash: line 1: pkill: command not found
Traceback (most recent call last):
  File "<stdin>", line 2, in <module>
NameError: name 'usage' is not defined
```
</details>

### Step 28: Bash

```bash
docker exec sn-cobol-production-parity bash -lc 'cd /w; cat >> h.py <<EOF
def usage(plan,svc,qty,extra=None,**ak):
    a=acct(id="AC000001",plan=plan,**ak)
    recs=[us(svc=svc,q="%09d"%qty)]+(extra or [])
    o=run(ctl(),[a],recs)
    m=re.search(r"^ {11}USAGE .{18}(.{12})(.{14})",o["STATEMENTS.RPT"] or "",re.M)
    return m and (m.group(1).strip(),m.group(2).strip()) 
EOF
timeout 100 python3 - <<EOF
from h import *
for plan in "BSP":
    print(plan,[ (q/100,usage(plan,"DATA",q)) for q in [50,100,500,1000,1001,1500,2000,2500,3000,4000,5000,5001,6000,8000,10000,20000]])
EOF'
```

<details><summary>output</summary>

```
B [(0.5, ('', '0.50')), (1.0, ('', '1.00')), (5.0, ('', '5.00')), (10.0, ('', '10.00')), (10.01, ('', '10.01')), (15.0, ('', '15.00')), (20.0, ('', '20.00')), (25.0, ('', '25.00')), (30.0, ('', '30.00')), (40.0, ('', '40.00')), (50.0, ('', '50.00')), (50.01, ('', '50.01')), (60.0, ('', '60.00')), (80.0, ('', '80.00')), (100.0, ('1', '00.00')), (200.0, ('2', '00.00        1'))]
S [(0.5, ('', '0.50')), (1.0, ('', '1.00')), (5.0, ('', '5.00')), (10.0, ('', '10.00')), (10.01, ('', '10.01')), (15.0, ('', '15.00')), (20.0, ('', '20.00')), (25.0, ('', '25.00')), (30.0, ('', '30.00')), (40.0, ('', '40.00')), (50.0, ('', '50.00')), (50.01, ('', '50.01')), (60.0, ('', '60.00')), (80.0, ('', '80.00')), (100.0, ('1', '00.00')), (200.0, ('2', '00.00        1'))]
P [(0.5, ('', '0.50')), (1.0, ('', '1.00')), (5.0, ('', '5.00')), (10.0, ('', '10.00')), (10.01, ('', '10.01')), (15.0, ('', '15.00')), (20.0, ('', '20.00')), (25.0, ('', '25.00')), (30.0, ('', '30.00')), (40.0, ('', '40.00')), (50.0, ('', '50.00')), (50.01, ('', '50.01')), (60.0, ('', '60.00')), (80.0, ('', '80.00')), (100.0, ('1', '00.00')), (200.0, ('2', '00.00        1'))]
```
</details>

### Step 29: Bash

```bash
docker exec sn-cobol-production-parity bash -lc 'cd /w; cat >> h.py <<EOF
def lines(o):
    out=[]
    for l in (o["STATEMENTS.RPT"] or "").split("\n"):
        l=l.ljust(70)
        out.append((l[0:10].strip(),l[11:40].strip(),l[40:52].strip(),l[52:70].strip()))
    return out
def usage(plan,svc,qty,extra=None,acctextra=None,**ak):
    a=acct(id="AC000001",plan=plan,**ak)
    recs=[us(svc=svc,q="%09d"%qty)]+(extra or [])
    o=run(ctl(),[a],recs)
    for d,de,q,am in lines(o):
        if de.startswith("USAGE"): return (q,am)
EOF
timeout 100 python3 - <<EOF
from h import *
for plan in "BSP":
    print(plan,[ (q/100,usage(plan,"DATA",q)) for q in [50,100,500,1000,1001,1500,2000,2500,3000,4000,5000,5001,6000,8000,10000,20000]])
EOF'
```

<details><summary>output</summary>

```
B [(0.5, ('0.50', '0.75')), (1.0, ('1.00', '1.50')), (5.0, ('5.00', '7.50')), (10.0, ('10.00', '15.00')), (10.01, ('10.01', '15.01')), (15.0, ('15.00', '21.00')), (20.0, ('20.00', '27.00')), (25.0, ('25.00', '33.00')), (30.0, ('30.00', '39.00')), (40.0, ('40.00', '51.00')), (50.0, ('50.00', '59.00')), (50.01, ('50.01', '59.01')), (60.0, ('60.00', '67.00')), (80.0, ('80.00', '83.00')), (100.0, ('100.00', '99.00')), (200.0, ('200.00', '179.00'))]
S [(0.5, ('0.50', '0.00')), (1.0, ('1.00', '0.00')), (5.0, ('5.00', '4.50')), (10.0, ('10.00', '12.00')), (10.01, ('10.01', '12.02')), (15.0, ('15.00', '18.60')), (20.0, ('20.00', '24.60')), (25.0, ('25.00', '30.60')), (30.0, ('30.00', '36.60')), (40.0, ('40.00', '48.60')), (50.0, ('50.00', '57.40')), (50.01, ('50.01', '57.41')), (60.0, ('60.00', '65.40')), (80.0, ('80.00', '81.40')), (100.0, ('100.00', '97.40')), (200.0, ('200.00', '177.40'))]
P [(0.5, ('0.50', '0.00')), (1.0, ('1.00', '0.00')), (5.0, ('5.00', '0.00')), (10.0, ('10.00', '7.50')), (10.01, ('10.01', '7.52')), (15.0, ('15.00', '15.00')), (20.0, ('20.00', '21.00')), (25.0, ('25.00', '27.00')), (30.0, ('30.00', '33.00')), (40.0, ('40.00', '45.00')), (50.0, ('50.00', '55.00')), (50.01, ('50.01', '55.01')), (60.0, ('60.00', '63.00')), (80.0, ('80.00', '79.00')), (100.0, ('100.00', '95.00')), (200.0, ('200.00', '175.00'))]
```
</details>

### Step 30: Bash

```bash
docker exec sn-cobol-production-parity bash -lc 'cd /w; timeout 100 python3 - <<EOF
from h import *
qs=[0,1,50,99,100,101,150,199,200,1000,1050,5000,10000,10001,20000,50000,100000]
for svc in ["VOIC"]:
  for plan in "BSP":
    print(svc,plan,[ (q/100,usage(plan,svc,q)) for q in qs])
EOF'
```

<details><summary>output</summary>

```
VOIC B [(0.0, ('0.00', '0.00')), (0.01, ('1.00', '0.05')), (0.5, ('1.00', '0.05')), (0.99, ('1.00', '0.05')), (1.0, ('1.00', '0.05')), (1.01, ('2.00', '0.10')), (1.5, ('2.00', '0.10')), (1.99, ('2.00', '0.10')), (2.0, ('2.00', '0.10')), (10.0, ('10.00', '0.50')), (10.5, ('11.00', '0.55')), (50.0, ('50.00', '2.50')), (100.0, ('100.00', '5.00')), (100.01, ('101.00', '5.05')), (200.0, ('200.00', '10.00')), (500.0, ('500.00', '25.00')), (1000.0, ('1,000.00', '50.00'))]
VOIC S [(0.0, ('0.00', '0.00')), (0.01, ('1.00', '0.05')), (0.5, ('1.00', '0.05')), (0.99, ('1.00', '0.05')), (1.0, ('1.00', '0.05')), (1.01, ('2.00', '0.10')), (1.5, ('2.00', '0.10')), (1.99, ('2.00', '0.10')), (2.0, ('2.00', '0.10')), (10.0, ('10.00', '0.50')), (10.5, ('11.00', '0.55')), (50.0, ('50.00', '2.50')), (100.0, ('100.00', '5.00')), (100.01, ('101.00', '5.05')), (200.0, ('200.00', '10.00')), (500.0, ('500.00', '25.00')), (1000.0, ('1,000.00', '50.00'))]
VOIC P [(0.0, ('0.00', '0.00')), (0.01, ('1.00', '0.03')), (0.5, ('1.00', '0.03')), (0.99, ('1.00', '0.03')), (1.0, ('1.00', '0.03')), (1.01, ('2.00', '0.06')), (1.5, ('2.00', '0.06')), (1.99, ('2.00', '0.06')), (2.0, ('2.00', '0.06')), (10.0, ('10.00', '0.30')), (10.5, ('11.00', '0.33')), (50.0, ('50.00', '1.50')), (100.0, ('100.00', '3.00')), (100.01, ('101.00', '3.03')), (200.0, ('200.00', '6.00')), (500.0, ('500.00', '15.00')), (1000.0, ('1,000.00', '30.00'))]
```
</details>

### Step 31: Bash

```bash
docker exec sn-cobol-production-parity bash -lc 'cd /w; timeout 100 python3 - <<EOF
from h import *
qs=[0,1,50,100,101,150,1000,5000,9900,10000,10001,20000,50000,100000,100001,200000,500000]
for svc in ["SMS ","ROAM"]:
  for plan in "BSP":
    print(svc,plan,[ (q/100,usage(plan,svc,q)) for q in qs])
EOF'
```

<details><summary>output</summary>

```
SMS  B [(0.0, ('0.00', '0.00')), (0.01, ('0.00', '0.00')), (0.5, ('0.00', '0.00')), (1.0, ('1.00', '0.03')), (1.01, ('1.00', '0.03')), (1.5, ('1.00', '0.03')), (10.0, ('10.00', '0.30')), (50.0, ('50.00', '1.50')), (99.0, ('99.00', '2.97')), (100.0, ('100.00', '3.00')), (100.01, ('100.00', '3.00')), (200.0, ('200.00', '6.00')), (500.0, ('500.00', '15.00')), (1000.0, ('1,000.00', '30.00')), (1000.01, ('1,000.00', '30.00')), (2000.0, ('2,000.00', '60.00')), (5000.0, ('5,000.00', '150.00'))]
SMS  S [(0.0, ('0.00', '0.00')), (0.01, ('0.00', '0.00')), (0.5, ('0.00', '0.00')), (1.0, ('1.00', '0.02')), (1.01, ('1.00', '0.02')), (1.5, ('1.00', '0.02')), (10.0, ('10.00', '0.20')), (50.0, ('50.00', '1.00')), (99.0, ('99.00', '1.98')), (100.0, ('100.00', '2.00')), (100.01, ('100.00', '2.00')), (200.0, ('200.00', '4.00')), (500.0, ('500.00', '10.00')), (1000.0, ('1,000.00', '20.00')), (1000.01, ('1,000.00', '20.00')), (2000.0, ('2,000.00', '40.00')), (5000.0, ('5,000.00', '100.00'))]
SMS  P [(0.0, ('0.00', '0.00')), (0.01, ('0.00', '0.00')), (0.5, ('0.00', '0.00')), (1.0, ('1.00', '0.00')), (1.01, ('1.00', '0.00')), (1.5, ('1.00', '0.00')), (10.0, ('10.00', '0.00')), (50.0, ('50.00', '0.00')), (99.0, ('99.00', '0.00')), (100.0, ('100.00', '0.00')), (100.01, ('100.00', '0.00')), (200.0, ('200.00', '2.00')), (500.0, ('500.00', '8.00')), (1000.0, ('1,000.00', '18.00')), (1000.01, ('1,000.00', '18.00')), (2000.0, ('2,000.00', '38.00')), (5000.0, ('5,000.00', '98.00'))]
ROAM B [(0.0, ('0.00', '0.00')), (0.01, ('0.01', '0.00')), (0.5, ('0.50', '0.12')), (1.0, ('1.00', '0.25')), (1.01, ('1.01', '0.25')), (1.5, ('1.50', '0.38')), (10.0, ('10.00', '2.50')), (50.0, ('50.00', '12.50')), (99.0, ('99.00', '24.75')), (100.0, ('100.00', '25.00')), (100.01, ('100.01', '25.00')), (200.0, ('200.00', '50.00')), (500.0, ('500.00', '125.00')), (1000.0, ('1,000.00', '250.00')), (1000.01, ('1,000.01', '250.00')), (2000.0, ('2,000.00', '500.00')), (5000.0, ('5,000.00', '1,250.00'))]
ROAM S [(0.0, ('0.00', '0.00')), (0.01, ('0.01', '0.00')), (0.5, ('0.50', '0.12')), (1.0, ('1.00', '0.25')), (1.01, ('1.01', '0.25')), (1.5, ('1.50', '0.38')), (10.0, ('10.00', '2.50')), (50.0, ('50.00', '12.50')), (99.0, ('99.00', '24.75')), (100.0, ('100.00', '25.00')), (100.01, ('100.01', '25.00')), (200.0, ('200.00', '50.00')), (500.0, ('500.00', '125.00')), (1000.0, ('1,000.00', '250.00')), (1000.01, ('1,000.01', '250.00')), (2000.0, ('2,000.00', '500.00')), (5000.0, ('5,000.00', '1,250.00'))]
ROAM P [(0.0, ('0.00', '0.00')), (0.01, ('0.01', '0.00')), (0.5, ('0.50', '0.12')), (1.0, ('1.00', '0.25')), (1.01, ('1.01', '0.25')), (1.5, ('1.50', '0.38')), (10.0, ('10.00', '2.50')), (50.0, ('50.00', '12.50')), (99.0, ('99.00', '24.75')), (100.0, ('100.00', '25.00')), (100.01, ('100.01', '25.00')), (200.0, ('200.00', '50.00')), (500.0, ('500.00', '125.00')), (1000.0, ('1,000.00', '250.00')), (1000.01, ('1,000.01', '250.00')), (2000.0, ('2,000.00', '500.00')), (5000.0, ('5,000.00', '1,250.00'))]
```
</details>

### Step 32: Bash

```bash
docker exec sn-cobol-production-parity bash -lc 'cd /w; timeout 100 python3 - <<EOF
from h import *
def multi(plan,recs):
    o=run(ctl(),[acct(id="AC000001",plan=plan)],recs)
    return [l for l in lines(o) if l[1].startswith("USAGE")]
for svc in ["VOIC","SMS ","ROAM","DATA"]:
    print(svc,multi("B",[us(svc=svc,q="000000050",d="20250305"),us(svc=svc,q="000000050",d="20250306")]))
print(multi("B",[us(svc="ROAM",q="000000250"),us(svc="ROAM",q="000000250",d="20250311")]))
print(multi("B",[us(svc="ROAM",q="000000250")]),multi("B",[us(svc="ROAM",q="000000750")]),multi("B",[us(svc="ROAM",q="000001250")]))
print(multi("B",[us(svc="DATA",q="000000250"),us(svc="DATA",q="000000350",d="20250311")]))
print(multi("B",[us(svc="VOIC",q="000000250"),us(svc="VOIC",q="000000350",d="20250311")]))
print(multi("B",[us(svc="SMS ",q="000000250"),us(svc="SMS ",q="000000350",d="20250311")]))
print(multi("B",[us(svc="SMS ",q="000000250",d="20250312"),us(svc="DATA",q="000000350",d="20250311"),us(svc="ROAM",q="000000350",d="20250310"),us(svc="VOIC",q="000000350",d="20250309")]))
EOF'
```

<details><summary>output</summary>

```
VOIC [('', 'USAGE VOICE MIN', '2.00', '0.10')]
SMS  [('', 'USAGE SMS MSG', '0.00', '0.00')]
ROAM [('', 'USAGE ROAMING MB', '1.00', '0.24')]
DATA [('', 'USAGE DATA GB', '1.00', '1.50')]
[('', 'USAGE ROAMING MB', '5.00', '1.24')]
[('', 'USAGE ROAMING MB', '2.50', '0.62')] [('', 'USAGE ROAMING MB', '7.50', '1.88')] [('', 'USAGE ROAMING MB', '12.50', '3.12')]
[('', 'USAGE DATA GB', '6.00', '9.00')]
[('', 'USAGE VOICE MIN', '7.00', '0.35')]
[('', 'USAGE SMS MSG', '5.00', '0.15')]
[('', 'USAGE DATA GB', '3.50', '5.25'), ('', 'USAGE VOICE MIN', '4.00', '0.20'), ('', 'USAGE SMS MSG', '2.00', '0.06'), ('', 'USAGE ROAMING MB', '3.50', '0.88')]
```
</details>

### Step 33: Bash

```bash
docker exec sn-cobol-production-parity bash -lc 'cd /w; timeout 100 python3 - <<EOF
from h import *
def multi(plan,recs,**k):
    o=run(ctl(),[acct(id="AC000001",plan=plan,**k)],recs)
    return [l for l in lines(o) if l[1].startswith("USAGE") or l[1].startswith("BASE")]
print("2x8GB B",multi("B",[us(svc="DATA",q="000000800"),us(svc="DATA",q="000000800",d="20250311")]))
print("P sms 60+60",multi("P",[us(svc="SMS ",q="000006000"),us(svc="SMS ",q="000006000",d="20250311")]))
print("P sms 60.9+60.9",multi("P",[us(svc="SMS ",q="000006090"),us(svc="SMS ",q="000006090",d="20250311")]))
print("B->P on 15, data30 on 5",multi("B",[us(svc="DATA",q="000003000",d="20250305"),pc(d="20250315",p="P")]))
print("B->P on 15, data30 on 20",multi("B",[us(svc="DATA",q="000003000",d="20250320"),pc(d="20250315",p="P")]))
print("B->P on 15, data30 on 15",multi("B",[us(svc="DATA",q="000003000",d="20250315"),pc(d="20250315",p="P")]))
print("B->P on 15, voic 10 on 5",multi("B",[us(svc="VOIC",q="000001000",d="20250305"),pc(d="20250315",p="P")]))
print("PC later in file, B->P on 15, voic 10 on 5",multi("B",[pc(d="20250315",p="P"),us(svc="VOIC",q="000001000",d="20250305")]))
print("B->P ->B on 15 +20",multi("B",[pc(d="20250315",p="P"),pc(d="20250320",p="B"),us(svc="VOIC",q="000001000",d="20250305")]))
print("PC out of order",multi("B",[pc(d="20250320",p="B"),pc(d="20250315",p="P"),us(svc="VOIC",q="000001000",d="20250305")]))
EOF'
```

<details><summary>output</summary>

```
2x8GB B [('2025-03-01', 'BASE FEE PLAN B', '31.00', '10.00'), ('', 'USAGE DATA GB', '16.00', '22.20')]
P sms 60+60 [('2025-03-01', 'BASE FEE PLAN P', '31.00', '60.00'), ('', 'USAGE SMS MSG', '120.00', '0.40')]
P sms 60.9+60.9 [('2025-03-01', 'BASE FEE PLAN P', '31.00', '60.00'), ('', 'USAGE SMS MSG', '120.00', '0.40')]
B->P on 15, data30 on 5 [('2025-03-01', 'BASE FEE PLAN B', '14.00', '4.52'), ('2025-03-15', 'BASE FEE PLAN P', '17.00', '32.90'), ('', 'USAGE DATA GB', '30.00', '33.00')]
B->P on 15, data30 on 20 [('2025-03-01', 'BASE FEE PLAN B', '14.00', '4.52'), ('2025-03-15', 'BASE FEE PLAN P', '17.00', '32.90'), ('', 'USAGE DATA GB', '30.00', '33.00')]
B->P on 15, data30 on 15 [('2025-03-01', 'BASE FEE PLAN B', '14.00', '4.52'), ('2025-03-15', 'BASE FEE PLAN P', '17.00', '32.90'), ('', 'USAGE DATA GB', '30.00', '33.00')]
B->P on 15, voic 10 on 5 [('2025-03-01', 'BASE FEE PLAN B', '14.00', '4.52'), ('2025-03-15', 'BASE FEE PLAN P', '17.00', '32.90'), ('', 'USAGE VOICE MIN', '10.00', '0.30')]
PC later in file, B->P on 15, voic 10 on 5 [('2025-03-01', 'BASE FEE PLAN B', '14.00', '4.52'), ('2025-03-15', 'BASE FEE PLAN P', '17.00', '32.90'), ('', 'USAGE VOICE MIN', '10.00', '0.30')]
B->P ->B on 15 +20 [('2025-03-01', 'BASE FEE PLAN B', '14.00', '4.52'), ('2025-03-15', 'BASE FEE PLAN P', '5.00', '9.68'), ('2025-03-20', 'BASE FEE PLAN B', '12.00', '3.87'), ('', 'USAGE VOICE MIN', '10.00', '0.50')]
PC out of order [('2025-03-01', 'BASE FEE PLAN B', '14.00', '4.52'), ('2025-03-15', 'BASE FEE PLAN P', '5.00', '9.68'), ('2025-03-20', 'BASE FEE PLAN B', '12.00', '3.87'), ('', 'USAGE VOICE MIN', '10.00', '0.50')]
```
</details>

### Step 34: Bash

```bash
docker exec sn-cobol-production-parity bash -lc 'cd /w; timeout 100 python3 - <<EOF
from h import *
def base(recs,plan="S",**k):
    o=run(ctl(),[acct(id="AC000001",plan=plan,**k)],recs)
    return [l[0:1]+l[2:] if False else l for l in lines(o) if l[1].startswith("BASE") or "NO ACT" in l[1] or "SUSP" in l[1] or l[1].startswith("SUBT")]
print("susp 3 days",base([su(d="20250324",e="20250326")]))
print("susp 1 day",base([su(d="20250324",e="20250324")]))
print("susp 10 days",base([su(d="20250301",e="20250310")]))
print("susp whole",base([su(d="20250301",e="20250331")]))
print("susp whole beyond",base([su(d="20250301",e="20250430")]))
print("susp start 20 to beyond",base([su(d="20250320",e="20250430")]))
print("susp 2 overlapping",base([su(d="20250310",e="20250315"),su(d="20250313",e="20250320")]))
print("susp 2 nonoverlapping",base([su(d="20250310",e="20250315"),su(d="20250320",e="20250322")]))
print("susp with PC",base([su(d="20250310",e="20250320"),pc(d="20250315",p="P")]))
print("PC same plan",base([pc(d="20250315",p="S")]))
print("PC same date two",base([pc(d="20250315",p="P"),pc(d="20250315",p="B")]))
print("PC same date two rev",base([pc(d="20250315",p="B"),pc(d="20250315",p="P")]))
print("PC on first day",base([pc(d="20250301",p="P")]))
print("PC on last day",base([pc(d="20250331",p="P")]))
print("open mid + PC",base([pc(d="20250315",p="P")],op="20250310"))
print("open mid close mid",base([],op="20250310",cl="20250320"))
print("open mid close mid+susp",base([su(d="20250312",e="20250314")],op="20250310",cl="20250320"))
print("open mid close mid+susp start before open?",base([su(d="20250310",e="20250314")],op="20250310",cl="20250320"))
EOF'
```

<details><summary>output</summary>

```
susp 3 days [('2025-03-01', 'BASE FEE PLAN S', '31.00', '23.79'), ('', 'SUBTOTAL', '', '23.79')]
susp 1 day [('2025-03-01', 'BASE FEE PLAN S', '31.00', '24.60'), ('', 'SUBTOTAL', '', '24.60')]
susp 10 days [('2025-03-01', 'BASE FEE PLAN S', '31.00', '20.97'), ('', 'SUBTOTAL', '', '20.97')]
susp whole [('2025-03-01', 'BASE FEE PLAN S', '31.00', '12.50'), ('', 'SUBTOTAL', '', '12.50')]
susp whole beyond [('2025-03-01', 'BASE FEE PLAN S', '31.00', '12.50'), ('', 'SUBTOTAL', '', '12.50')]
susp start 20 to beyond [('2025-03-01', 'BASE FEE PLAN S', '31.00', '20.16'), ('', 'SUBTOTAL', '', '20.16')]
susp 2 overlapping [('2025-03-01', 'BASE FEE PLAN S', '31.00', '20.56'), ('', 'SUBTOTAL', '', '20.56')]
susp 2 nonoverlapping [('2025-03-01', 'BASE FEE PLAN S', '31.00', '21.37'), ('', 'SUBTOTAL', '', '21.37')]
susp with PC [('2025-03-01', 'BASE FEE PLAN S', '14.00', '9.27'), ('2025-03-15', 'BASE FEE PLAN P', '17.00', '27.10'), ('', 'SUBTOTAL', '', '36.37')]
PC same plan [('2025-03-01', 'BASE FEE PLAN S', '31.00', '25.00'), ('', 'SUBTOTAL', '', '25.00')]
PC same date two [('2025-03-01', 'BASE FEE PLAN S', '14.00', '11.29'), ('2025-03-15', 'BASE FEE PLAN B', '17.00', '5.48'), ('', 'SUBTOTAL', '', '16.77')]
PC same date two rev [('2025-03-01', 'BASE FEE PLAN S', '14.00', '11.29'), ('2025-03-15', 'BASE FEE PLAN P', '17.00', '32.90'), ('', 'SUBTOTAL', '', '44.19')]
PC on first day [('2025-03-01', 'BASE FEE PLAN P', '31.00', '60.00'), ('', 'SUBTOTAL', '', '60.00')]
PC on last day [('2025-03-01', 'BASE FEE PLAN S', '30.00', '24.19'), ('2025-03-31', 'BASE FEE PLAN P', '1.00', '1.94'), ('', 'SUBTOTAL', '', '26.13')]
open mid + PC [('2025-03-10', 'BASE FEE PLAN S', '5.00', '4.03'), ('2025-03-15', 'BASE FEE PLAN P', '17.00', '32.90'), ('', 'SUBTOTAL', '', '36.93')]
open mid close mid [('', 'NO ACTIVITY THIS PERIOD', '', ''), ('2025-03-10', 'BASE FEE PLAN S', '11.00', '8.87'), ('', 'SUBTOTAL', '', '8.87')]
open mid close mid+susp [('2025-03-10', 'BASE FEE PLAN S', '11.00', '7.66'), ('', 'SUBTOTAL', '', '7.66')]
open mid close mid+susp start before open? [('2025-03-10', 'BASE FEE PLAN S', '11.00', '6.85'), ('', 'SUBTOTAL', '', '6.85')]
```
</details>

### Step 35: Bash

```bash
docker exec sn-cobol-production-parity bash -lc 'cd /w; timeout 100 python3 - <<EOF
from h import *
def base(recs,plan="S",c=None,**k):
    o=run(c or ctl(),[acct(id="AC000001",plan=plan,**k)],recs)
    return [l for l in lines(o) if l[1].startswith("BASE") or "NO ACT" in l[1] or l[1].startswith("SUBT") or l[1].startswith("TAX")]
c8=ctl(s="20250301",e="20250308")
print("tie 8d 1day",base([],c=c8,op="20250308"))
print("tie 8d 1day susp",base([su(d="20250308",e="20250308")],c=c8,op="20250305"))
for n in [1,2,28,30]:
    e="202503%02d"%n
    print(n,base([],c=ctl(s="20250301",e=e),op="20250301"))
print("feb",base([],c=ctl(s="20250201",e="20250228"),plan="P",op="20250215"))
print("cross month",base([],c=ctl(s="20250115",e="20250214"),plan="P",op="20250201"))
print("year cross",base([],c=ctl(s="20241220",e="20250118"),plan="P",op="20250101"))
print("only PC",base([pc(p="P")]))
EOF'
```

<details><summary>output</summary>

```
tie 8d 1day [('', 'NO ACTIVITY THIS PERIOD', '', ''), ('2025-03-08', 'BASE FEE PLAN S', '1.00', '3.13'), ('', 'SUBTOTAL', '', '3.13'), ('', 'TAX N 8.25%', '', '0.26')]
tie 8d 1day susp [('2025-03-05', 'BASE FEE PLAN S', '4.00', '10.94'), ('', 'SUBTOTAL', '', '10.94'), ('', 'TAX N 8.25%', '', '0.90')]
1 [('', 'NO ACTIVITY THIS PERIOD', '', ''), ('2025-03-01', 'BASE FEE PLAN S', '1.00', '25.00'), ('', 'SUBTOTAL', '', '25.00'), ('', 'TAX N 8.25%', '', '2.06')]
2 [('', 'NO ACTIVITY THIS PERIOD', '', ''), ('2025-03-01', 'BASE FEE PLAN S', '2.00', '25.00'), ('', 'SUBTOTAL', '', '25.00'), ('', 'TAX N 8.25%', '', '2.06')]
28 [('', 'NO ACTIVITY THIS PERIOD', '', ''), ('2025-03-01', 'BASE FEE PLAN S', '28.00', '25.00'), ('', 'SUBTOTAL', '', '25.00'), ('', 'TAX N 8.25%', '', '2.06')]
30 [('', 'NO ACTIVITY THIS PERIOD', '', ''), ('2025-03-01', 'BASE FEE PLAN S', '30.00', '25.00'), ('', 'SUBTOTAL', '', '25.00'), ('', 'TAX N 8.25%', '', '2.06')]
feb [('', 'NO ACTIVITY THIS PERIOD', '', ''), ('2025-02-15', 'BASE FEE PLAN P', '14.00', '30.00'), ('', 'SUBTOTAL', '', '30.00'), ('', 'TAX N 8.25%', '', '2.48')]
cross month [('', 'NO ACTIVITY THIS PERIOD', '', ''), ('2025-02-01', 'BASE FEE PLAN P', '14.00', '27.10'), ('', 'SUBTOTAL', '', '27.10'), ('', 'TAX N 8.25%', '', '2.24')]
year cross [('', 'NO ACTIVITY THIS PERIOD', '', ''), ('2025-01-01', 'BASE FEE PLAN P', '18.00', '36.00'), ('', 'SUBTOTAL', '', '36.00'), ('', 'TAX N 8.25%', '', '2.97')]
only PC [('2025-03-01', 'BASE FEE PLAN S', '9.00', '7.26'), ('2025-03-10', 'BASE FEE PLAN P', '22.00', '42.58'), ('', 'SUBTOTAL', '', '49.84'), ('', 'TAX N 8.25%', '', '4.11')]
```
</details>

### Step 36: Bash

```bash
docker exec sn-cobol-production-parity bash -lc 'cd /w; timeout 100 python3 - <<EOF
from h import *
def stm(recs,plan="S",c=None,**k):
    o=run(c or ctl(),[acct(id="AC000001",plan=plan,**k)],recs)
    return [l for l in lines(o)[7:-3] if l[1] and not l[1].startswith("---")]
for loy in ["L1","L2","L3","  ","L4"]:
    print(loy,stm([],loy=loy))
print("L2 w usage+charge",stm([us(svc="VOIC",q="000010000"),ch(amt="+000010000",code="EQUP")],loy="L2"))
print("L2 prorated",stm([],loy="L2",op="20250310"))
print("L2 PC",stm([pc(d="20250315",p="P")],loy="L2"))
EOF'
```

<details><summary>output</summary>

```
L1 [('', 'NO ACTIVITY THIS PERIOD', '', ''), ('2025-03-01', 'BASE FEE PLAN S', '31.00', '25.00'), ('', 'LOYALTY DISCOUNT L1  5%', '', '1.25CR'), ('', 'SUBTOTAL', '', '23.75'), ('', 'TAX N 8.25%', '', '1.96'), ('', 'CURRENT CHARGES', '', '25.71'), ('', 'PRIOR BALANCE', '', '0.00')]
L2 [('', 'NO ACTIVITY THIS PERIOD', '', ''), ('2025-03-01', 'BASE FEE PLAN S', '31.00', '25.00'), ('', 'LOYALTY DISCOUNT L2 10%', '', '2.50CR'), ('', 'SUBTOTAL', '', '22.50'), ('', 'TAX N 8.25%', '', '1.86'), ('', 'CURRENT CHARGES', '', '24.36'), ('', 'PRIOR BALANCE', '', '0.00')]
L3 [('', 'NO ACTIVITY THIS PERIOD', '', ''), ('2025-03-01', 'BASE FEE PLAN S', '31.00', '25.00'), ('', 'LOYALTY DISCOUNT L3 15%', '', '3.75CR'), ('', 'SUBTOTAL', '', '21.25'), ('', 'TAX N 8.25%', '', '1.75'), ('', 'CURRENT CHARGES', '', '23.00'), ('', 'PRIOR BALANCE', '', '0.00')]
   [('', 'NO ACTIVITY THIS PERIOD', '', ''), ('2025-03-01', 'BASE FEE PLAN S', '31.00', '25.00'), ('', 'SUBTOTAL', '', '25.00'), ('', 'TAX N 8.25%', '', '2.06'), ('', 'CURRENT CHARGES', '', '27.06'), ('', 'PRIOR BALANCE', '', '0.00')]
L4 [('', 'NO ACTIVITY THIS PERIOD', '', ''), ('2025-03-01', 'BASE FEE PLAN S', '31.00', '25.00'), ('', 'SUBTOTAL', '', '25.00'), ('', 'TAX N 8.25%', '', '2.06'), ('', 'CURRENT CHARGES', '', '27.06'), ('', 'PRIOR BALANCE', '', '0.00')]
L2 w usage+charge [('2025-03-01', 'BASE FEE PLAN S', '31.00', '25.00'), ('', 'USAGE VOICE MIN', '100.00', '5.00'), ('2025-03-10', 'EQUP SOME CHARGE', '', '100.00'), ('', 'LOYALTY DISCOUNT L2 10%', '', '2.50CR'), ('', 'SUBTOTAL', '', '127.50'), ('', 'TAX N 8.25%', '', '10.52'), ('', 'CURRENT CHARGES', '', '138.02'), ('', 'PRIOR BALANCE', '', '0.00')]
L2 prorated [('', 'NO ACTIVITY THIS PERIOD', '', ''), ('2025-03-10', 'BASE FEE PLAN S', '22.00', '17.74'), ('', 'LOYALTY DISCOUNT L2 10%', '', '1.77CR'), ('', 'SUBTOTAL', '', '15.97'), ('', 'TAX N 8.25%', '', '1.32'), ('', 'CURRENT CHARGES', '', '17.29'), ('', 'PRIOR BALANCE', '', '0.00')]
L2 PC [('2025-03-01', 'BASE FEE PLAN S', '14.00', '11.29'), ('2025-03-15', 'BASE FEE PLAN P', '17.00', '32.90'), ('', 'LOYALTY DISCOUNT L2 10%', '', '4.42CR'), ('', 'SUBTOTAL', '', '39.77'), ('', 'TAX N 8.25%', '', '3.28'), ('', 'CURRENT CHARGES', '', '43.05'), ('', 'PRIOR BALANCE', '', '0.00')]
```
</details>

### Step 37: Bash

```bash
docker exec sn-cobol-production-parity bash -lc 'cd /w; timeout 100 python3 - <<EOF
from h import *
def stm(recs,plan="S",c=None,**k):
    o=run(c or ctl(),[acct(id="AC000001",plan=plan,**k)],recs)
    return [l for l in lines(o)[7:-3] if l[1] and not l[1].startswith("---") and not l[1].startswith("PRIOR") and "NO ACT" not in l[1]]
print("P15",stm([ds(k="P",v="+000001500")]))
print("P0.01",stm([ds(k="P",v="+000000001")]))
print("P5.5",stm([ds(k="P",v="+000000550")]))
print("P100",stm([ds(k="P",v="+000010000")]))
print("F 2.5",stm([ds(k="F",v="+000000250")]))
print("F 1000",stm([ds(k="F",v="+000100000")]))
print("F 30 > base 25",stm([ds(k="F",v="+000003000")]))
print("P15 w usage",stm([ds(k="P",v="+000001500"),us(svc="VOIC",q="000010000")]))
print("P15 w charge",stm([ds(k="P",v="+000001500"),ch(code="EQUP",amt="+000010000")]))
print("P15 w deposit",stm([ds(k="P",v="+000001500"),ch(code="DEPO",amt="+000010000")]))
print("P15 w late",stm([ds(k="P",v="+000001500"),ch(code="LATE",amt="+000001000")]))
print("P15 w neg charge",stm([ds(k="P",v="+000001500"),ch(code="MISC",amt="-000001000")]))
print("P15 w adj",stm([ds(k="P",v="+000001500"),ad(amt="+000001000")]))
print("P15 L2",stm([ds(k="P",v="+000001500")],loy="L2"))
print("F5 + P15 L2",stm([ds(k="P",v="+000001500"),ds(k="F",v="+000000500")],loy="L2"))
EOF'
```

<details><summary>output</summary>

```
P15 [('2025-03-01', 'BASE FEE PLAN S', '31.00', '25.00'), ('2025-03-10', 'COUPON 15.00%', '', '3.75CR'), ('', 'SUBTOTAL', '', '21.25'), ('', 'TAX N 8.25%', '', '1.75'), ('', 'CURRENT CHARGES', '', '23.00')]
P0.01 [('2025-03-01', 'BASE FEE PLAN S', '31.00', '25.00'), ('2025-03-10', 'COUPON  0.01%', '', '0.00'), ('', 'SUBTOTAL', '', '25.00'), ('', 'TAX N 8.25%', '', '2.06'), ('', 'CURRENT CHARGES', '', '27.06')]
P5.5 [('2025-03-01', 'BASE FEE PLAN S', '31.00', '25.00'), ('2025-03-10', 'COUPON  5.50%', '', '1.38CR'), ('', 'SUBTOTAL', '', '23.62'), ('', 'TAX N 8.25%', '', '1.95'), ('', 'CURRENT CHARGES', '', '25.57')]
P100 [('2025-03-01', 'BASE FEE PLAN S', '31.00', '25.00'), ('2025-03-10', 'COUPON  0.00%', '', '25.00CR'), ('', 'DISCOUNT CAP', '', '12.50'), ('', 'SUBTOTAL', '', '12.50'), ('', 'TAX N 8.25%', '', '1.03'), ('', 'CURRENT CHARGES', '', '13.53')]
F 2.5 [('2025-03-01', 'BASE FEE PLAN S', '31.00', '25.00'), ('2025-03-10', 'COUPON FIXED', '', '2.50CR'), ('', 'SUBTOTAL', '', '22.50'), ('', 'TAX N 8.25%', '', '1.86'), ('', 'CURRENT CHARGES', '', '24.36')]
F 1000 [('2025-03-01', 'BASE FEE PLAN S', '31.00', '25.00'), ('2025-03-10', 'COUPON FIXED', '', '25.00CR'), ('', 'DISCOUNT CAP', '', '12.50'), ('', 'SUBTOTAL', '', '12.50'), ('', 'TAX N 8.25%', '', '1.03'), ('', 'CURRENT CHARGES', '', '13.53')]
F 30 > base 25 [('2025-03-01', 'BASE FEE PLAN S', '31.00', '25.00'), ('2025-03-10', 'COUPON FIXED', '', '25.00CR'), ('', 'DISCOUNT CAP', '', '12.50'), ('', 'SUBTOTAL', '', '12.50'), ('', 'TAX N 8.25%', '', '1.03'), ('', 'CURRENT CHARGES', '', '13.53')]
P15 w usage [('2025-03-01', 'BASE FEE PLAN S', '31.00', '25.00'), ('', 'USAGE VOICE MIN', '100.00', '5.00'), ('2025-03-10', 'COUPON 15.00%', '', '4.50CR'), ('', 'SUBTOTAL', '', '25.50'), ('', 'TAX N 8.25%', '', '2.10'), ('', 'CURRENT CHARGES', '', '27.60')]
P15 w charge [('2025-03-01', 'BASE FEE PLAN S', '31.00', '25.00'), ('2025-03-10', 'EQUP SOME CHARGE', '', '100.00'), ('2025-03-10', 'COUPON 15.00%', '', '18.75CR'), ('', 'SUBTOTAL', '', '106.25'), ('', 'TAX N 8.25%', '', '8.77'), ('', 'CURRENT CHARGES', '', '115.02')]
P15 w deposit [('2025-03-01', 'BASE FEE PLAN S', '31.00', '25.00'), ('2025-03-10', 'DEPO SOME CHARGE', '', '100.00'), ('2025-03-10', 'COUPON 15.00%', '', '3.75CR'), ('', 'SUBTOTAL', '', '121.25'), ('', 'TAX N 8.25%', '', '1.75'), ('', 'CURRENT CHARGES', '', '123.00')]
P15 w late [('2025-03-01', 'BASE FEE PLAN S', '31.00', '25.00'), ('2025-03-10', 'LATE SOME CHARGE', '', '10.00'), ('2025-03-10', 'COUPON 15.00%', '', '5.25CR'), ('', 'SUBTOTAL', '', '29.75'), ('', 'TAX N 8.25%', '', '2.45'), ('', 'CURRENT CHARGES', '', '32.20')]
P15 w neg charge [('2025-03-01', 'BASE FEE PLAN S', '31.00', '25.00'), ('2025-03-10', 'MISC SOME CHARGE', '', '10.00CR'), ('2025-03-10', 'COUPON 15.00%', '', '2.25CR'), ('', 'SUBTOTAL', '', '12.75'), ('', 'TAX N 8.25%', '', '1.05'), ('', 'CURRENT CHARGES', '', '13.80')]
P15 w adj [('2025-03-01', 'BASE FEE PLAN S', '31.00', '25.00'), ('2025-03-10', 'COUPON 15.00%', ''
... [722 more chars truncated]
```
</details>

### Step 38: Bash

```bash
docker exec sn-cobol-production-parity bash -lc 'cd /w; timeout 100 python3 - <<EOF
from h import *
def stm(recs,plan="S",c=None,**k):
    o=run(c or ctl(),[acct(id="AC000001",plan=plan,**k)],recs)
    return [l[1:] if 0 else l for l in lines(o)[7:-3] if l[1] and not l[1].startswith("---") and not l[1].startswith("PRIOR") and "NO ACT" not in l[1] and not l[1].startswith("TAX") and not l[1].startswith("CURR")]
big=ds(k="F",v="+999999999")
print("cap w usage",stm([big,us(svc="VOIC",q="000010000")]))
print("cap w charge",stm([big,ch(code="EQUP",amt="+000010000")]))
print("cap w deposit",stm([big,ch(code="DEPO",amt="+000010000")]))
print("cap w late",stm([big,ch(code="LATE",amt="+000001000")]))
print("cap w negcharge",stm([big,ch(code="MISC",amt="-000001000")]))
print("cap w loy",stm([big],loy="L2"))
print("cap w loy exactly",stm([ds(k="F",v="+000001000")],loy="L2"))
print("cap just under",stm([ds(k="F",v="+000000999")],loy="L2"))
print("cap just over",stm([ds(k="F",v="+000001001")],loy="L2"))
print("cap with pc",stm([big,pc(d="20250315",p="P")]))
print("cap with P",stm([ds(k="P",v="+000009000")],loy="L3"))
EOF'
```

<details><summary>output</summary>

```
cap w usage [('2025-03-01', 'BASE FEE PLAN S', '31.00', '25.00'), ('', 'USAGE VOICE MIN', '100.00', '5.00'), ('2025-03-10', 'COUPON FIXED', '', '30.00CR'), ('', 'DISCOUNT CAP', '', '15.00'), ('', 'SUBTOTAL', '', '15.00')]
cap w charge [('2025-03-01', 'BASE FEE PLAN S', '31.00', '25.00'), ('2025-03-10', 'EQUP SOME CHARGE', '', '100.00'), ('2025-03-10', 'COUPON FIXED', '', '125.00CR'), ('', 'DISCOUNT CAP', '', '62.50'), ('', 'SUBTOTAL', '', '62.50')]
cap w deposit [('2025-03-01', 'BASE FEE PLAN S', '31.00', '25.00'), ('2025-03-10', 'DEPO SOME CHARGE', '', '100.00'), ('2025-03-10', 'COUPON FIXED', '', '25.00CR'), ('', 'DISCOUNT CAP', '', '12.50'), ('', 'SUBTOTAL', '', '112.50')]
cap w late [('2025-03-01', 'BASE FEE PLAN S', '31.00', '25.00'), ('2025-03-10', 'LATE SOME CHARGE', '', '10.00'), ('2025-03-10', 'COUPON FIXED', '', '35.00CR'), ('', 'DISCOUNT CAP', '', '17.50'), ('', 'SUBTOTAL', '', '17.50')]
cap w negcharge [('2025-03-01', 'BASE FEE PLAN S', '31.00', '25.00'), ('2025-03-10', 'MISC SOME CHARGE', '', '10.00CR'), ('2025-03-10', 'COUPON FIXED', '', '15.00CR'), ('', 'DISCOUNT CAP', '', '7.50'), ('', 'SUBTOTAL', '', '7.50')]
cap w loy [('2025-03-01', 'BASE FEE PLAN S', '31.00', '25.00'), ('', 'LOYALTY DISCOUNT L2 10%', '', '2.50CR'), ('2025-03-10', 'COUPON FIXED', '', '22.50CR'), ('', 'DISCOUNT CAP', '', '12.50'), ('', 'SUBTOTAL', '', '12.50')]
cap w loy exactly [('2025-03-01', 'BASE FEE PLAN S', '31.00', '25.00'), ('', 'LOYALTY DISCOUNT L2 10%', '', '2.50CR'), ('2025-03-10', 'COUPON FIXED', '', '10.00CR'), ('', 'SUBTOTAL', '', '12.50')]
cap just under [('2025-03-01', 'BASE FEE PLAN S', '31.00', '25.00'), ('', 'LOYALTY DISCOUNT L2 10%', '', '2.50CR'), ('2025-03-10', 'COUPON FIXED', '', '9.99CR'), ('', 'SUBTOTAL', '', '12.51')]
cap just over [('2025-03-01', 'BASE FEE PLAN S', '31.00', '25.00'), ('', 'LOYALTY DISCOUNT L2 10%', '', '2.50CR'), ('2025-03-10', 'COUPON FIXED', '', '10.01CR'), ('', 'DISCOUNT CAP', '', '0.01'), ('', 'SUBTOTAL', '', '12.50')]
cap with pc [('2025-03-01', 'BASE FEE PLAN S', '14.00', '11.29'), ('2025-03-15', 'BASE FEE PLAN P', '17.00', '32.90'), ('2025-03-10', 'COUPON FIXED', '', '44.19CR'), ('', 'DISCOUNT CAP', '', '22.09'), ('', 'SUBTOTAL', '', '22.09')]
cap with P [('2025-03-01', 'BASE FEE PLAN S', '31.00', '25.00'), ('', 'LOYALTY DISCOUNT L3 15%', '', '3.75CR'), ('2025-03-10', 'COUPON 90.00%', '', '19.13CR'), ('', 'DISCOUNT CAP', '', '10.38'), ('', 'SUBTOTAL', '', '12.50')]
```
</details>

### Step 39: Bash

```bash
docker exec sn-cobol-production-parity bash -lc 'cd /w; timeout 100 python3 - <<EOF
from h import *
def stm(recs,plan="S",c=None,**k):
    o=run(c or ctl(),[acct(id="AC000001",plan=plan,**k)],recs)
    return [l for l in lines(o)[7:-3] if l[1] and not l[1].startswith("---") and not l[1].startswith("PRIOR") and "NO ACT" not in l[1] and not l[1].startswith("TAX") and not l[1].startswith("CURR") and not l[1].startswith("BASE")]
print("P10 d12, F5 d10",stm([ds(d="20250312",k="P",v="+000001000"),ds(d="20250310",k="F",v="+000000500")]))
print("F5 d10, P10 d12",stm([ds(d="20250310",k="F",v="+000000500"),ds(d="20250312",k="P",v="+000001000")]))
print("P10 d12, P20 d10",stm([ds(d="20250312",k="P",v="+000001000"),ds(d="20250310",k="P",v="+000002000")]))
print("P10 d10, P20 d12",stm([ds(d="20250310",k="P",v="+000001000"),ds(d="20250312",k="P",v="+000002000")]))
print("F5 d12, F3 d10",stm([ds(d="20250312",k="F",v="+000000500"),ds(d="20250310",k="F",v="+000000300")]))
print("F5 d12, F3 d10, P10 d11, P50 d9",stm([ds(d="20250312",k="F",v="+000000500"),ds(d="20250310",k="F",v="+000000300"),ds(d="20250311",k="P",v="+000001000"),ds(d="20250309",k="P",v="+000005000")]))
print("F20 d12, F20 d10 (cap at remaining)",stm([ds(d="20250312",k="F",v="+000002000"),ds(d="20250310",k="F",v="+000002000")]))
print("F20 d10, F20 d12, P d11",stm([ds(d="20250310",k="F",v="+000002000"),ds(d="20250312",k="F",v="+000002000"),ds(d="20250311",k="P",v="+000002000")]))
print("same date P20,P10",stm([ds(d="20250310",k="P",v="+000002000"),ds(d="20250310",k="P",v="+000001000")]))
print("same date P10,P20",stm([ds(d="20250310",k="P",v="+000001000"),ds(d="20250310",k="P",v="+000002000")]))
EOF'
```

<details><summary>output</summary>

```
P10 d12, F5 d10 [('2025-03-10', 'COUPON FIXED', '', '5.00CR'), ('2025-03-12', 'COUPON 10.00%', '', '2.00CR'), ('', 'SUBTOTAL', '', '18.00')]
F5 d10, P10 d12 [('2025-03-10', 'COUPON FIXED', '', '5.00CR'), ('2025-03-12', 'COUPON 10.00%', '', '2.00CR'), ('', 'SUBTOTAL', '', '18.00')]
P10 d12, P20 d10 [('2025-03-10', 'COUPON 20.00%', '', '5.00CR'), ('2025-03-12', 'COUPON 10.00%', '', '2.00CR'), ('', 'SUBTOTAL', '', '18.00')]
P10 d10, P20 d12 [('2025-03-10', 'COUPON 10.00%', '', '2.50CR'), ('2025-03-12', 'COUPON 20.00%', '', '4.50CR'), ('', 'SUBTOTAL', '', '18.00')]
F5 d12, F3 d10 [('2025-03-10', 'COUPON FIXED', '', '3.00CR'), ('2025-03-12', 'COUPON FIXED', '', '5.00CR'), ('', 'SUBTOTAL', '', '17.00')]
F5 d12, F3 d10, P10 d11, P50 d9 [('2025-03-10', 'COUPON FIXED', '', '3.00CR'), ('2025-03-12', 'COUPON FIXED', '', '5.00CR'), ('2025-03-09', 'COUPON 50.00%', '', '8.50CR'), ('2025-03-11', 'COUPON 10.00%', '', '0.85CR'), ('', 'DISCOUNT CAP', '', '4.85'), ('', 'SUBTOTAL', '', '12.50')]
F20 d12, F20 d10 (cap at remaining) [('2025-03-10', 'COUPON FIXED', '', '20.00CR'), ('2025-03-12', 'COUPON FIXED', '', '5.00CR'), ('', 'DISCOUNT CAP', '', '12.50'), ('', 'SUBTOTAL', '', '12.50')]
F20 d10, F20 d12, P d11 [('2025-03-10', 'COUPON FIXED', '', '20.00CR'), ('2025-03-12', 'COUPON FIXED', '', '5.00CR'), ('2025-03-11', 'COUPON 20.00%', '', '0.00'), ('', 'DISCOUNT CAP', '', '12.50'), ('', 'SUBTOTAL', '', '12.50')]
same date P20,P10 [('2025-03-10', 'COUPON 20.00%', '', '5.00CR'), ('2025-03-10', 'COUPON 10.00%', '', '2.00CR'), ('', 'SUBTOTAL', '', '18.00')]
same date P10,P20 [('2025-03-10', 'COUPON 10.00%', '', '2.50CR'), ('2025-03-10', 'COUPON 20.00%', '', '4.50CR'), ('', 'SUBTOTAL', '', '18.00')]
```
</details>

### Step 40: Bash

```bash
docker exec sn-cobol-production-parity bash -lc 'cd /w; timeout 100 python3 - <<EOF
from h import *
def stm(recs,plan="S",c=None,**k):
    o=run(c or ctl(),[acct(id="AC000001",plan=plan,**k)],recs)
    return [l for l in lines(o)[7:-3] if l[1] and not l[1].startswith("---") and not l[1].startswith("PRIOR") and "NO ACT" not in l[1] and not l[1].startswith("CURR") and not l[1].startswith("BASE")]
L=lambda d,a,desc="LATE": ch(d=d,code="LATE",amt=a,desc=desc)
print("late 40",stm([L("20250310","+000004000")]))
print("late 100",stm([L("20250310","+000010000")]))
print("late 150",stm([L("20250310","+000015000")]))
print("late 25.01",stm([L("20250310","+000002501")]))
print("late 25.00",stm([L("20250310","+000002500")]))
print("late 20+20",stm([L("20250310","+000002000","A"),L("20250311","+000002000","B")]))
print("late 20+20+20",stm([L("20250310","+000002000","A"),L("20250311","+000002000","B"),L("20250312","+000002000","C")]))
print("late out of order",stm([L("20250312","+000002000","A"),L("20250310","+000002000","B"),L("20250311","+000002000","C")]))
print("late neg",stm([L("20250310","-000002000","A"),L("20250311","+000003000","B")]))
print("late 30 then -10 ",stm([L("20250310","+000003000","A"),L("20250311","-000001000","B")]))
print("late 30,30,-10 ",stm([L("20250310","+000003000","A"),L("20250311","+000003000","B"),L("20250312","-000001000","C")]))
EOF'
```

<details><summary>output</summary>

```
late 40 [('2025-03-10', 'LATE LATE', '', '40.00'), ('', 'LATE FEE CAP', '', '25.00CR'), ('', 'SUBTOTAL', '', '40.00'), ('', 'TAX N 8.25%', '', '3.30')]
late 100 [('2025-03-10', 'LATE LATE', '', '100.00'), ('', 'LATE FEE CAP', '', '85.00CR'), ('', 'SUBTOTAL', '', '40.00'), ('', 'TAX N 8.25%', '', '3.30')]
late 150 [('2025-03-10', 'LATE LATE', '', '150.00'), ('', 'LATE FEE CAP', '', '135.00CR'), ('', 'SUBTOTAL', '', '40.00'), ('', 'TAX N 8.25%', '', '3.30')]
late 25.01 [('2025-03-10', 'LATE LATE', '', '25.01'), ('', 'LATE FEE CAP', '', '10.01CR'), ('', 'SUBTOTAL', '', '40.00'), ('', 'TAX N 8.25%', '', '3.30')]
late 25.00 [('2025-03-10', 'LATE LATE', '', '25.00'), ('', 'LATE FEE CAP', '', '10.00CR'), ('', 'SUBTOTAL', '', '40.00'), ('', 'TAX N 8.25%', '', '3.30')]
late 20+20 [('2025-03-10', 'LATE A', '', '20.00'), ('2025-03-11', 'LATE B', '', '20.00'), ('', 'LATE FEE CAP', '', '25.00CR'), ('', 'SUBTOTAL', '', '40.00'), ('', 'TAX N 8.25%', '', '3.30')]
late 20+20+20 [('2025-03-10', 'LATE A', '', '20.00'), ('2025-03-11', 'LATE B', '', '20.00'), ('2025-03-12', 'LATE C', '', '20.00'), ('', 'LATE FEE CAP', '', '45.00CR'), ('', 'SUBTOTAL', '', '40.00'), ('', 'TAX N 8.25%', '', '3.30')]
late out of order [('2025-03-10', 'LATE B', '', '20.00'), ('2025-03-11', 'LATE C', '', '20.00'), ('2025-03-12', 'LATE A', '', '20.00'), ('', 'LATE FEE CAP', '', '45.00CR'), ('', 'SUBTOTAL', '', '40.00'), ('', 'TAX N 8.25%', '', '3.30')]
late neg [('2025-03-10', 'LATE A', '', '20.00CR'), ('2025-03-11', 'LATE B', '', '30.00'), ('', 'SUBTOTAL', '', '35.00'), ('', 'TAX N 8.25%', '', '2.89')]
late 30 then -10  [('2025-03-10', 'LATE A', '', '30.00'), ('2025-03-11', 'LATE B', '', '10.00CR'), ('', 'LATE FEE CAP', '', '5.00CR'), ('', 'SUBTOTAL', '', '40.00'), ('', 'TAX N 8.25%', '', '3.30')]
late 30,30,-10  [('2025-03-10', 'LATE A', '', '30.00'), ('2025-03-11', 'LATE B', '', '30.00'), ('2025-03-12', 'LATE C', '', '10.00CR'), ('', 'LATE FEE CAP', '', '35.00CR'), ('', 'SUBTOTAL', '', '40.00'), ('', 'TAX N 8.25%', '', '3.30')]
```
</details>

### Step 41: Bash

```bash
docker exec sn-cobol-production-parity bash -lc 'cd /w; timeout 100 python3 - <<EOF
from h import *
def stm(recs,plan="S",c=None,**k):
    o=run(c or ctl(),[acct(id="AC000001",plan=plan,**k)],recs)
    return [l for l in lines(o)[7:-3] if l[1] and not l[1].startswith("---") and not l[1].startswith("PRIOR") and "NO ACT" not in l[1] and not l[1].startswith("CURR") and not l[1].startswith("BASE")]
L=lambda d,a,desc="LATE": ch(d=d,code="LATE",amt=a,desc=desc)
print("late 15.00",stm([L("20250310","+000001500")]))
print("late 15.01",stm([L("20250310","+000001501")]))
print("late100+P10+L2",stm([L("20250310","+000010000"),ds(k="P",v="+000001000")],loy="L2"))
print("late100+F big",stm([L("20250310","+000010000"),ds(k="F",v="+000100000")],loy="L2"))
print("deposit neg",stm([ch(code="DEPO",amt="-000001000")]))
print("deposit+misc",stm([ch(code="DEPO",amt="+000005000"),ch(code="MISC",amt="+000001000")]))
print("exempt dep",stm([ch(code="DEPO",amt="+000005000")],tc="E"))
print("R dep",stm([ch(code="DEPO",amt="+000005000"),ch(code="MISC",amt="+000001234")],tc="R"))
EOF'
```

<details><summary>output</summary>

```
late 15.00 [('2025-03-10', 'LATE LATE', '', '15.00'), ('', 'SUBTOTAL', '', '40.00'), ('', 'TAX N 8.25%', '', '3.30')]
late 15.01 [('2025-03-10', 'LATE LATE', '', '15.01'), ('', 'LATE FEE CAP', '', '0.01CR'), ('', 'SUBTOTAL', '', '40.00'), ('', 'TAX N 8.25%', '', '3.30')]
late100+P10+L2 [('2025-03-10', 'LATE LATE', '', '100.00'), ('', 'LATE FEE CAP', '', '85.00CR'), ('', 'LOYALTY DISCOUNT L2 10%', '', '2.50CR'), ('2025-03-10', 'COUPON 10.00%', '', '3.75CR'), ('', 'SUBTOTAL', '', '33.75'), ('', 'TAX N 8.25%', '', '2.78')]
late100+F big [('2025-03-10', 'LATE LATE', '', '100.00'), ('', 'LATE FEE CAP', '', '85.00CR'), ('', 'LOYALTY DISCOUNT L2 10%', '', '2.50CR'), ('2025-03-10', 'COUPON FIXED', '', '37.50CR'), ('', 'DISCOUNT CAP', '', '20.00'), ('', 'SUBTOTAL', '', '20.00'), ('', 'TAX N 8.25%', '', '1.65')]
deposit neg [('2025-03-10', 'DEPO SOME CHARGE', '', '10.00CR'), ('', 'SUBTOTAL', '', '15.00'), ('', 'TAX N 8.25%', '', '2.06')]
deposit+misc [('2025-03-10', 'DEPO SOME CHARGE', '', '50.00'), ('2025-03-10', 'MISC SOME CHARGE', '', '10.00'), ('', 'SUBTOTAL', '', '85.00'), ('', 'TAX N 8.25%', '', '2.89')]
exempt dep [('2025-03-10', 'DEPO SOME CHARGE', '', '50.00'), ('', 'SUBTOTAL', '', '75.00'), ('', 'TAX E 0.00%', '', '0.00')]
R dep [('2025-03-10', 'DEPO SOME CHARGE', '', '50.00'), ('2025-03-10', 'MISC SOME CHARGE', '', '12.34'), ('', 'SUBTOTAL', '', '87.34'), ('', 'TAX R 4.00%', '', '1.49')]
```
</details>

### Step 42: Bash

```bash
docker exec sn-cobol-production-parity bash -lc 'cd /w; timeout 100 python3 - <<EOF
from h import *
cs=[c for c in range(2500,3500) if (c*825)%10000==5000]
print(cs[:10])
for c in cs[:4]:
    m=c-2500
    o=run(ctl(),[acct(id="AC000001",plan="S")],[ch(code="MISC",amt="+%09d"%m)])
    print(c,[l for l in lines(o) if l[1].startswith("TAX") or l[1].startswith("SUBT")])
# also negative-tax case and near-zero
EOF'
```

<details><summary>output</summary>

```
[2600, 3000, 3400]
2600 [('', 'SUBTOTAL', '', '26.00'), ('', 'TAX N 8.25%', '', '2.15')]
3000 [('', 'SUBTOTAL', '', '30.00'), ('', 'TAX N 8.25%', '', '2.48')]
3400 [('', 'SUBTOTAL', '', '34.00'), ('', 'TAX N 8.25%', '', '2.81')]
```
</details>

### Step 43: Bash

```bash
docker exec sn-cobol-production-parity bash -lc 'cd /w; timeout 100 python3 - <<EOF
from h import *
def summ(recs,**k):
    o=run(ctl(),[acct(id="AC000001",plan="S",**k)],recs)
    s=o["SUMMARY.RPT"].split("\n")
    return [x for x in s if x.startswith("TOTAL")][:8]
L=lambda d,a,desc="LATE": ch(d=d,code="LATE",amt=a,desc=desc)
print("late100+F big",summ([L("20250310","+000010000"),ds(k="F",v="+000100000")],loy="L2"))
print("late 100",summ([L("20250310","+000010000")]))
print("dep",summ([ch(code="DEPO",amt="+000005000")]))
print("adj/pay",summ([ad(amt="+000005000"),ad(amt="-000001000"),py(amt="+000002000")]))
print("cap",summ([ds(k="F",v="+000100000")]))
EOF'
```

<details><summary>output</summary>

```
late100+F big ['TOTAL BASE FEES                    25.00', 'TOTAL USAGE                         0.00', 'TOTAL CHARGES                      15.00', 'TOTAL DISCOUNTS                    20.00', 'TOTAL TAX                           1.65', 'TOTAL ADJUSTMENTS                   0.00', 'TOTAL PAYMENTS                      0.00', 'TOTAL AMOUNT DUE                   21.65']
late 100 ['TOTAL BASE FEES                    25.00', 'TOTAL USAGE                         0.00', 'TOTAL CHARGES                      15.00', 'TOTAL DISCOUNTS                     0.00', 'TOTAL TAX                           3.30', 'TOTAL ADJUSTMENTS                   0.00', 'TOTAL PAYMENTS                      0.00', 'TOTAL AMOUNT DUE                   43.30']
dep ['TOTAL BASE FEES                    25.00', 'TOTAL USAGE                         0.00', 'TOTAL CHARGES                      50.00', 'TOTAL DISCOUNTS                     0.00', 'TOTAL TAX                           2.06', 'TOTAL ADJUSTMENTS                   0.00', 'TOTAL PAYMENTS                      0.00', 'TOTAL AMOUNT DUE                   77.06']
adj/pay ['TOTAL BASE FEES                    25.00', 'TOTAL USAGE                         0.00', 'TOTAL CHARGES                       0.00', 'TOTAL DISCOUNTS                     0.00', 'TOTAL TAX                           2.06', 'TOTAL ADJUSTMENTS                  40.00', 'TOTAL PAYMENTS                     20.00', 'TOTAL AMOUNT DUE                   47.06']
cap ['TOTAL BASE FEES                    25.00', 'TOTAL USAGE                         0.00', 'TOTAL CHARGES                       0.00', 'TOTAL DISCOUNTS                    12.50', 'TOTAL TAX                           1.03', 'TOTAL ADJUSTMENTS                   0.00', 'TOTAL PAYMENTS                      0.00', 'TOTAL AMOUNT DUE                   13.53']
```
</details>

### Step 44: Bash

```bash
docker exec sn-cobol-production-parity bash -lc 'cd /w; timeout 100 python3 - <<EOF
from h import *
A=[acct(id="AC000001",plan="P",reg="NE"),acct(id="AC000002",plan="P",reg="NE",bal="+999999999"),acct(id="AC000003",plan="B",reg="W",bal="-000100000"),acct(id="AC000004",plan="B",reg="  ",bal="-000100000")]
o=run(ctl(),A,[ch(code="MISC",amt="+999999999",d="20250310"),ch(a="AC000002",code="MISC",amt="+999999999",d="20250310"),ch(a="AC000003",code="MISC",amt="-999999999",d="20250310")])
for l in o["SUMMARY.RPT"].split("\n"): print(len(l),repr(l))
for l in lines(o): 
    if l[1].startswith("AMOUNT") or l[1].startswith("PRIOR"): print(l)
EOF'
```

<details><summary>output</summary>

```
43 'BILLRUN 4.2 RUN SUMMARY          RUN 000001'
12 'COMPANY ACME'
35 'ACCOUNTS READ                     4'
35 'ACCOUNTS BILLED                   4'
35 'ACCOUNTS NOT IN CYCLE             0'
35 'ACCOUNTS REJECTED                 0'
35 'ACTIVITY READ                     3'
35 'ACTIVITY ACCEPTED                 3'
35 'ACTIVITY REJECTED                 0'
35 'STATEMENTS PRODUCED               4'
40 'TOTAL BASE FEES                   140.00'
40 'TOTAL USAGE                         0.00'
40 'TOTAL CHARGES               9,999,999.99'
40 'TOTAL DISCOUNTS                     0.00'
40 'TOTAL TAX                          10.73'
40 'TOTAL ADJUSTMENTS                   0.00'
40 'TOTAL PAYMENTS                      0.00'
40 'TOTAL AMOUNT DUE               -1,849.29'
20 'AMOUNT DUE BY REGION'
40 '  REGION                         -989.17'
40 '  REGION NE                       129.87'
40 '  REGION W                       -989.99'
0 ''
('', 'PRIOR BALANCE', '', '1,000.00CR')
('', 'AMOUNT DUE', '', '989.17CR')
('', 'PRIOR BALANCE', '', '0.00')
('', 'AMOUNT DUE', '', '64.94')
('', 'PRIOR BALANCE', '', '9,999,999.99')
('', 'AMOUNT DUE', '', '64.93')
('', 'PRIOR BALANCE', '', '1,000.00CR')
('', 'AMOUNT DUE', '', '989.99CR')
```
</details>

### Step 45: Bash

```bash
docker exec sn-cobol-production-parity bash -lc 'cd /w; timeout 100 python3 - <<EOF
from h import *
print("S open 16th data5",usage("S","DATA",500,op="20250316"), "full",usage("S","DATA",500))
print("P open 16th data10",usage("P","DATA",1000,op="20250316"), "full",usage("P","DATA",1000))
print("P open 16th sms150",usage("P","SMS ",15000,op="20250316"), "full",usage("P","SMS ",15000))
print("P susp sms150",usage("P","SMS ",15000,extra=[su(d="20250301",e="20250310")]))
print("S susp data5",usage("S","DATA",500,extra=[su(d="20250301",e="20250310")]))
print("P PC to B sms150",usage("P","SMS ",15000,extra=[pc(d="20250302",p="B")]))
def t(recs,plan="B",**k):
    o=run(ctl(),[acct(id="AC000001",plan=plan,**k)],recs)
    return [l for l in lines(o)[7:-3] if l[1] and not l[1].startswith("---")]
print(t([py(amt="+000000500")]))
print(t([ad(amt="+000000500")]))
print(t([us(d="20250305"),ch(a="AC000001",d="20250301",code="EQUP",amt="+000000100"),ds(d="20250310",k="F",v="+000000100")]))
EOF'
```

<details><summary>output</summary>

```
S open 16th data5 None full ('5.00', '4.50')
P open 16th data10 None full ('10.00', '7.50')
P open 16th sms150 None full ('150.00', '1.00')
P susp sms150 ('150.00', '1.00')
S susp data5 ('5.00', '4.50')
P PC to B sms150 ('150.00', '4.50')
[('2025-03-01', 'BASE FEE PLAN B', '31.00', '10.00'), ('', 'SUBTOTAL', '', '10.00'), ('', 'TAX N 8.25%', '', '0.83'), ('', 'CURRENT CHARGES', '', '10.83'), ('', 'PRIOR BALANCE', '', '0.00'), ('2025-03-10', 'PAYMENT RECEIVED', '', '5.00CR')]
[('2025-03-01', 'BASE FEE PLAN B', '31.00', '10.00'), ('', 'SUBTOTAL', '', '10.00'), ('', 'TAX N 8.25%', '', '0.83'), ('2025-03-10', 'ADJ REASON', '', '5.00'), ('', 'CURRENT CHARGES', '', '15.83'), ('', 'PRIOR BALANCE', '', '0.00')]
[('2025-03-01', 'BASE FEE PLAN B', '31.00', '10.00'), ('', 'USAGE VOICE MIN', '10.00', '0.50'), ('2025-03-01', 'EQUP SOME CHARGE', '', '1.00'), ('2025-03-10', 'COUPON FIXED', '', '1.00CR'), ('', 'SUBTOTAL', '', '10.50'), ('', 'TAX N 8.25%', '', '0.87'), ('', 'CURRENT CHARGES', '', '11.37'), ('', 'PRIOR BALANCE', '', '0.00')]
```
</details>

### Step 46: Bash

```bash
docker exec sn-cobol-production-parity bash -lc 'cd /w; timeout 100 python3 - <<EOF
from h import *
o=run(ctl(),[],[]); show(o)
o=run(ctl(),None,None); print(o["rc"], repr(o["SUMMARY.RPT"][-80:]))
o=run(ctl(),[acct(id="AC000001")],[us(svc="XXXX")]); print([l for l in lines(o) if "NO ACT" in l[1]], o["rc"])
o=run(ctl(),[acct(id="AC000001",plan="S")],[us(),us(d="20250311",q="000002000")]); 
# negative discount base
def t(recs,plan="S",**k):
    o=run(ctl(),[acct(id="AC000001",plan=plan,**k)],recs)
    return [l for l in lines(o)[7:-3] if l[1] and not l[1].startswith("---") and not l[1].startswith("PRIOR")]
print(t([ch(code="MISC",amt="-000010000"),ds(k="F",v="+000000500")],loy="L1"))
print(t([ch(code="MISC",amt="-000010000"),ds(k="P",v="+000000500")],loy="L1"))
print(t([ch(code="MISC",amt="-000002500"),ds(k="P",v="+000000500"),ds(k="F",v="+000000500")],loy="L1"))
EOF'
```

<details><summary>output</summary>

```
==STATEMENTS.RPT

==REJECTS.RPT
BILLRUN.4.2.REJECT.REPORT..........RUN.000001
SEQ....SRC..CODE.MESSAGE................RECORD
TOTAL.REJECTS.....0

==SUMMARY.RPT
BILLRUN.4.2.RUN.SUMMARY..........RUN.000001
COMPANY.ACME
ACCOUNTS.READ.....................0
ACCOUNTS.BILLED...................0
ACCOUNTS.NOT.IN.CYCLE.............0
ACCOUNTS.REJECTED.................0
ACTIVITY.READ.....................0
ACTIVITY.ACCEPTED.................0
ACTIVITY.REJECTED.................0
STATEMENTS.PRODUCED...............0
TOTAL.BASE.FEES.....................0.00
TOTAL.USAGE.........................0.00
TOTAL.CHARGES.......................0.00
TOTAL.DISCOUNTS.....................0.00
TOTAL.TAX...........................0.00
TOTAL.ADJUSTMENTS...................0.00
TOTAL.PAYMENTS......................0.00
TOTAL.AMOUNT.DUE....................0.00

rc 0 
0 'TAL PAYMENTS                      0.00\nTOTAL AMOUNT DUE                    0.00\n'
[('', 'NO ACTIVITY THIS PERIOD', '', '')] 4
[('2025-03-01', 'BASE FEE PLAN S', '31.00', '25.00'), ('2025-03-10', 'MISC SOME CHARGE', '', '100.00CR'), ('', 'COUPON L1.00%', '', '0.00'), ('', 'SUBTOTAL', '', '75.00CR'), ('', 'TAX N 8.25%', '', '0.00'), ('', 'CURRENT CHARGES', '', '75.00CR')]
[('2025-03-01', 'BASE FEE PLAN S', '31.00', '25.00'), ('2025-03-10', 'MISC SOME CHARGE', '', '100.00CR'), ('', 'COUPON L1.00%', '', '0.00'), ('', 'SUBTOTAL', '', '75.00CR'), ('', 'TAX N 8.25%', '', '0.00'), ('', 'CURRENT CHARGES', '', '75.00CR')]
[('2025-03-01', 'BASE FEE PLAN S', '31.00', '25.00'), ('2025-03-10', 'MISC SOME CHARGE', '', '25.00CR'), ('', 'COUPON L1.00%', '', '0.00'), ('', 'COUPON L1.00%', '', '0.00'), ('', 'SUBTOTAL', '', '0.00'), ('', 'TAX N 8.25%', '', '0.00'), ('', 'CURRENT CHARGES', '', '0.00')]
```
</details>

### Step 47: Bash

```bash
docker exec sn-cobol-production-parity bash -lc 'cd /w; timeout 100 python3 - <<EOF
from h import *
o=run(ctl(),[acct(id="AC000001",plan="S",loy="L1")],[ch(code="MISC",amt="-000010000"),ds(k="F",v="+000000500")]); show(o)
EOF'
```

<details><summary>output</summary>

```
==STATEMENTS.RPT
========================================================================
ACME............................BILLING.STATEMENT..RUN.000001
ACCOUNT.AC000001..TEST.CUSTOMER.............REGION.NE
PERIOD.2025-03-01.TO.2025-03-31..DAYS.31..PLAN.S
------------------------------------------------------------------------
DATE.......DESCRIPTION............................QTY..........AMOUNT
------------------------------------------------------------------------
2025-03-01.BASE.FEE.PLAN.S.....................31.00.........25.00
2025-03-10.MISC.SOME.CHARGE.................................100.00CR
...........COUPON.L1.00%......................................0.00
...........SUBTOTAL..........................................75.00CR
...........TAX.N.8.25%........................................0.00
...........CURRENT.CHARGES...................................75.00CR
...........PRIOR.BALANCE......................................0.00
------------------------------------------------------------------------
...........AMOUNT.DUE........................................75.00CR

==REJECTS.RPT
BILLRUN.4.2.REJECT.REPORT..........RUN.000001
SEQ....SRC..CODE.MESSAGE................RECORD
TOTAL.REJECTS.....0

==SUMMARY.RPT
BILLRUN.4.2.RUN.SUMMARY..........RUN.000001
COMPANY.ACME
ACCOUNTS.READ.....................1
ACCOUNTS.BILLED...................1
ACCOUNTS.NOT.IN.CYCLE.............0
ACCOUNTS.REJECTED.................0
ACTIVITY.READ.....................2
ACTIVITY.ACCEPTED.................2
ACTIVITY.REJECTED.................0
STATEMENTS.PRODUCED...............1
TOTAL.BASE.FEES....................25.00
TOTAL.USAGE.........................0.00
TOTAL.CHARGES....................-100.00
TOTAL.DISCOUNTS.....................0.00
TOTAL.TAX...........................0.00
TOTAL.ADJUSTMENTS...................0.00
TOTAL.PAYMENTS......................0.00
TOTAL.AMOUNT.DUE..................-75.00
AMOUNT.DUE.BY.REGION
..REGION.NE.......................-75.00

rc 0
```
</details>

### Step 48: Bash

```bash
docker exec sn-cobol-production-parity bash -lc 'cd /w; timeout 100 python3 - <<EOF
from h import *
def t(recs,plan="S",**k):
    o=run(ctl(),[acct(id="AC000001",plan=plan,**k)],recs)
    return [(l[0],l[1],l[3]) for l in lines(o)[7:-3] if l[1] and not l[1].startswith("---") and not l[1].startswith("PRIOR") and not l[1].startswith("TAX")and not l[1].startswith("CURR") and not l[1].startswith("BASE")]
neg=ch(code="MISC",amt="-000010000")
print("loy blank F5",t([neg,ds(k="F",v="+000000500")],loy="  "))
print("loy L2 F5",t([neg,ds(k="F",v="+000000500")],loy="L2"))
print("loy L2 P50",t([neg,ds(k="P",v="+000005000")],loy="L2"))
print("loy L2 P50 F7",t([neg,ds(k="P",v="+000005000",d="20250312"),ds(k="F",v="+000000700",d="20250311")],loy="L2"))
print("loy L2 none",t([neg],loy="L2"))
print("loy L2, zero base via exact",t([ch(code="MISC",amt="-000002500"),ds(k="F",v="+000000700",d="20250311")],loy="L2"))
print("base 0.01",t([ch(code="MISC",amt="-000002499"),ds(k="F",v="+000000700",d="20250311")],loy="L2"))
print("base 0.01 P",t([ch(code="MISC",amt="-000002499"),ds(k="P",v="+000001000",d="20250311")],loy="L2"))
print("base 1.00 P",t([ch(code="MISC",amt="-000002400"),ds(k="P",v="+000001000",d="20250311")],loy="L2"))
print("base 1.00 F big",t([ch(code="MISC",amt="-000002400"),ds(k="F",v="+000100000",d="20250311")],loy="L2"))
print("base 0 with usage",t([ch(code="MISC",amt="-000003000"),us(svc="VOIC",q="000010000"),ds(k="F",v="+000100000",d="20250311")],loy="L2"))
EOF'
```

<details><summary>output</summary>

```
loy blank F5 [('2025-03-10', 'MISC SOME CHARGE', '100.00CR'), ('', 'COUPON   .00%', '0.00'), ('', 'SUBTOTAL', '75.00CR')]
loy L2 F5 [('2025-03-10', 'MISC SOME CHARGE', '100.00CR'), ('', 'COUPON L2.00%', '0.00'), ('', 'SUBTOTAL', '75.00CR')]
loy L2 P50 [('2025-03-10', 'MISC SOME CHARGE', '100.00CR'), ('', 'COUPON L2.00%', '0.00'), ('', 'SUBTOTAL', '75.00CR')]
loy L2 P50 F7 [('2025-03-10', 'MISC SOME CHARGE', '100.00CR'), ('', 'COUPON L2.00%', '0.00'), ('', 'COUPON L2.00%', '0.00'), ('', 'SUBTOTAL', '75.00CR')]
loy L2 none [('2025-03-10', 'MISC SOME CHARGE', '100.00CR'), ('', 'SUBTOTAL', '75.00CR')]
loy L2, zero base via exact [('2025-03-10', 'MISC SOME CHARGE', '25.00CR'), ('', 'COUPON L2.00%', '0.00'), ('', 'SUBTOTAL', '0.00')]
base 0.01 [('2025-03-10', 'MISC SOME CHARGE', '24.99CR'), ('', 'LOYALTY DISCOUNT L2 10%', '2.50CR'), ('2025-03-11', 'COUPON FIXED', '0.00'), ('', 'DISCOUNT CAP', '2.49'), ('', 'SUBTOTAL', '0.00')]
base 0.01 P [('2025-03-10', 'MISC SOME CHARGE', '24.99CR'), ('', 'LOYALTY DISCOUNT L2 10%', '2.50CR'), ('2025-03-11', 'COUPON 10.00%', '0.00'), ('', 'DISCOUNT CAP', '2.49'), ('', 'SUBTOTAL', '0.00')]
base 1.00 P [('2025-03-10', 'MISC SOME CHARGE', '24.00CR'), ('', 'LOYALTY DISCOUNT L2 10%', '2.50CR'), ('2025-03-11', 'COUPON 10.00%', '0.00'), ('', 'DISCOUNT CAP', '2.00'), ('', 'SUBTOTAL', '0.50')]
base 1.00 F big [('2025-03-10', 'MISC SOME CHARGE', '24.00CR'), ('', 'LOYALTY DISCOUNT L2 10%', '2.50CR'), ('2025-03-11', 'COUPON FIXED', '0.00'), ('', 'DISCOUNT CAP', '2.00'), ('', 'SUBTOTAL', '0.50')]
base 0 with usage [('', 'USAGE VOICE MIN', '5.00'), ('2025-03-10', 'MISC SOME CHARGE', '30.00CR'), ('', 'COUPON L2.00%', '0.00'), ('', 'SUBTOTAL', '0.00')]
```
</details>

### Step 49: Bash

```bash
docker exec sn-cobol-production-parity bash -lc 'cd /app/src; cp -r /app/src /w/src37; cat lib/dateutil.cbl | head -5; cat LICENSE | head -3; ls /app/build'
```

<details><summary>output</summary>

```
      *================================================================
      * DATEUTIL - VALIDATE A YYYYMMDD DATE AND RETURN ITS DAY NUMBER
      * PART OF BILLRUN.  MIT LICENSE, SEE LICENSE.
      *================================================================
       IDENTIFICATION DIVISION.
MIT License

Copyright (c) 2026 The BILLRUN authors
```
</details>

Update DATEUTIL and copybooks first.

### Step 50: Bash

```bash
docker exec -i sn-cobol-production-parity bash -c 'cat > /app/src/lib/dateutil.cbl' <<'EOF'
      *================================================================
      * DATEUTIL - VALIDATE A YYYYMMDD DATE AND RETURN ITS DAY NUMBER
      * PART OF BILLRUN.  MIT LICENSE, SEE LICENSE.
      * 4.2: CALENDAR-ACCURATE, YEARS 1900 THROUGH 9999.
      *================================================================
       IDENTIFICATION DIVISION.
       PROGRAM-ID. DATEUTIL.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-YY                       PIC 9(4).
       01  WS-MM                       PIC 99.
       01  WS-DD                       PIC 99.
       01  WS-MAX                      PIC 99.
       01  WS-Q                        PIC 9(4).
       01  WS-R4                       PIC 9(4).
       01  WS-R100                     PIC 9(4).
       01  WS-R400                     PIC 9(4).
       01  MONTH-DAY-VALUES            PIC X(24)
                                VALUE "312831303130313130313031".
       01  MONTH-DAY-TABLE REDEFINES MONTH-DAY-VALUES.
           05  MD-DAYS OCCURS 12 TIMES PIC 99.
       LINKAGE SECTION.
       COPY DUPARM.
       PROCEDURE DIVISION USING DU-PARMS.
       0000-MAIN.
           MOVE "N" TO DU-VALID
           MOVE 0 TO DU-DAYNUM
           IF DU-DATE IS NOT NUMERIC
               GOBACK
           END-IF
           MOVE DU-DATE(1:4) TO WS-YY
           MOVE DU-DATE(5:2) TO WS-MM
           MOVE DU-DATE(7:2) TO WS-DD
           IF WS-YY < 1900
               GOBACK
           END-IF
           IF WS-MM < 1 OR WS-MM > 12
               GOBACK
           END-IF
           MOVE MD-DAYS(WS-MM) TO WS-MAX
           IF WS-MM = 2
               DIVIDE WS-YY BY 4 GIVING WS-Q REMAINDER WS-R4
               DIVIDE WS-YY BY 100 GIVING WS-Q REMAINDER WS-R100
               DIVIDE WS-YY BY 400 GIVING WS-Q REMAINDER WS-R400
               IF WS-R4 = 0 AND (WS-R100 NOT = 0 OR WS-R400 = 0)
                   MOVE 29 TO WS-MAX
               END-IF
           END-IF
           IF WS-DD < 1 OR WS-DD > WS-MAX
               GOBACK
           END-IF
           MOVE "Y" TO DU-VALID
           COMPUTE DU-DAYNUM = FUNCTION INTEGER-OF-DATE(DU-DATE-N)
           GOBACK.
EOF
docker exec -i sn-cobol-production-parity bash -c 'cd /app/src/copy; python3 - <<PY
s=open("ACTREC.cpy").read()
s=s.replace("""           05  XR-PC-DATA REDEFINES XR-DATA.
               10  XR-PC-PLAN              PIC X.
               10  FILLER                  PIC X(61).
""","""           05  XR-PC-DATA REDEFINES XR-DATA.
               10  XR-PC-PLAN              PIC X.
               10  FILLER                  PIC X(61).
           05  XR-DS-DATA REDEFINES XR-DATA.
               10  XR-DS-KIND              PIC X.
               10  FILLER                  PIC X(61).
           05  XR-SU-DATA REDEFINES XR-DATA.
               10  XR-SU-END               PIC X(8).
               10  FILLER                  PIC X(54).
""")
s=s.replace("AD ADJUSTMENT","AD ADJUSTMENT  DS COUPON  SU SUSPENSION")
open("ACTREC.cpy","w").write(s)
PY
cat ACTREC.cpy | tail -12'
```

<details><summary>output</summary>

```
               10  XR-CH-CODE          PIC X(4).
               10  XR-CH-AMOUNT.
                   15  XR-CH-SIGN      PIC X.
                   15  XR-CH-DIGITS    PIC X(9).
               10  XR-CH-DIGITS-N REDEFINES XR-CH-AMOUNT.
                   15  FILLER          PIC X.
                   15  XR-CH-VALUE     PIC 9(7)V99.
               10  XR-CH-DESC          PIC X(20).
               10  FILLER              PIC X(28).
           05  XR-PC-DATA REDEFINES XR-DATA.
               10  XR-PC-PLAN          PIC X.
               10  FILLER              PIC X(61).
```
</details>

### Step 51: Bash

```bash
docker exec -i sn-cobol-production-parity bash -c 'cd /app/src/copy; cat >> ACTREC.cpy <<EOF
           05  XR-DS-DATA REDEFINES XR-DATA.
               10  XR-DS-KIND          PIC X.
               10  FILLER              PIC X(61).
           05  XR-SU-DATA REDEFINES XR-DATA.
               10  XR-SU-END           PIC X(8).
               10  FILLER              PIC X(54).
EOF
sed -i "s/AD ADJUSTMENT/AD ADJUSTMENT  DS COUPON  SU SUSPENSION/" ACTREC.cpy; head -8 ACTREC.cpy'
```

<details><summary>output</summary>

```
      *----------------------------------------------------------------
      * ACTREC - ACTIVITY RECORD (ACTIVITY.DAT), 80 BYTES
      *   US USAGE  CH CHARGE  PC PLAN CHANGE  PY PAYMENT
      *   AD ADJUSTMENT  DS COUPON  SU SUSPENSION  DS COUPON  SU SUSPENSION
      *----------------------------------------------------------------
       01  ACT-RECORD.
           05  XR-TYPE                 PIC XX.
           05  XR-ACCT-ID              PIC X(8).
```
</details>

### Step 52: Bash

```bash
docker exec sn-cobol-production-parity bash -c 'cd /app/src/copy; sed -i "s/  DS COUPON  SU SUSPENSION  DS COUPON  SU SUSPENSION/  DS COUPON  SU SUSPENSION/" ACTREC.cpy; sed -n 3,5p ACTREC.cpy
cat > REJMSG.cpy <<EOF
      *----------------------------------------------------------------
      * REJMSG - REJECT CODES AND MESSAGE TEXT (4.2)
      *----------------------------------------------------------------
       01  REJ-MSG-VALUES.
           05  FILLER PIC X(25) VALUE "A01MISSING ACCOUNT ID".
           05  FILLER PIC X(25) VALUE "A02DUPLICATE ACCOUNT".
           05  FILLER PIC X(25) VALUE "A03INVALID PLAN".
           05  FILLER PIC X(25) VALUE "A04INVALID OPEN DATE".
           05  FILLER PIC X(25) VALUE "A05INVALID CLOSE DATE".
           05  FILLER PIC X(25) VALUE "A06INVALID TAX CLASS".
           05  FILLER PIC X(25) VALUE "A07INVALID BALANCE".
           05  FILLER PIC X(25) VALUE "R01UNKNOWN RECORD TYPE".
           05  FILLER PIC X(25) VALUE "R02UNKNOWN ACCOUNT".
           05  FILLER PIC X(25) VALUE "R03INVALID DATE".
           05  FILLER PIC X(25) VALUE "R04DATE OUTSIDE CYCLE".
           05  FILLER PIC X(25) VALUE "R05INVALID AMOUNT".
           05  FILLER PIC X(25) VALUE "R06INVALID CODE".
           05  FILLER PIC X(25) VALUE "R07DUPLICATE ACTIVITY".
           05  FILLER PIC X(25) VALUE "R08ACCOUNT NOT ACTIVE".
           05  FILLER PIC X(25) VALUE "R09INVALID PLAN CHANGE".
           05  FILLER PIC X(25) VALUE "R10INVALID PAYMENT".
           05  FILLER PIC X(25) VALUE "R11INVALID DISCOUNT".
           05  FILLER PIC X(25) VALUE "R12INVALID SUSPENSION".
           05  FILLER PIC X(25) VALUE "C01INVALID CONTROL RECORD".
       01  REJ-MSG-TABLE REDEFINES REJ-MSG-VALUES.
           05  RM-ENTRY OCCURS 20 TIMES.
               10  RM-CODE             PIC X(3).
               10  RM-TEXT             PIC X(22).
EOF'
```

<details><summary>output</summary>

```
      *   US USAGE  CH CHARGE  PC PLAN CHANGE  PY PAYMENT
      *   AD ADJUSTMENT  DS COUPON  SU SUSPENSION
      *----------------------------------------------------------------
```
</details>

### Step 53: Bash

```bash
docker exec -i sn-cobol-production-parity bash -c 'cat > /app/src/billrun.cbl' <<'EOF'
      *================================================================
      * BILLRUN - MONTHLY BILLING AND STATEMENT BATCH
      * VERSION 4.2
      * COPYRIGHT (C) THE BILLRUN AUTHORS.  MIT LICENSE, SEE LICENSE.
      *
      * INPUT  : CONTROL.DAT  ACCOUNTS.DAT  ACTIVITY.DAT
      * OUTPUT : STATEMENTS.RPT  REJECTS.RPT  SUMMARY.RPT
      *
      * CHANGE LOG
      *   3.0  STATEMENT REWRITE, SUBPROGRAMS SPLIT OUT
      *   3.4  PLAN CHANGE RECORDS (PC)
      *   3.6  LOYALTY DISCOUNTS L1/L2
      *   3.7  REDUCED TAX CLASS R
      *   4.2  COUPONS, SUSPENSIONS, PRORATION, REVISED RATING
      *================================================================
       IDENTIFICATION DIVISION.
       PROGRAM-ID. BILLRUN.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT CTL-FILE ASSIGN TO "CONTROL.DAT"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-CTL-STAT.
           SELECT ACCT-FILE ASSIGN TO "ACCOUNTS.DAT"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-ACCT-STAT.
           SELECT ACT-FILE ASSIGN TO "ACTIVITY.DAT"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-ACT-STAT.
           SELECT STMT-FILE ASSIGN TO "STATEMENTS.RPT"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-STMT-STAT.
           SELECT REJ-FILE ASSIGN TO "REJECTS.RPT"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-REJ-STAT.
           SELECT SUM-FILE ASSIGN TO "SUMMARY.RPT"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-SUM-STAT.
       DATA DIVISION.
       FILE SECTION.
       FD  CTL-FILE.
           COPY CTLREC.
       FD  ACCT-FILE.
           COPY ACCTREC.
       FD  ACT-FILE.
           COPY ACTREC.
       FD  STMT-FILE.
       01  STMT-LINE                   PIC X(80).
       FD  REJ-FILE.
       01  REJ-LINE                    PIC X(100).
       FD  SUM-FILE.
       01  SUM-LINE                    PIC X(80).

       WORKING-STORAGE SECTION.
       01  WS-FILE-STATUS.
           05  WS-CTL-STAT             PIC XX.
           05  WS-ACCT-STAT            PIC XX.
           05  WS-ACT-STAT             PIC XX.
           05  WS-STMT-STAT            PIC XX.
           05  WS-REJ-STAT             PIC XX.
           05  WS-SUM-STAT             PIC XX.
       01  WS-SWITCHES.
           05  WS-EOF                  PIC X.
           05  WS-CTL-OK               PIC X.
           05  WS-AMT-OK               PIC X.
       01  WS-VERSION                  PIC X(3) VALUE "4.2".
       01  WS-RC                       PIC 99 VALUE 0.

       COPY REJMSG.

       COPY DUPARM.

      *    RUN CONTROL
       01  WS-CONTROL.
           05  WS-CYC-START            PIC 9(8).
           05  WS-CYC-END              PIC 9(8).
           05  WS-CYC-START-DN         PIC 9(9).
           05  WS-CYC-END-DN           PIC 9(9).
           05  WS-CYC-DAYS             PIC 999.
           05  WS-RUN-NO               PIC X(6).
           05  WS-COMPANY              PIC X(30).

      *    COUNTERS
       01  WS-COUNTERS.
           05  WS-ACCT-READ            PIC 9(5) VALUE 0.
           05  WS-ACCT-REJECTED        PIC 9(5) VALUE 0.
           05  WS-ACCT-NOCYC           PIC 9(5) VALUE 0.
           05  WS-STMT-COUNT           PIC 9(5) VALUE 0.
           05  WS-ACT-READ             PIC 9(5) VALUE 0.
           05  WS-ACT-REJECTED         PIC 9(5) VALUE 0.
           05  WS-ACT-ACCEPTED         PIC 9(5) VALUE 0.
           05  WS-REJ-TOTAL            PIC 9(5) VALUE 0.
       01  WS-REJ-COUNTS.
           05  REJ-CNT OCCURS 20 TIMES PIC 9(5) VALUE 0.

      *    RUN TOTALS
       01  WS-RUN-TOTALS.
           05  WT-BASE                 PIC S9(9)V99 VALUE 0.
           05  WT-USAGE                PIC S9(9)V99 VALUE 0.
           05  WT-CHARGES              PIC S9(9)V99 VALUE 0.
           05  WT-DISC                 PIC S9(9)V99 VALUE 0.
           05  WT-TAX                  PIC S9(9)V99 VALUE 0.
           05  WT-ADJ                  PIC S9(9)V99 VALUE 0.
           05  WT-PAY                  PIC S9(9)V99 VALUE 0.
           05  WT-DUE                  PIC S9(9)V99 VALUE 0.

      *    DUE BY REGION (ACCOUNTS ARE BILLED IN REGION ORDER)
       01  REGION-TABLE.
           05  RT-COUNT                PIC 9(4) COMP VALUE 0.
           05  RT-ENTRY OCCURS 500 TIMES.
               10  RT-REGION           PIC XX.
               10  RT-DUE              PIC S9(9)V99.

      *    ACCOUNT TABLE
       01  ACCT-TABLE.
           05  AT-COUNT                PIC 9(4) COMP VALUE 0.
           05  AT-ENTRY OCCURS 500 TIMES.
               10  AT-KEY.
                   15  AT-REGION       PIC XX.
                   15  AT-ACCT-ID      PIC X(8).
               10  AT-NAME             PIC X(24).
               10  AT-PLAN             PIC X.
               10  AT-OPEN-DATE        PIC 9(8).
               10  AT-CLOSE-DATE       PIC 9(8).
               10  AT-TAX-CLASS        PIC X.
               10  AT-PRIOR-BAL        PIC S9(7)V99.
               10  AT-LOYALTY          PIC XX.
               10  AT-INCYCLE          PIC X.

       01  ORD-TABLE.
           05  OD-COUNT                PIC 9(4) COMP VALUE 0.
           05  OD-IX OCCURS 500 TIMES  PIC 9(4) COMP.

      *    ACTIVITY TABLE (ACCEPTED RECORDS)
       01  ACT-TABLE.
           05  XT-COUNT                PIC 9(4) COMP VALUE 0.
           05  XT-ENTRY OCCURS 3000 TIMES.
               10  XT-TYPE             PIC XX.
               10  XT-ACCT-IX          PIC 9(4) COMP.
               10  XT-DATE             PIC 9(8).
               10  XT-CODE             PIC X(4).
               10  XT-QTY              PIC 9(7)V99.
               10  XT-AMOUNT           PIC S9(7)V99.
               10  XT-DESC             PIC X(20).
               10  XT-END              PIC 9(8).
               10  XT-RAW              PIC X(80).

      *    SORTED SELECTION OF ONE ACCOUNT'S ACTIVITY
       01  WS-SEL.
           05  WS-SEL-TYPE             PIC XX.
           05  WS-SEL-KIND             PIC X.
           05  SL-COUNT                PIC 9(4) COMP.
           05  SL-IX OCCURS 3000 TIMES PIC 9(4) COMP.
       01  WS-PCSEL.
           05  PC-COUNT                PIC 9(4) COMP.
           05  PC-IX OCCURS 3000 TIMES PIC 9(4) COMP.

       01  WS-INDEXES.
           05  WI                      PIC 9(4) COMP.
           05  WJ                      PIC 9(4) COMP.
           05  WK                      PIC 9(4) COMP.
           05  WL                      PIC 9(4) COMP.
           05  WX                      PIC 9(4) COMP.
           05  WA                      PIC 9(4) COMP.
           05  WD                      PIC 9(4) COMP.
           05  WP                      PIC 9(4) COMP.
           05  WN                      PIC 9(4) COMP.

       01  WS-WORK.
           05  WS-AMOUNT               PIC S9(7)V99.
           05  WS-AMT-SIGN             PIC X.
           05  WS-AMT-DIGITS           PIC X(9).
           05  WS-AMT-VALUE REDEFINES WS-AMT-DIGITS
                                       PIC 9(7)V99.
           05  WS-CLOSE-N              PIC 9(8).
           05  WS-OPEN-N               PIC 9(8).
           05  WS-REJ-CODE             PIC X(3).
           05  WS-REJ-SRC              PIC X(3).
           05  WS-REJ-SEQ              PIC 9(6).
           05  WS-REJ-RECORD           PIC X(80).
           05  WS-END-N                PIC 9(8).
           05  WS-AMT-OKF              PIC X.

      *    PER-ACCOUNT BILLING WORK AREA
       01  WS-BILL.
           05  WB-AX                   PIC 9(4) COMP.
           05  WB-BASE                 PIC S9(7)V99.
           05  WB-USAGE                PIC S9(7)V99.
           05  WB-CHARGES              PIC S9(7)V99.
           05  WB-LATE                 PIC S9(7)V99.
           05  WB-LATECAP              PIC S9(7)V99.
           05  WB-DEPOSIT              PIC S9(7)V99.
           05  WB-DISC                 PIC S9(7)V99.
           05  WB-SUBTOTAL             PIC S9(7)V99.
           05  WB-TAXABLE              PIC S9(7)V99.
           05  WB-TAX                  PIC S9(7)V99.
           05  WB-ADJ                  PIC S9(7)V99.
           05  WB-CURRENT              PIC S9(7)V99.
           05  WB-PAY                  PIC S9(7)V99.
           05  WB-DUE                  PIC S9(7)V99.
           05  WB-FINAL-PLAN           PIC X.
           05  WB-NACT                 PIC 9(5).
           05  WB-DB                   PIC S9(7)V99.
           05  WB-REM                  PIC S9(7)V99.
           05  WB-LOYAMT               PIC S9(7)V99.
           05  WB-TD                   PIC S9(7)V99.
           05  WB-LIMIT                PIC S9(7)V99.
           05  WB-CAP                  PIC S9(7)V99.
           05  WB-CAMT                 PIC S9(7)V99.
           05  WB-NCOUP                PIC 9(4).
           05  WB-PCT                  PIC 99.

      *    DAY TABLE FOR PRORATION
       01  WS-DAYS.
           05  DAY-ENTRY OCCURS 31 TIMES.
               10  DAY-DATE            PIC 9(8).
               10  DAY-PLAN            PIC X.
               10  DAY-ACT             PIC X.
               10  DAY-SUSP            PIC X.
       01  WS-SEGS.
           05  SG-COUNT                PIC 99.
           05  SG-ENTRY OCCURS 31 TIMES.
               10  SG-PLAN             PIC X.
               10  SG-DATE             PIC 9(8).
               10  SG-N                PIC 99.
               10  SG-S                PIC 99.
               10  SG-AMT              PIC S9(7)V99.
       01  WS-PRORATE.
           05  WS-FEE                  PIC 9(5)V99.
           05  WS-UNITS                PIC 999.
           05  WS-DEN                  PIC 999.

      *    USAGE WORK
       01  WS-USAGE.
           05  WU-HAS-DATA             PIC X.
           05  WU-HAS-VOIC             PIC X.
           05  WU-HAS-SMS              PIC X.
           05  WU-HAS-ROAM             PIC X.
           05  WU-DATA-QTY             PIC 9(9)V99.
           05  WU-VOIC-MIN             PIC 9(9).
           05  WU-SMS-MSG              PIC 9(9).
           05  WU-ROAM-QTY             PIC 9(9)V99.
           05  WU-ROAM-AMT             PIC 9(9)V99.
           05  WU-Q                    PIC 9(11).
           05  WU-M                    PIC 9(9).
           05  WU-C                    PIC 9(11).
           05  WU-R                    PIC 9.
           05  WU-ALLOW                PIC 9(3)V99.
           05  WU-BILLABLE             PIC 9(9)V99.
           05  WU-T1                   PIC 9(9)V99.
           05  WU-T2                   PIC 9(9)V99.
           05  WU-T3                   PIC 9(9)V99.
           05  WU-REM                  PIC 9(9)V99.
           05  WU-AMT                  PIC S9(9)V99.

      *    REPORT LINES
       01  WS-RULE-STAR                PIC X(72) VALUE ALL "=".
       01  WS-RULE-DASH                PIC X(72) VALUE ALL "-".
       01  WS-PRINT                    PIC X(100).
       01  WS-DATE-DISP                PIC X(10).
       01  WS-DATE-DISP2               PIC X(10).
       01  WS-DATE-IN                  PIC 9(8).
       01  WS-ED-COUNT                 PIC ZZZZ9.
       01  WS-ED-DAYS                  PIC Z9.
       01  WS-ED-SUM                   PIC -ZZZ,ZZZ,ZZ9.99.
       01  WS-ED-PCT                   PIC Z9.99.
       01  WS-ED-PCTW                  PIC Z9.
       01  WS-ED-QTY                   PIC Z,ZZZ,ZZ9.99.
       01  WS-TAXRATE                  PIC 9V9(4).
       01  WS-TAXDISP                  PIC X(6).

       01  WP-PARMS.
           05  WP-DATE                 PIC 9(8).
           05  WP-DESC                 PIC X(29).
           05  WP-HASQTY               PIC X.
           05  WP-QTY                  PIC 9(9)V99.
           05  WP-AMT                  PIC S9(7)V99.

       01  DL-LINE.
           05  DL-DATE                 PIC X(10).
           05  FILLER                  PIC X VALUE SPACE.
           05  DL-DESC                 PIC X(29).
           05  DL-QTY                  PIC X(12).
           05  FILLER                  PIC X(2) VALUE SPACES.
           05  DL-AMT                  PIC Z,ZZZ,ZZ9.99.
           05  DL-CR                   PIC XX.

       01  RJ-DETAIL.
           05  RJ-SEQ                  PIC 9(6).
           05  FILLER                  PIC X VALUE SPACE.
           05  RJ-SRC                  PIC X(3).
           05  FILLER                  PIC X(2) VALUE SPACES.
           05  RJ-CODE                 PIC X(3).
           05  FILLER                  PIC X(2) VALUE SPACES.
           05  RJ-MSG                  PIC X(22).
           05  FILLER                  PIC X VALUE SPACE.
           05  RJ-REC                  PIC X(40).

       PROCEDURE DIVISION.
      *----------------------------------------------------------------
      * MAIN LINE. CONTROL, LOAD, BILL, REPORT.
      *----------------------------------------------------------------
       0000-MAIN.
           PERFORM 1000-INIT
           PERFORM 1100-READ-CONTROL
           IF WS-CTL-OK = "N"
               PERFORM 1900-CONTROL-FAIL
           ELSE
               PERFORM 2000-LOAD-ACCOUNTS
               PERFORM 3000-LOAD-ACTIVITY
               PERFORM 4900-ORDER-ACCOUNTS
               PERFORM 5000-PRODUCE-STATEMENTS
               PERFORM 7900-REJECT-TRAILER
               PERFORM 8000-WRITE-SUMMARY
               IF WS-REJ-TOTAL > 0
                   MOVE 4 TO WS-RC
               END-IF
           END-IF
           PERFORM 9000-CLOSE
           MOVE WS-RC TO RETURN-CODE
           STOP RUN.

       1000-INIT.
           OPEN OUTPUT STMT-FILE
           OPEN OUTPUT REJ-FILE
           OPEN OUTPUT SUM-FILE.

      *----------------------------------------------------------------
      * READ AND VALIDATE THE CONTROL RECORD.
      *----------------------------------------------------------------
       1100-READ-CONTROL.
           MOVE "Y" TO WS-CTL-OK
           MOVE SPACES TO CTL-RECORD
           OPEN INPUT CTL-FILE
           IF WS-CTL-STAT NOT = "00"
               MOVE "N" TO WS-CTL-OK
           ELSE
               READ CTL-FILE
                   AT END MOVE "N" TO WS-CTL-OK
               END-READ
               CLOSE CTL-FILE
           END-IF
           MOVE CTL-RUN-NO TO WS-RUN-NO
           MOVE CTL-COMPANY TO WS-COMPANY
           PERFORM 1200-REJECT-HEADER
           IF WS-CTL-OK = "Y"
               MOVE CTL-START-DATE TO DU-DATE
               CALL "DATEUTIL" USING DU-PARMS
               IF DU-VALID NOT = "Y"
                   MOVE "N" TO WS-CTL-OK
               ELSE
                   MOVE DU-DATE-N TO WS-CYC-START
                   MOVE DU-DAYNUM TO WS-CYC-START-DN
               END-IF
           END-IF
           IF WS-CTL-OK = "Y"
               MOVE CTL-END-DATE TO DU-DATE
               CALL "DATEUTIL" USING DU-PARMS
               IF DU-VALID NOT = "Y"
                   MOVE "N" TO WS-CTL-OK
               ELSE
                   MOVE DU-DATE-N TO WS-CYC-END
                   MOVE DU-DAYNUM TO WS-CYC-END-DN
               END-IF
           END-IF
           IF WS-CTL-OK = "Y"
               IF WS-CYC-END < WS-CYC-START
                   MOVE "N" TO WS-CTL-OK
               ELSE
                   COMPUTE WS-CYC-DAYS =
                       WS-CYC-END-DN - WS-CYC-START-DN + 1
                   IF WS-CYC-END-DN - WS-CYC-START-DN + 1 > 31
                       MOVE "N" TO WS-CTL-OK
                   END-IF
               END-IF
           END-IF.

       1200-REJECT-HEADER.
           MOVE SPACES TO WS-PRINT
           STRING "BILLRUN " WS-VERSION " REJECT REPORT          RUN "
                  WS-RUN-NO
                  DELIMITED BY SIZE INTO WS-PRINT
           WRITE REJ-LINE FROM WS-PRINT
           MOVE SPACES TO WS-PRINT
           STRING "SEQ    SRC  CODE MESSAGE                RECORD"
                  DELIMITED BY SIZE INTO WS-PRINT
           WRITE REJ-LINE FROM WS-PRINT.

       1900-CONTROL-FAIL.
           MOVE "C01" TO WS-REJ-CODE
           MOVE "CTL" TO WS-REJ-SRC
           MOVE 1 TO WS-REJ-SEQ
           MOVE CTL-RECORD TO WS-REJ-RECORD
           PERFORM 7000-WRITE-REJECT
           PERFORM 7900-REJECT-TRAILER
           MOVE SPACES TO WS-PRINT
           STRING "BILLRUN " WS-VERSION " RUN SUMMARY          RUN "
                  WS-RUN-NO
                  DELIMITED BY SIZE INTO WS-PRINT
           WRITE SUM-LINE FROM WS-PRINT
           MOVE "RUN ABORTED - INVALID CONTROL RECORD" TO SUM-LINE
           WRITE SUM-LINE
           MOVE 16 TO WS-RC.

      *----------------------------------------------------------------
      * LOAD THE ACCOUNT MASTER.
      *----------------------------------------------------------------
       2000-LOAD-ACCOUNTS.
           MOVE "N" TO WS-EOF
           OPEN INPUT ACCT-FILE
           IF WS-ACCT-STAT NOT = "00"
               MOVE "Y" TO WS-EOF
           END-IF
           PERFORM UNTIL WS-EOF = "Y"
               READ ACCT-FILE
                   AT END
                       MOVE "Y" TO WS-EOF
                   NOT AT END
                       ADD 1 TO WS-ACCT-READ
                       PERFORM 2100-VALIDATE-ACCOUNT
               END-READ
           END-PERFORM
           IF WS-ACCT-STAT NOT = "35"
               CLOSE ACCT-FILE
           END-IF.

       2100-VALIDATE-ACCOUNT.
           MOVE SPACES TO WS-REJ-CODE
           IF AR-ACCT-ID = SPACES
               MOVE "A01" TO WS-REJ-CODE
           END-IF
           IF WS-REJ-CODE = SPACES
               PERFORM VARYING WI FROM 1 BY 1 UNTIL WI > AT-COUNT
                   IF AT-ACCT-ID(WI) = AR-ACCT-ID
                       MOVE "A02" TO WS-REJ-CODE
                   END-IF
               END-PERFORM
           END-IF
           IF WS-REJ-CODE = SPACES
               IF AR-PLAN NOT = "B" AND AR-PLAN NOT = "S"
                  AND AR-PLAN NOT = "P"
                   MOVE "A03" TO WS-REJ-CODE
               END-IF
           END-IF
           IF WS-REJ-CODE = SPACES
               MOVE AR-OPEN-DATE TO DU-DATE
               CALL "DATEUTIL" USING DU-PARMS
               IF DU-VALID NOT = "Y"
                   MOVE "A04" TO WS-REJ-CODE
               ELSE
                   MOVE DU-DATE-N TO WS-OPEN-N
               END-IF
           END-IF
           IF WS-REJ-CODE = SPACES
               IF AR-CLOSE-DATE = SPACES OR AR-CLOSE-DATE = "00000000"
                   MOVE 0 TO WS-CLOSE-N
               ELSE
                   MOVE AR-CLOSE-DATE TO DU-DATE
                   CALL "DATEUTIL" USING DU-PARMS
                   IF DU-VALID NOT = "Y"
                       MOVE "A05" TO WS-REJ-CODE
                   ELSE
                       MOVE DU-DATE-N TO WS-CLOSE-N
                       IF WS-CLOSE-N < WS-OPEN-N
                           MOVE "A05" TO WS-REJ-CODE
                       END-IF
                   END-IF
               END-IF
           END-IF
           IF WS-REJ-CODE = SPACES
               IF AR-TAX-CLASS NOT = "N" AND AR-TAX-CLASS NOT = "R"
                  AND AR-TAX-CLASS NOT = "E"
                   MOVE "A06" TO WS-REJ-CODE
               END-IF
           END-IF
           IF WS-REJ-CODE = SPACES
               IF AR-BAL-DIGITS IS NOT NUMERIC
                  OR (AR-BAL-SIGN NOT = "+" AND AR-BAL-SIGN NOT = "-")
                   MOVE "A07" TO WS-REJ-CODE
               END-IF
           END-IF
           IF WS-REJ-CODE NOT = SPACES
               ADD 1 TO WS-ACCT-REJECTED
               MOVE ACCT-RECORD TO WS-REJ-RECORD
               MOVE "ACC" TO WS-REJ-SRC
               MOVE WS-ACCT-READ TO WS-REJ-SEQ
               PERFORM 7000-WRITE-REJECT
           ELSE
               PERFORM 2200-STORE-ACCOUNT
           END-IF.

       2200-STORE-ACCOUNT.
           ADD 1 TO AT-COUNT
           MOVE AT-COUNT TO WA
           MOVE AR-ACCT-ID TO AT-ACCT-ID(WA)
           MOVE AR-NAME TO AT-NAME(WA)
           MOVE AR-PLAN TO AT-PLAN(WA)
           MOVE WS-OPEN-N TO AT-OPEN-DATE(WA)
           MOVE WS-CLOSE-N TO AT-CLOSE-DATE(WA)
           MOVE AR-TAX-CLASS TO AT-TAX-CLASS(WA)
           MOVE AR-REGION TO AT-REGION(WA)
           MOVE AR-BAL-SIGN TO WS-AMT-SIGN
           MOVE AR-BAL-DIGITS TO WS-AMT-DIGITS
           PERFORM 3160-SIGNED-VALUE
           MOVE WS-AMOUNT TO AT-PRIOR-BAL(WA)
           MOVE AR-LOYALTY TO AT-LOYALTY(WA)
           MOVE "Y" TO AT-INCYCLE(WA)
           IF WS-OPEN-N > WS-CYC-END
               MOVE "N" TO AT-INCYCLE(WA)
           END-IF
           IF WS-CLOSE-N NOT = 0 AND WS-CLOSE-N < WS-CYC-START
               MOVE "N" TO AT-INCYCLE(WA)
           END-IF
           IF AT-INCYCLE(WA) = "N"
               ADD 1 TO WS-ACCT-NOCYC
           END-IF.

      *----------------------------------------------------------------
      * LOAD THE ACTIVITY FILE.
      *----------------------------------------------------------------
       3000-LOAD-ACTIVITY.
           MOVE "N" TO WS-EOF
           OPEN INPUT ACT-FILE
           IF WS-ACT-STAT NOT = "00"
               MOVE "Y" TO WS-EOF
           END-IF
           PERFORM UNTIL WS-EOF = "Y"
               READ ACT-FILE
                   AT END
                       MOVE "Y" TO WS-EOF
                   NOT AT END
                       ADD 1 TO WS-ACT-READ
                       PERFORM 3100-VALIDATE-ACTIVITY
               END-READ
           END-PERFORM
           IF WS-ACT-STAT NOT = "35"
               CLOSE ACT-FILE
           END-IF.

       3100-VALIDATE-ACTIVITY.
           MOVE SPACES TO WS-REJ-CODE
           IF XR-TYPE NOT = "US" AND XR-TYPE NOT = "CH"
              AND XR-TYPE NOT = "PC" AND XR-TYPE NOT = "PY"
              AND XR-TYPE NOT = "AD" AND XR-TYPE NOT = "DS"
              AND XR-TYPE NOT = "SU"
               MOVE "R01" TO WS-REJ-CODE
           END-IF
           IF WS-REJ-CODE = SPACES
               MOVE 0 TO WA
               PERFORM VARYING WI FROM 1 BY 1 UNTIL WI > AT-COUNT
                   IF AT-ACCT-ID(WI) = XR-ACCT-ID AND WA = 0
                       MOVE WI TO WA
                   END-IF
               END-PERFORM
               IF WA = 0
                   MOVE "R02" TO WS-REJ-CODE
               END-IF
           END-IF
           IF WS-REJ-CODE = SPACES
               MOVE XR-DATE TO DU-DATE
               CALL "DATEUTIL" USING DU-PARMS
               IF DU-VALID NOT = "Y"
                   MOVE "R03" TO WS-REJ-CODE
               END-IF
           END-IF
           IF WS-REJ-CODE = SPACES
               IF DU-DATE-N < WS-CYC-START OR DU-DATE-N > WS-CYC-END
                   MOVE "R04" TO WS-REJ-CODE
               END-IF
           END-IF
           IF WS-REJ-CODE = SPACES
               IF DU-DATE-N < AT-OPEN-DATE(WA)
                   MOVE "R08" TO WS-REJ-CODE
               END-IF
               IF AT-CLOSE-DATE(WA) NOT = 0
                  AND DU-DATE-N > AT-CLOSE-DATE(WA)
                   MOVE "R08" TO WS-REJ-CODE
               END-IF
           END-IF
           IF WS-REJ-CODE = SPACES
               EVALUATE XR-TYPE
                   WHEN "US"  PERFORM 3200-CHECK-USAGE
                   WHEN "CH"  PERFORM 3300-CHECK-CHARGE
                   WHEN "PC"  PERFORM 3400-CHECK-PLAN-CHANGE
                   WHEN "PY"  PERFORM 3500-CHECK-PAYMENT
                   WHEN "AD"  PERFORM 3150-CHECK-AMOUNT
                   WHEN "DS"  PERFORM 3600-CHECK-COUPON
                   WHEN "SU"  PERFORM 3700-CHECK-SUSPENSION
               END-EVALUATE
           END-IF
           IF WS-REJ-CODE = SPACES
               PERFORM VARYING WI FROM 1 BY 1 UNTIL WI > XT-COUNT
                   IF XT-RAW(WI) = ACT-RECORD
                       MOVE "R07" TO WS-REJ-CODE
                   END-IF
               END-PERFORM
           END-IF
           IF WS-REJ-CODE NOT = SPACES
               ADD 1 TO WS-ACT-REJECTED
               MOVE ACT-RECORD TO WS-REJ-RECORD
               MOVE "ACT" TO WS-REJ-SRC
               MOVE WS-ACT-READ TO WS-REJ-SEQ
               PERFORM 7000-WRITE-REJECT
           ELSE
               PERFORM 3900-STORE-ACTIVITY
           END-IF.

      *    SIGN MUST BE + OR -, DIGITS NUMERIC (CH PY AD DS)
       3150-CHECK-AMOUNT.
           IF XR-CH-DIGITS IS NOT NUMERIC
              OR (XR-CH-SIGN NOT = "+" AND XR-CH-SIGN NOT = "-")
               MOVE "R05" TO WS-REJ-CODE
           END-IF.

      *    SIGN + DIGITS TO A SIGNED VALUE. ONLY '-' IS NEGATIVE.
       3160-SIGNED-VALUE.
           MOVE WS-AMT-VALUE TO WS-AMOUNT
           IF WS-AMT-SIGN = "-"
               COMPUTE WS-AMOUNT = 0 - WS-AMOUNT
           END-IF.

       3200-CHECK-USAGE.
           IF XR-US-SERVICE NOT = "DATA"
              AND XR-US-SERVICE NOT = "VOIC"
              AND XR-US-SERVICE NOT = "SMS "
              AND XR-US-SERVICE NOT = "ROAM"
               MOVE "R06" TO WS-REJ-CODE
           ELSE
               IF XR-US-QTY IS NOT NUMERIC
                   MOVE "R05" TO WS-REJ-CODE
               END-IF
           END-IF.

       3300-CHECK-CHARGE.
           IF XR-CH-CODE NOT = "EQUP" AND XR-CH-CODE NOT = "INST"
              AND XR-CH-CODE NOT = "LATE" AND XR-CH-CODE NOT = "DEPO"
              AND XR-CH-CODE NOT = "MISC"
               MOVE "R06" TO WS-REJ-CODE
           ELSE
               PERFORM 3150-CHECK-AMOUNT
           END-IF.

       3400-CHECK-PLAN-CHANGE.
           IF XR-PC-PLAN NOT = "B" AND XR-PC-PLAN NOT = "S"
              AND XR-PC-PLAN NOT = "P"
               MOVE "R09" TO WS-REJ-CODE
           END-IF.

       3500-CHECK-PAYMENT.
           PERFORM 3150-CHECK-AMOUNT
           IF WS-REJ-CODE = SPACES
               IF XR-CH-SIGN = "-" OR XR-CH-VALUE = 0
                   MOVE "R10" TO WS-REJ-CODE
               END-IF
           END-IF.

       3600-CHECK-COUPON.
           IF XR-DS-KIND NOT = "P" AND XR-DS-KIND NOT = "F"
               MOVE "R11" TO WS-REJ-CODE
           ELSE
               PERFORM 3150-CHECK-AMOUNT
               IF WS-REJ-CODE = SPACES
                   IF XR-CH-SIGN = "-" OR XR-CH-VALUE = 0
                       MOVE "R11" TO WS-REJ-CODE
                   END-IF
                   IF XR-DS-KIND = "P" AND XR-CH-VALUE > 100
                       MOVE "R11" TO WS-REJ-CODE
                   END-IF
               END-IF
           END-IF.

       3700-CHECK-SUSPENSION.
           MOVE XR-SU-END TO DU-DATE
           CALL "DATEUTIL" USING DU-PARMS
           IF DU-VALID NOT = "Y"
               MOVE "R12" TO WS-REJ-CODE
           ELSE
               MOVE DU-DATE-N TO WS-END-N
               IF WS-END-N < XR-DATE-N
                   MOVE "R12" TO WS-REJ-CODE
               END-IF
           END-IF.

       3900-STORE-ACTIVITY.
           ADD 1 TO XT-COUNT
           ADD 1 TO WS-ACT-ACCEPTED
           MOVE XT-COUNT TO WX
           MOVE XR-TYPE TO XT-TYPE(WX)
           MOVE WA TO XT-ACCT-IX(WX)
           MOVE XR-DATE TO XT-DATE(WX)
           MOVE ACT-RECORD TO XT-RAW(WX)
           MOVE SPACES TO XT-CODE(WX) XT-DESC(WX)
           MOVE 0 TO XT-QTY(WX) XT-AMOUNT(WX) XT-END(WX)
           EVALUATE XR-TYPE
               WHEN "US"
                   MOVE XR-US-SERVICE TO XT-CODE(WX)
                   MOVE XR-US-QTY-N TO XT-QTY(WX)
               WHEN "PC"
                   MOVE XR-PC-PLAN TO XT-CODE(WX)
               WHEN "SU"
                   MOVE WS-END-N TO XT-END(WX)
               WHEN "DS"
                   MOVE XR-DS-KIND TO XT-CODE(WX)
                   MOVE XR-CH-SIGN TO WS-AMT-SIGN
                   MOVE XR-CH-DIGITS TO WS-AMT-DIGITS
                   PERFORM 3160-SIGNED-VALUE
                   MOVE WS-AMOUNT TO XT-AMOUNT(WX)
               WHEN OTHER
                   MOVE XR-CH-CODE TO XT-CODE(WX)
                   MOVE XR-CH-DESC TO XT-DESC(WX)
                   MOVE XR-CH-SIGN TO WS-AMT-SIGN
                   MOVE XR-CH-DIGITS TO WS-AMT-DIGITS
                   PERFORM 3160-SIGNED-VALUE
                   MOVE WS-AMOUNT TO XT-AMOUNT(WX)
           END-EVALUATE.

      *----------------------------------------------------------------
      * ORDER THE ACCOUNTS IN CYCLE BY REGION AND ACCOUNT ID.
      *----------------------------------------------------------------
       4900-ORDER-ACCOUNTS.
           MOVE 0 TO OD-COUNT
           PERFORM VARYING WL FROM 1 BY 1 UNTIL WL > AT-COUNT
               IF AT-INCYCLE(WL) = "Y"
                   MOVE OD-COUNT TO WJ
                   PERFORM UNTIL WJ = 0
                       OR AT-KEY(OD-IX(WJ)) NOT > AT-KEY(WL)
                       COMPUTE WK = WJ + 1
                       MOVE OD-IX(WJ) TO OD-IX(WK)
                       SUBTRACT 1 FROM WJ
                   END-PERFORM
                   COMPUTE WK = WJ + 1
                   MOVE WL TO OD-IX(WK)
                   ADD 1 TO OD-COUNT
               END-IF
           END-PERFORM.

      *----------------------------------------------------------------
      * COLLECT ONE ACCOUNT'S ACTIVITY OF WS-SEL-TYPE (AND COUPON KIND
      * WS-SEL-KIND WHEN NOT SPACE) IN DATE ORDER, FILE ORDER ON TIES.
      *----------------------------------------------------------------
       4950-COLLECT.
           MOVE 0 TO SL-COUNT
           PERFORM VARYING WI FROM 1 BY 1 UNTIL WI > XT-COUNT
               IF XT-ACCT-IX(WI) = WB-AX AND XT-TYPE(WI) = WS-SEL-TYPE
                  AND (WS-SEL-KIND = SPACE
                       OR XT-CODE(WI)(1:1) = WS-SEL-KIND)
                   MOVE SL-COUNT TO WJ
                   PERFORM UNTIL WJ = 0
                       OR XT-DATE(SL-IX(WJ)) NOT > XT-DATE(WI)
                       COMPUTE WK = WJ + 1
                       MOVE SL-IX(WJ) TO SL-IX(WK)
                       SUBTRACT 1 FROM WJ
                   END-PERFORM
                   COMPUTE WK = WJ + 1
                   MOVE WI TO SL-IX(WK)
                   ADD 1 TO SL-COUNT
               END-IF
           END-PERFORM.

      *----------------------------------------------------------------
      * ONE STATEMENT PER ACCOUNT IN CYCLE.
      *----------------------------------------------------------------
       5000-PRODUCE-STATEMENTS.
           PERFORM VARYING WP FROM 1 BY 1 UNTIL WP > OD-COUNT
               MOVE OD-IX(WP) TO WB-AX
               PERFORM 5100-BILL-ACCOUNT
           END-PERFORM.

       5100-BILL-ACCOUNT.
           ADD 1 TO WS-STMT-COUNT
           MOVE 0 TO WB-BASE WB-USAGE WB-CHARGES WB-LATE WB-LATECAP
                     WB-DEPOSIT WB-DISC WB-SUBTOTAL WB-TAXABLE WB-TAX
                     WB-ADJ WB-CURRENT WB-PAY WB-DUE WB-NACT
           PERFORM VARYING WL FROM 1 BY 1 UNTIL WL > XT-COUNT
               IF XT-ACCT-IX(WL) = WB-AX
                   ADD 1 TO WB-NACT
               END-IF
           END-PERFORM
           PERFORM 5300-FINAL-PLAN
           PERFORM 5400-STATEMENT-HEADER
           IF WB-NACT = 0
               MOVE 0 TO WP-DATE
               MOVE "N" TO WP-HASQTY
               MOVE "NO ACTIVITY THIS PERIOD" TO WP-DESC
               PERFORM 5905-PUT-TEXT
           END-IF
           PERFORM 5500-BASE-FEES
           PERFORM 5600-USAGE
           PERFORM 5700-CHARGES
           PERFORM 5750-DISCOUNTS
           PERFORM 5800-TOTALS.

      *    THE LAST PLAN CHANGE BY DATE SETS THE PLAN.
       5300-FINAL-PLAN.
           MOVE AT-PLAN(WB-AX) TO WB-FINAL-PLAN
           MOVE "PC" TO WS-SEL-TYPE
           MOVE SPACE TO WS-SEL-KIND
           PERFORM 4950-COLLECT
           MOVE SL-COUNT TO PC-COUNT
           PERFORM VARYING WL FROM 1 BY 1 UNTIL WL > SL-COUNT
               MOVE SL-IX(WL) TO PC-IX(WL)
               MOVE XT-CODE(PC-IX(WL))(1:1) TO WB-FINAL-PLAN
           END-PERFORM.

       5400-STATEMENT-HEADER.
           WRITE STMT-LINE FROM WS-RULE-STAR
           MOVE SPACES TO WS-PRINT
           STRING WS-COMPANY "  BILLING STATEMENT  RUN " WS-RUN-NO
                  DELIMITED BY SIZE INTO WS-PRINT
           WRITE STMT-LINE FROM WS-PRINT
           MOVE SPACES TO WS-PRINT
           STRING "ACCOUNT " AT-ACCT-ID(WB-AX) "  "
                  AT-NAME(WB-AX) "  REGION " AT-REGION(WB-AX)
                  DELIMITED BY SIZE INTO WS-PRINT
           WRITE STMT-LINE FROM WS-PRINT
           MOVE WS-CYC-START TO WS-DATE-IN
           PERFORM 5990-FORMAT-DATE
           MOVE WS-DATE-DISP TO WS-DATE-DISP2
           MOVE WS-CYC-END TO WS-DATE-IN
           PERFORM 5990-FORMAT-DATE
           MOVE WS-CYC-DAYS TO WS-ED-DAYS
           MOVE SPACES TO WS-PRINT
           STRING "PERIOD " WS-DATE-DISP2 " TO "
                  WS-DATE-DISP "  DAYS " WS-ED-DAYS "  PLAN "
                  WB-FINAL-PLAN
                  DELIMITED BY SIZE INTO WS-PRINT
           WRITE STMT-LINE FROM WS-PRINT
           WRITE STMT-LINE FROM WS-RULE-DASH
           MOVE SPACES TO WS-PRINT
           STRING "DATE       DESCRIPTION                       "
                  "     QTY          AMOUNT"
                  DELIMITED BY SIZE INTO WS-PRINT
           WRITE STMT-LINE FROM WS-PRINT
           WRITE STMT-LINE FROM WS-RULE-DASH.

      *----------------------------------------------------------------
      * MONTHLY FEE BY PLAN SEGMENT. SUSPENDED DAYS COUNT HALF.
      *----------------------------------------------------------------
       5500-BASE-FEES.
           PERFORM VARYING WD FROM 1 BY 1 UNTIL WD > WS-CYC-DAYS
               COMPUTE DAY-DATE(WD) = FUNCTION DATE-OF-INTEGER
                   (WS-CYC-START-DN + WD - 1)
               MOVE AT-PLAN(WB-AX) TO DAY-PLAN(WD)
               PERFORM VARYING WL FROM 1 BY 1 UNTIL WL > PC-COUNT
                   IF XT-DATE(PC-IX(WL)) NOT > DAY-DATE(WD)
                       MOVE XT-CODE(PC-IX(WL))(1:1) TO DAY-PLAN(WD)
                   END-IF
               END-PERFORM
               MOVE "Y" TO DAY-ACT(WD)
               IF DAY-DATE(WD) < AT-OPEN-DATE(WB-AX)
                   MOVE "N" TO DAY-ACT(WD)
               END-IF
               IF AT-CLOSE-DATE(WB-AX) NOT = 0
                  AND DAY-DATE(WD) > AT-CLOSE-DATE(WB-AX)
                   MOVE "N" TO DAY-ACT(WD)
               END-IF
               MOVE "N" TO DAY-SUSP(WD)
           END-PERFORM
           PERFORM VARYING WL FROM 1 BY 1 UNTIL WL > XT-COUNT
               IF XT-ACCT-IX(WL) = WB-AX AND XT-TYPE(WL) = "SU"
                   PERFORM VARYING WD FROM 1 BY 1
                           UNTIL WD > WS-CYC-DAYS
                       IF DAY-DATE(WD) NOT < XT-DATE(WL)
                          AND DAY-DATE(WD) NOT > XT-END(WL)
                           MOVE "Y" TO DAY-SUSP(WD)
                       END-IF
                   END-PERFORM
               END-IF
           END-PERFORM
           MOVE 0 TO SG-COUNT
           PERFORM VARYING WD FROM 1 BY 1 UNTIL WD > WS-CYC-DAYS
               IF DAY-ACT(WD) = "Y"
                   IF SG-COUNT = 0
                       PERFORM 5510-NEW-SEGMENT
                   ELSE
                       IF DAY-PLAN(WD) NOT = SG-PLAN(SG-COUNT)
                           PERFORM 5510-NEW-SEGMENT
                       END-IF
                   END-IF
                   IF DAY-SUSP(WD) = "Y"
                       ADD 1 TO SG-S(SG-COUNT)
                   ELSE
                       ADD 1 TO SG-N(SG-COUNT)
                   END-IF
               END-IF
           END-PERFORM
           PERFORM VARYING WN FROM 1 BY 1 UNTIL WN > SG-COUNT
               EVALUATE SG-PLAN(WN)
                   WHEN "B" MOVE 10.00 TO WS-FEE
                   WHEN "S" MOVE 25.00 TO WS-FEE
                   WHEN OTHER MOVE 60.00 TO WS-FEE
               END-EVALUATE
               COMPUTE WS-UNITS = 2 * SG-N(WN) + SG-S(WN)
               COMPUTE WS-DEN = 2 * WS-CYC-DAYS
               COMPUTE SG-AMT(WN) ROUNDED =
                   WS-FEE * WS-UNITS / WS-DEN
               MOVE SG-DATE(WN) TO WP-DATE
               MOVE SPACES TO WP-DESC
               STRING "BASE FEE PLAN " SG-PLAN(WN)
                      DELIMITED BY SIZE INTO WP-DESC
               MOVE "Y" TO WP-HASQTY
               COMPUTE WP-QTY = SG-N(WN) + SG-S(WN)
               MOVE SG-AMT(WN) TO WP-AMT
               PERFORM 5900-PUT-LINE
               ADD SG-AMT(WN) TO WB-BASE
           END-PERFORM.

       5510-NEW-SEGMENT.
           ADD 1 TO SG-COUNT
           MOVE DAY-PLAN(WD) TO SG-PLAN(SG-COUNT)
           MOVE DAY-DATE(WD) TO SG-DATE(SG-COUNT)
           MOVE 0 TO SG-N(SG-COUNT) SG-S(SG-COUNT).

      *----------------------------------------------------------------
      * USAGE, ONE LINE PER SERVICE IN USE.
      *----------------------------------------------------------------
       5600-USAGE.
           MOVE "N" TO WU-HAS-DATA WU-HAS-VOIC WU-HAS-SMS WU-HAS-ROAM
           MOVE 0 TO WU-DATA-QTY WU-VOIC-MIN WU-SMS-MSG WU-ROAM-QTY
                     WU-ROAM-AMT
           PERFORM VARYING WL FROM 1 BY 1 UNTIL WL > XT-COUNT
               IF XT-ACCT-IX(WL) = WB-AX AND XT-TYPE(WL) = "US"
                   COMPUTE WU-Q = XT-QTY(WL) * 100
                   EVALUATE XT-CODE(WL)
                       WHEN "DATA"
                           MOVE "Y" TO WU-HAS-DATA
                           ADD XT-QTY(WL) TO WU-DATA-QTY
                       WHEN "VOIC"
                           MOVE "Y" TO WU-HAS-VOIC
                           COMPUTE WU-M = (WU-Q + 99) / 100
                           ADD WU-M TO WU-VOIC-MIN
                       WHEN "SMS "
                           MOVE "Y" TO WU-HAS-SMS
                           COMPUTE WU-M = WU-Q / 100
                           ADD WU-M TO WU-SMS-MSG
                       WHEN "ROAM"
                           MOVE "Y" TO WU-HAS-ROAM
                           ADD XT-QTY(WL) TO WU-ROAM-QTY
                           PERFORM 5640-ROAM-RECORD
                   END-EVALUATE
               END-IF
           END-PERFORM
           MOVE 0 TO WP-DATE
           IF WU-HAS-DATA = "Y"
               PERFORM 5610-RATE-DATA
           END-IF
           IF WU-HAS-VOIC = "Y"
               PERFORM 5620-RATE-VOICE
           END-IF
           IF WU-HAS-SMS = "Y"
               PERFORM 5630-RATE-SMS
           END-IF
           IF WU-HAS-ROAM = "Y"
               MOVE "USAGE ROAMING MB" TO WP-DESC
               MOVE "Y" TO WP-HASQTY
               MOVE WU-ROAM-QTY TO WP-QTY
               MOVE WU-ROAM-AMT TO WP-AMT
               ADD WP-AMT TO WB-USAGE
               PERFORM 5900-PUT-LINE
           END-IF.

       5610-RATE-DATA.
           EVALUATE WB-FINAL-PLAN
               WHEN "S" MOVE 2.00 TO WU-ALLOW
               WHEN "P" MOVE 5.00 TO WU-ALLOW
               WHEN OTHER MOVE 0 TO WU-ALLOW
           END-EVALUATE
           IF WU-DATA-QTY > WU-ALLOW
               COMPUTE WU-BILLABLE = WU-DATA-QTY - WU-ALLOW
           ELSE
               MOVE 0 TO WU-BILLABLE
           END-IF
           IF WU-BILLABLE > 10.00
               MOVE 10.00 TO WU-T1
               COMPUTE WU-REM = WU-BILLABLE - 10.00
           ELSE
               MOVE WU-BILLABLE TO WU-T1
               MOVE 0 TO WU-REM
           END-IF
           IF WU-REM > 30.00
               MOVE 30.00 TO WU-T2
               COMPUTE WU-T3 = WU-REM - 30.00
           ELSE
               MOVE WU-REM TO WU-T2
               MOVE 0 TO WU-T3
           END-IF
           COMPUTE WU-AMT ROUNDED =
               WU-T1 * 1.50 + WU-T2 * 1.20 + WU-T3 * 0.80
           MOVE "USAGE DATA GB" TO WP-DESC
           MOVE "Y" TO WP-HASQTY
           MOVE WU-DATA-QTY TO WP-QTY
           MOVE WU-AMT TO WP-AMT
           ADD WP-AMT TO WB-USAGE
           PERFORM 5900-PUT-LINE.

       5620-RATE-VOICE.
           IF WB-FINAL-PLAN = "P"
               COMPUTE WU-AMT = WU-VOIC-MIN * 0.03
           ELSE
               COMPUTE WU-AMT = WU-VOIC-MIN * 0.05
           END-IF
           MOVE "USAGE VOICE MIN" TO WP-DESC
           MOVE "Y" TO WP-HASQTY
           MOVE WU-VOIC-MIN TO WP-QTY
           MOVE WU-AMT TO WP-AMT
           ADD WP-AMT TO WB-USAGE
           PERFORM 5900-PUT-LINE.

       5630-RATE-SMS.
           MOVE WU-SMS-MSG TO WU-M
           IF WB-FINAL-PLAN = "P"
               IF WU-M > 100
                   SUBTRACT 100 FROM WU-M
               ELSE
                   MOVE 0 TO WU-M
               END-IF
           END-IF
           EVALUATE WB-FINAL-PLAN
               WHEN "B" COMPUTE WU-AMT = WU-M * 0.03
               WHEN OTHER COMPUTE WU-AMT = WU-M * 0.02
           END-EVALUATE
           MOVE "USAGE SMS MSG" TO WP-DESC
           MOVE "Y" TO WP-HASQTY
           MOVE WU-SMS-MSG TO WP-QTY
           MOVE WU-AMT TO WP-AMT
           ADD WP-AMT TO WB-USAGE
           PERFORM 5900-PUT-LINE.

      *    ROAMING: 0.25 PER MB, EACH RECORD ROUNDED HALF TO EVEN.
       5640-ROAM-RECORD.
           COMPUTE WU-C = WU-Q / 4
           COMPUTE WU-R = WU-Q - WU-C * 4
           IF WU-R > 2
               ADD 1 TO WU-C
           ELSE
               IF WU-R = 2
                   DIVIDE WU-C BY 2 GIVING WU-M REMAINDER WU-R
                   IF WU-R = 1
                       ADD 1 TO WU-C
                   END-IF
               END-IF
           END-IF
           COMPUTE WU-ROAM-AMT = WU-ROAM-AMT + WU-C / 100.

      *----------------------------------------------------------------
      * ONE-TIME CHARGES IN DATE ORDER, THEN THE LATE FEE CAP.
      *----------------------------------------------------------------
       5700-CHARGES.
           MOVE "CH" TO WS-SEL-TYPE
           MOVE SPACE TO WS-SEL-KIND
           PERFORM 4950-COLLECT
           PERFORM VARYING WL FROM 1 BY 1 UNTIL WL > SL-COUNT
               MOVE SL-IX(WL) TO WX
               MOVE XT-DATE(WX) TO WP-DATE
               MOVE SPACES TO WP-DESC
               STRING XT-CODE(WX) " " XT-DESC(WX)
                      DELIMITED BY SIZE INTO WP-DESC
               MOVE "N" TO WP-HASQTY
               MOVE XT-AMOUNT(WX) TO WP-AMT
               PERFORM 5900-PUT-LINE
               ADD XT-AMOUNT(WX) TO WB-CHARGES
               IF XT-CODE(WX) = "LATE"
                   ADD XT-AMOUNT(WX) TO WB-LATE
               END-IF
               IF XT-CODE(WX) = "DEPO"
                   ADD XT-AMOUNT(WX) TO WB-DEPOSIT
               END-IF
           END-PERFORM
           IF WB-LATE > 15.00
               COMPUTE WB-LATECAP = WB-LATE - 15.00
               MOVE 0 TO WP-DATE
               MOVE "LATE FEE CAP" TO WP-DESC
               COMPUTE WP-AMT = 0 - WB-LATECAP
               PERFORM 5900-PUT-LINE
               SUBTRACT WB-LATECAP FROM WB-CHARGES
           END-IF.

      *----------------------------------------------------------------
      * LOYALTY DISCOUNT AND COUPONS, CAPPED AT HALF THE DISCOUNTABLE
      * AMOUNT.
      *----------------------------------------------------------------
       5750-DISCOUNTS.
           COMPUTE WB-DB = WB-BASE + WB-USAGE + WB-CHARGES
                         - WB-DEPOSIT
           MOVE "DS" TO WS-SEL-TYPE
           MOVE SPACE TO WS-SEL-KIND
           PERFORM 4950-COLLECT
           MOVE SL-COUNT TO WB-NCOUP
           MOVE 0 TO WB-TD WB-LOYAMT
           IF WB-DB NOT > 0
               PERFORM VARYING WL FROM 1 BY 1 UNTIL WL > WB-NCOUP
                   MOVE 0 TO WP-DATE
                   MOVE SPACES TO WP-DESC
                   STRING "COUPON " AT-LOYALTY(WB-AX) ".00%"
                          DELIMITED BY SIZE INTO WP-DESC
                   MOVE "N" TO WP-HASQTY
                   MOVE 0 TO WP-AMT
                   PERFORM 5900-PUT-LINE
               END-PERFORM
           ELSE
               PERFORM 5760-LOYALTY
               MOVE WB-DB TO WB-REM
               SUBTRACT WB-LOYAMT FROM WB-REM
               MOVE "F" TO WS-SEL-KIND
               PERFORM 4950-COLLECT
               PERFORM VARYING WL FROM 1 BY 1 UNTIL WL > SL-COUNT
                   MOVE SL-IX(WL) TO WX
                   MOVE XT-AMOUNT(WX) TO WB-CAMT
                   IF WB-REM < 0
                       MOVE 0 TO WB-CAMT
                   ELSE
                       IF WB-CAMT > WB-REM
                           MOVE WB-REM TO WB-CAMT
                       END-IF
                   END-IF
                   MOVE SPACES TO WP-DESC
                   MOVE "COUPON FIXED" TO WP-DESC
                   PERFORM 5770-COUPON-LINE
               END-PERFORM
               MOVE "P" TO WS-SEL-KIND
               PERFORM 4950-COLLECT
               PERFORM VARYING WL FROM 1 BY 1 UNTIL WL > SL-COUNT
                   MOVE SL-IX(WL) TO WX
                   IF WB-REM < 0
                       MOVE 0 TO WB-CAMT
                   ELSE
                       COMPUTE WB-CAMT ROUNDED =
                           WB-REM * XT-AMOUNT(WX) / 100
                   END-IF
                   MOVE XT-AMOUNT(WX) TO WS-ED-PCT
                   MOVE SPACES TO WP-DESC
                   STRING "COUPON " WS-ED-PCT "%"
                          DELIMITED BY SIZE INTO WP-DESC
                   PERFORM 5770-COUPON-LINE
               END-PERFORM
               COMPUTE WB-LIMIT ROUNDED = WB-DB * 0.5
               IF WB-TD > WB-LIMIT
                   COMPUTE WB-CAP = WB-TD - WB-LIMIT
                   MOVE 0 TO WP-DATE
                   MOVE "DISCOUNT CAP" TO WP-DESC
                   MOVE "N" TO WP-HASQTY
                   MOVE WB-CAP TO WP-AMT
                   PERFORM 5900-PUT-LINE
                   MOVE WB-LIMIT TO WB-TD
               END-IF
           END-IF
           MOVE WB-TD TO WB-DISC.

       5760-LOYALTY.
           MOVE 0 TO WB-PCT
           EVALUATE AT-LOYALTY(WB-AX)
               WHEN "L1" MOVE 5 TO WB-PCT
               WHEN "L2" MOVE 10 TO WB-PCT
               WHEN "L3" MOVE 15 TO WB-PCT
           END-EVALUATE
           COMPUTE WB-LOYAMT ROUNDED = WB-BASE * WB-PCT / 100
           IF WB-LOYAMT NOT = 0
               MOVE WB-PCT TO WS-ED-PCTW
               MOVE 0 TO WP-DATE
               MOVE SPACES TO WP-DESC
               STRING "LOYALTY DISCOUNT " AT-LOYALTY(WB-AX) " "
                      WS-ED-PCTW "%"
                      DELIMITED BY SIZE INTO WP-DESC
               MOVE "N" TO WP-HASQTY
               COMPUTE WP-AMT = 0 - WB-LOYAMT
               PERFORM 5900-PUT-LINE
           END-IF
           ADD WB-LOYAMT TO WB-TD.

      *    PRINT ONE COUPON LINE (DESCRIPTION IN WP-DESC, AMOUNT IN
      *    WB-CAMT) AND TAKE IT OFF THE REMAINING AMOUNT.
       5770-COUPON-LINE.
           MOVE XT-DATE(WX) TO WP-DATE
           MOVE "N" TO WP-HASQTY
           COMPUTE WP-AMT = 0 - WB-CAMT
           PERFORM 5900-PUT-LINE
           SUBTRACT WB-CAMT FROM WB-REM
           ADD WB-CAMT TO WB-TD.

      *----------------------------------------------------------------
      * STATEMENT TOTALS.
      *----------------------------------------------------------------
       5800-TOTALS.
           MOVE 0 TO WP-DATE
           MOVE "N" TO WP-HASQTY
           IF WB-DB > 0
               COMPUTE WB-SUBTOTAL = WB-BASE + WB-USAGE + WB-CHARGES
                                   - WB-DISC
           ELSE
               COMPUTE WB-SUBTOTAL = WB-BASE + WB-USAGE + WB-CHARGES
           END-IF
           WRITE STMT-LINE FROM WS-RULE-DASH-DUMMY
           .
EOF
echo done
```

<details><summary>output</summary>

```
done
```
</details>

### Step 54: Bash

```bash
docker exec -i sn-cobol-production-parity bash -c 'cd /app/src; python3 - <<"PY"
s=open("billrun.cbl").read()
i=s.index("       5800-TOTALS.")
s=s[:i]
tail=r"""       5800-TOTALS.
           MOVE 0 TO WP-DATE
           MOVE "N" TO WP-HASQTY
           COMPUTE WB-SUBTOTAL = WB-BASE + WB-USAGE + WB-CHARGES
                               - WB-DISC
           MOVE "SUBTOTAL" TO WP-DESC
           MOVE WB-SUBTOTAL TO WP-AMT
           PERFORM 5900-PUT-LINE
           EVALUATE AT-TAX-CLASS(WB-AX)
               WHEN "R"
                   MOVE 0.0400 TO WS-TAXRATE
                   MOVE "4.00%" TO WS-TAXDISP
               WHEN "E"
                   MOVE 0 TO WS-TAXRATE
                   MOVE "0.00%" TO WS-TAXDISP
               WHEN OTHER
                   MOVE 0.0825 TO WS-TAXRATE
                   MOVE "8.25%" TO WS-TAXDISP
           END-EVALUATE
           COMPUTE WB-TAXABLE = WB-SUBTOTAL - WB-DEPOSIT
           IF WB-TAXABLE > 0
               COMPUTE WB-TAX ROUNDED = WB-TAXABLE * WS-TAXRATE
           ELSE
               MOVE 0 TO WB-TAX
           END-IF
           MOVE SPACES TO WP-DESC
           STRING "TAX " AT-TAX-CLASS(WB-AX) " " WS-TAXDISP
                  DELIMITED BY SIZE INTO WP-DESC
           MOVE WB-TAX TO WP-AMT
           PERFORM 5900-PUT-LINE
           MOVE "AD" TO WS-SEL-TYPE
           MOVE SPACE TO WS-SEL-KIND
           PERFORM 4950-COLLECT
           PERFORM VARYING WL FROM 1 BY 1 UNTIL WL > SL-COUNT
               MOVE SL-IX(WL) TO WX
               MOVE XT-DATE(WX) TO WP-DATE
               MOVE SPACES TO WP-DESC
               STRING "ADJ " XT-DESC(WX)
                      DELIMITED BY SIZE INTO WP-DESC
               MOVE XT-AMOUNT(WX) TO WP-AMT
               PERFORM 5900-PUT-LINE
               ADD XT-AMOUNT(WX) TO WB-ADJ
           END-PERFORM
           MOVE 0 TO WP-DATE
           COMPUTE WB-CURRENT = WB-SUBTOTAL + WB-TAX + WB-ADJ
           MOVE "CURRENT CHARGES" TO WP-DESC
           MOVE WB-CURRENT TO WP-AMT
           PERFORM 5900-PUT-LINE
           MOVE "PRIOR BALANCE" TO WP-DESC
           MOVE AT-PRIOR-BAL(WB-AX) TO WP-AMT
           PERFORM 5900-PUT-LINE
           MOVE "PY" TO WS-SEL-TYPE
           PERFORM 4950-COLLECT
           PERFORM VARYING WL FROM 1 BY 1 UNTIL WL > SL-COUNT
               MOVE SL-IX(WL) TO WX
               MOVE XT-DATE(WX) TO WP-DATE
               MOVE "PAYMENT RECEIVED" TO WP-DESC
               COMPUTE WP-AMT = 0 - XT-AMOUNT(WX)
               PERFORM 5900-PUT-LINE
               ADD XT-AMOUNT(WX) TO WB-PAY
           END-PERFORM
           WRITE STMT-LINE FROM WS-RULE-DASH
           MOVE 0 TO WP-DATE
           COMPUTE WB-DUE = AT-PRIOR-BAL(WB-AX) + WB-CURRENT - WB-PAY
           MOVE "AMOUNT DUE" TO WP-DESC
           MOVE WB-DUE TO WP-AMT
           PERFORM 5900-PUT-LINE
           ADD WB-BASE TO WT-BASE
           ADD WB-USAGE TO WT-USAGE
           ADD WB-CHARGES TO WT-CHARGES
           ADD WB-DISC TO WT-DISC
           ADD WB-TAX TO WT-TAX
           ADD WB-ADJ TO WT-ADJ
           ADD WB-PAY TO WT-PAY
           ADD WB-DUE TO WT-DUE
           IF RT-COUNT > 0
              AND RT-REGION(RT-COUNT) = AT-REGION(WB-AX)
               ADD WB-DUE TO RT-DUE(RT-COUNT)
           ELSE
               ADD 1 TO RT-COUNT
               MOVE AT-REGION(WB-AX) TO RT-REGION(RT-COUNT)
               MOVE WB-DUE TO RT-DUE(RT-COUNT)
           END-IF.

      *----------------------------------------------------------------
      * PRINT ONE STATEMENT DETAIL LINE.
      *----------------------------------------------------------------
       5900-PUT-LINE.
           MOVE SPACES TO DL-LINE
           IF WP-DATE NOT = 0
               MOVE WP-DATE TO WS-DATE-IN
               PERFORM 5990-FORMAT-DATE
               MOVE WS-DATE-DISP TO DL-DATE
           END-IF
           MOVE WP-DESC TO DL-DESC
           IF WP-HASQTY = "Y"
               MOVE WP-QTY TO WS-ED-QTY
               MOVE WS-ED-QTY TO DL-QTY
           END-IF
           IF WP-AMT < 0
               COMPUTE DL-AMT = 0 - WP-AMT
               MOVE "CR" TO DL-CR
           ELSE
               MOVE WP-AMT TO DL-AMT
           END-IF
           WRITE STMT-LINE FROM DL-LINE
           MOVE "N" TO WP-HASQTY.

       5905-PUT-TEXT.
           MOVE SPACES TO DL-LINE
           MOVE WP-DESC TO DL-DESC
           WRITE STMT-LINE FROM DL-LINE.

       5990-FORMAT-DATE.
           MOVE SPACES TO WS-DATE-DISP
           STRING WS-DATE-IN(1:4) "-" WS-DATE-IN(5:2) "-"
                  WS-DATE-IN(7:2)
                  DELIMITED BY SIZE INTO WS-DATE-DISP.

      *----------------------------------------------------------------
      * REJECT LISTING
      *----------------------------------------------------------------
       7000-WRITE-REJECT.
           ADD 1 TO WS-REJ-TOTAL
           MOVE SPACES TO RJ-MSG
           PERFORM VARYING WI FROM 1 BY 1 UNTIL WI > 20
               IF RM-CODE(WI) = WS-REJ-CODE
                   MOVE RM-TEXT(WI) TO RJ-MSG
                   ADD 1 TO REJ-CNT(WI)
               END-IF
           END-PERFORM
           MOVE WS-REJ-SEQ TO RJ-SEQ
           MOVE WS-REJ-SRC TO RJ-SRC
           MOVE WS-REJ-CODE TO RJ-CODE
           MOVE WS-REJ-RECORD(1:40) TO RJ-REC
           WRITE REJ-LINE FROM RJ-DETAIL.

       7900-REJECT-TRAILER.
           MOVE WS-REJ-TOTAL TO WS-ED-COUNT
           MOVE SPACES TO WS-PRINT
           STRING "TOTAL REJECTS " WS-ED-COUNT
                  DELIMITED BY SIZE INTO WS-PRINT
           WRITE REJ-LINE FROM WS-PRINT.

      *----------------------------------------------------------------
      * RUN SUMMARY
      *----------------------------------------------------------------
       8000-WRITE-SUMMARY.
           MOVE SPACES TO WS-PRINT
           STRING "BILLRUN " WS-VERSION " RUN SUMMARY          RUN "
                  WS-RUN-NO
                  DELIMITED BY SIZE INTO WS-PRINT
           WRITE SUM-LINE FROM WS-PRINT
           MOVE SPACES TO WS-PRINT
           STRING "COMPANY " WS-COMPANY
                  DELIMITED BY SIZE INTO WS-PRINT
           WRITE SUM-LINE FROM WS-PRINT
           MOVE WS-ACCT-READ TO WS-ED-COUNT
           MOVE "ACCOUNTS READ" TO WS-PRINT
           PERFORM 8100-COUNT-LINE
           MOVE OD-COUNT TO WS-ED-COUNT
           MOVE "ACCOUNTS BILLED" TO WS-PRINT
           PERFORM 8100-COUNT-LINE
           MOVE WS-ACCT-NOCYC TO WS-ED-COUNT
           MOVE "ACCOUNTS NOT IN CYCLE" TO WS-PRINT
           PERFORM 8100-COUNT-LINE
           MOVE WS-ACCT-REJECTED TO WS-ED-COUNT
           MOVE "ACCOUNTS REJECTED" TO WS-PRINT
           PERFORM 8100-COUNT-LINE
           MOVE WS-ACT-READ TO WS-ED-COUNT
           MOVE "ACTIVITY READ" TO WS-PRINT
           PERFORM 8100-COUNT-LINE
           MOVE WS-ACT-ACCEPTED TO WS-ED-COUNT
           MOVE "ACTIVITY ACCEPTED" TO WS-PRINT
           PERFORM 8100-COUNT-LINE
           MOVE WS-ACT-REJECTED TO WS-ED-COUNT
           MOVE "ACTIVITY REJECTED" TO WS-PRINT
           PERFORM 8100-COUNT-LINE
           MOVE WS-STMT-COUNT TO WS-ED-COUNT
           MOVE "STATEMENTS PRODUCED" TO WS-PRINT
           PERFORM 8100-COUNT-LINE
           IF WS-REJ-TOTAL > 0
               MOVE "REJECTS BY CODE" TO SUM-LINE
               WRITE SUM-LINE
               PERFORM VARYING WI FROM 1 BY 1 UNTIL WI > 19
                   IF REJ-CNT(WI) > 0
                       MOVE SPACES TO WS-PRINT
                       MOVE RM-CODE(WI) TO WS-PRINT(3:3)
                       MOVE RM-TEXT(WI) TO WS-PRINT(7:22)
                       MOVE REJ-CNT(WI) TO WS-ED-COUNT
                       PERFORM 8100-COUNT-LINE
                   END-IF
               END-PERFORM
           END-IF
           MOVE WT-BASE TO WS-ED-SUM
           MOVE "TOTAL BASE FEES" TO WS-PRINT
           PERFORM 8200-AMOUNT-LINE
           MOVE WT-USAGE TO WS-ED-SUM
           MOVE "TOTAL USAGE" TO WS-PRINT
           PERFORM 8200-AMOUNT-LINE
           MOVE WT-CHARGES TO WS-ED-SUM
           MOVE "TOTAL CHARGES" TO WS-PRINT
           PERFORM 8200-AMOUNT-LINE
           MOVE WT-DISC TO WS-ED-SUM
           MOVE "TOTAL DISCOUNTS" TO WS-PRINT
           PERFORM 8200-AMOUNT-LINE
           MOVE WT-TAX TO WS-ED-SUM
           MOVE "TOTAL TAX" TO WS-PRINT
           PERFORM 8200-AMOUNT-LINE
           MOVE WT-ADJ TO WS-ED-SUM
           MOVE "TOTAL ADJUSTMENTS" TO WS-PRINT
           PERFORM 8200-AMOUNT-LINE
           MOVE WT-PAY TO WS-ED-SUM
           MOVE "TOTAL PAYMENTS" TO WS-PRINT
           PERFORM 8200-AMOUNT-LINE
           MOVE WT-DUE TO WS-ED-SUM
           MOVE "TOTAL AMOUNT DUE" TO WS-PRINT
           PERFORM 8200-AMOUNT-LINE
           IF RT-COUNT > 0
               MOVE "AMOUNT DUE BY REGION" TO SUM-LINE
               WRITE SUM-LINE
               PERFORM VARYING WI FROM 1 BY 1 UNTIL WI > RT-COUNT
                   MOVE SPACES TO WS-PRINT
                   STRING "  REGION " RT-REGION(WI)
                          DELIMITED BY SIZE INTO WS-PRINT
                   MOVE RT-DUE(WI) TO WS-ED-SUM
                   PERFORM 8200-AMOUNT-LINE
               END-PERFORM
           END-IF.

       8100-COUNT-LINE.
           MOVE WS-ED-COUNT TO WS-PRINT(31:5)
           WRITE SUM-LINE FROM WS-PRINT
           MOVE SPACES TO WS-PRINT.

       8200-AMOUNT-LINE.
           MOVE WS-ED-SUM TO WS-PRINT(26:15)
           WRITE SUM-LINE FROM WS-PRINT
           MOVE SPACES TO WS-PRINT.

       9000-CLOSE.
           CLOSE STMT-FILE
           CLOSE REJ-FILE
           CLOSE SUM-FILE.
"""
s+=tail
# header literal fix
old=s[s.index("           STRING \"DATE       DESCRIPTION"):s.index("           WRITE STMT-LINE FROM WS-PRINT\n           WRITE STMT-LINE FROM WS-RULE-DASH.")]
new=("           STRING \"DATE       DESCRIPTION\" SPACES-28 \"QTY\"\n")
s=s.replace(old,"""           MOVE "DATE       DESCRIPTION" TO WS-PRINT(1:22)
           MOVE "QTY" TO WS-PRINT(51:3)
           MOVE "AMOUNT" TO WS-PRINT(64:6)
""")
# fix SU check
s=s.replace("IF WS-END-N < XR-DATE-N","IF WS-END-N < WS-ACTD")
s=s.replace("           05  WS-AMT-OKF              PIC X.","           05  WS-AMT-OKF              PIC X.\n           05  WS-ACTD                 PIC 9(8).")
s=s.replace("""           IF WS-REJ-CODE = SPACES
               IF DU-DATE-N < WS-CYC-START OR DU-DATE-N > WS-CYC-END""","""           IF WS-REJ-CODE = SPACES
               MOVE DU-DATE-N TO WS-ACTD
               IF DU-DATE-N < WS-CYC-START OR DU-DATE-N > WS-CYC-END""")
open("billrun.cbl","w").write(s)
PY
cd /app/src && cobc -x -fstatic-call -I copy -o /app/build/billrun billrun.cbl lib/*.cbl 2>&1 | head -40'
```

<details><summary>output</summary>

```
lib/prorate.cbl:9: error: RATETAB: No such file or directory
lib/prorate.cbl: in paragraph '0000-MAIN':
lib/prorate.cbl:41: error: 'PF-PLAN' is not defined
lib/prorate.cbl:42: error: 'PF-FEE' is not defined
```
</details>

### Step 55: Bash

```bash
docker exec sn-cobol-production-parity bash -lc 'cd /w/src37 && cobc -x -fstatic-call -I copy -o /w/b37 billrun.cbl lib/*.cbl 2>&1 | head; ls -la /w/src37/copy /app/src/copy; env | grep -i -E "COB|LANG"'
```

<details><summary>output</summary>

```
Exit code 1
copy/REJMSG.cpy:19: error: syntax error, unexpected MESSAGE
billrun.cbl: in paragraph '7000-WRITE-REJECT':
billrun.cbl:860: error: syntax error, unexpected MESSAGE
lib/prorate.cbl:9: error: RATETAB: No such file or directory
lib/prorate.cbl: in paragraph '0000-MAIN':
lib/prorate.cbl:41: error: 'PF-PLAN' is not defined
lib/prorate.cbl:42: error: 'PF-FEE' is not defined
/app/src/copy:
total 56
drwxr-xr-x 1 root root 4096 Nov 18 08:59 .
drwxr-xr-x 1 root root 4096 Nov 18 08:30 ..
-rw-r--r-- 1 root root  965 Nov 18 08:30 ACCTREC.cpy
-rw-r--r-- 1 root root 1728 Nov 18 08:59 ACTREC.cpy
-rw-r--r-- 1 root root  474 Nov 18 08:30 CTLREC.cpy
-rw-r--r-- 1 root root  459 Nov 18 08:30 DSPARM.cpy
-rw-r--r-- 1 root root  442 Nov 18 08:30 DUPARM.cpy
-rw-r--r-- 1 root root  667 Nov 18 08:30 PRPARM.cpy
-rw-r--r-- 1 root root  501 Nov 18 08:30 RCPARM.cpy
-rw-r--r-- 1 root root 1645 Nov 18 08:59 REJMSG.cpy
-rw-r--r-- 1 root root  406 Nov 18 08:30 TXPARM.cpy
-rw-r--r-- 1 root root  552 Nov 18 08:30 ratetab.cpy

/w/src37/copy:
total 48
drwxr-xr-x 2 root root 4096 Nov 18 08:59 .
drwxr-xr-x 4 root root 4096 Nov 18 08:59 ..
-rw-r--r-- 1 root root  965 Nov 18 08:59 ACCTREC.cpy
-rw-r--r-- 1 root root 1417 Nov 18 08:59 ACTREC.cpy
-rw-r--r-- 1 root root  474 Nov 18 08:59 CTLREC.cpy
-rw-r--r-- 1 root root  459 Nov 18 08:59 DSPARM.cpy
-rw-r--r-- 1 root root  442 Nov 18 08:59 DUPARM.cpy
-rw-r--r-- 1 root root  667 Nov 18 08:59 PRPARM.cpy
-rw-r--r-- 1 root root  501 Nov 18 08:59 RCPARM.cpy
-rw-r--r-- 1 root root 1048 Nov 18 08:59 REJMSG.cpy
-rw-r--r-- 1 root root  406 Nov 18 08:59 TXPARM.cpy
-rw-r--r-- 1 root root  552 Nov 18 08:59 ratetab.cpy
```
</details>

### Step 56: Bash

```bash
docker exec sn-cobol-production-parity bash -lc 'cd /app/src && mv copy/ratetab.cpy copy/RATETAB.cpy && cobc -x -fstatic-call -I copy -o /app/build/billrun billrun.cbl lib/*.cbl 2>&1 | head -40'
```

<details><summary>output</summary>

```
(Bash completed with no output)
```
</details>

### Step 57: Bash

```bash
docker exec sn-cobol-production-parity bash -lc 'cd /w; cat >> h.py <<EOF
import difflib
def cmp(c,a,x,verbose=True):
    p=run(c,a,x); m=run(c,a,x,binp="/app/build/billrun")
    bad=[k for k in p if p[k]!=m[k]]
    if bad and verbose:
        for k in bad:
            if k in ("rc","stderr"): print(k,p[k],m[k]); continue
            print("DIFF",k)
            for l in difflib.unified_diff((p[k] or "").split("\n"),(m[k] or "").split("\n"),"prod","mine",lineterm="",n=1): print(l.replace(" ","."))
    return not bad
EOF
timeout 100 python3 - <<EOF
from h import *
import glob
c=open("/app/samples/basic/CONTROL.DAT").read(); a=open("/app/samples/basic/ACCOUNTS.DAT").read(); x=open("/app/samples/basic/ACTIVITY.DAT").read()
print(cmp(c,a,x))
EOF'
```

<details><summary>output</summary>

```
True
```
</details>

Sample matches. Now a random fuzzer.

### Step 58: Bash

```bash
docker exec sn-cobol-production-parity bash -lc 'cd /w; cat > fuzz.py <<EOF
import random,sys
from h import *
def rdate(lo="20250301",hi="20250331",bad=0.03):
    r=random.random()
    if r<bad: return random.choice(["20250230","        ","2025031x","20251301","20250300","18991231"])
    d=random.randint(int(lo[6:]),int(hi[6:])); return lo[:6]+"%02d"%d
def ramt(maxv=100000,bad=0.02,pos=False):
    r=random.random()
    if r<bad: return random.choice(["+00000x000","          ","*000001000","000001000 ","-000000000","+000000000"])
    v=random.choice([random.randint(0,maxv),random.randint(0,3000),random.randint(0,99)])
    s=random.choice("+-") if not pos else "+"
    return s+"%09d"%v
def gen(seed):
    random.seed(seed)
    s=random.choice(["20250301","20250301","20250301","20250215","20250101","20241220"])
    n=random.choice([31,31,28,30,10,1,15,7,8])
    import datetime
    sd=datetime.datetime.strptime(s,"%Y%m%d"); ed=sd+datetime.timedelta(days=n-1)
    c=ctl(s=s,e=ed.strftime("%Y%m%d"),run=random.choice(["000123","7","  ABC"]),co=random.choice(["ACME CORP","NORTHWIND TELECOM",""]))
    ids=["AC%06d"%i for i in range(1,random.randint(2,8))]
    A=[]
    def dd(off): return (sd+datetime.timedelta(days=off)).strftime("%Y%m%d")
    for i in ids:
        r=random.random()
        op=random.choice(["20200101","20240601",dd(random.randint(0,n-1)),dd(random.randint(0,n-1)),dd(n+3)])
        cl=random.choice(["        ","        ","00000000",dd(random.randint(0,n-1)),dd(-5),dd(random.randint(0,n+3))])
        A.append(acct(id=i,name=random.choice(["JOHN SMITH","ANA ADAMS","X"]),plan=random.choice("BSP"),op=op,cl=cl,tc=random.choice("NNNRE"),reg=random.choice(["NE","SW","NE","W ","  "]),bal=random.choice(["+000000000","+000012550","-000000700","+000100000"]),loy=random.choice(["  ","L1","L2","L3","L1","L9"])))
        if random.random()<0.04: A.append(random.choice([acct(id=i),acct(id="        "),acct(id="BADPLAN1",plan="X"),acct(id="BADDATE1",op="20250230"),acct(id="BADTAX01",tc="Z"),acct(id="BADBAL01",bal="+0000A0000")]))
    X=[]
    for k in range(random.randint(0,40)):
        a=random.choice(ids+(["NOACCT01"] if random.random()<0.05 else []))
        d=rdate(dd(0),dd(n-1)) if random.random()>0.05 else dd(n+2)
        t=random.choice(["US","US","US","CH","CH","PC","PY","AD","DS","SU","DS","SU"])
        if random.random()<0.02: t="ZZ"
        if t=="US": X.append(us(a=a,d=d,svc=random.choice(["DATA","VOIC","SMS ","ROAM","DATA","VOIC","XXXX" if random.random()<0.05 else "ROAM"]),q=random.choice(["%09d"%random.randint(0,20000),"%09d"%random.randint(0,500000),"%09d"%random.randint(0,3000),"0000x0000"][:3 if random.random()>0.03 else 4]),t="US"))
        elif t=="CH": X.append(ch(a=a,d=d,code=random.choice(["EQUP","INST","LATE","LATE","DEPO","MISC","BAD1" if random.random()<0.05 else "MISC"]),amt=ramt(20000),desc=random.choice(["PHONE","LATE FEE","","A B C"])))
        elif t=="PC": X.append(pc(a=a,d=d,p=random.choice("BSPBSP"+("X" if random.random()<0.05 else "B"))))
        elif t=="PY": X.append(py(a=a,d=d,amt=ramt(30000,pos=random.random()<0.9)))
        elif t=="AD": X.append(ad(a=a,d=d,amt=ramt(5000),reason=random.choice(["GOODWILL","ERR","" ])))
        elif t=="DS": X.append(ds(a=a,d=d,k=random.choice("PFPF"+("X" if random.random()<0.05 else "P")),v=random.choice(["+000001500","+000000500","+000002000","+000000250","+000010000","+000100000","+000010001","+000050000","-000000100","+000003333"])))
        elif t=="SU": 
            e=rdate(d,dd(n+2),bad=0.03) if random.random()>0.05 else d
            X.append(su(a=a,d=d,e=e))
        else: X.append(us(a=a,d=d,t=t))
        if random.random()<0.04: X.append(X[-1])
    return c,A,X
if __name__=="__main__":
    lo,hi=int(sys.argv[1]),int(sys.argv[2]); bad=0
    for sd in range(lo,hi):
        c,A,X=gen(sd)
        if not cmp(c,A,X,verbose=(bad<2)):
            bad+=1; print("SEED",sd)
            if bad>=3: break
    print("bad",bad)
EOF
timeout 110 python3 fuzz.py 0 150'
```

<details><summary>output</summary>

```
Exit code 1
Traceback (most recent call last):
  File "/w/fuzz.py", line 50, in <module>
    c,A,X=gen(sd)
          ^^^^^^^
  File "/w/fuzz.py", line 32, in gen
    d=rdate(dd(0),dd(n-1)) if random.random()>0.05 else dd(n+2)
      ^^^^^^^^^^^^^^^^^^^^
  File "/w/fuzz.py", line 6, in rdate
    d=random.randint(int(lo[6:]),int(hi[6:])); return lo[:6]+"%02d"%d
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/usr/lib/python3.11/random.py", line 362, in randint
    return self.randrange(a, b+1)
           ^^^^^^^^^^^^^^^^^^^^^^
  File "/usr/lib/python3.11/random.py", line 345, in randrange
    raise ValueError("empty range for randrange() (%d, %d, %d)" % (istart, istop, width))
ValueError: empty range for randrange() (15, 2, -13)
```
</details>

### Step 59: Bash

```bash
docker exec sn-cobol-production-parity bash -lc 'cd /w; python3 - <<EOF
s=open("fuzz.py").read()
i=s.index("def rdate"); j=s.index("def ramt")
s=s[:i]+"""import datetime
def rdate(lo,hi,bad=0.03):
    r=random.random()
    if r<bad: return random.choice(["20250230","        ","2025031x","20251301","20250300","18991231"])
    a=datetime.datetime.strptime(lo,"%Y%m%d"); b=datetime.datetime.strptime(hi,"%Y%m%d")
    if b<a: return lo
    return (a+datetime.timedelta(days=random.randint(0,(b-a).days))).strftime("%Y%m%d")
"""+s[j:]
open("fuzz.py","w").write(s)
EOF
timeout 110 python3 fuzz.py 0 150'
```

<details><summary>output</summary>

```
Exit code 1
DIFF SUMMARY.RPT
---.prod
+++.mine
@@.-17,3.+17,3.@@
.TOTAL.USAGE........................18.81
-TOTAL.CHARGES.....................-24.39
+TOTAL.CHARGES............-.........24.39
.TOTAL.DISCOUNTS....................18.27
SEED 3
Traceback (most recent call last):
  File "/w/fuzz.py", line 53, in <module>
    c,A,X=gen(sd)
          ^^^^^^^
  File "/w/fuzz.py", line 45, in gen
    e=rdate(d,dd(n+2),bad=0.03) if random.random()>0.05 else d
      ^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/w/fuzz.py", line 7, in rdate
    a=datetime.datetime.strptime(lo,"%Y%m%d"); b=datetime.datetime.strptime(hi,"%Y%m%d")
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/usr/lib/python3.11/_strptime.py", line 568, in _strptime_datetime
    tt, fraction, gmtoff_fraction = _strptime(data_string, format)
                                    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/usr/lib/python3.11/_strptime.py", line 352, in _strptime
    raise ValueError("unconverted data remains: %s" %
ValueError: unconverted data remains: 1
```
</details>

### Step 60: Bash

```bash
docker exec sn-cobol-production-parity bash -lc 'cd /w; sed -i "s/PIC -ZZZ,ZZZ,ZZ9.99/PIC ----,---,--9.99/" /app/src/billrun.cbl; grep -n "WS-ED-SUM  " /app/src/billrun.cbl; python3 - <<EOF
s=open("fuzz.py").read()
s=s.replace("    a=datetime.datetime.strptime(lo,\"%Y%m%d\")","    try: a=datetime.datetime.strptime(lo,\"%Y%m%d\")\n    except Exception: return lo\n    a=datetime.datetime.strptime(lo,\"%Y%m%d\")",1)
open("fuzz.py","w").write(s)
EOF
cd /app/src && cobc -x -fstatic-call -I copy -o /app/build/billrun billrun.cbl lib/*.cbl 2>&1 | head; cd /w; timeout 110 python3 fuzz.py 0 150'
```

<details><summary>output</summary>

```
266:       01  WS-ED-SUM                   PIC ----,---,--9.99.
DIFF STATEMENTS.RPT
---.prod
+++.mine
@@.-10,5.+10,5.@@
.2025-02-21.LATE.PHONE........................................99.97CR
-2025-02-16.COUPON....00%......................................0.00
-2025-02-16.COUPON....00%......................................0.00
-2025-02-16.COUPON....00%......................................0.00
+...........COUPON....00%......................................0.00
+...........COUPON....00%......................................0.00
+...........COUPON....00%......................................0.00
............SUBTOTAL.........................................270.01CR
SEED 134
bad 1
```
</details>

### Step 61: Bash

```bash
docker exec sn-cobol-production-parity bash -lc 'cd /w; timeout 100 python3 - <<EOF
from fuzz import *
c,A,X=gen(134)
print(c);print("\n".join(A));print("\n".join(X))
o=run(c,A,X); print(o["STATEMENTS.RPT"][:3000])
EOF'
```

<details><summary>output</summary>

```
2025021520250222000123                              
AC000001ANA ADAMS               B20250215        E  +000100000  
AC000002X                       S2020010120250225NNE-000000700L1
AC000003JOHN SMITH              S20250221        NSW+000012550L9
AC000004X                       B2024060120250219NSW+000000000L3
AC000005JOHN SMITH              B2024060120250216N  +000012550L1
CHAC00000220250221MISC+000000088PHONE               
CHAC00000318991231MISC+000000115PHONE               
ADAC00000120250219    -000002470                    
USAC00000420250219ROAM000019268
USAC00000220250221DATA000262294
CHAC00000420250216LATE+000015619LATE FEE            
SUAC0000012025022520250225
ADAC00000220250220    -000000075                    
DSAC00000420250219P   +000050000
CHAC00000120250221LATE-000009997PHONE               
DSAC00000220250225P   +000010001
SUAC0000012025022520250225
ADAC00000120250215    -000001180ERR                 
PYAC00000120250218CARD+000000008
CHAC00000220250215EQUP-000011170A B C               
USAC00000320250219VOIC000003122
DSAC00000120250221F   +000000500
SUAC0000012025021520250223
CHAC00000120250218MISC-000017504                    
PCAC00000520250220S
DSAC00000320250220P   +000000500
ADAC00000320250222    -000000096                    
USAC00000420250215ROAM000016669
USAC00000520250221ROAM000410822
DSAC00000520250221P   +000100000
USAC00000420250220ROAM000013498
CHAC00000520250220MISC-000000038                    
DSAC00000120250218P   +000000500
SUAC0000022025021520250222
SUAC0000022025021720250221
DSAC00000120250222P   +000001500
CHAC00000420250219LATE+000001510A B C               
========================================================================
                                BILLING STATEMENT  RUN 000123
ACCOUNT AC000001  ANA ADAMS                 REGION
PERIOD 2025-02-15 TO 2025-02-22  DAYS  8  PLAN B
------------------------------------------------------------------------
DATE       DESCRIPTION                            QTY          AMOUNT
------------------------------------------------------------------------
2025-02-15 BASE FEE PLAN B                      8.00          5.00
2025-02-18 MISC                                             175.04CR
2025-02-21 LATE PHONE                                        99.97CR
2025-02-16 COUPON   .00%                                      0.00
2025-02-16 COUPON   .00%                                      0.00
2025-02-16 COUPON   .00%                                      0.00
           SUBTOTAL                                         270.01CR
           TAX E 0.00%                                        0.00
2025-02-15 ADJ ERR                                           11.80CR
2025-02-19 ADJ                                               24.70CR
           CURRENT CHARGES                                  306.51CR
           PRIOR BALANCE                                  1,000.00
2025-02-18 PAYMENT RECEIVED                                   0.08CR
---------------------------------------
... [1611 more chars truncated]
```
</details>

### Step 62: Bash

```bash
docker exec sn-cobol-production-parity bash -lc 'cd /w; timeout 100 python3 - <<EOF
from h import *
import re
def t(c,A,X):
    o=run(c,A,X); return [(l[0],l[1],l[3]) for l in lines(o) if l[1].startswith("COUPON")]
c=ctl(s="20250215",e="20250222")
a1=acct(id="AC000001",plan="B",op="20250215",tc="E",reg="  ",bal="+000100000")
base=[ch(a="AC000001",d="20250218",code="MISC",amt="-000017504",desc=""),ch(a="AC000001",d="20250221",code="LATE",amt="-000009997",desc="PHONE"),
 ds(a="AC000001",d="20250221",k="F",v="+000000500"),ds(a="AC000001",d="20250218",k="P",v="+000000500"),ds(a="AC000001",d="20250222",k="P",v="+000001500")]
print("base",t(c,[a1],base))
print("only one ds",t(c,[a1],base[:2]+[base[2]]))
print("only P",t(c,[a1],base[:2]+[base[3]]))
# other accounts present
a2=acct(id="AC000005",plan="B",op="20240601",cl="20250216",tc="N",reg="  ",bal="+000012550",loy="L1")
print("with acct5",t(c,[a1,a2],base))
a3=acct(id="AC000004",plan="B",op="20240601",cl="20250219",tc="N",reg="SW",bal="+000012550",loy="L3")
print("with acct4 only",t(c,[a1,a3],base))
print("acct5 first",t(c,[a2,a1],base))
EOF'
```

<details><summary>output</summary>

```
base [('', 'COUPON   .00%', '0.00'), ('', 'COUPON   .00%', '0.00'), ('', 'COUPON   .00%', '0.00')]
only one ds [('', 'COUPON   .00%', '0.00')]
only P [('', 'COUPON   .00%', '0.00')]
with acct5 [('2025-02-16', 'COUPON   .00%', '0.00'), ('2025-02-16', 'COUPON   .00%', '0.00'), ('2025-02-16', 'COUPON   .00%', '0.00')]
with acct4 only [('2025-02-19', 'COUPON   .00%', '0.00'), ('2025-02-19', 'COUPON   .00%', '0.00'), ('2025-02-19', 'COUPON   .00%', '0.00')]
acct5 first [('', 'COUPON   .00%', '0.00'), ('', 'COUPON   .00%', '0.00'), ('', 'COUPON   .00%', '0.00')]
```
</details>

### Step 63: Bash

```bash
docker exec sn-cobol-production-parity bash -lc 'cd /w; timeout 100 python3 - <<EOF
from h import *
def t(c,A,X):
    o=run(c,A,X); return [(l[0],l[1],l[3]) for l in lines(o) if l[1].startswith("COUPON")]
c=ctl(s="20250215",e="20250222")
a1=acct(id="AC000001",plan="B",op="20250215",tc="E",reg="  ",bal="+000100000")
base=[ch(a="AC000001",d="20250218",code="MISC",amt="-000017504",desc=""),ds(a="AC000001",d="20250221",k="F",v="+000000500")]
a5=acct(id="AC000005",plan="B",op="20240601",cl="20250216",tc="N",reg="  ")
rej=acct(id="AC000006",plan="X",op="20240601",cl="20250217")
notin=acct(id="AC000007",plan="B",op="20240601",cl="20250110")
print("rejected last",t(c,[a1,a5,rej],base))
print("notin last",t(c,[a1,a5,notin],base))
print("close 00000000 last",t(c,[a1,a5,acct(id="AC000008",cl="00000000")],base))
EOF'
```

<details><summary>output</summary>

```
rejected last [('2025-02-16', 'COUPON   .00%', '0.00')]
notin last [('2025-01-10', 'COUPON   .00%', '0.00')]
close 00000000 last [('', 'COUPON   .00%', '0.00')]
```
</details>

### Step 64: Bash

```bash
docker exec sn-cobol-production-parity bash -lc 'cd /app/src; python3 - <<EOF
s=open("billrun.cbl").read()
old="""               PERFORM VARYING WL FROM 1 BY 1 UNTIL WL > WB-NCOUP
                   MOVE 0 TO WP-DATE
"""
new="""               PERFORM VARYING WL FROM 1 BY 1 UNTIL WL > WB-NCOUP
                   MOVE AT-CLOSE-DATE(AT-COUNT) TO WP-DATE
"""
assert old in s
open("billrun.cbl","w").write(s.replace(old,new))
EOF
cobc -x -fstatic-call -I copy -o /app/build/billrun billrun.cbl lib/*.cbl 2>&1 | head; cd /w; timeout 115 python3 fuzz.py 0 250'
```

<details><summary>output</summary>

```
bad 0
```
</details>

### Step 65: Bash

```bash
docker exec sn-cobol-production-parity bash -lc 'cd /w; (timeout 280 python3 fuzz.py 250 1200 > f1.out 2>&1 &) ; (timeout 280 python3 fuzz.py 1200 2200 > f2.out 2>&1 &); sleep 270; cat f1.out f2.out'
```

<details><summary>output</summary>

```
Command did not complete within its 120s timeout and was moved to the background (ID: bwn0gia74). Output is being written to: <tmp> You will be notified when it completes. It is running now: do not start a second copy while it runs. If it is no longer needed, stop it with TaskStop. No output had been read from it when it was moved. A program that buffers its output, or a pipe into one such as tail, can keep the output file empty until the command finishes. To check interim output, use Read on that file path.
```
</details>

### Step 66: Bash

```bash
sleep 100; docker exec sn-cobol-production-parity bash -lc 'cd /w; cat f1.out f2.out'
```

<details><summary>output</summary>

```
<tool_use_error>Blocked: sleep 100 followed by: docker exec sn-cobol-production-parity bash -lc 'cd /w; cat f1.out f2.out'. To wait for a condition, use Monitor with an until-loop (e.g. `until <check>; do sleep 2; done`). To wait for a command you started, use run_in_background: true. Do not chain shorter sleeps to work around this block.</tool_use_error>
```
</details>

### Step 67: Bash

```bash
docker exec sn-cobol-production-parity bash -lc 'cd /w; until [ -s f1.out ] && [ -s f2.out ]; do sleep 3; done; cat f1.out f2.out'
```

<details><summary>output</summary>

```
bad 0
bad 0
```
</details>

### Step 68: Bash

```bash
docker exec sn-cobol-production-parity bash -lc 'cd /w; timeout 110 python3 - <<EOF
from h import *
A1=[acct(id="AC000001",plan="S",loy="L1"),acct(id="AC000002",plan="P",op="20250310")]
X1=[us(),ch(),py()]
cases=[]
for c in [None,"",ctl(s="18991231",e="19000101"),ctl(s="19000101",e="19000131"),ctl(s="20250301",e="20250331"),ctl(s="20250301",e="20250401"),ctl(s="20250228",e="20250331"),ctl(s="20250301",e="20250228"),ctl(s="2025030x"),ctl(run="",co=""),"2025030120250331","20250301","\n"+ctl(),ctl()+"\n\n"+ctl(),ctl(s="20240229",e="20240331"),ctl(s="20241201",e="20241231")]:
    cases.append((c,A1,X1))
cases += [(ctl(),None,None),(ctl(),[],None),(ctl(),None,[us()]),(ctl(),A1,[]),(ctl(),[""]+A1,["",""]+X1),(ctl(),A1+[""],X1+[""]),(ctl(),[a[:30] for a in A1],[x[:25] for x in X1]),(ctl(),[a.rstrip() for a in A1],[x.rstrip() for x in X1])]
for i,(c,a,x) in enumerate(cases):
    if not cmp(c,a,x): print("CASE",i,repr(c)[:50])
print("done")
EOF'
```

<details><summary>output</summary>

```
done
```
</details>

### Step 69: Bash

```bash
docker exec sn-cobol-production-parity bash -lc 'cd /w; cat > fuzz2.py <<EOF
import random,sys
from h import *
import fuzz
def gen(seed):
    random.seed(seed)
    c=ctl(s="20250301",e=random.choice(["20250331","20250331","20250308","20250301","20250330"]))
    ids=["AC%06d"%i for i in range(1,random.randint(2,5))]
    A=[acct(id=i,plan=random.choice("BSP"),op=random.choice(["20200101","20250305","20250331"]),bal=random.choice(["+999999999","-999999999","+000000001","+500000000"]),loy=random.choice(["L1","L2","L3","  "]),tc=random.choice("NRE"),reg=random.choice(["NE","SW"])) for i in ids]
    X=[]
    big=lambda: random.choice(["%09d"%random.randint(0,999999999),"999999999","%09d"%random.randint(0,99999999),"%09d"%random.randint(0,9999999)])
    for k in range(random.randint(1,25)):
        a=random.choice(ids); d="202503%02d"%random.randint(5,31)
        t=random.choice(["US","CH","DS","AD","PY","PC","SU"])
        if t=="US": X.append(us(a=a,d=d,svc=random.choice(["DATA","VOIC","SMS ","ROAM"]),q=big()))
        elif t=="CH": X.append(ch(a=a,d=d,code=random.choice(["EQUP","LATE","DEPO","MISC"]),amt=random.choice("+-")+big()))
        elif t=="DS": X.append(ds(a=a,d=d,k=random.choice("PF"),v=random.choice(["+","+"])+random.choice(["%09d"%random.randint(1,10000),big()])))
        elif t=="AD": X.append(ad(a=a,d=d,amt=random.choice("+-")+big()))
        elif t=="PY": X.append(py(a=a,d=d,amt="+"+big()))
        elif t=="PC": X.append(pc(a=a,d=d,p=random.choice("BSP")))
        else: X.append(su(a=a,d=d,e="2025033%d"%random.randint(0,1)))
    return c,A,X
lo,hi=int(sys.argv[1]),int(sys.argv[2]); bad=0
for sd in range(lo,hi):
    c,A,X=gen(sd)
    if not cmp(c,A,X,verbose=(bad<2)):
        bad+=1; print("SEED",sd)
        if bad>=3: break
print("bad",bad)
EOF
timeout 110 python3 fuzz2.py 0 200'
```

<details><summary>output</summary>

```
DIFF STATEMENTS.RPT
---.prod
+++.mine
@@.-10,3.+10,3.@@
............USAGE.DATA.GB..................825,760.45....660,625.76
-...........USAGE.VOICE.MIN......................0.00..........0.00
+...........USAGE.VOICE.MIN......................0.00....500,000.00
............USAGE.SMS.MSG..................744,275.00.....14,885.50
@@.-18,9.+18,9.@@
.2025-03-20.COUPON.FIXED..................................58,850.24CR
-2025-03-16.COUPON..3.85%.................................25,271.15CR
-2025-03-16.COUPON.30.11%................................190,030.94CR
-...........SUBTOTAL...................................1,125,825.54
-...........TAX.R.4.00%...................................17,643.66
+2025-03-16.COUPON..3.85%.................................44,521.15CR
+2025-03-16.COUPON.30.11%................................334,784.76CR
+...........SUBTOTAL...................................1,461,821.72
+...........TAX.R.4.00%...................................31,083.50
.2025-03-25.ADJ.REASON...................................597,073.18CR
.2025-03-29.ADJ.REASON....................................84,598.91CR
-...........CURRENT.CHARGES..............................461,797.11
+...........CURRENT.CHARGES..............................811,233.13
............PRIOR.BALANCE..............................9,999,999.99CR
@@.-28,3.+28,3.@@
.------------------------------------------------------------------------
-...........AMOUNT.DUE.................................9,538,202.87CR
+...........AMOUNT.DUE.................................9,188,766.85CR
.
DIFF SUMMARY.RPT
---.prod
+++.mine
@@.-11,11.+11,11.@@
.TOTAL.BASE.FEES.....................7.18
-TOTAL.USAGE...................675,511.26
+TOTAL.USAGE.................1,175,511.26
.TOTAL.CHARGES.................724,522.78
-TOTAL.DISCOUNTS...............274,215.68
-TOTAL.TAX......................17,643.66
+TOTAL.DISCOUNTS...............438,219.50
+TOTAL.TAX......................31,083.50
.TOTAL.ADJUSTMENTS............-681,672.09
.TOTAL.PAYMENTS..............9,999,999.99
-TOTAL.AMOUNT.DUE...........-9,538,202.87
+TOTAL.AMOUNT.DUE...........-9,188,766.85
.AMOUNT.DUE.BY.REGION
-..REGION.NE................-9,538,202.87
+..REGION.NE................-9,188,766.85
.
SEED 2
DIFF STATEMENTS.RPT
---.prod
+++.mine
@@.-27,3.+27,3.@@
.2025-03-29.BASE.FEE.PLAN.S......................3.00..........1.21
-...........USAGE.DATA.GB..................175,450.80..4,140,378.04
+...........USAGE.DATA.GB................5,175,450.80..4,140,378.04
............USAGE.SMS.MSG...................65,029.00......1,300.58
SEED 3
SEED 5
bad 3
```
</details>

### Step 70: Bash

```bash
docker exec sn-cobol-production-parity bash -lc 'cd /w; timeout 100 python3 - <<EOF
from h import *
def u(svc,recs,plan="S"):
    o=run(ctl(),[acct(id="AC000001",plan=plan)],recs)
    return [(l[2],l[3]) for l in lines(o) if l[1].startswith("USAGE")], o["STATEMENTS.RPT"].count("\n")
for m in [99999,100000,100001,999999,1000000,1234567,9999999]:
    print("VOIC",m,u("VOIC",[us(svc="VOIC",q="%09d"%(m*100))]))
for m in [99999,100000,999999,1000000,1234567,9999999]:
    print("SMS",m,u("SMS ",[us(svc="SMS ",q="%09d"%(m*100))]))
for m in [999999,1000000,1234567,9999999]:
    print("ROAM",m,u("ROAM",[us(svc="ROAM",q="%09d"%(m*100))]))
for m in [999999,1000000,1234567,5000000]:
    print("DATA",m,u("DATA",[us(svc="DATA",q="%09d"%(m*100))]))
EOF'
```

<details><summary>output</summary>

```
VOIC 99999 ([('99,999.00', '4,999.95')], 15)
VOIC 100000 ([('100,000.00', '5,000.00')], 15)
VOIC 100001 ([('100,001.00', '5,000.05')], 15)
VOIC 999999 ([('999,999.00', '49,999.95')], 15)
VOIC 1000000 ([('0.00', '50,000.00')], 15)
VOIC 1234567 ([('234,567.00', '61,728.35')], 15)
VOIC 9999999 ([('999,999.00', '499,999.95')], 15)
SMS 99999 ([('99,999.00', '1,999.98')], 15)
SMS 100000 ([('100,000.00', '2,000.00')], 15)
SMS 999999 ([('999,999.00', '19,999.98')], 15)
SMS 1000000 ([('0.00', '20,000.00')], 15)
SMS 1234567 ([('234,567.00', '24,691.34')], 15)
SMS 9999999 ([('999,999.00', '199,999.98')], 15)
ROAM 999999 ([('999,999.00', '249,999.75')], 15)
ROAM 1000000 ([('0.00', '250,000.00')], 15)
ROAM 1234567 ([('234,567.00', '308,641.75')], 15)
ROAM 9999999 ([('999,999.00', '2,499,999.75')], 15)
DATA 999999 ([('999,999.00', '800,016.60')], 15)
DATA 1000000 ([('0.00', '800,017.40')], 15)
DATA 1234567 ([('234,567.00', '987,671.00')], 15)
DATA 5000000 ([('0.00', '4,000,017.40')], 15)
```
</details>

### Step 71: Bash

```bash
docker exec sn-cobol-production-parity bash -lc 'cd /w; timeout 100 python3 - <<EOF
from h import *
def u(recs,plan="S"):
    o=run(ctl(),[acct(id="AC000001",plan=plan)],recs)
    return [(l[1][6:],l[2],l[3]) for l in lines(o) if l[1].startswith("USAGE")]
d=lambda i:"202503%02d"%(10+i)
print("VOIC 10M",u([us(svc="VOIC",q="999999999")]))
print("VOIC 9999999 x2",u([us(svc="VOIC",q="999999900",d=d(0)),us(svc="VOIC",q="999999900",d=d(1))]))
print("VOIC 9999999 x3",u([us(svc="VOIC",q="999999900",d=d(i)) for i in range(3)]))
print("VOIC 5M x3",u([us(svc="VOIC",q="500000000",d=d(i)) for i in range(3)]))
print("SMS 9999999 x2",u([us(svc="SMS ",q="999999900",d=d(i)) for i in range(2)]))
print("SMS 9999999 x3",u([us(svc="SMS ",q="999999900",d=d(i)) for i in range(3)]))
print("SMS 9999999 x20",u([us(svc="SMS ",q="999999900",d=d(i)) for i in range(20)]))
print("ROAM x2",u([us(svc="ROAM",q="999999999",d=d(i)) for i in range(2)]))
print("ROAM x5",u([us(svc="ROAM",q="999999999",d=d(i)) for i in range(5)]))
print("DATA x2",u([us(svc="DATA",q="999999999",d=d(i)) for i in range(2)]))
print("DATA x3",u([us(svc="DATA",q="999999999",d=d(i)) for i in range(3)]))
print("DATA x12",u([us(svc="DATA",q="999999999",d=d(i)) for i in range(12)]))
print("DATA 9M+",u([us(svc="DATA",q="900000000",d=d(i)) for i in range(2)]))
EOF'
```

<details><summary>output</summary>

```
VOIC 10M [('VOICE MIN', '0.00', '0.00')]
VOIC 9999999 x2 [('VOICE MIN', '999,998.00', '499,999.90')]
VOIC 9999999 x3 [('VOICE MIN', '999,997.00', '499,999.85')]
VOIC 5M x3 [('VOICE MIN', '0.00', '250,000.00')]
SMS 9999999 x2 [('SMS MSG', '999,998.00', '199,999.96')]
SMS 9999999 x3 [('SMS MSG', '999,997.00', '199,999.94')]
SMS 9999999 x20 [('SMS MSG', '999,980.00', '199,999.60')]
ROAM x2 [('ROAMING MB', '999,999.98', '5,000,000.00')]
ROAM x5 [('ROAMING MB', '999,999.95', '2,500,000.00')]
DATA x2 [('DATA GB', '999,999.98', '8,000,017.38')]
DATA x3 [('DATA GB', '999,999.97', '8,000,017.38')]
DATA x12 [('DATA GB', '999,999.88', '8,000,017.30')]
DATA 9M+ [('DATA GB', '0.00', '6,400,017.40')]
```
</details>

### Step 72: Bash

```bash
docker exec sn-cobol-production-parity bash -lc 'cd /app/src; python3 - <<EOF
s=open("billrun.cbl").read()
rep=[("           05  WU-DATA-QTY             PIC 9(9)V99.","           05  WU-DATA-QTY             PIC 9(7)V99."),
("           05  WU-VOIC-MIN             PIC 9(9).","           05  WU-VOIC-MIN             PIC 9(7)."),
("           05  WU-SMS-MSG              PIC 9(9).","           05  WU-SMS-MSG              PIC 9(7)."),
("           05  WU-ROAM-QTY             PIC 9(9)V99.","           05  WU-ROAM-QTY             PIC 9(7)V99."),
("           05  WU-ROAM-AMT             PIC 9(9)V99.","           05  WU-ROAM-AMT             PIC 9(7)V99."),
("           05  WU-M                    PIC 9(9).","           05  WU-M                    PIC 9(7)."),
("       01  WS-ED-QTY                   PIC Z,ZZZ,ZZ9.99.","       01  WS-ED-QTY                   PIC ZZZ,ZZ9.99."),
("           05  DL-DESC                 PIC X(29).\n           05  DL-QTY                  PIC X(12).","           05  DL-DESC                 PIC X(31).\n           05  DL-QTY                  PIC X(10)."),
]
for a,b in rep:
    assert a in s,a
    s=s.replace(a,b)
open("billrun.cbl","w").write(s)
EOF
cobc -x -fstatic-call -I copy -o /app/build/billrun billrun.cbl lib/*.cbl 2>&1 | head; cd /w; timeout 100 python3 fuzz2.py 0 100'
```

<details><summary>output</summary>

```
bad 0
```
</details>

### Step 73: Bash

```bash
docker exec sn-cobol-production-parity bash -lc 'cd /w; (timeout 250 python3 fuzz2.py 100 1100 > g1.out 2>&1 &) ; (timeout 250 python3 fuzz2.py 1100 2100 > g2.out 2>&1 &); (timeout 250 python3 fuzz.py 3000 4200 > g3.out 2>&1 &); until [ -s g1.out ] && [ -s g2.out ] && [ -s g3.out ]; do sleep 3; done; cat g1.out g2.out g3.out'
```

<details><summary>output</summary>

```
bad 0
bad 0
bad 0
```
</details>

### Step 74: Bash

```bash
docker exec sn-cobol-production-parity bash -lc 'cd /w; cat > grid.py <<EOF
from h import *
import random
bad=0
# proration x loyalty x cycle length
for n in range(1,32):
    c=ctl(s="20250301",e="202503%02d"%n) if n>0 else None
    A=[]
    for p in "BSP":
        for l in ["L1","L2","L3"]:
            for op in range(1,n+1):
                A.append(acct(id="%s%s%02d%03d"%(p,l[1],op,n),plan=p,op="202503%02d"%op,loy=l))
    A=A[:500]
    # split into chunks of 50
    for i in range(0,len(A),50):
        if not cmp(c,A[i:i+50],[],verbose=False): bad+=1; print("BAD proration",n,i)
print("bad",bad)
EOF
timeout 250 python3 grid.py'
```

<details><summary>output</summary>

```
bad 0
```
</details>

### Step 75: Bash

```bash
docker exec sn-cobol-production-parity bash -lc 'cd /w; cat > grid2.py <<EOF
from h import *
import random
random.seed(5)
bad=0
for it in range(120):
    A=[];X=[]
    for k in range(40):
        i="AC%06d"%k; p=random.choice("BSP"); A.append(acct(id=i,plan=p,loy=random.choice(["  ","L1","L2","L3"]),tc=random.choice("NRE")))
        svc=random.choice(["DATA","VOIC","SMS ","ROAM"])
        q=random.choice([random.randint(0,300),random.randint(0,6000),random.randint(0,25000),random.randint(0,200000)])
        X.append(us(a=i,svc=svc,q="%09d"%q))
        if random.random()<0.3: X.append(us(a=i,svc=svc,q="%09d"%random.randint(0,5000),d="20250312"))
    if not cmp(ctl(),A,X,verbose=(bad<2)): bad+=1
print("bad",bad)
EOF
timeout 250 python3 grid2.py'
```

<details><summary>output</summary>

```
bad 0
```
</details>

### Step 76: Bash

```bash
docker exec sn-cobol-production-parity bash -lc 'cd /w; cat > grid3.py <<EOF
from h import *
import random
random.seed(9)
bad=0
for it in range(150):
    A=[];X=[]
    for k in range(40):
        i="AC%06d"%k; p=random.choice("BSP"); A.append(acct(id=i,plan=p,op="202503%02d"%random.randint(1,31),loy=random.choice(["  ","L1","L2","L3"]),tc=random.choice("NRE")))
        for j in range(random.randint(0,4)):
            t=random.choice(["CH","CH","DS","DS","AD"])
            d="202503%02d"%random.randint(25,31)
            if t=="CH": X.append(ch(a=i,d=d,code=random.choice(["MISC","LATE","DEPO","EQUP"]),amt=random.choice("+-")+"%09d"%random.randint(0,random.choice([100,3000,10000])),desc="X%d"%j))
            elif t=="DS": X.append(ds(a=i,d=d,k=random.choice("PF"),v="+%09d"%random.choice([random.randint(1,10000),random.randint(1,500),random.randint(1,3000)])))
            else: X.append(ad(a=i,d=d,amt="+%09d"%random.randint(1,100),reason="R%d"%j))
    if not cmp(ctl(),A,X,verbose=(bad<2)): bad+=1
print("bad",bad)
EOF
timeout 250 python3 grid3.py'
```

<details><summary>output</summary>

```
bad 0
```
</details>

### Step 77: Bash

```bash
docker exec sn-cobol-production-parity bash -lc 'cd /w; timeout 200 python3 - <<EOF
from h import *
import datetime
bad=0
for (s,e) in [("20240201","20240229"),("20240215","20240316"),("21000201","21000228"),("21000215","21000305"),("19000101","19000131"),("19000115","19000214"),("99991201","99991231"),("20001231","20010101"),("20250101","20250131"),("20251201","20251231"),("18991231","19000101"),("20200229","20200229"),("20190301","20190301")]:
    sd=datetime.datetime.strptime(s,"%Y%m%d") if s[:2]!="99" else None
    A=[acct(id="AC%06d"%k,plan="BSP"[k%3],op=op,cl=cl,loy=["  ","L1","L2","L3"][k%4]) for k,(op,cl) in enumerate([("19000101","        "),(s,e),(e,"        "),("18500101","        "),(s,"        "),("19900101",e),("19900101","00000000")])]
    X=[us(a="AC000001",d=s),us(a="AC000002",d=e,svc="DATA"),ch(a="AC000003",d=e),su(a="AC000004",d=s,e=e),pc(a="AC000005",d=e,p="P"),ds(a="AC000006",d=s,k="P"),py(a="AC000001",d=s)]
    if not cmp(ctl(s=s,e=e),A,X,verbose=(bad<2)): bad+=1; print("BAD",s,e)
print("bad",bad)
EOF'
```

<details><summary>output</summary>

```
bad 0
```
</details>

### Step 78: Bash

```bash
docker exec sn-cobol-production-parity bash -lc 'cd /w; (timeout 250 python3 fuzz.py 5000 7000 > h1.out 2>&1 &) ; (timeout 250 python3 fuzz.py 7000 9000 > h2.out 2>&1 &); (timeout 250 python3 fuzz2.py 3000 4500 > h3.out 2>&1 &); until [ -s h1.out ] && [ -s h2.out ] && [ -s h3.out ]; do sleep 3; done; cat h1.out h2.out h3.out; cd /app/src && cobc -x -fstatic-call -I copy -o /app/build/billrun billrun.cbl lib/*.cbl && echo built'
```

<details><summary>output</summary>

```
bad 0
DIFF STATEMENTS.RPT
---.prod
+++.mine
@@.-40,3.+40,3.@@
.2025-03-01.LATE.PHONE........................................71.94CR
-...........COUPON.L3.00%......................................0.00
+2025-03-01.COUPON.L3.00%......................................0.00
............SUBTOTAL..........................................59.44CR
SEED 8167
bad 1
bad 0
built
```
</details>

### Step 79: Bash

```bash
docker exec sn-cobol-production-parity bash -lc 'cd /w; timeout 100 python3 - <<EOF
from fuzz import *
c,A,X=gen(8167)
print(c);print("\n".join(A));
o=run(c,A,X); 
import re
print(o["STATEMENTS.RPT"][o["STATEMENTS.RPT"].index("COUPON")-1500:][:1800])
print([x for x in X if x[:2]=="DS"])
EOF'
```

<details><summary>output</summary>

```
20250301202503017                                   
AC000001ANA ADAMS               S2025030120250304RNE+000100000  
AC000002X                       P2024060100000000NSW+000000000L3
AC000003JOHN SMITH              B2020010120250301ESW-000000700  
AC000004X                       S20250301        ENE+000100000L9
AC000005JOHN SMITH              S2025030120250301RNE+000012550L3
AC000006X                       B2025030120250224ESW-000000700L9
BADTAX01TEST CUSTOMER           B20200101        ZNE+000000000  
                  REGION NE
PERIOD 2025-03-01 TO 2025-03-01  DAYS  1  PLAN S
------------------------------------------------------------------------
DATE       DESCRIPTION                            QTY          AMOUNT
------------------------------------------------------------------------
2025-03-01 BASE FEE PLAN S                      1.00         25.00
           USAGE DATA GB                       55.13         61.50
           SUBTOTAL                                          86.50
           TAX E 0.00%                                        0.00
           CURRENT CHARGES                                   86.50
           PRIOR BALANCE                                  1,000.00
2025-03-01 PAYMENT RECEIVED                                   0.65CR
------------------------------------------------------------------------
           AMOUNT DUE                                     1,085.85
========================================================================
                                BILLING STATEMENT  RUN 7
ACCOUNT AC000005  JOHN SMITH                REGION NE
PERIOD 2025-03-01 TO 2025-03-01  DAYS  1  PLAN S
------------------------------------------------------------------------
DATE       DESCRIPTION                            QTY          AMOUNT
------------------------------------------------------------------------
2025-03-01 BASE FEE PLAN S                      1.00         12.50
2025-03-01 LATE PHONE                                        71.94CR
           COUPON L3.00%                                      0.00
           SUBTOTAL                                          59.44CR
           TAX R 4.00%                                        0.00
2025-03-01 ADJ ERR                                            7.14CR
           CURRENT CHARGES             
['DSAC00000620250301P   +000050000', 'DSAC00000520250301F   +000000250', 'DSAC00000620250301P   +000001500']
```
</details>

### Step 80: Bash

```bash
docker exec sn-cobol-production-parity bash -lc 'cd /app/src; sed -i "s/MOVE AT-CLOSE-DATE(AT-COUNT) TO WP-DATE/MOVE WS-CLOSE-N TO WP-DATE/" billrun.cbl; grep -n "WS-CLOSE-N TO WP-DATE" billrun.cbl; cobc -x -fstatic-call -I copy -o /app/build/billrun billrun.cbl lib/*.cbl 2>&1|head; cd /w; timeout 100 python3 - <<EOF
from h import *
def t(c,A,X):
    o=run(c,A,X); return [(l[0],l[1],l[3]) for l in lines(o) if l[1].startswith("COUPON")]
c=ctl(s="20250215",e="20250222")
a1=acct(id="AC000001",plan="B",op="20250215",tc="E",reg="  ",bal="+000100000")
base=[ch(a="AC000001",d="20250218",code="MISC",amt="-000017504",desc=""),ds(a="AC000001",d="20250221",k="F",v="+000000500")]
a5=acct(id="AC000005",plan="B",op="20240601",cl="20250216",tc="N",reg="  ")
for name,r in [("A04",acct(id="AC000006",op="20250230",cl="20250217")),("A05inv",acct(id="AC000006",cl="2025023x")),("A05lt",acct(id="AC000006",op="20250210",cl="20250205")),("A06",acct(id="AC000006",cl="20250217",tc="Z")),("A07",acct(id="AC000006",cl="20250217",bal="x")),("A02",acct(id="AC000001",cl="20250217")),("A01",acct(id="        ",cl="20250217"))]:
    print(name,cmp(c,[a1,a5,r],base,verbose=True), t(c,[a1,a5,r],base))
EOF'
```

<details><summary>output</summary>

```
1094:                   MOVE WS-CLOSE-N TO WP-DATE
A04 True [('2025-02-16', 'COUPON   .00%', '0.00')]
A05inv True [('2025-02-16', 'COUPON   .00%', '0.00')]
DIFF STATEMENTS.RPT
---.prod
+++.mine
@@.-9,3.+9,3.@@
.2025-02-18.MISC.............................................175.04CR
-2025-02-16.COUPON....00%......................................0.00
+2025-02-05.COUPON....00%......................................0.00
............SUBTOTAL.........................................165.04CR
A05lt False [('2025-02-16', 'COUPON   .00%', '0.00')]
A06 True [('2025-02-17', 'COUPON   .00%', '0.00')]
A07 True [('2025-02-17', 'COUPON   .00%', '0.00')]
A02 True [('2025-02-16', 'COUPON   .00%', '0.00')]
A01 True [('2025-02-16', 'COUPON   .00%', '0.00')]
```
</details>

### Step 81: Bash

```bash
docker exec sn-cobol-production-parity bash -lc 'cd /app/src; python3 - <<EOF
s=open("billrun.cbl").read()
old="""                       MOVE DU-DATE-N TO WS-CLOSE-N
                       IF WS-CLOSE-N < WS-OPEN-N
                           MOVE "A05" TO WS-REJ-CODE
                       END-IF
"""
new="""                       IF DU-DATE-N < WS-OPEN-N
                           MOVE "A05" TO WS-REJ-CODE
                       ELSE
                           MOVE DU-DATE-N TO WS-CLOSE-N
                       END-IF
"""
assert old in s
open("billrun.cbl","w").write(s.replace(old,new))
EOF
cobc -x -fstatic-call -I copy -o /app/build/billrun billrun.cbl lib/*.cbl 2>&1|head; cd /w; (timeout 250 python3 fuzz.py 8000 9500 > i1.out 2>&1 &) ; (timeout 250 python3 fuzz.py 9500 11000 > i2.out 2>&1 &); (timeout 250 python3 fuzz.py 0 1500 > i3.out 2>&1 &); until [ -s i1.out ] && [ -s i2.out ] && [ -s i3.out ]; do sleep 3; done; cat i1.out i2.out i3.out'
```

<details><summary>output</summary>

```
bad 0
bad 0
bad 0
```
</details>

### Step 82: Bash

```bash
docker exec sn-cobol-production-parity bash -lc 'cd /app/src && rm -f /app/build/billrun && cobc -x -fstatic-call -I copy -o /app/build/billrun billrun.cbl lib/*.cbl && echo ok; cd /w; python3 - <<EOF
from h import *
c=open("/app/samples/basic/CONTROL.DAT").read(); a=open("/app/samples/basic/ACCOUNTS.DAT").read(); x=open("/app/samples/basic/ACTIVITY.DAT").read()
print(cmp(c,a,x))
EOF'
```

<details><summary>output</summary>

```
ok
True
```
</details>

### Step 83: SubagentHandback

```bash
{"message": "I rewrote `/app/src/billrun.cbl` to behave like production 4.2. The build command from the task compiles it, and across several thousand randomized input sets all three reports and the return code match `/app/prod/billrun` byte for byte. My confidence is fairly high, not certain.\n\n**Build fixes (the 3.7 source did not compile)**\n- `copy/ratetab.cpy` is renamed to `copy/RATETAB.cpy`, because `COPY RATETAB` failed on a case-sensitive filesystem.\n- `REJMSG.cpy` used `MESSAGE`, which is a reserved word, so I rewrote it with a 20-entry table (A01–A07, R01–R12, C01).\n- `copy/ACTREC.cpy` gains DS and SU record layouts.\n\n**Program changes**\n- `lib/dateutil.cbl` now does a proper calendar check with leap years and a minimum year of 1900.\n- `billrun.cbl` implements everything I could observe from production 4.2:\n  - the new account and activity validation and reject codes, plus the new report layouts;\n  - proration with suspended days billed at half;\n  - plan allowances and tiered data pricing, per-record voice, SMS and roaming rounding, the late-fee cap, deposits excluded from tax, and tax rounding;\n  - loyalty and coupon stacking with the 50% discount cap;\n  - statement ordering by region and account id, the summary and per-region totals, and return codes 0, 4 and 16.\n- The 3.7 library modules other than `DATEUTIL` are untouched and unused. `DATEUTIL` is the only `CALL`, with a literal name.\n- Field widths, including the overflow wrap-around on very large quantities, follow what production does.\n- Production has an odd quirk when the discount base is zero or negative. Coupon lines then print as `COUPON L1.00%` with the last-read account's close date in the date column. I reproduced it, including how that date goes stale.\n\n**Testing**\nI diffed my build against production on inputs I generated. That covered:\n- about 8,000 mixed random seeds, including invalid values, duplicates and extreme magnitudes;\n- grids over cycle length and open day for every plan and loyalty tier;\n- usage quantity sweeps, discount and tax rounding ties, and leap-year and 1900 dates;\n- missing, empty and short-line files.\n\nThe only mismatches found along the way were the quirk's stale date and extreme-value field widths, and both are fixed. The remaining risk is a rule production has that my inputs never triggered."}
```

<details><summary>output</summary>

```
{"success":true,"message":"Report delivered to your caller."}
```
</details>

