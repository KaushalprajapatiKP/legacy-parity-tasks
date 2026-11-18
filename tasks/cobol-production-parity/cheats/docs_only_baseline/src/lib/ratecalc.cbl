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
           05  WS-DATA-INCL-S          PIC 9V99    VALUE 1.00.
           05  WS-DATA-INCL-P          PIC 9V99    VALUE 3.00.
           05  WS-VOIC-RATE            PIC 9V99    VALUE 0.05.
           05  WS-VOIC-RATE-P          PIC 9V99    VALUE 0.04.
           05  WS-SMS-RATE             PIC 9V99    VALUE 0.02.
           05  WS-SMS-RATE-B           PIC 9V99    VALUE 0.03.
           05  WS-SMS-FREE-P           PIC 9(3)    VALUE 50.
           05  WS-ROAM-RATE            PIC 9V99    VALUE 0.25.
       01  WS-WORK.
           05  WS-BILLABLE             PIC S9(7)V99.
           05  WS-T1                   PIC 9(7)V99.
           05  WS-T2                   PIC 9(7)V99.
           05  WS-T3                   PIC 9(7)V99.
           05  WS-WHOLE                PIC 9(7)V99.
           05  WS-RAW                  PIC S9(9)V9(6).
       LINKAGE SECTION.
       COPY RCPARM.
       PROCEDURE DIVISION USING RC-PARMS.
       0000-MAIN.
           MOVE 0 TO RC-AMOUNT
           EVALUATE RC-FUNC
               WHEN "M"
                   PERFORM 1000-VOICE-MINUTES
               WHEN "N"
                   COMPUTE RC-BILL-QTY =
                       FUNCTION INTEGER-PART(RC-QTY)
               WHEN "R"
                   MOVE RC-QTY TO RC-BILL-QTY
                   COMPUTE RC-AMOUNT ROUNDED =
                       RC-QTY * WS-ROAM-RATE
               WHEN "D"
                   PERFORM 2000-DATA
               WHEN "V"
                   IF RC-PLAN = "P"
                       COMPUTE RC-AMOUNT ROUNDED =
                           RC-QTY * WS-VOIC-RATE-P
                   ELSE
                       COMPUTE RC-AMOUNT ROUNDED =
                           RC-QTY * WS-VOIC-RATE
                   END-IF
               WHEN "S"
                   PERFORM 3000-SMS
           END-EVALUATE
           GOBACK.

       1000-VOICE-MINUTES.
           COMPUTE WS-WHOLE = FUNCTION INTEGER-PART(RC-QTY)
           IF RC-QTY - WS-WHOLE NOT < 0.50
               ADD 1 TO WS-WHOLE
           END-IF
           MOVE WS-WHOLE TO RC-BILL-QTY.

       2000-DATA.
           MOVE RC-QTY TO WS-BILLABLE
           EVALUATE RC-PLAN
               WHEN "S"
                   SUBTRACT WS-DATA-INCL-S FROM WS-BILLABLE
               WHEN "P"
                   SUBTRACT WS-DATA-INCL-P FROM WS-BILLABLE
           END-EVALUATE
           IF WS-BILLABLE < 0
               MOVE 0 TO WS-BILLABLE
           END-IF
           MOVE 0 TO WS-T1 WS-T2 WS-T3
           IF WS-BILLABLE > WS-DATA-T1-LIMIT
               MOVE WS-DATA-T1-LIMIT TO WS-T1
               IF WS-BILLABLE > WS-DATA-T2-LIMIT
                   COMPUTE WS-T2 = WS-DATA-T2-LIMIT - WS-DATA-T1-LIMIT
                   COMPUTE WS-T3 = WS-BILLABLE - WS-DATA-T2-LIMIT
               ELSE
                   COMPUTE WS-T2 = WS-BILLABLE - WS-DATA-T1-LIMIT
               END-IF
           ELSE
               MOVE WS-BILLABLE TO WS-T1
           END-IF
           COMPUTE WS-RAW = WS-T1 * WS-DATA-T1-RATE
                          + WS-T2 * WS-DATA-T2-RATE
                          + WS-T3 * WS-DATA-T3-RATE
           COMPUTE RC-AMOUNT ROUNDED = WS-RAW.

       3000-SMS.
           MOVE RC-QTY TO WS-BILLABLE
           IF RC-PLAN = "P"
               SUBTRACT WS-SMS-FREE-P FROM WS-BILLABLE
               IF WS-BILLABLE < 0
                   MOVE 0 TO WS-BILLABLE
               END-IF
           END-IF
           IF RC-PLAN = "B"
               COMPUTE RC-AMOUNT ROUNDED = WS-BILLABLE * WS-SMS-RATE-B
           ELSE
               COMPUTE RC-AMOUNT ROUNDED = WS-BILLABLE * WS-SMS-RATE
           END-IF.
