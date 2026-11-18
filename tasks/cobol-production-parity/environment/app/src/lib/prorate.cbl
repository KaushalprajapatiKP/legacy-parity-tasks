      *================================================================
      * PRORATE - BASE FEE BY PLAN SEGMENT
      * PART OF BILLRUN.  MIT LICENSE, SEE LICENSE.
      *================================================================
       IDENTIFICATION DIVISION.
       PROGRAM-ID. PRORATE.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY RATETAB.
       01  WS-D                        PIC 99.
       01  WS-S                        PIC 99.
       01  WS-P                        PIC 9.
       01  WS-PREV                     PIC X.
       01  WS-FEE                      PIC 9(5)V99.
       LINKAGE SECTION.
       COPY PRPARM.
       PROCEDURE DIVISION USING PR-PARMS.
       0000-MAIN.
           MOVE 0 TO PR-SEG-COUNT PR-TOTAL
           MOVE SPACE TO WS-PREV
           PERFORM VARYING WS-D FROM 1 BY 1
                   UNTIL WS-D > PR-CYCLE-DAYS
               IF PR-DAY-PLAN(WS-D) = SPACE
                   MOVE SPACE TO WS-PREV
               ELSE
                   IF PR-DAY-PLAN(WS-D) NOT = WS-PREV
                       ADD 1 TO PR-SEG-COUNT
                       MOVE PR-SEG-COUNT TO WS-S
                       MOVE PR-DAY-PLAN(WS-D) TO PR-SEG-PLAN(WS-S)
                       MOVE WS-D TO PR-SEG-START(WS-S)
                       MOVE 0 TO PR-SEG-DAYS(WS-S)
                       MOVE PR-DAY-PLAN(WS-D) TO WS-PREV
                   END-IF
                   ADD 1 TO PR-SEG-DAYS(WS-S)
               END-IF
           END-PERFORM
           PERFORM VARYING WS-S FROM 1 BY 1
                   UNTIL WS-S > PR-SEG-COUNT
               MOVE 0 TO WS-FEE
               PERFORM VARYING WS-P FROM 1 BY 1 UNTIL WS-P > 3
                   IF PF-PLAN(WS-P) = PR-SEG-PLAN(WS-S)
                       MOVE PF-FEE(WS-P) TO WS-FEE
                   END-IF
               END-PERFORM
               COMPUTE PR-SEG-AMOUNT(WS-S) ROUNDED =
                   WS-FEE * PR-SEG-DAYS(WS-S) / PR-CYCLE-DAYS
               ADD PR-SEG-AMOUNT(WS-S) TO PR-TOTAL
           END-PERFORM
           GOBACK.
