      *----------------------------------------------------------------
      * ACTREC - ACTIVITY RECORD (ACTIVITY.DAT), 80 BYTES
      *   US USAGE  CH CHARGE  PC PLAN CHANGE  PY PAYMENT
      *   AD ADJUSTMENT  DS DISCOUNT COUPON  SU SUSPENSION
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
               10  XR-CH-AMOUNT-N REDEFINES XR-CH-AMOUNT
                                       PIC S9(7)V99
                                       SIGN LEADING SEPARATE.
               10  XR-CH-DESC          PIC X(20).
               10  FILLER              PIC X(28).
           05  XR-PC-DATA REDEFINES XR-DATA.
               10  XR-PC-PLAN          PIC X.
               10  FILLER              PIC X(61).
           05  XR-DS-DATA REDEFINES XR-DATA.
               10  XR-DS-KIND          PIC X.
               10  FILLER              PIC X(3).
               10  XR-DS-VALUE         PIC X(10).
               10  FILLER              PIC X(48).
           05  XR-SU-DATA REDEFINES XR-DATA.
               10  XR-SU-END           PIC X(8).
               10  FILLER              PIC X(54).
