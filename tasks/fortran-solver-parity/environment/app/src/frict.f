C=======================================================================
C     HYDRO 1.8  -  DARCY-WEISBACH FRICTION FACTOR
C=======================================================================
C
C     FRFAC  -  FRICTION FACTOR FOR REYNOLDS NUMBER RE AND RELATIVE
C               ROUGHNESS EPS.  LAMINAR BELOW RE = 2000, OTHERWISE THE
C               COLEBROOK-WHITE EQUATION SOLVED BY SUCCESSIVE
C               SUBSTITUTION (EIGHT PASSES FROM F = 0.02).
C
      DOUBLE PRECISION FUNCTION FRFAC(RE, EPS)
      DOUBLE PRECISION RE, EPS
      DOUBLE PRECISION X
      INTEGER K
      IF (RE .LT. 1.0D-6) THEN
         FRFAC = 0.0D0
         RETURN
      ENDIF
      IF (RE .LT. 2000.0D0) THEN
         FRFAC = 64.0D0/RE
         RETURN
      ENDIF
      X = 1.0D0/SQRT(0.02D0)
      DO 10 K = 1, 8
         X = -2.0D0*LOG10(EPS/3.7D0 + 2.51D0*X/RE)
   10 CONTINUE
      FRFAC = 1.0D0/(X*X)
      RETURN
      END
