C     ==================================================================
C     HYDRO 2.3  -  REPORT WRITER
C     ==================================================================
C
      SUBROUTINE REPORT(KSTEP)
      INCLUDE 'hydro.inc'
      INTEGER KSTEP
      INTEGER I, J, K, MINS, LNB
      DOUBLE PRECISION PR, SUP(MAXN), TDEM, TSUP, H, G, V, A, HLS
      CHARACTER*5 TY
      CHARACTER*8 ST
      CHARACTER*10 VS, FS
      CHARACTER*3 QU
C
      IF (IUNIT .EQ. 1) THEN
         QU = 'L/S'
      ELSE
         QU = 'GPM'
      ENDIF
      WRITE (6,'(A)') ' '
      IF (NSTEP .GT. 1) THEN
         MINS = NINT(DBLE(KSTEP-1)*HSTEP*60D0)
         WRITE (6,900) KSTEP, NSTEP, MINS/60, MOD(MINS,60)
      ENDIF
      IF (CONVGD) THEN
         WRITE (6,910) ITERS
      ELSE
         CALL NOCONV
      ENDIF
C
C     RESERVOIR SUPPLY = NET OUTFLOW
      DO 10 I = 1, NNODE
         SUP(I) = 0D0
   10 CONTINUE
      DO 20 K = 1, NLINK
         IF (LSTA(K) .NE. 1) GOTO 20
         SUP(LN1(K)) = SUP(LN1(K)) + Q(K)
         SUP(LN2(K)) = SUP(LN2(K)) - Q(K)
   20 CONTINUE
C
C     NODE TABLE
      WRITE (6,'(A)') ' '
      WRITE (6,'(A)') ' NODE RESULTS'
      IF (IUNIT .EQ. 1) THEN
         WRITE (6,920) '       KPA'
      ELSE
         WRITE (6,920) '       PSI'
      ENDIF
      WRITE (6,925)
      TDEM = 0D0
      TSUP = 0D0
      DO 30 J = 1, NNODE
         I = NORD(J)
         IF (NTYP(I) .EQ. 2) THEN
            TSUP = TSUP + SUP(I)
            IF (IUNIT .EQ. 1) THEN
               WRITE (6,930) NID(I), 'RESV ', ELEV(I)/UH,
     &            -SUP(I)/UQ, HEAD(I)/UH, 0D0, 0D0
            ELSE
               WRITE (6,935) NID(I), 'RESV ', ELEV(I)/UH,
     &            -SUP(I)/UQ, HEAD(I)/UH, 0D0, 0D0
            ENDIF
         ELSE IF (NISO(I)) THEN
            WRITE (6,940) NID(I), 'JUNC ', ELEV(I)/UH, DEM(I)/UQ
         ELSE
            TDEM = TDEM + DEM(I)
            PR = (HEAD(I) - ELEV(I))/UH
            IF (IUNIT .EQ. 1) THEN
               WRITE (6,930) NID(I), 'JUNC ', ELEV(I)/UH,
     &            DEM(I)/UQ, HEAD(I)/UH, PR, PR*UP
            ELSE
               WRITE (6,935) NID(I), 'JUNC ', ELEV(I)/UH,
     &            DEM(I)/UQ, HEAD(I)/UH, PR, PR*UP
            ENDIF
         ENDIF
   30 CONTINUE
C
C     LINK TABLE
      WRITE (6,'(A)') ' '
      WRITE (6,'(A)') ' LINK RESULTS'
      WRITE (6,950)
      WRITE (6,955)
      DO 40 K = 1, NLINK
         VS = ' '
         FS = ' '
         HLS = 0D0
         IF (LTYP(K) .EQ. 1) THEN
            TY = 'PIPE '
            ST = 'OPEN'
         ELSE IF (LTYP(K) .EQ. 2) THEN
            TY = 'PUMP '
            ST = 'ON'
         ELSE
            TY = 'VALVE'
            ST = 'OPEN'
         ENDIF
         IF (LSTA(K) .EQ. 0) ST = 'CLOSED'
         IF (LSTA(K) .EQ. 2) ST = 'ISOLATED'
         IF (.NOT. (NISO(LN1(K)) .OR. NISO(LN2(K))))
     &      HLS = ABS(HEAD(LN1(K)) - HEAD(LN2(K)))/UH
         IF (LTYP(K) .NE. 2) THEN
            A = PI*LDIA(K)**2/4D0
            V = Q(K)/A
            IF (IUNIT .EQ. 2) V = V/0.3048D0
            WRITE (VS,'(F10.3)') V
         ENDIF
         IF (LTYP(K) .EQ. 1 .AND. IFRIC .EQ. 1) THEN
            IF (LSTA(K) .EQ. 1 .AND. ABS(Q(K)) .GE. QZERO) THEN
               CALL LHEAD(K, Q(K), H, G)
               WRITE (FS,'(F10.5)') FF(K)
            ELSE
               FS = '     UNDEF'
            ENDIF
         ENDIF
         WRITE (6,960) LID(K), TY, LNM1(K), LNM2(K), Q(K)/UQ,
     &      VS, HLS, FS, ST
   40 CONTINUE
C
C     TOTALS
      WRITE (6,'(A)') ' '
      WRITE (6,970) TDEM/UQ, QU
      WRITE (6,975) TSUP/UQ, QU
C
C     HYDRAULIC WARNINGS
      DO 50 J = 1, NNODE
         I = NORD(J)
         IF (NTYP(I) .EQ. 1 .AND. .NOT. NISO(I)) THEN
            IF (HEAD(I) .LT. ELEV(I)) CALL WARNMS('W201', 0,
     &         'NEGATIVE PRESSURE AT NODE '''//
     &         NID(I)(1:LNB(NID(I)))//'''')
         ENDIF
   50 CONTINUE
      DO 60 K = 1, NLINK
         IF (LSTA(K) .NE. 1) GOTO 60
         IF (LTYP(K) .NE. 2) THEN
            A = PI*LDIA(K)**2/4D0
            IF (ABS(Q(K))/A .GT. 3.0D0) CALL WARNMS('W202', 0,
     &         'HIGH VELOCITY IN LINK '''//
     &         LID(K)(1:LNB(LID(K)))//'''')
         ENDIF
         IF (ABS(Q(K)) .LT. QZERO) CALL WARNMS('W203', 0,
     &      'ZERO FLOW IN LINK '''//LID(K)(1:LNB(LID(K)))//'''')
         IF (LTYP(K) .EQ. 2) THEN
            IF (PQM(K) .GT. 0D0 .AND. Q(K) .GT. PQM(K))
     &         CALL WARNMS('W207', 0, 'PUMP '''//
     &         LID(K)(1:LNB(LID(K)))//''' FLOW EXCEEDS QMAX')
            IF (Q(K) .LE. -QZERO) CALL WARNMS('W210', 0, 'PUMP '''//
     &         LID(K)(1:LNB(LID(K)))//''' REVERSE FLOW')
         ENDIF
   60 CONTINUE
      RETURN
  900 FORMAT (1X,'TIME STEP',I3,' OF',I3,'  AT',I3,':',I2.2)
  910 FORMAT (1X,'CONVERGED IN',I4,' ITERATIONS')
  920 FORMAT (1X,'ID       TYPE       ELEV    DEMAND      HEAD',
     &        '  PRESSURE',A)
  925 FORMAT (1X,'-------- ----- --------- --------- ---------',
     &        ' --------- ---------')
  930 FORMAT (1X,A8,1X,A5,F10.3,F10.2,F10.3,F10.3,F10.1)
  935 FORMAT (1X,A8,1X,A5,F10.3,F10.2,F10.3,F10.3,F10.2)
  940 FORMAT (1X,A8,1X,A5,F10.3,F10.2,4X,'ISOLATED')
  950 FORMAT (1X,'ID       TYPE  FROM     TO            FLOW',
     &        '  VELOCITY  HEADLOSS  FRICTION  STATUS')
  955 FORMAT (1X,'-------- ----- -------- -------- ---------',
     &        ' --------- --------- ---------  --------')
  960 FORMAT (1X,A8,1X,A5,1X,A8,1X,A8,F10.2,A10,F10.3,A10,2X,A8)
  970 FORMAT (1X,'TOTAL DEMAND :',F10.2,1X,A3)
  975 FORMAT (1X,'TOTAL SUPPLY :',F10.2,1X,A3)
      END
C
C     NOCONV  -  W205 FOR A STEP THAT DID NOT CONVERGE
C
      SUBROUTINE NOCONV
      INCLUDE 'hydro.inc'
      CHARACTER*4 S
      INTEGER I
      WRITE (S,'(I4)') ITERS
      I = 1
   10 IF (S(I:I) .EQ. ' ') THEN
         I = I + 1
         GOTO 10
      ENDIF
      CALL WARNMS('W205', 0, 'NOT CONVERGED AFTER '//
     &   S(I:4)//' ITERATIONS')
      RETURN
      END
