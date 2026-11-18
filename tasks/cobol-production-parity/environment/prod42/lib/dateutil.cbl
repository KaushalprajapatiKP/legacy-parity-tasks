      *================================================================
      * DATEUTIL - VALIDATE A YYYYMMDD DATE AND RETURN ITS DAY NUMBER
      * PART OF BILLRUN.  MIT LICENSE, SEE LICENSE.
      *================================================================
       IDENTIFICATION DIVISION.
       PROGRAM-ID. DATEUTIL.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-YYYY                     PIC 9(4).
       01  WS-MM                       PIC 99.
       01  WS-DD                       PIC 99.
       01  WS-MAXDD                    PIC 99.
       01  WS-QUOT                     PIC 9(4).
       01  WS-REM4                     PIC 9(4).
       01  WS-REM100                   PIC 9(4).
       01  WS-REM400                   PIC 9(4).
       01  WS-LEAP                     PIC X.
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
           MOVE DU-DATE(1:4) TO WS-YYYY
           MOVE DU-DATE(5:2) TO WS-MM
           MOVE DU-DATE(7:2) TO WS-DD
           IF WS-YYYY < 1900
               GOBACK
           END-IF
           IF WS-MM < 1 OR WS-MM > 12
               GOBACK
           END-IF
           PERFORM 1000-LEAP-TEST
           MOVE MD-DAYS(WS-MM) TO WS-MAXDD
           IF WS-MM = 2 AND WS-LEAP = "Y"
               MOVE 29 TO WS-MAXDD
           END-IF
           IF WS-DD < 1 OR WS-DD > WS-MAXDD
               GOBACK
           END-IF
           MOVE "Y" TO DU-VALID
           COMPUTE DU-DAYNUM = FUNCTION INTEGER-OF-DATE(DU-DATE-N)
           GOBACK.

       1000-LEAP-TEST.
           MOVE "N" TO WS-LEAP
           DIVIDE WS-YYYY BY 4 GIVING WS-QUOT REMAINDER WS-REM4
           DIVIDE WS-YYYY BY 100 GIVING WS-QUOT REMAINDER WS-REM100
           DIVIDE WS-YYYY BY 400 GIVING WS-QUOT REMAINDER WS-REM400
           IF WS-REM4 = 0
               MOVE "Y" TO WS-LEAP
               IF WS-REM100 = 0 AND WS-REM400 NOT = 0
                   MOVE "N" TO WS-LEAP
               END-IF
           END-IF.
