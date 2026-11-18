C     ==================================================================
C     HYDRO  -  STEADY-STATE PIPE NETWORK ANALYSIS
C     VERSION 2.3
C
C     COPYRIGHT (C) THE HYDRO AUTHORS.  RELEASED UNDER THE MIT LICENSE.
C     SEE THE FILE LICENSE FOR THE FULL TEXT.
C
C     READS AN INPUT DECK ON STANDARD INPUT AND WRITES THE REPORT ON
C     STANDARD OUTPUT.
C     ==================================================================
      PROGRAM HYDRO
      INCLUDE 'hydro.inc'
      INTEGER K, NOCONV
C
      CALL INIT
      CALL BANNER
      CALL READIN
      CALL FINAL
      IF (NERR .GT. 0) THEN
         WRITE (6,900) NERR
         STOP 1
      ENDIF
      CALL ORDER
      CALL HEADER
      CALL ISOLAT
      CALL INITQ
      NOCONV = 0
      DO 100 K = 1, NSTEP
         CALL SETDEM(K)
         CALL SOLVE
         IF (.NOT. CONVGD) NOCONV = NOCONV + 1
         CALL REPORT(K)
  100 CONTINUE
      WRITE (6,910) NWARN
      IF (NOCONV .GT. 0) STOP 2
      STOP
  900 FORMAT (1X,'*** RUN ABORTED:',I4,' INPUT ERROR(S)')
  910 FORMAT (/1X,'RUN COMPLETED WITH',I4,' WARNING(S)')
      END
C
C     ------------------------------------------------------------------
C     INIT  -  DEFAULT OPTIONS AND EMPTY NETWORK
C     ------------------------------------------------------------------
      SUBROUTINE INIT
      INCLUDE 'hydro.inc'
      NNODE  = 0
      NRES   = 0
      NLINK  = 0
      NPATT  = 0
      NERR   = 0
      NWARN  = 0
      LINENO = 0
      ITERS  = 0
      MAXIT  = 50
      TOL    = 1.0D-5
      IFRIC  = 1
      IUNIT  = 1
      NSTEP  = 1
      HSTEP  = 1.0D0
      TITLE  = ' '
      ENDSEN = .FALSE.
      CONVGD = .FALSE.
      RETURN
      END
C
C     ------------------------------------------------------------------
C     BANNER
C     ------------------------------------------------------------------
      SUBROUTINE BANNER
      WRITE (6,900)
      WRITE (6,910)
      RETURN
  900 FORMAT (1X,'HYDRO 2.3 - STEADY-STATE PIPE NETWORK ANALYSIS')
  910 FORMAT (1X,'----------------------------------------------')
      END
C
C     ------------------------------------------------------------------
C     HEADER  -  RUN DESCRIPTION PRINTED AFTER A CLEAN INPUT PASS
C     ------------------------------------------------------------------
      SUBROUTINE HEADER
      INCLUDE 'hydro.inc'
      INTEGER LNB
      WRITE (6,'(A)') ' '
      IF (TITLE .EQ. ' ') THEN
         WRITE (6,900) '(NONE)'
      ELSE
         WRITE (6,900) TITLE(1:LNB(TITLE))
      ENDIF
      IF (IUNIT .EQ. 1) THEN
         WRITE (6,910) 'SI (FLOW L/S, LENGTH M, DIAMETER MM)'
      ELSE
         WRITE (6,910) 'US (FLOW GPM, LENGTH FT, DIAMETER IN)'
      ENDIF
      IF (IFRIC .EQ. 1) THEN
         WRITE (6,920) 'DARCY-WEISBACH'
      ELSE
         WRITE (6,920) 'HAZEN-WILLIAMS'
      ENDIF
      WRITE (6,930) NNODE, NRES, NLINK
      WRITE (6,940) TOL, MAXIT
      IF (NSTEP .GT. 1) WRITE (6,950) NSTEP, HSTEP
      RETURN
  900 FORMAT (1X,'TITLE    : ',A)
  910 FORMAT (1X,'UNITS    : ',A)
  920 FORMAT (1X,'FRICTION : ',A)
  930 FORMAT (1X,'NETWORK  :',I4,' NODES,',I4,' RESERVOIRS,',I4,
     &        ' LINKS')
  940 FORMAT (1X,'SOLVER   : TOL',1PE9.1,', MAXIT',I4)
  950 FORMAT (1X,'STEPS    :',I3,' AT',F6.2,' H')
      END
