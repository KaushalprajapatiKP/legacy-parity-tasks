      *----------------------------------------------------------------
      * ACTREC - ACTIVITY RECORD (ACTIVITY.DAT), 80 BYTES
      *   US USAGE  CH CHARGE  PC PLAN CHANGE  PY PAYMENT
      *   AD ADJUSTMENT
      *----------------------------------------------------------------
       01  ACT-RECORD.
           05  XR-TYPE                 PIC XX.
           05  XR-ACCT-ID              PIC X(8).
           05  XR-DATE                 PIC X(8).
           05  XR-DATA                 PIC X(62).
           05  XR-US-DATA REDEFINES XR-DATA.
               10  XR-US-SERVICE       PIC X(4).
               10  XR-US-QTY           PIC X(9).
               10  XR-US-QTY-N REDEFINES XR-US-QTY
                                       PIC 9(7)V99.
               10  FILLER              PIC X(49).
           05  XR-CH-DATA REDEFINES XR-DATA.
               10  XR-CH-CODE          PIC X(4).
               10  XR-CH-AMOUNT.
                   15  XR-CH-SIGN      PIC X.
                   15  XR-CH-DIGITS    PIC X(9).
               10  XR-CH-DIGITS-N REDEFINES XR-CH-AMOUNT.
                   15  FILLER          PIC X.
                   15  XR-CH-VALUE     PIC 9(7)V99.
               10  XR-CH-DESC          PIC X(20).
               10  FILLER              PIC X(28).
           05  XR-PC-DATA REDEFINES XR-DATA.
               10  XR-PC-PLAN          PIC X.
               10  FILLER              PIC X(61).
