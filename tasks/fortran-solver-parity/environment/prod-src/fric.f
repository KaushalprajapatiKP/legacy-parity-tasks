C     ==================================================================
C     HYDRO 2.3  -  LINK HEAD LOSS LAWS
C     ==================================================================
C
C     LHEAD  -  HEAD LOSS H (FROM-NODE MINUS TO-NODE) OF LINK K AT
C               FLOW QK, AND ITS GRADIENT G = DH/DQ USED BY THE SOLVER
C
      SUBROUTINE LHEAD(K, QK, H, G)
      INCLUDE 'hydro.inc'
      INTEGER K
      DOUBLE PRECISION QK, H, G
      DOUBLE PRECISION A, AQ, R, RE, F, CM, DWF
      AQ = ABS(QK)
      IF (LTYP(K) .EQ. 2) THEN
C        PUMP: HEAD GAIN H0*(1-(Q/QMAX)**2), OR CONSTANT H0
         IF (PQM(K) .GT. 0D0) THEN
            CM = PH0(K)/PQM(K)**2
            H = -(PH0(K) - CM*QK*AQ)
            G = 2D0*CM*AQ
         ELSE
            H = -PH0(K)
            G = 0D0
         ENDIF
      ELSE
C        PIPE OR VALVE: MINOR LOSS K*V**2/2G, LINEAR BELOW QZERO
         A = PI*LDIA(K)**2/4D0
         CM = LKM(K)/(2D0*GRAV*A*A)
         IF (AQ .GE. QZERO) THEN
            H = CM*QK*AQ
            G = 2D0*CM*AQ
         ELSE
            H = CM*QZERO*QK
            G = CM*QZERO
         ENDIF
         IF (LTYP(K) .EQ. 1) THEN
            IF (IFRIC .EQ. 2) THEN
C              HAZEN-WILLIAMS, LINEAR BELOW QZERO
               R = 10.667D0*LLEN(K)/
     &             (LRGH(K)**1.852D0*LDIA(K)**4.871D0)
               IF (AQ .GE. QZERO) THEN
                  H = H + R*SIGN(AQ**1.852D0, QK)
                  G = G + 1.852D0*R*AQ**0.852D0
               ELSE
                  H = H + R*QZERO**0.852D0*QK
                  G = G + R*QZERO**0.852D0
               ENDIF
            ELSE
C              DARCY-WEISBACH; THE LAMINAR LAW IS LINEAR IN Q
               RE = AQ*LDIA(K)/(A*VISC)
               IF (RE .LE. 2000D0) THEN
                  R = 32D0*VISC*LLEN(K)/(GRAV*LDIA(K)**2*A)
                  H = H + R*QK
                  G = G + R
                  FF(K) = 0D0
                  IF (RE .GT. 0D0) FF(K) = 64D0/RE
               ELSE
                  F = DWF(RE, LRGH(K)/LDIA(K))
                  FF(K) = F
                  R = F*LLEN(K)/(LDIA(K)*2D0*GRAV*A*A)
                  H = H + R*QK*AQ
                  G = G + 2D0*R*AQ
               ENDIF
            ENDIF
         ENDIF
      ENDIF
      IF (G .LT. GMIN) G = GMIN
      RETURN
      END
C
C     DWF  -  DARCY FRICTION FACTOR FOR REYNOLDS NUMBER RE AND
C             RELATIVE ROUGHNESS E
C
      DOUBLE PRECISION FUNCTION DWF(RE, E)
      DOUBLE PRECISION RE, E, SJF, F4
      IF (RE .LT. 1.0D-6) THEN
         DWF = 0D0
      ELSE IF (RE .LE. 2000D0) THEN
         DWF = 64D0/RE
      ELSE IF (RE .GE. 4000D0) THEN
         DWF = SJF(RE, E)
      ELSE
         F4 = SJF(4000D0, E)
         DWF = 0.032D0 + (F4 - 0.032D0)*(RE - 2000D0)/2000D0
      ENDIF
      RETURN
      END
C
C     SJF  -  EXPLICIT TURBULENT FRICTION FACTOR
C
      DOUBLE PRECISION FUNCTION SJF(RE, E)
      DOUBLE PRECISION RE, E, X
      X = LOG10(E/3.7D0 + 5.74D0/RE**0.9D0)
      SJF = 0.25D0/(X*X)
      RETURN
      END
