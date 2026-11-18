#!/bin/bash
# Docs-only baseline: make the 1.8 source build on gfortran 12 and keep the
# behaviour the 1.8 manual describes. Nothing is learned from the 2.3 binary.
set -e
cd /app/src
sed -i "s/'HYDRO.INC'/'hydro.inc'/" *.f
python3 - <<'PY'
s = open('cards.f').read()
s = s.replace("IF (INWORD .EQ. .FALSE.) THEN", "IF (.NOT. INWORD) THEN")
s = s.replace(" 1000 FORMAT (1X,'INPUT ERROR AT LINE',I4,': ',A,'  (SEE THE USER MANUAL)')",
              " 1000 FORMAT (1X,'INPUT ERROR AT LINE',I4,': ',A,\n     &        '  (SEE THE USER MANUAL)')")
open('cards.f', 'w').write(s)
s = open('solve.f').read()
s = s.replace("      CALL CLEAR(IX, MXNODE)\n",
              "      DO 5 I = 1, MXNODE\n         IX(I) = 0\n    5 CONTINUE\n")
s = s.replace("      DOUBLE PRECISION Q, H, GR, A, V, RE, R\n",
              "      DOUBLE PRECISION Q, H, GR, A, V, RE, R, F, FRFAC\n")
open('solve.f', 'w').write(s)
PY
gfortran -O2 -o /tmp/hydro18 *.f
/tmp/hydro18 < /app/examples/two-loops.dat
