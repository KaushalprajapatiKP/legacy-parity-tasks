      *================================================================
      * DATEUTIL - VALIDATE A YYYYMMDD DATE AND RETURN ITS DAY NUMBER
      * PART OF BILLRUN.  MIT LICENSE, SEE LICENSE.
      *================================================================
       IDENTIFICATION DIVISION.
       PROGRAM-ID. DATEUTIL.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-MM                       PIC 99.
       01  WS-DD                       PIC 99.
       01  MONTH-DAY-VALUES            PIC X(24)
                                VALUE "312931303130313130313031".
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
           MOVE DU-DATE(5:2) TO WS-MM
           MOVE DU-DATE(7:2) TO WS-DD
           IF WS-MM < 1 OR WS-MM > 12
               GOBACK
           END-IF
           IF WS-DD < 1 OR WS-DD > MD-DAYS(WS-MM)
               GOBACK
           END-IF
           MOVE "Y" TO DU-VALID
           COMPUTE DU-DAYNUM = FUNCTION INTEGER-OF-DATE(DU-DATE-N)
           GOBACK.
