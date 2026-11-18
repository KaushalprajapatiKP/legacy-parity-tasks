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
               10  XT-DATE             PIC 9(8).
               10  XT-CODE             PIC X(4).
               10  XT-QTY              PIC 9(7)V99.
               10  XT-AMOUNT           PIC S9(7)V99.
               10  XT-DESC             PIC X(20).

      *    PER-ACCOUNT WORK LIST (ACTIVITY INDEXES IN FILE ORDER)
       01  WS-LIST.
           05  WL-COUNT                PIC 9(4) COMP.
           05  WL-IX OCCURS 3000 TIMES PIC 9(4) COMP.

       01  WS-INDEXES.
           05  WI                      PIC 9(4) COMP.
           05  WX                      PIC 9(4) COMP.
           05  WA                      PIC 9(4) COMP.
           05  WD                      PIC 9(4) COMP.
           05  WP                      PIC 9(4) COMP.

       01  WS-WORK.
           05  WS-AMOUNT               PIC S9(7)V99.
           05  WS-AMT-SIGN             PIC X.
           05  WS-AMT-DIGITS           PIC X(9).
           05  WS-AMT-VALUE REDEFINES WS-AMT-DIGITS
                                       PIC 9(7)V99.
           05  WS-CLOSE-N              PIC 9(8).
           05  WS-REJ-CODE             PIC X(3).
           05  WS-REJ-RECORD           PIC X(80).

      *    PER-ACCOUNT BILLING WORK AREA
       01  WS-BILL.
           05  WB-AX                   PIC 9(4) COMP.
           05  WB-BASE                 PIC S9(7)V99.
           05  WB-USAGE                PIC S9(7)V99.
           05  WB-CHARGES              PIC S9(7)V99.
           05  WB-DISC                 PIC S9(7)V99.
           05  WB-SUBTOTAL             PIC S9(7)V99.
           05  WB-TAX                  PIC S9(7)V99.
           05  WB-ADJ                  PIC S9(7)V99.
           05  WB-CURRENT              PIC S9(7)V99.
           05  WB-PAY                  PIC S9(7)V99.
           05  WB-DUE                  PIC S9(7)V99.
           05  WB-FINAL-PLAN           PIC X.
           05  WB-DATA-QTY             PIC 9(7)V99.
           05  WB-VOIC-QTY             PIC 9(7)V99.
           05  WB-SMS-QTY              PIC 9(7)V99.
           05  WB-ROAM-QTY             PIC 9(7)V99.
           05  WB-HAS-DATA             PIC X.
           05  WB-HAS-VOIC             PIC X.
           05  WB-HAS-SMS              PIC X.
           05  WB-HAS-ROAM             PIC X.

      *    REPORT LINES
       01  WS-RULE-STAR                PIC X(60) VALUE ALL "*".
       01  WS-RULE-DASH                PIC X(60) VALUE ALL "-".
       01  WS-PRINT                    PIC X(100).
       01  WS-DATE-DISP                PIC X(10).
       01  WS-DATE-DISP2               PIC X(10).
       01  WS-DATE-IN                  PIC 9(8).
       01  WS-ED-COUNT                 PIC ZZZZ9.
       01  WS-ED-DAYS                  PIC ZZ9.
       01  WS-ED-SUM                   PIC -ZZZ,ZZZ,ZZ9.99.

       01  WP-PARMS.
           05  WP-DATE                 PIC 9(8).
           05  WP-DESC                 PIC X(32).
           05  WP-AMT                  PIC S9(7)V99.

       01  DL-LINE.
           05  DL-DATE                 PIC X(10).
           05  FILLER                  PIC X(2) VALUE SPACES.
           05  DL-DESC                 PIC X(32).
           05  FILLER                  PIC X(2) VALUE SPACES.
           05  DL-AMT                  PIC -Z,ZZZ,ZZ9.99.

       01  RJ-DETAIL.
           05  RJ-CODE                 PIC X(3).
           05  FILLER                  PIC X(2) VALUE SPACES.
           05  RJ-MSG                  PIC X(20).
           05  FILLER                  PIC X VALUE SPACE.
           05  RJ-REC                  PIC X(60).

       PROCEDURE DIVISION.
      *----------------------------------------------------------------
      * MAIN LINE. CONTROL, LOAD, BILL, REPORT.
      * RETURN CODE IS SET FROM WS-RC JUST BEFORE STOP RUN.
      *----------------------------------------------------------------
       0000-MAIN.
           PERFORM 1000-INIT
           PERFORM 1100-READ-CONTROL
           IF WS-CTL-OK = "N"
               PERFORM 1900-CONTROL-FAIL
           ELSE
               PERFORM 2000-LOAD-ACCOUNTS
               PERFORM 3000-LOAD-ACTIVITY
               PERFORM 5000-PRODUCE-STATEMENTS
               PERFORM 7900-REJECT-TRAILER
               PERFORM 8000-WRITE-SUMMARY
           END-IF
           PERFORM 9000-CLOSE
           MOVE WS-RC TO RETURN-CODE
           STOP RUN.

      *----------------------------------------------------------------
      *----------------------------------------------------------------
      * OPEN THE THREE REPORT FILES. THEY ARE ALWAYS CREATED,
      * EVEN WHEN THE CONTROL RECORD IS BAD.
      *----------------------------------------------------------------
       1000-INIT.
           OPEN OUTPUT STMT-FILE
           OPEN OUTPUT REJ-FILE
           OPEN OUTPUT SUM-FILE.

      *----------------------------------------------------------------
      * READ AND VALIDATE THE CONTROL RECORD. BOTH DATES MUST
      * BE VALID AND THE END MAY NOT BE BEFORE THE START.
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
               END-IF
           END-IF.

      *----------------------------------------------------------------
      * REJECT LISTING HEADINGS.
      *----------------------------------------------------------------
       1200-REJECT-HEADER.
           MOVE SPACES TO WS-PRINT
           STRING "BILLRUN " WS-VERSION " REJECT LISTING  RUN "
                  WS-RUN-NO
                  DELIMITED BY SIZE INTO WS-PRINT
           WRITE REJ-LINE FROM WS-PRINT
           MOVE SPACES TO WS-PRINT
           STRING "CODE MESSAGE              RECORD"
                  DELIMITED BY SIZE INTO WS-PRINT
           WRITE REJ-LINE FROM WS-PRINT.

      *----------------------------------------------------------------
      * BAD CONTROL RECORD: LIST IT, WRITE A SHORT CONTROL
      * TOTALS PAGE AND END WITH RETURN CODE 12.
      *----------------------------------------------------------------
       1900-CONTROL-FAIL.
           MOVE "C01" TO WS-REJ-CODE
           MOVE CTL-RECORD TO WS-REJ-RECORD
           PERFORM 7000-WRITE-REJECT
           PERFORM 7900-REJECT-TRAILER
           MOVE SPACES TO WS-PRINT
           STRING "BILLRUN " WS-VERSION " CONTROL TOTALS  RUN "
                  WS-RUN-NO
                  DELIMITED BY SIZE INTO WS-PRINT
           WRITE SUM-LINE FROM WS-PRINT
           MOVE "CONTROL CARD ERROR - RUN TERMINATED" TO SUM-LINE
           WRITE SUM-LINE
           MOVE 12 TO WS-RC.

      *----------------------------------------------------------------
      * ACCOUNT MASTER LOAD AND VALIDATION
      *----------------------------------------------------------------
      *----------------------------------------------------------------
      * LOAD THE ACCOUNT MASTER INTO ACCT-TABLE (MAX 500).
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

      *----------------------------------------------------------------
      * ACCOUNT EDITS, FIRST FAILURE WINS:
      *   A01 ID  A03 PLAN  A04 OPEN  A05 CLOSE  A07 BALANCE
      *----------------------------------------------------------------
       2100-VALIDATE-ACCOUNT.
           MOVE SPACES TO WS-REJ-CODE
           IF AR-ACCT-ID = SPACES
               MOVE "A01" TO WS-REJ-CODE
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
                   END-IF
               END-IF
           END-IF
           IF WS-REJ-CODE = SPACES
               IF AR-BAL-DIGITS IS NOT NUMERIC
                   MOVE "A07" TO WS-REJ-CODE
               END-IF
           END-IF
           IF WS-REJ-CODE NOT = SPACES
               ADD 1 TO WS-ACCT-REJECTED
               MOVE ACCT-RECORD TO WS-REJ-RECORD
               PERFORM 7000-WRITE-REJECT
           ELSE
               PERFORM 2200-STORE-ACCOUNT
           END-IF.

      *----------------------------------------------------------------
      * KEEP AN ACCEPTED ACCOUNT. UNKNOWN TAX CLASSES ARE
      * BILLED AS NORMAL (N).
      *----------------------------------------------------------------
       2200-STORE-ACCOUNT.
           ADD 1 TO AT-COUNT
           MOVE AT-COUNT TO WA
           MOVE AR-ACCT-ID TO AT-ACCT-ID(WA)
           MOVE AR-NAME TO AT-NAME(WA)
           MOVE AR-PLAN TO AT-PLAN(WA)
           MOVE AR-OPEN-DATE TO AT-OPEN-DATE(WA)
           MOVE WS-CLOSE-N TO AT-CLOSE-DATE(WA)
           MOVE AR-TAX-CLASS TO AT-TAX-CLASS(WA)
           IF AR-TAX-CLASS NOT = "R" AND AR-TAX-CLASS NOT = "E"
               MOVE "N" TO AT-TAX-CLASS(WA)
           END-IF
           MOVE AR-REGION TO AT-REGION(WA)
           MOVE AR-BAL-SIGN TO WS-AMT-SIGN
           MOVE AR-BAL-DIGITS TO WS-AMT-DIGITS
           PERFORM 3160-SIGNED-VALUE
           MOVE WS-AMOUNT TO AT-PRIOR-BAL(WA)
           MOVE AR-LOYALTY TO AT-LOYALTY(WA).

      *----------------------------------------------------------------
      * ACTIVITY LOAD AND VALIDATION
      *----------------------------------------------------------------
      *----------------------------------------------------------------
      * LOAD THE ACTIVITY FILE INTO ACT-TABLE (MAX 3000).
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

      *----------------------------------------------------------------
      * ACTIVITY EDITS, FIRST FAILURE WINS:
      *   R01 TYPE  R02 ACCOUNT  R03 DATE  THEN THE TYPE EDITS
      *----------------------------------------------------------------
       3100-VALIDATE-ACTIVITY.
           MOVE SPACES TO WS-REJ-CODE
           IF XR-TYPE NOT = "US" AND XR-TYPE NOT = "CH"
              AND XR-TYPE NOT = "PC" AND XR-TYPE NOT = "PY"
              AND XR-TYPE NOT = "AD"
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
               EVALUATE XR-TYPE
                   WHEN "US"  PERFORM 3200-CHECK-USAGE
                   WHEN "CH"  PERFORM 3300-CHECK-CHARGE
                   WHEN "PC"  PERFORM 3400-CHECK-PLAN-CHANGE
                   WHEN "PY"  PERFORM 3150-CHECK-AMOUNT
                   WHEN "AD"  PERFORM 3150-CHECK-AMOUNT
               END-EVALUATE
           END-IF
           IF WS-REJ-CODE NOT = SPACES
               ADD 1 TO WS-ACT-REJECTED
               MOVE ACT-RECORD TO WS-REJ-RECORD
               PERFORM 7000-WRITE-REJECT
           ELSE
               PERFORM 3900-STORE-ACTIVITY
           END-IF.

      *----------------------------------------------------------------
      * AMOUNT DIGITS MUST BE NUMERIC.
      *----------------------------------------------------------------
       3150-CHECK-AMOUNT.
           IF XR-CH-DIGITS IS NOT NUMERIC
               MOVE "R05" TO WS-REJ-CODE
           END-IF.

      *----------------------------------------------------------------
      * SIGN + DIGITS TO A SIGNED VALUE. ONLY '-' IS NEGATIVE.
      *----------------------------------------------------------------
       3160-SIGNED-VALUE.
           MOVE WS-AMT-VALUE TO WS-AMOUNT
           IF WS-AMT-SIGN = "-"
               COMPUTE WS-AMOUNT = 0 - WS-AMOUNT
           END-IF.

      *----------------------------------------------------------------
      * USAGE: SERVICE CODE THEN QUANTITY.
      *----------------------------------------------------------------
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

      *----------------------------------------------------------------
      * ONE-TIME CHARGE: CHARGE CODE THEN AMOUNT.
      *----------------------------------------------------------------
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
           PERFORM 5500-BASE-FEES
           PERFORM 5600-USAGE
           PERFORM 5700-CHARGES
           PERFORM 5750-DISCOUNTS
           PERFORM 5800-TOTALS.

      *----------------------------------------------------------------
      * COLLECT THIS ACCOUNT'S ACTIVITY (FILE ORDER).
      *----------------------------------------------------------------
       5200-BUILD-LIST.
           MOVE 0 TO WL-COUNT
           PERFORM VARYING WI FROM 1 BY 1 UNTIL WI > XT-COUNT
               IF XT-ACCT-IX(WI) = WB-AX
                   ADD 1 TO WL-COUNT
                   MOVE WI TO WL-IX(WL-COUNT)
               END-IF
           END-PERFORM.

      *----------------------------------------------------------------
      * THE LAST PLAN CHANGE IN THE FILE SETS THE PLAN.
      *----------------------------------------------------------------
       5300-FINAL-PLAN.
           MOVE AT-PLAN(WB-AX) TO WB-FINAL-PLAN
           PERFORM VARYING WI FROM 1 BY 1 UNTIL WI > WL-COUNT
               MOVE WL-IX(WI) TO WX
               IF XT-TYPE(WX) = "PC"
                   MOVE XT-CODE(WX)(1:1) TO WB-FINAL-PLAN
               END-IF
           END-PERFORM.

      *----------------------------------------------------------------
      * STATEMENT HEADING BLOCK.
      *----------------------------------------------------------------
       5400-STATEMENT-HEADER.
           WRITE STMT-LINE FROM WS-RULE-STAR
           MOVE SPACES TO WS-PRINT
           STRING "BILLRUN " WS-VERSION "   " WS-COMPANY
                  "   STATEMENT"
                  DELIMITED BY SIZE INTO WS-PRINT
           WRITE STMT-LINE FROM WS-PRINT
           MOVE SPACES TO WS-PRINT
           STRING "ACCT: " AT-ACCT-ID(WB-AX) "  NAME: "
                  AT-NAME(WB-AX)
                  DELIMITED BY SIZE INTO WS-PRINT
           WRITE STMT-LINE FROM WS-PRINT
           MOVE WS-CYC-START TO WS-DATE-IN
           PERFORM 5990-FORMAT-DATE
           MOVE WS-DATE-DISP TO WS-DATE-DISP2
           MOVE WS-CYC-END TO WS-DATE-IN
           PERFORM 5990-FORMAT-DATE
           MOVE WS-CYC-DAYS TO WS-ED-DAYS
           MOVE SPACES TO WS-PRINT
           STRING "BILLING PERIOD: " WS-DATE-DISP2 " - "
                  WS-DATE-DISP " (" WS-ED-DAYS " DAYS)"
                  DELIMITED BY SIZE INTO WS-PRINT
           WRITE STMT-LINE FROM WS-PRINT
           MOVE SPACES TO WS-PRINT
           STRING "REGION: " AT-REGION(WB-AX) "  PLAN: "
                  WB-FINAL-PLAN "  TAX CLASS: " AT-TAX-CLASS(WB-AX)
                  DELIMITED BY SIZE INTO WS-PRINT
           WRITE STMT-LINE FROM WS-PRINT
           WRITE STMT-LINE FROM WS-RULE-DASH.

      *----------------------------------------------------------------
      * MONTHLY FEE. EVERY DAY OF THE CYCLE CARRIES THE FINAL
      * PLAN, SO PRORATE RETURNS THE FULL MONTHLY FEE.
      *----------------------------------------------------------------
       5500-BASE-FEES.
           IF WS-CYC-DAYS > 31
               MOVE 31 TO PR-CYCLE-DAYS
           ELSE
               MOVE WS-CYC-DAYS TO PR-CYCLE-DAYS
           END-IF
           PERFORM VARYING WD FROM 1 BY 1 UNTIL WD > 31
               MOVE SPACE TO PR-DAY-PLAN(WD)
               IF WD NOT > PR-CYCLE-DAYS
                   MOVE WB-FINAL-PLAN TO PR-DAY-PLAN(WD)
               END-IF
           END-PERFORM
           CALL "PRORATE" USING PR-PARMS
           MOVE 0 TO WP-DATE
           MOVE SPACES TO WP-DESC
           STRING "MONTHLY FEE - PLAN " WB-FINAL-PLAN
                  DELIMITED BY SIZE INTO WP-DESC
           MOVE PR-TOTAL TO WP-AMT
           PERFORM 5900-PUT-LINE
           MOVE PR-TOTAL TO WB-BASE.

      *----------------------------------------------------------------
      * TOTAL USAGE PER SERVICE, THEN RATE EACH SERVICE ONCE.
      *----------------------------------------------------------------
       5600-USAGE.
           PERFORM VARYING WI FROM 1 BY 1 UNTIL WI > WL-COUNT
               MOVE WL-IX(WI) TO WX
               IF XT-TYPE(WX) = "US"
                   EVALUATE XT-CODE(WX)
                       WHEN "DATA"
                           MOVE "Y" TO WB-HAS-DATA
                           ADD XT-QTY(WX) TO WB-DATA-QTY
                       WHEN "VOIC"
                           MOVE "Y" TO WB-HAS-VOIC
                           ADD XT-QTY(WX) TO WB-VOIC-QTY
                       WHEN "SMS "
                           MOVE "Y" TO WB-HAS-SMS
                           ADD XT-QTY(WX) TO WB-SMS-QTY
                       WHEN "ROAM"
                           MOVE "Y" TO WB-HAS-ROAM
                           ADD XT-QTY(WX) TO WB-ROAM-QTY
                   END-EVALUATE
               END-IF
           END-PERFORM
           MOVE 0 TO WP-DATE
           MOVE WB-FINAL-PLAN TO RC-PLAN
           IF WB-HAS-DATA = "Y"
               MOVE "D" TO RC-FUNC
               MOVE WB-DATA-QTY TO RC-QTY
               MOVE "DATA USAGE" TO WP-DESC
               PERFORM 5650-RATE-LINE
           END-IF
           IF WB-HAS-VOIC = "Y"
               MOVE "V" TO RC-FUNC
               MOVE WB-VOIC-QTY TO RC-QTY
               MOVE "VOICE USAGE" TO WP-DESC
               PERFORM 5650-RATE-LINE
           END-IF
           IF WB-HAS-SMS = "Y"
               MOVE "S" TO RC-FUNC
               MOVE WB-SMS-QTY TO RC-QTY
               MOVE "SMS USAGE" TO WP-DESC
               PERFORM 5650-RATE-LINE
           END-IF
           IF WB-HAS-ROAM = "Y"
               MOVE "R" TO RC-FUNC
               MOVE WB-ROAM-QTY TO RC-QTY
               MOVE "ROAMING USAGE" TO WP-DESC
               PERFORM 5650-RATE-LINE
           END-IF.

      *----------------------------------------------------------------
      * RATE ONE SERVICE TOTAL AND PRINT IT.
      *----------------------------------------------------------------
       5650-RATE-LINE.
           CALL "RATECALC" USING RC-PARMS
           MOVE RC-AMOUNT TO WP-AMT
           ADD RC-AMOUNT TO WB-USAGE
           PERFORM 5900-PUT-LINE.

      *----------------------------------------------------------------
      * ONE-TIME CHARGES IN FILE ORDER.
      *----------------------------------------------------------------
       5700-CHARGES.
           PERFORM VARYING WI FROM 1 BY 1 UNTIL WI > WL-COUNT
               MOVE WL-IX(WI) TO WX
               IF XT-TYPE(WX) = "CH"
                   MOVE XT-DATE(WX) TO WP-DATE
                   MOVE SPACES TO WP-DESC
                   STRING XT-CODE(WX) " " XT-DESC(WX)
                          DELIMITED BY SIZE INTO WP-DESC
                   MOVE XT-AMOUNT(WX) TO WP-AMT
                   PERFORM 5900-PUT-LINE
                   ADD XT-AMOUNT(WX) TO WB-CHARGES
               END-IF
           END-PERFORM.

      *----------------------------------------------------------------
      * LOYALTY DISCOUNT ON FEES PLUS USAGE.
      *----------------------------------------------------------------
       5750-DISCOUNTS.
           MOVE WB-BASE TO DS-BASE
           MOVE WB-USAGE TO DS-USAGE
           MOVE AT-LOYALTY(WB-AX) TO DS-LOYALTY-CODE
           CALL "DISCOUNT" USING DS-PARMS
           MOVE DS-LOYALTY-AMT TO WB-DISC
           IF WB-DISC NOT = 0
               MOVE 0 TO WP-DATE
               MOVE SPACES TO WP-DESC
               STRING "LOYALTY DISCOUNT " DS-LOYALTY-CODE
                      DELIMITED BY SIZE INTO WP-DESC
               COMPUTE WP-AMT = 0 - WB-DISC
               PERFORM 5900-PUT-LINE
           END-IF.

      *----------------------------------------------------------------
      * STATEMENT TOTALS. TAX IS ON THE SUBTOTAL. ADJUSTMENTS
      * AND PAYMENTS ARE PRINTED AS ONE LINE EACH.
      *----------------------------------------------------------------
       5800-TOTALS.
           MOVE 0 TO WP-DATE
           WRITE STMT-LINE FROM WS-RULE-DASH
           COMPUTE WB-SUBTOTAL = WB-BASE + WB-USAGE + WB-CHARGES
                               - WB-DISC
           MOVE "SUBTOTAL" TO WP-DESC
           MOVE WB-SUBTOTAL TO WP-AMT
           PERFORM 5900-PUT-LINE
           MOVE AT-TAX-CLASS(WB-AX) TO TX-CLASS
           MOVE WB-SUBTOTAL TO TX-TAXABLE
           CALL "TAXCALC" USING TX-PARMS
           MOVE TX-AMOUNT TO WB-TAX
           MOVE SPACES TO WP-DESC
           STRING "SALES TAX " TX-RATE-DISP
                  DELIMITED BY SIZE INTO WP-DESC
           MOVE WB-TAX TO WP-AMT
           PERFORM 5900-PUT-LINE
           PERFORM VARYING WI FROM 1 BY 1 UNTIL WI > WL-COUNT
               MOVE WL-IX(WI) TO WX
               IF XT-TYPE(WX) = "AD"
                   ADD XT-AMOUNT(WX) TO WB-ADJ
               END-IF
               IF XT-TYPE(WX) = "PY"
                   ADD XT-AMOUNT(WX) TO WB-PAY
               END-IF
           END-PERFORM
           MOVE "ADJUSTMENTS" TO WP-DESC
           MOVE WB-ADJ TO WP-AMT
           PERFORM 5900-PUT-LINE
           COMPUTE WB-CURRENT = WB-SUBTOTAL + WB-TAX + WB-ADJ
           MOVE "TOTAL CURRENT CHARGES" TO WP-DESC
           MOVE WB-CURRENT TO WP-AMT
           PERFORM 5900-PUT-LINE
           MOVE "PREVIOUS BALANCE" TO WP-DESC
           MOVE AT-PRIOR-BAL(WB-AX) TO WP-AMT
           PERFORM 5900-PUT-LINE
           MOVE "PAYMENTS - THANK YOU" TO WP-DESC
           COMPUTE WP-AMT = 0 - WB-PAY
           PERFORM 5900-PUT-LINE
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
           ADD WB-DUE TO WT-DUE.

      *----------------------------------------------------------------
      * PRINT ONE STATEMENT DETAIL LINE.
      *----------------------------------------------------------------
       5900-PUT-LINE.
           MOVE SPACES TO DL-DATE
           IF WP-DATE NOT = 0
               MOVE WP-DATE TO WS-DATE-IN
               PERFORM 5990-FORMAT-DATE
               MOVE WS-DATE-DISP TO DL-DATE
           END-IF
           MOVE WP-DESC TO DL-DESC
           MOVE WP-AMT TO DL-AMT
           WRITE STMT-LINE FROM DL-LINE.

      *----------------------------------------------------------------
      * YYYYMMDD TO MM/DD/YYYY.
      *----------------------------------------------------------------
       5990-FORMAT-DATE.
           MOVE SPACES TO WS-DATE-DISP
           STRING WS-DATE-IN(5:2) "/" WS-DATE-IN(7:2) "/"
                  WS-DATE-IN(1:4)
                  DELIMITED BY SIZE INTO WS-DATE-DISP.

      *----------------------------------------------------------------
      * REJECT LISTING
      *----------------------------------------------------------------
      *----------------------------------------------------------------
      * PRINT ONE REJECT LINE.
      *----------------------------------------------------------------
       7000-WRITE-REJECT.
           ADD 1 TO WS-REJ-TOTAL
           MOVE SPACES TO RJ-MSG
           PERFORM VARYING WI FROM 1 BY 1 UNTIL WI > 11
               IF RM-CODE(WI) = WS-REJ-CODE
                   MOVE MESSAGE(WI) TO RJ-MSG
               END-IF
           END-PERFORM
           MOVE WS-REJ-CODE TO RJ-CODE
           MOVE WS-REJ-RECORD(1:60) TO RJ-REC
           WRITE REJ-LINE FROM RJ-DETAIL.

      *----------------------------------------------------------------
      * REJECT LISTING TRAILER.
      *----------------------------------------------------------------
       7900-REJECT-TRAILER.
           MOVE WS-REJ-TOTAL TO WS-ED-COUNT
           MOVE SPACES TO WS-PRINT
           STRING "RECORDS REJECTED: " WS-ED-COUNT
                  DELIMITED BY SIZE INTO WS-PRINT
           WRITE REJ-LINE FROM WS-PRINT.

      *----------------------------------------------------------------
      * CONTROL TOTALS
      *----------------------------------------------------------------
      *----------------------------------------------------------------
      * CONTROL TOTALS PAGE.
      *----------------------------------------------------------------
       8000-WRITE-SUMMARY.
           MOVE SPACES TO WS-PRINT
           STRING "BILLRUN " WS-VERSION " CONTROL TOTALS  RUN "
                  WS-RUN-NO
                  DELIMITED BY SIZE INTO WS-PRINT
           WRITE SUM-LINE FROM WS-PRINT
           MOVE WS-ACCT-READ TO WS-ED-COUNT
           MOVE "ACCOUNT RECORDS READ" TO WS-PRINT
           PERFORM 8100-COUNT-LINE
           MOVE WS-ACCT-REJECTED TO WS-ED-COUNT
           MOVE "ACCOUNT RECORDS REJECTED" TO WS-PRINT
           PERFORM 8100-COUNT-LINE
           MOVE WS-ACT-READ TO WS-ED-COUNT
           MOVE "ACTIVITY RECORDS READ" TO WS-PRINT
           PERFORM 8100-COUNT-LINE
           MOVE WS-ACT-REJECTED TO WS-ED-COUNT
           MOVE "ACTIVITY RECORDS REJECTED" TO WS-PRINT
           PERFORM 8100-COUNT-LINE
           MOVE WS-STMT-COUNT TO WS-ED-COUNT
           MOVE "STATEMENTS WRITTEN" TO WS-PRINT
           PERFORM 8100-COUNT-LINE
           MOVE WT-BASE TO WS-ED-SUM
           MOVE "MONTHLY FEES" TO WS-PRINT
           PERFORM 8200-AMOUNT-LINE
           MOVE WT-USAGE TO WS-ED-SUM
           MOVE "USAGE CHARGES" TO WS-PRINT
           PERFORM 8200-AMOUNT-LINE
           MOVE WT-CHARGES TO WS-ED-SUM
           MOVE "OTHER CHARGES" TO WS-PRINT
           PERFORM 8200-AMOUNT-LINE
           MOVE WT-DISC TO WS-ED-SUM
           MOVE "DISCOUNTS" TO WS-PRINT
           PERFORM 8200-AMOUNT-LINE
           MOVE WT-TAX TO WS-ED-SUM
           MOVE "SALES TAX" TO WS-PRINT
           PERFORM 8200-AMOUNT-LINE
           MOVE WT-ADJ TO WS-ED-SUM
           MOVE "ADJUSTMENTS" TO WS-PRINT
           PERFORM 8200-AMOUNT-LINE
           MOVE WT-PAY TO WS-ED-SUM
           MOVE "PAYMENTS" TO WS-PRINT
           PERFORM 8200-AMOUNT-LINE
           MOVE WT-DUE TO WS-ED-SUM
           MOVE "NET AMOUNT DUE" TO WS-PRINT
           PERFORM 8200-AMOUNT-LINE.

      *----------------------------------------------------------------
      * LABEL + COUNT.
      *----------------------------------------------------------------
       8100-COUNT-LINE.
           MOVE WS-ED-COUNT TO WS-PRINT(28:5)
           WRITE SUM-LINE FROM WS-PRINT
           MOVE SPACES TO WS-PRINT.

      *----------------------------------------------------------------
      * LABEL + AMOUNT.
      *----------------------------------------------------------------
       8200-AMOUNT-LINE.
           MOVE WS-ED-SUM TO WS-PRINT(18:15)
           WRITE SUM-LINE FROM WS-PRINT
           MOVE SPACES TO WS-PRINT.

      *----------------------------------------------------------------
      * CLOSE THE REPORT FILES.
      *----------------------------------------------------------------
       9000-CLOSE.
           CLOSE STMT-FILE
           CLOSE REJ-FILE
           CLOSE SUM-FILE.
