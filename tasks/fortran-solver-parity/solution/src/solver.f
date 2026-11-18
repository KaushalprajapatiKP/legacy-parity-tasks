C     ==================================================================
C     HYDRO 2.3  -  NETWORK SOLVER (GRADIENT METHOD ON NODAL HEADS)
C     ==================================================================
C
      SUBROUTINE SOLVE
      INCLUDE 'hydro.inc'
      DOUBLE PRECISION A(MAXN,MAXN), F(MAXN), X(MAXN)
      DOUBLE PRECISION P(MAXL), Y(MAXL)
      INTEGER IX(MAXN)
      COMMON /WORK/ A, F, X, P, Y, IX
      INTEGER I, J, K, N1, N2, I1, I2, NU, IT
      DOUBLE PRECISION H, G, QN, SDQ, SQ
      LOGICAL OK
C
C     NUMBER THE UNKNOWN HEADS; FIXED HEADS ARE KNOWN
      NU = 0
      DO 10 I = 1, NNODE
         IX(I) = 0
         IF (NTYP(I) .EQ. 2) THEN
            HEAD(I) = ELEV(I)
         ELSE IF (NISO(I)) THEN
            HEAD(I) = 0D0
         ELSE
            NU = NU + 1
            IX(I) = NU
         ENDIF
   10 CONTINUE
C
      CONVGD = .FALSE.
      DO 100 IT = 1, MAXIT
         ITERS = IT
         DO 20 I = 1, NU
            F(I) = 0D0
            DO 15 J = 1, NU
               A(I,J) = 0D0
   15       CONTINUE
   20    CONTINUE
         DO 25 I = 1, NNODE
            IF (IX(I) .GT. 0) F(IX(I)) = -DEM(I)
   25    CONTINUE
         DO 30 K = 1, NLINK
            IF (LSTA(K) .NE. 1) GOTO 30
            CALL LHEAD(K, Q(K), H, G)
            P(K) = 1D0/G
            Y(K) = P(K)*H
            N1 = LN1(K)
            N2 = LN2(K)
            I1 = IX(N1)
            I2 = IX(N2)
            IF (I1 .GT. 0) THEN
               A(I1,I1) = A(I1,I1) + P(K)
               F(I1) = F(I1) - (Q(K) - Y(K))
               IF (I2 .GT. 0) THEN
                  A(I1,I2) = A(I1,I2) - P(K)
               ELSE
                  F(I1) = F(I1) + P(K)*HEAD(N2)
               ENDIF
            ENDIF
            IF (I2 .GT. 0) THEN
               A(I2,I2) = A(I2,I2) + P(K)
               F(I2) = F(I2) + (Q(K) - Y(K))
               IF (I1 .GT. 0) THEN
                  A(I2,I1) = A(I2,I1) - P(K)
               ELSE
                  F(I2) = F(I2) + P(K)*HEAD(N1)
               ENDIF
            ENDIF
   30    CONTINUE
         IF (NU .GT. 0) THEN
            CALL GAUSS(A, F, X, NU, MAXN, OK)
            IF (.NOT. OK) THEN
               CALL ERRMSG('E303', 0, 'SINGULAR SYSTEM')
               STOP 1
            ENDIF
            DO 40 I = 1, NNODE
               IF (IX(I) .GT. 0) HEAD(I) = X(IX(I))
   40       CONTINUE
         ENDIF
C        NEW FLOWS AND CONVERGENCE TEST
         SDQ = 0D0
         SQ  = 0D0
         DO 50 K = 1, NLINK
            IF (LSTA(K) .NE. 1) GOTO 50
            QN = Q(K) - Y(K) + P(K)*(HEAD(LN1(K)) - HEAD(LN2(K)))
            SDQ = SDQ + ABS(QN - Q(K))
            SQ  = SQ + ABS(QN)
            Q(K) = QN
   50    CONTINUE
         IF (SDQ .LE. TOL*MAX(SQ, QZERO)) THEN
            CONVGD = .TRUE.
            RETURN
         ENDIF
  100 CONTINUE
      RETURN
      END
C
C     GAUSS  -  SOLVE A*X = B BY ELIMINATION WITH PARTIAL PIVOTING
C               (A AND B ARE OVERWRITTEN)
C
      SUBROUTINE GAUSS(A, B, X, N, LDA, OK)
      INTEGER N, LDA
      DOUBLE PRECISION A(LDA,*), B(*), X(*)
      LOGICAL OK
      INTEGER I, J, K, IP
      DOUBLE PRECISION T, AMAX
      OK = .TRUE.
      DO 50 K = 1, N
         IP = K
         AMAX = ABS(A(K,K))
         DO 10 I = K+1, N
            IF (ABS(A(I,K)) .GT. AMAX) THEN
               AMAX = ABS(A(I,K))
               IP = I
            ENDIF
   10    CONTINUE
         IF (AMAX .LT. 1.0D-30) THEN
            OK = .FALSE.
            RETURN
         ENDIF
         IF (IP .NE. K) THEN
            DO 20 J = K, N
               T = A(K,J)
               A(K,J) = A(IP,J)
               A(IP,J) = T
   20       CONTINUE
            T = B(K)
            B(K) = B(IP)
            B(IP) = T
         ENDIF
         DO 40 I = K+1, N
            T = A(I,K)/A(K,K)
            IF (T .NE. 0D0) THEN
               DO 30 J = K+1, N
                  A(I,J) = A(I,J) - T*A(K,J)
   30          CONTINUE
               B(I) = B(I) - T*B(K)
            ENDIF
   40    CONTINUE
   50 CONTINUE
      DO 70 I = N, 1, -1
         T = B(I)
         DO 60 J = I+1, N
            T = T - A(I,J)*X(J)
   60    CONTINUE
         X(I) = T/A(I,I)
   70 CONTINUE
      RETURN
      END
