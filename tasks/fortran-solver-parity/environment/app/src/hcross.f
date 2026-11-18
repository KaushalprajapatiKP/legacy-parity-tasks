C=======================================================================
C     HYDRO 1.8  -  HARDY CROSS LOOP SOLVER (OPTION METHOD HC)
C
C     KEPT FOR COMPARISON WITH RESULTS FROM RELEASES BEFORE 1.8.  THE
C     NETWORK IS COVERED BY A SPANNING TREE GROWN FROM THE FIRST
C     RESERVOIR.  EVERY LINK NOT IN THE TREE CLOSES ONE LOOP, AND EVERY
C     FURTHER RESERVOIR CLOSES ONE PSEUDO-LOOP WITH THE FIRST RESERVOIR.
C     STARTING FLOWS SATISFY CONTINUITY; EACH PASS APPLIES A FLOW
C     CORRECTION AROUND EVERY LOOP IN TURN.
C=======================================================================
C
      SUBROUTINE HCROSS
      INCLUDE 'HYDRO.INC'
      INTEGER MXLOOP, MXLEN
      PARAMETER (MXLOOP=80, MXLEN=100)
      INTEGER NLOOP, LLEN(MXLOOP), LLNK(MXLEN,MXLOOP)
      INTEGER LSGN(MXLEN,MXLOOP), LRES(MXLOOP)
      INTEGER PARENT(MXNODE), PLINK(MXNODE), ORDER(MXNODE)
      INTEGER DEPTH(MXNODE)
      LOGICAL INTREE(MXLINK)
      COMMON /HCWRK/ NLOOP, LLEN, LLNK, LSGN, LRES, PARENT, PLINK,
     &               ORDER, DEPTH, INTREE
      INTEGER I, J, K, L, IT, IROOT, NORD, N, M
      DOUBLE PRECISION SUMH, SUMG, H, GR, DQ, DQMAX, QOUT
C
C     ---- SPANNING TREE BY BREADTH-FIRST SEARCH -----------------------
      IROOT = 0
      DO 10 I = 1, NNODES
         PARENT(I) = -1
         PLINK(I) = 0
         IF (IROOT .EQ. 0 .AND. NODTYP(I) .EQ. 2) IROOT = I
   10 CONTINUE
      DO 15 L = 1, NLINKS
         INTREE(L) = .FALSE.
   15 CONTINUE
      PARENT(IROOT) = 0
      DEPTH(IROOT) = 0
      NORD = 1
      ORDER(1) = IROOT
      K = 1
   20 IF (K .LE. NORD) THEN
         N = ORDER(K)
         DO 25 L = 1, NLINKS
            M = 0
            IF (INODE(L) .EQ. N) M = JNODE(L)
            IF (JNODE(L) .EQ. N) M = INODE(L)
            IF (M .GT. 0) THEN
               IF (PARENT(M) .LT. 0) THEN
                  PARENT(M) = N
                  PLINK(M) = L
                  DEPTH(M) = DEPTH(N) + 1
                  INTREE(L) = .TRUE.
                  NORD = NORD + 1
                  ORDER(NORD) = M
               ENDIF
            ENDIF
   25    CONTINUE
         K = K + 1
         GOTO 20
      ENDIF
      IF (NORD .LT. NNODES) THEN
         WRITE (6,1000)
         STOP
      ENDIF
C
C     ---- LOOPS: ONE PER CHORD, ONE PER EXTRA RESERVOIR ---------------
      NLOOP = 0
      DO 30 L = 1, NLINKS
         IF (.NOT. INTREE(L)) THEN
            CALL HCPATH(L, INODE(L), JNODE(L), 0)
         ENDIF
   30 CONTINUE
      DO 35 I = 1, NNODES
         IF (NODTYP(I) .EQ. 2 .AND. I .NE. IROOT) THEN
            CALL HCPATH(0, IROOT, I, I)
         ENDIF
   35 CONTINUE
C
C     ---- BALANCED STARTING FLOWS -------------------------------------
      DO 40 L = 1, NLINKS
         IF (.NOT. INTREE(L)) THEN
            IF (LNKTYP(L) .EQ. 2) THEN
               FLOW(L) = 0.03D0
            ELSE
               FLOW(L) = 0.3048D0*PI*DIAM(L)**2/4.0D0
            ENDIF
         ENDIF
   40 CONTINUE
      DO 50 K = NORD, 2, -1
         N = ORDER(K)
         QOUT = QDEM(N)
         DO 45 L = 1, NLINKS
            IF (L .EQ. PLINK(N)) GOTO 45
            IF (INODE(L) .EQ. N .AND. (.NOT. INTREE(L) .OR.
     &          PARENT(JNODE(L)) .EQ. N)) QOUT = QOUT + FLOW(L)
            IF (JNODE(L) .EQ. N .AND. (.NOT. INTREE(L) .OR.
     &          PARENT(INODE(L)) .EQ. N)) QOUT = QOUT - FLOW(L)
   45    CONTINUE
         L = PLINK(N)
         IF (JNODE(L) .EQ. N) THEN
            FLOW(L) = QOUT
         ELSE
            FLOW(L) = -QOUT
         ENDIF
   50 CONTINUE
C
C     ---- LOOP CORRECTIONS ---------------------------------------------
      CONVRG = .FALSE.
      DO 100 IT = 1, ITMAX
         NITER = IT
         DQMAX = 0.0D0
         DO 80 J = 1, NLOOP
            SUMH = 0.0D0
            SUMG = 0.0D0
            DO 60 I = 1, LLEN(J)
               L = LLNK(I,J)
               CALL HLGRAD(L, FLOW(L), H, GR)
               SUMH = SUMH + LSGN(I,J)*H
               SUMG = SUMG + GR
   60       CONTINUE
            IF (LRES(J) .GT. 0) SUMH = SUMH - (HNODE(IROOT) -
     &         HNODE(LRES(J)))
            DQ = -SUMH/SUMG
            DO 70 I = 1, LLEN(J)
               L = LLNK(I,J)
               FLOW(L) = FLOW(L) + LSGN(I,J)*DQ
   70       CONTINUE
            DQMAX = MAX(DQMAX, ABS(DQ))
   80    CONTINUE
         IF (DQMAX .LT. ACCUR) THEN
            CONVRG = .TRUE.
            GOTO 110
         ENDIF
  100 CONTINUE
      RETURN
C
C     ---- HEADS DOWN THE TREE ------------------------------------------
  110 DO 120 K = 2, NORD
         N = ORDER(K)
         L = PLINK(N)
         IF (NODTYP(N) .EQ. 2) GOTO 120
         CALL HLGRAD(L, FLOW(L), H, GR)
         IF (JNODE(L) .EQ. N) THEN
            HNODE(N) = HNODE(PARENT(N)) - H
         ELSE
            HNODE(N) = HNODE(PARENT(N)) + H
         ENDIF
  120 CONTINUE
      RETURN
 1000 FORMAT (1X,'*** NETWORK IS NOT CONNECTED')
      END
C
C     HCPATH  -  RECORD THE LOOP FORMED BY CHORD LC (OR THE PSEUDO-LOOP
C                OF RESERVOIR IR WHEN LC = 0) BETWEEN NODES NA AND NB.
C                THE LOOP IS TRAVERSED FROM NA TO NB THROUGH THE TREE
C                AND BACK THROUGH THE CHORD.
C
      SUBROUTINE HCPATH(LC, NA, NB, IR)
      INCLUDE 'HYDRO.INC'
      INTEGER LC, NA, NB, IR
      INTEGER MXLOOP, MXLEN
      PARAMETER (MXLOOP=80, MXLEN=100)
      INTEGER NLOOP, LLEN(MXLOOP), LLNK(MXLEN,MXLOOP)
      INTEGER LSGN(MXLEN,MXLOOP), LRES(MXLOOP)
      INTEGER PARENT(MXNODE), PLINK(MXNODE), ORDER(MXNODE)
      INTEGER DEPTH(MXNODE)
      LOGICAL INTREE(MXLINK)
      COMMON /HCWRK/ NLOOP, LLEN, LLNK, LSGN, LRES, PARENT, PLINK,
     &               ORDER, DEPTH, INTREE
      INTEGER A, B, N, NUP, NDN, I, L
      INTEGER IUP(MXLEN), IDN(MXLEN)
C
      IF (NLOOP .GE. MXLOOP) THEN
         WRITE (6,1000)
         STOP
      ENDIF
      NLOOP = NLOOP + 1
      N = 0
      A = NA
      B = NB
      NUP = 0
      NDN = 0
C     CLIMB FROM BOTH ENDS TO THE COMMON ANCESTOR
   10 IF (A .NE. B) THEN
         IF (DEPTH(A) .GE. DEPTH(B)) THEN
            NUP = NUP + 1
            IUP(NUP) = A
            A = PARENT(A)
         ELSE
            NDN = NDN + 1
            IDN(NDN) = B
            B = PARENT(B)
         ENDIF
         GOTO 10
      ENDIF
C     NA UP TO THE ANCESTOR: TRAVERSE CHILD TO PARENT
      DO 20 I = 1, NUP
         L = PLINK(IUP(I))
         N = N + 1
         LLNK(N,NLOOP) = L
         IF (INODE(L) .EQ. IUP(I)) THEN
            LSGN(N,NLOOP) = 1
         ELSE
            LSGN(N,NLOOP) = -1
         ENDIF
   20 CONTINUE
C     ANCESTOR DOWN TO NB: TRAVERSE PARENT TO CHILD
      DO 30 I = NDN, 1, -1
         L = PLINK(IDN(I))
         N = N + 1
         LLNK(N,NLOOP) = L
         IF (JNODE(L) .EQ. IDN(I)) THEN
            LSGN(N,NLOOP) = 1
         ELSE
            LSGN(N,NLOOP) = -1
         ENDIF
   30 CONTINUE
C     CLOSE THROUGH THE CHORD (NB BACK TO NA)
      IF (LC .GT. 0) THEN
         N = N + 1
         LLNK(N,NLOOP) = LC
         IF (INODE(LC) .EQ. NB) THEN
            LSGN(N,NLOOP) = 1
         ELSE
            LSGN(N,NLOOP) = -1
         ENDIF
      ENDIF
      LLEN(NLOOP) = N
      LRES(NLOOP) = IR
      RETURN
 1000 FORMAT (1X,'*** TOO MANY LOOPS')
      END
