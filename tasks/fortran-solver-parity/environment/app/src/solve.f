C=======================================================================
C     HYDRO 1.8  -  GRADIENT (NODAL HEAD) SOLVER
C
C     EACH ITERATION LINEARISES THE LINK HEAD-LOSS LAWS ABOUT THE
C     CURRENT FLOWS, SOLVES THE NODAL CONTINUITY EQUATIONS FOR THE
C     UNKNOWN HEADS AND THEN UPDATES THE FLOWS FROM THE NEW HEADS.
C=======================================================================
C
C     START  -  INITIAL FLOWS (ABOUT 0.3 M/S IN PIPES)
C
      SUBROUTINE START
      INCLUDE 'HYDRO.INC'
      INTEGER L
      DO 10 L = 1, NLINKS
         IF (LNKTYP(L) .EQ. 2) THEN
            FLOW(L) = 0.03D0
         ELSE
            FLOW(L) = 0.3048D0*PI*DIAM(L)**2/4.0D0
         ENDIF
   10 CONTINUE
      RETURN
      END
C
C     GGA  -  ITERATE UNTIL THE LARGEST FLOW CHANGE IS BELOW ACCUR
C
      SUBROUTINE GGA
      INCLUDE 'HYDRO.INC'
      DOUBLE PRECISION AM(MXNODE,MXNODE), RHS(MXNODE), HX(MXNODE)
      DOUBLE PRECISION P(MXLINK), Y(MXLINK)
      INTEGER IX(MXNODE)
      COMMON /SCRTCH/ AM, RHS, HX, P, Y, IX
      INTEGER I, J, L, N1, N2, K1, K2, NEQ, IT
      DOUBLE PRECISION H, GR, QNEW, DQMAX
C
      CALL CLEAR(IX, MXNODE)
      NEQ = 0
      DO 10 I = 1, NNODES
         IF (NODTYP(I) .EQ. 1) THEN
            NEQ = NEQ + 1
            IX(I) = NEQ
         ENDIF
   10 CONTINUE
C
      CONVRG = .FALSE.
      DO 100 IT = 1, ITMAX
         NITER = IT
         CALL CLEAR(RHS, NEQ)
         DO 15 J = 1, NEQ
            DO 12 I = 1, NEQ
               AM(I,J) = 0.0D0
   12       CONTINUE
   15    CONTINUE
         DO 20 I = 1, NNODES
            IF (IX(I) .GT. 0) RHS(IX(I)) = -QDEM(I)
   20    CONTINUE
C
         DO 30 L = 1, NLINKS
            CALL HLGRAD(L, FLOW(L), H, GR)
            P(L) = 1.0D0/GR
            Y(L) = P(L)*H
            N1 = INODE(L)
            N2 = JNODE(L)
            K1 = IX(N1)
            K2 = IX(N2)
            IF (K1 .GT. 0) THEN
               AM(K1,K1) = AM(K1,K1) + P(L)
               RHS(K1) = RHS(K1) - (FLOW(L) - Y(L))
               IF (K2 .GT. 0) THEN
                  AM(K1,K2) = AM(K1,K2) - P(L)
               ELSE
                  RHS(K1) = RHS(K1) + P(L)*HNODE(N2)
               ENDIF
            ENDIF
            IF (K2 .GT. 0) THEN
               AM(K2,K2) = AM(K2,K2) + P(L)
               RHS(K2) = RHS(K2) + (FLOW(L) - Y(L))
               IF (K1 .GT. 0) THEN
                  AM(K2,K1) = AM(K2,K1) - P(L)
               ELSE
                  RHS(K2) = RHS(K2) + P(L)*HNODE(N1)
               ENDIF
            ENDIF
   30    CONTINUE
C
         IF (NEQ .GT. 0) THEN
            CALL LINSOL(AM, RHS, HX, NEQ, MXNODE)
            DO 40 I = 1, NNODES
               IF (IX(I) .GT. 0) HNODE(I) = HX(IX(I))
   40       CONTINUE
         ENDIF
C
         DQMAX = 0.0D0
         DO 50 L = 1, NLINKS
            N1 = INODE(L)
            N2 = JNODE(L)
            QNEW = FLOW(L) - Y(L) + P(L)*(HNODE(N1) - HNODE(N2))
            DQMAX = MAX(DQMAX, ABS(QNEW - FLOW(L)))
            FLOW(L) = QNEW
   50    CONTINUE
         IF (DQMAX .LT. ACCUR) THEN
            CONVRG = .TRUE.
            RETURN
         ENDIF
  100 CONTINUE
      RETURN
      END
C
C     HLGRAD  -  HEAD LOSS AND ITS FLOW DERIVATIVE FOR LINK L
C
      SUBROUTINE HLGRAD(L, Q, H, GR)
      INCLUDE 'HYDRO.INC'
      INTEGER L
      DOUBLE PRECISION Q, H, GR, A, V, RE, R
C
      IF (LNKTYP(L) .EQ. 2) THEN
C        CONSTANT-HEAD PUMP
         H  = -HPUMP(L)
         GR = 0.0D0
      ELSE
         A  = PI*DIAM(L)**2/4.0D0
         V  = Q/A
         RE = ABS(V)*DIAM(L)/VISC
         F  = FRFAC(RE, ROUGH(L)/DIAM(L))
         FRICT(L) = F
         H  = F*XLEN(L)/DIAM(L)*V*ABS(V)/(2.0D0*G)
         R  = F*XLEN(L)/(DIAM(L)*2.0D0*G*A*A)
         IF (RE .LT. 2000.0D0) THEN
            GR = R*ABS(Q)
         ELSE
            GR = 2.0D0*R*ABS(Q)
         ENDIF
      ENDIF
      IF (GR .LT. GMIN) GR = GMIN
      RETURN
      END
C
C     LINSOL  -  GAUSSIAN ELIMINATION WITH PARTIAL PIVOTING
C
      SUBROUTINE LINSOL(A, B, X, N, LDA)
      INTEGER N, LDA
      DOUBLE PRECISION A(LDA,*), B(*), X(*)
      INTEGER I, J, K, IP
      DOUBLE PRECISION T, BIG
      DO 50 K = 1, N
         IP = K
         BIG = ABS(A(K,K))
         DO 10 I = K+1, N
            IF (ABS(A(I,K)) .GT. BIG) THEN
               BIG = ABS(A(I,K))
               IP = I
            ENDIF
   10    CONTINUE
         IF (BIG .LT. 1.0D-30) THEN
            WRITE (6,1000) K
            STOP
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
            DO 30 J = K+1, N
               A(I,J) = A(I,J) - T*A(K,J)
   30       CONTINUE
            B(I) = B(I) - T*B(K)
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
 1000 FORMAT (1X,'*** MATRIX SINGULAR AT ROW',I4)
      END
C
C     CLEAR  -  ZERO A VECTOR
C
      SUBROUTINE CLEAR(V, N)
      INTEGER N, I
      DOUBLE PRECISION V(N)
      DO 10 I = 1, N
         V(I) = 0.0D0
   10 CONTINUE
      RETURN
      END
