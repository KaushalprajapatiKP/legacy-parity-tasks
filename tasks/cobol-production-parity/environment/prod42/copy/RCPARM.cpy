      *----------------------------------------------------------------
      * RCPARM - PARAMETERS FOR RATECALC
      *   FUNC D=DATA V=VOICE S=SMS R=ROAMING RECORD
      *        M=VOICE MINUTES PER RECORD  N=SMS COUNT PER RECORD
      *----------------------------------------------------------------
       01  RC-PARMS.
           05  RC-FUNC                 PIC X.
           05  RC-PLAN                 PIC X.
           05  RC-QTY                  PIC 9(7)V99.
           05  RC-BILL-QTY             PIC 9(7)V99.
           05  RC-AMOUNT               PIC S9(7)V99.
