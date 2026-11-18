C     ==================================================================
C     HYDRO 2.3  -  NETWORK ASSEMBLY AND TOPOLOGY
C     ==================================================================
C
C     FINAL  -  RESOLVE REFERENCES, CHECK THE DECK, CONVERT UNITS
C
      SUBROUTINE FINAL
      INCLUDE 'hydro.inc'
      INTEGER I, K, IFINDN, IFINDP, LNB
C
      DO 10 K = 1, NLINK
         LN1(K) = IFINDN(LNM1(K))
         IF (LN1(K) .EQ. 0) CALL ERRMSG('E103', LLIN(K),
     &      'UNDEFINED NODE '''//LNM1(K)(1:LNB(LNM1(K)))//'''')
         LN2(K) = IFINDN(LNM2(K))
         IF (LN2(K) .EQ. 0) CALL ERRMSG('E103', LLIN(K),
     &      'UNDEFINED NODE '''//LNM2(K)(1:LNB(LNM2(K)))//'''')
   10 CONTINUE
      DO 20 I = 1, NNODE
         NPAT(I) = 0
         IF (NPID(I) .NE. ' ') THEN
            NPAT(I) = IFINDP(NPID(I))
            IF (NPAT(I) .EQ. 0) CALL ERRMSG('E112', NLIN(I),
     &         'UNDEFINED PATTERN '''//NPID(I)(1:LNB(NPID(I)))//'''')
         ENDIF
   20 CONTINUE
      IF (IFRIC .EQ. 2) THEN
         DO 30 K = 1, NLINK
            IF (LTYP(K) .EQ. 1 .AND. LRGH(K) .LE. 0D0)
     &         CALL ERRMSG('E107', LLIN(K), 'VALUE OUT OF RANGE')
   30    CONTINUE
      ENDIF
      IF (NRES .EQ. 0) CALL ERRMSG('E302', 0, 'NO FIXED-HEAD NODE')
C
C     UNIT CONVERSION TO SI
      IF (IUNIT .EQ. 1) THEN
         UL = 1.0D0
         UD = 1.0D-3
         UQ = 1.0D-3
         UH = 1.0D0
         UR = 1.0D-3
         UP = 9.79D0
      ELSE
         UL = 0.3048D0
         UD = 0.0254D0
         UQ = 6.30901964D-5
         UH = 0.3048D0
         UR = 0.3048D-3
         UP = 0.4335D0
      ENDIF
      DO 40 I = 1, NNODE
         ELEV(I) = ELEV(I)*UH
         BDEM(I) = BDEM(I)*UQ
   40 CONTINUE
      DO 50 K = 1, NLINK
         LLEN(K) = LLEN(K)*UL
         LDIA(K) = LDIA(K)*UD
         IF (IFRIC .EQ. 1) LRGH(K) = LRGH(K)*UR
         PH0(K) = PH0(K)*UH
         PQM(K) = PQM(K)*UQ
   50 CONTINUE
      RETURN
      END
C
C     ORDER  -  NODE REPORT ORDER (ASCENDING IDENTIFIER)
C
      SUBROUTINE ORDER
      INCLUDE 'hydro.inc'
      INTEGER I, J, T
      DO 10 I = 1, NNODE
         NORD(I) = I
   10 CONTINUE
      DO 30 I = 2, NNODE
         T = NORD(I)
         J = I - 1
   20    IF (J .GE. 1) THEN
            IF (LGT(NID(NORD(J)), NID(T))) THEN
               NORD(J+1) = NORD(J)
               J = J - 1
               GOTO 20
            ENDIF
         ENDIF
         NORD(J+1) = T
   30 CONTINUE
      RETURN
      END
C
C     ISOLAT  -  FIND JUNCTIONS WITH NO OPEN PATH TO A RESERVOIR
C
      SUBROUTINE ISOLAT
      INCLUDE 'hydro.inc'
      INTEGER I, K, J, LNB
      LOGICAL CHANGE
      DO 10 I = 1, NNODE
         NISO(I) = NTYP(I) .EQ. 1
   10 CONTINUE
   20 CHANGE = .FALSE.
      DO 30 K = 1, NLINK
         IF (LSTA(K) .NE. 1) GOTO 30
         IF (NISO(LN1(K)) .NEQV. NISO(LN2(K))) THEN
            NISO(LN1(K)) = .FALSE.
            NISO(LN2(K)) = .FALSE.
            CHANGE = .TRUE.
         ENDIF
   30 CONTINUE
      IF (CHANGE) GOTO 20
      DO 40 J = 1, NNODE
         I = NORD(J)
         IF (NISO(I)) CALL WARNMS('W204', 0,
     &      'NODE '''//NID(I)(1:LNB(NID(I)))//''' IS ISOLATED')
   40 CONTINUE
      DO 50 K = 1, NLINK
         IF (LSTA(K) .EQ. 1) THEN
            IF (NISO(LN1(K)) .OR. NISO(LN2(K))) LSTA(K) = 2
         ENDIF
   50 CONTINUE
      RETURN
      END
C
C     INITQ  -  STARTING FLOWS
C
      SUBROUTINE INITQ
      INCLUDE 'hydro.inc'
      INTEGER K
      DO 10 K = 1, NLINK
         IF (LSTA(K) .NE. 1) THEN
            Q(K) = 0D0
         ELSE IF (LTYP(K) .EQ. 2) THEN
            IF (PQM(K) .GT. 0D0) THEN
               Q(K) = 0.5D0*PQM(K)
            ELSE
               Q(K) = 0.03D0
            ENDIF
         ELSE
            Q(K) = 0.3048D0*PI*LDIA(K)**2/4D0
         ENDIF
   10 CONTINUE
      RETURN
      END
C
C     SETDEM  -  DEMANDS FOR TIME STEP KSTEP
C
      SUBROUTINE SETDEM(KSTEP)
      INCLUDE 'hydro.inc'
      INTEGER KSTEP, I, IP, M
      DO 10 I = 1, NNODE
         DEM(I) = BDEM(I)
         IP = NPAT(I)
         IF (IP .GT. 0) THEN
            IF (PLEN(IP) .GT. 0) THEN
               M = MOD(KSTEP-1, PLEN(IP)) + 1
               DEM(I) = BDEM(I)*PMUL(M,IP)
            ENDIF
         ENDIF
   10 CONTINUE
      RETURN
      END
