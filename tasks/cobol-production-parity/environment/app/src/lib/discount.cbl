      *================================================================
      * DISCOUNT - LOYALTY DISCOUNT
      * PART OF BILLRUN.  MIT LICENSE, SEE LICENSE.
      *================================================================
       IDENTIFICATION DIVISION.
       PROGRAM-ID. DISCOUNT.
       DATA DIVISION.
       LINKAGE SECTION.
       COPY DSPARM.
       PROCEDURE DIVISION USING DS-PARMS.
       0000-MAIN.
           EVALUATE DS-LOYALTY-CODE
               WHEN "L1"  MOVE 5 TO DS-LOYALTY-PCT
               WHEN "L2"  MOVE 10 TO DS-LOYALTY-PCT
               WHEN OTHER MOVE 0 TO DS-LOYALTY-PCT
           END-EVALUATE
           COMPUTE DS-LOYALTY-AMT ROUNDED =
               (DS-BASE + DS-USAGE) * DS-LOYALTY-PCT / 100
           GOBACK.
