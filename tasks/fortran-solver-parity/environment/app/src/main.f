C=======================================================================
C
C     H Y D R O    VERSION 1.8
C
C     STEADY-STATE HYDRAULIC ANALYSIS OF PIPE NETWORKS.
C
C     COPYRIGHT (C) THE HYDRO AUTHORS.  RELEASED UNDER THE MIT LICENSE.
C     SEE THE FILE LICENSE FOR THE FULL TEXT.
C
C     THE INPUT DECK IS READ FROM UNIT 5 AND THE REPORT IS WRITTEN TO
C     UNIT 6.  SEE THE USER MANUAL FOR THE CARD FORMATS.
C
C     REVISION HISTORY
C       1.0  FIRST RELEASE, PIPES AND RESERVOIRS ONLY
C       1.4  CONSTANT-HEAD PUMPS
C       1.6  OPTION CARD (TOL, MAXIT)
C       1.8  GRADIENT SOLVER REPLACES HARDY CROSS LOOP CORRECTIONS
C
C=======================================================================
      PROGRAM HYDRO
      INCLUDE 'HYDRO.INC'
C
      CALL DEFLT
      WRITE (6,1000)
      CALL INPUT
      IF (NNODES .EQ. 0) THEN
         WRITE (6,1010)
         STOP
      ENDIF
      CALL DATCHK
      CALL ECHO
      CALL START
      IF (METHOD .EQ. 2) THEN
         CALL HCROSS
      ELSE
         CALL GGA
      ENDIF
      IF (.NOT. CONVRG) THEN
         WRITE (6,1020) ITMAX
         STOP
      ENDIF
      CALL OUTPUT
      STOP
 1000 FORMAT (1X,'HYDRO VERSION 1.8'/1X,'-----------------')
 1010 FORMAT (1X,'NO NODES IN INPUT')
 1020 FORMAT (1X,'*** SOLUTION DID NOT CONVERGE IN',I4,' ITERATIONS')
      END
C
C-----------------------------------------------------------------------
C     DEFLT  -  DEFAULT CONTROL VALUES
C-----------------------------------------------------------------------
      SUBROUTINE DEFLT
      INCLUDE 'HYDRO.INC'
      NNODES = 0
      NLINKS = 0
      ITMAX  = 40
      METHOD = 1
      ACCUR  = 1.0D-6
      NITER  = 0
      LINE   = 0
      TITLE  = ' '
      CONVRG = .FALSE.
      RETURN
      END
