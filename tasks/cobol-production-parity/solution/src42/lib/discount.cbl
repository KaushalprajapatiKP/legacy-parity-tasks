      *================================================================
      * DISCOUNT - LOYALTY AND COUPON DISCOUNTS
      * PART OF BILLRUN.  MIT LICENSE, SEE LICENSE.
      *================================================================
       IDENTIFICATION DIVISION.
       PROGRAM-ID. DISCOUNT.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-I                        PIC 99.
       01  WS-N                        PIC 99.
       01  WS-REMAIN                   PIC S9(7)V99.
       01  WS-CAP                      PIC S9(7)V99.
       01  WS-CAP-PCT                  PIC V99 VALUE .50.
       LINKAGE SECTION.
       COPY DSPARM.
       PROCEDURE DIVISION USING DS-PARMS.
       0000-MAIN.
           MOVE 0 TO DS-LOYALTY-AMT DS-CAP-AMT DS-TOTAL
           MOVE 0 TO DS-LOYALTY-PCT WS-N
           PERFORM VARYING WS-I FROM 1 BY 1
                   UNTIL WS-I > DS-CPN-COUNT
               MOVE 0 TO DS-CPN-AMT(WS-I)
               MOVE 0 TO DS-CPN-ORDER(WS-I)
           END-PERFORM
           IF DS-DISCOUNTABLE NOT > 0
               GOBACK
           END-IF
           EVALUATE DS-LOYALTY-CODE
               WHEN "L1"  MOVE 5 TO DS-LOYALTY-PCT
               WHEN "L2"  MOVE 10 TO DS-LOYALTY-PCT
               WHEN "L3"  MOVE 15 TO DS-LOYALTY-PCT
               WHEN OTHER MOVE 0 TO DS-LOYALTY-PCT
           END-EVALUATE
           COMPUTE DS-LOYALTY-AMT ROUNDED =
               DS-BASE * DS-LOYALTY-PCT / 100
           MOVE DS-LOYALTY-AMT TO DS-TOTAL
           COMPUTE WS-REMAIN = DS-DISCOUNTABLE - DS-LOYALTY-AMT
      *    FIXED COUPONS FIRST, THEN PERCENTAGE COUPONS ON REMAINDER
           PERFORM VARYING WS-I FROM 1 BY 1
                   UNTIL WS-I > DS-CPN-COUNT
               IF DS-CPN-KIND(WS-I) = "F"
                   IF DS-CPN-VALUE(WS-I) > WS-REMAIN
                       MOVE WS-REMAIN TO DS-CPN-AMT(WS-I)
                   ELSE
                       MOVE DS-CPN-VALUE(WS-I) TO DS-CPN-AMT(WS-I)
                   END-IF
                   IF DS-CPN-AMT(WS-I) < 0
                       MOVE 0 TO DS-CPN-AMT(WS-I)
                   END-IF
                   SUBTRACT DS-CPN-AMT(WS-I) FROM WS-REMAIN
                   ADD DS-CPN-AMT(WS-I) TO DS-TOTAL
                   ADD 1 TO WS-N
                   MOVE WS-I TO DS-CPN-ORDER(WS-N)
               END-IF
           END-PERFORM
           PERFORM VARYING WS-I FROM 1 BY 1
                   UNTIL WS-I > DS-CPN-COUNT
               IF DS-CPN-KIND(WS-I) = "P"
                   IF WS-REMAIN > 0
                       COMPUTE DS-CPN-AMT(WS-I) ROUNDED =
                           WS-REMAIN * DS-CPN-VALUE(WS-I) / 100
                   END-IF
                   SUBTRACT DS-CPN-AMT(WS-I) FROM WS-REMAIN
                   ADD DS-CPN-AMT(WS-I) TO DS-TOTAL
                   ADD 1 TO WS-N
                   MOVE WS-I TO DS-CPN-ORDER(WS-N)
               END-IF
           END-PERFORM
           COMPUTE WS-CAP ROUNDED = DS-DISCOUNTABLE * WS-CAP-PCT
           IF DS-TOTAL > WS-CAP
               COMPUTE DS-CAP-AMT = DS-TOTAL - WS-CAP
               MOVE WS-CAP TO DS-TOTAL
           END-IF
           GOBACK.
