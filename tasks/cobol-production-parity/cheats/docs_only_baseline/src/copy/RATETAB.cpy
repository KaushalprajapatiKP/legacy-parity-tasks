      *----------------------------------------------------------------
      * RATETAB - MONTHLY PLAN FEES
      *----------------------------------------------------------------
       01  PLAN-FEE-VALUES.
           05  FILLER  PIC X(8)  VALUE "B0001000".
           05  FILLER  PIC X(8)  VALUE "S0002500".
           05  FILLER  PIC X(8)  VALUE "P0006000".
       01  PLAN-FEE-TABLE REDEFINES PLAN-FEE-VALUES.
           05  PF-ENTRY OCCURS 3 TIMES.
               10  PF-PLAN             PIC X.
               10  PF-FEE              PIC 9(5)V99.
