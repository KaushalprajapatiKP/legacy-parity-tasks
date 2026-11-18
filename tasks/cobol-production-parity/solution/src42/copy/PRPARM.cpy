      *----------------------------------------------------------------
      * PRPARM - PARAMETERS FOR PRORATE
      *----------------------------------------------------------------
       01  PR-PARMS.
           05  PR-CYCLE-DAYS           PIC 99.
           05  PR-DAY OCCURS 31 TIMES.
               10  PR-DAY-PLAN         PIC X.
               10  PR-DAY-SUSP         PIC X.
           05  PR-SEG-COUNT            PIC 99.
           05  PR-SEG OCCURS 31 TIMES.
               10  PR-SEG-PLAN         PIC X.
               10  PR-SEG-START        PIC 99.
               10  PR-SEG-DAYS         PIC 99.
               10  PR-SEG-AMOUNT       PIC 9(5)V99.
           05  PR-TOTAL                PIC 9(7)V99.
