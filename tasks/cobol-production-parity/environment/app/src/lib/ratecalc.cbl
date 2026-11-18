      *================================================================
      * RATECALC - USAGE RATING
      * PART OF BILLRUN.  MIT LICENSE, SEE LICENSE.
      *================================================================
       IDENTIFICATION DIVISION.
       PROGRAM-ID. RATECALC.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-RATES.
           05  WS-DATA-T1-LIMIT        PIC 9(3)V99 VALUE 10.00.
           05  WS-DATA-T2-LIMIT        PIC 9(3)V99 VALUE 50.00.
           05  WS-DATA-T1-RATE         PIC 9V99    VALUE 1.50.
           05  WS-DATA-T2-RATE         PIC 9V99    VALUE 1.20.
           05  WS-DATA-T3-RATE         PIC 9V99    VALUE 0.90.
           05  WS-VOIC-RATE            PIC 9V99    VALUE 0.05.
           05  WS-SMS-RATE             PIC 9V99    VALUE 0.02.
           05  WS-ROAM-RATE            PIC 9V99    VALUE 0.25.
       01  WS-WORK.
           05  WS-T1                   PIC 9(7)V99.
           05  WS-T2                   PIC 9(7)V99.
           05  WS-T3                   PIC 9(7)V99.
           05  WS-C1                   PIC 9(7)V99.
           05  WS-C2                   PIC 9(7)V99.
           05  WS-C3                   PIC 9(7)V99.
       LINKAGE SECTION.
       COPY RCPARM.
       PROCEDURE DIVISION USING RC-PARMS.
       0000-MAIN.
           MOVE 0 TO RC-AMOUNT
           MOVE RC-QTY TO RC-BILL-QTY
           EVALUATE RC-FUNC
               WHEN "D"
                   PERFORM 2000-DATA
               WHEN "V"
                   COMPUTE RC-AMOUNT ROUNDED = RC-QTY * WS-VOIC-RATE
               WHEN "S"
                   COMPUTE RC-AMOUNT ROUNDED = RC-QTY * WS-SMS-RATE
               WHEN "R"
                   COMPUTE RC-AMOUNT = RC-QTY * WS-ROAM-RATE
           END-EVALUATE
           GOBACK.

       2000-DATA.
           MOVE 0 TO WS-T1 WS-T2 WS-T3
           IF RC-QTY > WS-DATA-T1-LIMIT
               MOVE WS-DATA-T1-LIMIT TO WS-T1
               IF RC-QTY > WS-DATA-T2-LIMIT
                   COMPUTE WS-T2 = WS-DATA-T2-LIMIT - WS-DATA-T1-LIMIT
                   COMPUTE WS-T3 = RC-QTY - WS-DATA-T2-LIMIT
               ELSE
                   COMPUTE WS-T2 = RC-QTY - WS-DATA-T1-LIMIT
               END-IF
           ELSE
               MOVE RC-QTY TO WS-T1
           END-IF
           COMPUTE WS-C1 ROUNDED = WS-T1 * WS-DATA-T1-RATE
           COMPUTE WS-C2 ROUNDED = WS-T2 * WS-DATA-T2-RATE
           COMPUTE WS-C3 ROUNDED = WS-T3 * WS-DATA-T3-RATE
           COMPUTE RC-AMOUNT = WS-C1 + WS-C2 + WS-C3.
