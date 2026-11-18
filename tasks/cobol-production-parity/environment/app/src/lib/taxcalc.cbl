      *================================================================
      * TAXCALC - SALES TAX BY TAX CLASS
      * PART OF BILLRUN.  MIT LICENSE, SEE LICENSE.
      *================================================================
       IDENTIFICATION DIVISION.
       PROGRAM-ID. TaxCalc.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-RATE                     PIC 9V9(4).
       LINKAGE SECTION.
       COPY TXPARM.
       PROCEDURE DIVISION USING TX-PARMS.
       0000-MAIN.
           EVALUATE TX-CLASS
               WHEN "R"
                   MOVE 0.0400 TO WS-RATE
                   MOVE "4.00%" TO TX-RATE-DISP
               WHEN "E"
                   MOVE 0 TO WS-RATE
                   MOVE "0.00%" TO TX-RATE-DISP
               WHEN OTHER
                   MOVE 0.0825 TO WS-RATE
                   MOVE "8.25%" TO TX-RATE-DISP
           END-EVALUATE
           COMPUTE TX-AMOUNT = TX-TAXABLE * WS-RATE
           GOBACK.
