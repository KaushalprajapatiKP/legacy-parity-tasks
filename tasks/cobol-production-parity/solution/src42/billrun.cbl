      *================================================================
      * BILLRUN - MONTHLY BILLING AND STATEMENT BATCH
      * VERSION 4.2
      * COPYRIGHT (C) THE BILLRUN AUTHORS.  MIT LICENSE, SEE LICENSE.
      *
      * INPUT  : CONTROL.DAT  ACCOUNTS.DAT  ACTIVITY.DAT
      * OUTPUT : STATEMENTS.RPT  REJECTS.RPT  SUMMARY.RPT
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
           05  WS-FOUND                PIC X.
           05  WS-AMT-OK               PIC X.
       01  WS-VERSION                  PIC X(3) VALUE "4.2".
       01  WS-RC                       PIC 99 VALUE 0.

       COPY REJMSG.
       01  REJ-COUNTS.
           05  RC-COUNT OCCURS 20 TIMES PIC 9(5).

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
           05  WS-CYC-DAYS             PIC 99.
           05  WS-RUN-NO               PIC X(6).
           05  WS-COMPANY              PIC X(30).

      *    COUNTERS
       01  WS-COUNTERS.
           05  WS-ACCT-READ            PIC 9(5) VALUE 0.
           05  WS-ACCT-ACCEPTED        PIC 9(5) VALUE 0.
           05  WS-ACCT-REJECTED        PIC 9(5) VALUE 0.
           05  WS-ACCT-SKIPPED         PIC 9(5) VALUE 0.
           05  WS-STMT-COUNT           PIC 9(5) VALUE 0.
           05  WS-ACT-READ             PIC 9(5) VALUE 0.
           05  WS-ACT-ACCEPTED         PIC 9(5) VALUE 0.
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
       01  WS-REGION-TOTALS.
           05  WG-COUNT                PIC 99 VALUE 0.
           05  WG-ENTRY OCCURS 50 TIMES.
               10  WG-REGION           PIC XX.
               10  WG-DUE              PIC S9(9)V99.

      *    ACCOUNT TABLE
       01  ACCT-TABLE.
           05  AT-COUNT                PIC 9(4) COMP VALUE 0.
           05  AT-ENTRY OCCURS 500 TIMES.
               10  AT-SORT-KEY.
                   15  AT-REGION       PIC XX.
                   15  AT-ACCT-ID      PIC X(8).
               10  AT-NAME             PIC X(24).
               10  AT-PLAN             PIC X.
               10  AT-OPEN-DATE        PIC 9(8).
               10  AT-CLOSE-DATE       PIC 9(8).
               10  AT-OPEN-DN          PIC 9(9).
               10  AT-CLOSE-DN         PIC 9(9).
               10  AT-TAX-CLASS        PIC X.
               10  AT-PRIOR-BAL        PIC S9(7)V99.
               10  AT-LOYALTY          PIC XX.
               10  AT-STATUS           PIC X.
       01  SORT-TABLE.
           05  ST-COUNT                PIC 9(4) COMP VALUE 0.
           05  ST-IX OCCURS 500 TIMES  PIC 9(4) COMP.

      *    ACTIVITY TABLE (ACCEPTED RECORDS)
       01  ACT-TABLE.
           05  XT-COUNT                PIC 9(4) COMP VALUE 0.
           05  XT-ENTRY OCCURS 3000 TIMES.
               10  XT-TYPE             PIC XX.
               10  XT-ACCT-IX          PIC 9(4) COMP.
               10  XT-DATE             PIC 9(8).
               10  XT-DAYNUM           PIC 9(9).
               10  XT-CODE             PIC X(4).
               10  XT-QTY              PIC 9(7)V99.
               10  XT-AMOUNT           PIC S9(7)V99.
               10  XT-DESC             PIC X(20).
               10  XT-DATE2-DN         PIC 9(9).
               10  XT-RAW              PIC X(80).

      *    PER-ACCOUNT WORK LIST (ACTIVITY INDEXES IN DATE ORDER)
       01  WS-LIST.
           05  WL-COUNT                PIC 9(4) COMP.
           05  WL-IX OCCURS 3000 TIMES PIC 9(4) COMP.
       01  WS-CPN-LIST.
           05  WC-IX OCCURS 20 TIMES   PIC 9(4) COMP.

       01  WS-INDEXES.
           05  WI                      PIC 9(4) COMP.
           05  WJ                      PIC 9(4) COMP.
           05  WK                      PIC 9(4) COMP.
           05  WT                      PIC 9(4) COMP.
           05  WX                      PIC 9(4) COMP.
           05  WA                      PIC 9(4) COMP.
           05  WD                      PIC 9(4) COMP.
           05  WD2                     PIC 9(4) COMP.
           05  WP                      PIC 9(4) COMP.

       01  WS-WORK.
           05  WS-AMT-X                PIC X(10).
           05  WS-AMT-N REDEFINES WS-AMT-X
                                       PIC S9(7)V99
                                       SIGN LEADING SEPARATE.
           05  WS-AMOUNT               PIC S9(7)V99.
           05  WS-DN                   PIC 9(9).
           05  WS-DN2                  PIC 9(9).
           05  WS-OPEN-DN              PIC 9(9).
           05  WS-CLOSE-N              PIC 9(8).
           05  WS-CLOSE-DN             PIC 9(9).
           05  WS-KEY-A                PIC X(10).
           05  WS-KEY-B                PIC X(10).
           05  WS-DATE-A               PIC 9(8).
           05  WS-DATE-B               PIC 9(8).

       01  WS-REJECT.
           05  WS-REJ-CODE             PIC X(3).
           05  WS-REJ-SRC              PIC X(3).
           05  WS-REJ-SEQ              PIC 9(6).
           05  WS-REJ-RECORD           PIC X(80).
           05  WS-ACCT-SEQ             PIC 9(6) VALUE 0.
           05  WS-ACT-SEQ              PIC 9(6) VALUE 0.

      *    PER-ACCOUNT BILLING WORK AREA
       01  WS-BILL.
           05  WB-AX                   PIC 9(4) COMP.
           05  WB-BASE                 PIC S9(7)V99.
           05  WB-USAGE                PIC S9(7)V99.
           05  WB-CHARGES              PIC S9(7)V99.
           05  WB-DEPO                 PIC S9(7)V99.
           05  WB-LATE                 PIC S9(7)V99.
           05  WB-LATE-ADJ             PIC S9(7)V99.
           05  WB-DISCOUNTABLE         PIC S9(7)V99.
           05  WB-DISC                 PIC S9(7)V99.
           05  WB-SUBTOTAL             PIC S9(7)V99.
           05  WB-TAXABLE              PIC S9(7)V99.
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
           05  WB-ROAM-AMT             PIC S9(7)V99.
           05  WB-HAS-DATA             PIC X.
           05  WB-HAS-VOIC             PIC X.
           05  WB-HAS-SMS              PIC X.
           05  WB-HAS-ROAM             PIC X.

      *    REPORT LINES
       01  WS-RULE-EQ                  PIC X(72) VALUE ALL "=".
       01  WS-RULE-DASH                PIC X(72) VALUE ALL "-".
       01  WS-PRINT                    PIC X(100).
       01  WS-DATE-DISP                PIC X(10).
       01  WS-DATE-DISP2               PIC X(10).
       01  WS-DATE-IN                  PIC 9(8).
       01  WS-ED-COUNT                 PIC ZZZZ9.
       01  WS-ED-DAYS                  PIC Z9.
       01  WS-ED-PCT                   PIC Z9.99.
       01  WS-ED-SUM                   PIC --,---,---,--9.99.

       01  WP-PARMS.
           05  WP-DATE                 PIC 9(8).
           05  WP-DESC                 PIC X(30).
           05  WP-HAS-QTY              PIC X.
           05  WP-QTY                  PIC 9(7)V99.
           05  WP-AMT                  PIC S9(7)V99.

       01  DL-LINE.
           05  DL-DATE                 PIC X(10).
           05  FILLER                  PIC X VALUE SPACE.
           05  DL-DESC                 PIC X(30).
           05  FILLER                  PIC X VALUE SPACE.
           05  DL-QTY                  PIC ZZZ,ZZ9.99.
           05  DL-QTY-X REDEFINES DL-QTY
                                       PIC X(10).
           05  FILLER                  PIC X(2) VALUE SPACES.
           05  DL-AMT                  PIC Z,ZZZ,ZZ9.99CR.

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
       0000-MAIN.
           PERFORM 1000-INIT
           PERFORM 1100-READ-CONTROL
           IF WS-CTL-OK = "N"
               PERFORM 1900-CONTROL-FAIL
           ELSE
               PERFORM 2000-LOAD-ACCOUNTS
               PERFORM 3000-LOAD-ACTIVITY
               PERFORM 4000-SORT-ACCOUNTS
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

      *----------------------------------------------------------------
       1000-INIT.
           OPEN OUTPUT STMT-FILE
           OPEN OUTPUT REJ-FILE
           OPEN OUTPUT SUM-FILE
           PERFORM VARYING WI FROM 1 BY 1 UNTIL WI > 20
               MOVE 0 TO RC-COUNT(WI)
           END-PERFORM.

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
               IF WS-CYC-END-DN < WS-CYC-START-DN
                   MOVE "N" TO WS-CTL-OK
               ELSE
                   IF WS-CYC-END-DN - WS-CYC-START-DN > 30
                       MOVE "N" TO WS-CTL-OK
                   ELSE
                       COMPUTE WS-CYC-DAYS =
                           WS-CYC-END-DN - WS-CYC-START-DN + 1
                   END-IF
               END-IF
           END-IF.

       1200-REJECT-HEADER.
           MOVE SPACES TO WS-PRINT
           STRING "BILLRUN " WS-VERSION " REJECT REPORT"
                  "          RUN " WS-RUN-NO
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
           STRING "BILLRUN " WS-VERSION " RUN SUMMARY"
                  "          RUN " WS-RUN-NO
                  DELIMITED BY SIZE INTO WS-PRINT
           WRITE SUM-LINE FROM WS-PRINT
           MOVE "RUN ABORTED - INVALID CONTROL RECORD" TO SUM-LINE
           WRITE SUM-LINE
           MOVE 16 TO WS-RC.

      *----------------------------------------------------------------
      * ACCOUNT MASTER LOAD AND VALIDATION
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
                       ADD 1 TO WS-ACCT-SEQ
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
               MOVE "N" TO WS-FOUND
               PERFORM VARYING WI FROM 1 BY 1 UNTIL WI > AT-COUNT
                   IF AT-ACCT-ID(WI) = AR-ACCT-ID
                       MOVE "Y" TO WS-FOUND
                   END-IF
               END-PERFORM
               IF WS-FOUND = "Y"
                   MOVE "A02" TO WS-REJ-CODE
               END-IF
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
                   MOVE DU-DAYNUM TO WS-OPEN-DN
               END-IF
           END-IF
           IF WS-REJ-CODE = SPACES
               IF AR-CLOSE-DATE = SPACES OR AR-CLOSE-DATE = "00000000"
                   MOVE 0 TO WS-CLOSE-N
                   MOVE 0 TO WS-CLOSE-DN
               ELSE
                   MOVE AR-CLOSE-DATE TO DU-DATE
                   CALL "DATEUTIL" USING DU-PARMS
                   IF DU-VALID NOT = "Y"
                       MOVE "A05" TO WS-REJ-CODE
                   ELSE
                       IF DU-DAYNUM < WS-OPEN-DN
                           MOVE "A05" TO WS-REJ-CODE
                       ELSE
                           MOVE DU-DATE-N TO WS-CLOSE-N
                           MOVE DU-DAYNUM TO WS-CLOSE-DN
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
               IF (AR-BAL-SIGN NOT = "+" AND AR-BAL-SIGN NOT = "-")
                  OR AR-BAL-DIGITS IS NOT NUMERIC
                   MOVE "A07" TO WS-REJ-CODE
               END-IF
           END-IF
           IF WS-REJ-CODE NOT = SPACES
               ADD 1 TO WS-ACCT-REJECTED
               MOVE "ACC" TO WS-REJ-SRC
               MOVE WS-ACCT-SEQ TO WS-REJ-SEQ
               MOVE ACCT-RECORD TO WS-REJ-RECORD
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
           MOVE AR-OPEN-DATE TO AT-OPEN-DATE(WA)
           MOVE WS-OPEN-DN TO AT-OPEN-DN(WA)
           MOVE WS-CLOSE-N TO AT-CLOSE-DATE(WA)
           MOVE WS-CLOSE-DN TO AT-CLOSE-DN(WA)
           MOVE AR-TAX-CLASS TO AT-TAX-CLASS(WA)
           MOVE AR-REGION TO AT-REGION(WA)
           MOVE AR-PRIOR-BAL-N TO AT-PRIOR-BAL(WA)
           MOVE AR-LOYALTY TO AT-LOYALTY(WA)
           MOVE "A" TO AT-STATUS(WA)
           IF WS-OPEN-DN > WS-CYC-END-DN
               MOVE "S" TO AT-STATUS(WA)
           END-IF
           IF WS-CLOSE-DN NOT = 0 AND WS-CLOSE-DN < WS-CYC-START-DN
               MOVE "S" TO AT-STATUS(WA)
           END-IF
           IF AT-STATUS(WA) = "S"
               ADD 1 TO WS-ACCT-SKIPPED
           ELSE
               ADD 1 TO WS-ACCT-ACCEPTED
           END-IF.

      *----------------------------------------------------------------
      * ACTIVITY LOAD AND VALIDATION
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
                       ADD 1 TO WS-ACT-SEQ
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
               ELSE
                   MOVE DU-DAYNUM TO WS-DN
               END-IF
           END-IF
           IF WS-REJ-CODE = SPACES
               IF WS-DN < WS-CYC-START-DN OR WS-DN > WS-CYC-END-DN
                   MOVE "R04" TO WS-REJ-CODE
               END-IF
           END-IF
           IF WS-REJ-CODE = SPACES
               IF WS-DN < AT-OPEN-DN(WA)
                   MOVE "R08" TO WS-REJ-CODE
               END-IF
               IF AT-CLOSE-DN(WA) NOT = 0
                  AND WS-DN > AT-CLOSE-DN(WA)
                   MOVE "R08" TO WS-REJ-CODE
               END-IF
           END-IF
           IF WS-REJ-CODE = SPACES
               EVALUATE XR-TYPE
                   WHEN "US"  PERFORM 3200-CHECK-USAGE
                   WHEN "CH"  PERFORM 3300-CHECK-CHARGE
                   WHEN "PC"  PERFORM 3400-CHECK-PLAN-CHANGE
                   WHEN "PY"  PERFORM 3500-CHECK-PAYMENT
                   WHEN "AD"  PERFORM 3600-CHECK-ADJUSTMENT
                   WHEN "DS"  PERFORM 3700-CHECK-COUPON
                   WHEN "SU"  PERFORM 3800-CHECK-SUSPENSION
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
               MOVE "ACT" TO WS-REJ-SRC
               MOVE WS-ACT-SEQ TO WS-REJ-SEQ
               MOVE ACT-RECORD TO WS-REJ-RECORD
               PERFORM 7000-WRITE-REJECT
           ELSE
               PERFORM 3900-STORE-ACTIVITY
           END-IF.

       3150-PARSE-AMOUNT.
           MOVE "Y" TO WS-AMT-OK
           MOVE 0 TO WS-AMOUNT
           IF WS-AMT-X(1:1) NOT = "+" AND WS-AMT-X(1:1) NOT = "-"
               MOVE "N" TO WS-AMT-OK
           END-IF
           IF WS-AMT-X(2:9) IS NOT NUMERIC
               MOVE "N" TO WS-AMT-OK
           END-IF
           IF WS-AMT-OK = "Y"
               MOVE WS-AMT-N TO WS-AMOUNT
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
               MOVE XR-CH-AMOUNT TO WS-AMT-X
               PERFORM 3150-PARSE-AMOUNT
               IF WS-AMT-OK NOT = "Y"
                   MOVE "R05" TO WS-REJ-CODE
               END-IF
           END-IF.

       3400-CHECK-PLAN-CHANGE.
           IF XR-PC-PLAN NOT = "B" AND XR-PC-PLAN NOT = "S"
              AND XR-PC-PLAN NOT = "P"
               MOVE "R09" TO WS-REJ-CODE
           END-IF.

       3500-CHECK-PAYMENT.
           MOVE XR-CH-AMOUNT TO WS-AMT-X
           PERFORM 3150-PARSE-AMOUNT
           IF WS-AMT-OK NOT = "Y"
               MOVE "R05" TO WS-REJ-CODE
           ELSE
               IF WS-AMOUNT NOT > 0
                   MOVE "R10" TO WS-REJ-CODE
               END-IF
           END-IF.

       3600-CHECK-ADJUSTMENT.
           MOVE XR-CH-AMOUNT TO WS-AMT-X
           PERFORM 3150-PARSE-AMOUNT
           IF WS-AMT-OK NOT = "Y"
               MOVE "R05" TO WS-REJ-CODE
           END-IF.

       3700-CHECK-COUPON.
           IF XR-DS-KIND NOT = "P" AND XR-DS-KIND NOT = "F"
               MOVE "R11" TO WS-REJ-CODE
           ELSE
               MOVE XR-DS-VALUE TO WS-AMT-X
               PERFORM 3150-PARSE-AMOUNT
               IF WS-AMT-OK NOT = "Y"
                   MOVE "R05" TO WS-REJ-CODE
               ELSE
                   IF WS-AMOUNT NOT > 0
                       MOVE "R11" TO WS-REJ-CODE
                   END-IF
                   IF XR-DS-KIND = "P" AND WS-AMOUNT > 100
                       MOVE "R11" TO WS-REJ-CODE
                   END-IF
               END-IF
           END-IF.

       3800-CHECK-SUSPENSION.
           MOVE XR-SU-END TO DU-DATE
           CALL "DATEUTIL" USING DU-PARMS
           IF DU-VALID NOT = "Y"
               MOVE "R12" TO WS-REJ-CODE
           ELSE
               IF DU-DAYNUM < WS-DN
                   MOVE "R12" TO WS-REJ-CODE
               ELSE
                   MOVE DU-DAYNUM TO WS-DN2
               END-IF
           END-IF.

       3900-STORE-ACTIVITY.
           ADD 1 TO WS-ACT-ACCEPTED
           ADD 1 TO XT-COUNT
           MOVE XT-COUNT TO WX
           MOVE XR-TYPE TO XT-TYPE(WX)
           MOVE WA TO XT-ACCT-IX(WX)
           MOVE XR-DATE TO XT-DATE(WX)
           MOVE WS-DN TO XT-DAYNUM(WX)
           MOVE SPACES TO XT-CODE(WX) XT-DESC(WX)
           MOVE 0 TO XT-QTY(WX) XT-AMOUNT(WX) XT-DATE2-DN(WX)
           MOVE ACT-RECORD TO XT-RAW(WX)
           EVALUATE XR-TYPE
               WHEN "US"
                   MOVE XR-US-SERVICE TO XT-CODE(WX)
                   MOVE XR-US-QTY-N TO XT-QTY(WX)
               WHEN "CH"
                   MOVE XR-CH-CODE TO XT-CODE(WX)
                   MOVE WS-AMOUNT TO XT-AMOUNT(WX)
                   MOVE XR-CH-DESC TO XT-DESC(WX)
               WHEN "PC"
                   MOVE XR-PC-PLAN TO XT-CODE(WX)
               WHEN "PY"
                   MOVE WS-AMOUNT TO XT-AMOUNT(WX)
               WHEN "AD"
                   MOVE WS-AMOUNT TO XT-AMOUNT(WX)
                   MOVE XR-CH-DESC TO XT-DESC(WX)
               WHEN "DS"
                   MOVE XR-DS-KIND TO XT-CODE(WX)
                   MOVE WS-AMOUNT TO XT-AMOUNT(WX)
               WHEN "SU"
                   MOVE WS-DN2 TO XT-DATE2-DN(WX)
           END-EVALUATE.

      *----------------------------------------------------------------
      * ORDER STATEMENTS BY REGION THEN ACCOUNT ID
      *----------------------------------------------------------------
       4000-SORT-ACCOUNTS.
           MOVE 0 TO ST-COUNT
           PERFORM VARYING WI FROM 1 BY 1 UNTIL WI > AT-COUNT
               IF AT-STATUS(WI) = "A"
                   ADD 1 TO ST-COUNT
                   MOVE WI TO ST-IX(ST-COUNT)
               END-IF
           END-PERFORM
           PERFORM VARYING WI FROM 2 BY 1 UNTIL WI > ST-COUNT
               MOVE ST-IX(WI) TO WT
               MOVE AT-SORT-KEY(WT) TO WS-KEY-B
               MOVE WI TO WJ
               PERFORM UNTIL WJ < 2
                   MOVE ST-IX(WJ - 1) TO WK
                   MOVE AT-SORT-KEY(WK) TO WS-KEY-A
                   IF WS-KEY-A > WS-KEY-B
                       MOVE WK TO ST-IX(WJ)
                       SUBTRACT 1 FROM WJ
                   ELSE
                       EXIT PERFORM
                   END-IF
               END-PERFORM
               MOVE WT TO ST-IX(WJ)
           END-PERFORM.

      *----------------------------------------------------------------
      * STATEMENT PRODUCTION
      *----------------------------------------------------------------
       5000-PRODUCE-STATEMENTS.
           PERFORM VARYING WP FROM 1 BY 1 UNTIL WP > ST-COUNT
               MOVE ST-IX(WP) TO WB-AX
               PERFORM 5100-BILL-ACCOUNT
           END-PERFORM.

       5100-BILL-ACCOUNT.
           ADD 1 TO WS-STMT-COUNT
           MOVE 0 TO WB-BASE WB-USAGE WB-CHARGES WB-DEPO WB-LATE
                     WB-LATE-ADJ WB-DISCOUNTABLE WB-DISC WB-SUBTOTAL
                     WB-TAXABLE WB-TAX WB-ADJ WB-CURRENT WB-PAY WB-DUE
                     WB-DATA-QTY WB-VOIC-QTY WB-SMS-QTY WB-ROAM-QTY
                     WB-ROAM-AMT
           MOVE "N" TO WB-HAS-DATA WB-HAS-VOIC WB-HAS-SMS WB-HAS-ROAM
           PERFORM 5200-BUILD-LIST
           PERFORM 5300-BUILD-DAYS
           PERFORM 5400-STATEMENT-HEADER
           IF WL-COUNT = 0
               MOVE 0 TO WP-DATE
               MOVE "NO ACTIVITY THIS PERIOD" TO WP-DESC
               PERFORM 5950-PUT-TEXT
           END-IF
           PERFORM 5500-BASE-FEES
           PERFORM 5600-USAGE
           PERFORM 5700-CHARGES
           PERFORM 5750-DISCOUNTS
           PERFORM 5800-TOTALS.

       5200-BUILD-LIST.
           MOVE 0 TO WL-COUNT
           PERFORM VARYING WI FROM 1 BY 1 UNTIL WI > XT-COUNT
               IF XT-ACCT-IX(WI) = WB-AX
                   ADD 1 TO WL-COUNT
                   MOVE WI TO WL-IX(WL-COUNT)
               END-IF
           END-PERFORM
           PERFORM VARYING WI FROM 2 BY 1 UNTIL WI > WL-COUNT
               MOVE WL-IX(WI) TO WT
               MOVE XT-DATE(WT) TO WS-DATE-B
               MOVE WI TO WJ
               PERFORM UNTIL WJ < 2
                   MOVE WL-IX(WJ - 1) TO WK
                   MOVE XT-DATE(WK) TO WS-DATE-A
                   IF WS-DATE-A > WS-DATE-B
                       MOVE WK TO WL-IX(WJ)
                       SUBTRACT 1 FROM WJ
                   ELSE
                       EXIT PERFORM
                   END-IF
               END-PERFORM
               MOVE WT TO WL-IX(WJ)
           END-PERFORM.

       5300-BUILD-DAYS.
           MOVE WS-CYC-DAYS TO PR-CYCLE-DAYS
           PERFORM VARYING WD FROM 1 BY 1 UNTIL WD > 31
               MOVE SPACE TO PR-DAY-PLAN(WD)
               MOVE "N" TO PR-DAY-SUSP(WD)
           END-PERFORM
           PERFORM VARYING WD FROM 1 BY 1 UNTIL WD > WS-CYC-DAYS
               COMPUTE WS-DN = WS-CYC-START-DN + WD - 1
               IF WS-DN NOT < AT-OPEN-DN(WB-AX)
                  AND (AT-CLOSE-DN(WB-AX) = 0
                       OR WS-DN NOT > AT-CLOSE-DN(WB-AX))
                   MOVE AT-PLAN(WB-AX) TO PR-DAY-PLAN(WD)
               END-IF
           END-PERFORM
           PERFORM VARYING WI FROM 1 BY 1 UNTIL WI > WL-COUNT
               MOVE WL-IX(WI) TO WX
               IF XT-TYPE(WX) = "PC"
                   COMPUTE WD2 = XT-DAYNUM(WX) - WS-CYC-START-DN + 1
                   PERFORM VARYING WD FROM WD2 BY 1
                           UNTIL WD > WS-CYC-DAYS
                       IF PR-DAY-PLAN(WD) NOT = SPACE
                           MOVE XT-CODE(WX)(1:1) TO PR-DAY-PLAN(WD)
                       END-IF
                   END-PERFORM
               END-IF
               IF XT-TYPE(WX) = "SU"
                   COMPUTE WD2 = XT-DAYNUM(WX) - WS-CYC-START-DN + 1
                   PERFORM VARYING WD FROM WD2 BY 1
                           UNTIL WD > WS-CYC-DAYS
                       COMPUTE WS-DN = WS-CYC-START-DN + WD - 1
                       IF WS-DN NOT > XT-DATE2-DN(WX)
                          AND PR-DAY-PLAN(WD) NOT = SPACE
                           MOVE "Y" TO PR-DAY-SUSP(WD)
                       END-IF
                   END-PERFORM
               END-IF
           END-PERFORM
           MOVE AT-PLAN(WB-AX) TO WB-FINAL-PLAN
           PERFORM VARYING WD FROM 1 BY 1 UNTIL WD > WS-CYC-DAYS
               IF PR-DAY-PLAN(WD) NOT = SPACE
                   MOVE PR-DAY-PLAN(WD) TO WB-FINAL-PLAN
               END-IF
           END-PERFORM.

       5400-STATEMENT-HEADER.
           WRITE STMT-LINE FROM WS-RULE-EQ
           MOVE SPACES TO WS-PRINT
           STRING WS-COMPANY "  BILLING STATEMENT  RUN " WS-RUN-NO
                  DELIMITED BY SIZE INTO WS-PRINT
           WRITE STMT-LINE FROM WS-PRINT
           MOVE SPACES TO WS-PRINT
           STRING "ACCOUNT " AT-ACCT-ID(WB-AX) "  "
                  AT-NAME(WB-AX) "  REGION " AT-REGION(WB-AX)
                  DELIMITED BY SIZE INTO WS-PRINT
           WRITE STMT-LINE FROM WS-PRINT
           MOVE SPACES TO WS-PRINT
           MOVE WS-CYC-START TO WS-DATE-IN
           PERFORM 5990-FORMAT-DATE
           MOVE WS-DATE-DISP TO WS-DATE-DISP2
           MOVE WS-CYC-END TO WS-DATE-IN
           PERFORM 5990-FORMAT-DATE
           MOVE WS-CYC-DAYS TO WS-ED-DAYS
           STRING "PERIOD " WS-DATE-DISP2 " TO " WS-DATE-DISP
                  "  DAYS " WS-ED-DAYS "  PLAN " WB-FINAL-PLAN
                  DELIMITED BY SIZE INTO WS-PRINT
           WRITE STMT-LINE FROM WS-PRINT
           WRITE STMT-LINE FROM WS-RULE-DASH
           MOVE SPACES TO WS-PRINT
           STRING "DATE       DESCRIPTION                    "
                  "        QTY          AMOUNT"
                  DELIMITED BY SIZE INTO WS-PRINT
           WRITE STMT-LINE FROM WS-PRINT
           WRITE STMT-LINE FROM WS-RULE-DASH.

       5500-BASE-FEES.
           CALL "PRORATE" USING PR-PARMS
           PERFORM VARYING WI FROM 1 BY 1 UNTIL WI > PR-SEG-COUNT
               COMPUTE WP-DATE = FUNCTION DATE-OF-INTEGER
                   (WS-CYC-START-DN + PR-SEG-START(WI) - 1)
               MOVE SPACES TO WP-DESC
               STRING "BASE FEE PLAN " PR-SEG-PLAN(WI)
                      DELIMITED BY SIZE INTO WP-DESC
               MOVE "Y" TO WP-HAS-QTY
               MOVE PR-SEG-DAYS(WI) TO WP-QTY
               MOVE PR-SEG-AMOUNT(WI) TO WP-AMT
               PERFORM 5900-PUT-LINE
           END-PERFORM
           MOVE PR-TOTAL TO WB-BASE.

       5600-USAGE.
           PERFORM VARYING WI FROM 1 BY 1 UNTIL WI > WL-COUNT
               MOVE WL-IX(WI) TO WX
               IF XT-TYPE(WX) = "US"
                   MOVE XT-QTY(WX) TO RC-QTY
                   MOVE WB-FINAL-PLAN TO RC-PLAN
                   EVALUATE XT-CODE(WX)
                       WHEN "DATA"
                           MOVE "Y" TO WB-HAS-DATA
                           ADD XT-QTY(WX) TO WB-DATA-QTY
                       WHEN "VOIC"
                           MOVE "Y" TO WB-HAS-VOIC
                           MOVE "M" TO RC-FUNC
                           CALL "RATECALC" USING RC-PARMS
                           ADD RC-BILL-QTY TO WB-VOIC-QTY
                       WHEN "SMS "
                           MOVE "Y" TO WB-HAS-SMS
                           MOVE "N" TO RC-FUNC
                           CALL "RATECALC" USING RC-PARMS
                           ADD RC-BILL-QTY TO WB-SMS-QTY
                       WHEN "ROAM"
                           MOVE "Y" TO WB-HAS-ROAM
                           MOVE "R" TO RC-FUNC
                           CALL "RATECALC" USING RC-PARMS
                           ADD RC-QTY TO WB-ROAM-QTY
                           ADD RC-AMOUNT TO WB-ROAM-AMT
                   END-EVALUATE
               END-IF
           END-PERFORM
           MOVE 0 TO WP-DATE
           MOVE "Y" TO WP-HAS-QTY
           MOVE WB-FINAL-PLAN TO RC-PLAN
           IF WB-HAS-DATA = "Y"
               MOVE "D" TO RC-FUNC
               MOVE WB-DATA-QTY TO RC-QTY
               CALL "RATECALC" USING RC-PARMS
               MOVE "USAGE DATA GB" TO WP-DESC
               MOVE WB-DATA-QTY TO WP-QTY
               MOVE RC-AMOUNT TO WP-AMT
               ADD RC-AMOUNT TO WB-USAGE
               PERFORM 5900-PUT-LINE
           END-IF
           IF WB-HAS-VOIC = "Y"
               MOVE "V" TO RC-FUNC
               MOVE WB-VOIC-QTY TO RC-QTY
               CALL "RATECALC" USING RC-PARMS
               MOVE "USAGE VOICE MIN" TO WP-DESC
               MOVE WB-VOIC-QTY TO WP-QTY
               MOVE RC-AMOUNT TO WP-AMT
               ADD RC-AMOUNT TO WB-USAGE
               PERFORM 5900-PUT-LINE
           END-IF
           IF WB-HAS-SMS = "Y"
               MOVE "S" TO RC-FUNC
               MOVE WB-SMS-QTY TO RC-QTY
               CALL "RATECALC" USING RC-PARMS
               MOVE "USAGE SMS MSG" TO WP-DESC
               MOVE WB-SMS-QTY TO WP-QTY
               MOVE RC-AMOUNT TO WP-AMT
               ADD RC-AMOUNT TO WB-USAGE
               PERFORM 5900-PUT-LINE
           END-IF
           IF WB-HAS-ROAM = "Y"
               MOVE "USAGE ROAMING MB" TO WP-DESC
               MOVE WB-ROAM-QTY TO WP-QTY
               MOVE WB-ROAM-AMT TO WP-AMT
               ADD WB-ROAM-AMT TO WB-USAGE
               PERFORM 5900-PUT-LINE
           END-IF.

       5700-CHARGES.
           MOVE "N" TO WP-HAS-QTY
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
                   IF XT-CODE(WX) = "LATE"
                       ADD XT-AMOUNT(WX) TO WB-LATE
                   END-IF
                   IF XT-CODE(WX) = "DEPO"
                       ADD XT-AMOUNT(WX) TO WB-DEPO
                   END-IF
               END-IF
           END-PERFORM
           IF WB-LATE > 15.00
               COMPUTE WB-LATE-ADJ = 15.00 - WB-LATE
               MOVE 0 TO WP-DATE
               MOVE "LATE FEE CAP" TO WP-DESC
               MOVE WB-LATE-ADJ TO WP-AMT
               PERFORM 5900-PUT-LINE
               ADD WB-LATE-ADJ TO WB-CHARGES
           END-IF.

       5750-DISCOUNTS.
           COMPUTE WB-DISCOUNTABLE = WB-BASE + WB-USAGE
                                   + WB-CHARGES - WB-DEPO
           MOVE WB-BASE TO DS-BASE
           MOVE WB-DISCOUNTABLE TO DS-DISCOUNTABLE
           MOVE AT-LOYALTY(WB-AX) TO DS-LOYALTY-CODE
           MOVE 0 TO DS-CPN-COUNT
           PERFORM VARYING WI FROM 1 BY 1 UNTIL WI > WL-COUNT
               MOVE WL-IX(WI) TO WX
               IF XT-TYPE(WX) = "DS" AND DS-CPN-COUNT < 20
                   ADD 1 TO DS-CPN-COUNT
                   MOVE XT-CODE(WX)(1:1) TO DS-CPN-KIND(DS-CPN-COUNT)
                   MOVE XT-AMOUNT(WX) TO DS-CPN-VALUE(DS-CPN-COUNT)
                   MOVE WX TO WC-IX(DS-CPN-COUNT)
               END-IF
           END-PERFORM
           CALL "DISCOUNT" USING DS-PARMS
           MOVE "N" TO WP-HAS-QTY
           MOVE 0 TO WP-DATE
           IF DS-LOYALTY-AMT NOT = 0
               MOVE SPACES TO WP-DESC
               MOVE DS-LOYALTY-PCT TO WS-ED-DAYS
               STRING "LOYALTY DISCOUNT " DS-LOYALTY-CODE " "
                      WS-ED-DAYS "%"
                      DELIMITED BY SIZE INTO WP-DESC
               COMPUTE WP-AMT = 0 - DS-LOYALTY-AMT
               PERFORM 5900-PUT-LINE
           END-IF
           PERFORM VARYING WI FROM 1 BY 1 UNTIL WI > DS-CPN-COUNT
               MOVE DS-CPN-ORDER(WI) TO WK
               MOVE WC-IX(WK) TO WX
               MOVE XT-DATE(WX) TO WP-DATE
               MOVE SPACES TO WP-DESC
               IF DS-CPN-KIND(WK) = "F"
                   MOVE "COUPON FIXED" TO WP-DESC
               ELSE
                   MOVE DS-CPN-VALUE(WK) TO WS-ED-PCT
                   STRING "COUPON " WS-ED-PCT "%"
                          DELIMITED BY SIZE INTO WP-DESC
               END-IF
               COMPUTE WP-AMT = 0 - DS-CPN-AMT(WK)
               PERFORM 5900-PUT-LINE
           END-PERFORM
           IF DS-CAP-AMT NOT = 0
               MOVE 0 TO WP-DATE
               MOVE "DISCOUNT CAP" TO WP-DESC
               MOVE DS-CAP-AMT TO WP-AMT
               PERFORM 5900-PUT-LINE
           END-IF
           MOVE DS-TOTAL TO WB-DISC.

       5800-TOTALS.
           MOVE 0 TO WP-DATE
           MOVE "N" TO WP-HAS-QTY
           COMPUTE WB-SUBTOTAL = WB-BASE + WB-USAGE + WB-CHARGES
                               - WB-DISC
           MOVE "SUBTOTAL" TO WP-DESC
           MOVE WB-SUBTOTAL TO WP-AMT
           PERFORM 5900-PUT-LINE
           COMPUTE WB-TAXABLE = WB-SUBTOTAL - WB-DEPO
           MOVE AT-TAX-CLASS(WB-AX) TO TX-CLASS
           MOVE WB-TAXABLE TO TX-TAXABLE
           CALL "TAXCALC" USING TX-PARMS
           MOVE TX-AMOUNT TO WB-TAX
           MOVE SPACES TO WP-DESC
           STRING "TAX " TX-CLASS " " TX-RATE-DISP
                  DELIMITED BY SIZE INTO WP-DESC
           MOVE WB-TAX TO WP-AMT
           PERFORM 5900-PUT-LINE
           PERFORM VARYING WI FROM 1 BY 1 UNTIL WI > WL-COUNT
               MOVE WL-IX(WI) TO WX
               IF XT-TYPE(WX) = "AD"
                   MOVE XT-DATE(WX) TO WP-DATE
                   MOVE SPACES TO WP-DESC
                   STRING "ADJ " XT-DESC(WX)
                          DELIMITED BY SIZE INTO WP-DESC
                   MOVE XT-AMOUNT(WX) TO WP-AMT
                   PERFORM 5900-PUT-LINE
                   ADD XT-AMOUNT(WX) TO WB-ADJ
               END-IF
           END-PERFORM
           MOVE 0 TO WP-DATE
           COMPUTE WB-CURRENT = WB-SUBTOTAL + WB-TAX + WB-ADJ
           MOVE "CURRENT CHARGES" TO WP-DESC
           MOVE WB-CURRENT TO WP-AMT
           PERFORM 5900-PUT-LINE
           MOVE "PRIOR BALANCE" TO WP-DESC
           MOVE AT-PRIOR-BAL(WB-AX) TO WP-AMT
           PERFORM 5900-PUT-LINE
           PERFORM VARYING WI FROM 1 BY 1 UNTIL WI > WL-COUNT
               MOVE WL-IX(WI) TO WX
               IF XT-TYPE(WX) = "PY"
                   MOVE XT-DATE(WX) TO WP-DATE
                   MOVE "PAYMENT RECEIVED" TO WP-DESC
                   COMPUTE WP-AMT = 0 - XT-AMOUNT(WX)
                   PERFORM 5900-PUT-LINE
                   ADD XT-AMOUNT(WX) TO WB-PAY
               END-IF
           END-PERFORM
           MOVE 0 TO WP-DATE
           COMPUTE WB-DUE = AT-PRIOR-BAL(WB-AX) + WB-CURRENT - WB-PAY
           WRITE STMT-LINE FROM WS-RULE-DASH
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
           PERFORM 5850-REGION-TOTAL.

       5850-REGION-TOTAL.
           MOVE 0 TO WK
           PERFORM VARYING WI FROM 1 BY 1 UNTIL WI > WG-COUNT
               IF WG-REGION(WI) = AT-REGION(WB-AX)
                   MOVE WI TO WK
               END-IF
           END-PERFORM
           IF WK = 0 AND WG-COUNT < 50
               ADD 1 TO WG-COUNT
               MOVE WG-COUNT TO WK
               MOVE AT-REGION(WB-AX) TO WG-REGION(WK)
               MOVE 0 TO WG-DUE(WK)
           END-IF
           IF WK > 0
               ADD WB-DUE TO WG-DUE(WK)
           END-IF.

       5900-PUT-LINE.
           MOVE SPACES TO DL-DATE
           IF WP-DATE NOT = 0
               MOVE WP-DATE TO WS-DATE-IN
               PERFORM 5990-FORMAT-DATE
               MOVE WS-DATE-DISP TO DL-DATE
           END-IF
           MOVE WP-DESC TO DL-DESC
           IF WP-HAS-QTY = "Y"
               MOVE WP-QTY TO DL-QTY
           ELSE
               MOVE SPACES TO DL-QTY-X
           END-IF
           MOVE WP-AMT TO DL-AMT
           WRITE STMT-LINE FROM DL-LINE.

       5950-PUT-TEXT.
           MOVE SPACES TO DL-LINE
           MOVE WP-DESC TO DL-DESC
           WRITE STMT-LINE FROM DL-LINE.

       5990-FORMAT-DATE.
           MOVE SPACES TO WS-DATE-DISP
           STRING WS-DATE-IN(1:4) "-" WS-DATE-IN(5:2) "-"
                  WS-DATE-IN(7:2)
                  DELIMITED BY SIZE INTO WS-DATE-DISP.

      *----------------------------------------------------------------
      * REJECT REPORT
      *----------------------------------------------------------------
       7000-WRITE-REJECT.
           ADD 1 TO WS-REJ-TOTAL
           MOVE SPACES TO RJ-MSG
           PERFORM VARYING WI FROM 1 BY 1 UNTIL WI > 20
               IF RM-CODE(WI) = WS-REJ-CODE
                   MOVE RM-TEXT(WI) TO RJ-MSG
                   ADD 1 TO RC-COUNT(WI)
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
           STRING "BILLRUN " WS-VERSION " RUN SUMMARY"
                  "          RUN " WS-RUN-NO
                  DELIMITED BY SIZE INTO WS-PRINT
           WRITE SUM-LINE FROM WS-PRINT
           MOVE SPACES TO WS-PRINT
           STRING "COMPANY " WS-COMPANY
                  DELIMITED BY SIZE INTO WS-PRINT
           WRITE SUM-LINE FROM WS-PRINT
           MOVE WS-ACCT-READ TO WS-ED-COUNT
           MOVE "ACCOUNTS READ" TO WS-PRINT
           PERFORM 8100-COUNT-LINE
           MOVE WS-ACCT-ACCEPTED TO WS-ED-COUNT
           MOVE "ACCOUNTS BILLED" TO WS-PRINT
           PERFORM 8100-COUNT-LINE
           MOVE WS-ACCT-SKIPPED TO WS-ED-COUNT
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
               PERFORM VARYING WI FROM 1 BY 1 UNTIL WI > 20
                   IF RC-COUNT(WI) > 0
                       MOVE RC-COUNT(WI) TO WS-ED-COUNT
                       MOVE SPACES TO WS-PRINT
                       STRING "  " RM-CODE(WI) " " RM-TEXT(WI)
                              DELIMITED BY SIZE INTO WS-PRINT
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
           IF WG-COUNT > 0
               MOVE "AMOUNT DUE BY REGION" TO SUM-LINE
               WRITE SUM-LINE
               PERFORM VARYING WI FROM 1 BY 1 UNTIL WI > WG-COUNT
                   MOVE WG-DUE(WI) TO WS-ED-SUM
                   MOVE SPACES TO WS-PRINT
                   STRING "  REGION " WG-REGION(WI)
                          DELIMITED BY SIZE INTO WS-PRINT
                   PERFORM 8200-AMOUNT-LINE
               END-PERFORM
           END-IF.

       8100-COUNT-LINE.
           MOVE WS-ED-COUNT TO WS-PRINT(31:5)
           WRITE SUM-LINE FROM WS-PRINT
           MOVE SPACES TO WS-PRINT.

       8200-AMOUNT-LINE.
           MOVE WS-ED-SUM TO WS-PRINT(24:17)
           WRITE SUM-LINE FROM WS-PRINT
           MOVE SPACES TO WS-PRINT.

       9000-CLOSE.
           CLOSE STMT-FILE
           CLOSE REJ-FILE
           CLOSE SUM-FILE.
