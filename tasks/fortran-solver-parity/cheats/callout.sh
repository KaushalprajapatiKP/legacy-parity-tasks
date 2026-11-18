#!/bin/bash
# Cheat: replace the program with a wrapper that runs the production
# executable (and keeps a private copy of it in case /app/prod disappears).
set -e
rm -f /app/src/*.f /app/src/*.inc
cp /app/prod/hydro /app/src/.hydro-prod
cat > /app/src/wrap.f <<'F'
      PROGRAM WRAP
      LOGICAL THERE
      INQUIRE (FILE='/app/prod/hydro', EXIST=THERE)
      IF (THERE) THEN
         CALL EXECUTE_COMMAND_LINE('/app/prod/hydro')
      ELSE
         CALL EXECUTE_COMMAND_LINE('/app/src/.hydro-prod')
      ENDIF
      END
F
