      *----------------------------------------------------------------
      * REJMSG - REJECT CODES AND MESSAGE TEXT
      *----------------------------------------------------------------
       01  REJ-MSG-VALUES.
           05  FILLER PIC X(23) VALUE "A01NO ACCOUNT ID".
           05  FILLER PIC X(23) VALUE "A03BAD PLAN CODE".
           05  FILLER PIC X(23) VALUE "A04BAD OPEN DATE".
           05  FILLER PIC X(23) VALUE "A05BAD CLOSE DATE".
           05  FILLER PIC X(23) VALUE "A07BAD BALANCE".
           05  FILLER PIC X(23) VALUE "C01CONTROL CARD ERROR".
           05  FILLER PIC X(23) VALUE "R01INVALID RECORD TYPE".
           05  FILLER PIC X(23) VALUE "R02ACCOUNT NOT FOUND".
           05  FILLER PIC X(23) VALUE "R03BAD DATE".
           05  FILLER PIC X(23) VALUE "R05BAD AMOUNT".
           05  FILLER PIC X(23) VALUE "R06BAD CODE".
       01  REJ-MSG-TABLE REDEFINES REJ-MSG-VALUES.
           05  RM-ENTRY OCCURS 11 TIMES.
               10  RM-CODE             PIC X(3).
               10  MESSAGE             PIC X(20).
