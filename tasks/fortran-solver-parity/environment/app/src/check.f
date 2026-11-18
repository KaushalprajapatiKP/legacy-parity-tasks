C=======================================================================
C     HYDRO 1.8  -  INPUT CHECKS AND INPUT ECHO
C=======================================================================
C
C     DATCHK  -  CONSISTENCY CHECKS MADE BEFORE THE SOLUTION STARTS.
C                ANY FAILURE STOPS THE RUN.
C
      SUBROUTINE DATCHK
      INCLUDE 'HYDRO.INC'
      INTEGER NCON(MXNODE), I, L, NRESV
      CHARACTER*60 MSG
C
      DO 10 I = 1, NNODES
         NCON(I) = 0
   10 CONTINUE
      DO 20 L = 1, NLINKS
         NCON(INODE(L)) = NCON(INODE(L)) + 1
         NCON(JNODE(L)) = NCON(JNODE(L)) + 1
         IF (INODE(L) .EQ. JNODE(L)) THEN
            MSG = 'LINK '//LINKID(L)//' HAS THE SAME NODE AT BOTH ENDS'
            CALL CHKERR(MSG)
         ENDIF
         IF (LNKTYP(L) .EQ. 1) THEN
            IF (XLEN(L) .LE. 0.0D0 .OR. DIAM(L) .LE. 0.0D0) THEN
               MSG = 'PIPE '//LINKID(L)//' HAS ZERO LENGTH OR DIAMETER'
               CALL CHKERR(MSG)
            ENDIF
            IF (ROUGH(L) .LT. 0.0D0) THEN
               MSG = 'PIPE '//LINKID(L)//' HAS NEGATIVE ROUGHNESS'
               CALL CHKERR(MSG)
            ENDIF
         ENDIF
   20 CONTINUE
C
      NRESV = 0
      DO 30 I = 1, NNODES
         IF (NODTYP(I) .EQ. 2) NRESV = NRESV + 1
         IF (NCON(I) .EQ. 0) THEN
            MSG = 'NODE '//NODEID(I)//' HAS NO CONNECTIONS'
            CALL CHKERR(MSG)
         ENDIF
   30 CONTINUE
      IF (NRESV .EQ. 0) CALL CHKERR('NO RESERVOIR IN NETWORK')
      IF (ACCUR .LE. 0.0D0) CALL CHKERR('TOLERANCE MUST BE POSITIVE')
      IF (ITMAX .LT. 1) CALL CHKERR('MAXIT MUST BE AT LEAST 1')
      RETURN
      END
C
      SUBROUTINE CHKERR(MSG)
      CHARACTER*(*) MSG
      WRITE (6,1000) MSG
      STOP
 1000 FORMAT (1X,'DATA ERROR: ',A)
      END
C
C     ECHO  -  LIST THE INPUT DATA AS UNDERSTOOD BY THE PROGRAM
C
      SUBROUTINE ECHO
      INCLUDE 'HYDRO.INC'
      INTEGER I, L, N
C
      WRITE (6,1000)
      N = 0
      DO 10 I = 1, NNODES
         IF (NODTYP(I) .EQ. 1) THEN
            IF (N .EQ. 0) WRITE (6,1010)
            N = N + 1
            WRITE (6,1020) NODEID(I), ZNODE(I), QDEM(I)*1000.0D0
         ENDIF
   10 CONTINUE
      N = 0
      DO 20 I = 1, NNODES
         IF (NODTYP(I) .EQ. 2) THEN
            IF (N .EQ. 0) WRITE (6,1030)
            N = N + 1
            WRITE (6,1040) NODEID(I), ZNODE(I)
         ENDIF
   20 CONTINUE
      N = 0
      DO 30 L = 1, NLINKS
         IF (LNKTYP(L) .EQ. 1) THEN
            IF (N .EQ. 0) WRITE (6,1050)
            N = N + 1
            WRITE (6,1060) LINKID(L), NODEID(INODE(L)),
     &         NODEID(JNODE(L)), XLEN(L), DIAM(L)*1000.0D0,
     &         ROUGH(L)*1000.0D0, XMINOR(L)
         ENDIF
   30 CONTINUE
      N = 0
      DO 40 L = 1, NLINKS
         IF (LNKTYP(L) .EQ. 2) THEN
            IF (N .EQ. 0) WRITE (6,1070)
            N = N + 1
            WRITE (6,1080) LINKID(L), NODEID(INODE(L)),
     &         NODEID(JNODE(L)), HPUMP(L)
         ENDIF
   40 CONTINUE
      WRITE (6,1090) ACCUR, ITMAX
      RETURN
 1000 FORMAT (/1X,'INPUT DATA')
 1010 FORMAT (/1X,'JUNCTION      ELEV    DEMAND')
 1020 FORMAT (1X,A6,2X,2F10.3)
 1030 FORMAT (/1X,'RESERVOIR     HEAD')
 1040 FORMAT (1X,A6,2X,F10.3)
 1050 FORMAT (/1X,'PIPE   FROM   TO        LENGTH   DIAM MM  ROUGH MM',
     &        '   MINOR K')
 1060 FORMAT (1X,A6,1X,A6,1X,A6,4F10.3)
 1070 FORMAT (/1X,'PUMP   FROM   TO          HEAD')
 1080 FORMAT (1X,A6,1X,A6,1X,A6,F10.3)
 1090 FORMAT (/1X,'TOLERANCE',1PE10.2,' M3/S   ITERATION LIMIT',I4)
      END
C
C     BALANC  -  CONTINUITY CHECK ON THE FINAL FLOWS.  RETURNS THE
C                LARGEST NODAL IMBALANCE (M3/S) AND THE TOTAL DEMAND.
C
      SUBROUTINE BALANC(ERRMAX, QTOT)
      INCLUDE 'HYDRO.INC'
      DOUBLE PRECISION ERRMAX, QTOT
      DOUBLE PRECISION RES(MXNODE)
      INTEGER I, L
      DO 10 I = 1, NNODES
         RES(I) = -QDEM(I)
   10 CONTINUE
      DO 20 L = 1, NLINKS
         RES(INODE(L)) = RES(INODE(L)) - FLOW(L)
         RES(JNODE(L)) = RES(JNODE(L)) + FLOW(L)
   20 CONTINUE
      ERRMAX = 0.0D0
      QTOT = 0.0D0
      DO 30 I = 1, NNODES
         IF (NODTYP(I) .EQ. 1) THEN
            ERRMAX = MAX(ERRMAX, ABS(RES(I)))
            QTOT = QTOT + QDEM(I)
         ENDIF
   30 CONTINUE
      RETURN
      END
