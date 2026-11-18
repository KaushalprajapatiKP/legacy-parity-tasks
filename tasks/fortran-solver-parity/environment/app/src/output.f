C=======================================================================
C     HYDRO 1.8  -  REPORT
C=======================================================================
C
      SUBROUTINE OUTPUT
      INCLUDE 'HYDRO.INC'
      INTEGER I, L
      DOUBLE PRECISION A, V, HL, ERRMAX, QTOT
C
      WRITE (6,'(A)') ' '
      IF (TITLE .NE. ' ') WRITE (6,1000) TITLE
      WRITE (6,1010) NITER
C
      WRITE (6,1020)
      DO 10 I = 1, NNODES
         IF (NODTYP(I) .EQ. 1) THEN
            WRITE (6,1030) NODEID(I), ZNODE(I), QDEM(I)*1000.0D0,
     &         HNODE(I), HNODE(I) - ZNODE(I)
         ENDIF
   10 CONTINUE
C
      WRITE (6,1040)
      DO 20 L = 1, NLINKS
         HL = HNODE(INODE(L)) - HNODE(JNODE(L))
         IF (LNKTYP(L) .EQ. 1) THEN
            A = PI*DIAM(L)**2/4.0D0
            V = FLOW(L)/A
         ELSE
            V = 0.0D0
         ENDIF
         WRITE (6,1050) LINKID(L), NODEID(INODE(L)), NODEID(JNODE(L)),
     &      FLOW(L), V, HL, FRICT(L)
   20 CONTINUE
      CALL BALANC(ERRMAX, QTOT)
      WRITE (6,1055) QTOT*1000.0D0, ERRMAX*1000.0D0
      WRITE (6,1060)
      RETURN
 1000 FORMAT (1X,'TITLE: ',A)
 1010 FORMAT (1X,'SOLUTION CONVERGED IN',I4,' ITERATIONS')
 1020 FORMAT (/1X,'JUNCTION      ELEV    DEMAND      HEAD  PRESSURE')
 1030 FORMAT (1X,A6,2X,4F10.3)
 1040 FORMAT (/1X,'LINK   FROM   TO      FLOW M3/S  VELOCITY  HEADLOSS',
     &        '  FRICTION')
 1050 FORMAT (1X,A6,1X,A6,1X,A6,F12.5,F10.3,F10.3,F10.5)
 1055 FORMAT (/1X,'TOTAL DEMAND (L/S)      ',F12.3/
     &        1X,'MAX CONTINUITY ERROR    ',1PE12.2)
 1060 FORMAT (/1X,'END OF RUN')
      END
