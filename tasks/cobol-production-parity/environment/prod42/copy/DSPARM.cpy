      *----------------------------------------------------------------
      * DSPARM - PARAMETERS FOR DISCOUNT
      *----------------------------------------------------------------
       01  DS-PARMS.
           05  DS-BASE                 PIC S9(7)V99.
           05  DS-DISCOUNTABLE         PIC S9(7)V99.
           05  DS-LOYALTY-CODE         PIC XX.
           05  DS-LOYALTY-PCT          PIC 99.
           05  DS-LOYALTY-AMT          PIC S9(7)V99.
           05  DS-CPN-COUNT            PIC 99.
           05  DS-CPN OCCURS 20 TIMES.
               10  DS-CPN-KIND         PIC X.
               10  DS-CPN-VALUE        PIC 9(7)V99.
               10  DS-CPN-AMT          PIC S9(7)V99.
               10  DS-CPN-ORDER        PIC 99.
           05  DS-CAP-AMT              PIC S9(7)V99.
           05  DS-TOTAL                PIC S9(7)V99.
