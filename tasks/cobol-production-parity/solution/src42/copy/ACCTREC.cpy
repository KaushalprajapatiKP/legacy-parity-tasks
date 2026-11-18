      *----------------------------------------------------------------
      * ACCTREC - ACCOUNT MASTER RECORD (ACCOUNTS.DAT), 80 BYTES
      *----------------------------------------------------------------
       01  ACCT-RECORD.
           05  AR-ACCT-ID              PIC X(8).
           05  AR-NAME                 PIC X(24).
           05  AR-PLAN                 PIC X.
           05  AR-OPEN-DATE            PIC X(8).
           05  AR-CLOSE-DATE           PIC X(8).
           05  AR-TAX-CLASS            PIC X.
           05  AR-REGION               PIC X(2).
           05  AR-PRIOR-BAL-X.
               10  AR-BAL-SIGN         PIC X.
               10  AR-BAL-DIGITS       PIC X(9).
           05  AR-PRIOR-BAL-N REDEFINES AR-PRIOR-BAL-X
                                       PIC S9(7)V99
                                       SIGN LEADING SEPARATE.
           05  AR-LOYALTY              PIC X(2).
           05  FILLER                  PIC X(16).
