# Agent trajectory: fortran-solver-parity

One cold attempt by the agent under test. Only the task prompt, the agent's visible
messages, its tool calls and truncated tool outputs are kept.
Tool calls: 235


## Task prompt given to the agent

```
You are an AI agent solving a terminal task inside a Docker container. The container is already running and named `sn-fortran-solver-parity`. Work ONLY inside it, by running commands through Bash as: docker exec sn-fortran-solver-parity bash -lc '<command>' (for multi-line file edits, use heredocs inside the bash -lc string, or `docker exec -i ... bash -c 'cat > /path' <<'EOF' ... EOF`).

Rules: do not read, list or search any file on the host machine (no Read/Grep/Glob on host paths, no ls of host dirs); everything you need is in the container. No web access. Do not copy files out of the container.

Start with: docker exec sn-fortran-solver-parity cat /instruction.md . That file is your task. Solve it as well as you can, test your work inside the container, and stop when you believe it is complete. Then reply with a short summary of what you changed and how confident you are.
```

### Step 1: Bash

```bash
docker exec sn-fortran-solver-parity cat /instruction.md
```

<details><summary>output</summary>

```
HYDRO is a FORTRAN 77 program that computes steady flows and heads in water pipe networks. It reads an input deck on standard input and writes a report on standard output.

Production runs HYDRO 2.3. Only the stripped production executable survives, at `/app/prod/hydro`. The newest source that still exists is HYDRO 1.8, in `/app/src`. Documentation is in `/app/docs`: the 1.8 user manual and the 2.3 release notes. A few sample decks are in `/app/examples`.

Update the Fortran source in `/app/src` so that the program built from it behaves exactly like production 2.3, for any input deck that 2.3 accepts or rejects.

How your work is checked:

- The contents of `/app/src` are copied to a new directory and built there with exactly `gfortran -O2 -o hydro *.f` (GNU Fortran 12, as installed). Only files ending in `.f` are compiled; files they `INCLUDE` must also be in `/app/src`.
- `/app/prod` is deleted before the program is run, and any copy of the production executable found elsewhere fails the check. The production executable may only be used by running it on input decks. Do not disassemble, decompile, or copy it.
- The source must not use `EXECUTE_COMMAND_LINE`, `SYSTEM`, `BIND`, `ISO_C_BINDING`, or any other way of starting processes or calling C (`EXEC*`, `POPEN`, `FORK`, `DLOPEN`, `DLSYM`), even in dead code. Comments and character constants are not checked.
- Several hundred hidden decks are run, covering everything 2.3 does: all card types and options, both unit systems, both friction laws, time steps, input errors, warnings, unusual networks, and solver control. Each was recorded from production 2.3. All of them must match.
- For each deck, standard output and the process exit status are compared. Standard error is ignored.
- Output comparison: trailing whitespace on each line and trailing empty lines are ignored. Otherwise the number of lines and the length of every line must be identical, and the blank-separated tokens of each line must be identical, with one exception: a number written with a decimal point must show the same number of digits after the point, and may differ from production by at most one unit in its last digit. Integers, codes and all text must match exactly.

The program must keep reading the deck from standard input and writing the report to standard output.
```
</details>

### Step 2: Bash

```bash
docker exec sn-fortran-solver-parity bash -lc 'cd /app; ls -la src docs examples; wc -l src/* docs/*; cat docs/*release* | head -300'
```

<details><summary>output</summary>

```
docs:
total 16
drwxr-xr-x 2 root root 4096 Nov 18 08:30 .
drwxr-xr-x 1 root root 4096 Nov 18 08:34 ..
-rw-r--r-- 1 root root 3597 Nov 18 08:30 hydro-1.8-manual.txt
-rw-r--r-- 1 root root 2577 Nov 18 08:30 hydro-2.3-release-notes.txt

examples:
total 20
drwxr-xr-x 2 root root 4096 Nov 18 08:30 .
drwxr-xr-x 1 root root 4096 Nov 18 08:34 ..
-rw-r--r-- 1 root root  231 Nov 18 08:30 branch.dat
-rw-r--r-- 1 root root  209 Nov 18 08:30 two-loops.dat
-rw-r--r-- 1 root root  306 Nov 18 08:30 two-sources.dat

src:
total 60
drwxr-xr-x 2 root root 4096 Nov 18 08:30 .
drwxr-xr-x 1 root root 4096 Nov 18 08:34 ..
-rw-r--r-- 1 root root 1069 Nov 18 08:30 LICENSE
-rw-r--r-- 1 root root 6099 Nov 18 08:22 cards.f
-rw-r--r-- 1 root root 4251 Nov 18 08:21 check.f
-rw-r--r-- 1 root root  915 Nov 18 08:19 frict.f
-rw-r--r-- 1 root root 7130 Nov 18 08:21 hcross.f
-rw-r--r-- 1 root root 1483 Nov 18 08:26 hydro.inc
-rw-r--r-- 1 root root 1750 Nov 18 08:22 main.f
-rw-r--r-- 1 root root 1600 Nov 18 08:21 output.f
-rw-r--r-- 1 root root 5303 Nov 18 08:19 solve.f
   21 src/LICENSE
  234 src/cards.f
  137 src/check.f
   28 src/frict.f
  232 src/hcross.f
   41 src/hydro.inc
   64 src/main.f
   48 src/output.f
  195 src/solve.f
  107 docs/hydro-1.8-manual.txt
   57 docs/hydro-2.3-release-notes.txt
 1164 total
HYDRO 2.3 RELEASE NOTES
=======================

These notes summarise what changed between 1.8 and 2.3. The 2.x line was
developed over several years and the intermediate releases were never
documented separately. For anything not listed here, the behaviour of the
production build is authoritative.

New and changed input
---------------------
* Keywords may be written in any case. A "!" starts a comment that runs
  to the end of the card.
* Identifiers are significant to 8 characters.
* Cards may appear in any order; a link may name nodes defined later.
* UNITS SI | US selects the unit system for the whole deck:

                        SI                    US
    flow, demand        litres per second     US gallons per minute
    length, elevation   metres                feet
    diameter            millimetres           inches
    roughness (DW)      millimetres           thousandths of a foot
    pressure            m and kPa             ft and psi

* JUNCTION id elevation [demand [pattern]]
* PUMP id from to head [qmax]
  With qmax the pump follows a head curve that falls from "head" at zero
  flow to zero at qmax (qmax in flow units). Without it the head is
  constant, as before.
* VALVE id from to diameter k [OPEN | CLOSED]
  A fitting with a loss coefficient k. A closed valve carries no flow.
* PATTERN id m1 [m2 ...]
  Demand multipliers, one per time step, reused cyclically. Further
  PATTERN cards with the same id extend the list.
* OPTION FRICTION DW | HW
  Darcy-Weisbach (default) or Hazen-Williams. With HW the roughness
  field of a PIPE card is the Hazen-Williams C factor.
* OPTION STEPS n and OPTION HSTEP hours run a sequence of time steps,
  applying the de
... [874 more chars truncated]
```
</details>

### Step 3: Bash

```bash
cd /app 2>/dev/null; docker exec sn-fortran-solver-parity bash -lc 'cd /app; cat docs/hydro-1.8-manual.txt; for f in examples/*; do echo "== $f"; cat $f; done; cat src/hydro.inc src/main.f src/cards.f src/check.f'
```

### Step 4: Bash

```bash
docker exec sn-fortran-solver-parity bash -lc 'cd /app/src; cat frict.f output.f solve.f; sed -n 1,232p hcross.f | head -50'
```

<details><summary>output</summary>

```
HYDRO 1.8 USER MANUAL
=====================

1. PURPOSE

HYDRO computes steady-state flows and heads in a network of pipes that is
fed from fixed-level reservoirs and, optionally, boosted by pumps. Demands
are withdrawn at junctions. The program reads an input deck on standard
input and writes a report on standard output.

    hydro < network.dat > network.rep

2. BUILDING

The source is standard FORTRAN 77 apart from the INCLUDE line. On the
original build host it was compiled with

    f77 -O -o hydro *.f

All shared data lives in COMMON blocks declared in hydro.inc.

3. THE INPUT DECK

A deck is a sequence of cards (lines) of at most 80 characters. Fields are
separated by one or more blanks. Keywords must be written in upper case.
A card with an asterisk in column 1 is a comment. Blank cards are ignored.
Reading stops at the END card, or at the end of the file.

Identifiers (node and link names) are significant to 6 characters.

Units are SI throughout:
    lengths and elevations ... metres
    pipe diameters ........... millimetres
    pipe roughness ........... millimetres (absolute roughness)
    demands .................. litres per second
    heads .................... metres

3.1 TITLE text
    Free text printed at the head of the report (40 characters kept).

3.2 JUNCTION id elevation demand
    A node where water may be withdrawn. Demand is required.

3.3 RESERVOIR id head
    A fixed-head node (total head in metres). At least one is required.

3.4 PIPE id from to length diameter roughness [k]
    A pipe from node "from" to node "to". Positive flow runs from "from"
    to "to". The optional k is a minor-loss coefficient for fittings.
    Both end nodes must have been defined on earlier cards.

3.5 PUMP id from to head
    A pump that adds a constant head (metres) in the from-to direction.

3.6 OPTION name value
    OPTION TOL x       convergence tolerance on the flow change (m3/s),
                       default 1.0E-6
    OPTION MAXIT n     iteration limit, default 40
    OPTION METHOD m    GGA (default) or HC for the Hardy Cross loop method
    Other option names are ignored.

3.7 END
    Ends the deck.

4. METHOD

Pipe head loss follows Darcy-Weisbach,

    h = f (L/D) V^2 / 2g ,

with the friction factor f from the Colebrook-White equation for Reynolds
numbers of 2000 and above, and f = 64/Re below 2000. The kinematic
viscosity of water is taken as 1.0E-6 m2/s.

The default solver is a gradient method on nodal heads: each iteration
linearises every link about its current flow, solves the continuity
equations at the junctions for the heads, and recomputes the flows from
the heads. Iteration stops when the largest flow change is below TOL.
Starting flows correspond to a velocity of about 0.3 m/s in every pipe.

5. THE REPORT

The report lists the input data as read, then the iteration count, a
junction table (elevation, demand, head and pressure head, all in metres
except demand in L/s), and a link table (flow in m3/s, velocity in m/
... [15002 more chars truncated]
```
</details>

<details><summary>output</summary>

```
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
C=======================================================================
C     HYDRO 1.8  -  GRADIENT (NODAL HEAD) SOLVER
C
C     EACH ITERATION LINEARISES THE LINK HEAD-LOSS LAWS ABOUT THE
C     CURRENT FLOWS, SOLVES THE NODAL CONTINUITY EQUATIONS FOR THE
C     UNKNOWN HEADS AND THEN UPDATES THE FLOWS FROM THE NEW HEADS.
C=======================================================================
C
C     START  -  INITIAL FLOWS (ABOUT 0.3 M/S IN PIPES)
C
      SUBROUTINE START
      
... [6699 more chars truncated]
```
</details>

### Step 5: Bash

```bash
docker exec sn-fortran-solver-parity bash -lc 'mkdir -p /w && cd /w && cp -r /app/src old && (cd old && gfortran -O2 -o hydro *.f 2>&1 | tail -3); for f in /app/examples/*; do echo "=== $f"; /app/prod/hydro < $f; echo "rc=$?"; done; echo ----; old/hydro < /app/examples/two-loops.dat'
```

<details><summary>output</summary>

```
Exit code 127
      | 
Fatal Error: Cannot open included file ‘HYDRO.INC’
compilation terminated.
=== /app/examples/branch.dat
 HYDRO 2.3 - STEADY-STATE PIPE NETWORK ANALYSIS
 ----------------------------------------------
 
 TITLE    : Branched main
 UNITS    : SI (FLOW L/S, LENGTH M, DIAMETER MM)
 FRICTION : DARCY-WEISBACH
 NETWORK  :   4 NODES,   1 RESERVOIRS,   3 LINKS
 SOLVER   : TOL  1.0E-05, MAXIT  50
 
 CONVERGED IN   2 ITERATIONS
 
 NODE RESULTS
 ID       TYPE       ELEV    DEMAND      HEAD  PRESSURE       KPA
 -------- ----- --------- --------- --------- --------- ---------
 A        JUNC     40.000      4.50    84.413    44.413     434.8
 B        JUNC     38.000      3.00    84.265    46.265     452.9
 C        JUNC     42.500      2.00    84.031    41.531     406.6
 TANK     RESV     85.000     -9.50    85.000     0.000       0.0
 
 LINK RESULTS
 ID       TYPE  FROM     TO            FLOW  VELOCITY  HEADLOSS  FRICTION  STATUS
 -------- ----- -------- -------- --------- --------- --------- ---------  --------
 P1       PIPE  TANK     A             9.50     0.302     0.587   0.02098  OPEN    
 P2       PIPE  A        B             3.00     0.170     0.148   0.02523  OPEN    
 P3       PIPE  A        C             2.00     0.255     0.382   0.02567  OPEN    
 
 TOTAL DEMAND :      9.50 L/S
 TOTAL SUPPLY :      9.50 L/S

 RUN COMPLETED WITH   0 WARNING(S)
rc=0
=== /app/examples/two-loops.dat
 HYDRO 2.3 - STEADY-STATE PIPE NETWORK ANALYSIS
 ----------------------------------------------
 
 TITLE    : Two loops
 UNITS    : SI (FLOW L/S, LENGTH M, DIAMETER MM)
 FRICTION : DARCY-WEISBACH
 NETWORK  :   4 NODES,   1 RESERVOIRS,   4 LINKS
 SOLVER   : TOL  1.0E-05, MAXIT  50
 
 CONVERGED IN   5 ITERATIONS
 
 NODE RESULTS
 ID       TYPE       ELEV    DEMAND      HEAD  PRESSURE       KPA
 -------- ----- --------- --------- --------- --------- ---------
 J1       JUNC     60.000     10.00    98.928    38.928     381.1
 J2       JUNC     55.000     15.00    98.277    43.277     423.7
 J3       JUNC     50.000     12.00    98.213    48.213     472.0
 R1       RESV    100.000    -37.00   100.000     0.000       0.0
 
 LINK RESULTS
 ID       TYPE  FROM     TO            FLOW  VELOCITY  HEADLOSS  FRICTION  STATUS
 -------- ----- -------- -------- --------- --------- --------- ---------  --------
 P1       PIPE  R1       J1           37.00     0.754     1.072   0.01850  OPEN    
 P2       PIPE  J1       J2           17.70     0.564     0.651   0.02011  OPEN    
 P3       PIPE  J2       J3            2.70     0.153     0.064   0.02663  OPEN    
 P4       PIPE  J1       J3            9.30     0.526     0.715   0.02172  OPEN    
 
 TOTAL DEMAND :     37.00 L/S
 TOTAL SUPPLY :     37.00 L/S

 RUN COMPLETED WITH   0 WARNING(S)
rc=0
=== /app/examples/two-sources.dat
 HYDRO 2.3 - STEADY-STATE PIPE NETWORK ANALYSIS
 ----------------------------------------------
 
 TITLE    : Two sources
 UNITS    : SI (FLOW L/S, LENGTH M, DIAMETER MM)
 FRICTION : DARCY-WEISBACH
... [1505 more chars truncated]
```
</details>

### Step 6: Bash

```bash
docker exec sn-fortran-solver-parity bash -lc 'cd /w/old && ln -s hydro.inc HYDRO.INC; gfortran -O2 -o hydro *.f 2>&1 | grep -i error; ./hydro < /app/examples/two-loops.dat; cat > /w/p <<EOF
#!/bin/bash
# usage: p "deck text with \n"
printf "%b" "\$1" | /app/prod/hydro; echo "rc=\$?"
EOF
chmod +x /w/p; /w/p "RESERVOIR R 100\nJUNCTION a 10 5\nPIPE p r a 100 100 0.1\nEND\n"'
```

<details><summary>output</summary>

```
  233 |  1000 FORMAT (1X,'INPUT ERROR AT LINE',I4,': ',A,'  (SEE THE USER MANUAL)')
Error: Unexpected end of format string in format string at (1)
Error: Logicals at (1) must be compared with .eqv. instead of .eq.
Error: FORMAT label 1000 at (1) not defined
Error: Type mismatch in argument ‘v’ at (1); passed INTEGER(4) to REAL(8)
bash: line 1: ./hydro: No such file or directory
 HYDRO 2.3 - STEADY-STATE PIPE NETWORK ANALYSIS
 ----------------------------------------------
STOP 1
 *** ERROR E103 LINE   3: UNDEFINED NODE 'r'
 *** RUN ABORTED:   1 INPUT ERROR(S)
rc=1
```
</details>

### Step 7: Bash

```bash
cd /w 2>/dev/null; docker exec sn-fortran-solver-parity bash -lc 'cd /w
t(){ echo "##### $1"; printf "%b" "$1" | /app/prod/hydro 2>&1 | tail -n +3; echo "rc=${PIPESTATUS[1]}"; }
t ""
t "END\n"
t "FOO\n"
t "RESERVOIR R 100\nJUNCTION a 10 5\nPIPE p R a 100 100 0.1\n"
t "reservoir R 100 ! hi\njunction a 10 5\npipe p R a 100 100 0.1 ! c\nend\n"
t "RESERVOIR R\nJUNCTION a x 5\nPIPE p R a 100 100\nUNITS XX\nOPTION FOO 1\nOPTION TOL\nOPTION STEPS 0\n"
'
```

<details><summary>output</summary>

```
##### 
 *** WARNING W208: END CARD MISSING
 *** ERROR E302: NO FIXED-HEAD NODE
 *** RUN ABORTED:   1 INPUT ERROR(S)
STOP 1
rc=1
##### END\n
 *** ERROR E302: NO FIXED-HEAD NODE
 *** RUN ABORTED:   1 INPUT ERROR(S)
STOP 1
rc=1
##### FOO\n
 *** ERROR E101 LINE   1: UNKNOWN CARD 'FOO'
 *** WARNING W208: END CARD MISSING
 *** ERROR E302: NO FIXED-HEAD NODE
 *** RUN ABORTED:   2 INPUT ERROR(S)
STOP 1
rc=1
##### RESERVOIR R 100\nJUNCTION a 10 5\nPIPE p R a 100 100 0.1\n
 *** WARNING W208: END CARD MISSING
 
 TITLE    : (NONE)
 UNITS    : SI (FLOW L/S, LENGTH M, DIAMETER MM)
 FRICTION : DARCY-WEISBACH
 NETWORK  :   2 NODES,   1 RESERVOIRS,   1 LINKS
 SOLVER   : TOL  1.0E-05, MAXIT  50
 
 CONVERGED IN   2 ITERATIONS
 
 NODE RESULTS
 ID       TYPE       ELEV    DEMAND      HEAD  PRESSURE       KPA
 -------- ----- --------- --------- --------- --------- ---------
 R        RESV    100.000     -5.00   100.000     0.000       0.0
 a        JUNC     10.000      5.00    99.516    89.516     876.4
 
 LINK RESULTS
 ID       TYPE  FROM     TO            FLOW  VELOCITY  HEADLOSS  FRICTION  STATUS
 -------- ----- -------- -------- --------- --------- --------- ---------  --------
 p        PIPE  R        a             5.00     0.637     0.484   0.02345  OPEN    
 
 TOTAL DEMAND :      5.00 L/S
 TOTAL SUPPLY :      5.00 L/S

 RUN COMPLETED WITH   1 WARNING(S)
rc=0
##### reservoir R 100 ! hi\njunction a 10 5\npipe p R a 100 100 0.1 ! c\nend\n
 
 TITLE    : (NONE)
 UNITS    : SI (FLOW L/S, LENGTH M, DIAMETER MM)
 FRICTION : DARCY-WEISBACH
 NETWORK  :   2 NODES,   1 RESERVOIRS,   1 LINKS
 SOLVER   : TOL  1.0E-05, MAXIT  50
 
 CONVERGED IN   2 ITERATIONS
 
 NODE RESULTS
 ID       TYPE       ELEV    DEMAND      HEAD  PRESSURE       KPA
 -------- ----- --------- --------- --------- --------- ---------
 R        RESV    100.000     -5.00   100.000     0.000       0.0
 a        JUNC     10.000      5.00    99.516    89.516     876.4
 
 LINK RESULTS
 ID       TYPE  FROM     TO            FLOW  VELOCITY  HEADLOSS  FRICTION  STATUS
 -------- ----- -------- -------- --------- --------- --------- ---------  --------
 p        PIPE  R        a             5.00     0.637     0.484   0.02345  OPEN    
 
 TOTAL DEMAND :      5.00 L/S
 TOTAL SUPPLY :      5.00 L/S

 RUN COMPLETED WITH   0 WARNING(S)
rc=0
##### RESERVOIR R\nJUNCTION a x 5\nPIPE p R a 100 100\nUNITS XX\nOPTION FOO 1\nOPTION TOL\nOPTION STEPS 0\n
 *** ERROR E105 LINE   1: MISSING FIELD(S)
 *** ERROR E104 LINE   2: BAD NUMBER 'x'
 *** ERROR E105 LINE   3: MISSING FIELD(S)
 *** ERROR E108 LINE   4: INVALID OPTION VALUE 'XX'
 *** ERROR E109 LINE   5: UNKNOWN OPTION 'FOO'
 *** ERROR E105 LINE   6: MISSING FIELD(S)
 *** ERROR E108 LINE   7: INVALID OPTION VALUE '0'
 *** WARNING W208: END CARD MISSING
 *** ERROR E302: NO FIXED-HEAD NODE
 *** RUN ABORTED:   8 INPUT ERROR(S)
STOP 1
rc=1
```
</details>

### Step 8: Bash

```bash
cd /w; cat > /w/t.sh <<'EOF'
t(){ echo "##### $1"; printf "%b" "$1" | /app/prod/hydro 2>&1 | grep -v -e '^ HYDRO 2.3' -e '^ ------' ; echo "rc=${PIPESTATUS[1]}"; }
EOF
docker cp /w/t.sh sn-fortran-solver-parity:/w/t.sh 2>/dev/null; echo
```

<details><summary>output</summary>

```
(eval):cd:1: no such file or directory: /w
(eval):1: no such file or directory: /w/t.sh
```
</details>

### Step 9: Bash

```bash
docker exec -i sn-fortran-solver-parity bash -c 'cat > /w/t.sh' <<'EOF'
t(){ echo "##### $1"; printf "%b" "$1" | /app/prod/hydro 2>&1 | grep -v -e '^ HYDRO 2.3' -e '^ ------' ; echo "rc=${PIPESTATUS[1]}"; }
EOF
docker exec sn-fortran-solver-parity bash -lc 'cd /w; . ./t.sh
B="RESERVOIR R 100\nJUNCTION a 10 5\n"
t "RESERVOIR R 100\nRESERVOIR R 100\nJUNCTION a 10 5\nJUNCTION a 10 5\nPIPE p R a 100 100 0.1\nPIPE p R a 100 100 0.1\nEND\n"
t "${B}PIPE p R a 100 100 0.1 1 2 3 4\nEND\n"
t "${B}PIPE p R a -100 100 0.1\nPIPE q R a 100 0 0.1\nPIPE r R a 100 100 -1\nPIPE s R R 100 100 1\nEND\n"
t "${B}JUNCTION b 5 5\nPIPE p R a 100 100 0.1\nEND\n"
t "${B}PIPE p R zz 100 100 0.1\nPIPE p2 zz R 100 100 0.1\nEND\n"
'
```

<details><summary>output</summary>

```
##### RESERVOIR R 100\nRESERVOIR R 100\nJUNCTION a 10 5\nJUNCTION a 10 5\nPIPE p R a 100 100 0.1\nPIPE p R a 100 100 0.1\nEND\n
 *** ERROR E102 LINE   2: DUPLICATE ID 'R'
 *** ERROR E102 LINE   4: DUPLICATE ID 'a'
 *** ERROR E102 LINE   6: DUPLICATE ID 'p'
 *** RUN ABORTED:   3 INPUT ERROR(S)
STOP 1
rc=1
##### RESERVOIR R 100\nJUNCTION a 10 5\nPIPE p R a 100 100 0.1 1 2 3 4\nEND\n
 *** WARNING W209 LINE   3: EXTRA FIELDS IGNORED
 
 TITLE    : (NONE)
 UNITS    : SI (FLOW L/S, LENGTH M, DIAMETER MM)
 FRICTION : DARCY-WEISBACH
 NETWORK  :   2 NODES,   1 RESERVOIRS,   1 LINKS
 SOLVER   : TOL  1.0E-05, MAXIT  50
 
 CONVERGED IN   2 ITERATIONS
 
 NODE RESULTS
 ID       TYPE       ELEV    DEMAND      HEAD  PRESSURE       KPA
 R        RESV    100.000     -5.00   100.000     0.000       0.0
 a        JUNC     10.000      5.00    99.495    89.495     876.2
 
 LINK RESULTS
 ID       TYPE  FROM     TO            FLOW  VELOCITY  HEADLOSS  FRICTION  STATUS
 p        PIPE  R        a             5.00     0.637     0.505   0.02345  OPEN    
 
 TOTAL DEMAND :      5.00 L/S
 TOTAL SUPPLY :      5.00 L/S

 RUN COMPLETED WITH   1 WARNING(S)
rc=0
##### RESERVOIR R 100\nJUNCTION a 10 5\nPIPE p R a -100 100 0.1\nPIPE q R a 100 0 0.1\nPIPE r R a 100 100 -1\nPIPE s R R 100 100 1\nEND\n
 *** ERROR E107 LINE   3: VALUE OUT OF RANGE
 *** ERROR E107 LINE   4: VALUE OUT OF RANGE
 *** ERROR E107 LINE   5: VALUE OUT OF RANGE
 *** ERROR E110 LINE   6: LINK CONNECTS NODE TO ITSELF
 *** RUN ABORTED:   4 INPUT ERROR(S)
STOP 1
rc=1
##### RESERVOIR R 100\nJUNCTION a 10 5\nJUNCTION b 5 5\nPIPE p R a 100 100 0.1\nEND\n
 
 TITLE    : (NONE)
 UNITS    : SI (FLOW L/S, LENGTH M, DIAMETER MM)
 FRICTION : DARCY-WEISBACH
 NETWORK  :   3 NODES,   1 RESERVOIRS,   1 LINKS
 SOLVER   : TOL  1.0E-05, MAXIT  50
 *** WARNING W204: NODE 'b' IS ISOLATED
 
 CONVERGED IN   2 ITERATIONS
 
 NODE RESULTS
 ID       TYPE       ELEV    DEMAND      HEAD  PRESSURE       KPA
 R        RESV    100.000     -5.00   100.000     0.000       0.0
 a        JUNC     10.000      5.00    99.516    89.516     876.4
 b        JUNC      5.000      5.00    ISOLATED
 
 LINK RESULTS
 ID       TYPE  FROM     TO            FLOW  VELOCITY  HEADLOSS  FRICTION  STATUS
 p        PIPE  R        a             5.00     0.637     0.484   0.02345  OPEN    
 
 TOTAL DEMAND :      5.00 L/S
 TOTAL SUPPLY :      5.00 L/S

 RUN COMPLETED WITH   1 WARNING(S)
rc=0
##### RESERVOIR R 100\nJUNCTION a 10 5\nPIPE p R zz 100 100 0.1\nPIPE p2 zz R 100 100 0.1\nEND\n
 *** ERROR E103 LINE   3: UNDEFINED NODE 'zz'
 *** ERROR E103 LINE   4: UNDEFINED NODE 'zz'
 *** RUN ABORTED:   2 INPUT ERROR(S)
STOP 1
rc=1
```
</details>

### Step 10: Bash

```bash
cd /w; docker exec sn-fortran-solver-parity bash -lc 'cd /w; . ./t.sh
B="RESERVOIR R 100\nJUNCTION a 10 5\nPIPE p R a 100 100 0.1\nEND\n"
for o in "TOL 1e-3" "TOL 0" "TOL -1" "MAXIT 3" "MAXIT 0" "MAXIT 2.5" "MAXIT 1000" "FRICTION HW" "FRICTION hw" "FRICTION XX" "STEPS 3" "STEPS 1.5" "STEPS 1000" "HSTEP 0.5" "HSTEP 0" "HSTEP -1" "METHOD HC" "METHOD GGA" "UNITS SI" "ACCURACY 1" "TOL abc" "TOL 1 2" "tol 1e-3" "TOL 1d-3" "TOL .5" ; do echo "=== OPTION $o"; printf "OPTION $o\n$B" | /app/prod/hydro 2>&1 | grep -e "\*\*\*" -e SOLVER -e CONVERG -e STEP -e FRICTION; done' 2>&1 | head -150
```

<details><summary>output</summary>

```
(eval):cd:1: no such file or directory: /w
=== OPTION TOL 1e-3
 FRICTION : DARCY-WEISBACH
 SOLVER   : TOL  1.0E-03, MAXIT  50
 CONVERGED IN   2 ITERATIONS
 ID       TYPE  FROM     TO            FLOW  VELOCITY  HEADLOSS  FRICTION  STATUS
=== OPTION TOL 0
 *** ERROR E108 LINE   1: INVALID OPTION VALUE '0'
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== OPTION TOL -1
 *** ERROR E108 LINE   1: INVALID OPTION VALUE '-1'
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== OPTION MAXIT 3
 FRICTION : DARCY-WEISBACH
 SOLVER   : TOL  1.0E-05, MAXIT   3
 CONVERGED IN   2 ITERATIONS
 ID       TYPE  FROM     TO            FLOW  VELOCITY  HEADLOSS  FRICTION  STATUS
=== OPTION MAXIT 0
 *** ERROR E108 LINE   1: INVALID OPTION VALUE '0'
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== OPTION MAXIT 2.5
 *** ERROR E108 LINE   1: INVALID OPTION VALUE '2.5'
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== OPTION MAXIT 1000
 *** WARNING W206 LINE   1: MAXIT LIMITED TO 200
 FRICTION : DARCY-WEISBACH
 SOLVER   : TOL  1.0E-05, MAXIT 200
 CONVERGED IN   2 ITERATIONS
 ID       TYPE  FROM     TO            FLOW  VELOCITY  HEADLOSS  FRICTION  STATUS
=== OPTION FRICTION HW
 FRICTION : HAZEN-WILLIAMS
 SOLVER   : TOL  1.0E-05, MAXIT  50
 CONVERGED IN   2 ITERATIONS
 a        JUNC     10.000      5.00********************-3021278.8
 ID       TYPE  FROM     TO            FLOW  VELOCITY  HEADLOSS  FRICTION  STATUS
 *** WARNING W201: NEGATIVE PRESSURE AT NODE 'a'
=== OPTION FRICTION hw
 FRICTION : HAZEN-WILLIAMS
 SOLVER   : TOL  1.0E-05, MAXIT  50
 CONVERGED IN   2 ITERATIONS
 a        JUNC     10.000      5.00********************-3021278.8
 ID       TYPE  FROM     TO            FLOW  VELOCITY  HEADLOSS  FRICTION  STATUS
 *** WARNING W201: NEGATIVE PRESSURE AT NODE 'a'
=== OPTION FRICTION XX
 *** ERROR E108 LINE   1: INVALID OPTION VALUE 'XX'
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== OPTION STEPS 3
 FRICTION : DARCY-WEISBACH
 SOLVER   : TOL  1.0E-05, MAXIT  50
 STEPS    :  3 AT  1.00 H
 TIME STEP  1 OF  3  AT  0:00
 CONVERGED IN   2 ITERATIONS
 ID       TYPE  FROM     TO            FLOW  VELOCITY  HEADLOSS  FRICTION  STATUS
 TIME STEP  2 OF  3  AT  1:00
 CONVERGED IN   1 ITERATIONS
 ID       TYPE  FROM     TO            FLOW  VELOCITY  HEADLOSS  FRICTION  STATUS
 TIME STEP  3 OF  3  AT  2:00
 CONVERGED IN   1 ITERATIONS
 ID       TYPE  FROM     TO            FLOW  VELOCITY  HEADLOSS  FRICTION  STATUS
=== OPTION STEPS 1.5
 *** ERROR E108 LINE   1: INVALID OPTION VALUE '1.5'
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== OPTION STEPS 1000
 *** ERROR E108 LINE   1: INVALID OPTION VALUE '1000'
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== OPTION HSTEP 0.5
 FRICTION : DARCY-WEISBACH
 SOLVER   : TOL  1.0E-05, MAXIT  50
 CONVERGED IN   2 ITERATIONS
 ID       TYPE  FROM     TO            FLOW  VELOCITY  HEADLOSS  FRICTION  STATUS
=== OPTION HSTEP 0
 *** ERROR E108 LINE   1: INVALID OPTION VALUE '0'
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== OPTION HSTEP -1
 *** ERROR E108 LINE   1: INVALID OPTION VALUE '-1'
 *** RUN ABORTED:   1 INPUT ER
... [1361 more chars truncated]
```
</details>

### Step 11: Bash

```bash
cd /w; docker exec sn-fortran-solver-parity bash -lc '/app/prod/hydro < /app/examples/branch.dat 2>&1 | cat -A | sed -n 1,40p'
```

<details><summary>output</summary>

```
(eval):cd:1: no such file or directory: /w
 HYDRO 2.3 - STEADY-STATE PIPE NETWORK ANALYSIS$
 ----------------------------------------------$
 $
 TITLE    : Branched main$
 UNITS    : SI (FLOW L/S, LENGTH M, DIAMETER MM)$
 FRICTION : DARCY-WEISBACH$
 NETWORK  :   4 NODES,   1 RESERVOIRS,   3 LINKS$
 SOLVER   : TOL  1.0E-05, MAXIT  50$
 $
 CONVERGED IN   2 ITERATIONS$
 $
 NODE RESULTS$
 ID       TYPE       ELEV    DEMAND      HEAD  PRESSURE       KPA$
 -------- ----- --------- --------- --------- --------- ---------$
 A        JUNC     40.000      4.50    84.413    44.413     434.8$
 B        JUNC     38.000      3.00    84.265    46.265     452.9$
 C        JUNC     42.500      2.00    84.031    41.531     406.6$
 TANK     RESV     85.000     -9.50    85.000     0.000       0.0$
 $
 LINK RESULTS$
 ID       TYPE  FROM     TO            FLOW  VELOCITY  HEADLOSS  FRICTION  STATUS$
 -------- ----- -------- -------- --------- --------- --------- ---------  --------$
 P1       PIPE  TANK     A             9.50     0.302     0.587   0.02098  OPEN    $
 P2       PIPE  A        B             3.00     0.170     0.148   0.02523  OPEN    $
 P3       PIPE  A        C             2.00     0.255     0.382   0.02567  OPEN    $
 $
 TOTAL DEMAND :      9.50 L/S$
 TOTAL SUPPLY :      9.50 L/S$
$
 RUN COMPLETED WITH   0 WARNING(S)$
```
</details>

### Step 12: Bash

```bash
docker exec sn-fortran-solver-parity bash -lc 'which python3 perl gfortran; gfortran --version | head -1; ls /app /app/prod'
```

<details><summary>output</summary>

```
/usr/local/bin/python3
/usr/bin/perl
/usr/bin/gfortran
GNU Fortran (Debian 12.2.0-14+deb12u1) 12.2.0
/app:
docs
examples
prod
src

/app/prod:
hydro
```
</details>

### Step 13: Bash

```bash
docker exec sn-fortran-solver-parity bash -lc 'cd /w/old && python3 - <<EOF
import re
s=open("cards.f").read()
s=s.replace("IF (INWORD .EQ. .FALSE.) THEN","IF (.NOT. INWORD) THEN")
s=s.replace("1X,\x27INPUT ERROR AT LINE\x27,I4,\x27: \x27,A,\x27  (SEE THE USER MANUAL)\x27)","1X,\x27INPUT ERROR AT LINE\x27,I4,\x27: \x27,A)")
open("cards.f","w").write(s)
EOF
gfortran -O2 -fallow-argument-mismatch -o hydro *.f 2>&1 | grep -B3 -i error; ./hydro < /app/examples/branch.dat'
```

<details><summary>output</summary>

```
 HYDRO VERSION 1.8
 -----------------

 INPUT DATA

 JUNCTION      ELEV    DEMAND
 A           40.000     4.500
 B           38.000     3.000
 C           42.500     2.000

 RESERVOIR     HEAD
 TANK        85.000

 PIPE   FROM   TO        LENGTH   DIAM MM  ROUGH MM   MINOR K
 P1     TANK   A       1200.000   200.000     0.050     0.000
 P2     A      B        600.000   150.000     0.050     0.000
 P3     A      C        450.000   100.000     0.050     0.000

 TOLERANCE  1.00E-06 M3/S   ITERATION LIMIT  40
 *** MATRIX SINGULAR AT ROW   2
```
</details>

### Step 14: Bash

```bash
docker exec sn-fortran-solver-parity bash -lc 'cd /w; cat > scan.py <<EOF
import subprocess,sys,re
def run(deck):
    r=subprocess.run(["/app/prod/hydro"],input=deck,capture_output=True,text=True)
    return r.stdout,r.returncode
if __name__=="__main__":
    for q in [0.001,0.01,0.02,0.05,0.1,0.2,0.3,0.4,0.5,0.6,0.8,1,1.5,2,3,5,10,50,200]:
        d="RESERVOIR R 1000\nJUNCTION a 10 %g\nPIPE p R a 100 100 0.1\nEND\n"%q
        o,rc=run(d)
        l=[x for x in o.split("\n") if x.startswith(" p ")]
        n=[x for x in o.split("\n") if x.startswith(" a ")]
        it=[x for x in o.split("\n") if "CONVERGED" in x or "CONVERGE" in x]
        print(q,l,n,it)
EOF
python3 scan.py'
```

<details><summary>output</summary>

```
0.001 [' p        PIPE  R        a             0.00     0.000     0.000   5.02655  OPEN    '] [' a        JUNC     10.000      0.00  1000.000   990.000    9692.1'] [' CONVERGED IN   2 ITERATIONS']
0.01 [' p        PIPE  R        a             0.01     0.001     0.000   0.50265  OPEN    '] [' a        JUNC     10.000      0.01  1000.000   990.000    9692.1'] [' CONVERGED IN   2 ITERATIONS']
0.02 [' p        PIPE  R        a             0.02     0.003     0.000   0.25133  OPEN    '] [' a        JUNC     10.000      0.02  1000.000   990.000    9692.1'] [' CONVERGED IN   2 ITERATIONS']
0.05 [' p        PIPE  R        a             0.05     0.006     0.000   0.10053  OPEN    '] [' a        JUNC     10.000      0.05  1000.000   990.000    9692.1'] [' CONVERGED IN   2 ITERATIONS']
0.1 [' p        PIPE  R        a             0.10     0.013     0.000   0.05027  OPEN    '] [' a        JUNC     10.000      0.10  1000.000   990.000    9692.1'] [' CONVERGED IN   2 ITERATIONS']
0.2 [' p        PIPE  R        a             0.20     0.025     0.001   0.03465  OPEN    '] [' a        JUNC     10.000      0.20   999.999   989.999    9692.1'] [' CONVERGED IN   2 ITERATIONS']
0.3 [' p        PIPE  R        a             0.30     0.038     0.003   0.04082  OPEN    '] [' a        JUNC     10.000      0.30   999.997   989.997    9692.1'] [' CONVERGED IN   2 ITERATIONS']
0.4 [' p        PIPE  R        a             0.40     0.051     0.005   0.03890  OPEN    '] [' a        JUNC     10.000      0.40   999.995   989.995    9692.0'] [' CONVERGED IN   2 ITERATIONS']
0.5 [' p        PIPE  R        a             0.50     0.064     0.008   0.03660  OPEN    '] [' a        JUNC     10.000      0.50   999.992   989.992    9692.0'] [' CONVERGED IN   2 ITERATIONS']
0.6 [' p        PIPE  R        a             0.60     0.076     0.010   0.03491  OPEN    '] [' a        JUNC     10.000      0.60   999.990   989.990    9692.0'] [' CONVERGED IN   2 ITERATIONS']
0.8 [' p        PIPE  R        a             0.80     0.102     0.017   0.03252  OPEN    '] [' a        JUNC     10.000      0.80   999.983   989.983    9691.9'] [' CONVERGED IN   2 ITERATIONS']
1 [' p        PIPE  R        a             1.00     0.127     0.026   0.03090  OPEN    '] [' a        JUNC     10.000      1.00   999.974   989.974    9691.8'] [' CONVERGED IN   2 ITERATIONS']
1.5 [' p        PIPE  R        a             1.50     0.191     0.053   0.02837  OPEN    '] [' a        JUNC     10.000      1.50   999.947   989.947    9691.6'] [' CONVERGED IN   2 ITERATIONS']
2 [' p        PIPE  R        a             2.00     0.255     0.089   0.02688  OPEN    '] [' a        JUNC     10.000      2.00   999.911   989.911    9691.2'] [' CONVERGED IN   2 ITERATIONS']
3 [' p        PIPE  R        a             3.00     0.382     0.187   0.02514  OPEN    '] [' a        JUNC     10.000      3.00   999.813   989.813    9690.3'] [' CONVERGED IN   2 ITERATIONS']
5 [' p        PIPE  R        a             5.00     0.637     0.484   0.0234
... [699 more chars truncated]
```
</details>

### Step 15: Bash

```bash
docker exec sn-fortran-solver-parity bash -lc 'cd /w; cat > f.py <<EOF
from math import *
def sj(Re,e): return 0.25/log10(e/3.7+5.74/Re**0.9)**2
def dunlop(Re,e):
    w=Re*pi/4
    AB=3.28895476345e-03; AC=5.15053285e-04; A9=-0.86858896380650365530 # 1/ln? 
    A9=-0.8685889638
    y2=e/3.7+AB; y3=A9*log(y2); fa=1/(y3*y3); fb=(2+AC/(y2*y3))*fa
    r=w/(500*pi)
    x1=7*fa-fb; x2=0.128-17*fa+2.5*fb; x3=-0.128+13*fa-(fb+fb); x4=r*(0.032-3*fa+0.5*fb)
    return x1+r*(x2+r*(x3+x4))
for q in [0.2,0.3,0.4,0.5,200]:
    A=pi*0.01/4; V=q/1000/A; Re=V*0.1/1e-6
    print(q,Re,sj(Re,1e-3),dunlop(Re,1e-3))
EOF
python3 f.py'
```

<details><summary>output</summary>

```
0.2 2546.4790894703256 0.04795312239037797 0.02912434368607822
0.3 3819.7186342054883 0.042269447121264805 0.04119075883812898
0.4 5092.958178940651 0.03889916589117605 0.015870779203390223
0.5 6366.197723675815 0.03660154457882591 -0.12543879403102254
200 2546479.0894703255 0.019807740577194546 -104407888.63621621
```
</details>

### Step 16: Bash

```bash
docker exec sn-fortran-solver-parity bash -lc 'cd /w; cat >> f.py <<EOF
print("lin")
def lin(Re,e):
    if Re<2000: return 64/Re
    if Re>=4000: return sj(Re,e)
    f2=64/2000; f4=sj(4000,e)
    return f2+(f4-f2)*(Re-2000)/2000
for q in [0.2,0.3]:
    A=pi*0.01/4; V=q/1000/A; Re=V*0.1/1e-6
    print(q,Re,lin(Re,1e-3))
EOF
python3 f.py | tail -3'
```

<details><summary>output</summary>

```
lin
0.2 2546.4790894703256 0.03464917638421544
0.3 3819.7186342054883 0.04082148233032387
```
</details>

### Step 17: Bash

```bash
docker exec sn-fortran-solver-parity bash -lc 'cd /w; python3 -c "
from math import *
from f import sj
for pi_ in (pi,3.14159265358979,3.1416):
  A=pi_*0.01/4; V=0.2/A; Re=V*0.1/1e-6
  f=sj(Re,1e-3)
  print(pi_, f*1000*V*V/654.884/2)
" | tail -3'
```

<details><summary>output</summary>

```
3.141592653589793 9.80665263740981
3.14159265358979 9.80665263740983
3.1416 9.806606950617589
```
</details>

### Step 18: Bash

```bash
docker exec sn-fortran-solver-parity bash -lc 'cd /w; for f in two-loops two-sources branch; do echo $f; for t in 1 1e-1 1e-2 1e-3 1e-4 1e-5 1e-6 1e-7 1e-8 1e-9 1e-10 1e-12 1e-14 1e-20; do printf "TOL $t: "; (echo "OPTION TOL $t"; cat /app/examples/$f.dat) | /app/prod/hydro 2>&1 | grep -e "CONVERGED" -e NOT -e "\*\*\*" | tr "\n" " "; echo; done; done'
```

<details><summary>output</summary>

```
two-loops
TOL 1:  CONVERGED IN   1 ITERATIONS 
TOL 1e-1:  CONVERGED IN   2 ITERATIONS 
TOL 1e-2:  CONVERGED IN   3 ITERATIONS 
TOL 1e-3:  CONVERGED IN   4 ITERATIONS 
TOL 1e-4:  CONVERGED IN   4 ITERATIONS 
TOL 1e-5:  CONVERGED IN   5 ITERATIONS 
TOL 1e-6:  CONVERGED IN   6 ITERATIONS 
TOL 1e-7:  CONVERGED IN   7 ITERATIONS 
TOL 1e-8:  CONVERGED IN   8 ITERATIONS 
TOL 1e-9:  CONVERGED IN   9 ITERATIONS 
TOL 1e-10:  CONVERGED IN  10 ITERATIONS 
TOL 1e-12:  CONVERGED IN  11 ITERATIONS 
TOL 1e-14:  CONVERGED IN  14 ITERATIONS 
TOL 1e-20:  *** WARNING W205: NOT CONVERGED AFTER 50 ITERATIONS 
two-sources
TOL 1:  CONVERGED IN   1 ITERATIONS 
TOL 1e-1:  CONVERGED IN   3 ITERATIONS 
TOL 1e-2:  CONVERGED IN   4 ITERATIONS 
TOL 1e-3:  CONVERGED IN   5 ITERATIONS 
TOL 1e-4:  CONVERGED IN   5 ITERATIONS 
TOL 1e-5:  CONVERGED IN   6 ITERATIONS 
TOL 1e-6:  CONVERGED IN   7 ITERATIONS 
TOL 1e-7:  CONVERGED IN   7 ITERATIONS 
TOL 1e-8:  CONVERGED IN   8 ITERATIONS 
TOL 1e-9:  CONVERGED IN   9 ITERATIONS 
TOL 1e-10:  CONVERGED IN   9 ITERATIONS 
TOL 1e-12:  CONVERGED IN  11 ITERATIONS 
TOL 1e-14:  CONVERGED IN  12 ITERATIONS 
TOL 1e-20:  *** WARNING W205: NOT CONVERGED AFTER 50 ITERATIONS 
branch
TOL 1:  CONVERGED IN   1 ITERATIONS 
TOL 1e-1:  CONVERGED IN   2 ITERATIONS 
TOL 1e-2:  CONVERGED IN   2 ITERATIONS 
TOL 1e-3:  CONVERGED IN   2 ITERATIONS 
TOL 1e-4:  CONVERGED IN   2 ITERATIONS 
TOL 1e-5:  CONVERGED IN   2 ITERATIONS 
TOL 1e-6:  CONVERGED IN   2 ITERATIONS 
TOL 1e-7:  CONVERGED IN   2 ITERATIONS 
TOL 1e-8:  CONVERGED IN   2 ITERATIONS 
TOL 1e-9:  CONVERGED IN   2 ITERATIONS 
TOL 1e-10:  CONVERGED IN   2 ITERATIONS 
TOL 1e-12:  CONVERGED IN   2 ITERATIONS 
TOL 1e-14:  CONVERGED IN  15 ITERATIONS 
TOL 1e-20:  *** WARNING W205: NOT CONVERGED AFTER 50 ITERATIONS
```
</details>

### Step 19: Bash

```bash
docker exec sn-fortran-solver-parity bash -lc 'cd /w; cat > rep.py <<EOF
import sys,subprocess
from math import *
import numpy as np
G=9.80665
def frfac(Re,eps):
    if Re<1e-6: return 0.0
    if Re<2000: return 64/Re
    sjf=lambda R:0.25/log10(eps/3.7+5.74/R**0.9)**2
    if Re>=4000: return sjf(Re)
    f2=0.032;f4=sjf(4000.0)
    return f2+(f4-f2)*(Re-2000)/2000
def parse(txt):
    nodes=[];links=[]
    for ln in txt.split("\n"):
        t=ln.split()
        if not t: continue
        k=t[0].upper()
        if k=="RESERVOIR": nodes.append(dict(id=t[1],typ=2,z=float(t[2]),q=0.0))
        if k=="JUNCTION": nodes.append(dict(id=t[1],typ=1,z=float(t[2]),q=float(t[3])/1000))
        if k=="PIPE":
            links.append(dict(id=t[1],a=t[2],b=t[3],L=float(t[4]),D=float(t[5])/1000,e=float(t[6])/1000,k=float(t[7]) if len(t)>7 else 0.0))
    return nodes,links
def solve(txt,tol,crit,v0=0.3048,gexp=2.0,maxit=50,gmin=1e-4):
    nodes,links=parse(txt)
    idx={n["id"]:i for i,n in enumerate(nodes)}
    for l in links: l["i"]=idx[l["a"]]; l["j"]=idx[l["b"]]
    H=[n["z"] if n["typ"]==2 else 0.0 for n in nodes]
    ix={};neq=0
    for i,n in enumerate(nodes):
        if n["typ"]==1: ix[i]=neq;neq+=1
    Q=[v0*pi*l["D"]**2/4 for l in links]
    for it in range(1,maxit+1):
        A=np.zeros((neq,neq));rhs=np.zeros(neq)
        for i,n in enumerate(nodes):
            if i in ix: rhs[ix[i]]=-n["q"]
        P=[];Y=[]
        for L,l in enumerate(links):
            D=l["D"];Ar=pi*D*D/4;q=Q[L];V=q/Ar;Re=abs(V)*D/1e-6
            f=frfac(Re,l["e"]/D)
            h=f*l["L"]/D*V*abs(V)/(2*G)+l["k"]*V*abs(V)/(2*G)
            R=f*l["L"]/(D*2*G*Ar*Ar)
            gr=R*abs(q) if Re<2000 else 2*R*abs(q)
            gr+= l["k"]/(G*Ar*Ar)*abs(q)
            gr=max(gr,gmin)
            p=1/gr;y=p*h;P.append(p);Y.append(y)
            k1=ix.get(l["i"],-1);k2=ix.get(l["j"],-1)
            if k1>=0:
                A[k1,k1]+=p;rhs[k1]-=(q-y)
                if k2>=0:A[k1,k2]-=p
                else: rhs[k1]+=p*H[l["j"]]
            if k2>=0:
                A[k2,k2]+=p;rhs[k2]+=(q-y)
                if k1>=0:A[k2,k1]-=p
                else: rhs[k2]+=p*H[l["i"]]
        hx=np.linalg.solve(A,rhs)
        for i in ix: H[i]=hx[ix[i]]
        dq=[];sq=0
        for L,l in enumerate(links):
            qn=Q[L]-Y[L]+P[L]*(H[l["i"]]-H[l["j"]])
            dq.append(qn-Q[L]);Q[L]=qn
        if crit=="max_m3": c=max(abs(x) for x in dq)
        elif crit=="max_ls": c=1000*max(abs(x) for x in dq)
        elif crit=="rel": c=sum(abs(x) for x in dq)/sum(abs(x) for x in Q)
        elif crit=="rel_ls": c=sum(abs(x) for x in dq)/sum(abs(x) for x in Q)
        if c<tol: return it,Q,H
    return maxit,Q,H
if __name__=="__main__":
    f=sys.argv[1]
    txt=open(f).read()
    for crit in ["max_m3","max_ls","rel"]:
        print(crit,[solve(txt,t,crit)[0] for t in [1,1e-1,1e-2,1e-3,1e-4,1e-5,1e-6,1e-7,1e-8,1e-9,1e-10,1e-12]])
EOF
for f in two-loops two-sources branch; do python3 rep.py /app/examples/$f.dat; done'
```

<details><summary>output</summary>

```
Exit code 1
Traceback (most recent call last):
  File "/w/rep.py", line 3, in <module>
    import numpy as np
ModuleNotFoundError: No module named 'numpy'
Traceback (most recent call last):
  File "/w/rep.py", line 3, in <module>
    import numpy as np
ModuleNotFoundError: No module named 'numpy'
Traceback (most recent call last):
  File "/w/rep.py", line 3, in <module>
    import numpy as np
ModuleNotFoundError: No module named 'numpy'
```
</details>

### Step 20: Bash

```bash
docker exec sn-fortran-solver-parity bash -lc 'cd /w; python3 - <<EOF
s=open("rep.py").read()
s=s.replace("import numpy as np\n","""
def gsolve(A,b):
    n=len(b);A=[r[:] for r in A];b=b[:]
    for k in range(n):
        ip=max(range(k,n),key=lambda i:abs(A[i][k]))
        A[k],A[ip]=A[ip],A[k];b[k],b[ip]=b[ip],b[k]
        for i in range(k+1,n):
            t=A[i][k]/A[k][k]
            for j in range(k+1,n):A[i][j]-=t*A[k][j]
            b[i]-=t*b[k]
    x=[0]*n
    for i in range(n-1,-1,-1):
        t=b[i]
        for j in range(i+1,n):t-=A[i][j]*x[j]
        x[i]=t/A[i][i]
    return x
""")
s=s.replace("A=np.zeros((neq,neq));rhs=np.zeros(neq)","A=[[0.0]*neq for _ in range(neq)];rhs=[0.0]*neq")
s=s.replace("hx=np.linalg.solve(A,rhs)","hx=gsolve(A,rhs)")
import re
s=re.sub(r"A\[(\w+),(\w+)\]",r"A[\1][\2]",s)
open("rep.py","w").write(s)
EOF
for f in two-loops two-sources branch; do python3 rep.py /app/examples/$f.dat; done'
```

<details><summary>output</summary>

```
max_m3 [1, 1, 2, 2, 3, 4, 5, 6, 6, 7, 8, 10]
max_ls [2, 3, 4, 5, 6, 6, 7, 8, 9, 10, 11, 12]
rel [1, 2, 3, 4, 4, 5, 6, 7, 8, 9, 10, 11]
max_m3 [1, 1, 2, 4, 4, 5, 6, 6, 7, 8, 8, 10]
max_ls [4, 4, 5, 6, 6, 7, 8, 8, 9, 10, 10, 12]
rel [1, 3, 4, 5, 5, 6, 7, 7, 8, 9, 9, 11]
max_m3 [1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2]
max_ls [2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2]
rel [1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2]
```
</details>

### Step 21: Bash

```bash
docker exec sn-fortran-solver-parity bash -lc 'cd /w; . ./t.sh
t "UNITS US\nRESERVOIR R 100\nJUNCTION a 10 50\nPIPE p R a 1000 6 1.5\nEND\n"
t "units us\nOPTION FRICTION HW\nRESERVOIR R 100\nJUNCTION a 10 50\nPIPE p R a 1000 6 120\nEND\n"
t "OPTION FRICTION HW\nRESERVOIR R 100\nJUNCTION a 10 5\nPIPE p R a 1000 100 120\nEND\n"
'
```

<details><summary>output</summary>

```
##### UNITS US\nRESERVOIR R 100\nJUNCTION a 10 50\nPIPE p R a 1000 6 1.5\nEND\n
 
 TITLE    : (NONE)
 UNITS    : US (FLOW GPM, LENGTH FT, DIAMETER IN)
 FRICTION : DARCY-WEISBACH
 NETWORK  :   2 NODES,   1 RESERVOIRS,   1 LINKS
 SOLVER   : TOL  1.0E-05, MAXIT  50
 
 CONVERGED IN   2 ITERATIONS
 
 NODE RESULTS
 ID       TYPE       ELEV    DEMAND      HEAD  PRESSURE       PSI
 R        RESV    100.000    -50.00   100.000     0.000      0.00
 a        JUNC     10.000     50.00    99.692    89.692     38.88
 
 LINK RESULTS
 ID       TYPE  FROM     TO            FLOW  VELOCITY  HEADLOSS  FRICTION  STATUS
 p        PIPE  R        a            50.00     0.567     0.308   0.03079  OPEN    
 
 TOTAL DEMAND :     50.00 GPM
 TOTAL SUPPLY :     50.00 GPM

 RUN COMPLETED WITH   0 WARNING(S)
rc=0
##### units us\nOPTION FRICTION HW\nRESERVOIR R 100\nJUNCTION a 10 50\nPIPE p R a 1000 6 120\nEND\n
 
 TITLE    : (NONE)
 UNITS    : US (FLOW GPM, LENGTH FT, DIAMETER IN)
 FRICTION : HAZEN-WILLIAMS
 NETWORK  :   2 NODES,   1 RESERVOIRS,   1 LINKS
 SOLVER   : TOL  1.0E-05, MAXIT  50
 
 CONVERGED IN   2 ITERATIONS
 
 NODE RESULTS
 ID       TYPE       ELEV    DEMAND      HEAD  PRESSURE       PSI
 R        RESV    100.000    -50.00   100.000     0.000      0.00
 a        JUNC     10.000     50.00    99.665    89.665     38.87
 
 LINK RESULTS
 ID       TYPE  FROM     TO            FLOW  VELOCITY  HEADLOSS  FRICTION  STATUS
 p        PIPE  R        a            50.00     0.567     0.335            OPEN    
 
 TOTAL DEMAND :     50.00 GPM
 TOTAL SUPPLY :     50.00 GPM

 RUN COMPLETED WITH   0 WARNING(S)
rc=0
##### OPTION FRICTION HW\nRESERVOIR R 100\nJUNCTION a 10 5\nPIPE p R a 1000 100 120\nEND\n
 
 TITLE    : (NONE)
 UNITS    : SI (FLOW L/S, LENGTH M, DIAMETER MM)
 FRICTION : HAZEN-WILLIAMS
 NETWORK  :   2 NODES,   1 RESERVOIRS,   1 LINKS
 SOLVER   : TOL  1.0E-05, MAXIT  50
 
 CONVERGED IN   2 ITERATIONS
 
 NODE RESULTS
 ID       TYPE       ELEV    DEMAND      HEAD  PRESSURE       KPA
 R        RESV    100.000     -5.00   100.000     0.000       0.0
 a        JUNC     10.000      5.00    93.878    83.878     821.2
 
 LINK RESULTS
 ID       TYPE  FROM     TO            FLOW  VELOCITY  HEADLOSS  FRICTION  STATUS
 p        PIPE  R        a             5.00     0.637     6.122            OPEN    
 
 TOTAL DEMAND :      5.00 L/S
 TOTAL SUPPLY :      5.00 L/S

 RUN COMPLETED WITH   0 WARNING(S)
rc=0
```
</details>

### Step 22: Bash

```bash
docker exec sn-fortran-solver-parity bash -lc 'cd /w; cat > cal.py <<EOF
import subprocess,re
from math import *
def run(deck):
    return subprocess.run(["/app/prod/hydro"],input=deck,capture_output=True,text=True).stdout
def pipe(units,fr,q,L,D,r,H=100,z=10):
    d="UNITS %s\nOPTION FRICTION %s\nRESERVOIR R %g\nJUNCTION a %g %g\nPIPE p R a %g %g %g\nEND\n"%(units,fr,H,z,q,L,D,r)
    o=run(d)
    row=[x for x in o.split("\n") if x.startswith(" p ")][0]
    return row,o
if __name__=="__main__":
    for u,fr,D,r in [("SI","HW",100,120),("US","HW",6,120)]:
        for q in [5,50,500]:
            row,_=pipe(u,fr,q,1000,D,r,H=10000)
            print(u,fr,q,row)
EOF
python3 cal.py'
```

<details><summary>output</summary>

```
SI HW 5  p        PIPE  R        a             5.00     0.637     6.122            OPEN    
SI HW 50  p        PIPE  R        a            50.00     6.366   435.403            OPEN    
SI HW 500  p        PIPE  R        a           500.00    63.662 30966.425            OPEN    
US HW 5  p        PIPE  R        a             5.00     0.057     0.005            OPEN    
US HW 50  p        PIPE  R        a            50.00     0.567     0.335            OPEN    
US HW 500  p        PIPE  R        a           500.00     5.674    23.829            OPEN
```
</details>

### Step 23: Bash

```bash
docker exec sn-fortran-solver-parity bash -lc 'cd /w; python3 -c "
from math import *
# SI: q L/s
for q,hl in [(5,6.122),(50,435.403),(500,30966.425)]:
    Q=q/1000; k=hl*120**1.852*0.1**4.871/(1000*Q**1.852); print(\"SI\",k)
# US: gpm -> cfs, D=0.5ft
for q,hl in [(50,0.335),(500,23.829)]:
    Q=q/448.831; k=hl*120**1.852*0.5**4.871/(1000*Q**1.852); print(\"US\",k, q/448.831, q*0.002228009, q/448.8325)
"

```

<details><summary>output</summary>

```
Exit code 1
(eval):10: unmatched '
```
</details>

### Step 24: Bash

```bash
docker exec sn-fortran-solver-parity bash -lc 'cd /w; cat > c2.py <<EOF
from math import *
for q,hl in [(5,6.122),(50,435.403),(500,30966.425)]:
    Q=q/1000; k=hl*120**1.852*0.1**4.871/(1000*Q**1.852); print("SI",k)
for q,hl in [(50,0.335),(500,23.829)]:
    Q=q/448.831; k=hl*120**1.852*0.5**4.871/(1000*Q**1.852); print("US",k)
EOF
python3 c2.py'
```

<details><summary>output</summary>

```
SI 10.667055259502517
SI 10.667008391171798
SI 10.666999866052738
US 4.726463922653861
US 4.7271279488600015
```
</details>

### Step 25: Bash

```bash
docker exec sn-fortran-solver-parity bash -lc 'cd /w; cat > c3.py <<EOF
from cal import *
for q in [5e5,5e6]:
    row,o=pipe("US","HW",q,1000,6,120,H=1e9)
    print(row)
    V=float(row.split()[5]); hl=float(row.split()[6])
    A=pi*0.25**2/4*4
    A=pi*0.5**2/4
    print("cf",q/V/A, "k", hl*120**1.852*0.5**4.871/(1000*(V*A)**1.852))
EOF
python3 c3.py'
```

<details><summary>output</summary>

```
Exit code 1
Traceback (most recent call last):
  File "/w/c3.py", line 5, in <module>
    V=float(row.split()[5]); hl=float(row.split()[6])
 p        PIPE  R        a        500000.00  5673.579**********            OPEN    
      ^^^^^^^^^^^^^^^^^^^^^
ValueError: could not convert string to float: '5673.579**********'
```
</details>

### Step 26: Bash

```bash
docker exec sn-fortran-solver-parity bash -lc 'cd /w; cat > c3.py <<EOF
from cal import *
for q,L in [(5e4,1),(2e5,0.1)]:
    row,o=pipe("US","HW",q,L,6,120,H=1e9)
    print(row)
    V=float(row.split()[5]); hl=float(row.split()[6])
    A=pi*0.5**2/4
    print("cf",q/V/A, "k", hl*120**1.852*0.5**4.871/(L*(V*A)**1.852))
EOF
python3 c3.py'
```

<details><summary>output</summary>

```
 p        PIPE  R        a         50000.00   567.358   120.532            OPEN    
cf 448.8310889192231 k 4.7270920840873005
 p        PIPE  R        a        200000.00  2269.432   157.078            OPEN    
cf 448.8310889192231 k 4.727069184318376
```
</details>

### Step 27: Bash

```bash
docker exec sn-fortran-solver-parity bash -lc 'cd /w; cat > c4.py <<EOF
from cal import *
cf=448.831
for q in [0.01,0.001]:
    row,o=pipe("US","DW",q,1000,6,1.5,H=100)
    print(row)
    f=float(row.split()[7]); 
    V=q/cf/(pi*0.25**2/4*1.0)
    A=pi*0.5**2/4
    V=q/cf/A
    Re=64/f
    print("nu",V*0.5/Re)
EOF
python3 c4.py'
```

<details><summary>output</summary>

```
Exit code 1
 p        PIPE  R        a             0.01     0.000     0.000     UNDEF  OPEN    
Traceback (most recent call last):
  File "/w/c4.py", line 6, in <module>
    f=float(row.split()[7]); 
      ^^^^^^^^^^^^^^^^^^^^^
ValueError: could not convert string to float: 'UNDEF'
```
</details>

### Step 28: Bash

```bash
docker exec sn-fortran-solver-parity bash -lc 'cd /w; cat > c4.py <<EOF
from cal import *
cf=448.831
for q in [0.02,0.05,0.1,0.2,0.5,1,3]:
    row,o=pipe("US","DW",q,1000,6,1.5,H=100)
    print(q,row)
    try: f=float(row.split()[7])
    except: continue
    A=pi*0.5**2/4
    V=q/cf/A
    Re=64/f
    print("nu",V*0.5/Re)
EOF
python3 c4.py'
```

<details><summary>output</summary>

```
0.02  p        PIPE  R        a             0.02     0.000     0.000   6.07104  OPEN    
nu 1.0763918108470898e-05
0.05  p        PIPE  R        a             0.05     0.001     0.000   2.42842  OPEN    
nu 1.076393583841191e-05
0.1  p        PIPE  R        a             0.10     0.001     0.000   1.21421  OPEN    
nu 1.076393583841191e-05
0.2  p        PIPE  R        a             0.20     0.002     0.000   0.60710  OPEN    
nu 1.0763847188706847e-05
0.5  p        PIPE  R        a             0.50     0.006     0.000   0.24284  OPEN    
nu 1.0763847188706847e-05
1  p        PIPE  R        a             1.00     0.011     0.000   0.12142  OPEN    
nu 1.0763847188706847e-05
3  p        PIPE  R        a             3.00     0.034     0.001   0.04047  OPEN    
nu 1.0762960691656221e-05
```
</details>

### Step 29: Bash

```bash
docker exec sn-fortran-solver-parity bash -lc 'cd /w; cat > c5.py <<EOF
from cal import *
for q in [0,1e-5,1e-4,5e-4,0.001,0.0005,0.0004,0.0003,0.0002,0.00015,0.0001]:
    row,o=pipe("SI","DW",q,100,100,0.1,H=100)
    print(q,row, "Re=%g"%(q/1000/(pi*0.01/4)*0.1/1e-6))
EOF
python3 c5.py'
```

<details><summary>output</summary>

```
0  p        PIPE  R        a             0.00     0.000     0.000     UNDEF  OPEN     Re=0
1e-05  p        PIPE  R        a             0.00     0.000     0.000     UNDEF  OPEN     Re=0.127324
0.0001  p        PIPE  R        a             0.00     0.000     0.000     UNDEF  OPEN     Re=1.27324
0.0005  p        PIPE  R        a             0.00     0.000     0.000     UNDEF  OPEN     Re=6.3662
0.001  p        PIPE  R        a             0.00     0.000     0.000     UNDEF  OPEN     Re=12.7324
0.0005  p        PIPE  R        a             0.00     0.000     0.000     UNDEF  OPEN     Re=6.3662
0.0004  p        PIPE  R        a             0.00     0.000     0.000     UNDEF  OPEN     Re=5.09296
0.0003  p        PIPE  R        a             0.00     0.000     0.000     UNDEF  OPEN     Re=3.81972
0.0002  p        PIPE  R        a             0.00     0.000     0.000     UNDEF  OPEN     Re=2.54648
0.00015  p        PIPE  R        a             0.00     0.000     0.000     UNDEF  OPEN     Re=1.90986
0.0001  p        PIPE  R        a             0.00     0.000     0.000     UNDEF  OPEN     Re=1.27324
```
</details>

### Step 30: Bash

```bash
docker exec sn-fortran-solver-parity bash -lc 'cd /w; . ./t.sh
t "RESERVOIR R 1000\nJUNCTION a 10 0.001\nPIPE p R a 100 100 0.1\nEND\n" | grep " p "
t "OPTION FRICTION DW\nRESERVOIR R 1000\nJUNCTION a 10 0.001\nPIPE p R a 100 100 0.1\nEND\n" | grep " p "
t "UNITS SI\nRESERVOIR R 1000\nJUNCTION a 10 0.001\nPIPE p R a 100 100 0.1\nEND\n" | grep " p "
t "RESERVOIR R 100\nJUNCTION a 10 0.001\nPIPE p R a 100 100 0.1\nEND\n" | grep " p "
'
```

<details><summary>output</summary>

```
##### RESERVOIR R 1000\nJUNCTION a 10 0.001\nPIPE p R a 100 100 0.1\nEND\n
 p        PIPE  R        a             0.00     0.000     0.000   5.02655  OPEN    
##### OPTION FRICTION DW\nRESERVOIR R 1000\nJUNCTION a 10 0.001\nPIPE p R a 100 100 0.1\nEND\n
 p        PIPE  R        a             0.00     0.000     0.000   5.02655  OPEN    
##### UNITS SI\nRESERVOIR R 1000\nJUNCTION a 10 0.001\nPIPE p R a 100 100 0.1\nEND\n
 p        PIPE  R        a             0.00     0.000     0.000   5.02655  OPEN    
##### RESERVOIR R 100\nJUNCTION a 10 0.001\nPIPE p R a 100 100 0.1\nEND\n
 p        PIPE  R        a             0.00     0.000     0.000     UNDEF  OPEN
```
</details>

### Step 31: Bash

```bash
docker exec sn-fortran-solver-parity bash -lc 'cd /w; . ./t.sh
t "RESERVOIR R 100\nJUNCTION a 10 0.001\nPIPE p R a 100 100 0.1\nEND\n"
t "RESERVOIR R 1000\nJUNCTION a 10 0.001\nPIPE p R a 100 100 0.1\nEND\n"' | grep -e CONV -e " a " -e " p "
```

<details><summary>output</summary>

```
##### RESERVOIR R 100\nJUNCTION a 10 0.001\nPIPE p R a 100 100 0.1\nEND\n
 CONVERGED IN   2 ITERATIONS
 a        JUNC     10.000      0.00   100.000    90.000     881.1
 p        PIPE  R        a             0.00     0.000     0.000     UNDEF  OPEN    
##### RESERVOIR R 1000\nJUNCTION a 10 0.001\nPIPE p R a 100 100 0.1\nEND\n
 CONVERGED IN   2 ITERATIONS
 a        JUNC     10.000      0.00  1000.000   990.000    9692.1
 p        PIPE  R        a             0.00     0.000     0.000   5.02655  OPEN
```
</details>

### Step 32: Bash

```bash
docker exec sn-fortran-solver-parity bash -lc 'cd /w; cat > c6.py <<EOF
from cal import *
for H in [20,50,100,101,200,500,999,1000,1001,2000]:
    row,o=pipe("SI","DW",0.001,100,100,0.1,H=H)
    print(H,row[-22:])
EOF
python3 c6.py'
```

<details><summary>output</summary>

```
20 00     UNDEF  OPEN    
50 00   5.02655  OPEN    
100 00     UNDEF  OPEN    
101 00     UNDEF  OPEN    
200 00     UNDEF  OPEN    
500 00     UNDEF  OPEN    
999 00     UNDEF  OPEN    
1000 00   5.02655  OPEN    
1001 00   5.02655  OPEN    
2000 00     UNDEF  OPEN
```
</details>

### Step 33: Bash

```bash
docker exec sn-fortran-solver-parity bash -lc 'python3 -c "
print(10.667*0.3048**(-4.871)*0.0283168**1.852, 10.667*0.3048**(-4.871)*(1/448.831/35.3147*35.3147)**1.852)
print(10.667*0.3048**(-4.871)*(0.001/ (448.831/ 35.3146667))**1.852)
"'
```

<details><summary>output</summary>

```
4.727061157343173 0.04263320500347087
8.720890819809993e-05
```
</details>

### Step 34: Bash

```bash
docker exec sn-fortran-solver-parity bash -lc 'cd /w; cat > c7.py <<EOF
from cal import *
for q in [5e6,5e5]:
    row,o=pipe("US","HW",q,1000,6,120,H=1e9)
    V=float(row.split()[5])
    for D in [0.5,6*0.0254/0.3048]:
        A=pi*D*D/4
        print(q,V,"cf",q/V/A)
    # SI internal: D=0.1524 m, V m/s
    A=pi*0.1524**2/4
    print("gpm per m3/s",q/(V*0.3048*A), "m3/s per gpm",(V*0.3048*A)/q)
EOF
python3 c7.py'
```

<details><summary>output</summary>

```
Exit code 1
Traceback (most recent call last):
  File "/w/c7.py", line 4, in <module>
    V=float(row.split()[5])
      ^^^^^^^^^^^^^^^^^^^^^
ValueError: could not convert string to float: '56735.790**********'
```
</details>

### Step 35: Bash

```bash
docker exec sn-fortran-solver-parity bash -lc 'cd /w; cat > c7.py <<EOF
from cal import *
for q in [5e6,5e5]:
    row,o=pipe("US","HW",q,1000,6,120,H=1e9)
    V=float(row[43:53])
    print(row)
    A=pi*0.1524**2/4
    print("gpm per m3/s",q/(V*0.3048*A), "m3/s per gpm",(V*0.3048*A)/q, 1/448.831/35.3146667)
EOF
python3 c7.py'
```

<details><summary>output</summary>

```
 p        PIPE  R        a       5000000.00 56735.790**********            OPEN    
gpm per m3/s 15850.32311313269 m3/s per gpm 6.309019651286831e-05 6.309022017024336e-05
 p        PIPE  R        a        500000.00  5673.579**********            OPEN    
gpm per m3/s 15850.323113132694 m3/s per gpm 6.30901965128683e-05 6.309022017024336e-05
```
</details>

### Step 36: Bash

```bash
docker exec sn-fortran-solver-parity bash -lc 'cd /w; cat > c8.py <<EOF
from cal import *
for u in ["SI","US"]:
  for H in [1000,1e5,1e6,1e7]:
    row,o=pipe(u,"DW",1,10,100,0.1,H=H)
    a=[x for x in o.split("\n") if x.startswith(" a ")][0]
    print(u,a)
    pr=float(a[43:53]) if 0 else None
EOF
python3 c8.py'
```

<details><summary>output</summary>

```
SI  a        JUNC     10.000      1.00   999.997   989.997    9692.1
SI  a        JUNC     10.000      1.00 99999.997 99989.997  978902.1
SI  a        JUNC     10.000      1.00999999.997999989.997 9789902.1
SI  a        JUNC     10.000      1.00********************97899902.1
US  a        JUNC     10.000      1.00  1000.000   990.000    429.16
US  a        JUNC     10.000      1.00100000.000 99990.000  43345.66
US  a        JUNC     10.000      1.00**********999990.000 433495.66
US  a        JUNC     10.000      1.00********************4334995.67
```
</details>

### Step 37: Bash

```bash
docker exec sn-fortran-solver-parity bash -lc 'cd /w; . ./t.sh
t "RESERVOIR R 100\nJUNCTION a 10 5\nJUNCTION b 20 3\nPUMP u R a 30\nPIPE p a b 100 100 0.1\nEND\n"
t "RESERVOIR R 100\nJUNCTION a 10 5\nJUNCTION b 20 3\nPUMP u R a 30 20\nPIPE p a b 100 100 0.1\nEND\n"
' | grep -v -e "^ *$" -e TITLE -e UNITS -e FRICTION
```

<details><summary>output</summary>

```
##### RESERVOIR R 100\nJUNCTION a 10 5\nJUNCTION b 20 3\nPUMP u R a 30\nPIPE p a b 100 100 0.1\nEND\n
 NETWORK  :   3 NODES,   1 RESERVOIRS,   2 LINKS
 SOLVER   : TOL  1.0E-05, MAXIT  50
 CONVERGED IN   2 ITERATIONS
 NODE RESULTS
 ID       TYPE       ELEV    DEMAND      HEAD  PRESSURE       KPA
 R        RESV    100.000     -8.00   100.000     0.000       0.0
 a        JUNC     10.000      5.00   130.000   120.000    1174.8
 b        JUNC     20.000      3.00   129.813   109.813    1075.1
 LINK RESULTS
 u        PUMP  R        a             8.00              30.000            ON      
 p        PIPE  a        b             3.00     0.382     0.187   0.02514  OPEN    
 TOTAL DEMAND :      8.00 L/S
 TOTAL SUPPLY :      8.00 L/S
 RUN COMPLETED WITH   0 WARNING(S)
rc=0
##### RESERVOIR R 100\nJUNCTION a 10 5\nJUNCTION b 20 3\nPUMP u R a 30 20\nPIPE p a b 100 100 0.1\nEND\n
 NETWORK  :   3 NODES,   1 RESERVOIRS,   2 LINKS
 SOLVER   : TOL  1.0E-05, MAXIT  50
 CONVERGED IN   2 ITERATIONS
 NODE RESULTS
 ID       TYPE       ELEV    DEMAND      HEAD  PRESSURE       KPA
 R        RESV    100.000     -8.00   100.000     0.000       0.0
 a        JUNC     10.000      5.00   125.200   115.200    1127.8
 b        JUNC     20.000      3.00   125.013   105.013    1028.1
 LINK RESULTS
 u        PUMP  R        a             8.00              25.200            ON      
 p        PIPE  a        b             3.00     0.382     0.187   0.02514  OPEN    
 TOTAL DEMAND :      8.00 L/S
 TOTAL SUPPLY :      8.00 L/S
 RUN COMPLETED WITH   0 WARNING(S)
rc=0
```
</details>

### Step 38: Bash

```bash
docker exec sn-fortran-solver-parity bash -lc 'cd /w; . ./t.sh
t "RESERVOIR R 100\nJUNCTION a 10 5\nJUNCTION b 20 3\nPIPE p R a 100 100 0.1\nVALVE v a b 100 5\nEND\n"
t "RESERVOIR R 100\nJUNCTION a 10 5\nJUNCTION b 20 3\nPIPE p R a 100 100 0.1\nVALVE v a b 100 5 CLOSED\nEND\n"
t "RESERVOIR R 100\nJUNCTION a 10 5\nJUNCTION b 20 3\nPIPE p R a 100 100 0.1\nVALVE v a b 100 5 OPEN\nPATTERN pp 1 2 3\nEND\n"
' | grep -v -e "^ *$" -e TITLE -e UNITS -e FRICTION -e NETWORK -e SOLVER -e "^ HYDRO" -e "\-\-\-"
```

<details><summary>output</summary>

```
##### RESERVOIR R 100\nJUNCTION a 10 5\nJUNCTION b 20 3\nPIPE p R a 100 100 0.1\nVALVE v a b 100 5\nEND\n
 CONVERGED IN   2 ITERATIONS
 NODE RESULTS
 ID       TYPE       ELEV    DEMAND      HEAD  PRESSURE       KPA
 R        RESV    100.000     -8.00   100.000     0.000       0.0
 a        JUNC     10.000      5.00    98.820    88.820     869.5
 b        JUNC     20.000      3.00    98.783    78.783     771.3
 LINK RESULTS
 p        PIPE  R        a             8.00     1.019     1.180   0.02230  OPEN    
 v        VALVE a        b             3.00     0.382     0.037            OPEN    
 TOTAL DEMAND :      8.00 L/S
 TOTAL SUPPLY :      8.00 L/S
 RUN COMPLETED WITH   0 WARNING(S)
rc=0
##### RESERVOIR R 100\nJUNCTION a 10 5\nJUNCTION b 20 3\nPIPE p R a 100 100 0.1\nVALVE v a b 100 5 CLOSED\nEND\n
 *** WARNING W204: NODE 'b' IS ISOLATED
 CONVERGED IN   2 ITERATIONS
 NODE RESULTS
 ID       TYPE       ELEV    DEMAND      HEAD  PRESSURE       KPA
 R        RESV    100.000     -5.00   100.000     0.000       0.0
 a        JUNC     10.000      5.00    99.516    89.516     876.4
 b        JUNC     20.000      3.00    ISOLATED
 LINK RESULTS
 p        PIPE  R        a             5.00     0.637     0.484   0.02345  OPEN    
 v        VALVE a        b             0.00     0.000     0.000            CLOSED  
 TOTAL DEMAND :      5.00 L/S
 TOTAL SUPPLY :      5.00 L/S
 RUN COMPLETED WITH   1 WARNING(S)
rc=0
##### RESERVOIR R 100\nJUNCTION a 10 5\nJUNCTION b 20 3\nPIPE p R a 100 100 0.1\nVALVE v a b 100 5 OPEN\nPATTERN pp 1 2 3\nEND\n
 CONVERGED IN   2 ITERATIONS
 NODE RESULTS
 ID       TYPE       ELEV    DEMAND      HEAD  PRESSURE       KPA
 R        RESV    100.000     -8.00   100.000     0.000       0.0
 a        JUNC     10.000      5.00    98.820    88.820     869.5
 b        JUNC     20.000      3.00    98.783    78.783     771.3
 LINK RESULTS
 p        PIPE  R        a             8.00     1.019     1.180   0.02230  OPEN    
 v        VALVE a        b             3.00     0.382     0.037            OPEN    
 TOTAL DEMAND :      8.00 L/S
 TOTAL SUPPLY :      8.00 L/S
 RUN COMPLETED WITH   0 WARNING(S)
rc=0
```
</details>

### Step 39: Bash

```bash
docker exec sn-fortran-solver-parity bash -lc 'cd /w; . ./t.sh
F="grep -e \*\*\* -e \" [pv] \" -e \" [ab] \" -e DEMAND"
t "RESERVOIR R 100\nJUNCTION a 10 5\nJUNCTION b 20 3\nPIPE p R a 100 100 0.1 0 CLOSED\nPIPE v a b 100 100 0.1 0.5 OPEN\nEND\n" | grep -e "\*\*\*" -e " [pv] " -e " [ab] "
t "RESERVOIR R 100\nJUNCTION a 10 5\nJUNCTION b 20 3\nPIPE p R a 100 100 0.1 CLOSED\nPIPE v a b 100 100 0.1 0.5 OPEN\nEND\n" | grep -e "\*\*\*" -e " [pv] " -e " [ab] "
t "RESERVOIR R 100 5\nJUNCTION a 10\nJUNCTION b 20 3 pp 4\nPIPE p R a 100 100\nEND\n" | grep -e "\*\*\*" -e " [pv] " -e " [ab] "
t "RESERVOIR R 100\nJUNCTION a 10 5 nopat\nPIPE p R a 100 100 0.1\nEND\n" | grep -e "\*\*\*" -e " [pv] " -e " [ab] "
t "RESERVOIR R 100\nJUNCTION a 10 5\nPIPE p R a 100 100 0.1\nPUMP u R a 10 20 5\nPUMP u2 R a 10 -5\nPUMP u3 R a -10 \nEND\n" | grep -e "\*\*\*" -e " [pv] " -e " [ab] "
'
```

<details><summary>output</summary>

```
##### RESERVOIR R 100\nJUNCTION a 10 5\nJUNCTION b 20 3\nPIPE p R a 100 100 0.1 0 CLOSED\nPIPE v a b 100 100 0.1 0.5 OPEN\nEND\n
 *** WARNING W209 LINE   4: EXTRA FIELDS IGNORED
 *** WARNING W209 LINE   5: EXTRA FIELDS IGNORED
 a        JUNC     10.000      5.00    98.820    88.820     869.5
 b        JUNC     20.000      3.00    98.629    78.629     769.8
 p        PIPE  R        a             8.00     1.019     1.180   0.02230  OPEN    
 v        PIPE  a        b             3.00     0.382     0.191   0.02514  OPEN    
##### RESERVOIR R 100\nJUNCTION a 10 5\nJUNCTION b 20 3\nPIPE p R a 100 100 0.1 CLOSED\nPIPE v a b 100 100 0.1 0.5 OPEN\nEND\n
 *** ERROR E104 LINE   4: BAD NUMBER 'CLOSED'
 *** WARNING W209 LINE   5: EXTRA FIELDS IGNORED
 *** RUN ABORTED:   1 INPUT ERROR(S)
##### RESERVOIR R 100 5\nJUNCTION a 10\nJUNCTION b 20 3 pp 4\nPIPE p R a 100 100\nEND\n
 *** WARNING W209 LINE   1: EXTRA FIELDS IGNORED
 *** WARNING W209 LINE   3: EXTRA FIELDS IGNORED
 *** ERROR E105 LINE   4: MISSING FIELD(S)
 *** ERROR E112 LINE   3: UNDEFINED PATTERN 'pp'
 *** RUN ABORTED:   2 INPUT ERROR(S)
##### RESERVOIR R 100\nJUNCTION a 10 5 nopat\nPIPE p R a 100 100 0.1\nEND\n
 *** ERROR E112 LINE   2: UNDEFINED PATTERN 'nopat'
 *** RUN ABORTED:   1 INPUT ERROR(S)
##### RESERVOIR R 100\nJUNCTION a 10 5\nPIPE p R a 100 100 0.1\nPUMP u R a 10 20 5\nPUMP u2 R a 10 -5\nPUMP u3 R a -10 \nEND\n
 *** WARNING W209 LINE   4: EXTRA FIELDS IGNORED
 *** ERROR E107 LINE   5: VALUE OUT OF RANGE
 *** ERROR E107 LINE   6: VALUE OUT OF RANGE
 *** RUN ABORTED:   2 INPUT ERROR(S)
```
</details>

### Step 40: Bash

```bash
docker exec sn-fortran-solver-parity bash -lc 'cd /w; . ./t.sh
t "RESERVOIR R 100\nEND\n"
t "JUNCTION a 10 5\nEND\n"
t "RESERVOIR R 100\nJUNCTION a 10 5\nEND\n"
t "RESERVOIR R 100\nRESERVOIR S 90\nPIPE p R S 100 100 0.1\nEND\n"
t "RESERVOIR R 100\nRESERVOIR S 100\nPIPE p R S 100 100 0.1\nEND\n"
t "RESERVOIR R 100\nJUNCTION a 10 5\nPIPE p R a 100 100 0.1\nPUMP u a R 0\nEND\n"
' | grep -v -e "^ *$" -e TITLE -e UNITS -e FRICTION  -e SOLVER -e "^ HYDRO" -e "\-\-\-"
```

<details><summary>output</summary>

```
##### RESERVOIR R 100\nEND\n
 NETWORK  :   1 NODES,   1 RESERVOIRS,   0 LINKS
 CONVERGED IN   1 ITERATIONS
 NODE RESULTS
 ID       TYPE       ELEV    DEMAND      HEAD  PRESSURE       KPA
 R        RESV    100.000     -0.00   100.000     0.000       0.0
 LINK RESULTS
 TOTAL DEMAND :      0.00 L/S
 TOTAL SUPPLY :      0.00 L/S
 RUN COMPLETED WITH   0 WARNING(S)
rc=0
##### JUNCTION a 10 5\nEND\n
 *** ERROR E302: NO FIXED-HEAD NODE
 *** RUN ABORTED:   1 INPUT ERROR(S)
STOP 1
rc=1
##### RESERVOIR R 100\nJUNCTION a 10 5\nEND\n
 NETWORK  :   2 NODES,   1 RESERVOIRS,   0 LINKS
 *** WARNING W204: NODE 'a' IS ISOLATED
 CONVERGED IN   1 ITERATIONS
 NODE RESULTS
 ID       TYPE       ELEV    DEMAND      HEAD  PRESSURE       KPA
 R        RESV    100.000     -0.00   100.000     0.000       0.0
 a        JUNC     10.000      5.00    ISOLATED
 LINK RESULTS
 TOTAL DEMAND :      0.00 L/S
 TOTAL SUPPLY :      0.00 L/S
 RUN COMPLETED WITH   1 WARNING(S)
rc=0
##### RESERVOIR R 100\nRESERVOIR S 90\nPIPE p R S 100 100 0.1\nEND\n
 NETWORK  :   2 NODES,   2 RESERVOIRS,   1 LINKS
 CONVERGED IN   8 ITERATIONS
 NODE RESULTS
 ID       TYPE       ELEV    DEMAND      HEAD  PRESSURE       KPA
 R        RESV    100.000    -24.16   100.000     0.000       0.0
 S        RESV     90.000     24.16    90.000     0.000       0.0
 LINK RESULTS
 p        PIPE  R        S            24.16     3.076    10.000   0.02072  OPEN    
 TOTAL DEMAND :      0.00 L/S
 TOTAL SUPPLY :      0.00 L/S
 *** WARNING W202: HIGH VELOCITY IN LINK 'p'
 RUN COMPLETED WITH   1 WARNING(S)
rc=0
##### RESERVOIR R 100\nRESERVOIR S 100\nPIPE p R S 100 100 0.1\nEND\n
 NETWORK  :   2 NODES,   2 RESERVOIRS,   1 LINKS
 CONVERGED IN   6 ITERATIONS
 NODE RESULTS
 ID       TYPE       ELEV    DEMAND      HEAD  PRESSURE       KPA
 R        RESV    100.000     -0.00   100.000     0.000       0.0
 S        RESV    100.000     -0.00   100.000     0.000       0.0
 LINK RESULTS
 p        PIPE  R        S             0.00     0.000     0.000     UNDEF  OPEN    
 TOTAL DEMAND :      0.00 L/S
 TOTAL SUPPLY :      0.00 L/S
 *** WARNING W203: ZERO FLOW IN LINK 'p'
 RUN COMPLETED WITH   1 WARNING(S)
rc=0
##### RESERVOIR R 100\nJUNCTION a 10 5\nPIPE p R a 100 100 0.1\nPUMP u a R 0\nEND\n
 *** ERROR E107 LINE   4: VALUE OUT OF RANGE
 *** RUN ABORTED:   1 INPUT ERROR(S)
STOP 1
rc=1
```
</details>

### Step 41: Bash

```bash
docker exec sn-fortran-solver-parity bash -lc 'cd /w; cat > c9.py <<EOF
from cal import *
for q in [20,23,23.5,23.6,24,30,35,40,50]:
    row,o=pipe("SI","DW",q,100,100,0.1,H=1000)
    print(q,row[43:53],[x for x in o.split("\n") if "WARN" in x])
EOF
python3 c9.py'
```

<details><summary>output</summary>

```
20      2.546 [' RUN COMPLETED WITH   0 WARNING(S)']
23      2.928 [' RUN COMPLETED WITH   0 WARNING(S)']
23.5      2.992 [' RUN COMPLETED WITH   0 WARNING(S)']
23.6      3.005 [" *** WARNING W202: HIGH VELOCITY IN LINK 'p'", ' RUN COMPLETED WITH   1 WARNING(S)']
24      3.056 [" *** WARNING W202: HIGH VELOCITY IN LINK 'p'", ' RUN COMPLETED WITH   1 WARNING(S)']
30      3.820 [" *** WARNING W202: HIGH VELOCITY IN LINK 'p'", ' RUN COMPLETED WITH   1 WARNING(S)']
35      4.456 [" *** WARNING W202: HIGH VELOCITY IN LINK 'p'", ' RUN COMPLETED WITH   1 WARNING(S)']
40      5.093 [" *** WARNING W202: HIGH VELOCITY IN LINK 'p'", ' RUN COMPLETED WITH   1 WARNING(S)']
50      6.366 [" *** WARNING W202: HIGH VELOCITY IN LINK 'p'", ' RUN COMPLETED WITH   1 WARNING(S)']
```
</details>

### Step 42: Bash

```bash
docker exec sn-fortran-solver-parity bash -lc 'cd /w; . ./t.sh; (echo "OPTION TOL 1e-20"; cat /app/examples/two-loops.dat) | /app/prod/hydro; echo; (echo "OPTION TOL 1e-20"; echo "OPTION MAXIT 3";echo "OPTION MAXIT 7000"; cat /app/examples/two-loops.dat) | /app/prod/hydro | head -12'
```

<details><summary>output</summary>

```
 HYDRO 2.3 - STEADY-STATE PIPE NETWORK ANALYSIS
 ----------------------------------------------
 
 TITLE    : Two loops
 UNITS    : SI (FLOW L/S, LENGTH M, DIAMETER MM)
 FRICTION : DARCY-WEISBACH
 NETWORK  :   4 NODES,   1 RESERVOIRS,   4 LINKS
 SOLVER   : TOL  1.0E-20, MAXIT  50
 
 *** WARNING W205: NOT CONVERGED AFTER 50 ITERATIONS
 
 NODE RESULTS
 ID       TYPE       ELEV    DEMAND      HEAD  PRESSURE       KPA
 -------- ----- --------- --------- --------- --------- ---------
 J1       JUNC     60.000     10.00    98.928    38.928     381.1
 J2       JUNC     55.000     15.00    98.277    43.277     423.7
 J3       JUNC     50.000     12.00    98.213    48.213     472.0
 R1       RESV    100.000    -37.00   100.000     0.000       0.0
 
 LINK RESULTS
 ID       TYPE  FROM     TO            FLOW  VELOCITY  HEADLOSS  FRICTION  STATUS
 -------- ----- -------- -------- --------- --------- --------- ---------  --------
 P1       PIPE  R1       J1           37.00     0.754     1.072   0.01850  OPEN    
 P2       PIPE  J1       J2           17.70     0.564     0.651   0.02011  OPEN    
 P3       PIPE  J2       J3            2.70     0.153     0.064   0.02663  OPEN    
 P4       PIPE  J1       J3            9.30     0.526     0.715   0.02172  OPEN    
 
 TOTAL DEMAND :     37.00 L/S
 TOTAL SUPPLY :     37.00 L/S

 RUN COMPLETED WITH   1 WARNING(S)
STOP 2

STOP 2
 HYDRO 2.3 - STEADY-STATE PIPE NETWORK ANALYSIS
 ----------------------------------------------
 *** WARNING W206 LINE   3: MAXIT LIMITED TO 200
 
 TITLE    : Two loops
 UNITS    : SI (FLOW L/S, LENGTH M, DIAMETER MM)
 FRICTION : DARCY-WEISBACH
 NETWORK  :   4 NODES,   1 RESERVOIRS,   4 LINKS
 SOLVER   : TOL  1.0E-20, MAXIT 200
 
 *** WARNING W205: NOT CONVERGED AFTER 200 ITERATIONS
```
</details>

### Step 43: Bash

```bash
docker exec sn-fortran-solver-parity bash -lc 'cd /w; . ./t.sh
B="RESERVOIR R 100\nJUNCTION a 10 5\n"
for c in "RESERVOIR" "RESERVOIR X" "RESERVOIR X abc" "JUNCTION" "JUNCTION X" "JUNCTION X 1 abc" "JUNCTION X 1 -5" "JUNCTION X -5 1" "RESERVOIR X -5" "JUNCTION X 1 1 pp" "PIPE" "PIPE p" "PIPE p R" "PIPE p R a" "PIPE p R a 1" "PIPE p R a 1 1" "PIPE p R a 1 1 0" "PIPE p R a 1 1 0 -1" "PIPE p R a 1 1 0 x" "PIPE p R a x 1 0" "PUMP" "PUMP u R a" "PUMP u R a x" "PUMP u R a 0" "PUMP u R a 5 0" "PUMP u R a 5 -1" "PUMP u R a 5 x" "VALVE" "VALVE v R a" "VALVE v R a 100" "VALVE v R a 100 0" "VALVE v R a 100 -1" "VALVE v R a 0 1" "VALVE v R a -5 1" "VALVE v R a 100 1 FOO" "VALVE v R a 100 1 closed" "VALVE v R a 100 1 open extra" "PATTERN" "PATTERN pp" "PATTERN pp x" "PATTERN pp -1" "PATTERN pp 0" "PATTERN pp 1 2 x" "UNITS" "UNITS si" "UNITS Us" "UNITS SI X" "TITLE" "OPTION" "OPTION TOL" "OPTION FRICTION" "OPTION STEPS" "OPTION HSTEP" "OPTION MAXIT x" "OPTION STEPS 0" "OPTION STEPS -1" "OPTION STEPS 24" "OPTION STEPS 25" "OPTION STEPS 100" "OPTION STEPS 101" ; do echo "=== $c"; printf "${B}$c\nEND\n" | /app/prod/hydro 2>&1 | grep -e "\*\*\*" -e "^ NETWORK" -e "^ STEPS"; done' 2>&1
```

<details><summary>output</summary>

```
=== RESERVOIR
 *** ERROR E105 LINE   3: MISSING FIELD(S)
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== RESERVOIR X
 *** ERROR E105 LINE   3: MISSING FIELD(S)
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== RESERVOIR X abc
 *** ERROR E104 LINE   3: BAD NUMBER 'abc'
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== JUNCTION
 *** ERROR E105 LINE   3: MISSING FIELD(S)
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== JUNCTION X
 *** ERROR E105 LINE   3: MISSING FIELD(S)
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== JUNCTION X 1 abc
 *** ERROR E104 LINE   3: BAD NUMBER 'abc'
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== JUNCTION X 1 -5
 NETWORK  :   3 NODES,   1 RESERVOIRS,   0 LINKS
 *** WARNING W204: NODE 'X' IS ISOLATED
 *** WARNING W204: NODE 'a' IS ISOLATED
=== JUNCTION X -5 1
 NETWORK  :   3 NODES,   1 RESERVOIRS,   0 LINKS
 *** WARNING W204: NODE 'X' IS ISOLATED
 *** WARNING W204: NODE 'a' IS ISOLATED
=== RESERVOIR X -5
 NETWORK  :   3 NODES,   2 RESERVOIRS,   0 LINKS
 *** WARNING W204: NODE 'a' IS ISOLATED
=== JUNCTION X 1 1 pp
 *** ERROR E112 LINE   3: UNDEFINED PATTERN 'pp'
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== PIPE
 *** ERROR E105 LINE   3: MISSING FIELD(S)
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== PIPE p
 *** ERROR E105 LINE   3: MISSING FIELD(S)
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== PIPE p R
 *** ERROR E105 LINE   3: MISSING FIELD(S)
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== PIPE p R a
 *** ERROR E105 LINE   3: MISSING FIELD(S)
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== PIPE p R a 1
 *** ERROR E105 LINE   3: MISSING FIELD(S)
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== PIPE p R a 1 1
 *** ERROR E105 LINE   3: MISSING FIELD(S)
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== PIPE p R a 1 1 0
 NETWORK  :   2 NODES,   1 RESERVOIRS,   1 LINKS
 a        JUNC     10.000      5.00******************************
 p        PIPE  R        a             5.00  6366.198**********   0.00869  OPEN    
 *** WARNING W201: NEGATIVE PRESSURE AT NODE 'a'
 *** WARNING W202: HIGH VELOCITY IN LINK 'p'
=== PIPE p R a 1 1 0 -1
 *** ERROR E107 LINE   3: VALUE OUT OF RANGE
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== PIPE p R a 1 1 0 x
 *** ERROR E104 LINE   3: BAD NUMBER 'x'
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== PIPE p R a x 1 0
 *** ERROR E104 LINE   3: BAD NUMBER 'x'
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== PUMP
 *** ERROR E105 LINE   3: MISSING FIELD(S)
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== PUMP u R a
 *** ERROR E105 LINE   3: MISSING FIELD(S)
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== PUMP u R a x
 *** ERROR E104 LINE   3: BAD NUMBER 'x'
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== PUMP u R a 0
 *** ERROR E107 LINE   3: VALUE OUT OF RANGE
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== PUMP u R a 5 0
 *** ERROR E107 LINE   3: VALUE OUT OF RANGE
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== PUMP u R a 5 -1
 *** ERROR E107 LINE   3: VALUE OUT OF RANGE
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== PUMP u R a 5 x
 *** ERROR E104 LINE   3: BAD NUMBER 'x'
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== VALVE
 *** ERROR E105 LINE   3: MISSING F
... [3378 more chars truncated]
```
</details>

### Step 44: Bash

```bash
docker exec sn-fortran-solver-parity bash -lc 'cd /w; . ./t.sh
B="RESERVOIR R 100\nJUNCTION a 10 5\n"
for c in "PIPE p R zz x 1 0" "PIPE p zz zz 1 1 0" "PIPE p zz zz 0 1 0" "PIPE p R R 0 1 0" "PIPE p R R x 1 0" "PIPE a R a 100 100 0.1" "PIPE R R a 100 100 0.1" "JUNCTION p 1 1\nPIPE p R a 100 100 0.1" "JUNCTION a 1 x" "JUNCTION a x 1" "JUNCTION a x x" "JUNCTION 1234567890 1 1\nJUNCTION 12345678ab 1 1\nPIPE LONGLINK12 R 1234567890 100 100 0.1\nPIPE LONGLINK13 R 12345678zz 100 100 0.1" "JUNCTION A 1 1\nPIPE p R A 100 100 0.1" "JUNCTION Q 1 1\nPIPE p R q 100 100 0.1" "PUMP u R a 0 x" "PUMP u R a -1 x" "VALVE v zz a 0 1" "PATTERN pp 1\nPATTERN PP 1" "PATTERN pp 1\nPATTERN pp 2\nJUNCTION b 1 1 pp" "JUNCTION b 1 1 PP\nPATTERN pp 1"  ; do echo "=== $c"; printf "${B}$c\nEND\n" | /app/prod/hydro 2>&1 | grep -e "\*\*\*" -e "^ NETWORK" -e "^ STEPS" -e "ABORT" -e " [Pp][0-9A-Za-z]* *PIPE"; done' 2>&1
```

<details><summary>output</summary>

```
=== PIPE p R zz x 1 0
 *** ERROR E104 LINE   3: BAD NUMBER 'x'
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== PIPE p zz zz 1 1 0
 *** ERROR E110 LINE   3: LINK CONNECTS NODE TO ITSELF
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== PIPE p zz zz 0 1 0
 *** ERROR E110 LINE   3: LINK CONNECTS NODE TO ITSELF
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== PIPE p R R 0 1 0
 *** ERROR E110 LINE   3: LINK CONNECTS NODE TO ITSELF
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== PIPE p R R x 1 0
 *** ERROR E110 LINE   3: LINK CONNECTS NODE TO ITSELF
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== PIPE a R a 100 100 0.1
 NETWORK  :   2 NODES,   1 RESERVOIRS,   1 LINKS
=== PIPE R R a 100 100 0.1
 NETWORK  :   2 NODES,   1 RESERVOIRS,   1 LINKS
=== JUNCTION p 1 1\nPIPE p R a 100 100 0.1
 NETWORK  :   3 NODES,   1 RESERVOIRS,   1 LINKS
 *** WARNING W204: NODE 'p' IS ISOLATED
 p        PIPE  R        a             5.00     0.637     0.484   0.02345  OPEN    
=== JUNCTION a 1 x
 *** ERROR E102 LINE   3: DUPLICATE ID 'a'
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== JUNCTION a x 1
 *** ERROR E102 LINE   3: DUPLICATE ID 'a'
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== JUNCTION a x x
 *** ERROR E102 LINE   3: DUPLICATE ID 'a'
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== JUNCTION 1234567890 1 1\nJUNCTION 12345678ab 1 1\nPIPE LONGLINK12 R 1234567890 100 100 0.1\nPIPE LONGLINK13 R 12345678zz 100 100 0.1
 *** ERROR E106 LINE   3: ID TOO LONG '1234567890'
 *** ERROR E106 LINE   4: ID TOO LONG '12345678ab'
 *** ERROR E106 LINE   5: ID TOO LONG 'LONGLINK12'
 *** ERROR E106 LINE   6: ID TOO LONG 'LONGLINK13'
 *** RUN ABORTED:   4 INPUT ERROR(S)
=== JUNCTION A 1 1\nPIPE p R A 100 100 0.1
 NETWORK  :   3 NODES,   1 RESERVOIRS,   1 LINKS
 *** WARNING W204: NODE 'a' IS ISOLATED
 p        PIPE  R        A             1.00     0.127     0.026   0.03090  OPEN    
=== JUNCTION Q 1 1\nPIPE p R q 100 100 0.1
 *** ERROR E103 LINE   4: UNDEFINED NODE 'q'
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== PUMP u R a 0 x
 *** ERROR E104 LINE   3: BAD NUMBER 'x'
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== PUMP u R a -1 x
 *** ERROR E104 LINE   3: BAD NUMBER 'x'
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== VALVE v zz a 0 1
 *** ERROR E107 LINE   3: VALUE OUT OF RANGE
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== PATTERN pp 1\nPATTERN PP 1
 NETWORK  :   2 NODES,   1 RESERVOIRS,   0 LINKS
 *** WARNING W204: NODE 'a' IS ISOLATED
=== PATTERN pp 1\nPATTERN pp 2\nJUNCTION b 1 1 pp
 NETWORK  :   3 NODES,   1 RESERVOIRS,   0 LINKS
 *** WARNING W204: NODE 'a' IS ISOLATED
 *** WARNING W204: NODE 'b' IS ISOLATED
=== JUNCTION b 1 1 PP\nPATTERN pp 1
 *** ERROR E112 LINE   3: UNDEFINED PATTERN 'PP'
 *** RUN ABORTED:   1 INPUT ERROR(S)
```
</details>

### Step 45: Bash

```bash
docker exec sn-fortran-solver-parity bash -lc 'cd /w; . ./t.sh
B="RESERVOIR R 100\nJUNCTION a 10 5\nPIPE q R a 1 1 1\n"
for c in "PIPE p zz yy 100 100 0.1" "PIPE p zz R 100 100 0.1" "PIPE p R yy 100 100 0.1" "PIPE q zz yy 100 100 0.1" "PIPE q R a x 100 0.1" "PIPE q R a 0 y 0.1" "PIPE q R a 0 -1 z" "PIPE 12345678 R a 1 1 1\nPIPE 123456789 R a 1 1 1" "JUNCTION 12345678 1 1\nJUNCTION 123456789 1 1" "JUNCTION a 1 1 123456789\nPATTERN 123456789 1\nPATTERN 12345678 1 \nPIPE p R a 1 1 1 1" "PATTERN 123456789 1" "JUNCTION b 1 1\nVALVE b R a 1 1 closed" "VALVE q R a 1 1 closed" "PUMP q R a 1 1" "PUMP p R yy x" "PUMP p yy a x" "PUMP p yy a 5 x" "JUNCTION b 1 1 xxxxxxxxxxxxx" "TITLE a\tb\tc" "RESERVOIR R2 1\tx"; do echo "=== $c"; printf "${B}$c\nEND\n" | /app/prod/hydro 2>&1 | grep -e "\*\*\*" -e "ABORT" -e TITLE; done' 2>&1
```

<details><summary>output</summary>

```
=== PIPE p zz yy 100 100 0.1
 *** ERROR E103 LINE   4: UNDEFINED NODE 'zz'
 *** ERROR E103 LINE   4: UNDEFINED NODE 'yy'
 *** RUN ABORTED:   2 INPUT ERROR(S)
=== PIPE p zz R 100 100 0.1
 *** ERROR E103 LINE   4: UNDEFINED NODE 'zz'
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== PIPE p R yy 100 100 0.1
 *** ERROR E103 LINE   4: UNDEFINED NODE 'yy'
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== PIPE q zz yy 100 100 0.1
 *** ERROR E102 LINE   4: DUPLICATE ID 'q'
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== PIPE q R a x 100 0.1
 *** ERROR E102 LINE   4: DUPLICATE ID 'q'
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== PIPE q R a 0 y 0.1
 *** ERROR E102 LINE   4: DUPLICATE ID 'q'
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== PIPE q R a 0 -1 z
 *** ERROR E102 LINE   4: DUPLICATE ID 'q'
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== PIPE 12345678 R a 1 1 1\nPIPE 123456789 R a 1 1 1
 *** ERROR E106 LINE   5: ID TOO LONG '123456789'
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== JUNCTION 12345678 1 1\nJUNCTION 123456789 1 1
 *** ERROR E106 LINE   5: ID TOO LONG '123456789'
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== JUNCTION a 1 1 123456789\nPATTERN 123456789 1\nPATTERN 12345678 1 \nPIPE p R a 1 1 1 1
 *** ERROR E106 LINE   4: ID TOO LONG '123456789'
 *** ERROR E106 LINE   5: ID TOO LONG '123456789'
 *** RUN ABORTED:   2 INPUT ERROR(S)
=== PATTERN 123456789 1
 *** ERROR E106 LINE   4: ID TOO LONG '123456789'
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== JUNCTION b 1 1\nVALVE b R a 1 1 closed
 TITLE    : (NONE)
 *** WARNING W204: NODE 'b' IS ISOLATED
 a        JUNC     10.000      5.00******************************
 q        PIPE  R        a             5.00  6366.198**********   0.77436  OPEN    
 b        VALVE R        a             0.00     0.000**********            CLOSED  
 *** WARNING W201: NEGATIVE PRESSURE AT NODE 'a'
 *** WARNING W202: HIGH VELOCITY IN LINK 'q'
=== VALVE q R a 1 1 closed
 *** ERROR E102 LINE   4: DUPLICATE ID 'q'
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== PUMP q R a 1 1
 *** ERROR E102 LINE   4: DUPLICATE ID 'q'
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== PUMP p R yy x
 *** ERROR E104 LINE   4: BAD NUMBER 'x'
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== PUMP p yy a x
 *** ERROR E104 LINE   4: BAD NUMBER 'x'
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== PUMP p yy a 5 x
 *** ERROR E104 LINE   4: BAD NUMBER 'x'
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== JUNCTION b 1 1 xxxxxxxxxxxxx
 *** ERROR E106 LINE   4: ID TOO LONG 'xxxxxxxxxxxxx'
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== TITLE a\tb\tc
 TITLE    : a b c
 a        JUNC     10.000      5.00******************************
 q        PIPE  R        a             5.00  6366.198**********   0.77436  OPEN    
 *** WARNING W201: NEGATIVE PRESSURE AT NODE 'a'
 *** WARNING W202: HIGH VELOCITY IN LINK 'q'
=== RESERVOIR R2 1\tx
 *** WARNING W209 LINE   4: EXTRA FIELDS IGNORED
 TITLE    : (NONE)
 a        JUNC     10.000      5.00******************************
 q        PIPE  R        a             5.00  6366.198**********   0.77436  OPEN    
 *** WARNING W
... [79 more chars truncated]
```
</details>

### Step 46: Bash

```bash
docker exec sn-fortran-solver-parity bash -lc 'cd /w; . ./t.sh
B="RESERVOIR R 100\nJUNCTION a 10 5\nPIPE q R a 100 100 0.1\n"
for c in "TITLE   Hello   World  " "title Hello ! comment here" "TITLE ! only comment" "TITLE x\nTITLE y" "TITLE x\nTITLE" "TITLE 0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890" "TITLE   a\tb" "   TITLE indented" "* comment\nTITLE after star" " * not comment" "TITLE x!y" "TITLE a  !b  !c" "!whole line comment" "\n\n   \nTITLE blank before" "TITLEX abc" "TITLE=abc" ; do echo "=== $c"; printf "${B}$c\nEND\n" | /app/prod/hydro 2>&1 | grep -e "\*\*\*" -e "ABORT" -e "TITLE" | cat -A; done' 2>&1
```

<details><summary>output</summary>

```
=== TITLE   Hello   World  
 TITLE    : Hello   World$
=== title Hello ! comment here
 TITLE    : Hello$
=== TITLE ! only comment
 TITLE    : (NONE)$
=== TITLE x\nTITLE y
 TITLE    : y$
=== TITLE x\nTITLE
 TITLE    : (NONE)$
=== TITLE 0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890
 TITLE    : 012345678901234567890123456789012345678901234567890123456789$
=== TITLE   a\tb
 TITLE    : a b$
===    TITLE indented
 TITLE    : indented$
=== * comment\nTITLE after star
 TITLE    : after star$
===  * not comment
 *** ERROR E101 LINE   4: UNKNOWN CARD '*'$
 *** RUN ABORTED:   1 INPUT ERROR(S)$
=== TITLE x!y
 TITLE    : x$
=== TITLE a  !b  !c
 TITLE    : a$
=== !whole line comment
 TITLE    : (NONE)$
=== \n\n   \nTITLE blank before
 TITLE    : blank before$
=== TITLEX abc
 *** ERROR E101 LINE   4: UNKNOWN CARD 'TITLEX'$
 *** RUN ABORTED:   1 INPUT ERROR(S)$
=== TITLE=abc
 *** ERROR E101 LINE   4: UNKNOWN CARD 'TITLE=ABC'$
 *** RUN ABORTED:   1 INPUT ERROR(S)$
```
</details>

### Step 47: Bash

```bash
docker exec sn-fortran-solver-parity bash -lc 'cd /w; . ./t.sh
B="RESERVOIR R 100\nJUNCTION a 10 5\nPIPE q R a 100 100 0.1\n"
L=abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz0123456789abcdefghij
for c in "$L" "OPTION $L 1" "OPTION TOL $L" "OPTION FRICTION $L" "OPTION FRICTION xYz" "OPTION frICtion hW" "PIPE p2 R $L 1 1 1" "PIPE p3 R a 1 1 $L" "PIPE $L R a 1 1 1" "UNITS $L" "JUNCTION $L 1" "JUNCTION b 1 1 $L" "VALVE v R a 1 1 $L" "PIPE p4 R a 100 100 0.1                                                    0.5 1" "PIPE p4 R a 100 100 0.1                                                     0.5 1"; do echo "=== $c"; printf "${B}$c\nEND\n" | /app/prod/hydro 2>&1 | grep -e "\*\*\*" -e "ABORT" | cat -A; done' 2>&1
```

<details><summary>output</summary>

```
=== abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz0123456789abcdefghij
 *** ERROR E101 LINE   4: UNKNOWN CARD 'ABCDEFGHIJKLMNOP'$
 *** RUN ABORTED:   1 INPUT ERROR(S)$
=== OPTION abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz0123456789abcdefghij 1
 *** ERROR E105 LINE   4: MISSING FIELD(S)$
 *** RUN ABORTED:   1 INPUT ERROR(S)$
=== OPTION TOL abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz0123456789abcdefghij
 *** ERROR E104 LINE   4: BAD NUMBER 'abcdefghijklmnopqrstuvwxyz0123456789abcd'$
 *** RUN ABORTED:   1 INPUT ERROR(S)$
=== OPTION FRICTION abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz0123456789abcdefghij
 *** ERROR E108 LINE   4: INVALID OPTION VALUE 'abcdefghijklmnopqrstuvwxyz0123456789abcd'$
 *** RUN ABORTED:   1 INPUT ERROR(S)$
=== OPTION FRICTION xYz
 *** ERROR E108 LINE   4: INVALID OPTION VALUE 'xYz'$
 *** RUN ABORTED:   1 INPUT ERROR(S)$
=== OPTION frICtion hW
 a        JUNC     10.000      5.00********************-3021278.8$
 *** WARNING W201: NEGATIVE PRESSURE AT NODE 'a'$
=== PIPE p2 R abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz0123456789abcdefghij 1 1 1
 *** ERROR E105 LINE   4: MISSING FIELD(S)$
 *** RUN ABORTED:   1 INPUT ERROR(S)$
=== PIPE p3 R a 1 1 abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz0123456789abcdefghij
 *** ERROR E104 LINE   4: BAD NUMBER 'abcdefghijklmnopqrstuvwxyz0123456789abcd'$
 *** RUN ABORTED:   1 INPUT ERROR(S)$
=== PIPE abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz0123456789abcdefghij R a 1 1 1
 *** ERROR E105 LINE   4: MISSING FIELD(S)$
 *** RUN ABORTED:   1 INPUT ERROR(S)$
=== UNITS abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz0123456789abcdefghij
 *** ERROR E108 LINE   4: INVALID OPTION VALUE 'abcdefghijklmnopqrstuvwxyz0123456789abcd'$
 *** RUN ABORTED:   1 INPUT ERROR(S)$
=== JUNCTION abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz0123456789abcdefghij 1
 *** ERROR E105 LINE   4: MISSING FIELD(S)$
 *** RUN ABORTED:   1 INPUT ERROR(S)$
=== JUNCTION b 1 1 abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz0123456789abcdefghij
 *** ERROR E106 LINE   4: ID TOO LONG 'abcdefghijklmnopqrstuvwxyz0123456789abcd'$
 *** RUN ABORTED:   1 INPUT ERROR(S)$
=== VALVE v R a 1 1 abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz0123456789abcdefghij
 *** ERROR E108 LINE   4: INVALID OPTION VALUE 'abcdefghijklmnopqrstuvwxyz0123456789abcd'$
 *** RUN ABORTED:   1 INPUT ERROR(S)$
=== PIPE p4 R a 100 100 0.1                                                    0.5 1
 *** WARNING W209 LINE   4: EXTRA FIELDS IGNORED$
=== PIPE p4 R a 100 100 0.1                                                     0.5 1
```
</details>

### Step 48: Bash

```bash
docker exec sn-fortran-solver-parity bash -lc 'cd /w; . ./t.sh
B="RESERVOIR R 100\nJUNCTION a 10 5\nPIPE q R a 100 100 0.1\n"
L=abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz0123456789abcdefghij
for c in "OPTION foo 1" "OPTION $L 1 2" "PIPE p R $L 100 100 0.1" "PIPE p $L R 100 100 0.1" "PIPE $L R a 100 100 0.1" "PIPE p R a 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1" "PIPE p R a 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1" "PATTERN pp $L" "OPTION TOL 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19"  "OPTION TOL 1e-4 \t!c"; do echo "=== $c"; printf "${B}$c\nEND\n" | /app/prod/hydro 2>&1 | grep -e "\*\*\*" -e "ABORT" | cat -A; done' 2>&1
```

<details><summary>output</summary>

```
=== OPTION foo 1
 *** ERROR E109 LINE   4: UNKNOWN OPTION 'FOO'$
 *** RUN ABORTED:   1 INPUT ERROR(S)$
=== OPTION abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz0123456789abcdefghij 1 2
 *** ERROR E105 LINE   4: MISSING FIELD(S)$
 *** RUN ABORTED:   1 INPUT ERROR(S)$
=== PIPE p R abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz0123456789abcdefghij 100 100 0.1
 *** ERROR E105 LINE   4: MISSING FIELD(S)$
 *** RUN ABORTED:   1 INPUT ERROR(S)$
=== PIPE p abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz0123456789abcdefghij R 100 100 0.1
 *** ERROR E105 LINE   4: MISSING FIELD(S)$
 *** RUN ABORTED:   1 INPUT ERROR(S)$
=== PIPE abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz0123456789abcdefghij R a 100 100 0.1
 *** ERROR E105 LINE   4: MISSING FIELD(S)$
 *** RUN ABORTED:   1 INPUT ERROR(S)$
=== PIPE p R a 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1
 *** WARNING W209 LINE   4: EXTRA FIELDS IGNORED$
 *** WARNING W203: ZERO FLOW IN LINK 'p'$
=== PIPE p R a 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1
 *** WARNING W209 LINE   4: EXTRA FIELDS IGNORED$
 *** WARNING W203: ZERO FLOW IN LINK 'p'$
=== PATTERN pp abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz0123456789abcdefghij
 *** ERROR E104 LINE   4: BAD NUMBER 'abcdefghijklmnopqrstuvwxyz0123456789abcd'$
 *** RUN ABORTED:   1 INPUT ERROR(S)$
=== OPTION TOL 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19
 *** WARNING W209 LINE   4: EXTRA FIELDS IGNORED$
=== OPTION TOL 1e-4 \t!c
```
</details>

### Step 49: Bash

```bash
docker exec sn-fortran-solver-parity bash -lc 'cd /w; cat > big.py <<EOF
import subprocess,sys
def run(d): return subprocess.run(["/app/prod/hydro"],input=d,capture_output=True,text=True)
for n in [100,101,150,200,201,256,300,500,1000,1001]:
    d="RESERVOIR R 100\n"+"".join("JUNCTION j%d 10 0.01\n"%i for i in range(n-1))+"".join("PIPE p%d R j%d 100 100 0.1\n"%(i,i) for i in range(n-1))+"END\n"
    r=run(d)
    print(n,r.returncode,[l for l in r.stdout.split("\n") if "***" in l][:3], [l for l in r.stdout.split("\n") if "NETWORK" in l])
for n in [100,150,151,200,300,500,1000]:
    d="RESERVOIR R 100\nJUNCTION a 10 0.01\n"+"".join("PIPE p%d R a 100 100 0.1\n"%(i) for i in range(n))+"END\n"
    r=run(d)
    print("links",n,r.returncode,[l for l in r.stdout.split("\n") if "***" in l][:3], [l for l in r.stdout.split("\n") if "NETWORK" in l])
EOF
python3 big.py'
```

<details><summary>output</summary>

```
100 0 [] [' HYDRO 2.3 - STEADY-STATE PIPE NETWORK ANALYSIS', ' NETWORK  : 100 NODES,   1 RESERVOIRS,  99 LINKS']
101 1 [' *** ERROR E111 LINE 101: TOO MANY NODES', " *** ERROR E103 LINE 201: UNDEFINED NODE 'j99'", ' *** RUN ABORTED:   2 INPUT ERROR(S)'] [' HYDRO 2.3 - STEADY-STATE PIPE NETWORK ANALYSIS']
150 1 [' *** ERROR E111 LINE 101: TOO MANY NODES', ' *** ERROR E111 LINE 102: TOO MANY NODES', ' *** ERROR E111 LINE 103: TOO MANY NODES'] [' HYDRO 2.3 - STEADY-STATE PIPE NETWORK ANALYSIS']
200 1 [' *** ERROR E111 LINE 101: TOO MANY NODES', ' *** ERROR E111 LINE 102: TOO MANY NODES', ' *** ERROR E111 LINE 103: TOO MANY NODES'] [' HYDRO 2.3 - STEADY-STATE PIPE NETWORK ANALYSIS']
201 1 [' *** ERROR E111 LINE 101: TOO MANY NODES', ' *** ERROR E111 LINE 102: TOO MANY NODES', ' *** ERROR E111 LINE 103: TOO MANY NODES'] [' HYDRO 2.3 - STEADY-STATE PIPE NETWORK ANALYSIS']
256 1 [' *** ERROR E111 LINE 101: TOO MANY NODES', ' *** ERROR E111 LINE 102: TOO MANY NODES', ' *** ERROR E111 LINE 103: TOO MANY NODES'] [' HYDRO 2.3 - STEADY-STATE PIPE NETWORK ANALYSIS']
300 1 [' *** ERROR E111 LINE 101: TOO MANY NODES', ' *** ERROR E111 LINE 102: TOO MANY NODES', ' *** ERROR E111 LINE 103: TOO MANY NODES'] [' HYDRO 2.3 - STEADY-STATE PIPE NETWORK ANALYSIS']
500 1 [' *** ERROR E111 LINE 101: TOO MANY NODES', ' *** ERROR E111 LINE 102: TOO MANY NODES', ' *** ERROR E111 LINE 103: TOO MANY NODES'] [' HYDRO 2.3 - STEADY-STATE PIPE NETWORK ANALYSIS']
1000 1 [' *** ERROR E111 LINE 101: TOO MANY NODES', ' *** ERROR E111 LINE 102: TOO MANY NODES', ' *** ERROR E111 LINE 103: TOO MANY NODES'] [' HYDRO 2.3 - STEADY-STATE PIPE NETWORK ANALYSIS']
1001 1 [' *** ERROR E111 LINE 101: TOO MANY NODES', ' *** ERROR E111 LINE 102: TOO MANY NODES', ' *** ERROR E111 LINE 103: TOO MANY NODES'] [' HYDRO 2.3 - STEADY-STATE PIPE NETWORK ANALYSIS']
links 100 0 [" *** WARNING W203: ZERO FLOW IN LINK 'p0'", " *** WARNING W203: ZERO FLOW IN LINK 'p1'", " *** WARNING W203: ZERO FLOW IN LINK 'p2'"] [' HYDRO 2.3 - STEADY-STATE PIPE NETWORK ANALYSIS', ' NETWORK  :   2 NODES,   1 RESERVOIRS, 100 LINKS']
links 150 0 [" *** WARNING W203: ZERO FLOW IN LINK 'p0'", " *** WARNING W203: ZERO FLOW IN LINK 'p1'", " *** WARNING W203: ZERO FLOW IN LINK 'p2'"] [' HYDRO 2.3 - STEADY-STATE PIPE NETWORK ANALYSIS', ' NETWORK  :   2 NODES,   1 RESERVOIRS, 150 LINKS']
links 151 1 [' *** ERROR E111 LINE 153: TOO MANY LINKS', ' *** RUN ABORTED:   1 INPUT ERROR(S)'] [' HYDRO 2.3 - STEADY-STATE PIPE NETWORK ANALYSIS']
links 200 1 [' *** ERROR E111 LINE 153: TOO MANY LINKS', ' *** ERROR E111 LINE 154: TOO MANY LINKS', ' *** ERROR E111 LINE 155: TOO MANY LINKS'] [' HYDRO 2.3 - STEADY-STATE PIPE NETWORK ANALYSIS']
links 300 1 [' *** ERROR E111 LINE 153: TOO MANY LINKS', ' *** ERROR E111 LINE 154: TOO MANY LINKS', ' *** ERROR E111 LINE 155: TOO MANY LINKS'] [' HYDRO 2.3 - STEADY-STATE PIPE NETWORK ANALYSIS']
links 500 1 [' *** ERROR E111 LINE 153: TOO MANY LINKS', ' *** ERROR E111 LINE 154: TOO MANY LINKS', ' *** ERROR E111
... [277 more chars truncated]
```
</details>

### Step 50: Bash

```bash
docker exec sn-fortran-solver-parity bash -lc 'cd /w; cat > big2.py <<EOF
import subprocess,sys
def run(d): return subprocess.run(["/app/prod/hydro"],input=d,capture_output=True,text=True)
n=1000
d="RESERVOIR R 100\n"+"".join("JUNCTION j%d 10 0.01\n"%i for i in range(n-1))+"END\n"
r=run(d); L=r.stdout.split("\n"); print(len(L),L[-6:])
# patterns count
for npat in [10,20,50,100,101,200]:
    d="RESERVOIR R 100\nJUNCTION a 1 1\n"+"".join("PATTERN p%d 1 2\n"%i for i in range(npat))+"END\n"
    r=run(d); print("pats",npat,[l for l in r.stdout.split("\n") if "***" in l][:3])
for nv in [10,24,25,48,60,100,101,200,500]:
    d="RESERVOIR R 100\nJUNCTION a 1 1\nPATTERN p "+" ".join(["1"]*nv)+"\nEND\n"
    r=run(d); print("vals one card",nv,[l for l in r.stdout.split("\n") if "***" in l][:3])
for nv in [8,9,10,11,12]:
    d="RESERVOIR R 100\nJUNCTION a 1 1\n"+"".join("PATTERN p %s\n"%" ".join(["1"]*10) for _ in range(nv))+"END\n"
    r=run(d); print("cards",nv,[l for l in r.stdout.split("\n") if "***" in l][:3])
EOF
python3 big2.py'
```

<details><summary>output</summary>

```
904 [' *** ERROR E111 LINE 997: TOO MANY NODES', ' *** ERROR E111 LINE 998: TOO MANY NODES', ' *** ERROR E111 LINE 999: TOO MANY NODES', ' *** ERROR E111 LINE1000: TOO MANY NODES', ' *** RUN ABORTED: 900 INPUT ERROR(S)', '']
pats 10 [" *** WARNING W204: NODE 'a' IS ISOLATED"]
pats 20 [' *** ERROR E111 LINE  13: TOO MANY PATTERNS', ' *** ERROR E111 LINE  14: TOO MANY PATTERNS', ' *** ERROR E111 LINE  15: TOO MANY PATTERNS']
pats 50 [' *** ERROR E111 LINE  13: TOO MANY PATTERNS', ' *** ERROR E111 LINE  14: TOO MANY PATTERNS', ' *** ERROR E111 LINE  15: TOO MANY PATTERNS']
pats 100 [' *** ERROR E111 LINE  13: TOO MANY PATTERNS', ' *** ERROR E111 LINE  14: TOO MANY PATTERNS', ' *** ERROR E111 LINE  15: TOO MANY PATTERNS']
pats 101 [' *** ERROR E111 LINE  13: TOO MANY PATTERNS', ' *** ERROR E111 LINE  14: TOO MANY PATTERNS', ' *** ERROR E111 LINE  15: TOO MANY PATTERNS']
pats 200 [' *** ERROR E111 LINE  13: TOO MANY PATTERNS', ' *** ERROR E111 LINE  14: TOO MANY PATTERNS', ' *** ERROR E111 LINE  15: TOO MANY PATTERNS']
vals one card 10 [" *** WARNING W204: NODE 'a' IS ISOLATED"]
vals one card 24 [" *** WARNING W204: NODE 'a' IS ISOLATED"]
vals one card 25 [" *** WARNING W204: NODE 'a' IS ISOLATED"]
vals one card 48 [" *** WARNING W204: NODE 'a' IS ISOLATED"]
vals one card 60 [" *** WARNING W204: NODE 'a' IS ISOLATED"]
vals one card 100 [" *** WARNING W204: NODE 'a' IS ISOLATED"]
vals one card 101 [" *** WARNING W204: NODE 'a' IS ISOLATED"]
vals one card 200 [" *** WARNING W204: NODE 'a' IS ISOLATED"]
vals one card 500 [" *** WARNING W204: NODE 'a' IS ISOLATED"]
cards 8 [' *** ERROR E113 LINE   5: PATTERN TOO LONG', ' *** ERROR E113 LINE   6: PATTERN TOO LONG', ' *** ERROR E113 LINE   7: PATTERN TOO LONG']
cards 9 [' *** ERROR E113 LINE   5: PATTERN TOO LONG', ' *** ERROR E113 LINE   6: PATTERN TOO LONG', ' *** ERROR E113 LINE   7: PATTERN TOO LONG']
cards 10 [' *** ERROR E113 LINE   5: PATTERN TOO LONG', ' *** ERROR E113 LINE   6: PATTERN TOO LONG', ' *** ERROR E113 LINE   7: PATTERN TOO LONG']
cards 11 [' *** ERROR E113 LINE   5: PATTERN TOO LONG', ' *** ERROR E113 LINE   6: PATTERN TOO LONG', ' *** ERROR E113 LINE   7: PATTERN TOO LONG']
cards 12 [' *** ERROR E113 LINE   5: PATTERN TOO LONG', ' *** ERROR E113 LINE   6: PATTERN TOO LONG', ' *** ERROR E113 LINE   7: PATTERN TOO LONG']
```
</details>

### Step 51: Bash

```bash
docker exec sn-fortran-solver-parity bash -lc 'cd /w; cat > big3.py <<EOF
import subprocess,sys
def run(d): return subprocess.run(["/app/prod/hydro"],input=d,capture_output=True,text=True)
def msgs(d): return [l for l in run(d).stdout.split("\n") if "***" in l]
for tot in range(20,30):
    d="RESERVOIR R 100\nJUNCTION a 1 1\nPIPE p R a 100 100 .1\nOPTION STEPS 24\nPATTERN p "+" ".join(["1"]*10)+"\nPATTERN p "+" ".join(["1"]*(tot-10))+"\nEND\n"
    print(tot,msgs(d))
for nv in [11,12,13,14,20]:
    d="RESERVOIR R 100\nJUNCTION a 1 1\nPATTERN p "+" ".join(["1"]*nv)+"\nEND\n"
    print("one",nv,msgs(d))
EOF
python3 big3.py'
```

<details><summary>output</summary>

```
20 []
21 []
22 []
23 []
24 []
25 []
26 []
27 []
28 []
29 []
one 11 [" *** WARNING W204: NODE 'a' IS ISOLATED"]
one 12 [" *** WARNING W204: NODE 'a' IS ISOLATED"]
one 13 [" *** WARNING W204: NODE 'a' IS ISOLATED"]
one 14 [" *** WARNING W204: NODE 'a' IS ISOLATED"]
one 20 [" *** WARNING W204: NODE 'a' IS ISOLATED"]
```
</details>

### Step 52: Bash

```bash
docker exec sn-fortran-solver-parity bash -lc 'cd /w; cat > big3.py <<EOF
import subprocess,sys
def run(d): return subprocess.run(["/app/prod/hydro"],input=d,capture_output=True,text=True)
def msgs(d): return [l for l in run(d).stdout.split("\n") if "***" in l]
for tot in [30,31,32,35,36,40,48,60]:
    cards=[];left=tot
    while left>0:
        k=min(10,left);cards.append("PATTERN p "+" ".join(["1"]*k));left-=k
    d="RESERVOIR R 100\nJUNCTION a 1 1\nPIPE p R a 100 100 .1\nOPTION STEPS 24\n"+"\n".join(cards)+"\nEND\n"
    print(tot,msgs(d))
EOF
python3 big3.py'
```

<details><summary>output</summary>

```
30 [' *** ERROR E113 LINE   7: PATTERN TOO LONG', ' *** RUN ABORTED:   1 INPUT ERROR(S)']
31 [' *** ERROR E113 LINE   7: PATTERN TOO LONG', ' *** RUN ABORTED:   1 INPUT ERROR(S)']
32 [' *** ERROR E113 LINE   7: PATTERN TOO LONG', ' *** RUN ABORTED:   1 INPUT ERROR(S)']
35 [' *** ERROR E113 LINE   7: PATTERN TOO LONG', ' *** ERROR E113 LINE   8: PATTERN TOO LONG', ' *** RUN ABORTED:   2 INPUT ERROR(S)']
36 [' *** ERROR E113 LINE   7: PATTERN TOO LONG', ' *** ERROR E113 LINE   8: PATTERN TOO LONG', ' *** RUN ABORTED:   2 INPUT ERROR(S)']
40 [' *** ERROR E113 LINE   7: PATTERN TOO LONG', ' *** ERROR E113 LINE   8: PATTERN TOO LONG', ' *** RUN ABORTED:   2 INPUT ERROR(S)']
48 [' *** ERROR E113 LINE   7: PATTERN TOO LONG', ' *** ERROR E113 LINE   8: PATTERN TOO LONG', ' *** ERROR E113 LINE   9: PATTERN TOO LONG', ' *** RUN ABORTED:   3 INPUT ERROR(S)']
60 [' *** ERROR E113 LINE   7: PATTERN TOO LONG', ' *** ERROR E113 LINE   8: PATTERN TOO LONG', ' *** ERROR E113 LINE   9: PATTERN TOO LONG', ' *** ERROR E113 LINE  10: PATTERN TOO LONG', ' *** RUN ABORTED:   4 INPUT ERROR(S)']
```
</details>

### Step 53: Bash

```bash
docker exec sn-fortran-solver-parity bash -lc 'cd /w; cat > big3.py <<EOF
import subprocess,sys
def run(d): return subprocess.run(["/app/prod/hydro"],input=d,capture_output=True,text=True)
def msgs(d): return [l for l in run(d).stdout.split("\n") if "***" in l]
for sp in [(10,19),(10,20),(10,21),(15,15),(15,14),(20,9),(20,10),(1,28),(1,29),(1,30),(5,5,5,5,5,4),(5,5,5,5,5,5),(5,5,5,5,5,5,5,5,5,5,5,5)]:
    cards=["PATTERN p "+" ".join(["1"]*k) for k in sp]
    d="RESERVOIR R 100\nJUNCTION a 1 1\nPIPE p R a 100 100 .1\nOPTION STEPS 24\n"+"\n".join(cards)+"\nEND\n"
    print(sp,sum(sp),msgs(d))
EOF
python3 big3.py'
```

<details><summary>output</summary>

```
(10, 19) 29 []
(10, 20) 30 []
(10, 21) 31 []
(15, 15) 30 [' *** ERROR E113 LINE   6: PATTERN TOO LONG', ' *** RUN ABORTED:   1 INPUT ERROR(S)']
(15, 14) 29 [' *** ERROR E113 LINE   6: PATTERN TOO LONG', ' *** RUN ABORTED:   1 INPUT ERROR(S)']
(20, 9) 29 []
(20, 10) 30 []
(1, 28) 29 []
(1, 29) 30 []
(1, 30) 31 []
(5, 5, 5, 5, 5, 4) 29 [' *** ERROR E113 LINE   9: PATTERN TOO LONG', ' *** RUN ABORTED:   1 INPUT ERROR(S)']
(5, 5, 5, 5, 5, 5) 30 [' *** ERROR E113 LINE   9: PATTERN TOO LONG', ' *** ERROR E113 LINE  10: PATTERN TOO LONG', ' *** RUN ABORTED:   2 INPUT ERROR(S)']
(5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5) 60 [' *** ERROR E113 LINE   9: PATTERN TOO LONG', ' *** ERROR E113 LINE  10: PATTERN TOO LONG', ' *** ERROR E113 LINE  11: PATTERN TOO LONG', ' *** ERROR E113 LINE  12: PATTERN TOO LONG', ' *** ERROR E113 LINE  13: PATTERN TOO LONG', ' *** ERROR E113 LINE  14: PATTERN TOO LONG', ' *** ERROR E113 LINE  15: PATTERN TOO LONG', ' *** ERROR E113 LINE  16: PATTERN TOO LONG', ' *** RUN ABORTED:   8 INPUT ERROR(S)']
```
</details>

### Step 54: Bash

```bash
docker exec sn-fortran-solver-parity bash -lc 'cd /w; . ./t.sh
t "OPTION STEPS 3\nOPTION HSTEP 0.5\nPATTERN pp 1 2 0.5\nRESERVOIR R 100\nJUNCTION a 10 5 pp\nJUNCTION b 10 3\nPIPE q R a 100 100 0.1\nPIPE q2 a b 100 100 0.1\nEND\n" | cat -A'
```

<details><summary>output</summary>

```
##### OPTION STEPS 3\nOPTION HSTEP 0.5\nPATTERN pp 1 2 0.5\nRESERVOIR R 100\nJUNCTION a 10 5 pp\nJUNCTION b 10 3\nPIPE q R a 100 100 0.1\nPIPE q2 a b 100 100 0.1\nEND\n$
 $
 TITLE    : (NONE)$
 UNITS    : SI (FLOW L/S, LENGTH M, DIAMETER MM)$
 FRICTION : DARCY-WEISBACH$
 NETWORK  :   3 NODES,   1 RESERVOIRS,   2 LINKS$
 SOLVER   : TOL  1.0E-05, MAXIT  50$
 STEPS    :  3 AT  0.50 H$
 $
 TIME STEP  1 OF  3  AT  0:00$
 CONVERGED IN   2 ITERATIONS$
 $
 NODE RESULTS$
 ID       TYPE       ELEV    DEMAND      HEAD  PRESSURE       KPA$
 R        RESV    100.000     -8.00   100.000     0.000       0.0$
 a        JUNC     10.000      5.00    98.820    88.820     869.5$
 b        JUNC     10.000      3.00    98.633    88.633     867.7$
 $
 LINK RESULTS$
 ID       TYPE  FROM     TO            FLOW  VELOCITY  HEADLOSS  FRICTION  STATUS$
 q        PIPE  R        a             8.00     1.019     1.180   0.02230  OPEN    $
 q2       PIPE  a        b             3.00     0.382     0.187   0.02514  OPEN    $
 $
 TOTAL DEMAND :      8.00 L/S$
 TOTAL SUPPLY :      8.00 L/S$
 $
 TIME STEP  2 OF  3  AT  0:30$
 CONVERGED IN   2 ITERATIONS$
 $
 NODE RESULTS$
 ID       TYPE       ELEV    DEMAND      HEAD  PRESSURE       KPA$
 R        RESV    100.000    -13.00   100.000     0.000       0.0$
 a        JUNC     10.000     10.00    97.004    87.004     851.8$
 b        JUNC     10.000      3.00    96.817    86.817     849.9$
 $
 LINK RESULTS$
 ID       TYPE  FROM     TO            FLOW  VELOCITY  HEADLOSS  FRICTION  STATUS$
 q        PIPE  R        a            13.00     1.655     2.996   0.02145  OPEN    $
 q2       PIPE  a        b             3.00     0.382     0.187   0.02514  OPEN    $
 $
 TOTAL DEMAND :     13.00 L/S$
 TOTAL SUPPLY :     13.00 L/S$
 $
 TIME STEP  3 OF  3  AT  1:00$
 CONVERGED IN   2 ITERATIONS$
 $
 NODE RESULTS$
 ID       TYPE       ELEV    DEMAND      HEAD  PRESSURE       KPA$
 R        RESV    100.000     -5.50   100.000     0.000       0.0$
 a        JUNC     10.000      2.50    99.420    89.420     875.4$
 b        JUNC     10.000      3.00    99.233    89.233     873.6$
 $
 LINK RESULTS$
 ID       TYPE  FROM     TO            FLOW  VELOCITY  HEADLOSS  FRICTION  STATUS$
 q        PIPE  R        a             5.50     0.700     0.580   0.02319  OPEN    $
 q2       PIPE  a        b             3.00     0.382     0.187   0.02514  OPEN    $
 $
 TOTAL DEMAND :      5.50 L/S$
 TOTAL SUPPLY :      5.50 L/S$
$
 RUN COMPLETED WITH   0 WARNING(S)$
rc=0$
```
</details>

### Step 55: Bash

```bash
docker exec sn-fortran-solver-parity bash -lc 'cd /w; . ./t.sh
t "OPTION STEPS 3\nPATTERN pp 1 8 1\nRESERVOIR R 100\nJUNCTION a 10 5 pp\nJUNCTION b 10 3 pp\nPIPE q R a 100 100 0.1\nPIPE q2 a b 100 100 0.1\nEND\n" | grep -v -e "^ *$" -e "^ [A-Z]  *[A-Z]* *[0-9]" -e "\-\-\-" -e "RESULTS" -e "ID  "'
```

<details><summary>output</summary>

```
##### OPTION STEPS 3\nPATTERN pp 1 8 1\nRESERVOIR R 100\nJUNCTION a 10 5 pp\nJUNCTION b 10 3 pp\nPIPE q R a 100 100 0.1\nPIPE q2 a b 100 100 0.1\nEND\n
 TITLE    : (NONE)
 UNITS    : SI (FLOW L/S, LENGTH M, DIAMETER MM)
 FRICTION : DARCY-WEISBACH
 NETWORK  :   3 NODES,   1 RESERVOIRS,   2 LINKS
 SOLVER   : TOL  1.0E-05, MAXIT  50
 STEPS    :  3 AT  1.00 H
 TIME STEP  1 OF  3  AT  0:00
 CONVERGED IN   2 ITERATIONS
 a        JUNC     10.000      5.00    98.820    88.820     869.5
 b        JUNC     10.000      3.00    98.633    88.633     867.7
 q        PIPE  R        a             8.00     1.019     1.180   0.02230  OPEN    
 q2       PIPE  a        b             3.00     0.382     0.187   0.02514  OPEN    
 TOTAL DEMAND :      8.00 L/S
 TOTAL SUPPLY :      8.00 L/S
 TIME STEP  2 OF  3  AT  1:00
 CONVERGED IN   2 ITERATIONS
 a        JUNC     10.000     40.00    31.928    21.928     214.7
 b        JUNC     10.000     24.00    22.059    12.059     118.1
 q        PIPE  R        a            64.00     8.149    68.072   0.02011  OPEN    
 q2       PIPE  a        b            24.00     3.056     9.869   0.02073  OPEN    
 TOTAL DEMAND :     64.00 L/S
 TOTAL SUPPLY :     64.00 L/S
 *** WARNING W202: HIGH VELOCITY IN LINK 'q'
 *** WARNING W202: HIGH VELOCITY IN LINK 'q2'
 TIME STEP  3 OF  3  AT  2:00
 CONVERGED IN   2 ITERATIONS
 a        JUNC     10.000      5.00    98.820    88.820     869.5
 b        JUNC     10.000      3.00    98.633    88.633     867.7
 q        PIPE  R        a             8.00     1.019     1.180   0.02230  OPEN    
 q2       PIPE  a        b             3.00     0.382     0.187   0.02514  OPEN    
 TOTAL DEMAND :      8.00 L/S
 TOTAL SUPPLY :      8.00 L/S
 RUN COMPLETED WITH   2 WARNING(S)
rc=0
```
</details>

### Step 56: Bash

```bash
docker exec sn-fortran-solver-parity bash -lc 'cd /w; . ./t.sh
t "JUNCTION z 10 5\nRESERVOIR T2 100\nJUNCTION b 10 5\nRESERVOIR S1 100\nJUNCTION m 10 5\nPIPE p1 T2 z 100 100 0.1\nPIPE p2 z b 100 100 0.1\nPIPE p3 b m 100 100 0.1\nPIPE p0 S1 m 100 100 0.1\nEND\n" | grep -e JUNC -e RESV -e PIPE'
```

<details><summary>output</summary>

```
##### JUNCTION z 10 5\nRESERVOIR T2 100\nJUNCTION b 10 5\nRESERVOIR S1 100\nJUNCTION m 10 5\nPIPE p1 T2 z 100 100 0.1\nPIPE p2 z b 100 100 0.1\nPIPE p3 b m 100 100 0.1\nPIPE p0 S1 m 100 100 0.1\nEND\n
 S1       RESV    100.000     -7.50   100.000     0.000       0.0
 T2       RESV    100.000     -7.50   100.000     0.000       0.0
 b        JUNC     10.000      5.00    98.823    88.823     869.6
 m        JUNC     10.000      5.00    98.957    88.957     870.9
 z        JUNC     10.000      5.00    98.957    88.957     870.9
 p1       PIPE  T2       z             7.50     0.955     1.043   0.02244  OPEN    
 p2       PIPE  z        b             2.50     0.318     0.134   0.02587  OPEN    
 p3       PIPE  b        m            -2.50    -0.318     0.134   0.02587  OPEN    
 p0       PIPE  S1       m             7.50     0.955     1.043   0.02244  OPEN
```
</details>

### Step 57: Bash

```bash
docker exec sn-fortran-solver-parity bash -lc 'cd /w; . ./t.sh
B="RESERVOIR R 100\n"
for c in "PIPE p R a 1 1 1\nJUNCTION b 1 1 nopat\nPIPE q R b 1 1 x\nJUNCTION a 1 1\nPIPE r R c 1 1 1" "JUNCTION b 1 1 nopat\nPIPE p R zz 1 1 1\nPIPE p R R 1 1 1\nFOO\nPIPE p2 R R 1 1 1" "PIPE p R a 1 1 1\nJUNCTION a 1 1" "PIPE p R R 1 1 1\nJUNCTION a 1 1\nPIPE p3 R a 1 1 -1" "PIPE p R a 1 1 1 x\nJUNCTION a 1 1\nPATTERN q x" "PUMP u R b 5\nPUMP u2 R b 5\nJUNCTION b 1 1"; do echo "=== $c"; printf "${B}$c\nEND\n" | /app/prod/hydro 2>&1 | grep -e "\*\*\*" -e "ABORT" ; done' 2>&1
```

<details><summary>output</summary>

```
Exit code 1
=== PIPE p R a 1 1 1\nJUNCTION b 1 1 nopat\nPIPE q R b 1 1 x\nJUNCTION a 1 1\nPIPE r R c 1 1 1
 *** ERROR E104 LINE   4: BAD NUMBER 'x'
 *** ERROR E103 LINE   6: UNDEFINED NODE 'c'
 *** ERROR E112 LINE   3: UNDEFINED PATTERN 'nopat'
 *** RUN ABORTED:   3 INPUT ERROR(S)
=== JUNCTION b 1 1 nopat\nPIPE p R zz 1 1 1\nPIPE p R R 1 1 1\nFOO\nPIPE p2 R R 1 1 1
 *** ERROR E102 LINE   4: DUPLICATE ID 'p'
 *** ERROR E101 LINE   5: UNKNOWN CARD 'FOO'
 *** ERROR E110 LINE   6: LINK CONNECTS NODE TO ITSELF
 *** ERROR E103 LINE   3: UNDEFINED NODE 'zz'
 *** ERROR E112 LINE   2: UNDEFINED PATTERN 'nopat'
 *** RUN ABORTED:   5 INPUT ERROR(S)
=== PIPE p R a 1 1 1\nJUNCTION a 1 1
 a        JUNC      1.000      1.00******************************
 p        PIPE  R        a             1.00  1273.240**********   0.77443  OPEN    
 *** WARNING W201: NEGATIVE PRESSURE AT NODE 'a'
 *** WARNING W202: HIGH VELOCITY IN LINK 'p'
=== PIPE p R R 1 1 1\nJUNCTION a 1 1\nPIPE p3 R a 1 1 -1
 *** ERROR E110 LINE   2: LINK CONNECTS NODE TO ITSELF
 *** ERROR E107 LINE   4: VALUE OUT OF RANGE
 *** RUN ABORTED:   2 INPUT ERROR(S)
=== PIPE p R a 1 1 1 x\nJUNCTION a 1 1\nPATTERN q x
 *** ERROR E104 LINE   2: BAD NUMBER 'x'
 *** ERROR E104 LINE   4: BAD NUMBER 'x'
 *** RUN ABORTED:   2 INPUT ERROR(S)
=== PUMP u R b 5\nPUMP u2 R b 5\nJUNCTION b 1 1
```
</details>

### Step 58: Bash

```bash
docker exec sn-fortran-solver-parity bash -lc 'cd /w; . ./t.sh
B="RESERVOIR R 100\nJUNCTION a 1 1\n"
for c in "PIPE p R a x -1 y" "PIPE p R a 0 -1 -1 -1" "PIPE p R a -1 x 0" "PIPE p R a 1 1 x -1" "PIPE p R a 1 1 -1 x" "PIPE p R a 1 1 1 x" "PIPE p R a 1 1 1 -2" "JUNCTION b x y" "JUNCTION b x -1" "JUNCTION b 1 1 pp x" "PUMP u R a x -1" "PUMP u R a -1 x" "PUMP u R a -1 -1" "PUMP u R a 1 -1" "VALVE v R a x y z" "VALVE v R a 0 x" "VALVE v R a 0 -1 FOO" "VALVE v R a 100 -1 FOO" "VALVE v R a 100 1 FOO extra" "PATTERN p 1 x -1" "PATTERN p 1 -1 x" "PATTERN p -1 -2" "PATTERN p x\nPATTERN p 1" "PATTERN p 0 0 0"; do echo "=== $c"; printf "${B}$c\nEND\n" | /app/prod/hydro 2>&1 | grep -e "\*\*\*" -e "ABORT" ; done' 2>&1
```

<details><summary>output</summary>

```
=== PIPE p R a x -1 y
 *** ERROR E104 LINE   3: BAD NUMBER 'x'
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== PIPE p R a 0 -1 -1 -1
 *** ERROR E107 LINE   3: VALUE OUT OF RANGE
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== PIPE p R a -1 x 0
 *** ERROR E104 LINE   3: BAD NUMBER 'x'
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== PIPE p R a 1 1 x -1
 *** ERROR E104 LINE   3: BAD NUMBER 'x'
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== PIPE p R a 1 1 -1 x
 *** ERROR E104 LINE   3: BAD NUMBER 'x'
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== PIPE p R a 1 1 1 x
 *** ERROR E104 LINE   3: BAD NUMBER 'x'
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== PIPE p R a 1 1 1 -2
 *** ERROR E107 LINE   3: VALUE OUT OF RANGE
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== JUNCTION b x y
 *** ERROR E104 LINE   3: BAD NUMBER 'x'
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== JUNCTION b x -1
 *** ERROR E104 LINE   3: BAD NUMBER 'x'
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== JUNCTION b 1 1 pp x
 *** WARNING W209 LINE   3: EXTRA FIELDS IGNORED
 *** ERROR E112 LINE   3: UNDEFINED PATTERN 'pp'
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== PUMP u R a x -1
 *** ERROR E104 LINE   3: BAD NUMBER 'x'
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== PUMP u R a -1 x
 *** ERROR E104 LINE   3: BAD NUMBER 'x'
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== PUMP u R a -1 -1
 *** ERROR E107 LINE   3: VALUE OUT OF RANGE
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== PUMP u R a 1 -1
 *** ERROR E107 LINE   3: VALUE OUT OF RANGE
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== VALVE v R a x y z
 *** ERROR E104 LINE   3: BAD NUMBER 'x'
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== VALVE v R a 0 x
 *** ERROR E104 LINE   3: BAD NUMBER 'x'
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== VALVE v R a 0 -1 FOO
 *** ERROR E108 LINE   3: INVALID OPTION VALUE 'FOO'
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== VALVE v R a 100 -1 FOO
 *** ERROR E108 LINE   3: INVALID OPTION VALUE 'FOO'
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== VALVE v R a 100 1 FOO extra
 *** ERROR E108 LINE   3: INVALID OPTION VALUE 'FOO'
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== PATTERN p 1 x -1
 *** ERROR E104 LINE   3: BAD NUMBER 'x'
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== PATTERN p 1 -1 x
 *** ERROR E107 LINE   3: VALUE OUT OF RANGE
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== PATTERN p -1 -2
 *** ERROR E107 LINE   3: VALUE OUT OF RANGE
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== PATTERN p x\nPATTERN p 1
 *** ERROR E104 LINE   3: BAD NUMBER 'x'
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== PATTERN p 0 0 0
 *** WARNING W204: NODE 'a' IS ISOLATED
```
</details>

### Step 59: Bash

```bash
docker exec sn-fortran-solver-parity bash -lc 'cd /w; . ./t.sh
t "RESERVOIR R 100\nRESERVOIR S 150\nJUNCTION a 10 0\nPUMP u R a 10\nPIPE p a S 100 100 0.1\nEND\n" | tail -n +8
t "RESERVOIR R 100\nRESERVOIR S 150\nJUNCTION a 10 0\nPUMP u R a 10 20\nPIPE p a S 100 100 0.1\nEND\n" | tail -n +8
t "RESERVOIR R 100\nRESERVOIR S 90\nJUNCTION a 10 0\nPUMP u R a 10 20\nPIPE p a S 100 100 0.1\nEND\n" | tail -n +8
t "RESERVOIR R 100\nRESERVOIR S 90\nJUNCTION a 10 0\nPUMP u R a 10 0.1\nPIPE p a S 100 100 0.1\nEND\n" | tail -n +8
'
```

<details><summary>output</summary>

```
 CONVERGED IN   9 ITERATIONS
 
 NODE RESULTS
 ID       TYPE       ELEV    DEMAND      HEAD  PRESSURE       KPA
 R        RESV    100.000     48.91   100.000     0.000       0.0
 S        RESV    150.000    -48.91   150.000     0.000       0.0
 a        JUNC     10.000      0.00   110.000   100.000     979.0
 
 LINK RESULTS
 ID       TYPE  FROM     TO            FLOW  VELOCITY  HEADLOSS  FRICTION  STATUS
 u        PUMP  R        a           -48.91              10.000            ON      
 p        PIPE  a        S           -48.91    -6.227    40.000   0.02023  OPEN    
 
 TOTAL DEMAND :      0.00 L/S
 TOTAL SUPPLY :      0.00 L/S
 *** WARNING W210: PUMP 'u' REVERSE FLOW
 *** WARNING W202: HIGH VELOCITY IN LINK 'p'

 RUN COMPLETED WITH   2 WARNING(S)
rc=0
 
 CONVERGED IN   6 ITERATIONS
 
 NODE RESULTS
 ID       TYPE       ELEV    DEMAND      HEAD  PRESSURE       KPA
 R        RESV    100.000     30.88   100.000     0.000       0.0
 S        RESV    150.000    -30.88   150.000     0.000       0.0
 a        JUNC     10.000      0.00   133.832   123.832    1212.3
 
 LINK RESULTS
 ID       TYPE  FROM     TO            FLOW  VELOCITY  HEADLOSS  FRICTION  STATUS
 u        PUMP  R        a           -30.88              33.832            ON      
 p        PIPE  a        S           -30.88    -3.931    16.168   0.02052  OPEN    
 
 TOTAL DEMAND :      0.00 L/S
 TOTAL SUPPLY :      0.00 L/S
 *** WARNING W210: PUMP 'u' REVERSE FLOW
 *** WARNING W202: HIGH VELOCITY IN LINK 'p'

 RUN COMPLETED WITH   2 WARNING(S)
rc=0
 
 CONVERGED IN   6 ITERATIONS
 
 NODE RESULTS
 ID       TYPE       ELEV    DEMAND      HEAD  PRESSURE       KPA
 R        RESV    100.000    -21.77   100.000     0.000       0.0
 S        RESV     90.000     21.77    90.000     0.000       0.0
 a        JUNC     10.000      0.00    98.155    88.155     863.0
 
 LINK RESULTS
 ID       TYPE  FROM     TO            FLOW  VELOCITY  HEADLOSS  FRICTION  STATUS
 u        PUMP  R        a            21.77               1.845            ON      
 p        PIPE  a        S            21.77     2.771     8.155   0.02082  OPEN    
 
 TOTAL DEMAND :      0.00 L/S
 TOTAL SUPPLY :     -0.00 L/S
 *** WARNING W207: PUMP 'u' FLOW EXCEEDS QMAX

 RUN COMPLETED WITH   1 WARNING(S)
rc=0
 
 CONVERGED IN   6 ITERATIONS
 
 NODE RESULTS
 ID       TYPE       ELEV    DEMAND      HEAD  PRESSURE       KPA
 R        RESV    100.000     -0.14   100.000     0.000       0.0
 S        RESV     90.000      0.14    90.000     0.000       0.0
 a        JUNC     10.000      0.00    90.001    80.001     783.2
 
 LINK RESULTS
 ID       TYPE  FROM     TO            FLOW  VELOCITY  HEADLOSS  FRICTION  STATUS
 u        PUMP  R        a             0.14               9.999            ON      
 p        PIPE  a        S             0.14     0.018     0.001   0.03554  OPEN    
 
 TOTAL DEMAND :      0.00 L/S
 TOTAL SUPPLY :     -0.00 L/S
 *** WARNING W207: PUMP 'u' FLOW EXCEEDS QMAX

 RUN COMPLETED WITH   1 WARNING(S)
rc=0
```
</details>

### Step 60: Bash

```bash
docker exec sn-fortran-solver-parity bash -lc 'cd /w; . ./t.sh
B="RESERVOIR R 100\nJUNCTION a 10 5 pp\nPIPE p R a 100 100 0.1\n"
for c in "PATTERN pp 1 2 3 4\nOPTION STEPS 2" "PATTERN pp 1 2\nPATTERN unused 1\nOPTION STEPS 5" "PATTERN pp 1 2 3 4\nOPTION STEPS 1" "PATTERN pp 1\nOPTION HSTEP 100" "PATTERN pp 1\nOPTION HSTEP 1e5" "PATTERN pp 1\nOPTION STEPS 2\nOPTION HSTEP 0.01" "PATTERN pp 1\nOPTION STEPS 24\nOPTION HSTEP 0.3333" "PATTERN pp 1\nOPTION STEPS 24\nOPTION HSTEP 5" "PATTERN pp 1\nOPTION STEPS 24\nOPTION HSTEP 5.999"  "PATTERN pp 1\nOPTION STEPS 24\nOPTION HSTEP 9.999999"; do echo "=== $c"; printf "${B}$c\nEND\n" | /app/prod/hydro 2>&1 | grep -e "\*\*\*" -e "ABORT" -e "STEPS " -e "TIME STEP" | head -30; done' 2>&1
```

<details><summary>output</summary>

```
=== PATTERN pp 1 2 3 4\nOPTION STEPS 2
 STEPS    :  2 AT  1.00 H
 TIME STEP  1 OF  2  AT  0:00
 TIME STEP  2 OF  2  AT  1:00
=== PATTERN pp 1 2\nPATTERN unused 1\nOPTION STEPS 5
 STEPS    :  5 AT  1.00 H
 TIME STEP  1 OF  5  AT  0:00
 TIME STEP  2 OF  5  AT  1:00
 TIME STEP  3 OF  5  AT  2:00
 TIME STEP  4 OF  5  AT  3:00
 TIME STEP  5 OF  5  AT  4:00
=== PATTERN pp 1 2 3 4\nOPTION STEPS 1
=== PATTERN pp 1\nOPTION HSTEP 100
 *** ERROR E108 LINE   5: INVALID OPTION VALUE '100'
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== PATTERN pp 1\nOPTION HSTEP 1e5
 *** ERROR E108 LINE   5: INVALID OPTION VALUE '1e5'
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== PATTERN pp 1\nOPTION STEPS 2\nOPTION HSTEP 0.01
 STEPS    :  2 AT  0.01 H
 TIME STEP  1 OF  2  AT  0:00
 TIME STEP  2 OF  2  AT  0:01
=== PATTERN pp 1\nOPTION STEPS 24\nOPTION HSTEP 0.3333
 STEPS    : 24 AT  0.33 H
 TIME STEP  1 OF 24  AT  0:00
 TIME STEP  2 OF 24  AT  0:20
 TIME STEP  3 OF 24  AT  0:40
 TIME STEP  4 OF 24  AT  1:00
 TIME STEP  5 OF 24  AT  1:20
 TIME STEP  6 OF 24  AT  1:40
 TIME STEP  7 OF 24  AT  2:00
 TIME STEP  8 OF 24  AT  2:20
 TIME STEP  9 OF 24  AT  2:40
 TIME STEP 10 OF 24  AT  3:00
 TIME STEP 11 OF 24  AT  3:20
 TIME STEP 12 OF 24  AT  3:40
 TIME STEP 13 OF 24  AT  4:00
 TIME STEP 14 OF 24  AT  4:20
 TIME STEP 15 OF 24  AT  4:40
 TIME STEP 16 OF 24  AT  5:00
 TIME STEP 17 OF 24  AT  5:20
 TIME STEP 18 OF 24  AT  5:40
 TIME STEP 19 OF 24  AT  6:00
 TIME STEP 20 OF 24  AT  6:20
 TIME STEP 21 OF 24  AT  6:40
 TIME STEP 22 OF 24  AT  7:00
 TIME STEP 23 OF 24  AT  7:20
 TIME STEP 24 OF 24  AT  7:40
=== PATTERN pp 1\nOPTION STEPS 24\nOPTION HSTEP 5
 STEPS    : 24 AT  5.00 H
 TIME STEP  1 OF 24  AT  0:00
 TIME STEP  2 OF 24  AT  5:00
 TIME STEP  3 OF 24  AT 10:00
 TIME STEP  4 OF 24  AT 15:00
 TIME STEP  5 OF 24  AT 20:00
 TIME STEP  6 OF 24  AT 25:00
 TIME STEP  7 OF 24  AT 30:00
 TIME STEP  8 OF 24  AT 35:00
 TIME STEP  9 OF 24  AT 40:00
 TIME STEP 10 OF 24  AT 45:00
 TIME STEP 11 OF 24  AT 50:00
 TIME STEP 12 OF 24  AT 55:00
 TIME STEP 13 OF 24  AT 60:00
 TIME STEP 14 OF 24  AT 65:00
 TIME STEP 15 OF 24  AT 70:00
 TIME STEP 16 OF 24  AT 75:00
 TIME STEP 17 OF 24  AT 80:00
 TIME STEP 18 OF 24  AT 85:00
 TIME STEP 19 OF 24  AT 90:00
 TIME STEP 20 OF 24  AT 95:00
 TIME STEP 21 OF 24  AT100:00
 TIME STEP 22 OF 24  AT105:00
 TIME STEP 23 OF 24  AT110:00
 TIME STEP 24 OF 24  AT115:00
=== PATTERN pp 1\nOPTION STEPS 24\nOPTION HSTEP 5.999
 STEPS    : 24 AT  6.00 H
 TIME STEP  1 OF 24  AT  0:00
 TIME STEP  2 OF 24  AT  6:00
 TIME STEP  3 OF 24  AT 12:00
 TIME STEP  4 OF 24  AT 18:00
 TIME STEP  5 OF 24  AT 24:00
 TIME STEP  6 OF 24  AT 30:00
 TIME STEP  7 OF 24  AT 36:00
 TIME STEP  8 OF 24  AT 42:00
 TIME STEP  9 OF 24  AT 48:00
 TIME STEP 10 OF 24  AT 53:59
 TIME STEP 11 OF 24  AT 59:59
 TIME STEP 12 OF 24  AT 65:59
 TIME STEP 13 OF 24  AT 71:59
 TIME STEP 14 OF 24  AT 77:59
 TIME STEP 15 OF 24  AT 83:59
 TIME STEP 16 OF 24  AT 89:59
 TIME STEP 17 OF 24  AT 95:59
 TIME STEP 18 OF 24  AT101:59
 T
... [980 more chars truncated]
```
</details>

### Step 61: Bash

```bash
docker exec sn-fortran-solver-parity bash -lc 'cd /w; . ./t.sh
B="RESERVOIR R 100\nJUNCTION a 10 5 pp\nPIPE p R a 100 100 0.1\n"
for c in "PATTERN pp 2 3\nOPTION STEPS 1" "PATTERN pp 2 3\nOPTION STEPS 5" "PATTERN pp 2 3\nPATTERN pp 4\nOPTION STEPS 5" "PATTERN pp 0 0\nOPTION STEPS 3" ; do echo "=== $c"; printf "${B}$c\nEND\n" | /app/prod/hydro 2>&1 | grep -e "\*\*\*" -e "ABORT" -e "STEPS " -e "TIME STEP" -e "^ a " -e CONVERGED -e " p "; done
for h in 24 25 50 99 99.99 99.999 100.0 24.01 12.345; do printf "OPTION STEPS 2\nOPTION HSTEP $h\n${B}PATTERN pp 1\nEND\n" | /app/prod/hydro 2>&1 | grep -e "\*\*\*" -e "STEPS   " |head -2| tr "\n" " " ; echo; done' 2>&1
```

<details><summary>output</summary>

```
=== PATTERN pp 2 3\nOPTION STEPS 1
 CONVERGED IN   2 ITERATIONS
 a        JUNC     10.000     10.00    98.192    88.192     863.4
 p        PIPE  R        a            10.00     1.273     1.808   0.02188  OPEN    
=== PATTERN pp 2 3\nOPTION STEPS 5
 STEPS    :  5 AT  1.00 H
 TIME STEP  1 OF  5  AT  0:00
 CONVERGED IN   2 ITERATIONS
 a        JUNC     10.000     10.00    98.192    88.192     863.4
 p        PIPE  R        a            10.00     1.273     1.808   0.02188  OPEN    
 TIME STEP  2 OF  5  AT  1:00
 CONVERGED IN   2 ITERATIONS
 a        JUNC     10.000     15.00    96.048    86.048     842.4
 p        PIPE  R        a            15.00     1.910     3.952   0.02125  OPEN    
 TIME STEP  3 OF  5  AT  2:00
 CONVERGED IN   2 ITERATIONS
 a        JUNC     10.000     10.00    98.192    88.192     863.4
 p        PIPE  R        a            10.00     1.273     1.808   0.02188  OPEN    
 TIME STEP  4 OF  5  AT  3:00
 CONVERGED IN   2 ITERATIONS
 a        JUNC     10.000     15.00    96.048    86.048     842.4
 p        PIPE  R        a            15.00     1.910     3.952   0.02125  OPEN    
 TIME STEP  5 OF  5  AT  4:00
 CONVERGED IN   2 ITERATIONS
 a        JUNC     10.000     10.00    98.192    88.192     863.4
 p        PIPE  R        a            10.00     1.273     1.808   0.02188  OPEN    
=== PATTERN pp 2 3\nPATTERN pp 4\nOPTION STEPS 5
 STEPS    :  5 AT  1.00 H
 TIME STEP  1 OF  5  AT  0:00
 CONVERGED IN   2 ITERATIONS
 a        JUNC     10.000     10.00    98.192    88.192     863.4
 p        PIPE  R        a            10.00     1.273     1.808   0.02188  OPEN    
 TIME STEP  2 OF  5  AT  1:00
 CONVERGED IN   2 ITERATIONS
 a        JUNC     10.000     15.00    96.048    86.048     842.4
 p        PIPE  R        a            15.00     1.910     3.952   0.02125  OPEN    
 TIME STEP  3 OF  5  AT  2:00
 CONVERGED IN   2 ITERATIONS
 a        JUNC     10.000     20.00    93.087    83.087     813.4
 p        PIPE  R        a            20.00     2.546     6.913   0.02091  OPEN    
 TIME STEP  4 OF  5  AT  3:00
 CONVERGED IN   2 ITERATIONS
 a        JUNC     10.000     10.00    98.192    88.192     863.4
 p        PIPE  R        a            10.00     1.273     1.808   0.02188  OPEN    
 TIME STEP  5 OF  5  AT  4:00
 CONVERGED IN   2 ITERATIONS
 a        JUNC     10.000     15.00    96.048    86.048     842.4
 p        PIPE  R        a            15.00     1.910     3.952   0.02125  OPEN    
=== PATTERN pp 0 0\nOPTION STEPS 3
 STEPS    :  3 AT  1.00 H
 TIME STEP  1 OF  3  AT  0:00
 CONVERGED IN   2 ITERATIONS
 a        JUNC     10.000      0.00   100.000    90.000     881.1
 p        PIPE  R        a             0.00     0.000     0.000     UNDEF  OPEN    
 *** WARNING W203: ZERO FLOW IN LINK 'p'
 TIME STEP  2 OF  3  AT  1:00
 CONVERGED IN   1 ITERATIONS
 a        JUNC     10.000      0.00   100.000    90.000     881.1
 p        PIPE  R        a             0.00     0.000     0.000     UNDEF  OPEN    
 *** WARNING W203: ZERO FLOW IN LINK 'p'
... [946 more chars truncated]
```
</details>

### Step 62: Bash

```bash
docker exec sn-fortran-solver-parity bash -lc 'cd /w; . ./t.sh
t "RESERVOIR R 100\nJUNCTION a 10 5\nJUNCTION b 10 3\nJUNCTION c 10 3\nPIPE p R a 100 100 0.1\nPIPE q b c 100 100 0.1\nVALVE v a b 100 1 CLOSED\nPUMP u c a 5\nEND\n" | tail -n +8 | cat -A | sed -n 1,40p'
```

<details><summary>output</summary>

```
 $
 CONVERGED IN   2 ITERATIONS$
 $
 NODE RESULTS$
 ID       TYPE       ELEV    DEMAND      HEAD  PRESSURE       KPA$
 R        RESV    100.000    -11.00   100.000     0.000       0.0$
 a        JUNC     10.000      5.00    97.829    87.829     859.8$
 b        JUNC     10.000      3.00    92.642    82.642     809.1$
 c        JUNC     10.000      3.00    92.829    82.829     810.9$
 $
 LINK RESULTS$
 ID       TYPE  FROM     TO            FLOW  VELOCITY  HEADLOSS  FRICTION  STATUS$
 p        PIPE  R        a            11.00     1.401     2.171   0.02171  OPEN    $
 q        PIPE  b        c            -3.00    -0.382     0.187   0.02514  OPEN    $
 v        VALVE a        b             0.00     0.000     5.187            CLOSED  $
 u        PUMP  c        a            -6.00               5.000            ON      $
 $
 TOTAL DEMAND :     11.00 L/S$
 TOTAL SUPPLY :     11.00 L/S$
 *** WARNING W210: PUMP 'u' REVERSE FLOW$
$
 RUN COMPLETED WITH   1 WARNING(S)$
rc=0$
```
</details>

### Step 63: Bash

```bash
docker exec sn-fortran-solver-parity bash -lc 'cd /w; . ./t.sh
t "RESERVOIR R 100\nJUNCTION a 10 5\nJUNCTION b 10 3\nJUNCTION c 10 3\nPIPE p R a 100 100 0.1\nPIPE q b c 100 100 0.1\nVALVE v a b 100 1 CLOSED\nEND\n" | tail -n +8 | cat -A | sed -n 1,40p
t "RESERVOIR R 100\nJUNCTION a 10 5\nJUNCTION b 10 3\nVALVE v R a 100 1 CLOSED\nPIPE p a b 100 100 .1\nEND\n" | tail -n +3 | cat -A | sed -n 1,40p'
```

<details><summary>output</summary>

```
 *** WARNING W204: NODE 'b' IS ISOLATED$
 *** WARNING W204: NODE 'c' IS ISOLATED$
 $
 CONVERGED IN   2 ITERATIONS$
 $
 NODE RESULTS$
 ID       TYPE       ELEV    DEMAND      HEAD  PRESSURE       KPA$
 R        RESV    100.000     -5.00   100.000     0.000       0.0$
 a        JUNC     10.000      5.00    99.516    89.516     876.4$
 b        JUNC     10.000      3.00    ISOLATED$
 c        JUNC     10.000      3.00    ISOLATED$
 $
 LINK RESULTS$
 ID       TYPE  FROM     TO            FLOW  VELOCITY  HEADLOSS  FRICTION  STATUS$
 p        PIPE  R        a             5.00     0.637     0.484   0.02345  OPEN    $
 q        PIPE  b        c             0.00     0.000     0.000     UNDEF  ISOLATED$
 v        VALVE a        b             0.00     0.000     0.000            CLOSED  $
 $
 TOTAL DEMAND :      5.00 L/S$
 TOTAL SUPPLY :      5.00 L/S$
$
 RUN COMPLETED WITH   2 WARNING(S)$
rc=0$
 TITLE    : (NONE)$
 UNITS    : SI (FLOW L/S, LENGTH M, DIAMETER MM)$
 FRICTION : DARCY-WEISBACH$
 NETWORK  :   3 NODES,   1 RESERVOIRS,   2 LINKS$
 SOLVER   : TOL  1.0E-05, MAXIT  50$
 *** WARNING W204: NODE 'a' IS ISOLATED$
 *** WARNING W204: NODE 'b' IS ISOLATED$
 $
 CONVERGED IN   1 ITERATIONS$
 $
 NODE RESULTS$
 ID       TYPE       ELEV    DEMAND      HEAD  PRESSURE       KPA$
 R        RESV    100.000     -0.00   100.000     0.000       0.0$
 a        JUNC     10.000      5.00    ISOLATED$
 b        JUNC     10.000      3.00    ISOLATED$
 $
 LINK RESULTS$
 ID       TYPE  FROM     TO            FLOW  VELOCITY  HEADLOSS  FRICTION  STATUS$
 v        VALVE R        a             0.00     0.000     0.000            CLOSED  $
 p        PIPE  a        b             0.00     0.000     0.000     UNDEF  ISOLATED$
 $
 TOTAL DEMAND :      0.00 L/S$
 TOTAL SUPPLY :      0.00 L/S$
$
 RUN COMPLETED WITH   2 WARNING(S)$
rc=0$
```
</details>

### Step 64: Bash

```bash
docker exec sn-fortran-solver-parity bash -lc 'cd /w; . ./t.sh
t "RESERVOIR R 100\nRESERVOIR S 100\nJUNCTION z 10 70\nJUNCTION a 10 0\nJUNCTION y 10 0\nPIPE p1 R z 100 100 0.1\nPIPE p2 z a 100 100 0.1\nPUMP u1 R y 10 5\nPIPE p3 y S 100 100 0.1\nPIPE p4 R S 100 100 .1\nEND\n" | tail -n +8 | grep -e "\*\*\*" -e " [pu][0-9] "
t "RESERVOIR R 100\nJUNCTION z 10 70\nJUNCTION a 10 7\nJUNCTION b 10 7\nPIPE p1 R z 10 100 0.1\nPIPE p2 R a 100 100 0.1 \nPIPE p3 a b 100 100 0.1\nPIPE p4 b z 100 100 .1\nEND\n" | tail -n +8 | grep -e "\*\*\*" -e " [pu][0-9] " -e JUNC'
```

<details><summary>output</summary>

```
 p1       PIPE  R        z            70.00     8.913    81.290   0.02007  OPEN    
 p2       PIPE  z        a             0.00     0.000     0.000     UNDEF  OPEN    
 u1       PUMP  R        y             4.88               0.463            ON      
 p3       PIPE  y        S             4.88     0.622     0.463   0.02351  OPEN    
 p4       PIPE  R        S             0.00     0.000     0.000     UNDEF  OPEN    
 *** WARNING W202: HIGH VELOCITY IN LINK 'p1'
 *** WARNING W203: ZERO FLOW IN LINK 'p2'
 *** WARNING W203: ZERO FLOW IN LINK 'p4'
 a        JUNC     10.000      7.00    94.770    84.770     829.9
 b        JUNC     10.000      7.00    92.846    82.846     811.1
 z        JUNC     10.000     70.00    92.619    82.619     808.8
 p1       PIPE  R        z            66.67     8.489     7.381   0.02009  OPEN    
 p2       PIPE  R        a            17.33     2.206     5.230   0.02107  OPEN    
 p3       PIPE  a        b            10.33     1.315     1.924   0.02182  OPEN    
 p4       PIPE  b        z             3.33     0.424     0.227   0.02475  OPEN    
 *** WARNING W202: HIGH VELOCITY IN LINK 'p1'
```
</details>

### Step 65: Bash

```bash
docker exec sn-fortran-solver-parity bash -lc 'cd /w; . ./t.sh
t "RESERVOIR R 100\nRESERVOIR S 100\nJUNCTION z 10 70\nJUNCTION a 10 0\nJUNCTION y 10 0\nPIPE p0 R S 100 100 .1\nPIPE p1 R z 100 100 0.1\nPIPE p2 z a 100 100 0.1\nPUMP u1 R y 10 5\nPUMP u2 R y 10 0.1\nPIPE p3 y S 100 100 0.1\nPIPE p4 R S 100 100 .1\nEND\n" | tail -n +8 | grep -e "\*\*\*" -e " [pu][0-9] "
t "RESERVOIR R 100\nJUNCTION a 10 0\nJUNCTION b 10 0\nJUNCTION z 10 400\nRESERVOIR S 130\nPUMP u1 R a 10\nPIPE p1 a b 100 100 .1\nPIPE p2 a z 100 100 .1\nPIPE p3 b S 100 100 .1\nEND\n" | tail -n +8 | grep -e "\*\*\*" -e " [pu][0-9] "  -e JUNC'
```

<details><summary>output</summary>

```
 p0       PIPE  R        S             0.00     0.000     0.000     UNDEF  OPEN    
 p1       PIPE  R        z            70.00     8.913    81.290   0.02007  OPEN    
 p2       PIPE  z        a             0.00     0.000     0.000     UNDEF  OPEN    
 u1       PUMP  R        y             4.88               0.480            ON      
 u2       PUMP  R        y             0.10               0.480            ON      
 p3       PIPE  y        S             4.98     0.634     0.480   0.02346  OPEN    
 p4       PIPE  R        S             0.00     0.000     0.000     UNDEF  OPEN    
 *** WARNING W203: ZERO FLOW IN LINK 'p0'
 *** WARNING W202: HIGH VELOCITY IN LINK 'p1'
 *** WARNING W203: ZERO FLOW IN LINK 'p2'
 *** WARNING W203: ZERO FLOW IN LINK 'p4'
 a        JUNC     10.000      0.00   110.000   100.000     979.0
 b        JUNC     10.000      0.00   120.000   110.000    1076.9
 z        JUNC     10.000    400.00 -2499.027 -2509.027  -24563.4
 u1       PUMP  R        a           375.84              10.000            ON      
 p1       PIPE  a        b           -24.16    -3.076    10.000   0.02072  OPEN    
 p2       PIPE  a        z           400.00    50.930  2609.027   0.01973  OPEN    
 p3       PIPE  b        S           -24.16    -3.076    10.000   0.02072  OPEN    
 *** WARNING W201: NEGATIVE PRESSURE AT NODE 'z'
 *** WARNING W202: HIGH VELOCITY IN LINK 'p1'
 *** WARNING W202: HIGH VELOCITY IN LINK 'p2'
 *** WARNING W202: HIGH VELOCITY IN LINK 'p3'
```
</details>

### Step 66: Bash

```bash
docker exec sn-fortran-solver-parity bash -lc 'cd /w; cat > c10.py <<EOF
from cal import *
for q in [0.0005,0.0009,0.00099,0.00101,0.0011,0.002]:
    row,o=pipe("SI","DW",q,100,100,0.1,H=100)
    print(q,row[-30:],[x for x in o.split("\n") if "W20" in x])
for q in [0.0005,0.0009,0.0011,0.002]:
    row,o=pipe("SI","HW",q,100,100,100,H=100)
    print("HW",q,row[-30:],[x for x in o.split("\n") if "W20" in x])
EOF
python3 c10.py'
```

<details><summary>output</summary>

```
0.0005      0.000     UNDEF  OPEN     [" *** WARNING W203: ZERO FLOW IN LINK 'p'"]
0.0009      0.000     UNDEF  OPEN     [" *** WARNING W203: ZERO FLOW IN LINK 'p'"]
0.00099      0.000     UNDEF  OPEN     [" *** WARNING W203: ZERO FLOW IN LINK 'p'"]
0.00101      0.000   4.97678  OPEN     []
0.0011      0.000   4.56959  OPEN     []
0.002      0.000   2.51327  OPEN     []
HW 0.0005      0.000            OPEN     [" *** WARNING W203: ZERO FLOW IN LINK 'p'"]
HW 0.0009      0.000            OPEN     [" *** WARNING W203: ZERO FLOW IN LINK 'p'"]
HW 0.0011      0.000            OPEN     []
HW 0.002      0.000            OPEN     []
```
</details>

### Step 67: Bash

```bash
docker exec sn-fortran-solver-parity bash -lc 'cd /w; for v in "1,2" "1/2" "1;2" "nan" "inf" "NaN" "1e" "1e+" "+5" "." "5." "1d5" "1.5e3" "0x1A" "3*5" "1e400" "-0" "1.2.3" "1-2" "5e-1" "1 2" "T" "1E5" "1q5" "--5" "+.5" "1e-400" "(1,2)" "1_8" "٣"; do printf "RESERVOIR R 100\nJUNCTION a 10 $v\nPIPE p R a 100 100 .1\nEND\n" | /app/prod/hydro 2>&1 | grep -e "\*\*\*" -e "^ a " | head -2 | tr "\n" " " | sed "s/^/[$v] /"; echo; done'
```

<details><summary>output</summary>

```
[1,2]  *** ERROR E104 LINE   2: BAD NUMBER '1,2'  *** ERROR E103 LINE   3: UNDEFINED NODE 'a' 
sed: -e expression #1, char 9: unknown option to `s'

[1;2]  *** ERROR E104 LINE   2: BAD NUMBER '1;2'  *** ERROR E103 LINE   3: UNDEFINED NODE 'a' 
[nan]  *** ERROR E104 LINE   2: BAD NUMBER 'nan'  *** ERROR E103 LINE   3: UNDEFINED NODE 'a' 
[inf]  *** ERROR E104 LINE   2: BAD NUMBER 'inf'  *** ERROR E103 LINE   3: UNDEFINED NODE 'a' 
[NaN]  *** ERROR E104 LINE   2: BAD NUMBER 'NaN'  *** ERROR E103 LINE   3: UNDEFINED NODE 'a' 
[1e]  *** ERROR E104 LINE   2: BAD NUMBER '1e'  *** ERROR E103 LINE   3: UNDEFINED NODE 'a' 
[1e+]  *** ERROR E104 LINE   2: BAD NUMBER '1e+'  *** ERROR E103 LINE   3: UNDEFINED NODE 'a' 
[+5]  a        JUNC     10.000      5.00    99.516    89.516     876.4 
[.]  *** ERROR E104 LINE   2: BAD NUMBER '.'  *** ERROR E103 LINE   3: UNDEFINED NODE 'a' 
[5.]  a        JUNC     10.000      5.00    99.516    89.516     876.4 
[1d5]  a        JUNC     10.000 100000.00******************************  p        PIPE  R        a        100000.00 12732.395**********   0.01964  OPEN     
[1.5e3]  a        JUNC     10.000   1500.00-36469.603-36479.603 -357135.3  *** WARNING W201: NEGATIVE PRESSURE AT NODE 'a' 
[0x1A]  *** ERROR E104 LINE   2: BAD NUMBER '0x1A'  *** ERROR E103 LINE   3: UNDEFINED NODE 'a' 
[3*5]  *** ERROR E104 LINE   2: BAD NUMBER '3*5'  *** ERROR E103 LINE   3: UNDEFINED NODE 'a' 
[1e400]  a        JUNC     10.000  Infinity -Infinity -Infinity -Infinity  *** WARNING W201: NEGATIVE PRESSURE AT NODE 'a' 
[-0]  a        JUNC     10.000     -0.00   100.000    90.000     881.1  *** WARNING W203: ZERO FLOW IN LINK 'p' 
[1.2.3]  *** ERROR E104 LINE   2: BAD NUMBER '1.2.3'  *** ERROR E103 LINE   3: UNDEFINED NODE 'a' 
[1-2]  *** ERROR E104 LINE   2: BAD NUMBER '1-2'  *** ERROR E103 LINE   3: UNDEFINED NODE 'a' 
[5e-1]  a        JUNC     10.000      0.50    99.992    89.992     881.0 
[1 2]  *** ERROR E112 LINE   2: UNDEFINED PATTERN '2'  *** RUN ABORTED:   1 INPUT ERROR(S) 
[T]  *** ERROR E104 LINE   2: BAD NUMBER 'T'  *** ERROR E103 LINE   3: UNDEFINED NODE 'a' 
[1E5]  a        JUNC     10.000 100000.00******************************  p        PIPE  R        a        100000.00 12732.395**********   0.01964  OPEN     
[1q5]  *** ERROR E104 LINE   2: BAD NUMBER '1q5'  *** ERROR E103 LINE   3: UNDEFINED NODE 'a' 
[--5]  *** ERROR E104 LINE   2: BAD NUMBER '--5'  *** ERROR E103 LINE   3: UNDEFINED NODE 'a' 
[+.5]  a        JUNC     10.000      0.50    99.992    89.992     881.0 
[1e-400]  a        JUNC     10.000      0.00   100.000    90.000     881.1  *** WARNING W203: ZERO FLOW IN LINK 'p' 
[(1,2)]  *** ERROR E104 LINE   2: BAD NUMBER '(1,2)'  *** ERROR E103 LINE   3: UNDEFINED NODE 'a' 
[1_8]  *** ERROR E104 LINE   2: BAD NUMBER '1_8'  *** ERROR E103 LINE   3: UNDEFINED NODE 'a' 
[٣]  *** ERROR E104 LINE   2: BAD NUMBER '٣'  *** ERROR E103 LINE   3: UNDEFINED NODE 'a'
```
</details>

### Step 68: Bash

```bash
docker exec sn-fortran-solver-parity bash -lc 'cd /w; for o in "MAXIT 3.0" "MAXIT 1e2" "MAXIT 50." "MAXIT +5" "MAXIT 0.5" "MAXIT -3" "MAXIT 199.9999999999" "MAXIT 200" "MAXIT 201" "MAXIT 1e10" "MAXIT 3d0" "STEPS 3.0" "STEPS 2e0" "STEPS 1e400" "TOL 1e400" "TOL 1e-400" "TOL inf" "MAXIT 5000000000" "MAXIT 1e12" "MAXIT 99999999999999999999"; do printf "OPTION $o\nRESERVOIR R 100\nJUNCTION a 10 5\nPIPE p R a 100 100 .1\nEND\n" | /app/prod/hydro 2>&1 | grep -e "\*\*\*" -e "SOLVER" -e "^ STEPS" | head -3 | tr "\n" " " | sed "s|^|[$o] |"; echo; done'
```

<details><summary>output</summary>

```
[MAXIT 3.0]  SOLVER   : TOL  1.0E-05, MAXIT   3 
[MAXIT 1e2]  SOLVER   : TOL  1.0E-05, MAXIT 100 
[MAXIT 50.]  SOLVER   : TOL  1.0E-05, MAXIT  50 
[MAXIT +5]  SOLVER   : TOL  1.0E-05, MAXIT   5 
[MAXIT 0.5]  *** ERROR E108 LINE   1: INVALID OPTION VALUE '0.5'  *** RUN ABORTED:   1 INPUT ERROR(S) 
[MAXIT -3]  *** ERROR E108 LINE   1: INVALID OPTION VALUE '-3'  *** RUN ABORTED:   1 INPUT ERROR(S) 
[MAXIT 199.9999999999]  *** ERROR E108 LINE   1: INVALID OPTION VALUE '199.9999999999'  *** RUN ABORTED:   1 INPUT ERROR(S) 
[MAXIT 200]  SOLVER   : TOL  1.0E-05, MAXIT 200 
[MAXIT 201]  *** WARNING W206 LINE   1: MAXIT LIMITED TO 200  SOLVER   : TOL  1.0E-05, MAXIT 200 
[MAXIT 1e10]  *** WARNING W206 LINE   1: MAXIT LIMITED TO 200  SOLVER   : TOL  1.0E-05, MAXIT 200 
[MAXIT 3d0]  SOLVER   : TOL  1.0E-05, MAXIT   3 
[STEPS 3.0]  SOLVER   : TOL  1.0E-05, MAXIT  50  STEPS    :  3 AT  1.00 H 
[STEPS 2e0]  SOLVER   : TOL  1.0E-05, MAXIT  50  STEPS    :  2 AT  1.00 H 
[STEPS 1e400]  *** ERROR E108 LINE   1: INVALID OPTION VALUE '1e400'  *** RUN ABORTED:   1 INPUT ERROR(S) 
[TOL 1e400]  SOLVER   : TOL Infinity, MAXIT  50 
[TOL 1e-400]  *** ERROR E108 LINE   1: INVALID OPTION VALUE '1e-400'  *** RUN ABORTED:   1 INPUT ERROR(S) 
[TOL inf]  *** ERROR E104 LINE   1: BAD NUMBER 'inf'  *** RUN ABORTED:   1 INPUT ERROR(S) 
[MAXIT 5000000000]  *** WARNING W206 LINE   1: MAXIT LIMITED TO 200  SOLVER   : TOL  1.0E-05, MAXIT 200 
[MAXIT 1e12]  *** WARNING W206 LINE   1: MAXIT LIMITED TO 200  SOLVER   : TOL  1.0E-05, MAXIT 200 
[MAXIT 99999999999999999999]  *** WARNING W206 LINE   1: MAXIT LIMITED TO 200  SOLVER   : TOL  1.0E-05, MAXIT 200
```
</details>

### Step 69: Bash

```bash
docker exec sn-fortran-solver-parity bash -lc 'cd /w; . ./t.sh
B="RESERVOIR R 100\nJUNCTION a 1 1\n"
for c in "PIPE p R a x 1 1 1 1 1 1" "PIPE p R a 1 1 1 1 1 1 1" "RESERVOIR S x 5" "RESERVOIR a 5 5" "JUNCTION S -1 1 pp 5 6" "JUNCTION R 1 1 xx 5" "PIPE R R a 1 1 1 5 5" "PUMP u R a x 1 1" "PUMP u R a 1 1 1" "PUMP u R a -1 1 1" "VALVE v R a 100 1 open x" "VALVE v R a 100 -1 x y" "UNITS SI SI" "UNITS XX SI" "OPTION TOL x y" "OPTION TOL 0 y" "OPTION XX x y" "END extra" "OPTION FRICTION XX y" "OPTION FRICTION HW y z"; do echo "=== $c"; printf "${B}$c\nEND\n" | /app/prod/hydro 2>&1 | grep -e "\*\*\*" -e "ABORT" ; done' 2>&1
```

<details><summary>output</summary>

```
=== PIPE p R a x 1 1 1 1 1 1
 *** ERROR E104 LINE   3: BAD NUMBER 'x'
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== PIPE p R a 1 1 1 1 1 1 1
 *** WARNING W209 LINE   3: EXTRA FIELDS IGNORED
 a        JUNC      1.000      1.00******************************
 p        PIPE  R        a             1.00  1273.240**********   0.77443  OPEN    
 *** WARNING W201: NEGATIVE PRESSURE AT NODE 'a'
 *** WARNING W202: HIGH VELOCITY IN LINK 'p'
=== RESERVOIR S x 5
 *** ERROR E104 LINE   3: BAD NUMBER 'x'
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== RESERVOIR a 5 5
 *** ERROR E102 LINE   3: DUPLICATE ID 'a'
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== JUNCTION S -1 1 pp 5 6
 *** WARNING W209 LINE   3: EXTRA FIELDS IGNORED
 *** ERROR E112 LINE   3: UNDEFINED PATTERN 'pp'
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== JUNCTION R 1 1 xx 5
 *** ERROR E102 LINE   3: DUPLICATE ID 'R'
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== PIPE R R a 1 1 1 5 5
 *** WARNING W209 LINE   3: EXTRA FIELDS IGNORED
 a        JUNC      1.000      1.00******************************
 R        PIPE  R        a             1.00  1273.240**********   0.77443  OPEN    
 *** WARNING W201: NEGATIVE PRESSURE AT NODE 'a'
 *** WARNING W202: HIGH VELOCITY IN LINK 'R'
=== PUMP u R a x 1 1
 *** ERROR E104 LINE   3: BAD NUMBER 'x'
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== PUMP u R a 1 1 1
 *** WARNING W209 LINE   3: EXTRA FIELDS IGNORED
=== PUMP u R a -1 1 1
 *** ERROR E107 LINE   3: VALUE OUT OF RANGE
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== VALVE v R a 100 1 open x
 *** WARNING W209 LINE   3: EXTRA FIELDS IGNORED
=== VALVE v R a 100 -1 x y
 *** ERROR E108 LINE   3: INVALID OPTION VALUE 'x'
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== UNITS SI SI
 *** WARNING W209 LINE   3: EXTRA FIELDS IGNORED
 *** WARNING W204: NODE 'a' IS ISOLATED
=== UNITS XX SI
 *** ERROR E108 LINE   3: INVALID OPTION VALUE 'XX'
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== OPTION TOL x y
 *** ERROR E104 LINE   3: BAD NUMBER 'x'
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== OPTION TOL 0 y
 *** ERROR E108 LINE   3: INVALID OPTION VALUE '0'
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== OPTION XX x y
 *** ERROR E109 LINE   3: UNKNOWN OPTION 'XX'
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== END extra
 *** WARNING W204: NODE 'a' IS ISOLATED
=== OPTION FRICTION XX y
 *** ERROR E108 LINE   3: INVALID OPTION VALUE 'XX'
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== OPTION FRICTION HW y z
 *** WARNING W209 LINE   3: EXTRA FIELDS IGNORED
 *** WARNING W204: NODE 'a' IS ISOLATED
```
</details>

### Step 70: Bash

```bash
docker exec sn-fortran-solver-parity bash -lc 'cd /w; . ./t.sh
t "JUNCTION a 1 1 pp\nPIPE p a zz 1 1 1\nFOO\n"
t "JUNCTION a 1 1 pp\nPIPE p a zz 1 1 1\nFOO\nEND\n"
t "RESERVOIR R 100\nOPTION FRICTION HW\nOPTION STEPS 3\nJUNCTION a 1 1 pp\nPIPE p R a 1 1 0\n"
' | grep -e "###" -e "\*\*\*"'
```

<details><summary>output</summary>

```
(eval):5: unmatched '
```
</details>

### Step 71: Bash

```bash
cd /tmp; docker exec sn-fortran-solver-parity bash -lc 'cd /w; . ./t.sh
t "JUNCTION a 1 1 pp\nPIPE p a zz 1 1 1\nFOO\n" | grep -e "###" -e "\*\*\*"
t "JUNCTION a 1 1 pp\nPIPE p a zz 1 1 1\nFOO\nEND\n" | grep -e "###" -e "\*\*\*"
t "RESERVOIR R 100\nOPTION FRICTION HW\nPIPE p R a 1 1 0\nJUNCTION a 1 1 pp\n" | grep -e "###" -e "\*\*\*"
t "RESERVOIR R 100\nOPTION FRICTION HW\nPIPE p R a 1 1 0\nJUNCTION a 1 1 pp\nOPTION TOL x" | grep -e "###" -e "\*\*\*"
'
```

<details><summary>output</summary>

```
##### JUNCTION a 1 1 pp\nPIPE p a zz 1 1 1\nFOO\n
 *** ERROR E101 LINE   3: UNKNOWN CARD 'FOO'
 *** WARNING W208: END CARD MISSING
 *** ERROR E103 LINE   2: UNDEFINED NODE 'zz'
 *** ERROR E112 LINE   1: UNDEFINED PATTERN 'pp'
 *** ERROR E302: NO FIXED-HEAD NODE
 *** RUN ABORTED:   4 INPUT ERROR(S)
##### JUNCTION a 1 1 pp\nPIPE p a zz 1 1 1\nFOO\nEND\n
 *** ERROR E101 LINE   3: UNKNOWN CARD 'FOO'
 *** ERROR E103 LINE   2: UNDEFINED NODE 'zz'
 *** ERROR E112 LINE   1: UNDEFINED PATTERN 'pp'
 *** ERROR E302: NO FIXED-HEAD NODE
 *** RUN ABORTED:   4 INPUT ERROR(S)
##### RESERVOIR R 100\nOPTION FRICTION HW\nPIPE p R a 1 1 0\nJUNCTION a 1 1 pp\n
 *** WARNING W208: END CARD MISSING
 *** ERROR E112 LINE   4: UNDEFINED PATTERN 'pp'
 *** ERROR E107 LINE   3: VALUE OUT OF RANGE
 *** RUN ABORTED:   2 INPUT ERROR(S)
##### RESERVOIR R 100\nOPTION FRICTION HW\nPIPE p R a 1 1 0\nJUNCTION a 1 1 pp\nOPTION TOL x
 *** ERROR E104 LINE   5: BAD NUMBER 'x'
 *** WARNING W208: END CARD MISSING
 *** ERROR E112 LINE   4: UNDEFINED PATTERN 'pp'
 *** ERROR E107 LINE   3: VALUE OUT OF RANGE
 *** RUN ABORTED:   3 INPUT ERROR(S)
```
</details>

### Step 72: Bash

```bash
cd /tmp; docker exec sn-fortran-solver-parity bash -lc 'cd /w; . ./t.sh
t "OPTION FRICTION HW\nPIPE q a zz 1 1 0\nJUNCTION a 1 1 pp\nPIPE p a a2 1 1 0\nJUNCTION a2 1 1 pp2\n" | grep -e "###" -e "\*\*\*"
t "OPTION FRICTION HW\nPIPE q a a2 1 1 0\nJUNCTION a 1 1 \nPIPE p a a2 1 1 0\nJUNCTION a2 1 1 pp2\n" | grep -e "###" -e "\*\*\*"
t "OPTION FRICTION HW\nRESERVOIR R 1\nPIPE q R a 1 1 0\nPIPE q2 R a 1 1 -3\nJUNCTION a 1 1 \n" | grep -e "###" -e "\*\*\*"
t "OPTION FRICTION HW\nRESERVOIR R 1\nPIPE q R a 1 1 0.0001\nPIPE q2 R a 1 1 5\nVALVE v R a 1 1\nJUNCTION a 1 1 \n" | grep -e "###" -e "\*\*\*"
'
```

<details><summary>output</summary>

```
##### OPTION FRICTION HW\nPIPE q a zz 1 1 0\nJUNCTION a 1 1 pp\nPIPE p a a2 1 1 0\nJUNCTION a2 1 1 pp2\n
 *** WARNING W208: END CARD MISSING
 *** ERROR E103 LINE   2: UNDEFINED NODE 'zz'
 *** ERROR E112 LINE   3: UNDEFINED PATTERN 'pp'
 *** ERROR E112 LINE   5: UNDEFINED PATTERN 'pp2'
 *** ERROR E107 LINE   2: VALUE OUT OF RANGE
 *** ERROR E107 LINE   4: VALUE OUT OF RANGE
 *** ERROR E302: NO FIXED-HEAD NODE
 *** RUN ABORTED:   6 INPUT ERROR(S)
##### OPTION FRICTION HW\nPIPE q a a2 1 1 0\nJUNCTION a 1 1 \nPIPE p a a2 1 1 0\nJUNCTION a2 1 1 pp2\n
 *** WARNING W208: END CARD MISSING
 *** ERROR E112 LINE   5: UNDEFINED PATTERN 'pp2'
 *** ERROR E107 LINE   2: VALUE OUT OF RANGE
 *** ERROR E107 LINE   4: VALUE OUT OF RANGE
 *** ERROR E302: NO FIXED-HEAD NODE
 *** RUN ABORTED:   4 INPUT ERROR(S)
##### OPTION FRICTION HW\nRESERVOIR R 1\nPIPE q R a 1 1 0\nPIPE q2 R a 1 1 -3\nJUNCTION a 1 1 \n
 *** ERROR E107 LINE   4: VALUE OUT OF RANGE
 *** WARNING W208: END CARD MISSING
 *** ERROR E107 LINE   3: VALUE OUT OF RANGE
 *** RUN ABORTED:   2 INPUT ERROR(S)
##### OPTION FRICTION HW\nRESERVOIR R 1\nPIPE q R a 1 1 0.0001\nPIPE q2 R a 1 1 5\nVALVE v R a 1 1\nJUNCTION a 1 1 \n
 *** WARNING W208: END CARD MISSING
 *** WARNING W201: NEGATIVE PRESSURE AT NODE 'a'
 *** WARNING W203: ZERO FLOW IN LINK 'q'
 *** WARNING W202: HIGH VELOCITY IN LINK 'q2'
 *** WARNING W202: HIGH VELOCITY IN LINK 'v'
```
</details>

### Step 73: Bash

```bash
cd /tmp; docker exec sn-fortran-solver-parity bash -lc 'cd /w; . ./t.sh
t "RESERVOIR R 100\nRESERVOIR S 110\nJUNCTION a 1 0\nPUMP u R a 10\nPIPE p a S 100 100 .1\nEND\n" | tail -n +8
t "RESERVOIR R 100\nRESERVOIR S 110\nJUNCTION a 1 0\nPUMP u R a 10 5\nPIPE p a S 100 100 .1\nVALVE v a S 100 2\nEND\n" | tail -n +8 | grep -e "\*\*\*" -e " [upv] "
t "UNITS US\nRESERVOIR R 100\nJUNCTION a 1 80\nPIPE p R a 100 4 .1\nEND\n" | tail -n +8 | grep -e "\*\*\*" -e " [upv] "
'
```

<details><summary>output</summary>

```
 CONVERGED IN   7 ITERATIONS
 
 NODE RESULTS
 ID       TYPE       ELEV    DEMAND      HEAD  PRESSURE       KPA
 R        RESV    100.000      0.00   100.000     0.000       0.0
 S        RESV    110.000     -0.00   110.000     0.000       0.0
 a        JUNC      1.000      0.00   110.000   109.000    1067.1
 
 LINK RESULTS
 ID       TYPE  FROM     TO            FLOW  VELOCITY  HEADLOSS  FRICTION  STATUS
 u        PUMP  R        a            -0.00              10.000            ON      
 p        PIPE  a        S             0.00     0.000     0.000     UNDEF  OPEN    
 
 TOTAL DEMAND :      0.00 L/S
 TOTAL SUPPLY :     -0.00 L/S
 *** WARNING W203: ZERO FLOW IN LINK 'u'
 *** WARNING W203: ZERO FLOW IN LINK 'p'

 RUN COMPLETED WITH   2 WARNING(S)
rc=0
 *** WARNING W205: NOT CONVERGED AFTER 50 ITERATIONS
 u        PUMP  R        a             0.00              10.000            ON      
 p        PIPE  a        S            -0.00    -0.000     0.000     UNDEF  OPEN    
 v        VALVE a        S            -0.00    -0.000     0.000            OPEN    
 *** WARNING W203: ZERO FLOW IN LINK 'u'
 *** WARNING W203: ZERO FLOW IN LINK 'p'
 *** WARNING W203: ZERO FLOW IN LINK 'v'
 p        PIPE  R        a            80.00     2.042     0.409   0.02101  OPEN
```
</details>

### Step 74: Bash

```bash
cd /tmp; docker exec sn-fortran-solver-parity bash -lc 'cd /w; . ./t.sh
printf "TITLE crlf test\r\nRESERVOIR R 100\r\nJUNCTION a 10 5\r\nPIPE p R a 100 100 .1\r\nEND\r\n" | /app/prod/hydro 2>&1 | head -12 | cat -A
printf "TITLE a\001b\nRESERVOIR R 100\nJUNCTION a 10 5\nPIPE p R a 100 100 .1\nEND" | /app/prod/hydro 2>&1 | head -6 | cat -A
printf "TITLE x\nRESERVOIR R 100\nJUNCTION a\v10 5\nPIPE p R a 100 100 .1\nEND" | /app/prod/hydro 2>&1 | head -12 | cat -A
'
```

<details><summary>output</summary>

```
 HYDRO 2.3 - STEADY-STATE PIPE NETWORK ANALYSIS$
 ----------------------------------------------$
 $
 TITLE    : crlf test$
 UNITS    : SI (FLOW L/S, LENGTH M, DIAMETER MM)$
 FRICTION : DARCY-WEISBACH$
 NETWORK  :   2 NODES,   1 RESERVOIRS,   1 LINKS$
 SOLVER   : TOL  1.0E-05, MAXIT  50$
 $
 CONVERGED IN   2 ITERATIONS$
 $
 NODE RESULTS$
 HYDRO 2.3 - STEADY-STATE PIPE NETWORK ANALYSIS$
 ----------------------------------------------$
 $
 TITLE    : a^Ab$
 UNITS    : SI (FLOW L/S, LENGTH M, DIAMETER MM)$
 FRICTION : DARCY-WEISBACH$
 HYDRO 2.3 - STEADY-STATE PIPE NETWORK ANALYSIS$
 ----------------------------------------------$
 *** ERROR E103 LINE   4: UNDEFINED NODE 'a'$
 *** RUN ABORTED:   1 INPUT ERROR(S)$
STOP 1$
```
</details>

### Step 75: Bash

```bash
cd /tmp; docker exec sn-fortran-solver-parity bash -lc 'cd /w; . ./t.sh
B="RESERVOIR R 100\nJUNCTION a 1 1\n"
for c in "JUNCTION b x 1 123456789" "PIPE p R 123456789 1 1 1" "PIPE p R a 1 1 1\nPIPE p2 R a 1 1 1\nPUMP u R R 5" "PUMP u R R 5 1" "VALVE v R R 5 1 closed" "VALVE 123456789 R R 5 1 closed" "PIPE p R a 1 1 1" "RESERVOIR 123456789 x"; do echo "=== $c"; printf "${B}$c\nEND\n" | /app/prod/hydro 2>&1 | grep -e "\*\*\*" -e "ABORT" ; done
cd /w; python3 - <<EOF
import subprocess
def run(d): return subprocess.run(["/app/prod/hydro"],input=d,capture_output=True,text=True).stdout
d="RESERVOIR R 100\n"+"".join("JUNCTION j%d 10 0.01\n"%i for i in range(99))+"JUNCTION j5 1 1\nJUNCTION 123456789 x\nJUNCTION j5 1 x\nPIPE p R j1 1 1 1\n"+"".join("PIPE p%d R j1 100 100 0.1\n"%i for i in range(150))+"PIPE p5 R j1 1 1 1\nPIPE 123456789 R j1 x 1 1\nPIPE p5 R j1 x 1\nEND\n"
print([l for l in run(d).split("\n") if "***" in l and "E111" not in l])
EOF'
```

<details><summary>output</summary>

```
=== JUNCTION b x 1 123456789
 *** ERROR E106 LINE   3: ID TOO LONG '123456789'
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== PIPE p R 123456789 1 1 1
 *** ERROR E106 LINE   3: ID TOO LONG '123456789'
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== PIPE p R a 1 1 1\nPIPE p2 R a 1 1 1\nPUMP u R R 5
 *** ERROR E110 LINE   5: LINK CONNECTS NODE TO ITSELF
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== PUMP u R R 5 1
 *** ERROR E110 LINE   3: LINK CONNECTS NODE TO ITSELF
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== VALVE v R R 5 1 closed
 *** ERROR E110 LINE   3: LINK CONNECTS NODE TO ITSELF
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== VALVE 123456789 R R 5 1 closed
 *** ERROR E106 LINE   3: ID TOO LONG '123456789'
 *** RUN ABORTED:   1 INPUT ERROR(S)
=== PIPE p R a 1 1 1
 a        JUNC      1.000      1.00******************************
 p        PIPE  R        a             1.00  1273.240**********   0.77443  OPEN    
 *** WARNING W201: NEGATIVE PRESSURE AT NODE 'a'
 *** WARNING W202: HIGH VELOCITY IN LINK 'p'
=== RESERVOIR 123456789 x
 *** ERROR E106 LINE   3: ID TOO LONG '123456789'
 *** RUN ABORTED:   1 INPUT ERROR(S)
[" *** ERROR E102 LINE 101: DUPLICATE ID 'j5'", " *** ERROR E106 LINE 102: ID TOO LONG '123456789'", " *** ERROR E102 LINE 103: DUPLICATE ID 'j5'", " *** ERROR E102 LINE 255: DUPLICATE ID 'p5'", " *** ERROR E106 LINE 256: ID TOO LONG '123456789'", ' *** ERROR E105 LINE 257: MISSING FIELD(S)', ' *** RUN ABORTED:   7 INPUT ERROR(S)']
```
</details>

### Step 76: Bash

```bash
cd /w 2>/dev/null; docker exec sn-fortran-solver-parity bash -lc 'cd /w; python3 - <<EOF
import subprocess
def run(d): return subprocess.run(["/app/prod/hydro"],input=d,capture_output=True,text=True).stdout
d="RESERVOIR R 100\n"+"".join("JUNCTION j%d 10 0.01\n"%i for i in range(99))+"JUNCTION j5 1 1\nJUNCTION 123456789 x\nJUNCTION j9 1 x\nJUNCTION k1 x\nJUNCTION k2 1 1 pp\nPIPE p R j1 1 1 1\n"+"".join("PIPE p%d R j1 100 100 0.1\n"%i for i in range(149))+"PIPE p5 R j1 1 1 1\nPIPE 123456789 R j1 x 1 1\nPIPE p9 R R 1 1 1\nPIPE p9 R j1 x 1 1\nPIPE p9 R j1 1 1 1 1\nEND\n"
print([l for l in run(d).split("\n") if "***" in l])
EOF'
```

<details><summary>output</summary>

```
[" *** ERROR E102 LINE 101: DUPLICATE ID 'j5'", " *** ERROR E106 LINE 102: ID TOO LONG '123456789'", " *** ERROR E102 LINE 103: DUPLICATE ID 'j9'", ' *** ERROR E111 LINE 104: TOO MANY NODES', ' *** ERROR E111 LINE 105: TOO MANY NODES', " *** ERROR E102 LINE 256: DUPLICATE ID 'p5'", " *** ERROR E106 LINE 257: ID TOO LONG '123456789'", " *** ERROR E102 LINE 258: DUPLICATE ID 'p9'", " *** ERROR E102 LINE 259: DUPLICATE ID 'p9'", " *** ERROR E102 LINE 260: DUPLICATE ID 'p9'", ' *** RUN ABORTED:  10 INPUT ERROR(S)']
```
</details>

### Step 77: Bash

```bash
mkdir -p /tmp/x; docker exec sn-fortran-solver-parity bash -c 'mkdir -p /w/new && cd /w/new && rm -f * && cat > hydro.inc' <<'EOF'
C     HYDRO 2.3  COMMON BLOCKS
      INTEGER MXN, MXL, MXP, MXV, MXF
      PARAMETER (MXN=100, MXL=150, MXP=12, MXV=24, MXF=16)
      DOUBLE PRECISION GRAV, PI, VISC, GMIN, QZERO
      PARAMETER (GRAV=9.80665D0, PI=3.14159265358979323846D0)
      PARAMETER (VISC=1.0D-6, GMIN=1.0D-4, QZERO=1.0D-6)
C
C     NODES.  NTYP 1 JUNCTION, 2 RESERVOIR.  NODES ARE KEPT IN INPUT
C     ORDER; NSORT HOLDS THE REPORT ORDER (ALPHABETICAL).
      INTEGER NN, NTYP(MXN), NLINE(MXN), NSORT(MXN), NPAT(MXN)
      INTEGER NISO(MXN)
      CHARACTER*8 NID(MXN)
      CHARACTER*8 NPNAM(MXN)
      DOUBLE PRECISION ZIN(MXN), ZN(MXN), QB(MXN), QD(MXN), HN(MXN)
      COMMON /NODI/ NN, NTYP, NLINE, NSORT, NPAT, NISO
      COMMON /NODC/ NID, NPNAM
      COMMON /NODD/ ZIN, ZN, QB, QD, HN
C
C     LINKS.  LTYP 1 PIPE, 2 PUMP, 3 VALVE.  LCLOSE 1 IF CLOSED VALVE.
      INTEGER NL, LTYP(MXL), LLINE(MXL), LI(MXL), LJ(MXL), LCLOSE(MXL)
      INTEGER LACT(MXL)
      CHARACTER*8 LID(MXL)
      CHARACTER*40 LFROM(MXL), LTO(MXL)
      DOUBLE PRECISION XL(MXL), DI(MXL), RG(MXL), XK(MXL), PH(MXL)
      DOUBLE PRECISION PQ(MXL), QL(MXL), FR(MXL), PU(MXL)
      COMMON /LNKI/ NL, LTYP, LLINE, LI, LJ, LCLOSE, LACT
      COMMON /LNKC/ LID, LFROM, LTO
      COMMON /LNKD/ XL, DI, RG, XK, PH, PQ, QL, FR, PU
C
C     DEMAND PATTERNS
      INTEGER NP, PLEN(MXP)
      CHARACTER*8 PNAM(MXP)
      DOUBLE PRECISION PVAL(MXV,MXP)
      COMMON /PATI/ NP, PLEN
      COMMON /PATC/ PNAM
      COMMON /PATD/ PVAL
C
C     RUN CONTROL
      INTEGER IUNIT, IFRIC, MAXIT, NSTEP, NERR, NWARN, LINE, NITER
      INTEGER IEND, NCONV
      LOGICAL CONVRG
      DOUBLE PRECISION TOL, HSTEP
      CHARACTER*60 TITLE
      COMMON /CTLI/ IUNIT, IFRIC, MAXIT, NSTEP, NERR, NWARN, LINE,
     &              NITER, IEND, NCONV
      COMMON /CTLL/ CONVRG
      COMMON /CTLD/ TOL, HSTEP
      COMMON /CTLC/ TITLE
C
C     FIELDS OF THE CURRENT CARD
      INTEGER NFLD, KEYEND
      CHARACTER*40 FIELD(MXF)
      COMMON /CRDI/ NFLD, KEYEND
      COMMON /CRDC/ FIELD
EOF
echo ok
```

<details><summary>output</summary>

```
ok
```
</details>

### Step 78: Bash

```bash
cd /w; docker exec sn-fortran-solver-parity bash -lc 'cd /w; cat > rt.f <<EOF
      PROGRAM RT
      DOUBLE PRECISION X
      CHARACTER*40 S
      INTEGER IOS
      S = "1e400"
      READ (S,*,IOSTAT=IOS) X
      PRINT *, IOS, X
      READ (S,"(F40.0)",IOSTAT=IOS) X
      PRINT *, IOS, X
      S = "1e-400"
      READ (S,*,IOSTAT=IOS) X
      PRINT *, IOS, X
      READ (S,"(F40.0)",IOSTAT=IOS) X
      PRINT *, IOS, X
      S = "5."
      READ (S,*,IOSTAT=IOS) X
      PRINT *, IOS, X
      S = "1d5"
      READ (S,"(F40.0)",IOSTAT=IOS) X
      PRINT *, IOS, X
      S = ".5e+1"
      READ (S,"(F40.0)",IOSTAT=IOS) X
      PRINT *, IOS, X
      END
EOF
gfortran -o rt rt.f && ./rt'
```

<details><summary>output</summary>

```
(eval):cd:1: no such file or directory: /w
           0                  Infinity
           0                  Infinity
           0   0.0000000000000000     
           0   0.0000000000000000     
           0   5.0000000000000000     
           0   100000.00000000000     
           0   5.0000000000000000
```
</details>

### Step 79: Bash

```bash
cd /tmp; docker exec sn-fortran-solver-parity bash -c 'cd /w/new && cat > cards.f' <<'EOF'
C=======================================================================
C     HYDRO 2.3  -  INPUT CARDS
C=======================================================================
C
C     UPCASE  -  CONVERT A STRING TO UPPER CASE IN PLACE
C
      SUBROUTINE UPCASE(S)
      IMPLICIT NONE
      CHARACTER*(*) S
      INTEGER I, K
      DO 10 I = 1, LEN(S)
         K = ICHAR(S(I:I))
         IF (K .GE. 97 .AND. K .LE. 122) S(I:I) = CHAR(K - 32)
   10 CONTINUE
      RETURN
      END
C
C     SPLIT  -  BREAK A CARD INTO BLANK-DELIMITED FIELDS
C
      SUBROUTINE SPLIT(BUF)
      IMPLICIT NONE
      INCLUDE 'hydro.inc'
      CHARACTER*(*) BUF
      INTEGER I, I0, I1
      LOGICAL INWORD
      NFLD = 0
      KEYEND = 0
      INWORD = .FALSE.
      I0 = 1
      DO 20 I = 1, LEN(BUF) + 1
         IF (I .GT. LEN(BUF)) THEN
            IF (INWORD) THEN
               I1 = I - 1
            ENDIF
         ELSE IF (BUF(I:I) .NE. ' ') THEN
            IF (.NOT. INWORD) THEN
               INWORD = .TRUE.
               I0 = I
            ENDIF
            GOTO 20
         ENDIF
         IF (INWORD) THEN
            IF (I .LE. LEN(BUF)) I1 = I - 1
            INWORD = .FALSE.
            IF (NFLD .LT. MXF) THEN
               NFLD = NFLD + 1
               FIELD(NFLD) = BUF(I0:I1)
               IF (NFLD .EQ. 1) KEYEND = I1
            ENDIF
         ENDIF
   20 CONTINUE
      RETURN
      END
C
C     ISNUM  -  TRUE IF THE STRING IS A VALID NUMBER
C
      LOGICAL FUNCTION ISNUM(S)
      IMPLICIT NONE
      CHARACTER*(*) S
      INTEGER I, N, ND
      CHARACTER*1 C
      N = LEN_TRIM(S)
      ISNUM = .FALSE.
      IF (N .EQ. 0) RETURN
      I = 1
      C = S(I:I)
      IF (C .EQ. '+' .OR. C .EQ. '-') I = I + 1
      ND = 0
   10 IF (I .LE. N) THEN
         C = S(I:I)
         IF (C .GE. '0' .AND. C .LE. '9') THEN
            ND = ND + 1
            I = I + 1
            GOTO 10
         ENDIF
      ENDIF
      IF (I .LE. N) THEN
         IF (S(I:I) .EQ. '.') THEN
            I = I + 1
   20       IF (I .LE. N) THEN
               C = S(I:I)
               IF (C .GE. '0' .AND. C .LE. '9') THEN
                  ND = ND + 1
                  I = I + 1
                  GOTO 20
               ENDIF
            ENDIF
         ENDIF
      ENDIF
      IF (ND .EQ. 0) RETURN
      IF (I .LE. N) THEN
         C = S(I:I)
         IF (C .EQ. 'E' .OR. C .EQ. 'e' .OR. C .EQ. 'D' .OR.
     &       C .EQ. 'd') THEN
            I = I + 1
            IF (I .LE. N) THEN
               C = S(I:I)
               IF (C .EQ. '+' .OR. C .EQ. '-') I = I + 1
            ENDIF
            ND = 0
   30       IF (I .LE. N) THEN
               C = S(I:I)
               IF (C .GE. '0' .AND. C .LE. '9') THEN
                  ND = ND + 1
                  I = I + 1
                  GOTO 30
               ENDIF
            ENDIF
            IF (ND .EQ. 0) RETURN
         ENDIF
      ENDIF
      ISNUM = (I .GT. N)
      RETURN
      END
C
C     GETNUM  -  READ A NUMBER FROM A FIELD, REPORTING E104 IF BAD
C
      SUBROUTINE GETNUM(STR, X, OK)
      IMPLICIT NONE
      INCLUDE 'hydro.inc'
      CHARACTER*(*) STR
      DOUBLE PRECISION X
      LOGICAL OK, ISNUM
      INTEGER IOS
      OK = .FALSE.
      X = 0.0D0
      IF (.NOT. ISNUM(STR)) THEN
         CALL PERR(104, 'BAD NUMBER ', STR)
         RETURN
      ENDIF
      READ (STR,*,IOSTAT=IOS) X
      IF (IOS .NE. 0) THEN
         CALL PERR(104, 'BAD NUMBER ', STR)
         RETURN
      ENDIF
      OK = .TRUE.
      RETURN
      END
C
C     PERR  -  REPORT AN INPUT ERROR ON THE CURRENT LINE
C
      SUBROUTINE PERR(CODE, MSG, ARG)
      IMPLICIT NONE
      INCLUDE 'hydro.inc'
      INTEGER CODE
      CHARACTER*(*) MSG, ARG
      NERR = NERR + 1
      IF (LEN_TRIM(ARG) .GT. 0) THEN
         WRITE (6,1000) CODE, LINE, MSG, ARG(1:LEN_TRIM(ARG))
      ELSE
         WRITE (6,1010) CODE, LINE, MSG
      ENDIF
      RETURN
 1000 FORMAT (1X,'*** ERROR E',I3,' LINE',I4,': ',A,'''',A,'''')
 1010 FORMAT (1X,'*** ERROR E',I3,' LINE',I4,': ',A)
      END
C
C     PWARN  -  REPORT A WARNING ON THE CURRENT LINE
C
      SUBROUTINE PWARN(CODE, MSG)
      IMPLICIT NONE
      INCLUDE 'hydro.inc'
      INTEGER CODE
      CHARACTER*(*) MSG
      NWARN = NWARN + 1
      WRITE (6,1000) CODE, LINE, MSG
      RETURN
 1000 FORMAT (1X,'*** WARNING W',I3,' LINE',I4,': ',A)
      END
C
C     INPUT  -  READ THE DECK UNTIL AN END CARD OR END OF FILE
C
      SUBROUTINE INPUT
      IMPLICIT NONE
      INCLUDE 'hydro.inc'
      CHARACTER*80 BUF
      CHARACTER*40 KEY
      INTEGER IOS, I, IC
C
   10 READ (5,'(A)',IOSTAT=IOS) BUF
      IF (IOS .NE. 0) RETURN
      LINE = LINE + 1
      IF (BUF(1:1) .EQ. '*') GOTO 10
      IC = INDEX(BUF, '!')
      IF (IC .GT. 0) BUF(IC:) = ' '
      DO 15 I = 1, 80
         IF (ICHAR(BUF(I:I)) .EQ. 9) BUF(I:I) = ' '
   15 CONTINUE
      CALL SPLIT(BUF)
      IF (NFLD .EQ. 0) GOTO 10
C
      KEY = FIELD(1)
      CALL UPCASE(KEY)
      IF (KEY .EQ. 'END') THEN
         IEND = 1
         RETURN
      ELSE IF (KEY .EQ. 'TITLE') THEN
         CALL TITCRD(BUF)
      ELSE IF (KEY .EQ. 'UNITS') THEN
         CALL UNTCRD
      ELSE IF (KEY .EQ. 'OPTION') THEN
         CALL OPTCRD
      ELSE IF (KEY .EQ. 'JUNCTION') THEN
         CALL JUNCRD
      ELSE IF (KEY .EQ. 'RESERVOIR') THEN
         CALL RESCRD
      ELSE IF (KEY .EQ. 'PIPE') THEN
         CALL PIPCRD
      ELSE IF (KEY .EQ. 'PUMP') THEN
         CALL PMPCRD
      ELSE IF (KEY .EQ. 'VALVE') THEN
         CALL VLVCRD
      ELSE IF (KEY .EQ. 'PATTERN') THEN
         CALL PATCRD
      ELSE
         CALL PERR(101, 'UNKNOWN CARD ', KEY(1:16))
      ENDIF
      GOTO 10
      END
C
C     TITCRD  -  TITLE TEXT (FIRST 60 CHARACTERS AFTER THE KEYWORD)
C
      SUBROUTINE TITCRD(BUF)
      IMPLICIT NONE
      INCLUDE 'hydro.inc'
      CHARACTER*(*) BUF
      INTEGER I
      TITLE = ' '
      I = KEYEND + 1
   10 IF (I .LE. LEN(BUF)) THEN
         IF (BUF(I:I) .EQ. ' ') THEN
            I = I + 1
            GOTO 10
         ENDIF
         TITLE = BUF(I:)
      ENDIF
      RETURN
      END
C
C     UNTCRD  -  UNITS SI | US
C
      SUBROUTINE UNTCRD
      IMPLICIT NONE
      INCLUDE 'hydro.inc'
      CHARACTER*40 V
      IF (NFLD .LT. 2) THEN
         CALL PERR(105, 'MISSING FIELD(S)', ' ')
         RETURN
      ENDIF
      V = FIELD(2)
      CALL UPCASE(V)
      IF (V .EQ. 'SI') THEN
         IUNIT = 1
      ELSE IF (V .EQ. 'US') THEN
         IUNIT = 2
      ELSE
         CALL PERR(108, 'INVALID OPTION VALUE ', FIELD(2))
         RETURN
      ENDIF
      IF (NFLD .GT. 2) CALL PWARN(209, 'EXTRA FIELDS IGNORED')
      RETURN
      END
C
C     OPTCRD  -  OPTION NAME VALUE
C
      SUBROUTINE OPTCRD
      IMPLICIT NONE
      INCLUDE 'hydro.inc'
      CHARACTER*40 V, NAME
      DOUBLE PRECISION X
      LOGICAL OK
      IF (NFLD .LT. 3) THEN
         CALL PERR(105, 'MISSING FIELD(S)', ' ')
         RETURN
      ENDIF
      NAME = FIELD(2)
      CALL UPCASE(NAME)
      IF (NAME .EQ. 'FRICTION') THEN
         V = FIELD(3)
         CALL UPCASE(V)
         IF (V .EQ. 'DW') THEN
            IFRIC = 1
         ELSE IF (V .EQ. 'HW') THEN
            IFRIC = 2
         ELSE
            CALL PERR(108, 'INVALID OPTION VALUE ', FIELD(3))
            RETURN
         ENDIF
      ELSE IF (NAME .EQ. 'TOL') THEN
         CALL GETNUM(FIELD(3), X, OK)
         IF (.NOT. OK) RETURN
         IF (.NOT. (X .GT. 0.0D0)) THEN
            CALL PERR(108, 'INVALID OPTION VALUE ', FIELD(3))
            RETURN
         ENDIF
         TOL = X
      ELSE IF (NAME .EQ. 'MAXIT') THEN
         CALL GETNUM(FIELD(3), X, OK)
         IF (.NOT. OK) RETURN
         IF (X .LT. 1.0D0 .OR. X .NE. AINT(X)) THEN
            CALL PERR(108, 'INVALID OPTION VALUE ', FIELD(3))
            RETURN
         ENDIF
         IF (X .GT. 200.0D0) THEN
            CALL PWARN(206, 'MAXIT LIMITED TO 200')
            MAXIT = 200
         ELSE
            MAXIT = INT(X)
         ENDIF
      ELSE IF (NAME .EQ. 'STEPS') THEN
         CALL GETNUM(FIELD(3), X, OK)
         IF (.NOT. OK) RETURN
         IF (X .LT. 1.0D0 .OR. X .GT. 24.0D0 .OR.
     &       X .NE. AINT(X)) THEN
            CALL PERR(108, 'INVALID OPTION VALUE ', FIELD(3))
            RETURN
         ENDIF
         NSTEP = INT(X)
      ELSE IF (NAME .EQ. 'HSTEP') THEN
         CALL GETNUM(FIELD(3), X, OK)
         IF (.NOT. OK) RETURN
         IF (.NOT. (X .GT. 0.0D0 .AND. X .LE. 24.0D0)) THEN
            CALL PERR(108, 'INVALID OPTION VALUE ', FIELD(3))
            RETURN
         ENDIF
         HSTEP = X
      ELSE
         CALL PERR(109, 'UNKNOWN OPTION ', NAME)
         RETURN
      ENDIF
      IF (NFLD .GT. 3) CALL PWARN(209, 'EXTRA FIELDS IGNORED')
      RETURN
      END
C
C     CHKID  -  CHECK A NEW ID (LENGTH, DUPLICATE, CAPACITY).
C               KIND 1 = NODE, 2 = LINK.  OK=.FALSE. IF REJECTED.
C
      SUBROUTINE CHKID(S, KIND, OK)
      IMPLICIT NONE
      INCLUDE 'hydro.inc'
      CHARACTER*(*) S
      INTEGER KIND, I
      LOGICAL OK
      OK = .FALSE.
      IF (LEN_TRIM(S) .GT. 8) THEN
         CALL PERR(106, 'ID TOO LONG ', S)
         RETURN
      ENDIF
      IF (KIND .EQ. 1) THEN
         DO 10 I = 1, NN
            IF (NID(I) .EQ. S) THEN
               CALL PERR(102, 'DUPLICATE ID ', S)
               RETURN
            ENDIF
   10    CONTINUE
         IF (NN .GE. MXN) THEN
            CALL PERR(111, 'TOO MANY NODES', ' ')
            RETURN
         ENDIF
      ELSE
         DO 20 I = 1, NL
            IF (LID(I) .EQ. S) THEN
               CALL PERR(102, 'DUPLICATE ID ', S)
               RETURN
            ENDIF
   20    CONTINUE
         IF (NL .GE. MXL) THEN
            CALL PERR(111, 'TOO MANY LINKS', ' ')
            RETURN
         ENDIF
      ENDIF
      OK = .TRUE.
      RETURN
      END
C
C     JUNCRD  -  JUNCTION ID ELEVATION [DEMAND [PATTERN]]
C
      SUBROUTINE JUNCRD
      IMPLICIT NONE
      INCLUDE 'hydro.inc'
      LOGICAL OK
      DOUBLE PRECISION Z, Q
      IF (NFLD .LT. 3) THEN
         CALL PERR(105, 'MISSING FIELD(S)', ' ')
         RETURN
      ENDIF
      CALL CHKID(FIELD(2), 1, OK)
      IF (.NOT. OK) RETURN
      CALL GETNUM(FIELD(3), Z, OK)
      IF (.NOT. OK) RETURN
      Q = 0.0D0
      IF (NFLD .GE. 4) THEN
         CALL GETNUM(FIELD(4), Q, OK)
         IF (.NOT. OK) RETURN
      ENDIF
      IF (NFLD .GE. 5) THEN
         IF (LEN_TRIM(FIELD(5)) .GT. 8) THEN
            CALL PERR(106, 'ID TOO LONG ', FIELD(5))
            RETURN
         ENDIF
      ENDIF
      NN = NN + 1
      NID(NN) = FIELD(2)
      NTYP(NN) = 1
      NLINE(NN) = LINE
      ZIN(NN) = Z
      QB(NN) = Q
      NPNAM(NN) = ' '
      IF (NFLD .GE. 5) NPNAM(NN) = FIELD(5)
      IF (NFLD .GT. 5) CALL PWARN(209, 'EXTRA FIELDS IGNORED')
      RETURN
      END
C
C     RESCRD  -  RESERVOIR ID HEAD
C
      SUBROUTINE RESCRD
      IMPLICIT NONE
      INCLUDE 'hydro.inc'
      LOGICAL OK
      DOUBLE PRECISION Z
      IF (NFLD .LT. 3) THEN
         CALL PERR(105, 'MISSING FIELD(S)', ' ')
         RETURN
      ENDIF
      CALL CHKID(FIELD(2), 1, OK)
      IF (.NOT. OK) RETURN
      CALL GETNUM(FIELD(3), Z, OK)
      IF (.NOT. OK) RETURN
      NN = NN + 1
      NID(NN) = FIELD(2)
      NTYP(NN) = 2
      NLINE(NN) = LINE
      ZIN(NN) = Z
      QB(NN) = 0.0D0
      NPNAM(NN) = ' '
      IF (NFLD .GT. 3) CALL PWARN(209, 'EXTRA FIELDS IGNORED')
      RETURN
      END
C
C     NEWLNK  -  COMMON PART OF THE LINK CARDS.  RETURNS THE NEW LINK
C                INDEX IN L, OR 0 IF THE ID OR END NODES ARE REJECTED.
C
      SUBROUTINE NEWLNK(L, ITYPE)
      IMPLICIT NONE
      INCLUDE 'hydro.inc'
      INTEGER L, ITYPE
      LOGICAL OK
      L = 0
      CALL CHKID(FIELD(2), 2, OK)
      IF (.NOT. OK) RETURN
      IF (FIELD(3) .EQ. FIELD(4)) THEN
         CALL PERR(110, 'LINK CONNECTS NODE TO ITSELF', ' ')
         RETURN
      ENDIF
      L = NL + 1
      LID(L) = FIELD(2)
      LTYP(L) = ITYPE
      LLINE(L) = LINE
      LFROM(L) = FIELD(3)
      LTO(L) = FIELD(4)
      XL(L) = 0.0D0
      DI(L) = 0.0D0
      RG(L) = 0.0D0
      XK(L) = 0.0D0
      PH(L) = 0.0D0
      PQ(L) = 0.0D0
      LCLOSE(L) = 0
      RETURN
      END
C
C     PIPCRD  -  PIPE ID FROM TO LENGTH DIAMETER ROUGHNESS [K]
C
      SUBROUTINE PIPCRD
      IMPLICIT NONE
      INCLUDE 'hydro.inc'
      INTEGER L
      LOGICAL OK
      DOUBLE PRECISION A, B, C, D
      IF (NFLD .LT. 7) THEN
         CALL PERR(105, 'MISSING FIELD(S)', ' ')
         RETURN
      ENDIF
      CALL NEWLNK(L, 1)
      IF (L .EQ. 0) RETURN
      CALL GETNUM(FIELD(5), A, OK)
      IF (.NOT. OK) RETURN
      CALL GETNUM(FIELD(6), B, OK)
      IF (.NOT. OK) RETURN
      CALL GETNUM(FIELD(7), C, OK)
      IF (.NOT. OK) RETURN
      D = 0.0D0
      IF (NFLD .GE. 8) THEN
         CALL GETNUM(FIELD(8), D, OK)
         IF (.NOT. OK) RETURN
      ENDIF
      IF (A .LE. 0.0D0 .OR. B .LE. 0.0D0 .OR. C .LT. 0.0D0 .OR.
     &    D .LT. 0.0D0) THEN
         CALL PERR(107, 'VALUE OUT OF RANGE', ' ')
         RETURN
      ENDIF
      XL(L) = A
      DI(L) = B
      RG(L) = C
      XK(L) = D
      NL = L
      IF (NFLD .GT. 8) CALL PWARN(209, 'EXTRA FIELDS IGNORED')
      RETURN
      END
C
C     PMPCRD  -  PUMP ID FROM TO HEAD [QMAX]
C
      SUBROUTINE PMPCRD
      IMPLICIT NONE
      INCLUDE 'hydro.inc'
      INTEGER L
      LOGICAL OK
      DOUBLE PRECISION A, B
      IF (NFLD .LT. 5) THEN
         CALL PERR(105, 'MISSING FIELD(S)', ' ')
         RETURN
      ENDIF
      CALL NEWLNK(L, 2)
      IF (L .EQ. 0) RETURN
      CALL GETNUM(FIELD(5), A, OK)
      IF (.NOT. OK) RETURN
      B = 0.0D0
      IF (NFLD .GE. 6) THEN
         CALL GETNUM(FIELD(6), B, OK)
         IF (.NOT. OK) RETURN
      ENDIF
      IF (A .LE. 0.0D0 .OR. (NFLD .GE. 6 .AND. B .LE. 0.0D0)) THEN
         CALL PERR(107, 'VALUE OUT OF RANGE', ' ')
         RETURN
      ENDIF
      PH(L) = A
      PQ(L) = B
      NL = L
      IF (NFLD .GT. 6) CALL PWARN(209, 'EXTRA FIELDS IGNORED')
      RETURN
      END
C
C     VLVCRD  -  VALVE ID FROM TO DIAMETER K [OPEN | CLOSED]
C
      SUBROUTINE VLVCRD
      IMPLICIT NONE
      INCLUDE 'hydro.inc'
      INTEGER L, ICL
      LOGICAL OK
      DOUBLE PRECISION A, B
      CHARACTER*40 V
      IF (NFLD .LT. 6) THEN
         CALL PERR(105, 'MISSING FIELD(S)', ' ')
         RETURN
      ENDIF
      CALL NEWLNK(L, 3)
      IF (L .EQ. 0) RETURN
      CALL GETNUM(FIELD(5), A, OK)
      IF (.NOT. OK) RETURN
      CALL GETNUM(FIELD(6), B, OK)
      IF (.NOT. OK) RETURN
      ICL = 0
      IF (NFLD .GE. 7) THEN
         V = FIELD(7)
         CALL UPCASE(V)
         IF (V .EQ. 'CLOSED') THEN
            ICL = 1
         ELSE IF (V .NE. 'OPEN') THEN
            CALL PERR(108, 'INVALID OPTION VALUE ', FIELD(7))
            RETURN
         ENDIF
      ENDIF
      IF (A .LE. 0.0D0 .OR. B .LT. 0.0D0) THEN
         CALL PERR(107, 'VALUE OUT OF RANGE', ' ')
         RETURN
      ENDIF
      DI(L) = A
      XK(L) = B
      LCLOSE(L) = ICL
      NL = L
      IF (NFLD .GT. 7) CALL PWARN(209, 'EXTRA FIELDS IGNORED')
      RETURN
      END
C
C     PATCRD  -  PATTERN ID M1 [M2 ...]
C
      SUBROUTINE PATCRD
      IMPLICIT NONE
      INCLUDE 'hydro.inc'
      INTEGER I, K, N
      LOGICAL OK
      DOUBLE PRECISION X, T(MXF)
      IF (NFLD .LT. 3) THEN
         CALL PERR(105, 'MISSING FIELD(S)', ' ')
         RETURN
      ENDIF
      IF (LEN_TRIM(FIELD(2)) .GT. 8) THEN
         CALL PERR(106, 'ID TOO LONG ', FIELD(2))
         RETURN
      ENDIF
      K = 0
      DO 10 I = 1, NP
         IF (PNAM(I) .EQ. FIELD(2)) K = I
   10 CONTINUE
      IF (K .EQ. 0) THEN
         IF (NP .GE. MXP) THEN
            CALL PERR(111, 'TOO MANY PATTERNS', ' ')
            RETURN
         ENDIF
         N = 0
      ELSE
         N = PLEN(K)
      ENDIF
      IF (N + NFLD - 2 .GT. MXV) THEN
         CALL PERR(113, 'PATTERN TOO LONG', ' ')
         RETURN
      ENDIF
      DO 20 I = 3, NFLD
         CALL GETNUM(FIELD(I), X, OK)
         IF (.NOT. OK) RETURN
         IF (X .LT. 0.0D0) THEN
            CALL PERR(107, 'VALUE OUT OF RANGE', ' ')
            RETURN
         ENDIF
         T(I) = X
   20 CONTINUE
      IF (K .EQ. 0) THEN
         NP = NP + 1
         K = NP
         PNAM(K) = FIELD(2)
         PLEN(K) = 0
      ENDIF
      DO 30 I = 3, NFLD
         PLEN(K) = PLEN(K) + 1
         PVAL(PLEN(K),K) = T(I)
   30 CONTINUE
      RETURN
      END
EOF
echo ok
```

<details><summary>output</summary>

```
ok
```
</details>

### Step 80: Bash

```bash
cd /tmp; docker exec sn-fortran-solver-parity bash -c 'cd /w/new && python3 - <<PYEOF
s=open("cards.f").read()
old="""      CALL CHKID(FIELD(2), 1, OK)
      IF (.NOT. OK) RETURN
      CALL GETNUM(FIELD(3), Z, OK)
      IF (.NOT. OK) RETURN
      Q = 0.0D0
      IF (NFLD .GE. 4) THEN
         CALL GETNUM(FIELD(4), Q, OK)
         IF (.NOT. OK) RETURN
      ENDIF
      IF (NFLD .GE. 5) THEN
         IF (LEN_TRIM(FIELD(5)) .GT. 8) THEN
            CALL PERR(106, \x27ID TOO LONG \x27, FIELD(5))
            RETURN
         ENDIF
      ENDIF
"""
new="""      CALL CHKID(FIELD(2), 1, OK)
      IF (.NOT. OK) RETURN
      IF (NFLD .GE. 5) THEN
         IF (LEN_TRIM(FIELD(5)) .GT. 8) THEN
            CALL PERR(106, \x27ID TOO LONG \x27, FIELD(5))
            RETURN
         ENDIF
      ENDIF
      CALL GETNUM(FIELD(3), Z, OK)
      IF (.NOT. OK) RETURN
      Q = 0.0D0
      IF (NFLD .GE. 4) THEN
         CALL GETNUM(FIELD(4), Q, OK)
         IF (.NOT. OK) RETURN
      ENDIF
"""
assert old in s
s=s.replace(old,new)
old2="""      IF (FIELD(3) .EQ. FIELD(4)) THEN"""
new2="""      IF (LEN_TRIM(FIELD(3)) .GT. 8) THEN
         CALL PERR(106, \x27ID TOO LONG \x27, FIELD(3))
         RETURN
      ENDIF
      IF (LEN_TRIM(FIELD(4)) .GT. 8) THEN
         CALL PERR(106, \x27ID TOO LONG \x27, FIELD(4))
         RETURN
      ENDIF
      IF (FIELD(3) .EQ. FIELD(4)) THEN"""
s=s.replace(old2,new2)
open("cards.f","w").write(s)
PYEOF
echo done'
```

<details><summary>output</summary>

```
Traceback (most recent call last):
  File "<stdin>", line 34, in <module>
AssertionError
done
```
</details>

### Step 81: Bash

```bash
cd /tmp; cat > /tmp/ed1.py <<'PYEOF'
s=open("/w/new/cards.f").read()
old="""      CALL CHKID(FIELD(2), 1, OK)
      IF (.NOT. OK) RETURN
      CALL GETNUM(FIELD(3), Z, OK)
      IF (.NOT. OK) RETURN
      Q = 0.0D0
      IF (NFLD .GE. 4) THEN
         CALL GETNUM(FIELD(4), Q, OK)
         IF (.NOT. OK) RETURN
      ENDIF
      IF (NFLD .GE. 5) THEN
         IF (LEN_TRIM(FIELD(5)) .GT. 8) THEN
            CALL PERR(106, 'ID TOO LONG ', FIELD(5))
            RETURN
         ENDIF
      ENDIF
"""
new="""      CALL CHKID(FIELD(2), 1, OK)
      IF (.NOT. OK) RETURN
      IF (NFLD .GE. 5) THEN
         IF (LEN_TRIM(FIELD(5)) .GT. 8) THEN
            CALL PERR(106, 'ID TOO LONG ', FIELD(5))
            RETURN
         ENDIF
      ENDIF
      CALL GETNUM(FIELD(3), Z, OK)
      IF (.NOT. OK) RETURN
      Q = 0.0D0
      IF (NFLD .GE. 4) THEN
         CALL GETNUM(FIELD(4), Q, OK)
         IF (.NOT. OK) RETURN
      ENDIF
"""
assert old in s
s=s.replace(old,new)
old2="      IF (FIELD(3) .EQ. FIELD(4)) THEN"
new2="""      IF (LEN_TRIM(FIELD(3)) .GT. 8) THEN
         CALL PERR(106, 'ID TOO LONG ', FIELD(3))
         RETURN
      ENDIF
      IF (LEN_TRIM(FIELD(4)) .GT. 8) THEN
         CALL PERR(106, 'ID TOO LONG ', FIELD(4))
         RETURN
      ENDIF
      IF (FIELD(3) .EQ. FIELD(4)) THEN"""
assert old2 in s
s=s.replace(old2,new2)
open("/w/new/cards.f","w").write(s)
PYEOF
docker exec -i sn-fortran-solver-parity python3 - < /tmp/ed1.py && echo ok
```

<details><summary>output</summary>

```
Exit code 1
Traceback (most recent call last):
  File "<stdin>", line 34, in <module>
AssertionError
```
</details>

### Step 82: Bash

```bash
docker exec sn-fortran-solver-parity bash -c 'cd /w/new; grep -n "CHKID(FIELD(2), 1" -A 16 cards.f | head -50'
```

<details><summary>output</summary>

```
(Bash completed with no output)
```
</details>

### Step 83: Bash

```bash
docker exec sn-fortran-solver-parity bash -c 'cd /w/new; ls -la; wc -l *'
```

<details><summary>output</summary>

```
total 8
drwxr-xr-x 2 root root 4096 Nov 18 08:59 .
drwxr-xr-x 5 root root 4096 Nov 18 08:58 ..
-rw-r--r-- 1 root root    0 Nov 18 08:59 cards.f
-rw-r--r-- 1 root root    0 Nov 18 08:58 hydro.inc
0 cards.f
0 hydro.inc
0 total
```
</details>

### Step 84: Bash

```bash
cd /tmp; docker exec -i sn-fortran-solver-parity bash -c 'cat > /w/new/hydro.inc' <<'EOF'
C     HYDRO 2.3  COMMON BLOCKS
      INTEGER MXN, MXL, MXP, MXV, MXF
      PARAMETER (MXN=100, MXL=150, MXP=12, MXV=24, MXF=16)
      DOUBLE PRECISION GRAV, PI, VISC, GMIN, QZERO
      PARAMETER (GRAV=9.80665D0, PI=3.14159265358979323846D0)
      PARAMETER (VISC=1.0D-6, GMIN=1.0D-4, QZERO=1.0D-6)
C
C     NODES.  NTYP 1 JUNCTION, 2 RESERVOIR.  NODES ARE KEPT IN INPUT
C     ORDER; NSORT HOLDS THE REPORT ORDER (ALPHABETICAL).
      INTEGER NN, NTYP(MXN), NLINE(MXN), NSORT(MXN), NPAT(MXN)
      INTEGER NISO(MXN)
      CHARACTER*8 NID(MXN)
      CHARACTER*8 NPNAM(MXN)
      DOUBLE PRECISION ZIN(MXN), ZN(MXN), QB(MXN), QD(MXN), HN(MXN)
      COMMON /NODI/ NN, NTYP, NLINE, NSORT, NPAT, NISO
      COMMON /NODC/ NID, NPNAM
      COMMON /NODD/ ZIN, ZN, QB, QD, HN
C
C     LINKS.  LTYP 1 PIPE, 2 PUMP, 3 VALVE.  LCLOSE 1 IF CLOSED VALVE.
      INTEGER NL, LTYP(MXL), LLINE(MXL), LI(MXL), LJ(MXL), LCLOSE(MXL)
      INTEGER LACT(MXL)
      CHARACTER*8 LID(MXL)
      CHARACTER*40 LFROM(MXL), LTO(MXL)
      DOUBLE PRECISION XL(MXL), DI(MXL), RG(MXL), XK(MXL), PH(MXL)
      DOUBLE PRECISION PQ(MXL), QL(MXL), FR(MXL), PU(MXL)
      COMMON /LNKI/ NL, LTYP, LLINE, LI, LJ, LCLOSE, LACT
      COMMON /LNKC/ LID, LFROM, LTO
      COMMON /LNKD/ XL, DI, RG, XK, PH, PQ, QL, FR, PU
C
C     DEMAND PATTERNS
      INTEGER NP, PLEN(MXP)
      CHARACTER*8 PNAM(MXP)
      DOUBLE PRECISION PVAL(MXV,MXP)
      COMMON /PATI/ NP, PLEN
      COMMON /PATC/ PNAM
      COMMON /PATD/ PVAL
C
C     RUN CONTROL
      INTEGER IUNIT, IFRIC, MAXIT, NSTEP, NERR, NWARN, LINE, NITER
      INTEGER IEND, NCONV
      LOGICAL CONVRG
      DOUBLE PRECISION TOL, HSTEP
      CHARACTER*60 TITLE
      COMMON /CTLI/ IUNIT, IFRIC, MAXIT, NSTEP, NERR, NWARN, LINE,
     &              NITER, IEND, NCONV
      COMMON /CTLL/ CONVRG
      COMMON /CTLD/ TOL, HSTEP
      COMMON /CTLC/ TITLE
C
C     FIELDS OF THE CURRENT CARD
      INTEGER NFLD, KEYEND
      CHARACTER*40 FIELD(MXF)
      COMMON /CRDI/ NFLD, KEYEND
      COMMON /CRDC/ FIELD
EOF
wc -l /dev/null; docker exec sn-fortran-solver-parity wc -l /w/new/hydro.inc
```

<details><summary>output</summary>

```
       0 /dev/null
54 /w/new/hydro.inc
```
</details>

Now cards.f with the fixes.

### Step 85: Bash

```bash
cd /tmp; docker exec -i sn-fortran-solver-parity bash -c 'cat > /w/new/cards.f' <<'EOF'
C=======================================================================
C     HYDRO 2.3  -  INPUT CARDS
C=======================================================================
C
C     UPCASE  -  CONVERT A STRING TO UPPER CASE IN PLACE
C
      SUBROUTINE UPCASE(S)
      IMPLICIT NONE
      CHARACTER*(*) S
      INTEGER I, K
      DO 10 I = 1, LEN(S)
         K = ICHAR(S(I:I))
         IF (K .GE. 97 .AND. K .LE. 122) S(I:I) = CHAR(K - 32)
   10 CONTINUE
      RETURN
      END
C
C     SPLIT  -  BREAK A CARD INTO BLANK-DELIMITED FIELDS
C
      SUBROUTINE SPLIT(BUF)
      IMPLICIT NONE
      INCLUDE 'hydro.inc'
      CHARACTER*(*) BUF
      INTEGER I, I0, I1, N
      LOGICAL INWORD
      NFLD = 0
      KEYEND = 0
      INWORD = .FALSE.
      I0 = 1
      N = LEN(BUF)
      DO 20 I = 1, N + 1
         IF (I .LE. N) THEN
            IF (BUF(I:I) .NE. ' ') THEN
               IF (.NOT. INWORD) THEN
                  INWORD = .TRUE.
                  I0 = I
               ENDIF
               GOTO 20
            ENDIF
         ENDIF
         IF (INWORD) THEN
            I1 = I - 1
            INWORD = .FALSE.
            IF (NFLD .LT. MXF) THEN
               NFLD = NFLD + 1
               FIELD(NFLD) = BUF(I0:I1)
               IF (NFLD .EQ. 1) KEYEND = I1
            ENDIF
         ENDIF
   20 CONTINUE
      RETURN
      END
C
C     ISNUM  -  TRUE IF THE STRING IS A VALID NUMBER
C
      LOGICAL FUNCTION ISNUM(S)
      IMPLICIT NONE
      CHARACTER*(*) S
      INTEGER I, N, ND
      CHARACTER*1 C
      N = LEN_TRIM(S)
      ISNUM = .FALSE.
      IF (N .EQ. 0) RETURN
      I = 1
      C = S(I:I)
      IF (C .EQ. '+' .OR. C .EQ. '-') I = I + 1
      ND = 0
   10 IF (I .LE. N) THEN
         C = S(I:I)
         IF (C .GE. '0' .AND. C .LE. '9') THEN
            ND = ND + 1
            I = I + 1
            GOTO 10
         ENDIF
      ENDIF
      IF (I .LE. N) THEN
         IF (S(I:I) .EQ. '.') THEN
            I = I + 1
   20       IF (I .LE. N) THEN
               C = S(I:I)
               IF (C .GE. '0' .AND. C .LE. '9') THEN
                  ND = ND + 1
                  I = I + 1
                  GOTO 20
               ENDIF
            ENDIF
         ENDIF
      ENDIF
      IF (ND .EQ. 0) RETURN
      IF (I .LE. N) THEN
         C = S(I:I)
         IF (C .EQ. 'E' .OR. C .EQ. 'e' .OR. C .EQ. 'D' .OR.
     &       C .EQ. 'd') THEN
            I = I + 1
            IF (I .LE. N) THEN
               C = S(I:I)
               IF (C .EQ. '+' .OR. C .EQ. '-') I = I + 1
            ENDIF
            ND = 0
   30       IF (I .LE. N) THEN
               C = S(I:I)
               IF (C .GE. '0' .AND. C .LE. '9') THEN
                  ND = ND + 1
                  I = I + 1
                  GOTO 30
               ENDIF
            ENDIF
            IF (ND .EQ. 0) RETURN
         ENDIF
      ENDIF
      ISNUM = (I .GT. N)
      RETURN
      END
C
C     GETNUM  -  READ A NUMBER FROM A FIELD, REPORTING E104 IF BAD
C
      SUBROUTINE GETNUM(STR, X, OK)
      IMPLICIT NONE
      INCLUDE 'hydro.inc'
      CHARACTER*(*) STR
      DOUBLE PRECISION X
      LOGICAL OK, ISNUM
      INTEGER IOS
      OK = .FALSE.
      X = 0.0D0
      IF (.NOT. ISNUM(STR)) THEN
         CALL PERR(104, 'BAD NUMBER ', STR)
         RETURN
      ENDIF
      READ (STR,*,IOSTAT=IOS) X
      IF (IOS .NE. 0) THEN
         CALL PERR(104, 'BAD NUMBER ', STR)
         RETURN
      ENDIF
      OK = .TRUE.
      RETURN
      END
C
C     PERR  -  REPORT AN INPUT ERROR ON THE CURRENT LINE
C
      SUBROUTINE PERR(CODE, MSG, ARG)
      IMPLICIT NONE
      INCLUDE 'hydro.inc'
      INTEGER CODE
      CHARACTER*(*) MSG, ARG
      NERR = NERR + 1
      IF (LEN_TRIM(ARG) .GT. 0) THEN
         WRITE (6,1000) CODE, LINE, MSG, ARG(1:LEN_TRIM(ARG))
      ELSE
         WRITE (6,1010) CODE, LINE, MSG
      ENDIF
      RETURN
 1000 FORMAT (1X,'*** ERROR E',I3,' LINE',I4,': ',A,'''',A,'''')
 1010 FORMAT (1X,'*** ERROR E',I3,' LINE',I4,': ',A)
      END
C
C     PWARN  -  REPORT A WARNING ON THE CURRENT LINE
C
      SUBROUTINE PWARN(CODE, MSG)
      IMPLICIT NONE
      INCLUDE 'hydro.inc'
      INTEGER CODE
      CHARACTER*(*) MSG
      NWARN = NWARN + 1
      WRITE (6,1000) CODE, LINE, MSG
      RETURN
 1000 FORMAT (1X,'*** WARNING W',I3,' LINE',I4,': ',A)
      END
C
C     INPUT  -  READ THE DECK UNTIL AN END CARD OR END OF FILE
C
      SUBROUTINE INPUT
      IMPLICIT NONE
      INCLUDE 'hydro.inc'
      CHARACTER*80 BUF
      CHARACTER*40 KEY
      INTEGER IOS, I, IC
C
   10 READ (5,'(A)',IOSTAT=IOS) BUF
      IF (IOS .NE. 0) RETURN
      LINE = LINE + 1
      IF (BUF(1:1) .EQ. '*') GOTO 10
      IC = INDEX(BUF, '!')
      IF (IC .GT. 0) BUF(IC:) = ' '
      DO 15 I = 1, 80
         IF (ICHAR(BUF(I:I)) .EQ. 9) BUF(I:I) = ' '
   15 CONTINUE
      CALL SPLIT(BUF)
      IF (NFLD .EQ. 0) GOTO 10
C
      KEY = FIELD(1)
      CALL UPCASE(KEY)
      IF (KEY .EQ. 'END') THEN
         IEND = 1
         RETURN
      ELSE IF (KEY .EQ. 'TITLE') THEN
         CALL TITCRD(BUF)
      ELSE IF (KEY .EQ. 'UNITS') THEN
         CALL UNTCRD
      ELSE IF (KEY .EQ. 'OPTION') THEN
         CALL OPTCRD
      ELSE IF (KEY .EQ. 'JUNCTION') THEN
         CALL JUNCRD
      ELSE IF (KEY .EQ. 'RESERVOIR') THEN
         CALL RESCRD
      ELSE IF (KEY .EQ. 'PIPE') THEN
         CALL PIPCRD
      ELSE IF (KEY .EQ. 'PUMP') THEN
         CALL PMPCRD
      ELSE IF (KEY .EQ. 'VALVE') THEN
         CALL VLVCRD
      ELSE IF (KEY .EQ. 'PATTERN') THEN
         CALL PATCRD
      ELSE
         CALL PERR(101, 'UNKNOWN CARD ', KEY(1:16))
      ENDIF
      GOTO 10
      END
C
C     TITCRD  -  TITLE TEXT (FIRST 60 CHARACTERS AFTER THE KEYWORD)
C
      SUBROUTINE TITCRD(BUF)
      IMPLICIT NONE
      INCLUDE 'hydro.inc'
      CHARACTER*(*) BUF
      INTEGER I
      TITLE = ' '
      I = KEYEND + 1
   10 IF (I .LE. LEN(BUF)) THEN
         IF (BUF(I:I) .EQ. ' ') THEN
            I = I + 1
            GOTO 10
         ENDIF
         TITLE = BUF(I:)
      ENDIF
      RETURN
      END
C
C     UNTCRD  -  UNITS SI | US
C
      SUBROUTINE UNTCRD
      IMPLICIT NONE
      INCLUDE 'hydro.inc'
      CHARACTER*40 V
      IF (NFLD .LT. 2) THEN
         CALL PERR(105, 'MISSING FIELD(S)', ' ')
         RETURN
      ENDIF
      V = FIELD(2)
      CALL UPCASE(V)
      IF (V .EQ. 'SI') THEN
         IUNIT = 1
      ELSE IF (V .EQ. 'US') THEN
         IUNIT = 2
      ELSE
         CALL PERR(108, 'INVALID OPTION VALUE ', FIELD(2))
         RETURN
      ENDIF
      IF (NFLD .GT. 2) CALL PWARN(209, 'EXTRA FIELDS IGNORED')
      RETURN
      END
C
C     OPTCRD  -  OPTION NAME VALUE
C
      SUBROUTINE OPTCRD
      IMPLICIT NONE
      INCLUDE 'hydro.inc'
      CHARACTER*40 V, NAME
      DOUBLE PRECISION X
      LOGICAL OK
      IF (NFLD .LT. 3) THEN
         CALL PERR(105, 'MISSING FIELD(S)', ' ')
         RETURN
      ENDIF
      NAME = FIELD(2)
      CALL UPCASE(NAME)
      IF (NAME .EQ. 'FRICTION') THEN
         V = FIELD(3)
         CALL UPCASE(V)
         IF (V .EQ. 'DW') THEN
            IFRIC = 1
         ELSE IF (V .EQ. 'HW') THEN
            IFRIC = 2
         ELSE
            CALL PERR(108, 'INVALID OPTION VALUE ', FIELD(3))
            RETURN
         ENDIF
      ELSE IF (NAME .EQ. 'TOL') THEN
         CALL GETNUM(FIELD(3), X, OK)
         IF (.NOT. OK) RETURN
         IF (.NOT. (X .GT. 0.0D0)) THEN
            CALL PERR(108, 'INVALID OPTION VALUE ', FIELD(3))
            RETURN
         ENDIF
         TOL = X
      ELSE IF (NAME .EQ. 'MAXIT') THEN
         CALL GETNUM(FIELD(3), X, OK)
         IF (.NOT. OK) RETURN
         IF (X .LT. 1.0D0 .OR. X .NE. AINT(X)) THEN
            CALL PERR(108, 'INVALID OPTION VALUE ', FIELD(3))
            RETURN
         ENDIF
         IF (X .GT. 200.0D0) THEN
            CALL PWARN(206, 'MAXIT LIMITED TO 200')
            MAXIT = 200
         ELSE
            MAXIT = INT(X)
         ENDIF
      ELSE IF (NAME .EQ. 'STEPS') THEN
         CALL GETNUM(FIELD(3), X, OK)
         IF (.NOT. OK) RETURN
         IF (X .LT. 1.0D0 .OR. X .GT. 24.0D0 .OR.
     &       X .NE. AINT(X)) THEN
            CALL PERR(108, 'INVALID OPTION VALUE ', FIELD(3))
            RETURN
         ENDIF
         NSTEP = INT(X)
      ELSE IF (NAME .EQ. 'HSTEP') THEN
         CALL GETNUM(FIELD(3), X, OK)
         IF (.NOT. OK) RETURN
         IF (.NOT. (X .GT. 0.0D0 .AND. X .LE. 24.0D0)) THEN
            CALL PERR(108, 'INVALID OPTION VALUE ', FIELD(3))
            RETURN
         ENDIF
         HSTEP = X
      ELSE
         CALL PERR(109, 'UNKNOWN OPTION ', NAME)
         RETURN
      ENDIF
      IF (NFLD .GT. 3) CALL PWARN(209, 'EXTRA FIELDS IGNORED')
      RETURN
      END
C
C     CHKID  -  CHECK A NEW ID (LENGTH, DUPLICATE, CAPACITY).
C               KIND 1 = NODE, 2 = LINK.  OK=.FALSE. IF REJECTED.
C
      SUBROUTINE CHKID(S, KIND, OK)
      IMPLICIT NONE
      INCLUDE 'hydro.inc'
      CHARACTER*(*) S
      INTEGER KIND, I
      LOGICAL OK
      OK = .FALSE.
      IF (LEN_TRIM(S) .GT. 8) THEN
         CALL PERR(106, 'ID TOO LONG ', S)
         RETURN
      ENDIF
      IF (KIND .EQ. 1) THEN
         DO 10 I = 1, NN
            IF (NID(I) .EQ. S) THEN
               CALL PERR(102, 'DUPLICATE ID ', S)
               RETURN
            ENDIF
   10    CONTINUE
         IF (NN .GE. MXN) THEN
            CALL PERR(111, 'TOO MANY NODES', ' ')
            RETURN
         ENDIF
      ELSE
         DO 20 I = 1, NL
            IF (LID(I) .EQ. S) THEN
               CALL PERR(102, 'DUPLICATE ID ', S)
               RETURN
            ENDIF
   20    CONTINUE
         IF (NL .GE. MXL) THEN
            CALL PERR(111, 'TOO MANY LINKS', ' ')
            RETURN
         ENDIF
      ENDIF
      OK = .TRUE.
      RETURN
      END
C
C     JUNCRD  -  JUNCTION ID ELEVATION [DEMAND [PATTERN]]
C
      SUBROUTINE JUNCRD
      IMPLICIT NONE
      INCLUDE 'hydro.inc'
      LOGICAL OK
      DOUBLE PRECISION Z, Q
      IF (NFLD .LT. 3) THEN
         CALL PERR(105, 'MISSING FIELD(S)', ' ')
         RETURN
      ENDIF
      CALL CHKID(FIELD(2), 1, OK)
      IF (.NOT. OK) RETURN
      IF (NFLD .GE. 5) THEN
         IF (LEN_TRIM(FIELD(5)) .GT. 8) THEN
            CALL PERR(106, 'ID TOO LONG ', FIELD(5))
            RETURN
         ENDIF
      ENDIF
      CALL GETNUM(FIELD(3), Z, OK)
      IF (.NOT. OK) RETURN
      Q = 0.0D0
      IF (NFLD .GE. 4) THEN
         CALL GETNUM(FIELD(4), Q, OK)
         IF (.NOT. OK) RETURN
      ENDIF
      NN = NN + 1
      NID(NN) = FIELD(2)
      NTYP(NN) = 1
      NLINE(NN) = LINE
      ZIN(NN) = Z
      QB(NN) = Q
      NPNAM(NN) = ' '
      IF (NFLD .GE. 5) NPNAM(NN) = FIELD(5)
      IF (NFLD .GT. 5) CALL PWARN(209, 'EXTRA FIELDS IGNORED')
      RETURN
      END
C
C     RESCRD  -  RESERVOIR ID HEAD
C
      SUBROUTINE RESCRD
      IMPLICIT NONE
      INCLUDE 'hydro.inc'
      LOGICAL OK
      DOUBLE PRECISION Z
      IF (NFLD .LT. 3) THEN
         CALL PERR(105, 'MISSING FIELD(S)', ' ')
         RETURN
      ENDIF
      CALL CHKID(FIELD(2), 1, OK)
      IF (.NOT. OK) RETURN
      CALL GETNUM(FIELD(3), Z, OK)
      IF (.NOT. OK) RETURN
      NN = NN + 1
      NID(NN) = FIELD(2)
      NTYP(NN) = 2
      NLINE(NN) = LINE
      ZIN(NN) = Z
      QB(NN) = 0.0D0
      NPNAM(NN) = ' '
      IF (NFLD .GT. 3) CALL PWARN(209, 'EXTRA FIELDS IGNORED')
      RETURN
      END
C
C     NEWLNK  -  COMMON PART OF THE LINK CARDS.  RETURNS THE NEW LINK
C                INDEX IN L, OR 0 IF THE ID OR END NODES ARE REJECTED.
C
      SUBROUTINE NEWLNK(L, ITYPE)
      IMPLICIT NONE
      INCLUDE 'hydro.inc'
      INTEGER L, ITYPE
      LOGICAL OK
      L = 0
      CALL CHKID(FIELD(2), 2, OK)
      IF (.NOT. OK) RETURN
      IF (LEN_TRIM(FIELD(3)) .GT. 8) THEN
         CALL PERR(106, 'ID TOO LONG ', FIELD(3))
         RETURN
      ENDIF
      IF (LEN_TRIM(FIELD(4)) .GT. 8) THEN
         CALL PERR(106, 'ID TOO LONG ', FIELD(4))
         RETURN
      ENDIF
      IF (FIELD(3) .EQ. FIELD(4)) THEN
         CALL PERR(110, 'LINK CONNECTS NODE TO ITSELF', ' ')
         RETURN
      ENDIF
      L = NL + 1
      LID(L) = FIELD(2)
      LTYP(L) = ITYPE
      LLINE(L) = LINE
      LFROM(L) = FIELD(3)
      LTO(L) = FIELD(4)
      XL(L) = 0.0D0
      DI(L) = 0.0D0
      RG(L) = 0.0D0
      XK(L) = 0.0D0
      PH(L) = 0.0D0
      PQ(L) = 0.0D0
      LCLOSE(L) = 0
      RETURN
      END
C
C     PIPCRD  -  PIPE ID FROM TO LENGTH DIAMETER ROUGHNESS [K]
C
      SUBROUTINE PIPCRD
      IMPLICIT NONE
      INCLUDE 'hydro.inc'
      INTEGER L
      LOGICAL OK
      DOUBLE PRECISION A, B, C, D
      IF (NFLD .LT. 7) THEN
         CALL PERR(105, 'MISSING FIELD(S)', ' ')
         RETURN
      ENDIF
      CALL NEWLNK(L, 1)
      IF (L .EQ. 0) RETURN
      CALL GETNUM(FIELD(5), A, OK)
      IF (.NOT. OK) RETURN
      CALL GETNUM(FIELD(6), B, OK)
      IF (.NOT. OK) RETURN
      CALL GETNUM(FIELD(7), C, OK)
      IF (.NOT. OK) RETURN
      D = 0.0D0
      IF (NFLD .GE. 8) THEN
         CALL GETNUM(FIELD(8), D, OK)
         IF (.NOT. OK) RETURN
      ENDIF
      IF (A .LE. 0.0D0 .OR. B .LE. 0.0D0 .OR. C .LT. 0.0D0 .OR.
     &    D .LT. 0.0D0) THEN
         CALL PERR(107, 'VALUE OUT OF RANGE', ' ')
         RETURN
      ENDIF
      XL(L) = A
      DI(L) = B
      RG(L) = C
      XK(L) = D
      NL = L
      IF (NFLD .GT. 8) CALL PWARN(209, 'EXTRA FIELDS IGNORED')
      RETURN
      END
C
C     PMPCRD  -  PUMP ID FROM TO HEAD [QMAX]
C
      SUBROUTINE PMPCRD
      IMPLICIT NONE
      INCLUDE 'hydro.inc'
      INTEGER L
      LOGICAL OK
      DOUBLE PRECISION A, B
      IF (NFLD .LT. 5) THEN
         CALL PERR(105, 'MISSING FIELD(S)', ' ')
         RETURN
      ENDIF
      CALL NEWLNK(L, 2)
      IF (L .EQ. 0) RETURN
      CALL GETNUM(FIELD(5), A, OK)
      IF (.NOT. OK) RETURN
      B = 0.0D0
      IF (NFLD .GE. 6) THEN
         CALL GETNUM(FIELD(6), B, OK)
         IF (.NOT. OK) RETURN
      ENDIF
      IF (A .LE. 0.0D0 .OR. (NFLD .GE. 6 .AND. B .LE. 0.0D0)) THEN
         CALL PERR(107, 'VALUE OUT OF RANGE', ' ')
         RETURN
      ENDIF
      PH(L) = A
      PQ(L) = B
      NL = L
      IF (NFLD .GT. 6) CALL PWARN(209, 'EXTRA FIELDS IGNORED')
      RETURN
      END
C
C     VLVCRD  -  VALVE ID FROM TO DIAMETER K [OPEN | CLOSED]
C
      SUBROUTINE VLVCRD
      IMPLICIT NONE
      INCLUDE 'hydro.inc'
      INTEGER L, ICL
      LOGICAL OK
      DOUBLE PRECISION A, B
      CHARACTER*40 V
      IF (NFLD .LT. 6) THEN
         CALL PERR(105, 'MISSING FIELD(S)', ' ')
         RETURN
      ENDIF
      CALL NEWLNK(L, 3)
      IF (L .EQ. 0) RETURN
      CALL GETNUM(FIELD(5), A, OK)
      IF (.NOT. OK) RETURN
      CALL GETNUM(FIELD(6), B, OK)
      IF (.NOT. OK) RETURN
      ICL = 0
      IF (NFLD .GE. 7) THEN
         V = FIELD(7)
         CALL UPCASE(V)
         IF (V .EQ. 'CLOSED') THEN
            ICL = 1
         ELSE IF (V .NE. 'OPEN') THEN
            CALL PERR(108, 'INVALID OPTION VALUE ', FIELD(7))
            RETURN
         ENDIF
      ENDIF
      IF (A .LE. 0.0D0 .OR. B .LT. 0.0D0) THEN
         CALL PERR(107, 'VALUE OUT OF RANGE', ' ')
         RETURN
      ENDIF
      DI(L) = A
      XK(L) = B
      LCLOSE(L) = ICL
      NL = L
      IF (NFLD .GT. 7) CALL PWARN(209, 'EXTRA FIELDS IGNORED')
      RETURN
      END
C
C     PATCRD  -  PATTERN ID M1 [M2 ...]
C
      SUBROUTINE PATCRD
      IMPLICIT NONE
      INCLUDE 'hydro.inc'
      INTEGER I, K, N
      LOGICAL OK
      DOUBLE PRECISION X, T(MXF)
      IF (NFLD .LT. 3) THEN
         CALL PERR(105, 'MISSING FIELD(S)', ' ')
         RETURN
      ENDIF
      IF (LEN_TRIM(FIELD(2)) .GT. 8) THEN
         CALL PERR(106, 'ID TOO LONG ', FIELD(2))
         RETURN
      ENDIF
      K = 0
      DO 10 I = 1, NP
         IF (PNAM(I) .EQ. FIELD(2)) K = I
   10 CONTINUE
      IF (K .EQ. 0) THEN
         IF (NP .GE. MXP) THEN
            CALL PERR(111, 'TOO MANY PATTERNS', ' ')
            RETURN
         ENDIF
         N = 0
      ELSE
         N = PLEN(K)
      ENDIF
      IF (N + NFLD - 2 .GT. MXV) THEN
         CALL PERR(113, 'PATTERN TOO LONG', ' ')
         RETURN
      ENDIF
      DO 20 I = 3, NFLD
         CALL GETNUM(FIELD(I), X, OK)
         IF (.NOT. OK) RETURN
         IF (X .LT. 0.0D0) THEN
            CALL PERR(107, 'VALUE OUT OF RANGE', ' ')
            RETURN
         ENDIF
         T(I) = X
   20 CONTINUE
      IF (K .EQ. 0) THEN
         NP = NP + 1
         K = NP
         PNAM(K) = FIELD(2)
         PLEN(K) = 0
      ENDIF
      DO 30 I = 3, NFLD
         PLEN(K) = PLEN(K) + 1
         PVAL(PLEN(K),K) = T(I)
   30 CONTINUE
      RETURN
      END
EOF
docker exec sn-fortran-solver-parity wc -l /w/new/cards.f
```

<details><summary>output</summary>

```
644 /w/new/cards.f
```
</details>

### Step 86: Bash

```bash
cd /tmp; docker exec -i sn-fortran-solver-parity bash -c 'cat > /w/new/check.f' <<'EOF'
C=======================================================================
C     HYDRO 2.3  -  POST-INPUT CHECKS AND SET-UP
C=======================================================================
C
C     NODIDX  -  INDEX OF A NODE BY ID (0 IF NOT FOUND)
C
      INTEGER FUNCTION NODIDX(S)
      IMPLICIT NONE
      INCLUDE 'hydro.inc'
      CHARACTER*(*) S
      INTEGER I
      NODIDX = 0
      DO 10 I = 1, NN
         IF (NID(I) .EQ. S) THEN
            NODIDX = I
            RETURN
         ENDIF
   10 CONTINUE
      RETURN
      END
C
C     DATCHK  -  CHECKS MADE AFTER THE WHOLE DECK HAS BEEN READ
C
      SUBROUTINE DATCHK
      IMPLICIT NONE
      INCLUDE 'hydro.inc'
      INTEGER I, J, L, K, NODIDX, NRES
C
      IF (IEND .EQ. 0) THEN
         NWARN = NWARN + 1
         WRITE (6,1000)
      ENDIF
      DO 20 L = 1, NL
         LINE = LLINE(L)
         I = NODIDX(LFROM(L))
         IF (I .EQ. 0) THEN
            CALL PERR(103, 'UNDEFINED NODE ', LFROM(L))
         ENDIF
         J = NODIDX(LTO(L))
         IF (J .EQ. 0) THEN
            CALL PERR(103, 'UNDEFINED NODE ', LTO(L))
         ENDIF
         LI(L) = I
         LJ(L) = J
   20 CONTINUE
      DO 30 I = 1, NN
         NPAT(I) = 0
         IF (NPNAM(I) .NE. ' ') THEN
            K = 0
            DO 25 J = 1, NP
               IF (PNAM(J) .EQ. NPNAM(I)) K = J
   25       CONTINUE
            IF (K .EQ. 0) THEN
               LINE = NLINE(I)
               CALL PERR(112, 'UNDEFINED PATTERN ', NPNAM(I))
            ELSE
               NPAT(I) = K
            ENDIF
         ENDIF
   30 CONTINUE
      IF (IFRIC .EQ. 2) THEN
         DO 40 L = 1, NL
            IF (LTYP(L) .EQ. 1 .AND. RG(L) .LE. 0.0D0) THEN
               LINE = LLINE(L)
               CALL PERR(107, 'VALUE OUT OF RANGE', ' ')
            ENDIF
   40    CONTINUE
      ENDIF
      NRES = 0
      DO 50 I = 1, NN
         IF (NTYP(I) .EQ. 2) NRES = NRES + 1
   50 CONTINUE
      IF (NRES .EQ. 0) THEN
         NERR = NERR + 1
         WRITE (6,1010)
      ENDIF
      IF (NERR .GT. 0) THEN
         WRITE (6,1020) NERR
         STOP 1
      ENDIF
      RETURN
 1000 FORMAT (1X,'*** WARNING W208: END CARD MISSING')
 1010 FORMAT (1X,'*** ERROR E302: NO FIXED-HEAD NODE')
 1020 FORMAT (1X,'*** RUN ABORTED: ',I3,' INPUT ERROR(S)')
      END
C
C     SETUP  -  CONVERT TO INTERNAL (SI) UNITS AND ORDER THE NODES
C
      SUBROUTINE SETUP
      IMPLICIT NONE
      INCLUDE 'hydro.inc'
      INTEGER I, J, L, K
      DOUBLE PRECISION FL, FD, FR1, FQ
C
      IF (IUNIT .EQ. 1) THEN
         FL = 1.0D0
         FD = 1.0D-3
         FR1 = 1.0D-3
         FQ = 1.0D-3
      ELSE
         FL = 0.3048D0
         FD = 0.0254D0
         FR1 = 1.0D-3*0.3048D0
         FQ = 3.785411784D-3/60.0D0
      ENDIF
      DO 10 I = 1, NN
         ZN(I) = ZIN(I)*FL
         QB(I) = QB(I)*FQ
   10 CONTINUE
      DO 20 L = 1, NL
         IF (LTYP(L) .EQ. 1) THEN
            XL(L) = XL(L)*FL
            DI(L) = DI(L)*FD
            IF (IFRIC .EQ. 1) RG(L) = RG(L)*FR1
         ELSE IF (LTYP(L) .EQ. 2) THEN
            PH(L) = PH(L)*FL
            PQ(L) = PQ(L)*FQ
         ELSE
            DI(L) = DI(L)*FD
         ENDIF
   20 CONTINUE
C     REPORT ORDER OF THE NODES
      DO 30 I = 1, NN
         NSORT(I) = I
   30 CONTINUE
      DO 50 I = 2, NN
         K = NSORT(I)
         J = I - 1
   40    IF (J .GE. 1) THEN
            IF (NID(NSORT(J)) .GT. NID(K)) THEN
               NSORT(J+1) = NSORT(J)
               J = J - 1
               GOTO 40
            ENDIF
         ENDIF
         NSORT(J+1) = K
   50 CONTINUE
      RETURN
      END
EOF
echo ok
```

<details><summary>output</summary>

```
ok
```
</details>

### Step 87: Bash

```bash
cd /tmp; docker exec -i sn-fortran-solver-parity bash -c 'cat > /w/new/frict.f' <<'EOF'
C=======================================================================
C     HYDRO 2.3  -  DARCY-WEISBACH FRICTION FACTOR
C=======================================================================
C
C     FRFAC  -  FRICTION FACTOR FOR REYNOLDS NUMBER RE AND RELATIVE
C               ROUGHNESS EPS.  LAMINAR BELOW RE = 2000, SWAMEE-JAIN
C               ABOVE RE = 4000, LINEAR BLEND BETWEEN THE TWO.
C
      DOUBLE PRECISION FUNCTION FRFAC(RE, EPS)
      IMPLICIT NONE
      DOUBLE PRECISION RE, EPS, F2, F4
      IF (RE .LT. 2000.0D0) THEN
         IF (RE .LT. 1.0D-6) THEN
            FRFAC = 0.0D0
         ELSE
            FRFAC = 64.0D0/RE
         ENDIF
         RETURN
      ENDIF
      IF (RE .GE. 4000.0D0) THEN
         FRFAC = 0.25D0/LOG10(EPS/3.7D0 + 5.74D0/RE**0.9D0)**2
         RETURN
      ENDIF
      F2 = 64.0D0/2000.0D0
      F4 = 0.25D0/LOG10(EPS/3.7D0 + 5.74D0/4000.0D0**0.9D0)**2
      FRFAC = F2 + (F4 - F2)*(RE - 2000.0D0)/2000.0D0
      RETURN
      END
EOF
docker exec -i sn-fortran-solver-parity bash -c 'cat > /w/new/solve.f' <<'EOF'
C=======================================================================
C     HYDRO 2.3  -  GRADIENT (NODAL HEAD) SOLVER
C=======================================================================
C
C     CONNECT  -  FIND JUNCTIONS WITH NO OPEN PATH TO A RESERVOIR AND
C                 SET THE ACTIVE FLAG OF EVERY LINK
C
      SUBROUTINE CONNECT
      IMPLICIT NONE
      INCLUDE 'hydro.inc'
      INTEGER I, L, MORE
      DO 10 I = 1, NN
         NISO(I) = 1
         IF (NTYP(I) .EQ. 2) NISO(I) = 0
   10 CONTINUE
   20 MORE = 0
      DO 30 L = 1, NL
         IF (LCLOSE(L) .EQ. 0) THEN
            IF (NISO(LI(L)) .EQ. 0 .AND. NISO(LJ(L)) .EQ. 1) THEN
               NISO(LJ(L)) = 0
               MORE = 1
            ELSE IF (NISO(LJ(L)) .EQ. 0 .AND. NISO(LI(L)) .EQ. 1) THEN
               NISO(LI(L)) = 0
               MORE = 1
            ENDIF
         ENDIF
   30 CONTINUE
      IF (MORE .EQ. 1) GOTO 20
      DO 40 L = 1, NL
         LACT(L) = 1
         IF (LCLOSE(L) .EQ. 1) LACT(L) = 0
         IF (NISO(LI(L)) .EQ. 1 .OR. NISO(LJ(L)) .EQ. 1) LACT(L) = 0
   40 CONTINUE
      RETURN
      END
C
C     START  -  INITIAL FLOWS (ABOUT 0.3048 M/S IN PIPES AND VALVES)
C
      SUBROUTINE START
      IMPLICIT NONE
      INCLUDE 'hydro.inc'
      INTEGER L
      DO 10 L = 1, NL
         IF (LTYP(L) .EQ. 2) THEN
            QL(L) = 0.03D0
         ELSE
            QL(L) = 0.3048D0*PI*DI(L)**2/4.0D0
         ENDIF
         IF (LACT(L) .EQ. 0) QL(L) = 0.0D0
   10 CONTINUE
      DO 20 L = 1, NN
         HN(L) = ZN(L)
   20 CONTINUE
      RETURN
      END
C
C     SETDEM  -  DEMANDS FOR TIME STEP ISTEP
C
      SUBROUTINE SETDEM(ISTEP)
      IMPLICIT NONE
      INCLUDE 'hydro.inc'
      INTEGER ISTEP, I, K
      DO 10 I = 1, NN
         QD(I) = QB(I)
         IF (NPAT(I) .GT. 0) THEN
            K = NPAT(I)
            QD(I) = QB(I)*PVAL(MOD(ISTEP-1, PLEN(K)) + 1, K)
         ENDIF
   10 CONTINUE
      RETURN
      END
C
C     GGA  -  ITERATE UNTIL THE RELATIVE FLOW CHANGE IS BELOW TOL
C
      SUBROUTINE GGA
      IMPLICIT NONE
      INCLUDE 'hydro.inc'
      DOUBLE PRECISION AM(MXN,MXN), RHS(MXN), HX(MXN)
      DOUBLE PRECISION P(MXL), Y(MXL)
      INTEGER IX(MXN)
      INTEGER I, J, L, N1, N2, K1, K2, NEQ, IT
      DOUBLE PRECISION H, GR, QNEW, DQ, SDQ, SQ
C
      NEQ = 0
      DO 10 I = 1, NN
         IX(I) = 0
         IF (NTYP(I) .EQ. 1 .AND. NISO(I) .EQ. 0) THEN
            NEQ = NEQ + 1
            IX(I) = NEQ
         ENDIF
         IF (NTYP(I) .EQ. 2) HN(I) = ZN(I)
   10 CONTINUE
C
      CONVRG = .FALSE.
      NITER = 0
      DO 100 IT = 1, MAXIT
         NITER = IT
         DO 15 J = 1, NEQ
            RHS(J) = 0.0D0
            DO 12 I = 1, NEQ
               AM(I,J) = 0.0D0
   12       CONTINUE
   15    CONTINUE
         DO 20 I = 1, NN
            IF (IX(I) .GT. 0) RHS(IX(I)) = -QD(I)
   20    CONTINUE
C
         DO 30 L = 1, NL
            IF (LACT(L) .EQ. 1) THEN
               CALL HLGRAD(L, QL(L), H, GR)
               P(L) = 1.0D0/GR
               Y(L) = P(L)*H
               N1 = LI(L)
               N2 = LJ(L)
               K1 = IX(N1)
               K2 = IX(N2)
               IF (K1 .GT. 0) THEN
                  AM(K1,K1) = AM(K1,K1) + P(L)
                  RHS(K1) = RHS(K1) - (QL(L) - Y(L))
                  IF (K2 .GT. 0) THEN
                     AM(K1,K2) = AM(K1,K2) - P(L)
                  ELSE
                     RHS(K1) = RHS(K1) + P(L)*HN(N2)
                  ENDIF
               ENDIF
               IF (K2 .GT. 0) THEN
                  AM(K2,K2) = AM(K2,K2) + P(L)
                  RHS(K2) = RHS(K2) + (QL(L) - Y(L))
                  IF (K1 .GT. 0) THEN
                     AM(K2,K1) = AM(K2,K1) - P(L)
                  ELSE
                     RHS(K2) = RHS(K2) + P(L)*HN(N1)
                  ENDIF
               ENDIF
            ENDIF
   30    CONTINUE
C
         IF (NEQ .GT. 0) THEN
            CALL LINSOL(AM, RHS, HX, NEQ, MXN)
            DO 40 I = 1, NN
               IF (IX(I) .GT. 0) HN(I) = HX(IX(I))
   40       CONTINUE
         ENDIF
C
         SDQ = 0.0D0
         SQ = 0.0D0
         DO 50 L = 1, NL
            IF (LACT(L) .EQ. 1) THEN
               N1 = LI(L)
               N2 = LJ(L)
               QNEW = QL(L) - Y(L) + P(L)*(HN(N1) - HN(N2))
               DQ = QNEW - QL(L)
               SDQ = SDQ + ABS(DQ)
               SQ = SQ + ABS(QNEW)
               QL(L) = QNEW
            ENDIF
   50    CONTINUE
         IF (SQ .GT. 1.0D-30) THEN
            DQ = SDQ/SQ
         ELSE
            DQ = SDQ
         ENDIF
         IF (DQ .LT. TOL) THEN
            CONVRG = .TRUE.
            RETURN
         ENDIF
  100 CONTINUE
      RETURN
      END
C
C     HLGRAD  -  HEAD LOSS AND ITS FLOW DERIVATIVE FOR LINK L
C
      SUBROUTINE HLGRAD(L, Q, H, GR)
      IMPLICIT NONE
      INCLUDE 'hydro.inc'
      INTEGER L
      DOUBLE PRECISION Q, H, GR, A, V, RE, R, F, S, RK, HR
      DOUBLE PRECISION FRFAC
C
      IF (LTYP(L) .EQ. 2) THEN
         IF (PQ(L) .GT. 0.0D0) THEN
            S = Q/PQ(L)
            H = -PH(L)*(1.0D0 - S*ABS(S))
            GR = 2.0D0*PH(L)*ABS(Q)/(PQ(L)*PQ(L))
         ELSE
            H = -PH(L)
            GR = 0.0D0
         ENDIF
      ELSE IF (LTYP(L) .EQ. 3) THEN
         A = PI*DI(L)**2/4.0D0
         R = XK(L)/(2.0D0*GRAV*A*A)
         H = R*Q*ABS(Q)
         GR = 2.0D0*R*ABS(Q)
      ELSE
         A = PI*DI(L)**2/4.0D0
         RK = XK(L)/(2.0D0*GRAV*A*A)
         IF (IFRIC .EQ. 1) THEN
            V = Q/A
            RE = ABS(V)*DI(L)/VISC
            F = FRFAC(RE, RG(L)/DI(L))
            R = F*XL(L)/(DI(L)*2.0D0*GRAV*A*A) + RK
            H = R*Q*ABS(Q)
            IF (RE .LT. 2000.0D0) THEN
               GR = F*XL(L)/(DI(L)*2.0D0*GRAV*A*A)*ABS(Q)
               GR = GR + 2.0D0*RK*ABS(Q)
            ELSE
               GR = 2.0D0*R*ABS(Q)
            ENDIF
         ELSE
            HR = 10.667D0*XL(L)/(RG(L)**1.852D0*DI(L)**4.871D0)
            H = HR*ABS(Q)**1.852D0*SIGN(1.0D0,Q) + RK*Q*ABS(Q)
            GR = 1.852D0*HR*ABS(Q)**0.852D0 + 2.0D0*RK*ABS(Q)
         ENDIF
      ENDIF
      IF (GR .LT. GMIN) GR = GMIN
      RETURN
      END
C
C     LINSOL  -  GAUSSIAN ELIMINATION WITH PARTIAL PIVOTING
C
      SUBROUTINE LINSOL(A, B, X, N, LDA)
      IMPLICIT NONE
      INTEGER N, LDA
      DOUBLE PRECISION A(LDA,*), B(*), X(*)
      INTEGER I, J, K, IP
      DOUBLE PRECISION T, BIG
      DO 50 K = 1, N
         IP = K
         BIG = ABS(A(K,K))
         DO 10 I = K+1, N
            IF (ABS(A(I,K)) .GT. BIG) THEN
               BIG = ABS(A(I,K))
               IP = I
            ENDIF
   10    CONTINUE
         IF (IP .NE. K) THEN
            DO 20 J = K, N
               T = A(K,J)
               A(K,J) = A(IP,J)
               A(IP,J) = T
   20       CONTINUE
            T = B(K)
            B(K) = B(IP)
            B(IP) = T
         ENDIF
         DO 40 I = K+1, N
            T = A(I,K)/A(K,K)
            DO 30 J = K+1, N
               A(I,J) = A(I,J) - T*A(K,J)
   30       CONTINUE
            B(I) = B(I) - T*B(K)
   40    CONTINUE
   50 CONTINUE
      DO 70 I = N, 1, -1
         T = B(I)
         DO 60 J = I+1, N
            T = T - A(I,J)*X(J)
   60    CONTINUE
         X(I) = T/A(I,I)
   70 CONTINUE
      RETURN
      END
EOF
echo ok
```

<details><summary>output</summary>

```
ok
```
</details>

### Step 88: Bash

```bash
cd /tmp; docker exec -i sn-fortran-solver-parity bash -c 'cat > /w/new/output.f' <<'EOF'
C=======================================================================
C     HYDRO 2.3  -  REPORT
C=======================================================================
C
C     HEADER  -  RUN SUMMARY
C
      SUBROUTINE HEADER
      IMPLICIT NONE
      INCLUDE 'hydro.inc'
      INTEGER I, NRES
      NRES = 0
      DO 10 I = 1, NN
         IF (NTYP(I) .EQ. 2) NRES = NRES + 1
   10 CONTINUE
      WRITE (6,'(A)') ' '
      IF (TITLE .EQ. ' ') THEN
         WRITE (6,1000) '(NONE)'
      ELSE
         WRITE (6,1000) TITLE(1:LEN_TRIM(TITLE))
      ENDIF
      IF (IUNIT .EQ. 1) THEN
         WRITE (6,1010)
      ELSE
         WRITE (6,1020)
      ENDIF
      IF (IFRIC .EQ. 1) THEN
         WRITE (6,1030) 'DARCY-WEISBACH'
      ELSE
         WRITE (6,1030) 'HAZEN-WILLIAMS'
      ENDIF
      WRITE (6,1040) NN, NRES, NL
      WRITE (6,1050) TOL, MAXIT
      IF (NSTEP .GT. 1) WRITE (6,1060) NSTEP, HSTEP
      DO 20 I = 1, NN
         IF (NTYP(I) .EQ. 1 .AND. NISO(I) .EQ. 1) THEN
            NWARN = NWARN + 1
            WRITE (6,1070) NID(I)(1:LEN_TRIM(NID(I)))
         ENDIF
   20 CONTINUE
      RETURN
 1000 FORMAT (1X,'TITLE    : ',A)
 1010 FORMAT (1X,'UNITS    : SI (FLOW L/S, LENGTH M, DIAMETER MM)')
 1020 FORMAT (1X,'UNITS    : US (FLOW GPM, LENGTH FT, DIAMETER IN)')
 1030 FORMAT (1X,'FRICTION : ',A)
 1040 FORMAT (1X,'NETWORK  : ',I3,' NODES, ',I3,' RESERVOIRS, ',I3,
     &        ' LINKS')
 1050 FORMAT (1X,'SOLVER   : TOL ',1PE8.1,', MAXIT ',I3)
 1060 FORMAT (1X,'STEPS    : ',I2,' AT ',0PF5.2,' H')
 1070 FORMAT (1X,'*** WARNING W204: NODE ''',A,''' IS ISOLATED')
      END
C
C     REPORT  -  RESULTS OF ONE TIME STEP.  ISTEP IS ITS NUMBER.
C
      SUBROUTINE REPORT(ISTEP)
      IMPLICIT NONE
      INCLUDE 'hydro.inc'
      INTEGER ISTEP, I, II, L, NMIN, N1, N2, W
      DOUBLE PRECISION FQ, FL, FP, A, V, HL, PRS, DEM, TDEM, TSUP
      DOUBLE PRECISION QNET(MXN), HOUT, T
      CHARACTER*8 STAT
      LOGICAL ISOL
C
      IF (IUNIT .EQ. 1) THEN
         FQ = 1.0D-3
         FL = 1.0D0
      ELSE
         FQ = 3.785411784D-3/60.0D0
         FL = 0.3048D0
      ENDIF
      IF (NSTEP .GT. 1) THEN
         T = DBLE(ISTEP-1)*HSTEP*60.0D0
         NMIN = NINT(T)
         WRITE (6,'(A)') ' '
         WRITE (6,1000) ISTEP, NSTEP, NMIN/60, MOD(NMIN,60)
      ELSE
         WRITE (6,'(A)') ' '
      ENDIF
      IF (CONVRG) THEN
         WRITE (6,1010) NITER
      ELSE
         WRITE (6,1020) MAXIT
      ENDIF
C
C     NET OUTFLOW OF EVERY NODE
      DO 10 I = 1, NN
         QNET(I) = 0.0D0
   10 CONTINUE
      DO 20 L = 1, NL
         QNET(LI(L)) = QNET(LI(L)) + QL(L)
         QNET(LJ(L)) = QNET(LJ(L)) - QL(L)
   20 CONTINUE
C
      WRITE (6,'(A)') ' '
      WRITE (6,'(A)') ' NODE RESULTS'
      IF (IUNIT .EQ. 1) THEN
         WRITE (6,1030) 'KPA'
      ELSE
         WRITE (6,1030) 'PSI'
      ENDIF
      WRITE (6,1040)
      TDEM = 0.0D0
      TSUP = 0.0D0
      DO 30 II = 1, NN
         I = NSORT(II)
         IF (NTYP(I) .EQ. 1) THEN
            IF (NISO(I) .EQ. 1) THEN
               WRITE (6,1050) NID(I), 'JUNC', ZIN(I), QD(I)/FQ
            ELSE
               PRS = HN(I) - ZN(I)
               IF (IUNIT .EQ. 1) THEN
                  WRITE (6,1060) NID(I), 'JUNC', ZIN(I), QD(I)/FQ,
     &               HN(I), PRS, PRS*9.79D0
               ELSE
                  WRITE (6,1065) NID(I), 'JUNC', ZIN(I), QD(I)/FQ,
     &               HN(I)/FL, PRS/FL, PRS/FL*0.4335D0
               ENDIF
               TDEM = TDEM + QD(I)
            ENDIF
         ELSE
            IF (IUNIT .EQ. 1) THEN
               WRITE (6,1060) NID(I), 'RESV', ZIN(I), -QNET(I)/FQ,
     &            HN(I), 0.0D0, 0.0D0
            ELSE
               WRITE (6,1065) NID(I), 'RESV', ZIN(I), -QNET(I)/FQ,
     &            HN(I)/FL, 0.0D0, 0.0D0
            ENDIF
            TSUP = TSUP + QNET(I)
         ENDIF
   30 CONTINUE
C
      WRITE (6,'(A)') ' '
      WRITE (6,'(A)') ' LINK RESULTS'
      WRITE (6,1070)
      WRITE (6,1080)
      DO 40 L = 1, NL
         N1 = LI(L)
         N2 = LJ(L)
         ISOL = (NISO(N1) .EQ. 1 .OR. NISO(N2) .EQ. 1)
         IF (ISOL) THEN
            HL = 0.0D0
         ELSE
            HL = ABS(HN(N1) - HN(N2))/FL
         ENDIF
         IF (LTYP(L) .EQ. 2) THEN
            STAT = 'ON'
            IF (ISOL) STAT = 'ISOLATED'
            WRITE (6,1090) LID(L), 'PUMP', NID(N1), NID(N2),
     &         QL(L)/FQ, HL, STAT
         ELSE
            A = PI*DI(L)**2/4.0D0
            V = QL(L)/A/FL
            IF (LTYP(L) .EQ. 3) THEN
               STAT = 'OPEN'
               IF (ISOL) STAT = 'ISOLATED'
               IF (LCLOSE(L) .EQ. 1) STAT = 'CLOSED'
               WRITE (6,1100) LID(L), 'VALVE', NID(N1), NID(N2),
     &            QL(L)/FQ, V, HL, STAT
            ELSE
               STAT = 'OPEN'
               IF (ISOL) STAT = 'ISOLATED'
               IF (IFRIC .EQ. 2) THEN
                  WRITE (6,1100) LID(L), 'PIPE', NID(N1), NID(N2),
     &               QL(L)/FQ, V, HL, STAT
               ELSE IF (ABS(QL(L)) .LT. QZERO) THEN
                  WRITE (6,1110) LID(L), 'PIPE', NID(N1), NID(N2),
     &               QL(L)/FQ, V, HL, STAT
               ELSE
                  WRITE (6,1120) LID(L), 'PIPE', NID(N1), NID(N2),
     &               QL(L)/FQ, V, HL, FR(L), STAT
               ENDIF
            ENDIF
         ENDIF
   40 CONTINUE
C
      WRITE (6,1130) TDEM/FQ
      WRITE (6,1140) TSUP/FQ
      RETURN
 1000 FORMAT (1X,'TIME STEP ',I2,' OF ',I2,'  AT ',I3,':',I2.2)
 1010 FORMAT (1X,'CONVERGED IN ',I3,' ITERATIONS')
 1020 FORMAT (1X,'*** WARNING W205: NOT CONVERGED AFTER ',I3,
     &        ' ITERATIONS')
 1030 FORMAT (1X,'ID       TYPE       ELEV    DEMAND      HEAD  ',
     &        'PRESSURE       ',A3)
 1040 FORMAT (1X,'-------- ----- --------- --------- --------- ',
     &        '--------- ---------')
 1050 FORMAT (1X,A8,1X,A4,F11.3,F10.2,4X,'ISOLATED')
 1060 FORMAT (1X,A8,1X,A4,F11.3,F10.2,F10.3,F10.3,F10.1)
 1065 FORMAT (1X,A8,1X,A4,F11.3,F10.2,F10.3,F10.3,F10.2)
 1070 FORMAT (1X,'ID       TYPE  FROM     TO            FLOW  ',
     &        'VELOCITY  HEADLOSS  FRICTION  STATUS')
 1080 FORMAT (1X,'-------- ----- -------- -------- --------- ',
     &        '--------- --------- ---------  --------')
 1090 FORMAT (1X,A8,1X,A4,2X,A8,1X,A8,F10.2,10X,F10.3,10X,2X,A8)
 1100 FORMAT (1X,A8,1X,A5,1X,A8,1X,A8,F10.2,F10.3,F10.3,10X,2X,A8)
 1110 FORMAT (1X,A8,1X,A4,2X,A8,1X,A8,F10.2,F10.3,F10.3,'     UNDEF',
     &        2X,A8)
 1120 FORMAT (1X,A8,1X,A4,2X,A8,1X,A8,F10.2,F10.3,F10.3,F10.5,2X,A8)
 1130 FORMAT (/1X,'TOTAL DEMAND :',F10.2)
 1140 FORMAT (1X,'TOTAL SUPPLY :',F10.2)
      END
EOF
echo ok
```

<details><summary>output</summary>

```
ok
```
</details>

### Step 89: Bash

```bash
cd /tmp; cat > /tmp/ed2.py <<'PYEOF'
s=open("/w/new/output.f").read()
s=s.replace("""     &         QL(L)/FQ, HL, STAT
         ELSE""","""     &         QL(L)/FQ, HL, STAT
         ELSE""")
s=s.replace(" 1090 FORMAT (1X,A8,1X,A4,2X,A8,1X,A8,F10.2,10X,F10.3,10X,2X,A8)"," 1090 FORMAT (1X,A8,1X,A5,1X,A8,1X,A8,F10.2,10X,F10.3,10X,2X,A8)")
s=s.replace(" 1100 FORMAT (1X,A8,1X,A5,1X,A8,1X,A8,F10.2,F10.3,F10.3,10X,2X,A8)"," 1100 FORMAT (1X,A8,1X,A5,1X,A8,1X,A8,F10.2,F10.3,F10.3,10X,2X,A8)")
s=s.replace(" 1110 FORMAT (1X,A8,1X,A4,2X,A8,1X,A8,F10.2,F10.3,F10.3,'     UNDEF',"," 1110 FORMAT (1X,A8,1X,A5,1X,A8,1X,A8,F10.2,F10.3,F10.3,'     UNDEF',")
s=s.replace(" 1120 FORMAT (1X,A8,1X,A4,2X,A8,1X,A8,F10.2,F10.3,F10.3,F10.5,2X,A8)"," 1120 FORMAT (1X,A8,1X,A5,1X,A8,1X,A8,F10.2,F10.3,F10.3,F10.5,2X,A8)")
s=s.replace(" 1130 FORMAT (/1X,'TOTAL DEMAND :',F10.2)"," 1130 FORMAT (/1X,'TOTAL DEMAND :',F10.2,1X,A3)")
s=s.replace(" 1140 FORMAT (1X,'TOTAL SUPPLY :',F10.2)"," 1140 FORMAT (1X,'TOTAL SUPPLY :',F10.2,1X,A3)")
s=s.replace("""      WRITE (6,1130) TDEM/FQ
      WRITE (6,1140) TSUP/FQ
""","""      IF (IUNIT .EQ. 1) THEN
         WRITE (6,1130) TDEM/FQ, 'L/S'
         WRITE (6,1140) TSUP/FQ, 'L/S'
      ELSE
         WRITE (6,1130) TDEM/FQ, 'GPM'
         WRITE (6,1140) TSUP/FQ, 'GPM'
      ENDIF
""")
s=s.replace("""      IF (CONVRG) THEN
         WRITE (6,1010) NITER
      ELSE
         WRITE (6,1020) MAXIT
      ENDIF""","""      IF (CONVRG) THEN
         WRITE (6,1010) NITER
      ELSE
         NWARN = NWARN + 1
         NCONV = 1
         WRITE (6,1020) MAXIT
      ENDIF""")
s+="""C
C     FINAL  -  FRICTION FACTORS AT THE FINAL FLOWS
C
      SUBROUTINE FINAL
      IMPLICIT NONE
      INCLUDE 'hydro.inc'
      INTEGER L
      DOUBLE PRECISION A, V, RE, FRFAC
      DO 10 L = 1, NL
         FR(L) = 0.0D0
         IF (LTYP(L) .EQ. 1 .AND. IFRIC .EQ. 1) THEN
            A = PI*DI(L)**2/4.0D0
            V = QL(L)/A
            RE = ABS(V)*DI(L)/VISC
            FR(L) = FRFAC(RE, RG(L)/DI(L))
         ENDIF
   10 CONTINUE
      RETURN
      END
C
C     WARNS  -  HYDRAULIC WARNINGS FOR THE CURRENT TIME STEP
C
      SUBROUTINE WARNS
      IMPLICIT NONE
      INCLUDE 'hydro.inc'
      INTEGER I, II, L
      DOUBLE PRECISION A, V
      DO 10 II = 1, NN
         I = NSORT(II)
         IF (NTYP(I) .EQ. 1 .AND. NISO(I) .EQ. 0) THEN
            IF (HN(I) - ZN(I) .LT. 0.0D0) THEN
               NWARN = NWARN + 1
               WRITE (6,1000) NID(I)(1:LEN_TRIM(NID(I)))
            ENDIF
         ENDIF
   10 CONTINUE
      DO 20 L = 1, NL
         IF (LACT(L) .EQ. 1) THEN
            IF (ABS(QL(L)) .LT. QZERO) THEN
               NWARN = NWARN + 1
               WRITE (6,1010) LID(L)(1:LEN_TRIM(LID(L)))
            ELSE IF (LTYP(L) .EQ. 2) THEN
               IF (QL(L) .LT. 0.0D0) THEN
                  NWARN = NWARN + 1
                  WRITE (6,1020) LID(L)(1:LEN_TRIM(LID(L)))
               ELSE IF (PQ(L) .GT. 0.0D0 .AND. QL(L) .GT. PQ(L)) THEN
                  NWARN = NWARN + 1
                  WRITE (6,1030) LID(L)(1:LEN_TRIM(LID(L)))
               ENDIF
            ELSE
               A = PI*DI(L)**2/4.0D0
               V = QL(L)/A
               IF (ABS(V) .GT. 3.0D0) THEN
                  NWARN = NWARN + 1
                  WRITE (6,1040) LID(L)(1:LEN_TRIM(LID(L)))
               ENDIF
            ENDIF
         ENDIF
   20 CONTINUE
      RETURN
 1000 FORMAT (1X,'*** WARNING W201: NEGATIVE PRESSURE AT NODE ''',A,
     &        '''')
 1010 FORMAT (1X,'*** WARNING W203: ZERO FLOW IN LINK ''',A,'''')
 1020 FORMAT (1X,'*** WARNING W210: PUMP ''',A,''' REVERSE FLOW')
 1030 FORMAT (1X,'*** WARNING W207: PUMP ''',A,''' FLOW EXCEEDS QMAX')
 1040 FORMAT (1X,'*** WARNING W202: HIGH VELOCITY IN LINK ''',A,'''')
      END
"""
open("/w/new/output.f","w").write(s)
PYEOF
docker exec -i sn-fortran-solver-parity python3 - < /tmp/ed2.py && echo ok
docker exec -i sn-fortran-solver-parity bash -c 'cat > /w/new/main.f' <<'EOF'
C=======================================================================
C     H Y D R O    VERSION 2.3
C
C     STEADY-STATE HYDRAULIC ANALYSIS OF PIPE NETWORKS.
C
C     COPYRIGHT (C) THE HYDRO AUTHORS.  RELEASED UNDER THE MIT LICENSE.
C=======================================================================
      PROGRAM HYDRO
      IMPLICIT NONE
      INCLUDE 'hydro.inc'
      INTEGER ISTEP
C
      CALL DEFLT
      WRITE (6,1000)
      CALL INPUT
      CALL DATCHK
      CALL SETUP
      CALL CONNECT
      CALL HEADER
      CALL START
      DO 10 ISTEP = 1, NSTEP
         CALL SETDEM(ISTEP)
         CALL GGA
         CALL FINAL
         CALL REPORT(ISTEP)
         CALL WARNS
   10 CONTINUE
      WRITE (6,1010) NWARN
      IF (NCONV .NE. 0) STOP 2
      STOP
 1000 FORMAT (1X,'HYDRO 2.3 - STEADY-STATE PIPE NETWORK ANALYSIS'/
     &        1X,'----------------------------------------------')
 1010 FORMAT (/1X,'RUN COMPLETED WITH ',I3,' WARNING(S)')
      END
C
C     DEFLT  -  DEFAULT CONTROL VALUES
C
      SUBROUTINE DEFLT
      IMPLICIT NONE
      INCLUDE 'hydro.inc'
      NN = 0
      NL = 0
      NP = 0
      IUNIT = 1
      IFRIC = 1
      MAXIT = 50
      NSTEP = 1
      NERR = 0
      NWARN = 0
      LINE = 0
      NITER = 0
      IEND = 0
      NCONV = 0
      TOL = 1.0D-5
      HSTEP = 1.0D0
      TITLE = ' '
      CONVRG = .FALSE.
      RETURN
      END
EOF
docker exec sn-fortran-solver-parity bash -c 'cd /w/new && gfortran -O2 -o hydro *.f 2>&1 | head -40; ls'
```

<details><summary>output</summary>

```
ok
cards.f
check.f
frict.f
hydro
hydro.inc
main.f
output.f
solve.f
```
</details>

### Step 90: Bash

```bash
cd /tmp; docker exec -i sn-fortran-solver-parity bash -c 'cat > /w/cmp.py' <<'EOF'
import subprocess,re,sys,glob
PROD="/app/prod/hydro"
MINE="/w/new/hydro"
def run(exe,deck):
    r=subprocess.run([exe],input=deck,capture_output=True,text=True)
    return r.stdout,r.returncode
numre=re.compile(r'^[+-]?(\d+\.\d*|\.\d+)$')
def tokcmp(a,b):
    if a==b: return True
    if numre.match(a) and numre.match(b):
        da=len(a.split(".")[1]); db=len(b.split(".")[1])
        if da!=db: return False
        ia=int(a.replace(".","")) if True else 0
        try:
            ia=round(float(a)*10**da); ib=round(float(b)*10**db)
        except: return False
        return abs(ia-ib)<=1
    return False
def cmp(o1,o2):
    l1=[x.rstrip() for x in o1.split("\n")]; l2=[x.rstrip() for x in o2.split("\n")]
    while l1 and l1[-1]=="": l1.pop()
    while l2 and l2[-1]=="": l2.pop()
    if len(l1)!=len(l2): return "linecount %d vs %d"%(len(l1),len(l2)),None
    for i,(a,b) in enumerate(zip(l1,l2)):
        if len(a)!=len(b):
            return "len line %d"%i,(a,b)
        ta=a.split(); tb=b.split()
        if len(ta)!=len(tb): return "ntok line %d"%i,(a,b)
        for x,y in zip(ta,tb):
            if not tokcmp(x,y): return "tok line %d"%i,(a,b)
    return None,None
def check(deck,verbose=True,label=""):
    o1,r1=run(PROD,deck); o2,r2=run(MINE,deck)
    if r1!=r2:
        if verbose: print("RC DIFF",label,r1,r2)
        return False
    e,info=cmp(o1,o2)
    if e:
        if verbose:
            print("DIFF",label,e)
            if info: print("  P:",info[0]); print("  M:",info[1])
        return False
    return True
if __name__=="__main__":
    ok=0;n=0
    for f in sys.argv[1:]:
        d=open(f).read(); n+=1
        if check(d,label=f): ok+=1
    print(ok,"/",n)
EOF
docker exec sn-fortran-solver-parity bash -lc 'cd /w; python3 cmp.py /app/examples/*.dat'
```

<details><summary>output</summary>

```
3 / 3
```
</details>

### Step 91: Bash

```bash
cd /tmp; docker exec -i sn-fortran-solver-parity bash -c 'cat > /w/probes.py' <<'EOF'
import itertools,sys
from cmp import check
B="RESERVOIR R 100\nJUNCTION a 10 5\n"
L="abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz0123456789abcdefghij"
cards=["RESERVOIR","RESERVOIR X","RESERVOIR X abc","JUNCTION","JUNCTION X","JUNCTION X 1 abc","JUNCTION X 1 -5","JUNCTION X -5 1","RESERVOIR X -5","JUNCTION X 1 1 pp",
"PIPE","PIPE p","PIPE p R a 1 1","PIPE p R a 1 1 0","PIPE p R a 1 1 0 -1","PIPE p R a 1 1 0 x","PIPE p R a x 1 0","PUMP","PUMP u R a","PUMP u R a x","PUMP u R a 0","PUMP u R a 5 0","PUMP u R a 5 -1","PUMP u R a 5 x",
"VALVE","VALVE v R a 100","VALVE v R a 100 0","VALVE v R a 100 -1","VALVE v R a 0 1","VALVE v R a 100 1 FOO","VALVE v R a 100 1 closed","VALVE v R a 100 1 open extra","PATTERN","PATTERN pp","PATTERN pp x","PATTERN pp -1","PATTERN pp 0","PATTERN pp 1 2 x",
"UNITS","UNITS si","UNITS Us","UNITS SI X","TITLE","OPTION","OPTION TOL","OPTION STEPS 0","OPTION STEPS 24","OPTION STEPS 25","OPTION TOL 1e-3","OPTION TOL 0","OPTION TOL -1","OPTION MAXIT 3","OPTION MAXIT 0","OPTION MAXIT 2.5","OPTION MAXIT 1000","OPTION FRICTION HW","OPTION FRICTION hw","OPTION FRICTION XX",
"OPTION STEPS 3","OPTION STEPS 1.5","OPTION HSTEP 0.5","OPTION HSTEP 0","OPTION HSTEP 25","OPTION METHOD HC","OPTION TOL abc","OPTION TOL 1 2","OPTION TOL 1d-3","OPTION TOL .5",
"PIPE p R zz 1 1 0","PIPE p zz zz 1 1 0","PIPE p R R x 1 0","PIPE a R a 100 100 0.1","JUNCTION p 1 1\nPIPE p R a 100 100 0.1","JUNCTION a 1 x",
"JUNCTION 1234567890 1 1","JUNCTION A 1 1\nPIPE p R A 100 100 0.1","PATTERN pp 1\nPATTERN PP 1","PATTERN pp 1\nPATTERN pp 2\nJUNCTION b 1 1 pp","JUNCTION b 1 1 PP\nPATTERN pp 1",
"TITLE   Hello   World  ","title Hello ! comment here","TITLE ! only comment","TITLE x\nTITLE y","TITLE x\nTITLE","TITLE "+"0123456789"*9,"TITLE   a\tb","   TITLE indented","* comment\nTITLE after star"," * not comment","TITLEX abc","TITLE=abc","END extra",
"PIPE p R a 100 100 0.1 1 2 3 4","PIPE p R a x 1 1 1 1 1 1","PIPE p R a 1 1 1 1 1 1 1","RESERVOIR S x 5","RESERVOIR a 5 5","JUNCTION S -1 1 pp 5 6","PUMP u R a 1 1 1","PUMP u R a -1 1 1","VALVE v R a 100 1 open x",
"PIPE q R a 100 100 0.1\nPIPE q R a 100 100 0.1","PUMP u R a 5\nPUMP u2 R a 5 3","UNITS US","UNITS US\nOPTION FRICTION HW","JUNCTION b 1 1\nJUNCTION c 2 2 pp\nPATTERN pp 0.5 1.5\nOPTION STEPS 4",
"PIPE p R a 1 1 1","OPTION FRICTION HW\nPIPE p R a 100 100 100","OPTION FRICTION HW\nPIPE p R a 100 100 0","PIPE p R a 1 1 1\nPIPE p2 R a 1 1 1",
"JUNCTION b x 1 123456789","PIPE p R 123456789 1 1 1","PATTERN pp x\nJUNCTION b 1 1 pp","PATTERN "+"pp 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20","VALVE v R a 100 1 closed\nPIPE p R a 100 100 .1",
L,"OPTION TOL "+L,"JUNCTION b 1 1 "+L, "PIPE p4 R a 100 100 0.1"+" "*52+"0.5 1","PIPE p4 R a 100 100 0.1"+" "*53+"0.5 1"]
bad=0
for c in cards:
    for suf in ["END\n",""]:
        d=B+c+"\n"+suf
        if not check(d,label=repr(c)+" "+repr(suf)): bad+=1
print("bad",bad,"of",2*len(cards))
EOF
docker exec sn-fortran-solver-parity bash -lc 'cd /w; python3 probes.py 2>&1 | head -150'
```

<details><summary>output</summary>

```
DIFF 'JUNCTION X 1 -5' 'END\n' tok line 8
  P:  *** WARNING W204: NODE 'X' IS ISOLATED
  M:  *** WARNING W204: NODE 'a' IS ISOLATED
DIFF 'JUNCTION X 1 -5' '' tok line 9
  P:  *** WARNING W204: NODE 'X' IS ISOLATED
  M:  *** WARNING W204: NODE 'a' IS ISOLATED
DIFF 'JUNCTION X -5 1' 'END\n' tok line 8
  P:  *** WARNING W204: NODE 'X' IS ISOLATED
  M:  *** WARNING W204: NODE 'a' IS ISOLATED
DIFF 'JUNCTION X -5 1' '' tok line 9
  P:  *** WARNING W204: NODE 'X' IS ISOLATED
  M:  *** WARNING W204: NODE 'a' IS ISOLATED
DIFF 'OPTION STEPS 24' 'END\n' len line 11
  P:  TIME STEP  1 OF 24  AT  0:00
  M:  TIME STEP  1 OF 24  AT   0:00
DIFF 'OPTION STEPS 24' '' len line 12
  P:  TIME STEP  1 OF 24  AT  0:00
  M:  TIME STEP  1 OF 24  AT   0:00
DIFF 'OPTION STEPS 3' 'END\n' len line 11
  P:  TIME STEP  1 OF  3  AT  0:00
  M:  TIME STEP  1 OF  3  AT   0:00
DIFF 'OPTION STEPS 3' '' len line 12
  P:  TIME STEP  1 OF  3  AT  0:00
  M:  TIME STEP  1 OF  3  AT   0:00
DIFF 'PUMP u R a 5\nPUMP u2 R a 5 3' 'END\n' tok line 9
  P:  CONVERGED IN  16 ITERATIONS
  M:  CONVERGED IN  21 ITERATIONS
DIFF 'PUMP u R a 5\nPUMP u2 R a 5 3' '' tok line 10
  P:  CONVERGED IN  16 ITERATIONS
  M:  CONVERGED IN  21 ITERATIONS
DIFF 'JUNCTION b 1 1\nJUNCTION c 2 2 pp\nPATTERN pp 0.5 1.5\nOPTION STEPS 4' 'END\n' len line 13
  P:  TIME STEP  1 OF  4  AT  0:00
  M:  TIME STEP  1 OF  4  AT   0:00
DIFF 'JUNCTION b 1 1\nJUNCTION c 2 2 pp\nPATTERN pp 0.5 1.5\nOPTION STEPS 4' '' len line 14
  P:  TIME STEP  1 OF  4  AT  0:00
  M:  TIME STEP  1 OF  4  AT   0:00
bad 12 of 240
```
</details>

### Step 92: Bash

```bash
cd /tmp; cat > /tmp/ed3.py <<'PYEOF'
s=open("/w/new/output.f").read()
s=s.replace("""      DO 20 I = 1, NN
         IF (NTYP(I) .EQ. 1 .AND. NISO(I) .EQ. 1) THEN
            NWARN = NWARN + 1""","""      DO 20 II = 1, NN
         I = NSORT(II)
         IF (NTYP(I) .EQ. 1 .AND. NISO(I) .EQ. 1) THEN
            NWARN = NWARN + 1""")
s=s.replace("      INTEGER I, NRES\n      NRES = 0","      INTEGER I, II, NRES\n      NRES = 0")
s=s.replace("' OF ',I2,'  AT ',I3,':',I2.2)","' OF ',I2,'  AT',I3,':',I2.2)")
open("/w/new/output.f","w").write(s)
PYEOF
docker exec -i sn-fortran-solver-parity python3 - < /tmp/ed3.py
docker exec sn-fortran-solver-parity bash -lc 'cd /w/new && gfortran -O2 -o hydro *.f 2>&1 | head; cd /w; python3 probes.py | tail -5'
```

<details><summary>output</summary>

```
  M:  CONVERGED IN  21 ITERATIONS
DIFF 'PUMP u R a 5\nPUMP u2 R a 5 3' '' tok line 10
  P:  CONVERGED IN  16 ITERATIONS
  M:  CONVERGED IN  21 ITERATIONS
bad 2 of 240
```
</details>

### Step 93: Bash

```bash
cd /tmp; docker exec -i sn-fortran-solver-parity bash -c 'cat > /w/iters.py' <<'EOF'
import sys,re
from cmp import run,PROD,MINE
def iters(exe,deck):
    o,r=run(exe,deck)
    m=re.search(r"CONVERGED IN\s+(\d+)",o)
    if m: return int(m.group(1))
    return "NC" if "W205" in o else "?%d"%r
def sweep(base,tols=("1","1e-1","1e-2","1e-3","1e-4","1e-5","1e-6","1e-8","1e-10","1e-12")):
    p=[];m=[]
    for t in tols:
        d="OPTION TOL %s\n"%t+base
        p.append(iters(PROD,d)); m.append(iters(MINE,d))
    return p,m
if __name__=="__main__":
    cases={
     "constpump":"RESERVOIR R 100\nJUNCTION a 10 5\nJUNCTION b 20 3\nPUMP u R a 30\nPIPE p a b 100 100 0.1\nEND\n",
     "curvepump":"RESERVOIR R 100\nJUNCTION a 10 5\nJUNCTION b 20 3\nPUMP u R a 30 20\nPIPE p a b 100 100 0.1\nEND\n",
     "twopumps":"RESERVOIR R 100\nJUNCTION a 10 5\nPUMP u R a 5\nPUMP u2 R a 5 3\nEND\n",
     "valve":"RESERVOIR R 100\nJUNCTION a 10 5\nJUNCTION b 20 3\nPIPE p R a 100 100 0.1\nVALVE v a b 100 5\nEND\n",
     "minor":"RESERVOIR R 100\nJUNCTION a 10 5\nPIPE p R a 100 100 0.1 5\nEND\n",
     "hw":"OPTION FRICTION HW\nRESERVOIR R 100\nJUNCTION a 10 5\nJUNCTION b 10 5\nPIPE p R a 100 100 120\nPIPE q a b 100 100 120\nPIPE q2 R b 300 100 120\nEND\n",
    }
    for k,v in cases.items():
        p,m=sweep(v); print(k,"\n P",p,"\n M",m)
EOF
docker exec sn-fortran-solver-parity bash -lc 'cd /w; python3 iters.py'
```

<details><summary>output</summary>

```
constpump 
 P [2, 2, 2, 2, 2, 2, 2, 2, 3, 3] 
 M [2, 2, 2, 2, 2, 2, 2, 2, 3, 3]
curvepump 
 P [1, 2, 2, 2, 2, 2, 2, 2, 2, 2] 
 M [2, 2, 2, 2, 2, 2, 2, 2, 2, 2]
twopumps 
 P [2, 3, 6, 10, 13, 16, 20, 27, 31, 31] 
 M [4, 7, 11, 14, 17, 21, 24, 31, 35, 35]
valve 
 P [1, 2, 2, 2, 2, 2, 2, 2, 2, 2] 
 M [1, 2, 2, 2, 2, 2, 2, 2, 2, 2]
minor 
 P [1, 2, 2, 2, 2, 2, 2, 2, 2, 2] 
 M [1, 2, 2, 2, 2, 2, 2, 2, 2, 2]
hw 
 P [1, 3, 3, 4, 4, 4, 4, 5, 5, 5] 
 M [1, 3, 3, 4, 4, 4, 4, 5, 5, 5]
```
</details>

### Step 94: Bash

```bash
cd /tmp; cat > /tmp/var.py <<'PYEOF'
import subprocess,sys,shutil,os,re
sys.path.insert(0,"/w")
from iters import iters
from cmp import PROD
def build(name,repl):
    d="/w/var_"+name
    shutil.rmtree(d,ignore_errors=True); shutil.copytree("/w/new",d)
    s=open(d+"/solve.f").read()
    for a,b in repl:
        assert a in s,a
        s=s.replace(a,b)
    open(d+"/solve.f","w").write(s)
    r=subprocess.run("cd %s && gfortran -O2 -o hydro *.f"%d,shell=True,capture_output=True,text=True)
    if r.returncode: print(r.stderr[:2000])
    return d+"/hydro"
cases={
 "twopumps":"RESERVOIR R 100\nJUNCTION a 10 5\nPUMP u R a 5\nPUMP u2 R a 5 3\nEND\n",
 "curvepump":"RESERVOIR R 100\nJUNCTION a 10 5\nJUNCTION b 20 3\nPUMP u R a 30 20\nPIPE p a b 100 100 0.1\nEND\n",
 "cp2":"RESERVOIR R 100\nJUNCTION a 10 5\nJUNCTION b 20 3\nPUMP u R a 30 8\nPIPE p a b 100 100 0.1\nEND\n",
 "cp3":"RESERVOIR R 100\nRESERVOIR S 90\nJUNCTION a 10 0\nPUMP u R a 10 20\nPIPE p a S 100 100 0.1\nEND\n",
 "cp4":"RESERVOIR R 100\nRESERVOIR S 150\nJUNCTION a 10 0\nPUMP u R a 10 20\nPIPE p a S 100 100 0.1\nEND\n",
}
tols=("1","1e-1","1e-2","1e-3","1e-4","1e-5","1e-6","1e-8","1e-10","1e-12")
def sweep(exe,base):
    return [iters(exe,"OPTION TOL %s\n"%t+base) for t in tols]
if __name__=="__main__":
    print("PROD")
    for k,v in cases.items(): print(k,sweep(PROD,v))
    variants=eval(sys.argv[1])
    for name,repl in variants.items():
        exe=build(name,repl)
        print("VAR",name)
        for k,v in cases.items(): print(k,sweep(exe,v))
PYEOF
docker exec -i sn-fortran-solver-parity bash -c 'cat > /w/var.py' < /tmp/var.py
docker exec sn-fortran-solver-parity bash -lc 'cd /w; python3 var.py "{\"base\":[], \"c0\":[(\"QL(L) = 0.03D0\",\"QL(L) = 0.0D0\")], \"curve_half\":[(\"QL(L) = 0.03D0\",\"QL(L) = 0.03D0\\n         IF (PQ(L).GT.0.0D0) QL(L)=PQ(L)/2.0D0\")]}"'
```

<details><summary>output</summary>

```
PROD
twopumps [2, 3, 6, 10, 13, 16, 20, 27, 31, 31]
curvepump [1, 2, 2, 2, 2, 2, 2, 2, 2, 2]
cp2 [1, 2, 2, 2, 2, 2, 2, 2, 2, 2]
cp3 [1, 4, 5, 5, 6, 6, 7, 8, 9, 10]
cp4 [2, 4, 5, 5, 6, 6, 7, 8, 9, 10]
VAR base
twopumps [4, 7, 11, 14, 17, 21, 24, 31, 35, 35]
curvepump [2, 2, 2, 2, 2, 2, 2, 2, 2, 2]
cp2 [2, 2, 2, 2, 2, 2, 2, 2, 2, 2]
cp3 [1, 3, 4, 4, 5, 5, 6, 7, 8, 9]
cp4 [2, 4, 5, 6, 6, 7, 7, 8, 9, 10]
VAR c0
twopumps [2, 5, 8, 11, 15, 18, 21, 30, 34, 34]
curvepump [1, 2, 2, 2, 2, 2, 2, 3, 3, 3]
cp2 [1, 2, 2, 2, 2, 2, 2, 3, 3, 3]
cp3 [1, 6, 7, 8, 8, 9, 9, 10, 11, 12]
cp4 [2, 7, 8, 8, 9, 9, 10, 11, 11, 12]
VAR curve_half
twopumps [2, 3, 6, 10, 13, 16, 20, 27, 31, 31]
curvepump [1, 2, 2, 2, 2, 2, 2, 2, 2, 2]
cp2 [1, 2, 2, 2, 2, 2, 2, 2, 2, 2]
cp3 [1, 4, 5, 5, 6, 6, 7, 8, 9, 10]
cp4 [2, 4, 5, 5, 6, 6, 7, 8, 9, 10]
```
</details>

### Step 95: Bash

```bash
cd /tmp; cat > /tmp/ed4.py <<'PYEOF'
s=open("/w/new/solve.f").read()
s=s.replace("""            QL(L) = 0.03D0
""","""            QL(L) = 0.03D0
            IF (PQ(L) .GT. 0.0D0) QL(L) = PQ(L)/2.0D0
""")
open("/w/new/solve.f","w").write(s)
PYEOF
docker exec -i sn-fortran-solver-parity python3 - < /tmp/ed4.py
docker exec sn-fortran-solver-parity bash -lc 'cd /w/new && gfortran -O2 -o hydro *.f 2>&1 | head; cd /w; python3 probes.py | tail -3'
```

<details><summary>output</summary>

```
bad 0 of 240
```
</details>

### Step 96: Bash

```bash
cd /tmp; cat > /tmp/gen.py <<'PYEOF'
import random,sys
sys.path.insert(0,"/w")
from cmp import check
def gen(seed):
    r=random.Random(seed)
    us=r.random()<0.3
    hw=r.random()<0.35
    nj=r.randint(2,14); nr=r.choice([1,1,1,2,3])
    L=[]
    if r.random()<0.7: L.append("TITLE Random deck %d"%seed)
    if us: L.append("UNITS US")
    if hw: L.append("OPTION FRICTION HW")
    if r.random()<0.4: L.append("OPTION TOL %s"%r.choice(["1e-3","1e-4","1e-6","1e-7","1e-8","1e-2"]))
    if r.random()<0.15: L.append("OPTION MAXIT %d"%r.choice([2,3,5,10,20,100]))
    steps=1
    if r.random()<0.35:
        steps=r.randint(2,8); L.append("OPTION STEPS %d"%steps)
        if r.random()<0.7: L.append("OPTION HSTEP %s"%r.choice(["0.5","1","2","0.25","1.5","3"]))
    npat=0
    if steps>1 or r.random()<0.2:
        for k in range(r.randint(1,3)):
            L.append("PATTERN pt%d "%k+" ".join("%.2f"%r.choice([0,0.3,0.6,1,1.2,1.5,2,3]) for _ in range(r.randint(1,6))))
            npat+=1
    nodes=[]
    elev=lambda: round(r.uniform(0,60),1)
    for i in range(nr):
        nodes.append("R%d"%i); L.append("RESERVOIR R%d %.1f"%(i,r.uniform(80,140)*(3.28 if us else 1)))
    for i in range(nj):
        nodes.append("J%d"%i)
        q=r.choice([0,1,2,3,5,8,10,15,20])*(15.85 if us else 1)*r.choice([1,1,0.5,2])
        z=elev()*(3.28 if us else 1)
        line="JUNCTION J%d %.1f %.2f"%(i,z,q)
        if npat and r.random()<0.6: line+=" pt%d"%r.randrange(npat)
        L.append(line)
    links=[]
    def pipe(k,a,b):
        ln=r.choice([100,200,300,500,800,1200])*(3.28 if us else 1)
        d=r.choice([100,150,200,250,300,400])/(25.4 if us else 1)
        if hw: rough=r.choice([90,100,110,120,130,140])
        else: rough=(r.choice([0.05,0.1,0.26,0.5,1.0]) if not us else r.choice([0.2,0.5,1.0,2.0]))
        s="PIPE P%d %s %s %.1f %.2f %s"%(k,a,b,ln,d,rough)
        if r.random()<0.25: s+=" %s"%r.choice([0.5,1,2,5])
        return s
    k=0
    # spanning tree
    order=nodes[:nr]
    for j in range(nj):
        a=r.choice(order); b="J%d"%j
        if r.random()<0.1 and nj>2:
            pass
        L.append(pipe(k,a,b) if r.random()<0.9 else pipe(k,b,a)); k+=1; order.append(b)
    for e in range(r.randint(0,nj//2)):
        a,b=r.sample(nodes,2)
        L.append(pipe(k,a,b)); k+=1
    for e in range(r.choice([0,0,1,2])):
        a,b=r.sample(nodes,2)
        h=r.choice([5,10,20,30])*(3.28 if us else 1)
        if r.random()<0.5:
            L.append("PUMP U%d %s %s %.1f"%(e,a,b,h))
        else:
            L.append("PUMP U%d %s %s %.1f %.2f"%(e,a,b,h,r.choice([5,10,20,40,80])*(15.85 if us else 1)))
    for e in range(r.choice([0,0,1,2])):
        a,b=r.sample(nodes,2)
        st=r.choice(["","OPEN","CLOSED"])
        L.append("VALVE V%d %s %s %.0f %s %s"%(e,a,b,r.choice([100,150,200])/(25.4 if us else 1),r.choice([0,1,5,20]),st))
    if r.random()<0.1:
        L.append("JUNCTION ISO 10 5")
    r.shuffle(L) if r.random()<0.2 else None
    L.append("END")
    return "\n".join(L)+"\n"
if __name__=="__main__":
    a=int(sys.argv[1]); b=int(sys.argv[2])
    bad=0
    for s in range(a,b):
        d=gen(s)
        if not check(d,label="seed%d"%s): bad+=1
    print("bad",bad,"of",b-a)
PYEOF
docker exec -i sn-fortran-solver-parity bash -c 'cat > /w/gen.py' < /tmp/gen.py
docker exec sn-fortran-solver-parity bash -lc 'cd /w; python3 gen.py 0 60 2>&1 | head -80'
```

<details><summary>output</summary>

```
DIFF seed22 len line 9
  P:  *** WARNING W205: NOT CONVERGED AFTER 50 ITERATIONS
  M:  *** WARNING W205: NOT CONVERGED AFTER  50 ITERATIONS
DIFF seed25 len line 11
  P:  *** WARNING W205: NOT CONVERGED AFTER 5 ITERATIONS
  M:  *** WARNING W205: NOT CONVERGED AFTER   5 ITERATIONS
DIFF seed41 tok line 9
  P:  CONVERGED IN  14 ITERATIONS
  M:  CONVERGED IN  19 ITERATIONS
DIFF seed44 len line 11
  P:  *** WARNING W205: NOT CONVERGED AFTER 2 ITERATIONS
  M:  *** WARNING W205: NOT CONVERGED AFTER   2 ITERATIONS
DIFF seed45 len line 9
  P:  *** WARNING W205: NOT CONVERGED AFTER 2 ITERATIONS
  M:  *** WARNING W205: NOT CONVERGED AFTER   2 ITERATIONS
DIFF seed49 len line 9
  P:  *** WARNING W205: NOT CONVERGED AFTER 2 ITERATIONS
  M:  *** WARNING W205: NOT CONVERGED AFTER   2 ITERATIONS
DIFF seed53 len line 9
  P:  *** WARNING W205: NOT CONVERGED AFTER 50 ITERATIONS
  M:  *** WARNING W205: NOT CONVERGED AFTER  50 ITERATIONS
bad 7 of 60
```
</details>

### Step 97: Bash

```bash
cd /tmp; docker exec sn-fortran-solver-parity bash -lc 'cd /w/new && sed -i "s/NOT CONVERGED AFTER .,I3,/NOT CONVERGED AFTER ",I0,/" output.f && grep -n "NOT CONVERGED" -A1 output.f && gfortran -O2 -o hydro *.f; cd /w; python3 -c "
from gen import gen
print(gen(41))"'
```

<details><summary>output</summary>

```
Exit code 2
sed: -e expression #1, char 55: unknown option to `s'
bash: line 2: from: command not found
bash: -c: line 3: syntax error near unexpected token `gen'
bash: -c: line 3: `print(gen(41))"'
```
</details>

### Step 98: Bash

```bash
cd /tmp; cat > /tmp/ed5.py <<'PYEOF'
s=open("/w/new/output.f").read()
a=""" 1020 FORMAT (1X,'*** WARNING W205: NOT CONVERGED AFTER ',I3,
     &        ' ITERATIONS')"""
assert a in s
s=s.replace(a,""" 1020 FORMAT (1X,'*** WARNING W205: NOT CONVERGED AFTER ',I0,
     &        ' ITERATIONS')""")
open("/w/new/output.f","w").write(s)
PYEOF
docker exec -i sn-fortran-solver-parity python3 - < /tmp/ed5.py
docker exec sn-fortran-solver-parity bash -lc 'cd /w/new && gfortran -O2 -o hydro *.f; cd /w; python3 -c "
from gen import gen
print(gen(41))"'
```

<details><summary>output</summary>

```
TITLE Random deck 41
OPTION FRICTION HW
RESERVOIR R0 114.6
RESERVOIR R1 126.9
JUNCTION J0 56.9 0.00
JUNCTION J1 10.1 1.00
JUNCTION J2 47.1 0.00
JUNCTION J3 52.0 0.00
PIPE P0 R0 J0 500.0 150.00 130
PIPE P1 R0 J1 200.0 100.00 110
PIPE P2 R0 J2 100.0 200.00 120 0.5
PIPE P3 J1 J3 500.0 150.00 90 0.5
PIPE P4 J3 J1 500.0 300.00 140
END
```
</details>

### Step 99: Bash

```bash
cd /tmp; cat > /tmp/var2.py <<'PYEOF'
import sys
sys.path.insert(0,"/w")
from var import *
import var
deck=open("/tmp/d41.txt").read() if False else None
PYEOF
docker exec sn-fortran-solver-parity bash -lc 'cd /w; python3 -c "
from gen import gen
open(\"/w/d41.dat\",\"w\").write(gen(41))
"
cat > /w/var2.py <<EOF
import sys
sys.path.insert(0,"/w")
from var import build,tols
from iters import iters
from cmp import PROD
deck=open(sys.argv[1]).read()
def sweep(exe): return [iters(exe,"OPTION TOL %s\n"%t+deck) for t in tols]
print("PROD",sweep(PROD))
variants=eval(sys.argv[2])
for name,repl in variants.items():
    exe=build(name,repl)
    print(name,sweep(exe))
EOF
python3 var2.py d41.dat "{\"base\":[],\"gmin6\":[(\"GMIN\",\"GMIN\")]}"'
```

<details><summary>output</summary>

```
PROD [2, 7, 10, 14, 14, 14, 14, 14, 'NC', 'NC']
base [2, 7, 10, 13, 16, 19, 22, 'NC', 'NC', 'NC']
gmin6 [2, 7, 10, 13, 16, 19, 22, 'NC', 'NC', 'NC']
```
</details>

### Step 100: Bash

```bash
cd /tmp; docker exec sn-fortran-solver-parity bash -lc 'cd /w; python3 var2.py d41.dat "{\"f6\":[(\"      IF (GR .LT. GMIN) GR = GMIN\",\"      IF (LTYP(L).NE.2 .AND. GR .LT. 1.0D-6) GR = 1.0D-6\\n      IF (LTYP(L).EQ.2 .AND. GR .LT. GMIN) GR = GMIN\")],\"f8\":[(\"      IF (GR .LT. GMIN) GR = GMIN\",\"      IF (LTYP(L).NE.2 .AND. GR .LT. 1.0D-8) GR = 1.0D-8\\n      IF (LTYP(L).EQ.2 .AND. GR .LT. GMIN) GR = GMIN\")],\"f10\":[(\"      IF (GR .LT. GMIN) GR = GMIN\",\"      IF (LTYP(L).NE.2 .AND. GR .LT. 1.0D-10) GR = 1.0D-10\\n      IF (LTYP(L).EQ.2 .AND. GR .LT. GMIN) GR = GMIN\")],\"f12\":[(\"      IF (GR .LT. GMIN) GR = GMIN\",\"      IF (LTYP(L).NE.2 .AND. GR .LT. 1.0D-12) GR = 1.0D-12\\n      IF (LTYP(L).EQ.2 .AND. GR .LT. GMIN) GR = GMIN\")]}"'
```

<details><summary>output</summary>

```
PROD [2, 7, 10, 14, 14, 14, 14, 14, 'NC', 'NC']
f6 [2, 7, 10, 13, 16, 19, 'NC', 'NC', 'NC', 'NC']
f8 [2, 7, 10, 13, 16, 19, 49, 'NC', 'NC', 'NC']
f10 [2, 7, 10, 13, 16, 19, 49, 'NC', 'NC', 'NC']
f12 [2, 7, 11, 13, 16, 19, 49, 'NC', 'NC', 'NC']
```
</details>

### Step 101: Bash

```bash
cd /tmp; docker exec sn-fortran-solver-parity bash -lc 'cd /w; rm -rf dbg; cp -r new dbg; cd dbg; python3 - <<EOF
s=open("solve.f").read()
s=s.replace("         IF (SQ .GT. 1.0D-30) THEN","         WRITE (0,*) IT, QL(4), QL(5), SDQ, SQ\n         IF (SQ .GT. 1.0D-30) THEN")
open("solve.f","w").write(s)
EOF
gfortran -O2 -o hydro *.f && ./hydro < ../d41.dat 2>&1 >/dev/null | head -30'
```

<details><summary>output</summary>

```
           1   2.8255786383425989E-003   2.8255786383438665E-003   3.7635874360969254E-002   6.6511572766861727E-003
           2   1.3001986963295134E-003   1.3001986963320224E-003   3.0507598840254068E-003   3.6003973926607659E-003
           3   5.9827496092851198E-004   5.9827496092025091E-004   1.4038474708224415E-003   2.1965499218576613E-003
           4   2.7528459780443393E-004   2.7528459782551906E-004   6.4598072622553565E-004   1.5505691956321256E-003
           5   1.2666425314419790E-004   1.2666425318493720E-004   2.9724068930859484E-004   1.2533285063235308E-003
           6   5.8279826875448533E-005   5.8279826875179108E-005   1.3676885266289545E-004   1.1165596536606352E-003
           7   2.6814847640386261E-005   2.6814847592839479E-005   6.2929958679452399E-005   1.0536296953052838E-003
           8   1.2337469090805520E-005   1.2337468777044189E-005   2.8954757387445181E-005   1.0246749379178386E-003
           9   5.6763761951620761E-006   5.6763762994597450E-006   1.3322185464867475E-005   1.0113527526362503E-003
          10   2.6116274340095375E-006   2.6116281063775025E-006   6.1294982637757988E-006   1.0052232543724744E-003
          11   1.2015636666055942E-006   1.2015629474938863E-006   2.8201298446792244E-006   1.0024031263645785E-003
          12   5.5281317231582603E-007   5.5280922571046554E-007   1.2975068538611806E-006   1.0011056247862934E-003
          13   2.5433514727965794E-007   2.5433264325536956E-007   5.9695478971941183E-007   1.0005086703610301E-003
          14   1.1701207346313968E-007   1.1702000701922105E-007   2.7463835740397219E-007   1.0002340320036263E-003
          15   5.3833545253516334E-008   5.3834258088756255E-008   1.2636651852424998E-007   1.0001076654851020E-003
          16   2.4766960846171508E-008   2.4766084174741056E-008   5.8183957272913648E-008   1.0000494815278291E-003
          17   1.1394365906532689E-008   1.1393468529632523E-008   2.6881120152635681E-008   1.0000226004076764E-003
          18   5.2965021892629272E-009   5.2449042320687212E-009   1.2530318575199070E-008   1.0000106378702221E-003
          19   2.5150711178444088E-009   2.6185595028198425E-009   5.5786527833701013E-009   1.0000050592174389E-003
```
</details>

### Step 102: Bash

```bash
cd /tmp; docker exec sn-fortran-solver-parity bash -lc 'cd /w; python3 var2.py d41.dat "{\"A\":[(\"               DQ = QNEW - QL(L)\",\"               IF (ABS(QNEW) .LT. QZERO) QNEW = 0.0D0\\n               DQ = QNEW - QL(L)\")],\"B\":[(\"               CALL HLGRAD(L, QL(L), H, GR)\",\"               IF (ABS(QL(L)) .LT. QZERO) QL(L) = 0.0D0\\n               CALL HLGRAD(L, QL(L), H, GR)\")]}"'
```

<details><summary>output</summary>

```
PROD [2, 7, 10, 14, 14, 14, 14, 14, 'NC', 'NC']
A [2, 7, 10, 13, 13, 13, 13, 44, 'NC', 'NC']
B [2, 7, 10, 13, 13, 13, 13, 'NC', 'NC', 'NC']
```
</details>

### Step 103: Bash

```bash
cd /tmp; docker exec sn-fortran-solver-parity bash -lc 'cd /w; python3 var2.py d41.dat "{\"C\":[(\"               QNEW = QL(L) - Y(L) + P(L)*(HN(N1) - HN(N2))\",\"               QNEW = QL(L) - Y(L) + P(L)*(HN(N1) - HN(N2))\\n               IF (ABS(QL(L)) .LT. QZERO) QNEW = 0.0D0\")]}"'
```

<details><summary>output</summary>

```
PROD [2, 7, 10, 14, 14, 14, 14, 14, 'NC', 'NC']
C [2, 7, 10, 14, 14, 14, 14, 28, 'NC', 'NC']
```
</details>

### Step 104: Bash

```bash
cd /tmp; docker exec sn-fortran-solver-parity bash -lc 'cd /w; rm -rf dbg; cp -r new dbg; cd dbg; python3 - <<EOF
s=open("solve.f").read()
s=s.replace("               QNEW = QL(L) - Y(L) + P(L)*(HN(N1) - HN(N2))","               QNEW = QL(L) - Y(L) + P(L)*(HN(N1) - HN(N2))\n               IF (ABS(QL(L)) .LT. QZERO) QNEW = 0.0D0")
s=s.replace("         IF (SQ .GT. 1.0D-30) THEN","         WRITE (0,*) IT, SDQ, SQ, SDQ/SQ\n         IF (SQ .GT. 1.0D-30) THEN")
open("solve.f","w").write(s)
EOF
gfortran -O2 -o hydro *.f && (echo "OPTION TOL 1e-8"; cat ../d41.dat) | ./hydro 2>&1 >/dev/null | sed -n 8,40p'
```

<details><summary>output</summary>

```
           8   2.8954757387445181E-005   1.0246749379172592E-003   2.8257505200915949E-002
           9   1.3322185464867475E-005   1.0113527526356709E-003   1.3172639744291724E-002
          10   6.1294982637757980E-006   1.0052232543718950E-003   6.0976486935787827E-003
          11   2.8201298446792244E-006   1.0024031263639991E-003   2.8133689635512576E-003
          12   1.2975068538611806E-006   1.0011056247857140E-003   1.2960738824526244E-003
          13   1.1056225802544392E-006   1.0000000025699159E-003   1.1056225774130821E-003
          14   3.3591243220158773E-010   9.9999966665748367E-004   3.3591254417552049E-007
          15   2.1058230549944601E-010   9.9999987723978917E-004   2.1058233135057742E-007
          16   1.3735939404131703E-010   1.0000000145991832E-003   1.3735939203598209E-007
          17   5.9623581028997452E-011   9.9999995497560218E-004   5.9623583713513411E-008
          18   4.7168908752850958E-011   9.9999990780669343E-004   4.7168913101509023E-008
          19   2.9381503892193794E-010   1.0000002016217324E-003   2.9381497968245277E-007
          20   7.1797253038685671E-011   1.0000001298244793E-003   7.1797243717645884E-008
          21   1.8537006586834270E-010   9.9999994445441344E-004   1.8537007616483230E-007
          22   2.5465279407735353E-010   1.0000001991072075E-003   2.5465274337415692E-007
          23   3.5794307969017058E-010   9.9999984116412783E-004   3.5794313654438086E-007
          24   8.0138585220948522E-011   9.9999992130271305E-004   8.0138591527638249E-008
          25   3.5553339352428770E-010   1.0000002768361066E-003   3.5553329509983453E-007
          26   3.8884614061637790E-011   1.0000002379514925E-003   3.8884604808988039E-008
          27   3.4009362643791508E-010   9.9999989785786608E-004   3.4009366117580737E-007
          28   9.1277426155639274E-012   9.9999988873012346E-004   9.1277436312068346E-009
```
</details>

### Step 105: Bash

```bash
cd /tmp; docker exec sn-fortran-solver-parity bash -lc 'cd /w; python3 - <<EOF
import subprocess
reps=[]
base_z=("               QNEW = QL(L) - Y(L) + P(L)*(HN(N1) - HN(N2))\\n","               QNEW = QL(L) - Y(L) + P(L)*(HN(N1) - HN(N2))\\n               IF (ABS(QL(L)) .LT. QZERO) QNEW = 0.0D0\\n")
def v(fl):
    return [base_z,("      IF (GR .LT. GMIN) GR = GMIN","      IF (LTYP(L).NE.2 .AND. GR .LT. %s) GR = %s\\n      IF (LTYP(L).EQ.2 .AND. GR .LT. GMIN) GR = GMIN"%(fl,fl))]
d={"f1e-1":v("1.0D-1"),"f1e-2":v("1.0D-2"),"f1e-3":v("1.0D-3"),"f1":v("1.0D0"),"f1e-4":v("1.0D-4"),"f1e-5":v("1.0D-5")}
open("/w/vv.txt","w").write(repr(d))
EOF
python3 var2.py d41.dat "$(cat vv.txt)"'
```

<details><summary>output</summary>

```
PROD [2, 7, 10, 14, 14, 14, 14, 14, 'NC', 'NC']
f1e-1 [2, 7, 10, 14, 14, 14, 14, 14, 16, 'NC']
f1e-2 [2, 7, 10, 14, 14, 14, 14, 14, 24, 'NC']
f1e-3 [2, 7, 10, 14, 14, 14, 14, 14, 'NC', 'NC']
f1 [2, 7, 10, 15, 29, 29, 29, 29, 29, 'NC']
f1e-4 [2, 7, 10, 14, 14, 14, 14, 28, 'NC', 'NC']
f1e-5 [2, 7, 10, 14, 14, 14, 14, 'NC', 'NC', 'NC']
```
</details>

### Step 106: Bash

```bash
cd /tmp; cat > /tmp/ed6.py <<'PYEOF'
s=open("/w/new/solve.f").read()
a="               QNEW = QL(L) - Y(L) + P(L)*(HN(N1) - HN(N2))\n"
assert a in s
s=s.replace(a,a+"               IF (ABS(QL(L)) .LT. QZERO) QNEW = 0.0D0\n")
b="      IF (GR .LT. GMIN) GR = GMIN\n"
assert b in s
s=s.replace(b,"""      IF (LTYP(L) .EQ. 2) THEN
         IF (GR .LT. GMIN) GR = GMIN
      ELSE
         IF (GR .LT. GMINP) GR = GMINP
      ENDIF
""")
open("/w/new/solve.f","w").write(s)
h=open("/w/new/hydro.inc").read()
h=h.replace("DOUBLE PRECISION GRAV, PI, VISC, GMIN, QZERO","DOUBLE PRECISION GRAV, PI, VISC, GMIN, GMINP, QZERO")
h=h.replace("PARAMETER (VISC=1.0D-6, GMIN=1.0D-4, QZERO=1.0D-6)","PARAMETER (VISC=1.0D-6, GMIN=1.0D-4, GMINP=1.0D-3, QZERO=1.0D-6)")
open("/w/new/hydro.inc","w").write(h)
PYEOF
docker exec -i sn-fortran-solver-parity python3 - < /tmp/ed6.py
docker exec sn-fortran-solver-parity bash -lc 'cd /w/new && gfortran -O2 -o hydro *.f 2>&1|head; cd /w; python3 probes.py | tail -3; python3 gen.py 0 150 2>&1 | head -60'
```

<details><summary>output</summary>

```
  P:  CONVERGED IN   2 ITERATIONS
  M:  CONVERGED IN   1 ITERATIONS
bad 10 of 240
DIFF seed16 tok line 104
  P:  J4       JUNC     14.100     12.00    -2.912   -17.012    -166.5
  M:  J4       JUNC     14.100     12.00    -2.909   -17.009    -166.5
DIFF seed33 linecount 229 vs 230
DIFF seed47 linecount 209 vs 212
DIFF seed59 linecount 337 vs 345
DIFF seed67 linecount 123 vs 131
DIFF seed68 linecount 406 vs 436
DIFF seed69 tok line 9
  P:  CONVERGED IN  17 ITERATIONS
  M:  CONVERGED IN  19 ITERATIONS
DIFF seed86 linecount 254 vs 257
DIFF seed87 tok line 9
  P:  CONVERGED IN  15 ITERATIONS
  M:  CONVERGED IN  21 ITERATIONS
DIFF seed96 linecount 197 vs 201
DIFF seed110 linecount 58 vs 57
DIFF seed121 linecount 276 vs 281
DIFF seed130 linecount 208 vs 210
DIFF seed135 linecount 349 vs 357
DIFF seed146 linecount 372 vs 385
bad 15 of 150
```
</details>

### Step 107: Bash

```bash
cd /tmp; docker exec sn-fortran-solver-parity bash -lc 'cd /w; python3 probes.py | head -40'
```

<details><summary>output</summary>

```
DIFF 'PIPE p R a 1 1 0' 'END\n' tok line 9
  P:  CONVERGED IN   2 ITERATIONS
  M:  CONVERGED IN   1 ITERATIONS
DIFF 'PIPE p R a 1 1 0' '' tok line 10
  P:  CONVERGED IN   2 ITERATIONS
  M:  CONVERGED IN   1 ITERATIONS
DIFF 'PIPE p R a 1 1 1 1 1 1 1' 'END\n' tok line 10
  P:  CONVERGED IN   2 ITERATIONS
  M:  CONVERGED IN   1 ITERATIONS
DIFF 'PIPE p R a 1 1 1 1 1 1 1' '' tok line 11
  P:  CONVERGED IN   2 ITERATIONS
  M:  CONVERGED IN   1 ITERATIONS
DIFF 'PUMP u R a 5\nPUMP u2 R a 5 3' 'END\n' tok line 9
  P:  CONVERGED IN  16 ITERATIONS
  M:  CONVERGED IN  15 ITERATIONS
DIFF 'PUMP u R a 5\nPUMP u2 R a 5 3' '' tok line 10
  P:  CONVERGED IN  16 ITERATIONS
  M:  CONVERGED IN  15 ITERATIONS
DIFF 'PIPE p R a 1 1 1' 'END\n' tok line 9
  P:  CONVERGED IN   2 ITERATIONS
  M:  CONVERGED IN   1 ITERATIONS
DIFF 'PIPE p R a 1 1 1' '' tok line 10
  P:  CONVERGED IN   2 ITERATIONS
  M:  CONVERGED IN   1 ITERATIONS
DIFF 'PIPE p R a 1 1 1\nPIPE p2 R a 1 1 1' 'END\n' tok line 9
  P:  CONVERGED IN   2 ITERATIONS
  M:  CONVERGED IN   1 ITERATIONS
DIFF 'PIPE p R a 1 1 1\nPIPE p2 R a 1 1 1' '' tok line 10
  P:  CONVERGED IN   2 ITERATIONS
  M:  CONVERGED IN   1 ITERATIONS
bad 10 of 240
```
</details>

### Step 108: Bash

```bash
cd /tmp; cat > /tmp/ed7.py <<'PYEOF'
s=open("/w/new/solve.f").read()
a="               IF (ABS(QL(L)) .LT. QZERO) QNEW = 0.0D0\n"
assert a in s
s=s.replace(a,"""               IF (ABS(QL(L)) .LT. QZERO .AND. ABS(QNEW) .LT. QZERO)
     &            QNEW = 0.0D0
""")
open("/w/new/solve.f","w").write(s)
PYEOF
docker exec -i sn-fortran-solver-parity python3 - < /tmp/ed7.py
docker exec sn-fortran-solver-parity bash -lc 'cd /w/new && gfortran -O2 -o hydro *.f 2>&1|head; cd /w; python3 probes.py | tail -12;python3 var2.py d41.dat "{\"base\":[]}"; python3 gen.py 0 150 2>&1 | head -60'
```

<details><summary>output</summary>

```
DIFF 'PUMP u R a 5\nPUMP u2 R a 5 3' 'END\n' tok line 9
  P:  CONVERGED IN  16 ITERATIONS
  M:  CONVERGED IN  15 ITERATIONS
DIFF 'PUMP u R a 5\nPUMP u2 R a 5 3' '' tok line 10
  P:  CONVERGED IN  16 ITERATIONS
  M:  CONVERGED IN  15 ITERATIONS
bad 2 of 240
PROD [2, 7, 10, 14, 14, 14, 14, 14, 'NC', 'NC']
base [2, 7, 10, 14, 14, 14, 14, 14, 'NC', 'NC']
DIFF seed69 tok line 9
  P:  CONVERGED IN  17 ITERATIONS
  M:  CONVERGED IN  19 ITERATIONS
DIFF seed87 tok line 9
  P:  CONVERGED IN  15 ITERATIONS
  M:  CONVERGED IN  21 ITERATIONS
DIFF seed135 len line 181
  P:  CONVERGED IN   5 ITERATIONS
  M:  *** WARNING W205: NOT CONVERGED AFTER 5 ITERATIONS
bad 3 of 150
```
</details>

### Step 109: Bash

```bash
cd /tmp; cat > /tmp/ed8.py <<'PYEOF'
s=open("/w/new/solve.f").read()
a="""               IF (ABS(QL(L)) .LT. QZERO .AND. ABS(QNEW) .LT. QZERO)
     &            QNEW = 0.0D0
"""
assert a in s
s=s.replace(a,"""               IF (LTYP(L) .NE. 2 .AND. ABS(QL(L)) .LT. QZERO .AND.
     &            ABS(QNEW) .LT. QZERO) QNEW = 0.0D0
""")
open("/w/new/solve.f","w").write(s)
PYEOF
docker exec -i sn-fortran-solver-parity python3 - < /tmp/ed8.py
docker exec sn-fortran-solver-parity bash -lc 'cd /w/new && gfortran -O2 -o hydro *.f 2>&1|head; cd /w; python3 probes.py | tail -3; python3 gen.py 0 150 2>&1 | head -60'
```

<details><summary>output</summary>

```
bad 0 of 240
DIFF seed69 tok line 9
  P:  CONVERGED IN  17 ITERATIONS
  M:  CONVERGED IN  19 ITERATIONS
DIFF seed87 tok line 9
  P:  CONVERGED IN  15 ITERATIONS
  M:  CONVERGED IN  21 ITERATIONS
DIFF seed135 len line 181
  P:  CONVERGED IN   5 ITERATIONS
  M:  *** WARNING W205: NOT CONVERGED AFTER 5 ITERATIONS
bad 3 of 150
```
</details>

### Step 110: Bash

```bash
cd /tmp; docker exec sn-fortran-solver-parity bash -lc 'cd /w; python3 -c "
from gen import gen
for s in (69,87,135): open(\"/w/d%d.dat\"%s,\"w\").write(gen(s))
"; cat d69.dat; python3 var2.py d69.dat "{}"; cat d87.dat; python3 var2.py d87.dat "{}"'
```

<details><summary>output</summary>

```
TITLE Random deck 69
OPTION FRICTION HW
OPTION TOL 1e-8
RESERVOIR R0 129.8
JUNCTION J0 8.5 16.00
JUNCTION J1 24.9 10.00
JUNCTION J2 8.5 2.00
JUNCTION J3 41.6 5.00
PIPE P0 R0 J0 800.0 400.00 90
PIPE P1 J0 J1 200.0 100.00 100 1
PIPE P2 J0 J2 100.0 400.00 110
PIPE P3 J2 J3 100.0 200.00 120
PIPE P4 J0 J2 1200.0 400.00 140
PUMP U0 J3 J0 30.0
VALVE V0 J2 J3 150 0 OPEN
END
PROD [17, 17, 17, 17, 17, 17, 17, 17, 17, 17]
JUNCTION J1 101.0 31.70
PUMP U0 J5 J3 32.8 634.00
VALVE V0 J9 J1 6 0 
PIPE P9 J8 J9 328.0 5.91 130
RESERVOIR R0 438.7
JUNCTION J5 194.2 79.25
PIPE P11 J3 J4 3936.0 9.84 100
JUNCTION J2 49.2 15.85
PIPE P2 J0 J2 328.0 11.81 110
PIPE P5 J4 J5 1640.0 7.87 100
UNITS US
PIPE P4 J0 J4 328.0 3.94 110
JUNCTION J7 160.4 95.10
PIPE P6 J0 J6 328.0 15.75 140 2
PIPE P1 R0 J1 328.0 15.75 90
JUNCTION J0 75.8 0.00
PIPE P10 J9 J1 1640.0 5.91 140
TITLE Random deck 87
JUNCTION J4 117.1 158.50
JUNCTION J9 195.2 7.92
PIPE P0 R0 J0 984.0 9.84 130
PIPE P7 J1 J7 328.0 5.91 130
OPTION FRICTION HW
JUNCTION J3 60.0 31.70
PIPE P8 R0 J8 984.0 5.91 130
OPTION TOL 1e-8
JUNCTION J8 182.7 79.25
JUNCTION J6 134.2 237.75
PIPE P3 J0 J3 656.0 11.81 100
END
PROD [15, 15, 15, 15, 15, 15, 15, 15, 15, 15]
```
</details>

### Step 111: Bash

```bash
cd /tmp; cat > /w/var3.py <<'EOF'
import sys
sys.path.insert(0,"/w")
from var import build
from iters import iters
from cmp import PROD
decks=[open(f).read() for f in sys.argv[1].split(",")]
variants=eval(sys.argv[2])
print("PROD",[iters(PROD,d) for d in decks])
for name,repl in variants.items():
    exe=build(name,repl)
    print(name,[iters(exe,d) for d in decks])
EOF
docker exec sn-fortran-solver-parity bash -lc 'cd /w; python3 var3.py d69.dat,d87.dat,d135.dat "{\"base\":[],\"v4\":[(\"      ELSE\\n         IF (GR .LT. GMINP) GR = GMINP\",\"      ELSE IF (LTYP(L).EQ.3) THEN\\n         IF (GR .LT. GMIN) GR = GMIN\\n      ELSE\\n         IF (GR .LT. GMINP) GR = GMINP\")],\"v2\":[(\"      ELSE\\n         IF (GR .LT. GMINP) GR = GMINP\",\"      ELSE IF (LTYP(L).EQ.3) THEN\\n         IF (GR .LT. 1.0D-2) GR = 1.0D-2\\n      ELSE\\n         IF (GR .LT. GMINP) GR = GMINP\")]}"'
```

<details><summary>output</summary>

```
Exit code 2
(eval):1: no such file or directory: /w/var3.py
python3: can't open file '/w/var3.py': [Errno 2] No such file or directory
```
</details>

### Step 112: Bash

```bash
cd /tmp; docker exec -i sn-fortran-solver-parity bash -c 'cat > /w/var3.py' <<'EOF'
import sys
sys.path.insert(0,"/w")
from var import build
from iters import iters
from cmp import PROD
decks=[open(f).read() for f in sys.argv[1].split(",")]
variants=eval(sys.argv[2])
print("PROD",[iters(PROD,d) for d in decks])
for name,repl in variants.items():
    exe=build(name,repl)
    print(name,[iters(exe,d) for d in decks])
EOF
docker exec sn-fortran-solver-parity bash -lc 'cd /w; python3 var3.py d69.dat,d87.dat,d135.dat "{\"base\":[],\"v4\":[(\"      ELSE\\n         IF (GR .LT. GMINP) GR = GMINP\",\"      ELSE IF (LTYP(L).EQ.3) THEN\\n         IF (GR .LT. GMIN) GR = GMIN\\n      ELSE\\n         IF (GR .LT. GMINP) GR = GMINP\")],\"v2\":[(\"      ELSE\\n         IF (GR .LT. GMINP) GR = GMINP\",\"      ELSE IF (LTYP(L).EQ.3) THEN\\n         IF (GR .LT. 1.0D-2) GR = 1.0D-2\\n      ELSE\\n         IF (GR .LT. GMINP) GR = GMINP\")]}"'
```

<details><summary>output</summary>

```
PROD [17, 15, 4]
base [19, 21, 4]
v4 [18, 17, 4]
v2 [24, 45, 4]
```
</details>

### Step 113: Bash

```bash
cd /tmp; docker exec sn-fortran-solver-parity bash -lc 'cd /w; python3 - <<EOF
d={}
for nm,fl in [("5","1.0D-5"),("6","1.0D-6"),("8","1.0D-8"),("10","1.0D-10"),("12","1.0D-12")]:
    d["v"+nm]=[("      ELSE\n         IF (GR .LT. GMINP) GR = GMINP","      ELSE IF (LTYP(L).EQ.3) THEN\n         IF (GR .LT. %s) GR = %s\n      ELSE\n         IF (GR .LT. GMINP) GR = GMINP"%(fl,fl))]
open("/w/vv.txt","w").write(repr(d))
EOF
python3 var3.py d69.dat,d87.dat,d135.dat "$(cat vv.txt)"'
```

<details><summary>output</summary>

```
PROD [17, 15, 4]
v5 [15, 18, 4]
v6 [15, 19, 4]
v8 ['NC', 'NC', 1]
v10 ['NC', 'NC', 'NC']
v12 ['NC', 'NC', 'NC']
```
</details>

### Step 114: Bash

```bash
cd /tmp; docker exec sn-fortran-solver-parity bash -lc 'cd /w; cat > vk0.dat <<EOF
RESERVOIR R 100
JUNCTION a 10 5
JUNCTION b 20 3
PIPE p R a 100 100 0.1
VALVE v a b 100 0
END
EOF
python3 - <<EOF
d={}
for nm,fl in [("1","1.0D-1"),("2","1.0D-2"),("3","1.0D-3"),("4","1.0D-4"),("5","1.0D-5"),("7","1.0D-7"),("0","1.0D0")]:
    d["v"+nm]=[("      ELSE\n         IF (GR .LT. GMINP) GR = GMINP","      ELSE IF (LTYP(L).EQ.3) THEN\n         IF (GR .LT. %s) GR = %s\n      ELSE\n         IF (GR .LT. GMINP) GR = GMINP"%(fl,fl))]
open("/w/vv.txt","w").write(repr(d))
EOF
python3 var2.py vk0.dat "$(cat vv.txt)"'
```

<details><summary>output</summary>

```
PROD [1, 2, 2, 2, 2, 2, 2, 2, 'NC', 'NC']
v1 [1, 2, 2, 2, 2, 2, 2, 2, 2, 3]
v2 [1, 2, 2, 2, 2, 2, 2, 2, 5, 'NC']
v3 [1, 2, 2, 2, 2, 2, 2, 2, 6, 'NC']
v4 [1, 2, 2, 2, 2, 2, 2, 2, 'NC', 'NC']
v5 [1, 2, 2, 2, 2, 2, 2, 15, 'NC', 'NC']
v7 [1, 2, 2, 2, 2, 2, 19, 'NC', 'NC', 'NC']
v0 [1, 2, 2, 2, 2, 2, 2, 2, 2, 5]
```
</details>

### Step 115: Bash

```bash
cd /tmp; docker exec sn-fortran-solver-parity bash -lc 'cd /w; python3 var3.py d41.dat,d69.dat,d87.dat,vk0.dat "{\"g4\":[(\"GMINP\",\"GMIN\")]}"; grep -n GMINP new/solve.f'
```

<details><summary>output</summary>

```
PROD [14, 17, 15, 2]
g4 [14, 19, 21, 2]
221:         IF (GR .LT. GMINP) GR = GMINP
```
</details>

### Step 116: Bash

```bash
cd /tmp; cat > /tmp/ed9.py <<'PYEOF'
s=open("/w/new/solve.f").read()
a="""      IF (LTYP(L) .EQ. 2) THEN
         IF (GR .LT. GMIN) GR = GMIN
      ELSE
         IF (GR .LT. GMINP) GR = GMINP
      ENDIF
"""
assert a in s
s=s.replace(a,"""      IF (LTYP(L) .EQ. 2) THEN
         IF (GR .LT. GMINU) GR = GMINU
      ELSE IF (LTYP(L) .EQ. 3) THEN
         IF (GR .LT. GMINV) GR = GMINV
      ELSE
         IF (GR .LT. GMINP) GR = GMINP
      ENDIF
""")
open("/w/new/solve.f","w").write(s)
h=open("/w/new/hydro.inc").read()
h=h.replace("GMIN, GMINP, QZERO","GMIN, GMINP, GMINU, GMINV, QZERO")
h=h.replace("GMIN=1.0D-4, GMINP=1.0D-3, QZERO=1.0D-6)","GMIN=1.0D-4, GMINP=1.0D-4, GMINU=1.0D-4,\n     &           GMINV=1.0D-4, QZERO=1.0D-6)")
open("/w/new/hydro.inc","w").write(h)
PYEOF
docker exec -i sn-fortran-solver-parity python3 - < /tmp/ed9.py
docker exec sn-fortran-solver-parity bash -lc 'cd /w/new && gfortran -O2 -o hydro *.f 2>&1|head; cd /w; python3 probes.py | tail -3; python3 gen.py 0 150 2>&1 | head -60'
```

<details><summary>output</summary>

```
bad 0 of 240
DIFF seed69 tok line 9
  P:  CONVERGED IN  17 ITERATIONS
  M:  CONVERGED IN  19 ITERATIONS
DIFF seed87 tok line 9
  P:  CONVERGED IN  15 ITERATIONS
  M:  CONVERGED IN  21 ITERATIONS
DIFF seed135 len line 181
  P:  CONVERGED IN   5 ITERATIONS
  M:  *** WARNING W205: NOT CONVERGED AFTER 5 ITERATIONS
bad 3 of 150
```
</details>

### Step 117: Bash

```bash
cd /tmp; docker exec -i sn-fortran-solver-parity bash -c 'cat > /w/var4.py' <<'EOF'
import sys,shutil,subprocess,itertools
sys.path.insert(0,"/w")
from iters import iters
from cmp import PROD
def build(name,gp,gu,gv,extra=[]):
    d="/w/v4_"+name
    shutil.rmtree(d,ignore_errors=True); shutil.copytree("/w/new",d)
    h=open(d+"/hydro.inc").read()
    h=h.replace("GMINP=1.0D-4, GMINU=1.0D-4,\n     &           GMINV=1.0D-4","GMINP=%s, GMINU=%s,\n     &           GMINV=%s"%(gp,gu,gv))
    open(d+"/hydro.inc","w").write(h)
    for fn,a,b in extra:
        s=open(d+"/"+fn).read(); assert a in s,a; s=s.replace(a,b); open(d+"/"+fn,"w").write(s)
    r=subprocess.run("cd %s && gfortran -O2 -o hydro *.f"%d,shell=True,capture_output=True,text=True)
    if r.returncode: print(r.stderr[:1500])
    return d+"/hydro"
if __name__=="__main__":
    decks=[open(f).read() for f in sys.argv[1].split(",")]
    vals=sys.argv[2].split(",")
    p=[iters(PROD,d) for d in decks]
    print("PROD",p)
    for gp,gu,gv in itertools.product(sys.argv[3].split(","),sys.argv[4].split(","),sys.argv[5].split(",")):
        exe=build("t",gp,gu,gv)
        r=[iters(exe,d) for d in decks]
        print(gp,gu,gv,r,"OK" if r==p else "")
EOF
docker exec sn-fortran-solver-parity bash -lc 'cd /w; python3 var4.py d69.dat,d87.dat,d41.dat,vk0.dat x 1.0D-3,1.0D-4 1.0D-2,1.0D-3,1.0D-4,1.0D-5 1.0D-3,1.0D-4,1.0D-5'
```

<details><summary>output</summary>

```
PROD [17, 15, 14, 2]
1.0D-3 1.0D-2 1.0D-3 [19, 21, 14, 2] 
1.0D-3 1.0D-2 1.0D-4 [17, 17, 14, 2] 
1.0D-3 1.0D-2 1.0D-5 [15, 18, 14, 2] 
1.0D-3 1.0D-3 1.0D-3 [19, 21, 14, 2] 
1.0D-3 1.0D-3 1.0D-4 [18, 17, 14, 2] 
1.0D-3 1.0D-3 1.0D-5 [15, 18, 14, 2] 
1.0D-3 1.0D-4 1.0D-3 [19, 21, 14, 2] 
1.0D-3 1.0D-4 1.0D-4 [18, 17, 14, 2] 
1.0D-3 1.0D-4 1.0D-5 [15, 18, 14, 2] 
1.0D-3 1.0D-5 1.0D-3 [19, 21, 14, 2] 
1.0D-3 1.0D-5 1.0D-4 [18, 17, 14, 2] 
1.0D-3 1.0D-5 1.0D-5 [15, 18, 14, 2] 
1.0D-4 1.0D-2 1.0D-3 [17, 41, 14, 2] 
1.0D-4 1.0D-2 1.0D-4 [18, 21, 14, 2] 
1.0D-4 1.0D-2 1.0D-5 [15, 17, 14, 2] 
1.0D-4 1.0D-3 1.0D-3 [17, 41, 14, 2] 
1.0D-4 1.0D-3 1.0D-4 [18, 21, 14, 2] 
1.0D-4 1.0D-3 1.0D-5 [15, 17, 14, 2] 
1.0D-4 1.0D-4 1.0D-3 [17, 41, 14, 2] 
1.0D-4 1.0D-4 1.0D-4 [19, 21, 14, 2] 
1.0D-4 1.0D-4 1.0D-5 [15, 17, 14, 2] 
1.0D-4 1.0D-5 1.0D-3 [17, 41, 14, 2] 
1.0D-4 1.0D-5 1.0D-4 [19, 21, 14, 2] 
1.0D-4 1.0D-5 1.0D-5 [15, 17, 14, 2]
```
</details>

### Step 118: Bash

```bash
cd /tmp; docker exec -i sn-fortran-solver-parity bash -c 'cat > /w/ddmin.py' <<'EOF'
import sys
sys.path.insert(0,"/w")
from iters import iters
from cmp import PROD,MINE
def differs(deck):
    p=iters(PROD,deck); m=iters(MINE,deck)
    return p!=m and not str(p).startswith("?")
deck=open(sys.argv[1]).read().strip().split("\n")
changed=True
while changed:
    changed=False
    for i in range(len(deck)):
        t=deck[:i]+deck[i+1:]
        if differs("\n".join(t)+"\n"):
            deck=t; changed=True; break
print("\n".join(deck))
print(iters(PROD,"\n".join(deck)+"\n"),iters(MINE,"\n".join(deck)+"\n"))
EOF
docker exec sn-fortran-solver-parity bash -lc 'cd /w; python3 ddmin.py d69.dat; python3 ddmin.py d87.dat'
```

<details><summary>output</summary>

```
OPTION TOL 1e-8
RESERVOIR R0 129.8
JUNCTION J0 8.5 16.00
JUNCTION J2 8.5 2.00
JUNCTION J3 41.6 5.00
PIPE P0 R0 J0 800.0 400.00 90
PUMP U0 J3 J0 30.0
VALVE V0 J2 J3 150 0 OPEN
2 3
JUNCTION J1 101.0 31.70
VALVE V0 J9 J1 6 0 
RESERVOIR R0 438.7
PIPE P1 R0 J1 328.0 15.75 90
JUNCTION J9 195.2 7.92
14 12
```
</details>

### Step 119: Bash

```bash
cd /tmp; docker exec sn-fortran-solver-parity bash -lc 'cd /w; cat > m1.dat <<EOF
RESERVOIR R0 129.8
JUNCTION J0 8.5 16.00
JUNCTION J2 8.5 2.00
JUNCTION J3 41.6 5.00
PIPE P0 R0 J0 800.0 400.00 90
PUMP U0 J3 J0 30.0
VALVE V0 J2 J3 150 0 OPEN
END
EOF
python3 - <<EOF
import sys
sys.path.insert(0,"/w")
from iters import iters
from cmp import PROD,MINE
base=open("/w/m1.dat").read()
tols=("1e-3","1e-5","1e-6","1e-7","1e-8","1e-9","1e-10","1e-12")
for k in ["0","0.001","0.1","1","10"]:
    d=base.replace("150 0 OPEN","150 %s OPEN"%k)
    print(k,"P",[iters(PROD,"OPTION FRICTION HW\nOPTION TOL %s\n"%t+d) for t in tols])
    print(k,"M",[iters(MINE,"OPTION FRICTION HW\nOPTION TOL %s\n"%t+d) for t in tols])
EOF'
```

<details><summary>output</summary>

```
0 P [2, 2, 2, 2, 3, 'NC', 'NC', 'NC']
0 M [2, 2, 2, 2, 3, 'NC', 'NC', 'NC']
0.001 P [2, 2, 2, 2, 2, 'NC', 'NC', 'NC']
0.001 M [2, 2, 2, 2, 2, 27, 'NC', 'NC']
0.1 P [2, 2, 2, 2, 2, 'NC', 'NC', 'NC']
0.1 M [2, 2, 2, 2, 2, 7, 'NC', 'NC']
1 P [2, 2, 2, 2, 3, 'NC', 'NC', 'NC']
1 M [2, 2, 2, 2, 2, 5, 'NC', 'NC']
10 P [2, 2, 2, 2, 2, 3, 13, 'NC']
10 M [2, 2, 2, 2, 2, 13, 'NC', 'NC']
```
</details>

### Step 120: Bash

```bash
cd /tmp; docker exec -i sn-fortran-solver-parity bash -c 'cat > /w/m1test.py' <<'EOF'
import sys,shutil,subprocess
sys.path.insert(0,"/w")
from iters import iters
from cmp import PROD
base=open("/w/m1.dat").read()
tols=("1e-3","1e-5","1e-6","1e-7","1e-8","1e-9","1e-10","1e-12")
decks=[]
for k in ["0","0.001","0.1","1","10"]:
    decks.append("OPTION FRICTION HW\nOPTION TOL %s\n"+base.replace("150 0 OPEN","150 %s OPEN"%k))
def sweep(exe):
    return [[iters(exe,d%t) for t in tols] for d in decks]
def build(name,files):
    d="/w/m1_"+name
    shutil.rmtree(d,ignore_errors=True); shutil.copytree("/w/new",d)
    for fn,a,b in files:
        s=open(d+"/"+fn).read(); assert a in s,a; s=s.replace(a,b); open(d+"/"+fn,"w").write(s)
    r=subprocess.run("cd %s && gfortran -O2 -o hydro *.f"%d,shell=True,capture_output=True,text=True)
    if r.returncode: print(r.stderr[:1500])
    return d+"/hydro"
P=sweep(PROD)
def test(name,files):
    exe=build(name,files); M=sweep(exe)
    n=sum(1 for a,b in zip(P,M) for x,y in zip(a,b) if x!=y)
    print(name,"mismatch",n); 
    if n<=6: print(M)
    return n
if __name__=="__main__":
    variants=eval(sys.argv[1])
    for k,v in variants.items(): test(k,v)
EOF
docker exec sn-fortran-solver-parity bash -lc 'cd /w; python3 m1test.py "{\"base\":[],
\"b\":[(\"solve.f\",\"         R = XK(L)/(2.0D0*GRAV*A*A)\\n         H = R*Q*ABS(Q)\\n         GR = 2.0D0*R*ABS(Q)\",\"         V = Q/A\\n         H = XK(L)*V*ABS(V)/(2.0D0*GRAV)\\n         GR = 2.0D0*XK(L)*ABS(V)/(2.0D0*GRAV*A)\")],
\"c\":[(\"solve.f\",\"         R = XK(L)/(2.0D0*GRAV*A*A)\\n         H = R*Q*ABS(Q)\\n         GR = 2.0D0*R*ABS(Q)\",\"         V = Q/A\\n         H = XK(L)*V*ABS(V)/(2.0D0*GRAV)\\n         GR = XK(L)*ABS(V)/(GRAV*A)\")],
\"d\":[(\"solve.f\",\"         R = XK(L)/(2.0D0*GRAV*A*A)\\n         H = R*Q*ABS(Q)\\n         GR = 2.0D0*R*ABS(Q)\",\"         V = Q/A\\n         H = XK(L)*V*ABS(V)/(2.0D0*GRAV)\\n         GR = ABS(2.0D0*H/Q)\")]}"'
```

<details><summary>output</summary>

```
base mismatch 6
[[2, 2, 2, 2, 3, 'NC', 'NC', 'NC'], [2, 2, 2, 2, 2, 27, 'NC', 'NC'], [2, 2, 2, 2, 2, 7, 'NC', 'NC'], [2, 2, 2, 2, 2, 5, 'NC', 'NC'], [2, 2, 2, 2, 2, 13, 'NC', 'NC']]
b mismatch 3
[[2, 2, 2, 2, 3, 'NC', 'NC', 'NC'], [2, 2, 2, 2, 2, 'NC', 'NC', 'NC'], [2, 2, 2, 2, 2, 'NC', 'NC', 'NC'], [2, 2, 2, 2, 3, 3, 'NC', 'NC'], [2, 2, 2, 2, 2, 10, 'NC', 'NC']]
c mismatch 3
[[2, 2, 2, 2, 3, 'NC', 'NC', 'NC'], [2, 2, 2, 2, 2, 'NC', 'NC', 'NC'], [2, 2, 2, 2, 2, 'NC', 'NC', 'NC'], [2, 2, 2, 2, 3, 3, 'NC', 'NC'], [2, 2, 2, 2, 2, 10, 'NC', 'NC']]
d mismatch 6
[[2, 2, 2, 2, 3, 'NC', 'NC', 'NC'], [2, 2, 2, 2, 2, 12, 'NC', 'NC'], [2, 2, 2, 2, 2, 13, 'NC', 'NC'], [2, 2, 2, 2, 2, 12, 'NC', 'NC'], [2, 2, 2, 2, 2, 24, 24, 'NC']]
```
</details>

### Step 121: Bash

```bash
cd /tmp; docker exec -i sn-fortran-solver-parity bash -c 'cat > /w/score.py' <<'EOF'
import sys,shutil,subprocess
sys.path.insert(0,"/w")
from iters import iters
from cmp import PROD,run,cmp
from gen import gen
def build(name,files,base="/w/new"):
    d="/w/sc_"+name
    shutil.rmtree(d,ignore_errors=True); shutil.copytree(base,d)
    for fn,a,b in files:
        s=open(d+"/"+fn).read(); assert a in s,(fn,a); s=s.replace(a,b); open(d+"/"+fn,"w").write(s)
    r=subprocess.run("cd %s && gfortran -O2 -o hydro *.f"%d,shell=True,capture_output=True,text=True)
    if r.returncode: print(r.stderr[:1500])
    return d+"/hydro"
_cache={}
def suite(seeds,tols):
    out=[]
    for s in seeds:
        for t in tols:
            d="OPTION TOL %s\n"%t+gen(s)
            out.append(d)
    return out
def prodres(decks):
    key=id(decks)
    if key not in _cache:
        _cache[key]=[run(PROD,d) for d in decks]
    return _cache[key]
def score(exe,decks,verbose=False):
    P=prodres(decks); bad=0; badi=[]
    for i,(d,p) in enumerate(zip(decks,P)):
        m=run(exe,d)
        ok = (m[1]==p[1]) and cmp(p[0],m[0])[0] is None
        if not ok: bad+=1; badi.append(i)
    return bad,badi
if __name__=="__main__":
    decks=suite(range(2000,2060),["1e-4","1e-7","1e-9"])
    variants=eval(sys.argv[1])
    for k,v in variants.items():
        exe=build(k,v)
        b,bi=score(exe,decks)
        print(k,"bad",b,"of",len(decks),bi[:20])
EOF
docker exec sn-fortran-solver-parity bash -lc 'cd /w; python3 score.py "{\"base\":[]}"'
```

<details><summary>output</summary>

```
base bad 24 of 180 [0, 1, 2, 6, 7, 8, 11, 20, 25, 26, 38, 39, 40, 41, 56, 65, 74, 95, 122, 125]
```
</details>

### Step 122: Bash

```bash
cd /tmp; docker exec sn-fortran-solver-parity bash -lc 'cd /w; python3 - <<EOF
from gen import gen
from cmp import check
for s in (2000,2002,2003):
    check(gen(s),label=str(s))
open("/w/d2000.dat","w").write(gen(2000))
EOF
cat d2000.dat'
```

<details><summary>output</summary>

```
DIFF 2000 tok line 168
  P:  CONVERGED IN   2 ITERATIONS
  M:  CONVERGED IN   4 ITERATIONS
DIFF 2002 tok line 181
  P:  CONVERGED IN   6 ITERATIONS
  M:  CONVERGED IN   5 ITERATIONS
OPTION TOL 1e-2
OPTION MAXIT 10
OPTION STEPS 8
OPTION HSTEP 1.5
PATTERN pt0 1.50 1.50 2.00 0.00 1.00
PATTERN pt1 0.00 3.00 1.00 0.30 0.00 1.00
PATTERN pt2 3.00 0.30 1.00 0.30 1.20 3.00
RESERVOIR R0 105.1
JUNCTION J0 11.8 8.00 pt0
JUNCTION J1 6.4 0.00
JUNCTION J2 2.4 0.00 pt1
JUNCTION J3 11.8 3.00 pt0
JUNCTION J4 38.7 1.00 pt0
JUNCTION J5 53.8 20.00 pt2
JUNCTION J6 47.3 20.00 pt0
JUNCTION J7 3.0 7.50
JUNCTION J8 23.3 0.00 pt1
PIPE P0 R0 J0 200.0 100.00 0.5 2
PIPE P1 J0 J1 500.0 150.00 0.26
PIPE P2 R0 J2 800.0 400.00 0.26
PIPE P3 J2 J3 300.0 250.00 1.0
PIPE P4 J0 J4 500.0 300.00 1.0
PIPE P5 R0 J5 100.0 150.00 0.26
PIPE P6 J1 J6 100.0 150.00 0.1
PIPE P7 J4 J7 500.0 150.00 0.5
PIPE P8 J0 J8 1200.0 150.00 1.0
VALVE V0 J4 J1 100 0 CLOSED
VALVE V1 J7 R0 200 0 
JUNCTION ISO 10 5
END
```
</details>

### Step 123: Bash

```bash
cd /tmp; docker exec sn-fortran-solver-parity bash -lc 'cd /w; for e in /app/prod/hydro new/hydro; do $e < d2000.dat | grep -e "TIME STEP" -e CONVERGED -e "NOT CONV" | paste - - ; echo; done'
```

<details><summary>output</summary>

```
 TIME STEP  1 OF  8  AT  0:00	 CONVERGED IN   3 ITERATIONS
 TIME STEP  2 OF  8  AT  1:30	 CONVERGED IN   2 ITERATIONS
 TIME STEP  3 OF  8  AT  3:00	 CONVERGED IN   2 ITERATIONS
 TIME STEP  4 OF  8  AT  4:30	 CONVERGED IN   2 ITERATIONS
 TIME STEP  5 OF  8  AT  6:00	 CONVERGED IN   2 ITERATIONS
 TIME STEP  6 OF  8  AT  7:30	 CONVERGED IN   2 ITERATIONS
 TIME STEP  7 OF  8  AT  9:00	 CONVERGED IN   1 ITERATIONS
 TIME STEP  8 OF  8  AT 10:30	 CONVERGED IN   2 ITERATIONS

 TIME STEP  1 OF  8  AT  0:00	 CONVERGED IN   3 ITERATIONS
 TIME STEP  2 OF  8  AT  1:30	 CONVERGED IN   2 ITERATIONS
 TIME STEP  3 OF  8  AT  3:00	 CONVERGED IN   2 ITERATIONS
 TIME STEP  4 OF  8  AT  4:30	 CONVERGED IN   2 ITERATIONS
 TIME STEP  5 OF  8  AT  6:00	 CONVERGED IN   4 ITERATIONS
 TIME STEP  6 OF  8  AT  7:30	 CONVERGED IN   2 ITERATIONS
 TIME STEP  7 OF  8  AT  9:00	 CONVERGED IN   1 ITERATIONS
 TIME STEP  8 OF  8  AT 10:30	 CONVERGED IN   2 ITERATIONS
```
</details>

### Step 124: Bash

```bash
cd /tmp; docker exec sn-fortran-solver-parity bash -lc 'cd /w; python3 ddmin.py d2000.dat'
```

<details><summary>output</summary>

```
OPTION TOL 1e-2
OPTION MAXIT 10
OPTION STEPS 8
OPTION HSTEP 1.5
PATTERN pt0 1.50 1.50 2.00 0.00 1.00
PATTERN pt1 0.00 3.00 1.00 0.30 0.00 1.00
PATTERN pt2 3.00 0.30 1.00 0.30 1.20 3.00
RESERVOIR R0 105.1
JUNCTION J0 11.8 8.00 pt0
JUNCTION J1 6.4 0.00
JUNCTION J2 2.4 0.00 pt1
JUNCTION J3 11.8 3.00 pt0
JUNCTION J4 38.7 1.00 pt0
JUNCTION J5 53.8 20.00 pt2
JUNCTION J6 47.3 20.00 pt0
JUNCTION J7 3.0 7.50
JUNCTION J8 23.3 0.00 pt1
PIPE P0 R0 J0 200.0 100.00 0.5 2
PIPE P1 J0 J1 500.0 150.00 0.26
PIPE P2 R0 J2 800.0 400.00 0.26
PIPE P3 J2 J3 300.0 250.00 1.0
PIPE P4 J0 J4 500.0 300.00 1.0
PIPE P5 R0 J5 100.0 150.00 0.26
PIPE P6 J1 J6 100.0 150.00 0.1
PIPE P7 J4 J7 500.0 150.00 0.5
PIPE P8 J0 J8 1200.0 150.00 1.0
VALVE V0 J4 J1 100 0 CLOSED
VALVE V1 J7 R0 200 0 
JUNCTION ISO 10 5
END
3 3
```
</details>

### Step 125: Bash

```bash
cd /tmp; docker exec -i sn-fortran-solver-parity bash -c 'cat > /w/ddmin2.py' <<'EOF'
import sys,re
sys.path.insert(0,"/w")
from cmp import PROD,MINE,run
def seq(exe,deck):
    o,r=run(exe,deck)
    return (r,re.findall(r"CONVERGED IN\s+(\d+)|(NOT CONVERGED)",o))
def differs(deck):
    p=seq(PROD,deck); m=seq(MINE,deck)
    return p!=m
deck=open(sys.argv[1]).read().strip().split("\n")
assert differs("\n".join(deck)+"\n")
changed=True
while changed:
    changed=False
    for i in range(len(deck)):
        t=deck[:i]+deck[i+1:]
        if differs("\n".join(t)+"\n"):
            deck=t; changed=True; break
print("\n".join(deck))
print(seq(PROD,"\n".join(deck)+"\n")); print(seq(MINE,"\n".join(deck)+"\n"))
EOF
docker exec sn-fortran-solver-parity bash -lc 'cd /w; python3 ddmin2.py d2000.dat'
```

<details><summary>output</summary>

```
OPTION STEPS 8
PATTERN pt0 1.50 1.50 2.00 0.00 1.00
RESERVOIR R0 105.1
JUNCTION J0 11.8 8.00 pt0
JUNCTION J4 38.7 1.00 pt0
JUNCTION J7 3.0 7.50
PIPE P0 R0 J0 200.0 100.00 0.5 2
PIPE P4 J0 J4 500.0 300.00 1.0
PIPE P7 J4 J7 500.0 150.00 0.5
VALVE V1 J7 R0 200 0 
(0, [('6', ''), ('1', ''), ('3', ''), ('2', ''), ('5', ''), ('4', ''), ('1', ''), ('3', '')])
(0, [('6', ''), ('1', ''), ('3', ''), ('2', ''), ('6', ''), ('4', ''), ('1', ''), ('3', '')])
```
</details>

### Step 126: Bash

```bash
cd /tmp; docker exec sn-fortran-solver-parity bash -lc 'cd /w; python3 ddmin2.py d87.dat > m3.out; cat m3.out; python3 ddmin2.py d135.dat > m4.out; cat m4.out; python3 ddmin2.py d2002.dat 2>&1 | tail -20' 
```

<details><summary>output</summary>

```
JUNCTION J1 101.0 31.70
VALVE V0 J9 J1 6 0 
RESERVOIR R0 438.7
PIPE P1 R0 J1 328.0 15.75 90
JUNCTION J9 195.2 7.92
(0, [('14', '')])
(0, [('12', '')])
OPTION STEPS 8
PATTERN pt0 1.50 1.20 1.20
PATTERN pt1 1.20 1.20 1.20 0.00 1.00
RESERVOIR R0 97.0
JUNCTION J2 49.0 1.00 pt1
JUNCTION J3 43.1 1.00 pt1
JUNCTION J5 29.0 2.00 pt1
JUNCTION J7 24.2 3.00 pt0
JUNCTION J8 15.9 1.00 pt1
JUNCTION J9 41.2 7.50 pt1
JUNCTION J10 12.9 5.00 pt0
PIPE P5 R0 J5 500.0 200.00 0.05
PIPE P7 J2 J7 500.0 300.00 0.5
PIPE P8 J3 J8 500.0 200.00 1.0
PIPE P10 J7 J10 200.0 200.00 0.26
PIPE P11 J3 J8 1200.0 150.00 1.0 1
PIPE P12 J9 J2 100.0 250.00 0.26
PIPE P13 J5 J9 200.0 250.00 1.0
VALVE V0 J7 J3 200 20 
(0, [('7', ''), ('2', ''), ('1', ''), ('2', ''), ('5', ''), ('5', ''), ('2', ''), ('2', '')])
(0, [('7', ''), ('2', ''), ('1', ''), ('2', ''), ('6', ''), ('5', ''), ('2', ''), ('2', '')])
Traceback (most recent call last):
  File "/w/ddmin2.py", line 10, in <module>
    deck=open(sys.argv[1]).read().strip().split("\n")
         ^^^^^^^^^^^^^^^^^
FileNotFoundError: [Errno 2] No such file or directory: 'd2002.dat'
```
</details>

### Step 127: Bash

```bash
cd /tmp; docker exec sn-fortran-solver-parity bash -lc 'cd /w; cat > m3.dat <<EOF
UNITS US
OPTION FRICTION HW
JUNCTION J1 101.0 31.70
VALVE V0 J9 J1 6 0
RESERVOIR R0 438.7
PIPE P1 R0 J1 328.0 15.75 90
JUNCTION J9 195.2 7.92
END
EOF
python3 var4.py m3.dat x 1.0D-4 1.0D-4 1.0D0,1.0D-1,1.0D-2,1.0D-3,1.0D-4,1.0D-5,1.0D-6; cat m3.dat | ./new/hydro | head -30'
```

<details><summary>output</summary>

```
PROD [2]
1.0D-4 1.0D-4 1.0D0 [2] OK
1.0D-4 1.0D-4 1.0D-1 [2] OK
1.0D-4 1.0D-4 1.0D-2 [2] OK
1.0D-4 1.0D-4 1.0D-3 [2] OK
1.0D-4 1.0D-4 1.0D-4 [2] OK
1.0D-4 1.0D-4 1.0D-5 [2] OK
1.0D-4 1.0D-4 1.0D-6 [2] OK
 HYDRO 2.3 - STEADY-STATE PIPE NETWORK ANALYSIS
 ----------------------------------------------
 
 TITLE    : (NONE)
 UNITS    : US (FLOW GPM, LENGTH FT, DIAMETER IN)
 FRICTION : HAZEN-WILLIAMS
 NETWORK  :   3 NODES,   1 RESERVOIRS,   2 LINKS
 SOLVER   : TOL  1.0E-05, MAXIT  50
 
 CONVERGED IN   2 ITERATIONS
 
 NODE RESULTS
 ID       TYPE       ELEV    DEMAND      HEAD  PRESSURE       PSI
 -------- ----- --------- --------- --------- --------- ---------
 J1       JUNC    101.000     31.70   438.699   337.699    146.39
 J9       JUNC    195.200      7.92   438.699   243.499    105.56
 R0       RESV    438.700    -39.62   438.700     0.000      0.00
 
 LINK RESULTS
 ID       TYPE  FROM     TO            FLOW  VELOCITY  HEADLOSS  FRICTION  STATUS
 -------- ----- -------- -------- --------- --------- --------- ---------  --------
 V0       VALVE J9       J1           -7.92    -0.090     0.000            OPEN    
 P1        PIPE R0       J1           39.62     0.065     0.001            OPEN    

 TOTAL DEMAND :     39.62 GPM
 TOTAL SUPPLY :     39.62 GPM

 RUN COMPLETED WITH   0 WARNING(S)
```
</details>

### Step 128: Bash

```bash
cd /tmp; docker exec sn-fortran-solver-parity bash -lc 'cd /w; cat > m3.dat <<EOF
JUNCTION J1 101.0 31.70
VALVE V0 J9 J1 6 0 
RESERVOIR R0 438.7
PIPE P1 R0 J1 328.0 15.75 90
JUNCTION J9 195.2 7.92
EOF
cat > m2.dat <<EOF
OPTION STEPS 8
PATTERN pt0 1.50 1.50 2.00 0.00 1.00
RESERVOIR R0 105.1
JUNCTION J0 11.8 8.00 pt0
JUNCTION J4 38.7 1.00 pt0
JUNCTION J7 3.0 7.50
PIPE P0 R0 J0 200.0 100.00 0.5 2
PIPE P4 J0 J4 500.0 300.00 1.0
PIPE P7 J4 J7 500.0 150.00 0.5
VALVE V1 J7 R0 200 0 
END
EOF
cat > m4.dat <<EOF
OPTION STEPS 8
PATTERN pt0 1.50 1.20 1.20
PATTERN pt1 1.20 1.20 1.20 0.00 1.00
RESERVOIR R0 97.0
JUNCTION J2 49.0 1.00 pt1
JUNCTION J3 43.1 1.00 pt1
JUNCTION J5 29.0 2.00 pt1
JUNCTION J7 24.2 3.00 pt0
JUNCTION J8 15.9 1.00 pt1
JUNCTION J9 41.2 7.50 pt1
JUNCTION J10 12.9 5.00 pt0
PIPE P5 R0 J5 500.0 200.00 0.05
PIPE P7 J2 J7 500.0 300.00 0.5
PIPE P8 J3 J8 500.0 200.00 1.0
PIPE P10 J7 J10 200.0 200.00 0.26
PIPE P11 J3 J8 1200.0 150.00 1.0 1
PIPE P12 J9 J2 100.0 250.00 0.26
PIPE P13 J5 J9 200.0 250.00 1.0
VALVE V0 J7 J3 200 20
END
EOF
echo END >> m3.dat
for f in m1 m2 m3 m4; do python3 - <<EOF
import sys
sys.path.insert(0,"/w")
from ddmin2 import seq
EOF
done 2>/dev/null; true'
```

<details><summary>output</summary>

```
(Bash completed with no output)
```
</details>

### Step 129: Bash

```bash
cd /tmp; docker exec -i sn-fortran-solver-parity bash -c 'cat > /w/bench.py' <<'EOF'
import sys,re,shutil,subprocess,json,os
sys.path.insert(0,"/w")
from cmp import PROD,run
def seq(exe,deck):
    o,r=run(exe,deck)
    return (r,tuple(re.findall(r"CONVERGED IN\s+(\d+)|(NOT CONVERGED)",o)))
def decks():
    D=[]
    base=open("/w/m1.dat").read()
    for k in ["0","0.001","0.1","1","10"]:
        for t in ("1e-3","1e-5","1e-6","1e-7","1e-8","1e-9","1e-10","1e-12"):
            D.append("OPTION FRICTION HW\nOPTION TOL %s\n"%t+base.replace("150 0 OPEN","150 %s OPEN"%k))
            D.append("OPTION TOL %s\n"%t+base.replace("150 0 OPEN","150 %s OPEN"%k))
    for f in ["m2","m3","m4","vk0","d41","d69","d87","d2000"]:
        s=open("/w/%s.dat"%f).read()
        for t in ("1e-3","1e-5","1e-7","1e-9"):
            D.append("OPTION TOL %s\n"%t+s)
    return D
CACHE="/w/bench_prod.json"
def prodseqs(D):
    if os.path.exists(CACHE):
        c=json.load(open(CACHE))
        if len(c)==len(D): return [(a,tuple(tuple(x) for x in b)) for a,b in c]
    P=[seq(PROD,d) for d in D]
    json.dump(P,open(CACHE,"w"))
    return P
def build(name,files,base="/w/new"):
    d="/w/bn_"+name
    shutil.rmtree(d,ignore_errors=True); shutil.copytree(base,d)
    for fn,a,b in files:
        s=open(d+"/"+fn).read(); assert a in s,(fn,a); s=s.replace(a,b); open(d+"/"+fn,"w").write(s)
    r=subprocess.run("cd %s && gfortran -O2 -o hydro *.f"%d,shell=True,capture_output=True,text=True)
    if r.returncode: print(r.stderr[:1500])
    return d+"/hydro"
def score(exe,D,P):
    bad=[i for i,(d,p) in enumerate(zip(D,P)) if seq(exe,d)!=p]
    return len(bad),bad
if __name__=="__main__":
    D=decks(); P=prodseqs(D)
    variants=eval(sys.argv[1]) if len(sys.argv)>1 else {"base":[]}
    for k,v in variants.items():
        exe=build(k,v); n,bad=score(exe,D,P)
        print(k,"bad",n,"of",len(D),bad[:30])
EOF
docker exec sn-fortran-solver-parity bash -lc 'cd /w; for f in vk0 d41 d69 d87 d2000; do ls $f.dat; done; python3 bench.py'
```

<details><summary>output</summary>

```
vk0.dat
d41.dat
d69.dat
d87.dat
d2000.dat
base bad 37 of 112 [9, 26, 27, 41, 42, 43, 45, 56, 58, 59, 73, 74, 76, 80, 81, 82, 83, 84, 85, 87, 89, 91, 95, 98, 99, 100, 101, 102, 103, 104]
```
</details>

### Step 130: Bash

```bash
cd /tmp; cat > /tmp/vv.py <<'PYEOF'
vs_old="         R = XK(L)/(2.0D0*GRAV*A*A)\n         H = R*Q*ABS(Q)\n         GR = 2.0D0*R*ABS(Q)"
valve_b="         V = Q/A\n         H = XK(L)*V*ABS(V)/(2.0D0*GRAV)\n         GR = 2.0D0*XK(L)*ABS(V)/(2.0D0*GRAV*A)"
valve_c="         V = Q/A\n         H = XK(L)*V*ABS(V)/(2.0D0*GRAV)\n         GR = 2.0D0*XK(L)/(2.0D0*GRAV*A*A)*ABS(Q)"
valve_e="         V = Q/A\n         R = XK(L)/(2.0D0*GRAV*A*A)\n         H = XK(L)*V*ABS(V)/(2.0D0*GRAV)\n         GR = 2.0D0*R*ABS(Q)"
d={"base":[],
"vb":[("solve.f",vs_old,valve_b)],
"vc":[("solve.f",vs_old,valve_c)],
"ve":[("solve.f",vs_old,valve_e)],
}
open("/w/vv.txt","w").write(repr(d))
PYEOF
docker exec -i sn-fortran-solver-parity python3 - < /tmp/vv.py
docker exec sn-fortran-solver-parity bash -lc 'cd /w; python3 bench.py "$(cat vv.txt)"'
```

<details><summary>output</summary>

```
base bad 37 of 112 [9, 26, 27, 41, 42, 43, 45, 56, 58, 59, 73, 74, 76, 80, 81, 82, 83, 84, 85, 87, 89, 91, 95, 98, 99, 100, 101, 102, 103, 104]
vb bad 36 of 112 [9, 25, 27, 41, 43, 45, 58, 59, 74, 75, 76, 77, 80, 81, 82, 83, 84, 85, 87, 89, 91, 95, 98, 99, 100, 101, 102, 103, 104, 105]
vc bad 34 of 112 [9, 26, 27, 41, 43, 45, 58, 59, 75, 76, 80, 81, 82, 83, 84, 85, 87, 89, 91, 95, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107]
ve bad 34 of 112 [9, 26, 27, 41, 43, 45, 58, 59, 75, 76, 80, 81, 82, 83, 84, 85, 87, 89, 91, 95, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107]
```
</details>

### Step 131: Bash

```bash
cd /tmp; docker exec sn-fortran-solver-parity bash -lc 'cd /w; python3 - <<EOF
import sys
sys.path.insert(0,"/w")
from bench import *
D=decks();P=prodseqs(D)
for i in range(80,112):
    m=seq("/w/new/hydro",D[i])
    if m!=P[i]: print(i,D[i].split("\n")[0], [x[0] or x[1] for x in P[i][1]], [x[0] or x[1] for x in m[1]])
EOF'
```

<details><summary>output</summary>

```
80 OPTION TOL 1e-3 ['5', '1', '2', '2', '3', '2', '1', '2'] ['5', '1', '2', '2', '5', '2', '1', '2']
81 OPTION TOL 1e-5 ['6', '1', '3', '2', '5', '4', '1', '3'] ['6', '1', '3', '2', '6', '4', '1', '3']
82 OPTION TOL 1e-7 ['7', '1', '5', '3', '6', '5', '1', '5'] ['7', '1', '5', '3', '8', '5', '1', '5']
83 OPTION TOL 1e-9 ['NOT CONVERGED', 'NOT CONVERGED', 'NOT CONVERGED', 'NOT CONVERGED', '7', 'NOT CONVERGED', 'NOT CONVERGED', 'NOT CONVERGED'] ['NOT CONVERGED', 'NOT CONVERGED', 'NOT CONVERGED', '5', '9', 'NOT CONVERGED', 'NOT CONVERGED', 'NOT CONVERGED']
84 OPTION TOL 1e-3 ['6'] ['7']
85 OPTION TOL 1e-5 ['14'] ['12']
87 OPTION TOL 1e-9 ['29'] ['26']
89 OPTION TOL 1e-5 ['7', '2', '1', '2', '5', '5', '2', '2'] ['7', '2', '1', '2', '6', '5', '2', '2']
91 OPTION TOL 1e-9 ['13', '2', '1', '2', '10', '10', '2', '2'] ['13', '2', '1', '6', '11', '10', '2', '2']
95 OPTION TOL 1e-9 ['6'] ['26']
98 OPTION TOL 1e-7 ['14'] ['17']
99 OPTION TOL 1e-9 ['20'] ['NOT CONVERGED']
100 OPTION TOL 1e-3 ['17'] ['19']
101 OPTION TOL 1e-5 ['17'] ['19']
102 OPTION TOL 1e-7 ['17'] ['19']
103 OPTION TOL 1e-9 ['17'] ['19']
104 OPTION TOL 1e-3 ['15'] ['21']
105 OPTION TOL 1e-5 ['15'] ['21']
106 OPTION TOL 1e-7 ['15'] ['21']
107 OPTION TOL 1e-9 ['15'] ['21']
108 OPTION TOL 1e-3 ['3', '2', '2', '2', '2', '2', '1', '2'] ['3', '2', '2', '2', '4', '2', '1', '2']
109 OPTION TOL 1e-5 ['3', '2', '2', '2', '2', '2', '1', '2'] ['3', '2', '2', '2', '4', '2', '1', '2']
110 OPTION TOL 1e-7 ['3', '2', '2', '2', '2', '2', '1', '2'] ['3', '2', '2', '2', '4', '2', '1', '2']
111 OPTION TOL 1e-9 ['3', '2', '2', '2', '2', '2', '1', '2'] ['3', '2', '2', '2', '4', '2', '1', '2']
```
</details>

### Step 132: Bash

```bash
cd /tmp; cat > /tmp/vv.py <<'PYEOF'
def inc(gp,gu,gv):
    return ("hydro.inc","GMINP=1.0D-4, GMINU=1.0D-4,\n     &           GMINV=1.0D-4","GMINP=%s, GMINU=%s,\n     &           GMINV=%s"%(gp,gu,gv))
d={}
for gp in ["1.0D-2","1.0D-3","3.0D-4","1.0D-4"]:
    for gv in ["1.0D-4","1.0D-3"]:
        d["p%s_v%s"%(gp[-1],gv[-1])]=[inc(gp,"1.0D-4",gv)]
open("/w/vv.txt","w").write(repr(d))
PYEOF
docker exec -i sn-fortran-solver-parity python3 - < /tmp/vv.py
docker exec sn-fortran-solver-parity bash -lc 'cd /w; python3 bench.py "$(cat vv.txt)"'
```

<details><summary>output</summary>

```
p2_v4 bad 36 of 112 [9, 26, 27, 41, 42, 43, 45, 56, 58, 59, 73, 74, 76, 80, 81, 82, 83, 84, 85, 87, 89, 91, 95, 99, 100, 101, 102, 103, 104, 105]
p2_v3 bad 38 of 112 [8, 10, 11, 27, 41, 42, 43, 45, 56, 58, 59, 73, 74, 76, 80, 81, 82, 83, 84, 85, 86, 87, 89, 91, 95, 99, 100, 101, 102, 103]
p3_v4 bad 36 of 112 [9, 26, 27, 41, 42, 43, 45, 56, 58, 59, 73, 74, 76, 80, 81, 82, 83, 84, 85, 87, 89, 91, 95, 99, 100, 101, 102, 103, 104, 105]
p3_v3 bad 38 of 112 [8, 10, 11, 27, 41, 42, 43, 45, 56, 58, 59, 73, 74, 76, 80, 81, 82, 83, 84, 85, 86, 87, 89, 91, 95, 99, 100, 101, 102, 103]
p4_v4 bad 37 of 112 [9, 26, 27, 41, 42, 43, 45, 56, 58, 59, 73, 74, 76, 80, 81, 82, 83, 84, 85, 87, 89, 91, 95, 98, 99, 100, 101, 102, 103, 104]
p4_v3 bad 35 of 112 [8, 10, 11, 27, 41, 42, 43, 45, 56, 58, 59, 73, 74, 76, 80, 81, 82, 83, 84, 85, 86, 87, 89, 91, 95, 98, 99, 104, 105, 106]
```
</details>

### Step 133: Bash

```bash
cd /tmp; grep -n "SUBROUTINE START" -B3 -A22 /dev/null; docker exec sn-fortran-solver-parity bash -lc 'cd /w; sed -n 40,75p new/solve.f'
```

<details><summary>output</summary>

```
      IMPLICIT NONE
      INCLUDE 'hydro.inc'
      INTEGER L
      DO 10 L = 1, NL
         IF (LTYP(L) .EQ. 2) THEN
            QL(L) = 0.03D0
            IF (PQ(L) .GT. 0.0D0) QL(L) = PQ(L)/2.0D0
         ELSE
            QL(L) = 0.3048D0*PI*DI(L)**2/4.0D0
         ENDIF
         IF (LACT(L) .EQ. 0) QL(L) = 0.0D0
   10 CONTINUE
      DO 20 L = 1, NN
         HN(L) = ZN(L)
   20 CONTINUE
      RETURN
      END
C
C     SETDEM  -  DEMANDS FOR TIME STEP ISTEP
C
      SUBROUTINE SETDEM(ISTEP)
      IMPLICIT NONE
      INCLUDE 'hydro.inc'
      INTEGER ISTEP, I, K
      DO 10 I = 1, NN
         QD(I) = QB(I)
         IF (NPAT(I) .GT. 0) THEN
            K = NPAT(I)
            QD(I) = QB(I)*PVAL(MOD(ISTEP-1, PLEN(K)) + 1, K)
         ENDIF
   10 CONTINUE
      RETURN
      END
C
C     GGA  -  ITERATE UNTIL THE RELATIVE FLOW CHANGE IS BELOW TOL
C
```
</details>

### Step 134: Bash

```bash
cd /tmp; cat > /tmp/vv.py <<'PYEOF'
a="      CONVRG = .FALSE.\n      NITER = 0\n"
b="""      CONVRG = .FALSE.
      NITER = 0
      DO 17 L = 1, NL
         IF (LACT(L) .EQ. 1 .AND. LTYP(L) .NE. 2) THEN
            IF (ABS(QL(L)) .LT. QZERO)
     &         QL(L) = 0.3048D0*PI*DI(L)**2/4.0D0
         ENDIF
   17 CONTINUE
"""
b2="""      CONVRG = .FALSE.
      NITER = 0
      DO 17 L = 1, NL
         IF (LACT(L) .EQ. 1 .AND. LTYP(L) .NE. 2) THEN
            IF (ABS(QL(L)) .LT. QZERO)
     &         QL(L) = 0.3048D0*PI*DI(L)**2/4.0D0
         ELSE IF (LACT(L) .EQ. 1) THEN
            IF (ABS(QL(L)) .LT. QZERO) THEN
               QL(L) = 0.03D0
               IF (PQ(L) .GT. 0.0D0) QL(L) = PQ(L)/2.0D0
            ENDIF
         ENDIF
   17 CONTINUE
"""
d={"reset":[("solve.f",a,b)],"reset2":[("solve.f",a,b2)]}
open("/w/vv.txt","w").write(repr(d))
PYEOF
docker exec -i sn-fortran-solver-parity python3 - < /tmp/vv.py
docker exec sn-fortran-solver-parity bash -lc 'cd /w; python3 bench.py "$(cat vv.txt)"'
```

<details><summary>output</summary>

```
reset bad 39 of 112 [9, 26, 27, 41, 42, 43, 45, 56, 58, 59, 73, 74, 76, 80, 81, 82, 83, 84, 85, 87, 88, 89, 90, 91, 95, 98, 99, 100, 101, 102]
reset2 bad 39 of 112 [9, 26, 27, 41, 42, 43, 45, 56, 58, 59, 73, 74, 76, 80, 81, 82, 83, 84, 85, 87, 88, 89, 90, 91, 95, 98, 99, 100, 101, 102]
```
</details>

### Step 135: Bash

```bash
cd /tmp; docker exec -i sn-fortran-solver-parity bash -c 'cat > /w/z1.py' <<'EOF'
import sys
sys.path.insert(0,"/w")
from bench import seq
from cmp import PROD,MINE
for q in [0.5,1,5,20,100]:
  for D in [100,300]:
    for tol in ["1e-3","1e-6"]:
        d="OPTION TOL %s\nOPTION STEPS 4\nPATTERN pt 1 0 1 0\nRESERVOIR R 100\nJUNCTION a 10 %g pt\nPIPE p R a 500 %d 0.1\nEND\n"%(tol,q,D)
        p=[x[0] or x[1] for x in seq(PROD,d)[1]]; m=[x[0] or x[1] for x in seq(MINE,d)[1]]
        print(q,D,tol,p,m,"" if p==m else "<<")
EOF
docker exec sn-fortran-solver-parity bash -lc 'cd /w; python3 z1.py'
```

<details><summary>output</summary>

```
0.5 100 1e-3 ['2', '2', '2', '2'] ['2', '2', '2', '2'] 
0.5 100 1e-6 ['2', '2', '2', '2'] ['2', '2', '2', '2'] 
0.5 300 1e-3 ['2', '2', '2', '2'] ['2', '2', '2', '2'] 
0.5 300 1e-6 ['2', '2', '2', '2'] ['2', '2', '2', '2'] 
1 100 1e-3 ['2', '2', '2', '2'] ['2', '2', '2', '2'] 
1 100 1e-6 ['2', '2', '2', '2'] ['2', '2', '2', '2'] 
1 300 1e-3 ['2', '2', '2', '2'] ['2', '2', '2', '2'] 
1 300 1e-6 ['2', '2', '2', '2'] ['2', '2', '2', '2'] 
5 100 1e-3 ['2', '2', '2', '2'] ['2', '2', '2', '2'] 
5 100 1e-6 ['2', '2', '2', '2'] ['2', '2', '2', '2'] 
5 300 1e-3 ['2', '2', '2', '2'] ['2', '2', '2', '2'] 
5 300 1e-6 ['2', '2', '2', '2'] ['2', '2', '2', '2'] 
20 100 1e-3 ['2', '2', '2', '2'] ['2', '2', '2', '2'] 
20 100 1e-6 ['2', '2', '2', '2'] ['2', '2', '2', '2'] 
20 300 1e-3 ['2', '2', '2', '2'] ['2', '2', '2', '2'] 
20 300 1e-6 ['2', '2', '2', '2'] ['2', '2', '2', '2'] 
100 100 1e-3 ['2', '2', '2', '2'] ['2', '2', '2', '2'] 
100 100 1e-6 ['2', '2', '2', '2'] ['2', '2', '2', '2'] 
100 300 1e-3 ['2', '2', '2', '2'] ['2', '2', '2', '2'] 
100 300 1e-6 ['2', '2', '2', '2'] ['2', '2', '2', '2']
```
</details>

### Step 136: Bash

```bash
cd /tmp; docker exec sn-fortran-solver-parity bash -lc 'cd /w; rm -rf dbg; cp -r new dbg; cd dbg; python3 - <<EOF
s=open("solve.f").read()
s=s.replace("         IF (SQ .GT. 1.0D-30) THEN","         WRITE (0,*) IT, (QL(L),L=1,NL), SDQ/SQ\n         IF (SQ .GT. 1.0D-30) THEN")
s=s.replace("      CONVRG = .FALSE.\n      NITER = 0\n","      CONVRG = .FALSE.\n      NITER = 0\n      WRITE (0,*) \"START\", (QL(L),L=1,NL)\n")
open("solve.f","w").write(s)
EOF
gfortran -O2 -o hydro *.f && (echo "OPTION TOL 1e-3"; cat ../m2.dat) | ./hydro 2>&1 >/dev/null | sed -n 1,60p'
```

<details><summary>output</summary>

```
 START   2.3938936020354226E-003   2.1545042418318800E-002   5.3862606045797000E-003   9.5755744081416905E-003
           1   7.7326974130313393E-003  -4.2673025869684536E-003  -5.7673025869687082E-003  -1.3267302479665816E-002   2.0991918136467622     
           2   5.1210513848960956E-003  -6.8789486151041093E-003  -8.3789486151022510E-003  -1.5878948490229888E-002  0.28811886317125007     
           3   4.7544203303189576E-003  -7.2455796696814356E-003  -8.7455796696812218E-003  -1.6245579731152177E-002   3.9645267366847314E-002
           4   4.7389366244451163E-003  -7.2610633755534519E-003  -8.7610633755536519E-003  -1.6261063594232766E-002   1.6729179484859110E-003
           5   4.7385329909273152E-003  -7.2614670090710145E-003  -8.7614670090698822E-003  -1.6261466898289584E-002   4.3600126679604363E-005
 START   4.7385329909273152E-003  -7.2614670090710145E-003  -8.7614670090698822E-003  -1.6261466898289584E-002
           1   4.7385227500185822E-003  -7.2614772499785618E-003  -8.7614772499797350E-003  -1.6261477414322073E-002   1.1138700029827105E-006
 START   4.7385227500185822E-003  -7.2614772499785618E-003  -8.7614772499797350E-003  -1.6261477414322073E-002
           1   6.3180302642974299E-003  -9.6819697357021419E-003  -1.1681969735700449E-002  -1.9181969635714197E-002  0.20999055647289463     
           2   6.3132717764771366E-003  -9.6867282235219617E-003  -1.1686728223523195E-002  -1.9186728424632676E-002   4.0607742083575103E-004
 START   6.3132717764771366E-003  -9.6867282235219617E-003  -1.1686728223523195E-002  -1.9186728424632676E-002
           1   9.6382189748895531E-008   9.6382188918481198E-008   9.6382190426145555E-008  -7.4999036900079974E-003   5.2496849345417314     
           2   0.0000000000000000        0.0000000000000000        0.0000000000000000       -7.5000000396029665E-003   5.1399488270269283E-005
 START   0.0000000000000000        0.0000000000000000        0.0000000000000000       -7.5000000396029665E-003
           1   6.5000000404324965E-003  -1.4999999109477358E-003  -2.4999999936881068E-003  -1.0000000175399620E-002  0.63414634168149642     
           2   3.7566418915620028E-003  -4.2433581084406948E-003  -5.2433581084444323E-003  -1.2743358071806071E-002  0.42227083566121087     
           3   3.2040847392371002E-003  -4.7959152607605880E-003  -5.7959152607624841E-003  -1.3295915609309233E-002   8.1582858134103931E-002
           4   3.1647181784377931E-003  -4.8352818215635857E-003  -5.8352818215639899E-003  -1.3335281524281456E-002   5.7954483818276285E-003
           5   3.1632697681414188E-003  -4.8367302318584431E-003  -5.8367302318582262E-003  -1.3336730178811124E-002   2.1321853483411698E-004
 START   3.1632697681414188E-003  -4.8367302318584431E-003  -5.8367302318582262E-003  -1.3336730178811124E-002
           1   4.7448060626517560E-003  -7.2551939373478895E-003  -8.7551939373462593E-003  -1.6255194084909746E-002  0.26578828640410762     
           2   4.7386835247224266E-003  -7.261
... [747 more chars truncated]
```
</details>

### Step 137: Bash

```bash
cd /tmp; cat > /tmp/vv.py <<'PYEOF'
z="""               IF (LTYP(L) .NE. 2 .AND. ABS(QL(L)) .LT. QZERO .AND.
     &            ABS(QNEW) .LT. QZERO) QNEW = 0.0D0
"""
a="      CONVRG = .FALSE.\n      NITER = 0\n"
b="""      CONVRG = .FALSE.
      NITER = 0
      DO 17 L = 1, NL
         IF (LACT(L) .EQ. 1 .AND. LTYP(L) .NE. 2) THEN
            IF (ABS(QL(L)) .LT. QZERO)
     &         QL(L) = 0.3048D0*PI*DI(L)**2/4.0D0
         ENDIF
   17 CONTINUE
"""
d={"base":[],"reset":[("solve.f",a,b)],"nozero":[("solve.f",z,"")],
"z7":[("solve.f",z,z.replace("QZERO","1.0D-7"))],"z8":[("solve.f",z,z.replace("QZERO","1.0D-8"))]}
open("/w/vv.txt","w").write(repr(d))
PYEOF
docker exec -i sn-fortran-solver-parity python3 - < /tmp/vv.py
docker exec -i sn-fortran-solver-parity bash -c 'cat > /w/showm2.py' <<'EOF'
import sys
sys.path.insert(0,"/w")
from bench import *
vs=eval(open("/w/vv.txt").read())
decks=[open("/w/%s.dat"%f).read() for f in sys.argv[1].split(",")]
for tol in sys.argv[2].split(","):
  print("TOL",tol)
  for d in decks:
    dd="OPTION TOL %s\n"%tol+d
    print(" PROD",[x[0] or x[1] for x in seq(PROD,dd)[1]])
    for k,v in vs.items():
        exe=build(k,v)
        print(" %-8s"%k,[x[0] or x[1] for x in seq(exe,dd)[1]])
EOF
docker exec sn-fortran-solver-parity bash -lc 'cd /w; python3 showm2.py m2 1e-3,1e-5'
```

<details><summary>output</summary>

```
TOL 1e-3
 PROD ['5', '1', '2', '2', '3', '2', '1', '2']
 base     ['5', '1', '2', '2', '5', '2', '1', '2']
 reset    ['5', '1', '2', '2', '5', '2', '1', '2']
 nozero   ['5', '1', '2', '2', '3', '2', '1', '2']
 z7       ['5', '1', '2', '2', '5', '2', '1', '2']
 z8       ['5', '1', '2', '2', '3', '2', '1', '2']
TOL 1e-5
 PROD ['6', '1', '3', '2', '5', '4', '1', '3']
 base     ['6', '1', '3', '2', '6', '4', '1', '3']
 reset    ['6', '1', '3', '2', '6', '4', '1', '3']
 nozero   ['6', '1', '3', '2', '6', '4', '1', '3']
 z7       ['6', '1', '3', '2', '6', '4', '1', '3']
 z8       ['6', '1', '3', '2', '6', '4', '1', '3']
```
</details>

### Step 138: Bash

```bash
cd /tmp; docker exec -i sn-fortran-solver-parity bash -c 'cat > /w/z2.py' <<'EOF'
import sys,itertools
sys.path.insert(0,"/w")
from bench import *
def decks():
    D=[]
    for fr in ["DW","HW"]:
      for q in [1,5]:
        for (d3,d4) in [(150,300),(100,100),(200,50)]:
          for tol in ["1e-3","1e-5","1e-7","1e-9"]:
            rough="0.1" if fr=="DW" else "100"
            D.append("OPTION FRICTION %s\nOPTION TOL %s\nRESERVOIR R 100\nJUNCTION J1 10 %g\nJUNCTION J3 12 0\nPIPE P1 R J1 200 200 %s\nPIPE P3 J1 J3 500 %d %s\nPIPE P4 J3 J1 500 %d %s\nEND\n"%(fr,tol,q,rough,d3,rough,d4,rough))
    return D
D=decks()
P=[seq(PROD,d) for d in D]
if __name__=="__main__":
    vs=eval(sys.argv[1]) if len(sys.argv)>1 else {"base":[]}
    for k,v in vs.items():
        exe=build(k,v); M=[seq(exe,d) for d in D]
        bad=[i for i in range(len(D)) if M[i]!=P[i]]
        print(k,"bad",len(bad),"of",len(D),bad)
        if len(sys.argv)>2:
            for i in bad[:int(sys.argv[2])]: print(i,D[i].split("\n")[:2],[x[0] or x[1] for x in P[i][1]],[x[0] or x[1] for x in M[i][1]])
EOF
docker exec sn-fortran-solver-parity bash -lc 'cd /w; python3 z2.py "$(cat vv.txt)" 6'
```

<details><summary>output</summary>

```
base bad 15 of 48 [3, 6, 7, 10, 11, 19, 23, 26, 27, 30, 31, 35, 39, 43, 47]
3 ['OPTION FRICTION DW', 'OPTION TOL 1e-9'] ['7'] ['NOT CONVERGED']
6 ['OPTION FRICTION DW', 'OPTION TOL 1e-7'] ['6'] ['11']
7 ['OPTION FRICTION DW', 'OPTION TOL 1e-9'] ['6'] ['NOT CONVERGED']
10 ['OPTION FRICTION DW', 'OPTION TOL 1e-7'] ['6'] ['8']
11 ['OPTION FRICTION DW', 'OPTION TOL 1e-9'] ['6'] ['NOT CONVERGED']
19 ['OPTION FRICTION DW', 'OPTION TOL 1e-9'] ['6'] ['21']
reset bad 15 of 48 [3, 6, 7, 10, 11, 19, 23, 26, 27, 30, 31, 35, 39, 43, 47]
3 ['OPTION FRICTION DW', 'OPTION TOL 1e-9'] ['7'] ['NOT CONVERGED']
6 ['OPTION FRICTION DW', 'OPTION TOL 1e-7'] ['6'] ['11']
7 ['OPTION FRICTION DW', 'OPTION TOL 1e-9'] ['6'] ['NOT CONVERGED']
10 ['OPTION FRICTION DW', 'OPTION TOL 1e-7'] ['6'] ['8']
11 ['OPTION FRICTION DW', 'OPTION TOL 1e-9'] ['6'] ['NOT CONVERGED']
19 ['OPTION FRICTION DW', 'OPTION TOL 1e-9'] ['6'] ['21']
nozero bad 27 of 48 [3, 6, 7, 10, 11, 19, 23, 24, 25, 26, 27, 29, 30, 31, 32, 33, 34, 35, 37, 38, 39, 41, 42, 43, 45, 46, 47]
3 ['OPTION FRICTION DW', 'OPTION TOL 1e-9'] ['7'] ['NOT CONVERGED']
6 ['OPTION FRICTION DW', 'OPTION TOL 1e-7'] ['6'] ['15']
7 ['OPTION FRICTION DW', 'OPTION TOL 1e-9'] ['6'] ['NOT CONVERGED']
10 ['OPTION FRICTION DW', 'OPTION TOL 1e-7'] ['6'] ['8']
11 ['OPTION FRICTION DW', 'OPTION TOL 1e-9'] ['6'] ['NOT CONVERGED']
19 ['OPTION FRICTION DW', 'OPTION TOL 1e-9'] ['6'] ['12']
z7 bad 27 of 48 [3, 6, 7, 10, 11, 19, 23, 24, 25, 26, 27, 29, 30, 31, 32, 33, 34, 35, 37, 38, 39, 41, 42, 43, 45, 46, 47]
3 ['OPTION FRICTION DW', 'OPTION TOL 1e-9'] ['7'] ['NOT CONVERGED']
6 ['OPTION FRICTION DW', 'OPTION TOL 1e-7'] ['6'] ['11']
7 ['OPTION FRICTION DW', 'OPTION TOL 1e-9'] ['6'] ['NOT CONVERGED']
10 ['OPTION FRICTION DW', 'OPTION TOL 1e-7'] ['6'] ['8']
11 ['OPTION FRICTION DW', 'OPTION TOL 1e-9'] ['6'] ['NOT CONVERGED']
19 ['OPTION FRICTION DW', 'OPTION TOL 1e-9'] ['6'] ['21']
z8 bad 27 of 48 [3, 6, 7, 10, 11, 19, 23, 24, 25, 26, 27, 29, 30, 31, 32, 33, 34, 35, 37, 38, 39, 41, 42, 43, 45, 46, 47]
3 ['OPTION FRICTION DW', 'OPTION TOL 1e-9'] ['7'] ['NOT CONVERGED']
6 ['OPTION FRICTION DW', 'OPTION TOL 1e-7'] ['6'] ['11']
7 ['OPTION FRICTION DW', 'OPTION TOL 1e-9'] ['6'] ['NOT CONVERGED']
10 ['OPTION FRICTION DW', 'OPTION TOL 1e-7'] ['6'] ['8']
11 ['OPTION FRICTION DW', 'OPTION TOL 1e-9'] ['6'] ['NOT CONVERGED']
19 ['OPTION FRICTION DW', 'OPTION TOL 1e-9'] ['6'] ['21']
```
</details>

### Step 139: Bash

```bash
cd /tmp; cat > /tmp/vv.py <<'PYEOF'
old="""            R = F*XL(L)/(DI(L)*2.0D0*GRAV*A*A) + RK
            H = R*Q*ABS(Q)
            IF (RE .LT. 2000.0D0) THEN
               GR = F*XL(L)/(DI(L)*2.0D0*GRAV*A*A)*ABS(Q)
               GR = GR + 2.0D0*RK*ABS(Q)
            ELSE"""
new="""            R = F*XL(L)/(DI(L)*2.0D0*GRAV*A*A) + RK
            H = R*Q*ABS(Q)
            IF (RE .LT. 2000.0D0) THEN
               R0 = 32.0D0*VISC*XL(L)/(GRAV*DI(L)**2*A)
               H = R0*Q + RK*Q*ABS(Q)
               GR = R0 + 2.0D0*RK*ABS(Q)
            ELSE"""
d={"lam":[("solve.f",old,new),("solve.f","DOUBLE PRECISION Q, H, GR, A, V, RE, R, F, S, RK, HR","DOUBLE PRECISION Q, H, GR, A, V, RE, R, F, S, RK, HR, R0")]}
open("/w/vv.txt","w").write(repr(d))
PYEOF
docker exec -i sn-fortran-solver-parity python3 - < /tmp/vv.py
docker exec sn-fortran-solver-parity bash -lc 'cd /w; python3 z2.py "$(cat vv.txt)" 8'
```

<details><summary>output</summary>

```
lam bad 8 of 48 [26, 27, 30, 31, 35, 39, 43, 47]
26 ['OPTION FRICTION HW', 'OPTION TOL 1e-7'] ['14'] ['15']
27 ['OPTION FRICTION HW', 'OPTION TOL 1e-9'] ['25'] ['NOT CONVERGED']
30 ['OPTION FRICTION HW', 'OPTION TOL 1e-7'] ['13'] ['15']
31 ['OPTION FRICTION HW', 'OPTION TOL 1e-9'] ['13'] ['NOT CONVERGED']
35 ['OPTION FRICTION HW', 'OPTION TOL 1e-9'] ['11'] ['NOT CONVERGED']
39 ['OPTION FRICTION HW', 'OPTION TOL 1e-9'] ['14'] ['NOT CONVERGED']
43 ['OPTION FRICTION HW', 'OPTION TOL 1e-9'] ['13'] ['NOT CONVERGED']
47 ['OPTION FRICTION HW', 'OPTION TOL 1e-9'] ['11'] ['37']
```
</details>

### Step 140: Bash

```bash
cd /tmp; cat > /tmp/ed10.py <<'PYEOF'
s=open("/w/new/solve.f").read()
old="""            R = F*XL(L)/(DI(L)*2.0D0*GRAV*A*A) + RK
            H = R*Q*ABS(Q)
            IF (RE .LT. 2000.0D0) THEN
               GR = F*XL(L)/(DI(L)*2.0D0*GRAV*A*A)*ABS(Q)
               GR = GR + 2.0D0*RK*ABS(Q)
            ELSE"""
new="""            R = F*XL(L)/(DI(L)*2.0D0*GRAV*A*A) + RK
            H = R*Q*ABS(Q)
            IF (RE .LT. 2000.0D0) THEN
               R0 = 32.0D0*VISC*XL(L)/(GRAV*DI(L)**2*A)
               H = R0*Q + RK*Q*ABS(Q)
               GR = R0 + 2.0D0*RK*ABS(Q)
            ELSE"""
assert old in s
s=s.replace(old,new)
s=s.replace("DOUBLE PRECISION Q, H, GR, A, V, RE, R, F, S, RK, HR","DOUBLE PRECISION Q, H, GR, A, V, RE, R, F, S, RK, HR, R0")
open("/w/new/solve.f","w").write(s)
PYEOF
docker exec -i sn-fortran-solver-parity python3 - < /tmp/ed10.py
cat > /tmp/vv.py <<'PYEOF'
def inc(gp,gu,gv):
    return ("hydro.inc","GMINP=1.0D-4, GMINU=1.0D-4,\n     &           GMINV=1.0D-4","GMINP=%s, GMINU=%s,\n     &           GMINV=%s"%(gp,gu,gv))
z="""               IF (LTYP(L) .NE. 2 .AND. ABS(QL(L)) .LT. QZERO .AND.
     &            ABS(QNEW) .LT. QZERO) QNEW = 0.0D0
"""
d={"base":[]}
for gp in ["1.0D-2","1.0D-3","1.0D-5","1.0D-6"]:
    d["gp"+gp[-1]]=[inc(gp,"1.0D-4","1.0D-4")]
d["nozero"]=[("solve.f",z,"")]
d["z-"]=[("solve.f",z,z.replace(".AND.\n     &            ABS(QNEW) .LT. QZERO",".AND.\n     &            ABS(QNEW) .LT. 1.0D-5"))]
open("/w/vv.txt","w").write(repr(d))
PYEOF
docker exec -i sn-fortran-solver-parity python3 - < /tmp/vv.py
docker exec sn-fortran-solver-parity bash -lc 'cd /w/new; gfortran -O2 -o hydro *.f; cd /w; python3 z2.py "$(cat vv.txt)" 0'
```

<details><summary>output</summary>

```
base bad 8 of 48 [26, 27, 30, 31, 35, 39, 43, 47]
gp2 bad 2 of 48 [27, 35]
gp3 bad 3 of 48 [27, 31, 47]
gp5 bad 12 of 48 [26, 27, 30, 31, 34, 35, 38, 39, 42, 43, 46, 47]
gp6 bad 14 of 48 [25, 26, 27, 30, 31, 33, 34, 35, 38, 39, 42, 43, 46, 47]
nozero bad 20 of 48 [24, 25, 26, 27, 29, 30, 31, 32, 33, 34, 35, 37, 38, 39, 41, 42, 43, 45, 46, 47]
z- bad 8 of 48 [26, 27, 30, 31, 35, 39, 43, 47]
```
</details>

### Step 141: Bash

```bash
cd /tmp; cat > /tmp/vv.py <<'PYEOF'
def inc(gp,gu,gv):
    return ("hydro.inc","GMINP=1.0D-4, GMINU=1.0D-4,\n     &           GMINV=1.0D-4","GMINP=%s, GMINU=%s,\n     &           GMINV=%s"%(gp,gu,gv))
d={}
for gp in ["1.0D-2","2.0D-2","5.0D-3","3.0D-2","5.0D-2","1.0D-1","1.0D0"]:
    d["gp"+gp]=[inc(gp,"1.0D-4","1.0D-4")]
open("/w/vv.txt","w").write(repr(d))
PYEOF
docker exec -i sn-fortran-solver-parity python3 - < /tmp/vv.py
docker exec sn-fortran-solver-parity bash -lc 'cd /w; python3 z2.py "$(cat vv.txt)" 0'
```

<details><summary>output</summary>

```
gp1.0D-2 bad 2 of 48 [27, 35]
gp2.0D-2 bad 1 of 48 [27]
gp5.0D-3 bad 2 of 48 [27, 35]
gp3.0D-2 bad 1 of 48 [27]
gp5.0D-2 bad 1 of 48 [27]
gp1.0D-1 bad 7 of 48 [24, 25, 26, 27, 37, 38, 39]
gp1.0D0 bad 15 of 48 [0, 1, 2, 3, 12, 13, 14, 15, 24, 25, 26, 27, 37, 38, 39]
```
</details>

### Step 142: Bash

```bash
cd /tmp; cat > /tmp/vv.py <<'PYEOF'
def inc(gp,gu,gv):
    return ("hydro.inc","GMINP=1.0D-4, GMINU=1.0D-4,\n     &           GMINV=1.0D-4","GMINP=%s, GMINU=%s,\n     &           GMINV=%s"%(gp,gu,gv))
fl="""      ELSE
         IF (GR .LT. GMINP) GR = GMINP
      ENDIF"""
fl2="""      ELSE
         IF (GR .LT. GMINP) THEN
            GR = GMINP
            H = GR*Q
         ENDIF
      ENDIF"""
d={}
for gp in ["1.0D-3","1.0D-2","3.0D-2","1.0D-1"]:
    d["lin"+gp]=[inc(gp,"1.0D-4","1.0D-4"),("solve.f",fl,fl2)]
open("/w/vv.txt","w").write(repr(d))
PYEOF
docker exec -i sn-fortran-solver-parity python3 - < /tmp/vv.py
docker exec sn-fortran-solver-parity bash -lc 'cd /w; python3 z2.py "$(cat vv.txt)" 3'
```

<details><summary>output</summary>

```
lin1.0D-3 bad 3 of 48 [27, 31, 47]
27 ['OPTION FRICTION HW', 'OPTION TOL 1e-9'] ['25'] ['14']
31 ['OPTION FRICTION HW', 'OPTION TOL 1e-9'] ['13'] ['46']
47 ['OPTION FRICTION HW', 'OPTION TOL 1e-9'] ['11'] ['15']
lin1.0D-2 bad 2 of 48 [27, 35]
27 ['OPTION FRICTION HW', 'OPTION TOL 1e-9'] ['25'] ['14']
35 ['OPTION FRICTION HW', 'OPTION TOL 1e-9'] ['11'] ['13']
lin3.0D-2 bad 2 of 48 [24, 27]
24 ['OPTION FRICTION HW', 'OPTION TOL 1e-3'] ['14'] ['13']
27 ['OPTION FRICTION HW', 'OPTION TOL 1e-9'] ['25'] ['14']
lin1.0D-1 bad 7 of 48 [24, 25, 26, 27, 37, 38, 39]
24 ['OPTION FRICTION HW', 'OPTION TOL 1e-3'] ['14'] ['13']
25 ['OPTION FRICTION HW', 'OPTION TOL 1e-5'] ['14'] ['13']
26 ['OPTION FRICTION HW', 'OPTION TOL 1e-7'] ['14'] ['13']
```
</details>

### Step 143: Bash

```bash
cd /tmp; docker exec -i sn-fortran-solver-parity bash -c 'cat > /w/z3.py' <<'EOF'
import sys
sys.path.insert(0,"/w")
from bench import *
vs=eval(sys.argv[1])
tols=["1e-2","1e-3","1e-4","1e-5","1e-6","1e-7","1e-8","1e-9","1e-10","1e-11","1e-12"]
decks=[]
for q,d3,d4 in [(1,150,300),(1,200,50),(5,150,300)]:
    decks.append("OPTION FRICTION HW\nOPTION TOL %%s\nRESERVOIR R 100\nJUNCTION J1 10 %g\nJUNCTION J3 12 0\nPIPE P1 R J1 200 200 100\nPIPE P3 J1 J3 500 %d 100\nPIPE P4 J3 J1 500 %d 100\nEND\n"%(q,d3,d4))
for d in decks:
    print("deck",d.split("\n")[3:9])
    print(" PROD",[ (lambda s:(s[1][0][0] or s[1][0][1][:2]))(seq(PROD,d%t)) for t in tols])
    for k,v in vs.items():
        exe=build(k,v)
        print(" %-8s"%k,[ (lambda s:(s[1][0][0] or s[1][0][1][:2]))(seq(exe,d%t)) for t in tols])
EOF
cat > /tmp/vv.py <<'PYEOF'
def inc(gp,gu,gv):
    return ("hydro.inc","GMINP=1.0D-4, GMINU=1.0D-4,\n     &           GMINV=1.0D-4","GMINP=%s, GMINU=%s,\n     &           GMINV=%s"%(gp,gu,gv))
d={"g2":[inc("2.0D-2","1.0D-4","1.0D-4")],"g4":[inc("1.0D-4","1.0D-4","1.0D-4")]}
open("/w/vv.txt","w").write(repr(d))
PYEOF
docker exec -i sn-fortran-solver-parity python3 - < /tmp/vv.py
docker exec sn-fortran-solver-parity bash -lc 'cd /w; python3 z3.py "$(cat vv.txt)"'
```

<details><summary>output</summary>

```
deck ['JUNCTION J1 10 1', 'JUNCTION J3 12 0', 'PIPE P1 R J1 200 200 100', 'PIPE P3 J1 J3 500 150 100', 'PIPE P4 J3 J1 500 300 100', 'END']
 PROD ['10', '14', '14', '14', '14', '14', '14', '25', 'NO', 'NO', 'NO']
 g2       ['10', '14', '14', '14', '14', '14', '14', '14', '24', 'NO', 'NO']
 g4       ['10', '14', '14', '14', '14', '15', '25', 'NO', 'NO', 'NO', 'NO']
deck ['JUNCTION J1 10 1', 'JUNCTION J3 12 0', 'PIPE P1 R J1 200 200 100', 'PIPE P3 J1 J3 500 200 100', 'PIPE P4 J3 J1 500 50 100', 'END']
 PROD ['7', '11', '11', '11', '11', '11', '11', '11', '11', 'NO', 'NO']
 g2       ['7', '11', '11', '11', '11', '11', '11', '11', '21', 'NO', 'NO']
 g4       ['7', '11', '11', '11', '11', '11', '21', 'NO', 'NO', 'NO', 'NO']
deck ['JUNCTION J1 10 5', 'JUNCTION J3 12 0', 'PIPE P1 R J1 200 200 100', 'PIPE P3 J1 J3 500 150 100', 'PIPE P4 J3 J1 500 300 100', 'END']
 PROD ['8', '11', '14', '14', '14', '14', '14', '14', '14', 'NO', 'NO']
 g2       ['8', '11', '14', '14', '14', '14', '14', '14', '16', '19', 'NO']
 g4       ['8', '11', '14', '14', '14', '14', '23', 'NO', 'NO', 'NO', 'NO']
```
</details>

### Step 144: Bash

```bash
cd /tmp; docker exec sn-fortran-solver-parity bash -lc 'cd /w/new; sed -i "s/GMINP=1.0D-4/GMINP=2.0D-2/" hydro.inc; grep -n GMINP hydro.inc; gfortran -O2 -o hydro *.f; cd /w; python3 probes.py | tail -3; python3 gen.py 0 200 2>&1 | tail -40'
```

<details><summary>output</summary>

```
4:      DOUBLE PRECISION GRAV, PI, VISC, GMIN, GMINP, GMINU, GMINV, QZERO
6:      PARAMETER (VISC=1.0D-6, GMIN=1.0D-4, GMINP=2.0D-2, GMINU=1.0D-4,
bad 0 of 240
DIFF seed69 tok line 9
  P:  CONVERGED IN  17 ITERATIONS
  M:  CONVERGED IN  19 ITERATIONS
DIFF seed110 linecount 58 vs 57
bad 2 of 200
```
</details>

### Step 145: Bash

```bash
cd /tmp; docker exec sn-fortran-solver-parity bash -lc 'cd /w; python3 -c "
from gen import gen
open(\"/w/d110.dat\",\"w\").write(gen(110))"; cat d110.dat; /app/prod/hydro < d110.dat > p110.out; new/hydro < d110.dat > m110.out; diff p110.out m110.out'
```

<details><summary>output</summary>

```
Exit code 1
TITLE Random deck 110
RESERVOIR R0 110.1
JUNCTION J0 48.9 0.00
JUNCTION J1 26.5 1.00
JUNCTION J2 57.0 0.00
JUNCTION J3 17.3 1.50
JUNCTION J4 59.6 8.00
JUNCTION J5 16.5 40.00
JUNCTION J6 15.5 2.00
JUNCTION J7 10.6 15.00
JUNCTION J8 29.7 3.00
JUNCTION J9 9.9 8.00
JUNCTION J10 49.4 2.00
PIPE P0 R0 J0 300.0 400.00 0.1 5
PIPE P1 R0 J1 300.0 400.00 1.0
PIPE P2 J2 J0 500.0 300.00 0.05
PIPE P3 R0 J3 800.0 150.00 0.1
PIPE P4 R0 J4 200.0 400.00 0.1
PIPE P5 R0 J5 1200.0 200.00 0.05
PIPE P6 J5 J6 100.0 100.00 0.05
PIPE P7 R0 J7 800.0 100.00 0.05
PIPE P8 R0 J8 100.0 200.00 0.1
PIPE P9 J6 J9 300.0 400.00 0.5 2
PIPE P10 J10 J1 800.0 250.00 1.0
PIPE P11 J2 J10 500.0 300.00 0.1
PIPE P12 J0 R0 200.0 150.00 0.05
PUMP U0 R0 J3 20.0 10.00
PUMP U1 J5 J6 10.0 10.00
VALVE V0 J1 R0 100 0 
VALVE V1 J1 J5 100 0 
END
31,45c31,45
<  P0       PIPE  R0       J0            1.11     0.009     0.000   0.03877  OPEN    
<  P1       PIPE  R0       J1           -0.00    -0.000     0.000     UNDEF  OPEN    
<  P2       PIPE  J2       J0           -1.19    -0.017     0.001   0.03793  OPEN    
<  P3       PIPE  R0       J3           -8.17    -0.463     1.285   0.02209  OPEN    
<  P4       PIPE  R0       J4            8.00     0.064     0.003   0.02501  OPEN    
<  P5       PIPE  R0       J5           -0.00    -0.000     0.000     UNDEF  OPEN    
<  P6       PIPE  J5       J6            0.00     0.000     0.000     UNDEF  OPEN    
<  P7       PIPE  R0       J7           15.00     1.910    28.288   0.01901  OPEN    
<  P8       PIPE  R0       J8            3.00     0.095     0.006   0.02729  OPEN    
<  P9       PIPE  J6       J9            8.00     0.064     0.005   0.02745  OPEN    
<  P10      PIPE  J10      J1           -0.81    -0.016     0.002   0.04459  OPEN    
<  P11      PIPE  J2       J10           1.19     0.017     0.001   0.03814  OPEN    
<  P12      PIPE  J0       R0           -0.08    -0.005     0.000   0.09143  OPEN    
<  U0       PUMP  R0       J3            9.67               1.285            ON      
<  U1       PUMP  J5       J6           10.00               0.000            ON      
---
>  P0        PIPE R0       J0            1.11     0.009     0.000   0.03877  OPEN    
>  P1        PIPE R0       J1            0.00     0.000     0.000     UNDEF  OPEN    
>  P2        PIPE J2       J0           -1.19    -0.017     0.001   0.03793  OPEN    
>  P3        PIPE R0       J3           -8.17    -0.463     1.285   0.02209  OPEN    
>  P4        PIPE R0       J4            8.00     0.064     0.003   0.02501  OPEN    
>  P5        PIPE R0       J5            0.00     0.000     0.000     UNDEF  OPEN    
>  P6        PIPE J5       J6            0.00     0.000     0.000     UNDEF  OPEN    
>  P7        PIPE R0       J7           15.00     1.910    28.288   0.01901  OPEN    
>  P8        PIPE R0       J8            3.00     0.095     0.006   0.02729  OPEN    
>  P9        PIPE J6       J9            8.00     0.064     0.005   0.02745  OPEN    
>  P10       PIPE J10
... [564 more chars truncated]
```
</details>

### Step 146: Bash

```bash
cd /tmp; docker exec sn-fortran-solver-parity bash -lc 'cd /w; . ./t.sh; for q in 5 4.99 5.01 0.3 10 2.5; do printf "RESERVOIR R 100\nJUNCTION a 10 $q\nPUMP u R a 10 $q\nEND\n" | /app/prod/hydro | grep -e W20 -e " u "; echo "-- $q"; done'
```

<details><summary>output</summary>

```
 u        PUMP  R        a             5.00               0.000            ON      
-- 5
 u        PUMP  R        a             4.99               0.000            ON      
-- 4.99
 u        PUMP  R        a             5.01               0.000            ON      
-- 5.01
 u        PUMP  R        a             0.30               0.000            ON      
-- 0.3
 u        PUMP  R        a            10.00               0.000            ON      
-- 10
 u        PUMP  R        a             2.50               0.000            ON      
-- 2.5
```
</details>

### Step 147: Bash

```bash
cd /tmp; docker exec sn-fortran-solver-parity bash -lc 'cd /w/new; sed -i "s/LID(L), .PUMP., NID(N1)/LID(L), \x27PUMP \x27, NID(N1)/; s/LID(L), .VALVE., NID(N1)/LID(L), \x27VALVE\x27, NID(N1)/; s/LID(L), .PIPE., NID(N1)/LID(L), \x27PIPE \x27, NID(N1)/" output.f; grep -n "PUMP \|VALVE\x27\|PIPE " output.f | head; gfortran -O2 -o hydro *.f; cd /w; /app/prod/hydro < d110.dat > p110.out; new/hydro < d110.dat > m110.out; diff p110.out m110.out'
```

<details><summary>output</summary>

```
Exit code 1
150:            WRITE (6,1090) LID(L), 'PUMP ', NID(N1), NID(N2),
165:                  WRITE (6,1100) LID(L), 'PIPE ', NID(N1), NID(N2),
168:                  WRITE (6,1110) LID(L), 'PIPE ', NID(N1), NID(N2),
171:                  WRITE (6,1120) LID(L), 'PIPE ', NID(N1), NID(N2),
272: 1020 FORMAT (1X,'*** WARNING W210: PUMP ''',A,''' REVERSE FLOW')
273: 1030 FORMAT (1X,'*** WARNING W207: PUMP ''',A,''' FLOW EXCEEDS QMAX')
32c32
<  P1       PIPE  R0       J1           -0.00    -0.000     0.000     UNDEF  OPEN    
---
>  P1       PIPE  R0       J1            0.00     0.000     0.000     UNDEF  OPEN    
36c36
<  P5       PIPE  R0       J5           -0.00    -0.000     0.000     UNDEF  OPEN    
---
>  P5       PIPE  R0       J5            0.00     0.000     0.000     UNDEF  OPEN    
48c48
<  
---
> 
54d53
<  *** WARNING W207: PUMP 'U1' FLOW EXCEEDS QMAX
58c57
<  RUN COMPLETED WITH   6 WARNING(S)
---
>  RUN COMPLETED WITH   5 WARNING(S)
```
</details>

### Step 148: Bash

```bash
cd /tmp; cat > /tmp/vv.py <<'PYEOF'
z="""               IF (LTYP(L) .NE. 2 .AND. ABS(QL(L)) .LT. QZERO .AND.
     &            ABS(QNEW) .LT. QZERO) QNEW = 0.0D0
"""
fl="""      ELSE
         IF (GR .LT. GMINP) GR = GMINP
      ENDIF"""
fl2="""      ELSE
         IF (GR .LT. GMINP) GR = GMINP
         IF (ABS(Q) .LT. QZERO) H = 0.0D0
      ENDIF"""
fl3="""      ELSE
         IF (GR .LT. GMINP) GR = GMINP
         IF (ABS(Q) .LT. QZERO) THEN
            H = 0.0D0
            GR = GMINP
         ENDIF
      ENDIF"""
d={"base":[],"h0":[("solve.f",z,""),("solve.f",fl,fl2)],"h0g":[("solve.f",z,""),("solve.f",fl,fl3)]}
open("/w/vv.txt","w").write(repr(d))
PYEOF
docker exec -i sn-fortran-solver-parity python3 - < /tmp/vv.py
docker exec sn-fortran-solver-parity bash -lc 'cd /w; python3 z2.py "$(cat vv.txt)" 2; python3 bench.py "$(cat vv.txt)"'
```

<details><summary>output</summary>

```
base bad 1 of 48 [27]
27 ['OPTION FRICTION HW', 'OPTION TOL 1e-9'] ['25'] ['14']
h0 bad 20 of 48 [24, 25, 26, 27, 29, 30, 31, 32, 33, 34, 35, 37, 38, 39, 41, 42, 43, 45, 46, 47]
24 ['OPTION FRICTION HW', 'OPTION TOL 1e-3'] ['14'] ['13']
25 ['OPTION FRICTION HW', 'OPTION TOL 1e-5'] ['14'] ['13']
h0g bad 21 of 48 [7, 24, 25, 26, 27, 29, 30, 31, 32, 33, 34, 35, 37, 38, 39, 41, 42, 43, 45, 46, 47]
7 ['OPTION FRICTION DW', 'OPTION TOL 1e-9'] ['6'] ['17']
24 ['OPTION FRICTION HW', 'OPTION TOL 1e-3'] ['14'] ['13']
base bad 23 of 112 [9, 26, 27, 41, 42, 43, 45, 56, 58, 59, 73, 74, 76, 84, 85, 87, 91, 95, 99, 100, 101, 102, 103]
h0 bad 27 of 112 [9, 26, 27, 41, 42, 43, 45, 56, 58, 59, 73, 74, 76, 82, 84, 85, 87, 91, 95, 96, 97, 98, 99, 104, 105, 106, 107]
h0g bad 35 of 112 [9, 26, 27, 41, 42, 43, 45, 56, 58, 59, 73, 74, 76, 80, 81, 82, 83, 84, 85, 87, 89, 91, 95, 96, 97, 98, 99, 104, 105, 106]
```
</details>

### Step 149: Bash

```bash
cd /tmp; cat > /tmp/vv.py <<'PYEOF'
z="""               IF (LTYP(L) .NE. 2 .AND. ABS(QL(L)) .LT. QZERO .AND.
     &            ABS(QNEW) .LT. QZERO) QNEW = 0.0D0
"""
d={"base":[],"sgn":[("solve.f",z,z.replace("QNEW = 0.0D0","QNEW = SIGN(0.0D0, QNEW)"))],"sgnold":[("solve.f",z,z.replace("QNEW = 0.0D0","QNEW = SIGN(0.0D0, QL(L))"))]}
open("/w/vv.txt","w").write(repr(d))
PYEOF
docker exec -i sn-fortran-solver-parity python3 - < /tmp/vv.py
docker exec sn-fortran-solver-parity bash -lc 'cd /w; python3 var3.py d110.dat "$(cat vv.txt)" ; for v in sgn sgnold; do python3 - <<EOF
import sys
sys.path.insert(0,"/w")
from bench import *
exe=build("$v",eval(open("/w/vv.txt").read())["$v"])
import subprocess
from cmp import cmp,run
p=run(PROD,open("/w/d110.dat").read()); m=run(exe,open("/w/d110.dat").read())
print("$v",cmp(p[0],m[0]))
EOF
done'
```

<details><summary>output</summary>

```
PROD [10]
base [10]
Traceback (most recent call last):
  File "/w/var3.py", line 10, in <module>
    exe=build(name,repl)
        ^^^^^^^^^^^^^^^^
  File "/w/var.py", line 9, in build
    for a,b in repl:
        ^^^
ValueError: too many values to unpack (expected 2)
sgn ('linecount 58 vs 57', None)
sgnold ('linecount 58 vs 57', None)
```
</details>

### Step 150: Bash

```bash
cd /tmp; docker exec sn-fortran-solver-parity bash -lc 'cd /w; for v in sgn sgnold; do echo $v; bn_$v/hydro < d110.dat | diff p110.out - | head -8; done'
```

<details><summary>output</summary>

```
sgn
37c37
<  P6       PIPE  J5       J6            0.00     0.000     0.000     UNDEF  OPEN    
---
>  P6       PIPE  J5       J6           -0.00    -0.000     0.000     UNDEF  OPEN    
48c48
<  
---
> 
sgnold
36,37c36,37
<  P5       PIPE  R0       J5           -0.00    -0.000     0.000     UNDEF  OPEN    
<  P6       PIPE  J5       J6            0.00     0.000     0.000     UNDEF  OPEN    
---
>  P5       PIPE  R0       J5            0.00     0.000     0.000     UNDEF  OPEN    
>  P6       PIPE  J5       J6           -0.00    -0.000     0.000     UNDEF  OPEN    
48c48
<
```
</details>

### Step 151: Bash

```bash
cd /tmp; cat > /tmp/ed11.py <<'PYEOF'
s=open("/w/new/solve.f").read()
a="     &            ABS(QNEW) .LT. QZERO) QNEW = 0.0D0\n"
assert a in s
s=s.replace(a,"     &            ABS(QNEW) .LT. QZERO) QNEW = SIGN(0.0D0, QNEW)\n")
open("/w/new/solve.f","w").write(s)
PYEOF
docker exec -i sn-fortran-solver-parity python3 - < /tmp/ed11.py
docker exec sn-fortran-solver-parity bash -lc 'cd /w/new; gfortran -O2 -o hydro *.f; cd /w; python3 gen.py 200 500 2>&1 | grep -v "^  [PM]:" | head -60'
```

<details><summary>output</summary>

```
DIFF seed213 linecount 166 vs 165
RC DIFF seed314 0 2
DIFF seed414 tok line 9
DIFF seed469 linecount 245 vs 243
bad 4 of 300
```
</details>

### Step 152: Bash

```bash
cd /tmp; docker exec sn-fortran-solver-parity bash -lc 'cd /w; python3 - <<EOF
from gen import gen
for s in (213,314,414,469):
    open("/w/d%d.dat"%s,"w").write(gen(s))
EOF
for s in 213 314 414 469; do echo "== $s"; /app/prod/hydro < d$s.dat > p.out; new/hydro < d$s.dat > m.out; diff p.out m.out | head -12; done'
```

<details><summary>output</summary>

```
== 213
30c30
<  
---
> 
55c55
<  
---
> 
79c79
<  V0       VALVE J0       J1         2300.96    14.686     0.000            OPEN    
---
>  V0       VALVE J0       J1         2300.95    14.686     0.000            OPEN    
== 314
STOP 2
12c12
<  CONVERGED IN  28 ITERATIONS
---
>  *** WARNING W205: NOT CONVERGED AFTER 50 ITERATIONS
25c25
<  P1       PIPE  J0       J1            0.00     0.000     0.000            OPEN    
---
>  P1       PIPE  J0       J1            0.10     0.000     0.000            OPEN    
29c29
<  V0       VALVE J1       J0           87.00     0.987     0.000            OPEN    
---
>  V0       VALVE J1       J0           87.10     0.988     0.000            OPEN    
== 414
10c10
<  CONVERGED IN  15 ITERATIONS
---
>  CONVERGED IN  14 ITERATIONS
35c35
<  P4       PIPE  J3       J4           -0.00    -0.000     0.000            OPEN    
---
>  P4       PIPE  J3       J4            0.00     0.000     0.000            OPEN    
46c46
<  
---
> 
== 469
STOP 2
STOP 2
31c31
<  P2       PIPE  J0       J2            0.00     0.000     0.000            OPEN    
---
>  P2       PIPE  J0       J2           -0.00    -0.000     0.000            OPEN    
37c37
<  
---
> 
69c69
<  
---
>
```
</details>

### Step 153: Bash

```bash
cd /tmp; docker exec sn-fortran-solver-parity bash -lc 'cd /w; for s in 213 469; do /app/prod/hydro < d$s.dat | sed "s/ *$//" > p.out; new/hydro < d$s.dat | sed "s/ *$//"> m.out; diff p.out m.out | head -12; done; cat d314.dat'
```

<details><summary>output</summary>

```
79c79
<  V0       VALVE J0       J1         2300.96    14.686     0.000            OPEN
---
>  V0       VALVE J0       J1         2300.95    14.686     0.000            OPEN
115c115
<  CONVERGED IN   2 ITERATIONS
---
>  CONVERGED IN   5 ITERATIONS
127c127
<  P1       PIPE  J0       J1            0.00     0.000     0.000            OPEN
---
>  P1       PIPE  J0       J1            0.02     0.000     0.000            OPEN
STOP 2
STOP 2
31c31
<  P2       PIPE  J0       J2            0.00     0.000     0.000            OPEN
---
>  P2       PIPE  J0       J2           -0.00    -0.000     0.000            OPEN
95c95
<  P2       PIPE  J0       J2            0.00     0.000     0.000            OPEN
---
>  P2       PIPE  J0       J2           -0.00    -0.000     0.000            OPEN
97,99c97,99
<  P4       PIPE  J0       J4            0.00     0.000     0.000            OPEN
<  P5       PIPE  J3       J5           -0.00    -0.000     0.000            OPEN
<  V0       VALVE J5       J3            0.00     0.000     0.000            OPEN
TITLE Random deck 314
UNITS US
OPTION FRICTION HW
OPTION TOL 1e-8
OPTION STEPS 7
OPTION HSTEP 0.5
PATTERN pt0 1.00
RESERVOIR R0 375.1
JUNCTION J0 28.5 0.00 pt0
JUNCTION J1 121.0 317.00
PIPE P0 R0 J0 1640.0 11.81 110
PIPE P1 J0 J1 328.0 15.75 120
PIPE P2 J1 R0 3936.0 3.94 100
PUMP U0 J0 J1 98.4 317.00
PUMP U1 R0 J1 32.8 79.25
VALVE V0 J1 J0 6 0 
VALVE V1 J0 R0 8 20 CLOSED
END
```
</details>

### Step 154: Bash

```bash
cd /tmp; docker exec -i sn-fortran-solver-parity bash -c 'cat > /w/z4.py' <<'EOF'
import sys
sys.path.insert(0,"/w")
from bench import *
tols=["1e-2","1e-3","1e-4","1e-5","1e-6","1e-7","1e-8","1e-9","1e-10","1e-12"]
decks=[]
for q,dp in [(5,100),(20,300),(2,50)]:
    decks.append("OPTION TOL %%s\nRESERVOIR R 100\nJUNCTION J1 10 1\nJUNCTION J2 12 %g\nPIPE P0 R J1 200 200 0.1\nPIPE PX J1 J2 500 %d 0.1\nVALVE V J1 J2 100 0\nEND\n"%(q,dp))
    decks.append("OPTION FRICTION HW\nOPTION TOL %%s\nRESERVOIR R 100\nJUNCTION J1 10 1\nJUNCTION J2 12 %g\nPIPE P0 R J1 200 200 100\nPIPE PX J1 J2 500 %d 100\nVALVE V J1 J2 100 0\nEND\n"%(q,dp))
def row(exe,d): return [ (lambda s:(s[1][0][0] or s[1][0][1][:2]) if s[1] else "E%d"%s[0])(seq(exe,d%t)) for t in tols]
if __name__=="__main__":
    vs=eval(sys.argv[1])
    for d in decks:
        print("deck",d.split("\n")[1:2], d.split("\n")[6:8])
        print(" PROD",row(PROD,d))
        for k,v in vs.items():
            exe=build(k,v); print(" %-8s"%k,row(exe,d))
EOF
cat > /tmp/vv.py <<'PYEOF'
def inc(gp,gu,gv):
    return ("hydro.inc","GMINP=2.0D-2, GMINU=1.0D-4,\n     &           GMINV=1.0D-4","GMINP=%s, GMINU=%s,\n     &           GMINV=%s"%(gp,gu,gv))
d={}
for gv in ["1.0D-2","1.0D-3","1.0D-4","1.0D-5","1.0D-6"]:
    d["gv"+gv]=[inc("2.0D-2","1.0D-4",gv)]
open("/w/vv.txt","w").write(repr(d))
PYEOF
docker exec -i sn-fortran-solver-parity python3 - < /tmp/vv.py
docker exec sn-fortran-solver-parity bash -lc 'cd /w; python3 z4.py "$(cat vv.txt)"'
```

<details><summary>output</summary>

```
deck ['RESERVOIR R 100'] ['VALVE V J1 J2 100 0', 'END']
 PROD ['6', '6', '6', '6', '6', '7', '8', '18', '28', 'NO']
 gv1.0D-2 ['6', '6', '6', '7', '7', '7', '7', '8', '11', 'NO']
 gv1.0D-3 ['6', '6', '6', '6', '7', '7', '7', '8', '18', 'NO']
 gv1.0D-4 ['6', '6', '6', '6', '6', '7', '8', '12', 'NO', 'NO']
 gv1.0D-5 ['6', '6', '6', '6', '6', '8', '28', 'NO', 'NO', 'NO']
 gv1.0D-6 ['6', '6', '6', '6', '6', '15', 'NO', 'NO', 'NO', 'NO']
deck ['OPTION TOL %s'] ['PIPE PX J1 J2 500 100 100', 'VALVE V J1 J2 100 0']
 PROD ['6', '9', '11', '13', '13', '13', '14', '22', 'NO', 'NO']
 gv1.0D-2 ['6', '9', '12', '14', '16', '18', '20', '22', '27', 'NO']
 gv1.0D-3 ['6', '9', '11', '14', '14', '15', '16', '19', '44', 'NO']
 gv1.0D-4 ['6', '9', '11', '14', '14', '14', '16', '38', 'NO', 'NO']
 gv1.0D-5 ['6', '9', '11', '14', '14', '17', 'NO', 'NO', 'NO', 'NO']
 gv1.0D-6 ['6', '9', '12', '14', '14', '14', 'NO', 'NO', 'NO', 'NO']
deck ['RESERVOIR R 100'] ['VALVE V J1 J2 100 0', 'END']
 PROD ['8', '8', '8', '8', '9', '9', '9', '11', '20', 'NO']
 gv1.0D-2 ['8', '8', '9', '10', '10', '11', '12', '12', '13', '43']
 gv1.0D-3 ['8', '8', '8', '9', '9', '10', '10', '10', '15', 'NO']
 gv1.0D-4 ['8', '8', '8', '8', '9', '9', '9', '26', 'NO', 'NO']
 gv1.0D-5 ['8', '8', '8', '8', '8', '9', '9', '24', '24', 'NO']
 gv1.0D-6 ['8', '8', '8', '8', '8', '8', 'NO', 'NO', 'NO', 'NO']
deck ['OPTION TOL %s'] ['PIPE PX J1 J2 500 300 100', 'VALVE V J1 J2 100 0']
 PROD ['7', '10', '13', '15', '16', '16', '17', '20', 'NO', 'NO']
 gv1.0D-2 ['7', '10', '13', '17', '25', '27', '29', '31', '34', '43']
 gv1.0D-3 ['7', '10', '13', '16', '19', '20', '21', '22', '33', 'NO']
 gv1.0D-4 ['7', '10', '13', '16', '19', '19', '20', '28', 'NO', 'NO']
 gv1.0D-5 ['7', '10', '13', '16', '19', '19', '19', '24', 'NO', 'NO']
 gv1.0D-6 ['7', '10', '12', '16', '19', '19', '47', 'NO', 'NO', 'NO']
deck ['RESERVOIR R 100'] ['VALVE V J1 J2 100 0', 'END']
 PROD ['5', '5', '5', '5', '5', '5', '17', 'NO', 'NO', 'NO']
 gv1.0D-2 ['5', '5', '5', '5', '5', '6', '6', '6', '9', 'NO']
 gv1.0D-3 ['5', '5', '5', '5', '5', '5', '6', '6', '10', 'NO']
 gv1.0D-4 ['5', '5', '5', '5', '5', '5', '9', '39', 'NO', 'NO']
 gv1.0D-5 ['5', '5', '5', '5', '5', '16', '30', '30', 'NO', 'NO']
 gv1.0D-6 ['5', '5', '5', '5', '5', '5', 'NO', 'NO', 'NO', 'NO']
deck ['OPTION TOL %s'] ['PIPE PX J1 J2 500 50 100', 'VALVE V J1 J2 100 0']
 PROD ['5', '8', '11', '11', '11', '11', '17', '36', 'NO', 'NO']
 gv1.0D-2 ['5', '8', '11', '13', '15', '17', '19', '21', '26', 'NO']
 gv1.0D-3 ['5', '8', '11', '12', '13', '14', '15', '20', '20', 'NO']
 gv1.0D-4 ['5', '8', '11', '12', '12', '13', '17', '19', '19', 'NO']
 gv1.0D-5 ['5', '8', '11', '12', '12', '13', '14', 'NO', 'NO', 'NO']
 gv1.0D-6 ['5', '8', '11', '12', '12', '35', 'NO', 'NO', 'NO', 'NO']
```
</details>

### Step 155: Bash

```bash
cd /tmp; cat > /tmp/vv.py <<'PYEOF'
piv="""            IF (ABS(A(I,K)) .GT. BIG) THEN
               BIG = ABS(A(I,K))
               IP = I
            ENDIF"""
chol_call="""            CALL LINSOL(AM, RHS, HX, NEQ, MXN)"""
chol="""            CALL CHOL(AM, RHS, HX, NEQ, MXN)"""
chol_sub="""
      SUBROUTINE CHOL(A, B, X, N, LDA)
      IMPLICIT NONE
      INTEGER N, LDA
      DOUBLE PRECISION A(LDA,*), B(*), X(*)
      INTEGER I, J, K
      DOUBLE PRECISION T
      DO 50 J = 1, N
         T = A(J,J)
         DO 10 K = 1, J-1
            T = T - A(J,K)*A(J,K)
   10    CONTINUE
         A(J,J) = SQRT(T)
         DO 30 I = J+1, N
            T = A(I,J)
            DO 20 K = 1, J-1
               T = T - A(I,K)*A(J,K)
   20       CONTINUE
            A(I,J) = T/A(J,J)
   30    CONTINUE
   50 CONTINUE
      DO 70 I = 1, N
         T = B(I)
         DO 60 K = 1, I-1
            T = T - A(I,K)*X(K)
   60    CONTINUE
         X(I) = T/A(I,I)
   70 CONTINUE
      DO 90 I = N, 1, -1
         T = X(I)
         DO 80 K = I+1, N
            T = T - A(K,I)*X(K)
   80    CONTINUE
         X(I) = T/A(I,I)
   90 CONTINUE
      RETURN
      END
"""
d={"nopivot":[("solve.f",piv,"            CONTINUE")],"chol":[("solve.f",chol_call,chol),("solve.f","C     LINSOL  -  GAUSSIAN","C     CHOL  \n"+chol_sub.replace("\n      SUBROUTINE","      SUBROUTINE",1)+"C\nC     LINSOL  -  GAUSSIAN")]}
open("/w/vv.txt","w").write(repr(d))
PYEOF
docker exec -i sn-fortran-solver-parity python3 - < /tmp/vv.py
docker exec sn-fortran-solver-parity bash -lc 'cd /w; python3 z4.py "$(cat vv.txt)" 2>&1 | head -40'
```

<details><summary>output</summary>

```
deck ['RESERVOIR R 100'] ['VALVE V J1 J2 100 0', 'END']
 PROD ['6', '6', '6', '6', '6', '7', '8', '18', '28', 'NO']
 nopivot  ['6', '6', '6', '6', '6', '7', '8', '12', 'NO', 'NO']
 chol     ['6', '6', '6', '6', '6', '7', '7', '11', '46', 'NO']
deck ['OPTION TOL %s'] ['PIPE PX J1 J2 500 100 100', 'VALVE V J1 J2 100 0']
 PROD ['6', '9', '11', '13', '13', '13', '14', '22', 'NO', 'NO']
 nopivot  ['6', '9', '11', '14', '14', '14', '16', '38', 'NO', 'NO']
 chol     ['6', '9', '11', '14', '14', '14', '17', '21', 'NO', 'NO']
deck ['RESERVOIR R 100'] ['VALVE V J1 J2 100 0', 'END']
 PROD ['8', '8', '8', '8', '9', '9', '9', '11', '20', 'NO']
 nopivot  ['8', '8', '8', '8', '9', '9', '9', '26', 'NO', 'NO']
 chol     ['8', '8', '8', '8', '9', '9', '9', '19', '50', 'NO']
deck ['OPTION TOL %s'] ['PIPE PX J1 J2 500 300 100', 'VALVE V J1 J2 100 0']
 PROD ['7', '10', '13', '15', '16', '16', '17', '20', 'NO', 'NO']
 nopivot  ['7', '10', '13', '16', '19', '19', '20', '28', 'NO', 'NO']
 chol     ['7', '10', '13', '16', '19', '19', '20', '23', 'NO', 'NO']
deck ['RESERVOIR R 100'] ['VALVE V J1 J2 100 0', 'END']
 PROD ['5', '5', '5', '5', '5', '5', '17', 'NO', 'NO', 'NO']
 nopivot  ['5', '5', '5', '5', '5', '5', '9', '39', 'NO', 'NO']
 chol     ['5', '5', '5', '5', '5', '5', '9', '44', 'NO', 'NO']
deck ['OPTION TOL %s'] ['PIPE PX J1 J2 500 50 100', 'VALVE V J1 J2 100 0']
 PROD ['5', '8', '11', '11', '11', '11', '17', '36', 'NO', 'NO']
 nopivot  ['5', '8', '11', '12', '12', '13', '17', '19', '19', 'NO']
 chol     ['5', '8', '11', '12', '12', '13', '21', '50', 'NO', 'NO']
```
</details>

### Step 156: Bash

```bash
cd /tmp; docker exec -i sn-fortran-solver-parity bash -c 'cat > /w/multi.py' <<'EOF'
import sys,json,os
sys.path.insert(0,"/w")
from bench import seq,build,PROD,decks as bdecks
import z2
def z4decks():
    tols=["1e-2","1e-3","1e-4","1e-5","1e-6","1e-7","1e-8","1e-9","1e-10"]
    D=[]
    for q,dp in [(5,100),(20,300),(2,50)]:
        for t in tols:
            D.append("OPTION TOL %s\nRESERVOIR R 100\nJUNCTION J1 10 1\nJUNCTION J2 12 %g\nPIPE P0 R J1 200 200 0.1\nPIPE PX J1 J2 500 %d 0.1\nVALVE V J1 J2 100 0\nEND\n"%(t,q,dp))
            D.append("OPTION FRICTION HW\nOPTION TOL %s\nRESERVOIR R 100\nJUNCTION J1 10 1\nJUNCTION J2 12 %g\nPIPE P0 R J1 200 200 100\nPIPE PX J1 J2 500 %d 100\nVALVE V J1 J2 100 0\nEND\n"%(t,q,dp))
    return D
def alld():
    return z2.D+z4decks()+bdecks()
D=alld()
CACHE="/w/multi_prod.json"
if os.path.exists(CACHE) and len(json.load(open(CACHE)))==len(D):
    P=[(a,tuple(tuple(x) for x in b)) for a,b in json.load(open(CACHE))]
else:
    P=[seq(PROD,d) for d in D]; json.dump(P,open(CACHE,"w"))
def score(exe):
    bad=[i for i,(d,p) in enumerate(zip(D,P)) if seq(exe,d)!=p]
    return bad
def report(bad):
    n1=len(z2.D); n2=n1+len(z4decks())
    return "z2 %d/%d z4 %d/%d bench %d/%d"%(sum(1 for b in bad if b<n1),n1,sum(1 for b in bad if n1<=b<n2),n2-n1,sum(1 for b in bad if b>=n2),len(D)-n2)
if __name__=="__main__":
    vs=eval(sys.argv[1])
    for k,v in vs.items():
        exe=build(k,v); bad=score(exe); print("%-10s"%k,len(bad),report(bad))
EOF
cat > /tmp/vv.py <<'PYEOF'
z="""               IF (LTYP(L) .NE. 2 .AND. ABS(QL(L)) .LT. QZERO .AND.
     &            ABS(QNEW) .LT. QZERO) QNEW = SIGN(0.0D0, QNEW)
"""
def zz(c): return """               IF (LTYP(L) .NE. 2 .AND. %s) QNEW = SIGN(0.0D0, QNEW)
"""%c
d={"base":[],
"A":[("solve.f",z,zz("ABS(QNEW) .LT. QZERO"))],
"C":[("solve.f",z,zz("ABS(QL(L)) .LT. QZERO"))],
"F5":[("solve.f",z,zz("ABS(QL(L)) .LT. 5.0D-7 .AND. ABS(QNEW) .LT. 5.0D-7"))],
"F2":[("solve.f",z,zz("ABS(QL(L)) .LT. 2.0D-6 .AND. ABS(QNEW) .LT. 2.0D-6"))],
"F1e5":[("solve.f",z,zz("ABS(QL(L)) .LT. 1.0D-5 .AND. ABS(QNEW) .LT. 1.0D-5"))],
}
open("/w/vv.txt","w").write(repr(d))
PYEOF
docker exec -i sn-fortran-solver-parity python3 - < /tmp/vv.py
docker exec sn-fortran-solver-parity bash -lc 'cd /w; python3 multi.py "$(cat vv.txt)"'
```

<details><summary>output</summary>

```
base       45 z2 1/48 z4 21/54 bench 23/112
solve.f:153:72:

  153 |                IF (LTYP(L) .NE. 2 .AND. ABS(QNEW) .LT. QZERO) QNEW = SIGN(0.0D0, QNEW)
      |                                                                        1
Error: Symbol ‘sig’ at (1) has no IMPLICIT type

A          45 z2 1/48 z4 21/54 bench 23/112
solve.f:153:72:

  153 |                IF (LTYP(L) .NE. 2 .AND. ABS(QL(L)) .LT. QZERO) QNEW = SIGN(0.0D0, QNEW)
      |                                                                        1
Error: Symbol ‘si’ at (1) has no IMPLICIT type; did you mean ‘di’?

C          45 z2 1/48 z4 21/54 bench 23/112
solve.f:153:72:

  153 |                IF (LTYP(L) .NE. 2 .AND. ABS(QL(L)) .LT. 5.0D-7 .AND. ABS(QNEW) .LT. 5.0D-7) QNEW = SIGN(0.0D0, QNEW)
      |                                                                        1
Error: Function ‘abs’ requires an argument list at (1)

F5         45 z2 1/48 z4 21/54 bench 23/112
solve.f:153:72:

  153 |                IF (LTYP(L) .NE. 2 .AND. ABS(QL(L)) .LT. 2.0D-6 .AND. ABS(QNEW) .LT. 2.0D-6) QNEW = SIGN(0.0D0, QNEW)
      |                                                                        1
Error: Function ‘abs’ requires an argument list at (1)

F2         45 z2 1/48 z4 21/54 bench 23/112
solve.f:153:72:

  153 |                IF (LTYP(L) .NE. 2 .AND. ABS(QL(L)) .LT. 1.0D-5 .AND. ABS(QNEW) .LT. 1.0D-5) QNEW = SIGN(0.0D0, QNEW)
      |                                                                        1
Error: Function ‘abs’ requires an argument list at (1)

F1e5       45 z2 1/48 z4 21/54 bench 23/112
```
</details>

### Step 157: Bash

```bash
cd /tmp; cat > /tmp/vv.py <<'PYEOF'
z="""               IF (LTYP(L) .NE. 2 .AND. ABS(QL(L)) .LT. QZERO .AND.
     &            ABS(QNEW) .LT. QZERO) QNEW = SIGN(0.0D0, QNEW)
"""
def zz(c): return """               IF (LTYP(L) .NE. 2) THEN
                  IF (%s) THEN
                     QNEW = SIGN(0.0D0, QNEW)
                  ENDIF
               ENDIF
"""%c
d={"base":[],
"A":[("solve.f",z,zz("ABS(QNEW) .LT. QZERO"))],
"C":[("solve.f",z,zz("ABS(QL(L)) .LT. QZERO"))],
"F5":[("solve.f",z,zz("ABS(QL(L)) .LT. 5.0D-7 .AND.\n     &            ABS(QNEW) .LT. 5.0D-7"))],
"F2":[("solve.f",z,zz("ABS(QL(L)) .LT. 2.0D-6 .AND.\n     &            ABS(QNEW) .LT. 2.0D-6"))],
"F1e5":[("solve.f",z,zz("ABS(QL(L)) .LT. 1.0D-5 .AND.\n     &            ABS(QNEW) .LT. 1.0D-5"))],
}
open("/w/vv.txt","w").write(repr(d))
PYEOF
docker exec -i sn-fortran-solver-parity python3 - < /tmp/vv.py
docker exec sn-fortran-solver-parity bash -lc 'cd /w; python3 multi.py "$(cat vv.txt)"'
```

<details><summary>output</summary>

```
base       45 z2 1/48 z4 21/54 bench 23/112
A          65 z2 20/48 z4 18/54 bench 27/112
C          52 z2 1/48 z4 21/54 bench 30/112
F5         62 z2 14/48 z4 22/54 bench 26/112
F2         57 z2 20/48 z4 15/54 bench 22/112
F1e5       74 z2 21/48 z4 23/54 bench 30/112
```
</details>

### Step 158: Bash

```bash
cd /tmp; cat > /tmp/vv.py <<'PYEOF'
def inc(gp,gu,gv):
    return ("hydro.inc","GMINP=2.0D-2, GMINU=1.0D-4,\n     &           GMINV=1.0D-4","GMINP=%s, GMINU=%s,\n     &           GMINV=%s"%(gp,gu,gv))
d={}
for gp in ["1.0D-1","5.0D-2","2.0D-2","1.0D-2","1.0D-3","1.0D-4"]:
  for gv in ["1.0D-3","1.0D-4","1.0D-5"]:
    d["p%s_v%s"%(gp,gv[-1])]=[inc(gp,"1.0D-4",gv)]
open("/w/vv.txt","w").write(repr(d))
PYEOF
docker exec -i sn-fortran-solver-parity python3 - < /tmp/vv.py
docker exec sn-fortran-solver-parity bash -lc 'cd /w; python3 multi.py "$(cat vv.txt)"'
```

<details><summary>output</summary>

```
p1.0D-1_v3 65 z2 7/48 z4 29/54 bench 29/112
p1.0D-1_v4 52 z2 7/48 z4 22/54 bench 23/112
p1.0D-1_v5 65 z2 7/48 z4 26/54 bench 32/112
p5.0D-2_v3 60 z2 1/48 z4 30/54 bench 29/112
p5.0D-2_v4 46 z2 1/48 z4 22/54 bench 23/112
p5.0D-2_v5 59 z2 1/48 z4 26/54 bench 32/112
p2.0D-2_v3 60 z2 1/48 z4 30/54 bench 29/112
p2.0D-2_v4 45 z2 1/48 z4 21/54 bench 23/112
p2.0D-2_v5 54 z2 1/48 z4 25/54 bench 28/112
p1.0D-2_v3 61 z2 2/48 z4 30/54 bench 29/112
p1.0D-2_v4 49 z2 2/48 z4 20/54 bench 27/112
p1.0D-2_v5 57 z2 2/48 z4 23/54 bench 32/112
p1.0D-3_v3 59 z2 3/48 z4 27/54 bench 29/112
p1.0D-3_v4 49 z2 3/48 z4 19/54 bench 27/112
p1.0D-3_v5 57 z2 3/48 z4 22/54 bench 32/112
p1.0D-4_v3 58 z2 8/48 z4 24/54 bench 26/112
p1.0D-4_v4 55 z2 8/48 z4 19/54 bench 28/112
p1.0D-4_v5 64 z2 8/48 z4 23/54 bench 33/112
```
</details>

### Step 159: Bash

```bash
cd /tmp; docker exec sn-fortran-solver-parity bash -lc 'cd /w; rm -rf dbg; cp -r new dbg; cd dbg; python3 - <<EOF
s=open("solve.f").read()
s=s.replace("         IF (SQ .GT. 1.0D-30) THEN","         WRITE (0,*) IT, (QL(L),L=1,NL), SDQ/SQ\n         IF (SQ .GT. 1.0D-30) THEN")
open("solve.f","w").write(s)
EOF
gfortran -O2 -o hydro *.f && printf "OPTION FRICTION HW\nOPTION TOL 1e-8\nRESERVOIR R 100\nJUNCTION J1 10 1\nJUNCTION J2 12 5\nPIPE P0 R J1 200 200 100\nPIPE PX J1 J2 500 100 100\nVALVE V J1 J2 100 0\nEND\n" | ./hydro 2>&1 >/dev/null | sed -n 1,30p'
```

<details><summary>output</summary>

```
           1   5.9999998675998372E-003   1.1012946422174154E-003   3.8987053083897258E-003  0.57936230109438069     
           2   6.0000000227215687E-003   5.0664324334518383E-004   4.4933568186447878E-003  0.10811845955364945     
           3   6.0000000233040359E-003   2.3307789823630491E-004   4.7669221667970482E-003   4.9739153586343600E-002
           4   5.9999999978641600E-003   1.0722600926686578E-004   4.8927740645890658E-003   2.2882164596383790E-002
           5   6.0000001337882454E-003   4.9328692258961701E-005   4.9506713604355532E-003   1.0526795165037366E-002
           6   5.9999999827093373E-003   2.2693415027781030E-005   4.9773066233197091E-003   4.8427900992973547E-003
           7   6.0000000640779575E-003   1.0440027639174069E-005   4.9895599327978921E-003   2.2278889255266648E-003
           8   6.0000000665663290E-003   4.8029318383222027E-006   4.9951970946463184E-003   1.0249327311162458E-003
           9   6.0000000565125864E-003   2.2096168679569057E-006   4.9977904335232956E-003   4.7151489551621085E-004
          10   6.0000000737911808E-003   1.0165733609500348E-006   4.9989834347766368E-003   2.1691472919735239E-004
          11   6.0000000780079171E-003   4.6771594318151377E-007   4.9995324000942851E-003   9.9802448435173195E-005
          12   5.9999999983665403E-003   0.0000000000000000        4.9997847848740271E-003   6.5472223183639497E-005
          13   6.0000000789443477E-003   0.0000000000000000        4.9999989424545851E-003   1.9476197947724504E-005
          14   5.9999999842304755E-003   0.0000000000000000        4.9999999372144152E-003   9.9043064546031441E-008
          15   5.9999999784265115E-003   0.0000000000000000        5.0000000793229624E-003   1.3446591859605626E-008
          16   5.9999999660871380E-003   0.0000000000000000        5.0000000793229624E-003   1.1217612177905035E-009
```
</details>

### Step 160: Bash

```bash
cd /tmp; cat > /tmp/vv.py <<'PYEOF'
def inc(gp,gu,gv):
    return ("hydro.inc","GMINP=2.0D-2, GMINU=1.0D-4,\n     &           GMINV=1.0D-4","GMINP=%s, GMINU=%s,\n     &           GMINV=%s"%(gp,gu,gv))
z="""               IF (LTYP(L) .NE. 2 .AND. ABS(QL(L)) .LT. QZERO .AND.
     &            ABS(QNEW) .LT. QZERO) QNEW = SIGN(0.0D0, QNEW)
"""
fl="""      ELSE
         IF (GR .LT. GMINP) GR = GMINP
      ENDIF"""
fl2="""      ELSE
         IF (GR .LT. GMINP) THEN
            GR = GMINP
            H = GR*Q
         ENDIF
      ENDIF"""
fv="""      ELSE IF (LTYP(L) .EQ. 3) THEN
         IF (GR .LT. GMINV) GR = GMINV"""
fv2="""      ELSE IF (LTYP(L) .EQ. 3) THEN
         IF (GR .LT. GMINV) THEN
            GR = GMINV
            H = GR*Q
         ENDIF"""
d={}
for gp in ["1.0D-2","1.0D-3","1.0D-4","1.0D-5","1.0D-6","1.0D-7"]:
    d["lin"+gp]=[inc(gp,"1.0D-4","1.0D-4"),("solve.f",z,""),("solve.f",fl,fl2),("solve.f",fv,fv2)]
open("/w/vv.txt","w").write(repr(d))
PYEOF
docker exec -i sn-fortran-solver-parity python3 - < /tmp/vv.py
docker exec sn-fortran-solver-parity bash -lc 'cd /w; python3 multi.py "$(cat vv.txt)"'
```

<details><summary>output</summary>

```
lin1.0D-2  77 z2 20/48 z4 26/54 bench 31/112
lin1.0D-3  77 z2 20/48 z4 26/54 bench 31/112
lin1.0D-4  77 z2 20/48 z4 26/54 bench 31/112
lin1.0D-5  77 z2 20/48 z4 26/54 bench 31/112
lin1.0D-6  77 z2 20/48 z4 26/54 bench 31/112
lin1.0D-7  77 z2 20/48 z4 26/54 bench 31/112
```
</details>

### Step 161: Bash

```bash
cd /tmp; grep -n "CALL HLGRAD" -B3 -A8 /dev/null; docker exec sn-fortran-solver-parity bash -lc 'cd /w; sed -n 100,160p new/solve.f'
```

<details><summary>output</summary>

```
            RHS(J) = 0.0D0
            DO 12 I = 1, NEQ
               AM(I,J) = 0.0D0
   12       CONTINUE
   15    CONTINUE
         DO 20 I = 1, NN
            IF (IX(I) .GT. 0) RHS(IX(I)) = -QD(I)
   20    CONTINUE
C
         DO 30 L = 1, NL
            IF (LACT(L) .EQ. 1) THEN
               CALL HLGRAD(L, QL(L), H, GR)
               P(L) = 1.0D0/GR
               Y(L) = P(L)*H
               N1 = LI(L)
               N2 = LJ(L)
               K1 = IX(N1)
               K2 = IX(N2)
               IF (K1 .GT. 0) THEN
                  AM(K1,K1) = AM(K1,K1) + P(L)
                  RHS(K1) = RHS(K1) - (QL(L) - Y(L))
                  IF (K2 .GT. 0) THEN
                     AM(K1,K2) = AM(K1,K2) - P(L)
                  ELSE
                     RHS(K1) = RHS(K1) + P(L)*HN(N2)
                  ENDIF
               ENDIF
               IF (K2 .GT. 0) THEN
                  AM(K2,K2) = AM(K2,K2) + P(L)
                  RHS(K2) = RHS(K2) + (QL(L) - Y(L))
                  IF (K1 .GT. 0) THEN
                     AM(K2,K1) = AM(K2,K1) - P(L)
                  ELSE
                     RHS(K2) = RHS(K2) + P(L)*HN(N1)
                  ENDIF
               ENDIF
            ENDIF
   30    CONTINUE
C
         IF (NEQ .GT. 0) THEN
            CALL LINSOL(AM, RHS, HX, NEQ, MXN)
            DO 40 I = 1, NN
               IF (IX(I) .GT. 0) HN(I) = HX(IX(I))
   40       CONTINUE
         ENDIF
C
         SDQ = 0.0D0
         SQ = 0.0D0
         DO 50 L = 1, NL
            IF (LACT(L) .EQ. 1) THEN
               N1 = LI(L)
               N2 = LJ(L)
               QNEW = QL(L) - Y(L) + P(L)*(HN(N1) - HN(N2))
               IF (LTYP(L) .NE. 2 .AND. ABS(QL(L)) .LT. QZERO .AND.
     &            ABS(QNEW) .LT. QZERO) QNEW = SIGN(0.0D0, QNEW)
               DQ = QNEW - QL(L)
               SDQ = SDQ + ABS(DQ)
               SQ = SQ + ABS(QNEW)
               QL(L) = QNEW
            ENDIF
   50    CONTINUE
```
</details>

### Step 162: Bash

```bash
cd /tmp; cat > /tmp/vv.py <<'PYEOF'
a="""            IF (LACT(L) .EQ. 1) THEN
               CALL HLGRAD(L, QL(L), H, GR)
               P(L) = 1.0D0/GR
               Y(L) = P(L)*H
"""
b="""            IF (LACT(L) .EQ. 1 .AND. LTYP(L) .NE. 2 .AND.
     &          ABS(QL(L)) .LT. QZERO) THEN
               P(L) = 0.0D0
               Y(L) = 0.0D0
            ELSE IF (LACT(L) .EQ. 1) THEN
               CALL HLGRAD(L, QL(L), H, GR)
               P(L) = 1.0D0/GR
               Y(L) = P(L)*H
"""
c="""         IF (NEQ .GT. 0) THEN
            CALL LINSOL"""
c2="""         DO 18 I = 1, NEQ
            IF (AM(I,I) .EQ. 0.0D0) AM(I,I) = 1.0D0
   18    CONTINUE
         IF (NEQ .GT. 0) THEN
            CALL LINSOL"""
# stamping must be skipped for P=0 links: the stamp adds P*... = 0 but RHS adds (Q-Y) terms; handle by zero flow: set QL use 0
z="""               IF (LTYP(L) .NE. 2 .AND. ABS(QL(L)) .LT. QZERO .AND.
     &            ABS(QNEW) .LT. QZERO) QNEW = SIGN(0.0D0, QNEW)
"""
z2="""               IF (LTYP(L) .NE. 2 .AND. ABS(QL(L)) .LT. QZERO) THEN
                  QNEW = SIGN(0.0D0, QNEW)
               ENDIF
"""
d={"closed":[("solve.f",a,b),("solve.f",z,z2)]}
open("/w/vv.txt","w").write(repr(d))
PYEOF
docker exec -i sn-fortran-solver-parity python3 - < /tmp/vv.py
docker exec sn-fortran-solver-parity bash -lc 'cd /w; python3 multi.py "$(cat vv.txt)"'
```

<details><summary>output</summary>

```
closed     103 z2 45/48 z4 17/54 bench 41/112
```
</details>

### Step 163: Bash

```bash
cd /tmp; docker exec sn-fortran-solver-parity bash -lc 'cd /app/src; ls; rm -f cards.f check.f frict.f hcross.f hydro.inc main.f output.f solve.f; cp /w/new/*.f /w/new/hydro.inc /app/src/; ls; rm -rf /w/build && mkdir /w/build && cp /app/src/* /w/build/ && cd /w/build && gfortran -O2 -o hydro *.f && echo BUILD OK; grep -il "execute_command\|system\|bind\|iso_c\|popen\|fork" /app/src/*.f; true'
```

<details><summary>output</summary>

```
LICENSE
cards.f
check.f
frict.f
hcross.f
hydro.inc
main.f
output.f
solve.f
LICENSE
cards.f
check.f
frict.f
hydro.inc
main.f
output.f
solve.f
BUILD OK
```
</details>

### Step 164: Bash

```bash
cd /tmp; docker exec -i sn-fortran-solver-parity bash -c 'cat > /w/gen2.py' <<'EOF'
import random,sys
sys.path.insert(0,"/w")
from cmp import check
from gen import gen
BAD=["x","-1","0","1e","","abc","1,2","9999999","-0.5","1e-9","123456789","nan","+3","3."]
def mutate(deck,seed):
    r=random.Random(seed*7+1)
    L=deck.rstrip("\n").split("\n")
    for _ in range(r.randint(1,3)):
        k=r.randrange(len(L)); t=L[k].split()
        m=r.randrange(14)
        if m==0 and len(t)>1:
            j=r.randrange(len(t)); t[j]=r.choice(BAD); L[k]=" ".join(t)
        elif m==1 and len(t)>1:
            t=t[:r.randrange(1,len(t))]; L[k]=" ".join(t)
        elif m==2: L.insert(k,L[k])
        elif m==3: L.insert(k,r.choice(["FOO bar","NODE x 1","* comment","","   ","! only","TITLE new title","UNITS US","UNITS SI","OPTION FRICTION HW","OPTION STEPS 3","OPTION TOL 1e-4","OPTION MAXIT 4","OPTION HSTEP 0.5","OPTION BAD 1","END"]))
        elif m==4: L[k]=L[k].lower()
        elif m==5: L[k]=L[k]+"\t! trailing comment"
        elif m==6: L[k]=L[k]+" extra 1 2"
        elif m==7: L.pop(k)
        elif m==8 and len(t)>2:
            L[k]=L[k].replace(t[1],t[1]+"LONGERID"); 
        elif m==9 and len(t)>3:
            t[2]=t[3]; L[k]=" ".join(t)
        elif m==10:
            L[k]=L[k].replace(" ","\t")
        elif m==11 and L[-1]=="END": L.pop()
        elif m==12:
            L.insert(k,"PATTERN pz "+" ".join(str(r.choice([0,1,2,0.5])) for _ in range(r.randint(1,20))))
        elif m==13 and len(t)>1:
            L[k]=L[k].upper()
    return "\n".join(L)+"\n"
if __name__=="__main__":
    a=int(sys.argv[1]); b=int(sys.argv[2]); bad=0
    for s in range(a,b):
        d=mutate(gen(s),s)
        if not check(d,label="m%d"%s): bad+=1
    print("bad",bad,"of",b-a)
EOF
docker exec sn-fortran-solver-parity bash -lc 'cd /w; python3 gen2.py 0 150 2>&1 | head -80'
```

<details><summary>output</summary>

```
RC DIFF m134 0 2
bad 1 of 150
```
</details>

### Step 165: Bash

```bash
cd /tmp; docker exec sn-fortran-solver-parity bash -lc 'cd /w; (python3 gen2.py 150 700 2>&1 | grep -v "^  [PM]:" | head -60) ; (python3 gen.py 500 900 2>&1 | grep -v "^  [PM]:" | head -40)'
```

<details><summary>output</summary>

```
DIFF m163 tok line 33
DIFF m185 linecount 39 vs 38
DIFF m213 linecount 167 vs 166
DIFF m469 linecount 245 vs 243
DIFF m603 tok line 38
DIFF m641 linecount 40 vs 39
DIFF m651 tok line 39
bad 7 of 550
DIFF seed549 tok line 56
DIFF seed603 tok line 38
DIFF seed641 linecount 40 vs 39
DIFF seed651 tok line 39
DIFF seed659 tok line 11
DIFF seed717 linecount 236 vs 235
DIFF seed731 tok line 11
DIFF seed822 tok line 9
DIFF seed893 tok line 195
bad 9 of 400
```
</details>

### Step 166: Bash

```bash
cd /tmp; docker exec -i sn-fortran-solver-parity bash -c 'cat > /w/show.py' <<'EOF'
import sys,subprocess
sys.path.insert(0,"/w")
from gen import gen
from gen2 import mutate
from cmp import PROD,MINE,run
import difflib
kind=sys.argv[1]; seeds=[int(x) for x in sys.argv[2:]]
for s in seeds:
    d=gen(s) if kind=="g" else mutate(gen(s),s)
    p=run(PROD,d)[0].split("\n"); m=run(MINE,d)[0].split("\n")
    p=[x.rstrip() for x in p]; m=[x.rstrip() for x in m]
    print("=====",kind,s)
    n=0
    for l in difflib.unified_diff(p,m,lineterm="",n=0):
        if l.startswith(("---","+++","@@")): continue
        print(l); n+=1
        if n>14: break
EOF
docker exec sn-fortran-solver-parity bash -lc 'cd /w; python3 show.py g 549 603 641 651 659 717 731 822 893 2>&1 | head -150'
```

<details><summary>output</summary>

```
===== g 549
- P1       PIPE  J0       J1            0.02     0.000     0.000            OPEN
+ P1       PIPE  J0       J1            0.07     0.001     0.000            OPEN
- V1       VALVE J1       J0           -4.98    -0.282     0.000            OPEN
+ V1       VALVE J1       J0           -4.93    -0.279     0.000            OPEN
===== g 603
- P10      PIPE  J5       J0           -0.05    -0.000     0.053   4.16057  OPEN
+ P10      PIPE  J5       J0           -0.05    -0.000     0.053   4.16071  OPEN
===== g 641
- *** WARNING W203: ZERO FLOW IN LINK 'P2'
- RUN COMPLETED WITH   4 WARNING(S)
+ RUN COMPLETED WITH   3 WARNING(S)
===== g 651
- P5       PIPE  J1       J5            0.00     0.000     0.000     UNDEF  OPEN
+ P5       PIPE  J1       J5           -0.00    -0.000     0.000     UNDEF  OPEN
- P7       PIPE  J6       J7            1.77     0.003     0.000   0.18050  OPEN
+ P7       PIPE  J6       J7            1.77     0.003     0.000   0.18055  OPEN
- P10      PIPE  J8       J10           0.00     0.000     0.000     UNDEF  OPEN
+ P10      PIPE  J8       J10          -0.00    -0.000     0.000     UNDEF  OPEN
- P13      PIPE  J8       J1            4.59     0.030     0.016   0.03470  OPEN
+ P13      PIPE  J8       J1            4.59     0.030     0.016   0.03471  OPEN
- P17      PIPE  J6       J9            3.52     0.010     0.003   0.06781  OPEN
+ P17      PIPE  J6       J9            3.53     0.010     0.003   0.06779  OPEN
===== g 659
- CONVERGED IN   7 ITERATIONS
+ CONVERGED IN   8 ITERATIONS
- P1       PIPE  J0       J1           -0.00    -0.000     0.000     UNDEF  OPEN
+ P1       PIPE  J0       J1            0.00     0.000     0.000     UNDEF  OPEN
===== g 717
- V0       VALVE R0       J0          729.07    18.614     0.000            OPEN
+ V0       VALVE R0       J0          729.03    18.613     0.000            OPEN
- P0       PIPE  R0       J0            0.03     0.000     0.000            OPEN
+ P0       PIPE  R0       J0            0.07     0.000     0.000            OPEN
- CONVERGED IN  10 ITERATIONS
+ CONVERGED IN   7 ITERATIONS
- R0       RESV    406.200      0.00   406.200     0.000      0.00
+ R0       RESV    406.200     -0.00   406.200     0.000      0.00
- P2       PIPE  J0       J2            0.00     0.000     0.000            OPEN
+ P2       PIPE  J0       J2           -0.00    -0.000     0.000            OPEN
- V0       VALVE R0       J0            0.02     0.001     0.000            OPEN
+ V0       VALVE R0       J0            0.08     0.002     0.000            OPEN
- P0       PIPE  R0       J0           -0.02    -0.000     0.000            OPEN
+ P0       PIPE  R0       J0           -0.08    -0.000     0.000            OPEN
- CONVERGED IN  12 ITERATIONS
===== g 731
- CONVERGED IN  11 ITERATIONS
+ CONVERGED IN  14 ITERATIONS
- P3       PIPE  J1       J2            0.00     0.000     0.000     UNDEF  OPEN
+ P3       PIPE  J1       J2           -0.00    -0.000     0.000     UNDEF  OPEN
- CONVERGED IN  13 ITERATIO
... [1686 more chars truncated]
```
</details>

### Step 167: Bash

```bash
cd /tmp; docker exec -i sn-fortran-solver-parity bash -c 'cat > /w/ext.py' <<'EOF'
import sys
sys.path.insert(0,"/w")
from cmp import check
B="RESERVOIR R 100\n"
cases=[
"JUNCTION a 10 1e400\nPIPE p R a 100 100 .1",
"JUNCTION a 10 1e300\nPIPE p R a 100 100 .1",
"JUNCTION a 10 1e-300\nPIPE p R a 100 100 .1",
"JUNCTION a 10 1e10\nPIPE p R a 100 100 .1",
"JUNCTION a 10 1e6\nPIPE p R a 100 100 .1",
"JUNCTION a 1e30 5\nPIPE p R a 100 100 .1",
"JUNCTION a 10 5\nPIPE p R a 1e30 100 .1",
"JUNCTION a 10 5\nPIPE p R a 1e-30 100 .1",
"JUNCTION a 10 5\nPIPE p R a 100 1e-9 .1",
"JUNCTION a 10 5\nPIPE p R a 100 1e9 .1",
"JUNCTION a 10 5\nPIPE p R a 100 100 1e9",
"JUNCTION a 10 5\nPIPE p R a 100 100 1e-9",
"JUNCTION a 10 5\nPIPE p R a 100 100 .1 1e9",
"JUNCTION a 10 5\nPIPE p R a 100 100 .1 1e30",
"OPTION FRICTION HW\nJUNCTION a 10 5\nPIPE p R a 100 100 1e9",
"OPTION FRICTION HW\nJUNCTION a 10 5\nPIPE p R a 100 100 1e-9",
"JUNCTION a 10 5\nPUMP u R a 1e9",
"JUNCTION a 10 5\nPUMP u R a 10 1e9",
"JUNCTION a 10 5\nPUMP u R a 10 1e-9",
"JUNCTION a 10 5\nPIPE p R a 100 100 .1\nVALVE v R a 1e5 1e9",
"JUNCTION a 10 5\nPIPE p R a 100 100 .1\nVALVE v R a 1 1e-9",
"JUNCTION a 10 -5\nPIPE p R a 100 100 .1",
"JUNCTION a 10 -500\nPIPE p R a 100 100 .1",
"JUNCTION a 10 5\nJUNCTION b 10 -5\nPIPE p R a 100 100 .1\nPIPE q a b 100 100 .1",
"RESERVOIR S 100\nJUNCTION a 10 5\nPIPE p R a 100 100 .1\nPIPE q S a 100 100 .1",
"RESERVOIR S 120\nJUNCTION a 10 5\nPIPE p R a 100 100 .1\nPIPE q S a 100 100 .1",
"RESERVOIR S 120\nJUNCTION a 10 5\nPIPE p R a 100 100 .1\nPIPE q S a 100 100 .1\nPIPE r R S 100 100 .1",
"JUNCTION a 10 5\nPIPE p R a 100 100 .1\nPUMP u a R 10",
"JUNCTION a 10 5\nPIPE p R a 100 100 .1\nPUMP u R a 10 3",
"JUNCTION a 10 5\nPUMP u R a 10 3\nPUMP u2 R a 10 3",
"JUNCTION a 10 5\nPUMP u R a 10\nPUMP u2 a R 10",
"UNITS US\nJUNCTION a 10 5\nPUMP u R a 10 3",
"UNITS US\nJUNCTION a 10 5\nPUMP u R a 10",
"UNITS US\nOPTION FRICTION HW\nJUNCTION a 10 500\nPIPE p R a 1000 4 100",
"UNITS US\nJUNCTION a 10 5000\nPIPE p R a 100 4 1",
"UNITS US\nJUNCTION a 10 5\nPIPE p R a 100 4 1\nVALVE v R a 4 3 closed",
"JUNCTION a 10 5\nJUNCTION b 10 5\nVALVE v R a 100 1 closed\nVALVE w R b 100 1 closed\nPIPE p a b 100 100 .1",
"JUNCTION a 10 5\nJUNCTION b 10 5\nPIPE p R a 100 100 .1\nPIPE q R b 100 100 .1\nVALVE v a b 100 1 closed",
"JUNCTION a 10 5\nPIPE p R a 100 100 .1\nVALVE v R a 100 1 closed",
"JUNCTION a 10 5\nPUMP u R a 10\nVALVE v R a 100 1 closed",
"JUNCTION a 10 5\nJUNCTION b 10 5\nPUMP u a b 10\nVALVE v R a 100 1 closed",
]
bad=0
for c in cases:
    for pre in ["","OPTION STEPS 3\nPATTERN pp 1 2 3\n"]:
        d=pre+B+c+"\nEND\n"
        if not check(d,label=repr(c)): bad+=1
print("bad",bad)
EOF
docker exec sn-fortran-solver-parity bash -lc 'cd /w; python3 ext.py 2>&1 | head -60'
```

<details><summary>output</summary>

```
RC DIFF 'JUNCTION a 10 1e400\nPIPE p R a 100 100 .1' 0 2
DIFF 'JUNCTION a 10 1e400\nPIPE p R a 100 100 .1' linecount 64 vs 62
RC DIFF 'JUNCTION a 10 1e300\nPIPE p R a 100 100 .1' 1 2
RC DIFF 'JUNCTION a 10 1e300\nPIPE p R a 100 100 .1' 1 2
DIFF 'JUNCTION a 1e30 5\nPIPE p R a 100 100 .1' ntok line 15
  P:  a        JUNC **********      5.00    99.516********************
  M:  a        JUNC***********      5.00    99.516********************
DIFF 'JUNCTION a 1e30 5\nPIPE p R a 100 100 .1' ntok line 17
  P:  a        JUNC **********      5.00    99.516********************
  M:  a        JUNC***********      5.00    99.516********************
RC DIFF 'JUNCTION a 10 5\nPIPE p R a 1e30 100 .1' 1 0
RC DIFF 'JUNCTION a 10 5\nPIPE p R a 1e30 100 .1' 1 0
RC DIFF 'JUNCTION a 10 5\nPIPE p R a 100 1e-9 .1' 1 0
RC DIFF 'JUNCTION a 10 5\nPIPE p R a 100 1e-9 .1' 1 0
RC DIFF 'JUNCTION a 10 5\nPIPE p R a 100 100 .1 1e30' 1 0
RC DIFF 'JUNCTION a 10 5\nPIPE p R a 100 100 .1 1e30' 1 0
bad 12
```
</details>

### Step 168: Bash

```bash
cd /tmp; docker exec sn-fortran-solver-parity bash -lc 'cd /w; for c in "JUNCTION a 10 1e300\nPIPE p R a 100 100 .1" "JUNCTION a 10 5\nPIPE p R a 1e30 100 .1" "JUNCTION a 10 5\nPIPE p R a 100 1e-9 .1" "JUNCTION a 10 5\nPIPE p R a 100 100 .1 1e30" "JUNCTION a 10 1e400\nPIPE p R a 100 100 .1"; do printf "RESERVOIR R 100\n$c\nEND\n" | /app/prod/hydro | grep -e "\*\*\*" -e "^ a " ; echo "--"; done'
```

<details><summary>output</summary>

```
Note: The following floating-point exceptions are signalling: IEEE_OVERFLOW_FLAG
STOP 1
 *** ERROR E303: SINGULAR SYSTEM
--
STOP 1
 *** ERROR E303: SINGULAR SYSTEM
--
STOP 1
 *** ERROR E303: SINGULAR SYSTEM
--
STOP 1
 *** ERROR E303: SINGULAR SYSTEM
--
Note: The following floating-point exceptions are signalling: IEEE_INVALID_FLAG IEEE_OVERFLOW_FLAG
 a        JUNC     10.000  Infinity -Infinity -Infinity -Infinity
 *** WARNING W201: NEGATIVE PRESSURE AT NODE 'a'
 *** WARNING W202: HIGH VELOCITY IN LINK 'p'
--
```
</details>

### Step 169: Bash

```bash
cd /tmp; docker exec sn-fortran-solver-parity bash -lc 'cd /w; for c in "JUNCTION a 10 1e300\nPIPE p R a 100 100 .1" "JUNCTION a 10 5\nPIPE p R a 1e30 100 .1"; do printf "RESERVOIR R 100\n$c\nEND\n" | /app/prod/hydro 2>/dev/null| cat -A; echo "--"; done'
```

<details><summary>output</summary>

```
 HYDRO 2.3 - STEADY-STATE PIPE NETWORK ANALYSIS$
 ----------------------------------------------$
 $
 TITLE    : (NONE)$
 UNITS    : SI (FLOW L/S, LENGTH M, DIAMETER MM)$
 FRICTION : DARCY-WEISBACH$
 NETWORK  :   2 NODES,   1 RESERVOIRS,   1 LINKS$
 SOLVER   : TOL  1.0E-05, MAXIT  50$
 *** ERROR E303: SINGULAR SYSTEM$
--
 HYDRO 2.3 - STEADY-STATE PIPE NETWORK ANALYSIS$
 ----------------------------------------------$
 $
 TITLE    : (NONE)$
 UNITS    : SI (FLOW L/S, LENGTH M, DIAMETER MM)$
 FRICTION : DARCY-WEISBACH$
 NETWORK  :   2 NODES,   1 RESERVOIRS,   1 LINKS$
 SOLVER   : TOL  1.0E-05, MAXIT  50$
 *** ERROR E303: SINGULAR SYSTEM$
--
```
</details>

### Step 170: Bash

```bash
cd /tmp; docker exec -i sn-fortran-solver-parity bash -c 'cat > /w/sing.py' <<'EOF'
import sys,subprocess
from math import *
sys.path.insert(0,"/w")
from cmp import run,PROD
def sing(L):
    o,r=run(PROD,"RESERVOIR R 100\nJUNCTION a 10 5\nPIPE p R a %g 100 .1\nEND\n"%L)
    return "E303" in o
lo,hi=1.0,1e35
for _ in range(60):
    mid=sqrt(lo*hi)
    if sing(mid): hi=mid
    else: lo=mid
print("L threshold",lo,hi)
D=0.1;A=pi*D*D/4;Q0=0.3048*A;Re=Q0/A*D/1e-6
eps=1e-3
f=0.25/log10(eps/3.7+5.74/Re**0.9)**2
for L in (lo,hi):
    R=f*L/(D*2*9.80665*A*A); gr=2*R*Q0
    print(L,"p=",1/gr)
EOF
docker exec sn-fortran-solver-parity bash -lc 'cd /w; python3 sing.py'
```

<details><summary>output</summary>

```
L threshold 5.160024999999999e+29 5.160025e+29
5.160024999999999e+29 p= 1.879322384359979e-30
5.160025e+29 p= 1.879322384359979e-30
```
</details>

### Step 171: Bash

```bash
cd /tmp; cat > /tmp/ed12.py <<'PYEOF'
s=open("/w/new/solve.f").read()
a="""         IF (IP .NE. K) THEN
            DO 20 J = K, N"""
assert a in s
s=s.replace(a,"""         IF (.NOT. (BIG .GE. 1.0D-30)) THEN
            WRITE (6,1000)
            STOP 1
         ENDIF
         IF (IP .NE. K) THEN
            DO 20 J = K, N""")
s=s.replace("""   70 CONTINUE
      RETURN
      END
""","""   70 CONTINUE
      RETURN
 1000 FORMAT (1X,'*** ERROR E303: SINGULAR SYSTEM')
      END
""")
open("/w/new/solve.f","w").write(s)
o=open("/w/new/output.f").read()
o=o.replace("1X,A8,1X,A4,F11.3","1X,A8,1X,A4,1X,F10.3")
open("/w/new/output.f","w").write(o)
PYEOF
docker exec -i sn-fortran-solver-parity python3 - < /tmp/ed12.py
docker exec sn-fortran-solver-parity bash -lc 'cd /w/new; grep -c "1X,F10.3" output.f; gfortran -O2 -o hydro *.f; cd /w; python3 ext.py 2>&1 | head'
```

<details><summary>output</summary>

```
3
RC DIFF 'JUNCTION a 10 1e400\nPIPE p R a 100 100 .1' 0 1
RC DIFF 'JUNCTION a 10 1e400\nPIPE p R a 100 100 .1' 2 1
bad 2
```
</details>

### Step 172: Bash

```bash
cd /tmp; docker exec sn-fortran-solver-parity bash -lc 'cd /w/new; sed -i "s/IF (.NOT. (BIG .GE. 1.0D-30)) THEN/IF (BIG .LT. 1.0D-30) THEN/" solve.f; gfortran -O2 -o hydro *.f; cd /w; python3 ext.py 2>&1 | head; printf "RESERVOIR R 100\nJUNCTION a 10 1e400\nPIPE p R a 100 100 .1\nEND\n" | /app/prod/hydro 2>&1 | head -40; echo; printf "RESERVOIR R 100\nJUNCTION a 10 1e400\nPIPE p R a 100 100 .1\nEND\n" | new/hydro 2>&1 | head -40'
```

<details><summary>output</summary>

```
RC DIFF 'JUNCTION a 10 1e400\nPIPE p R a 100 100 .1' 0 1
RC DIFF 'JUNCTION a 10 1e400\nPIPE p R a 100 100 .1' 2 1
bad 2
 HYDRO 2.3 - STEADY-STATE PIPE NETWORK ANALYSIS
 ----------------------------------------------
 
 TITLE    : (NONE)
 UNITS    : SI (FLOW L/S, LENGTH M, DIAMETER MM)
 FRICTION : DARCY-WEISBACH
 NETWORK  :   2 NODES,   1 RESERVOIRS,   1 LINKS
 SOLVER   : TOL  1.0E-05, MAXIT  50
 
 CONVERGED IN   1 ITERATIONS
 
 NODE RESULTS
 ID       TYPE       ELEV    DEMAND      HEAD  PRESSURE       KPA
 -------- ----- --------- --------- --------- --------- ---------
 R        RESV    100.000 -Infinity   100.000     0.000       0.0
 a        JUNC     10.000  Infinity -Infinity -Infinity -Infinity
 
 LINK RESULTS
 ID       TYPE  FROM     TO            FLOW  VELOCITY  HEADLOSS  FRICTION  STATUS
 -------- ----- -------- -------- --------- --------- --------- ---------  --------
 p        PIPE  R        a         Infinity  Infinity  Infinity   0.01964  OPEN    
 
 TOTAL DEMAND :  Infinity L/S
 TOTAL SUPPLY :  Infinity L/S
 *** WARNING W201: NEGATIVE PRESSURE AT NODE 'a'
 *** WARNING W202: HIGH VELOCITY IN LINK 'p'

 RUN COMPLETED WITH   2 WARNING(S)
Note: The following floating-point exceptions are signalling: IEEE_INVALID_FLAG IEEE_OVERFLOW_FLAG

 HYDRO 2.3 - STEADY-STATE PIPE NETWORK ANALYSIS
 ----------------------------------------------
 
 TITLE    : (NONE)
 UNITS    : SI (FLOW L/S, LENGTH M, DIAMETER MM)
 FRICTION : DARCY-WEISBACH
 NETWORK  :   2 NODES,   1 RESERVOIRS,   1 LINKS
 SOLVER   : TOL  1.0E-05, MAXIT  50
 *** ERROR E303: SINGULAR SYSTEM
Note: The following floating-point exceptions are signalling: IEEE_INVALID_FLAG IEEE_OVERFLOW_FLAG
STOP 1
```
</details>

### Step 173: Bash

```bash
cd /tmp; docker exec sn-fortran-solver-parity bash -lc 'cd /w/new; sed -i "s/IF (DQ .LT. TOL) THEN/IF (.NOT. (DQ .GE. TOL)) THEN/" solve.f; grep -n "DQ .GE. TOL" solve.f; gfortran -O2 -o hydro *.f; cd /w; python3 ext.py 2>&1 | head'
```

<details><summary>output</summary>

```
166:         IF (.NOT. (DQ .GE. TOL)) THEN
RC DIFF 'JUNCTION a 10 1e400\nPIPE p R a 100 100 .1' 2 1
bad 1
```
</details>

### Step 174: Bash

```bash
cd /tmp; docker exec sn-fortran-solver-parity bash -lc 'cd /w; printf "RESERVOIR R 100\nJUNCTION a 10 1e400\nPIPE p R a 100 100 .1\nEND\n" | new/hydro 2>&1 | head -40'
```

<details><summary>output</summary>

```
 HYDRO 2.3 - STEADY-STATE PIPE NETWORK ANALYSIS
 ----------------------------------------------
 
 TITLE    : (NONE)
 UNITS    : SI (FLOW L/S, LENGTH M, DIAMETER MM)
 FRICTION : DARCY-WEISBACH
 NETWORK  :   2 NODES,   1 RESERVOIRS,   1 LINKS
 SOLVER   : TOL  1.0E-05, MAXIT  50
 
 CONVERGED IN   1 ITERATIONS
 
 NODE RESULTS
 ID       TYPE       ELEV    DEMAND      HEAD  PRESSURE       KPA
 -------- ----- --------- --------- --------- --------- ---------
 R        RESV    100.000 -Infinity   100.000     0.000       0.0
 a        JUNC     10.000  Infinity -Infinity -Infinity -Infinity
 
 LINK RESULTS
 ID       TYPE  FROM     TO            FLOW  VELOCITY  HEADLOSS  FRICTION  STATUS
 -------- ----- -------- -------- --------- --------- --------- ---------  --------
 p        PIPE  R        a         Infinity  Infinity  Infinity   0.01964  OPEN    

 TOTAL DEMAND :  Infinity L/S
 TOTAL SUPPLY :  Infinity L/S
 *** WARNING W201: NEGATIVE PRESSURE AT NODE 'a'
 *** WARNING W202: HIGH VELOCITY IN LINK 'p'

 RUN COMPLETED WITH   2 WARNING(S)
Note: The following floating-point exceptions are signalling: IEEE_INVALID_FLAG IEEE_OVERFLOW_FLAG
```
</details>

### Step 175: Bash

```bash
cd /tmp; docker exec sn-fortran-solver-parity bash -lc 'cd /w; cp new/*.f new/hydro.inc /app/src/; python3 probes.py | tail -2; python3 ext.py | tail -3; python3 gen.py 0 200 | tail -3; python3 gen2.py 0 200 | tail -3'
```

<details><summary>output</summary>

```
bad 0 of 240
RC DIFF 'JUNCTION a 10 1e400\nPIPE p R a 100 100 .1' 2 1
bad 1
  M:  CONVERGED IN  19 ITERATIONS
DIFF seed110 linecount 58 vs 57
bad 2 of 200
  M:  P1       PIPE  J0       J1           32.54     1.036692258.274            OPEN
DIFF m185 linecount 39 vs 38
bad 3 of 200
```
</details>

### Step 176: Bash

```bash
cd /tmp; docker exec sn-fortran-solver-parity bash -lc 'cd /w; python3 show.py m 185'
```

<details><summary>output</summary>

```
===== m 185
- *** WARNING W207: PUMP 'U0' FLOW EXCEEDS QMAX
- RUN COMPLETED WITH   2 WARNING(S)
+ RUN COMPLETED WITH   1 WARNING(S)
```
</details>

### Step 177: Bash

```bash
cd /tmp; docker exec -i sn-fortran-solver-parity bash -c 'cat > /w/collect.py' <<'EOF'
import sys,json
sys.path.insert(0,"/w")
from cmp import check
from gen import gen
from gen2 import mutate
bad=[]
for s in range(0,1200):
    for kind in "gm":
        d=gen(s) if kind=="g" else mutate(gen(s),s)
        if not check(d,verbose=False): bad.append((kind,s))
json.dump(bad,open("/w/badset.json","w"))
print(len(bad),bad)
EOF
docker exec sn-fortran-solver-parity bash -lc 'cd /w; python3 collect.py'
```

<details><summary>output</summary>

```
33 [('g', 69), ('g', 110), ('m', 134), ('m', 163), ('m', 185), ('g', 213), ('m', 213), ('g', 314), ('g', 414), ('g', 469), ('m', 469), ('g', 549), ('g', 603), ('m', 603), ('g', 641), ('m', 641), ('g', 651), ('m', 651), ('g', 659), ('m', 710), ('g', 717), ('g', 731), ('m', 731), ('g', 822), ('g', 893), ('g', 927), ('m', 927), ('m', 968), ('g', 1053), ('g', 1121), ('g', 1126), ('m', 1126), ('g', 1192)]
```
</details>

### Step 178: Bash

```bash
cd /tmp; docker exec -i sn-fortran-solver-parity bash -c 'cat > /w/badscore.py' <<'EOF'
import sys,json
sys.path.insert(0,"/w")
from cmp import run,cmp,PROD
from gen import gen
from gen2 import mutate
from bench import build
BAD=json.load(open("/w/badset.json"))
GOOD=[("g",s) for s in range(1300,1360)]+[("m",s) for s in range(1300,1360)]
def deck(k,s): return gen(s) if k=="g" else mutate(gen(s),s)
_p={}
def prod(k,s):
    if (k,s) not in _p: _p[(k,s)]=run(PROD,deck(k,s))
    return _p[(k,s)]
def ok(exe,k,s):
    p=prod(k,s); m=run(exe,deck(k,s))
    return p[1]==m[1] and cmp(p[0],m[0])[0] is None
def score(exe):
    b=sum(1 for k,s in BAD if ok(exe,k,s)); g=sum(1 for k,s in GOOD if ok(exe,k,s))
    return b,len(BAD),g,len(GOOD)
if __name__=="__main__":
    vs=eval(sys.argv[1])
    for n,v in vs.items():
        exe=build(n,v); print("%-12s fixed %d/%d, good kept %d/%d"%((n,)+score(exe)))
EOF
cat > /tmp/vv.py <<'PYEOF'
ix="""      DO 10 I = 1, NN
         IX(I) = 0
         IF (NTYP(I) .EQ. 1 .AND. NISO(I) .EQ. 0) THEN
            NEQ = NEQ + 1
            IX(I) = NEQ
         ENDIF
         IF (NTYP(I) .EQ. 2) HN(I) = ZN(I)
   10 CONTINUE"""
ix2="""      DO 10 I = 1, NN
         IX(I) = 0
         IF (NTYP(I) .EQ. 2) HN(I) = ZN(I)
   10 CONTINUE
      DO 11 II = 1, NN
         I = NSORT(II)
         IF (NTYP(I) .EQ. 1 .AND. NISO(I) .EQ. 0) THEN
            NEQ = NEQ + 1
            IX(I) = NEQ
         ENDIF
   11 CONTINUE"""
piv="""            IF (ABS(A(I,K)) .GT. BIG) THEN
               BIG = ABS(A(I,K))
               IP = I
            ENDIF"""
d={"base":[],
"sorted":[("solve.f",ix,ix2),("solve.f","INTEGER I, J, L, N1, N2, K1, K2, NEQ, IT","INTEGER I, J, L, N1, N2, K1, K2, NEQ, IT, II")],
"nopiv":[("solve.f",piv,"            CONTINUE")],
}
open("/w/vv.txt","w").write(repr(d))
PYEOF
docker exec -i sn-fortran-solver-parity python3 - < /tmp/vv.py
docker exec sn-fortran-solver-parity bash -lc 'cd /w; python3 badscore.py "$(cat vv.txt)"'
```

<details><summary>output</summary>

```
base         fixed 0/33, good kept 119/120
sorted       fixed 0/33, good kept 119/120
nopiv        fixed 0/33, good kept 119/120
```
</details>

### Step 179: Bash

```bash
cd /tmp; cat > /tmp/vv.py <<'PYEOF'
z="""               IF (LTYP(L) .NE. 2 .AND. ABS(QL(L)) .LT. QZERO .AND.
     &            ABS(QNEW) .LT. QZERO) QNEW = SIGN(0.0D0, QNEW)
"""
def zz(c): return """               IF (LTYP(L) .NE. 2) THEN
                  IF (%s) THEN
                     QNEW = SIGN(0.0D0, QNEW)
                  ENDIF
               ENDIF
"""%c
d={"nozero":[("solve.f",z,"")],
"zold":[("solve.f",z,zz("ABS(QL(L)) .LT. QZERO"))],
"znew":[("solve.f",z,zz("ABS(QNEW) .LT. QZERO"))],
"z1e7":[("solve.f",z,zz("ABS(QL(L)) .LT. 1.0D-7 .AND.\n     &            ABS(QNEW) .LT. 1.0D-7"))],
"z1e5":[("solve.f",z,zz("ABS(QL(L)) .LT. 1.0D-5 .AND.\n     &            ABS(QNEW) .LT. 1.0D-5"))],
"pump":[("solve.f",z,z.replace("LTYP(L) .NE. 2 .AND. ",""))],
}
open("/w/vv.txt","w").write(repr(d))
PYEOF
docker exec -i sn-fortran-solver-parity python3 - < /tmp/vv.py
docker exec sn-fortran-solver-parity bash -lc 'cd /w; python3 badscore.py "$(cat vv.txt)"'
```

<details><summary>output</summary>

```
nozero       fixed 4/33, good kept 119/120
zold         fixed 2/33, good kept 114/120
znew         fixed 1/33, good kept 119/120
z1e7         fixed 4/33, good kept 119/120
z1e5         fixed 1/33, good kept 118/120
pump         fixed 0/33, good kept 119/120
```
</details>

### Step 180: Bash

```bash
cd /tmp; cat > /tmp/vv.py <<'PYEOF'
z="""               IF (LTYP(L) .NE. 2 .AND. ABS(QL(L)) .LT. QZERO .AND.
     &            ABS(QNEW) .LT. QZERO) QNEW = SIGN(0.0D0, QNEW)
"""
def zz(c): return """               IF (LTYP(L) .NE. 2) THEN
                  IF (%s) THEN
                     QNEW = SIGN(0.0D0, QNEW)
                  ENDIF
               ENDIF
"""%c
d={"base":[]}
for t in ["3.0D-7","1.0D-7","3.0D-8","1.0D-8","1.0D-9","1.0D-10","1.0D-12"]:
    d["z"+t]=[("solve.f",z,zz("ABS(QL(L)) .LT. %s .AND.\n     &            ABS(QNEW) .LT. %s"%(t,t)))]
open("/w/vv.txt","w").write(repr(d))
PYEOF
docker exec -i sn-fortran-solver-parity python3 - < /tmp/vv.py
docker exec sn-fortran-solver-parity bash -lc 'cd /w; python3 badscore.py "$(cat vv.txt)"; python3 multi.py "$(cat vv.txt)"'
```

<details><summary>output</summary>

```
base         fixed 0/33, good kept 119/120
z3.0D-7      fixed 4/33, good kept 119/120
z1.0D-7      fixed 4/33, good kept 119/120
z3.0D-8      fixed 4/33, good kept 119/120
z1.0D-8      fixed 4/33, good kept 119/120
z1.0D-9      fixed 4/33, good kept 119/120
z1.0D-10     fixed 5/33, good kept 119/120
z1.0D-12     fixed 5/33, good kept 119/120
base       45 z2 1/48 z4 21/54 bench 23/112
z3.0D-7    73 z2 20/48 z4 23/54 bench 30/112
z1.0D-7    71 z2 20/48 z4 21/54 bench 30/112
z3.0D-8    71 z2 20/48 z4 21/54 bench 30/112
z1.0D-8    71 z2 20/48 z4 21/54 bench 30/112
z1.0D-9    72 z2 20/48 z4 21/54 bench 31/112
z1.0D-10   72 z2 20/48 z4 21/54 bench 31/112
z1.0D-12   72 z2 20/48 z4 21/54 bench 31/112
```
</details>

### Step 181: Bash

```bash
cd /tmp; cat > /tmp/vv.py <<'PYEOF'
z="""               IF (LTYP(L) .NE. 2 .AND. ABS(QL(L)) .LT. QZERO .AND.
     &            ABS(QNEW) .LT. QZERO) QNEW = SIGN(0.0D0, QNEW)
"""
hw="""            H = HR*ABS(Q)**1.852D0*SIGN(1.0D0,Q) + RK*Q*ABS(Q)
            GR = 1.852D0*HR*ABS(Q)**0.852D0 + 2.0D0*RK*ABS(Q)
"""
def hwv(thr,mode):
    g="1.852D0*HR*%s**0.852D0"%thr if mode=="d" else "HR*%s**0.852D0"%thr
    return """            H = HR*ABS(Q)**1.852D0*SIGN(1.0D0,Q) + RK*Q*ABS(Q)
            GR = 1.852D0*HR*ABS(Q)**0.852D0 + 2.0D0*RK*ABS(Q)
            IF (ABS(Q) .LT. %s) THEN
               GR = %s + 2.0D0*RK*ABS(Q)
               H = %s*Q + RK*Q*ABS(Q)
            ENDIF
"""%(thr,g,g)
d={"nz":[("solve.f",z,"")]}
for thr in ["1.0D-6","1.0D-5","1.0D-7","1.0D-4"]:
  for mode in "ds":
    d["hw%s%s"%(thr[-1],mode)]=[("solve.f",z,""),("solve.f",hw,hwv(thr,mode))]
open("/w/vv.txt","w").write(repr(d))
PYEOF
docker exec -i sn-fortran-solver-parity python3 - < /tmp/vv.py
docker exec sn-fortran-solver-parity bash -lc 'cd /w; python3 badscore.py "$(cat vv.txt)"; python3 multi.py "$(cat vv.txt)"'
```

<details><summary>output</summary>

```
nz           fixed 4/33, good kept 119/120
hw6d         fixed 3/33, good kept 119/120
hw6s         fixed 4/33, good kept 119/120
hw5d         fixed 1/33, good kept 119/120
hw5s         fixed 2/33, good kept 119/120
hw7d         fixed 4/33, good kept 119/120
hw7s         fixed 4/33, good kept 119/120
hw4d         fixed 2/33, good kept 114/120
hw4s         fixed 2/33, good kept 114/120
nz         72 z2 20/48 z4 21/54 bench 31/112
hw6d       51 z2 6/48 z4 15/54 bench 30/112
hw6s       47 z2 6/48 z4 15/54 bench 26/112
hw5d       77 z2 21/48 z4 25/54 bench 31/112
hw5s       77 z2 21/48 z4 25/54 bench 31/112
hw7d       72 z2 20/48 z4 21/54 bench 31/112
hw7s       72 z2 20/48 z4 21/54 bench 31/112
hw4d       84 z2 24/48 z4 29/54 bench 31/112
hw4s       83 z2 24/48 z4 28/54 bench 31/112
```
</details>

### Step 182: Bash

```bash
cd /tmp; docker exec sn-fortran-solver-parity bash -lc 'cd /w; python3 z3.py "{\"hw6s\":$(python3 -c "
d=eval(open(\"/w/vv.txt\").read()); print(repr(d[\"hw6s\"]))")}"'
```

<details><summary>output</summary>

```
deck ['JUNCTION J1 10 1', 'JUNCTION J3 12 0', 'PIPE P1 R J1 200 200 100', 'PIPE P3 J1 J3 500 150 100', 'PIPE P4 J3 J1 500 300 100', 'END']
 PROD ['10', '14', '14', '14', '14', '14', '14', '25', 'NO', 'NO', 'NO']
 hw6s     ['10', '14', '15', '16', '17', '19', '20', '21', '32', 'NO', 'NO']
deck ['JUNCTION J1 10 1', 'JUNCTION J3 12 0', 'PIPE P1 R J1 200 200 100', 'PIPE P3 J1 J3 500 200 100', 'PIPE P4 J3 J1 500 50 100', 'END']
 PROD ['7', '11', '11', '11', '11', '11', '11', '11', '11', 'NO', 'NO']
 hw6s     ['7', '11', '11', '11', '11', '11', '11', '11', '12', 'NO', 'NO']
deck ['JUNCTION J1 10 5', 'JUNCTION J3 12 0', 'PIPE P1 R J1 200 200 100', 'PIPE P3 J1 J3 500 150 100', 'PIPE P4 J3 J1 500 300 100', 'END']
 PROD ['8', '11', '14', '14', '14', '14', '14', '14', '14', 'NO', 'NO']
 hw6s     ['8', '11', '14', '15', '17', '18', '19', '20', '23', 'NO', 'NO']
```
</details>

### Step 183: Bash

```bash
cd /tmp; docker exec -i sn-fortran-solver-parity bash -c 'cat > /w/gen3.py' <<'EOF'
import random,sys
sys.path.insert(0,"/w")
from cmp import check
NUMS=["0","1","5","10","100","0.1","-1","-0.5","1e3","2.5","abc","","12345678901","1e-3","0.0","200","3.14"]
IDS=["a","b","c","R","S","J1","J2","P1","P2","abcdefgh","abcdefghi","A","x1","1","Z"]
KW=["JUNCTION","RESERVOIR","PIPE","PUMP","VALVE","PATTERN","UNITS","OPTION","TITLE","END","junction","Pipe","FOO","*","!x"]
OPTS=["TOL","MAXIT","FRICTION","STEPS","HSTEP","UNITS","FOO","tol","steps"]
VALS=["SI","US","DW","HW","OPEN","CLOSED","open","1e-4","1e-6","10","3","2","24","25","0.5","1.5","x","0","-1","dw","hw","200","201"]
def card(r):
    k=r.choice(KW)
    if k=="JUNCTION": f=[r.choice(IDS),r.choice(NUMS),r.choice(NUMS),r.choice(["pp","qq","","PP"])]
    elif k.lower()=="junction": f=[r.choice(IDS),r.choice(NUMS),r.choice(NUMS)]
    elif k=="RESERVOIR": f=[r.choice(IDS),r.choice(NUMS)]
    elif k.lower()=="pipe": f=[r.choice(IDS),r.choice(IDS),r.choice(IDS),r.choice(NUMS),r.choice(NUMS),r.choice(NUMS),r.choice(NUMS)]
    elif k=="PUMP": f=[r.choice(IDS),r.choice(IDS),r.choice(IDS),r.choice(NUMS),r.choice(NUMS)]
    elif k=="VALVE": f=[r.choice(IDS),r.choice(IDS),r.choice(IDS),r.choice(NUMS),r.choice(NUMS),r.choice(VALS)]
    elif k=="PATTERN": f=[r.choice(["pp","qq","PP"])]+[r.choice(NUMS) for _ in range(r.randint(0,5))]
    elif k=="UNITS": f=[r.choice(VALS)]
    elif k=="OPTION": f=[r.choice(OPTS),r.choice(VALS)]
    elif k=="TITLE": f=["Some","title",r.choice(NUMS)]
    else: f=[r.choice(NUMS)]
    f=[x for x in f if x!=""]
    r.shuffle(f) if r.random()<0.05 else None
    if r.random()<0.2: f=f[:r.randint(0,len(f))]
    return k+" "+" ".join(f)
def gen3(seed):
    r=random.Random(seed)
    L=[]
    if r.random()<0.7: L.append("RESERVOIR R "+r.choice(["100","50","120"]))
    for _ in range(r.randint(2,9)): L.append(card(r))
    if r.random()<0.8: L.append("END")
    return "\n".join(L)+"\n"
if __name__=="__main__":
    a=int(sys.argv[1]); b=int(sys.argv[2]); bad=0
    for s in range(a,b):
        if not check(gen3(s),label="t%d"%s): bad+=1
    print("bad",bad,"of",b-a)
EOF
docker exec sn-fortran-solver-parity bash -lc 'cd /w; python3 gen3.py 0 600 2>&1 | grep -v "^  [PM]:" | head -50'
```

<details><summary>output</summary>

```
bad 0 of 600
```
</details>

### Step 184: Bash

```bash
cd /tmp; docker exec -i sn-fortran-solver-parity bash -c 'cat > /w/gen4.py' <<'EOF'
import random,sys
sys.path.insert(0,"/w")
from cmp import check
from gen3 import card
def gen4(seed):
    r=random.Random(seed)
    L=["RESERVOIR R 100","JUNCTION a 10 5","JUNCTION b 20 3 pp","JUNCTION J1 5 2","PATTERN pp 1 2 0.5","PIPE P1 R a 100 100 0.1","PIPE P2 a b 100 100 0.1","PIPE p J1 b 200 150 0.2"]
    for _ in range(r.randint(1,4)):
        L.insert(r.randint(0,len(L)),card(r))
    if r.random()<0.9: L.append("END")
    return "\n".join(L)+"\n"
if __name__=="__main__":
    a=int(sys.argv[1]); b=int(sys.argv[2]); bad=0
    for s in range(a,b):
        if not check(gen4(s),label="u%d"%s): bad+=1
    print("bad",bad,"of",b-a)
EOF
docker exec sn-fortran-solver-parity bash -lc 'cd /w; python3 gen4.py 0 1500 2>&1 | grep -v "^  [PM]:" | head -50'
```

<details><summary>output</summary>

```
DIFF u479 len line 3
DIFF u959 len line 3
RC DIFF u1022 0 2
DIFF u1023 len line 3
DIFF u1273 len line 2
DIFF u1403 len line 2
bad 6 of 1500
```
</details>

### Step 185: Bash

```bash
cd /tmp; docker exec sn-fortran-solver-parity bash -lc 'cd /w; python3 - <<EOF
from gen4 import gen4
from cmp import *
for s in (479,959,1022,1023,1273,1403):
    d=gen4(s); p=run(PROD,d)[0].split("\n")[:6]; m=run(MINE,d)[0].split("\n")[:6]
    print(s,[x for x in d.split("\n") if x not in ("RESERVOIR R 100","JUNCTION a 10 5","JUNCTION b 20 3 pp","JUNCTION J1 5 2","PATTERN pp 1 2 0.5","PIPE P1 R a 100 100 0.1","PIPE P2 a b 100 100 0.1","PIPE p J1 b 200 150 0.2","END")])
    print(" P",p[2:4]); print(" M",m[2:4])
EOF'
```

<details><summary>output</summary>

```
479 ['FOO 2.5', 'PIPE x1 Z P2 0.1 0.1 5 100', 'PIPE x1 A abcdefghi 100 2.5 0 0.1', 'TITLE Some title 3.14', '']
 P [" *** ERROR E101 LINE   6: UNKNOWN CARD 'FOO'", " *** ERROR E106 LINE  11: ID TOO LONG 'abcdefghi'"]
 M [" *** ERROR E101 LINE   6: UNKNOWN CARD 'FOO'", " *** ERROR E102 LINE  11: DUPLICATE ID 'x1'"]
959 ['junction P2 0.0 0', 'RESERVOIR abcdefghi 1e-3', 'VALVE P1 A abcdefghi 200 0.1 HW', 'FOO 5', '']
 P [" *** ERROR E106 LINE   5: ID TOO LONG 'abcdefghi'", " *** ERROR E106 LINE  10: ID TOO LONG 'abcdefghi'"]
 M [" *** ERROR E106 LINE   5: ID TOO LONG 'abcdefghi'", " *** ERROR E102 LINE  10: DUPLICATE ID 'P1'"]
1022 ['Pipe 1 J1 R 1e-3 1 1e3 200', '!x ', '']
 P [' ', ' TITLE    : (NONE)']
 M [' ', ' TITLE    : (NONE)']
1023 ['VALVE J1 1 P1 12345678901 abc 1.5', 'PATTERN qq 12345678901 1e-3', 'VALVE P1 b abcdefghi 3.14 0.1 open', 'OPTION FRICTION 25', '']
 P [" *** ERROR E104 LINE   6: BAD NUMBER 'abc'", " *** ERROR E106 LINE  10: ID TOO LONG 'abcdefghi'"]
 M [" *** ERROR E104 LINE   6: BAD NUMBER 'abc'", " *** ERROR E102 LINE  10: DUPLICATE ID 'P1'"]
1273 ['Pipe P2 abcdefghi P2 -0.5 1 0 10', '']
 P [" *** ERROR E106 LINE   8: ID TOO LONG 'abcdefghi'", ' *** RUN ABORTED:   1 INPUT ERROR(S)']
 M [" *** ERROR E102 LINE   8: DUPLICATE ID 'P2'", ' *** RUN ABORTED:   1 INPUT ERROR(S)']
1403 ['Pipe Z P2 R 1e3 1e3 0 5', 'PIPE Z abcdefghi abcdefghi 100 0.0 3.14 1', 'PIPE abcdefgh A c 12345678901 12345678901 2.5 2.5', '']
 P [" *** ERROR E106 LINE   9: ID TOO LONG 'abcdefghi'", " *** ERROR E103 LINE   6: UNDEFINED NODE 'P2'"]
 M [" *** ERROR E102 LINE   9: DUPLICATE ID 'Z'", " *** ERROR E103 LINE   6: UNDEFINED NODE 'P2'"]
```
</details>

### Step 186: Bash

```bash
cd /tmp; cat > /tmp/ed13.py <<'PYEOF'
s=open("/w/new/cards.f").read()
old=s[s.index("      L = 0\n      CALL CHKID(FIELD(2), 2, OK)"):s.index("      L = NL + 1\n      LID(L) = FIELD(2)")]
new="""      L = 0
      IF (LEN_TRIM(FIELD(2)) .GT. 8) THEN
         CALL PERR(106, 'ID TOO LONG ', FIELD(2))
         RETURN
      ENDIF
      IF (LEN_TRIM(FIELD(3)) .GT. 8) THEN
         CALL PERR(106, 'ID TOO LONG ', FIELD(3))
         RETURN
      ENDIF
      IF (LEN_TRIM(FIELD(4)) .GT. 8) THEN
         CALL PERR(106, 'ID TOO LONG ', FIELD(4))
         RETURN
      ENDIF
      CALL CHKID(FIELD(2), 2, OK)
      IF (.NOT. OK) RETURN
      IF (FIELD(3) .EQ. FIELD(4)) THEN
         CALL PERR(110, 'LINK CONNECTS NODE TO ITSELF', ' ')
         RETURN
      ENDIF
"""
s=s.replace(old,new)
open("/w/new/cards.f","w").write(s)
PYEOF
docker exec -i sn-fortran-solver-parity python3 - < /tmp/ed13.py
docker exec sn-fortran-solver-parity bash -lc 'cd /w/new; gfortran -O2 -o hydro *.f; cd /w; python3 gen4.py 0 1500 2>&1 | grep -v "^  [PM]:"; python3 - <<EOF
from gen4 import gen4
from cmp import *
d=gen4(1022); print(d); 
import difflib
p=run(PROD,d);m=run(MINE,d)
print(p[1],m[1])
for l in difflib.unified_diff(p[0].split("\n"),m[0].split("\n"),lineterm="",n=0): print(l)
EOF'
```

<details><summary>output</summary>

```
RC DIFF u1022 0 2
bad 1 of 1500
RESERVOIR R 100
Pipe 1 J1 R 1e-3 1 1e3 200
JUNCTION a 10 5
JUNCTION b 20 3 pp
JUNCTION J1 5 2
PATTERN pp 1 2 0.5
PIPE P1 R a 100 100 0.1
!x 
PIPE P2 a b 100 100 0.1
PIPE p J1 b 200 150 0.2
END

0 2
--- 
+++ 
@@ -10 +10 @@
- CONVERGED IN   3 ITERATIONS
+ *** WARNING W205: NOT CONVERGED AFTER 50 ITERATIONS
@@ -15 +15 @@
- J1       JUNC      5.000      2.00    97.682    92.682     907.4
+ J1       JUNC      5.000      2.00    97.966    92.966     910.1
@@ -17,2 +17,2 @@
- a        JUNC     10.000      5.00    98.192    88.192     863.4
- b        JUNC     20.000      3.00    97.707    77.707     760.8
+ a        JUNC     10.000      5.00    98.369    88.369     865.1
+ b        JUNC     20.000      3.00    97.979    77.979     763.4
@@ -23,5 +23,5 @@
- 1        PIPE  J1       R            -0.00    -0.179     2.318     UNDEF  OPEN    
- P1       PIPE  R        a            10.00     1.273     1.808   0.02188  OPEN    
- P2       PIPE  a        b             5.00     0.637     0.484   0.02345  OPEN    
- p        PIPE  J1       b            -2.00    -0.113     0.026   0.02970  OPEN    
- 
+ 1        PIPE  J1       R            -0.49  -623.317     2.034   0.04228  OPEN    
+ P1       PIPE  R        a             9.51     1.211     1.631   0.02197  OPEN    
+ P2       PIPE  a        b             4.51     0.574     0.390   0.02375  OPEN    
+ p        PIPE  J1       b            -1.51    -0.085     0.013   0.03143  OPEN    
+
@@ -30 +30 @@
- *** WARNING W203: ZERO FLOW IN LINK '1'
+ *** WARNING W202: HIGH VELOCITY IN LINK '1'
@@ -32 +32 @@
- RUN COMPLETED WITH   1 WARNING(S)
+ RUN COMPLETED WITH   2 WARNING(S)
```
</details>

### Step 187: Bash

```bash
cd /tmp; cat > /tmp/vv.py <<'PYEOF'
z="""               IF (LTYP(L) .NE. 2 .AND. ABS(QL(L)) .LT. QZERO .AND.
     &            ABS(QNEW) .LT. QZERO) QNEW = SIGN(0.0D0, QNEW)
"""
z2="""               IF (LTYP(L) .NE. 2 .AND. IT .GT. 1 .AND.
     &            ABS(QL(L)) .LT. QZERO .AND.
     &            ABS(QNEW) .LT. QZERO) QNEW = SIGN(0.0D0, QNEW)
"""
d={"it2":[("solve.f",z,z2)]}
open("/w/vv.txt","w").write(repr(d))
PYEOF
docker exec -i sn-fortran-solver-parity python3 - < /tmp/vv.py
docker exec sn-fortran-solver-parity bash -lc 'cd /w; python3 badscore.py "$(cat vv.txt)"; python3 multi.py "$(cat vv.txt)"; python3 - <<EOF
import sys
sys.path.insert(0,"/w")
from bench import build
from gen4 import gen4
from cmp import *
exe=build("it2",eval(open("/w/vv.txt").read())["it2"])
d=gen4(1022)
print(run(PROD,d)[0]==run(exe,d)[0], cmp(run(PROD,d)[0],run(exe,d)[0]))
EOF'
```

<details><summary>output</summary>

```
it2          fixed 0/33, good kept 119/120
it2        45 z2 1/48 z4 21/54 bench 23/112
False ('len line 9', (' CONVERGED IN   3 ITERATIONS', ' *** WARNING W205: NOT CONVERGED AFTER 50 ITERATIONS'))
```
</details>

### Step 188: Bash

```bash
cd /tmp; docker exec sn-fortran-solver-parity bash -lc 'cd /w; cp new/*.f new/hydro.inc /app/src/; python3 - <<EOF
import sys,re,collections
sys.path.insert(0,"/w")
from cmp import run,PROD
from gen import gen
from gen2 import mutate
from gen3 import gen3
from gen4 import gen4
c=collections.Counter()
for s in range(0,400):
    for d in (gen(s),mutate(gen(s),s),gen3(s),gen4(s)):
        o=run(PROD,d)[0]
        for m in re.findall(r"\*\*\* (ERROR|WARNING) ([EW]\d+)",o): c[m[1]]+=1
print(sorted(c.items()))
EOF'
```

<details><summary>output</summary>

```
[('E101', 207), ('E102', 130), ('E103', 525), ('E104', 296), ('E105', 331), ('E106', 235), ('E107', 203), ('E108', 286), ('E109', 45), ('E110', 66), ('E112', 117), ('E302', 110), ('W201', 850), ('W202', 1010), ('W203', 699), ('W204', 104), ('W205', 77), ('W207', 211), ('W208', 136), ('W209', 37), ('W210', 136)]
```
</details>

### Step 189: Bash

```bash
cd /tmp; docker exec -i sn-fortran-solver-parity bash -c 'cat > /w/ext2.py' <<'EOF'
import sys
sys.path.insert(0,"/w")
from cmp import check
cases=[
"RESERVOIR R 100\nRESERVOIR S 90\nPUMP u R S 20",
"RESERVOIR R 100\nRESERVOIR S 90\nPUMP u S R 20",
"RESERVOIR R 100\nRESERVOIR S 90\nPUMP u S R 5 10",
"RESERVOIR R 100\nRESERVOIR S 90\nVALVE v R S 100 5",
"RESERVOIR R 100\nRESERVOIR S 90\nVALVE v R S 100 5 closed",
"RESERVOIR R 100\nRESERVOIR S 90\nVALVE v R S 100 0",
"RESERVOIR R 100\nRESERVOIR S 90\nJUNCTION a 5 5\nPIPE p R a 100 100 .1\nPIPE q a S 100 100 .1",
"RESERVOIR R 100\nRESERVOIR S 90\nRESERVOIR T 80\nJUNCTION a 5 0\nPIPE p R a 100 100 .1\nPIPE q a S 100 100 .1\nPIPE r a T 100 100 .1",
"RESERVOIR R 100\nRESERVOIR S 100\nJUNCTION a 5 3\nPIPE p R a 100 100 .1\nPIPE q a S 100 100 .1",
"RESERVOIR R 100\nRESERVOIR T 70\nJUNCTION a 5 3\nPIPE p R a 100 100 .1\nPIPE q a R 100 100 .1",
"RESERVOIR R 100\nJUNCTION a 5 3\nJUNCTION b 5 3\nPIPE p R a 100 100 .1\nPIPE q a b 100 100 .1\nPIPE r b R 100 100 .1",
"RESERVOIR R 100\nJUNCTION a 5 3\nJUNCTION b 5 3\nJUNCTION c 5 3\nPIPE p R a 100 100 .1\nPIPE q a b 100 100 .1\nPIPE r b c 100 100 .1\nPIPE s c a 100 100 .1",
"RESERVOIR R 100\nJUNCTION a 5 3\nPIPE p R a 100 100 .1\nPIPE p2 R a 100 100 .1\nPIPE p3 R a 100 100 .1",
"RESERVOIR R 100\nJUNCTION a 5 3\nPIPE p R a 100 100 .1\nPUMP u R a 10 5\nVALVE v R a 100 3",
"RESERVOIR R 100\nJUNCTION a 5 -3\nPIPE p R a 100 100 .1",
"RESERVOIR R 100\nJUNCTION a 5 3\nJUNCTION b 5 -3\nPIPE p R a 100 100 .1\nPIPE q a b 100 100 .1",
"RESERVOIR R 100\nJUNCTION a 150 3\nPIPE p R a 100 100 .1",
"RESERVOIR R 100\nJUNCTION a 99.9999 3\nPIPE p R a 1 1000 0",
"RESERVOIR R 100\nJUNCTION a 100 0\nPIPE p R a 100 100 .1",
"RESERVOIR R 100\nJUNCTION a 100 0.001\nPIPE p R a 100 100 .1",
"UNITS US\nRESERVOIR R 100\nJUNCTION a 100 0.01\nPIPE p R a 100 100 .1",
"UNITS US\nRESERVOIR R 100\nJUNCTION a 50 10\nPIPE p R a 100 2 .1\nPUMP u a R 5\nPUMP u2 R a 10 50",
"UNITS US\nOPTION FRICTION HW\nRESERVOIR R 100\nJUNCTION a 50 10\nPIPE p R a 100 2 120 1\nVALVE v a R 2 4 closed",
"OPTION STEPS 24\nOPTION HSTEP 1\nPATTERN d 0.5 0.6 0.7 0.8 0.9 1 1.1 1.2 1.3 1.2 1.1 1 0.9 0.8 0.7 0.6 0.5 0.4 0.3 0.2 0.3 0.4 0.5 0.6\nRESERVOIR R 100\nJUNCTION a 50 10 d\nPIPE p R a 100 100 .1",
"OPTION STEPS 24\nOPTION HSTEP 0.3\nPATTERN d 0 0 0 1\nRESERVOIR R 100\nJUNCTION a 50 10 d\nJUNCTION b 50 10 d\nPIPE p R a 100 100 .1\nPIPE q a b 100 100 .1\nPIPE r b R 300 100 .1",
]
bad=0
for c in cases:
    for pre in ["","OPTION FRICTION HW\n","OPTION TOL 1e-8\n","OPTION MAXIT 3\n"]:
        d=pre+c+"\nEND\n"
        if not check(d,label=repr(pre+c)): bad+=1
print("bad",bad)
EOF
docker exec sn-fortran-solver-parity bash -lc 'cd /w; python3 ext2.py 2>&1 | head -60'
```

<details><summary>output</summary>

```
DIFF 'OPTION FRICTION HW\nRESERVOIR R 100\nRESERVOIR S 90\nRESERVOIR T 80\nJUNCTION a 5 0\nPIPE p R a 100 100 .1\nPIPE q a S 100 100 .1\nPIPE r a T 100 100 .1' tok line 9
  P:  CONVERGED IN  11 ITERATIONS
  M:  CONVERGED IN  12 ITERATIONS
DIFF 'OPTION FRICTION HW\nRESERVOIR R 100\nJUNCTION a 5 3\nJUNCTION b 5 3\nPIPE p R a 100 100 .1\nPIPE q a b 100 100 .1\nPIPE r b R 100 100 .1' tok line 21
  P:  p        PIPE  R        a             3.00     0.382119859.058            OPEN
  M:  p        PIPE  R        a             3.00     0.382119859.054            OPEN
DIFF 'OPTION FRICTION HW\nRESERVOIR R 100\nJUNCTION a 5 3\nJUNCTION b 5 3\nJUNCTION c 5 3\nPIPE p R a 100 100 .1\nPIPE q a b 100 100 .1\nPIPE r b c 100 100 .1\nPIPE s c a 100 100 .1' tok line 15
  P:  a        JUNC      5.000      3.00********************-8975054.9
  M:  a        JUNC      5.000      3.00********************-8975052.5
RC DIFF 'OPTION FRICTION HW\nRESERVOIR R 100\nJUNCTION a 5 3\nPIPE p R a 100 100 .1\nPUMP u R a 10 5\nVALVE v R a 100 3' 0 2
DIFF 'OPTION TOL 1e-8\nRESERVOIR R 100\nJUNCTION a 99.9999 3\nPIPE p R a 1 1000 0' tok line 9
  P:  CONVERGED IN   3 ITERATIONS
  M:  CONVERGED IN   2 ITERATIONS
DIFF 'OPTION TOL 1e-8\nRESERVOIR R 100\nJUNCTION a 100 0.001\nPIPE p R a 100 100 .1' tok line 9
  P:  CONVERGED IN   2 ITERATIONS
  M:  CONVERGED IN   3 ITERATIONS
RC DIFF 'UNITS US\nRESERVOIR R 100\nJUNCTION a 100 0.01\nPIPE p R a 100 100 .1' 2 0
RC DIFF 'OPTION TOL 1e-8\nUNITS US\nRESERVOIR R 100\nJUNCTION a 100 0.01\nPIPE p R a 100 100 .1' 2 0
RC DIFF 'OPTION MAXIT 3\nUNITS US\nRESERVOIR R 100\nJUNCTION a 100 0.01\nPIPE p R a 100 100 .1' 2 0
DIFF 'OPTION STEPS 24\nOPTION HSTEP 0.3\nPATTERN d 0 0 0 1\nRESERVOIR R 100\nJUNCTION a 50 10 d\nJUNCTION b 50 10 d\nPIPE p R a 100 100 .1\nPIPE q a b 100 100 .1\nPIPE r b R 300 100 .1' tok line 100
  P:  CONVERGED IN   3 ITERATIONS
  M:  CONVERGED IN   2 ITERATIONS
DIFF 'OPTION FRICTION HW\nOPTION STEPS 24\nOPTION HSTEP 0.3\nPATTERN d 0 0 0 1\nRESERVOIR R 100\nJUNCTION a 50 10 d\nJUNCTION b 50 10 d\nPIPE p R a 100 100 .1\nPIPE q a b 100 100 .1\nPIPE r b R 300 100 .1' tok line 11
  P:  CONVERGED IN  13 ITERATIONS
  M:  CONVERGED IN  12 ITERATIONS
DIFF 'OPTION TOL 1e-8\nOPTION STEPS 24\nOPTION HSTEP 0.3\nPATTERN d 0 0 0 1\nRESERVOIR R 100\nJUNCTION a 50 10 d\nJUNCTION b 50 10 d\nPIPE p R a 100 100 .1\nPIPE q a b 100 100 .1\nPIPE r b R 300 100 .1' tok line 100
  P:  CONVERGED IN   3 ITERATIONS
  M:  CONVERGED IN   2 ITERATIONS
bad 12
```
</details>

### Step 190: Bash

```bash
cd /tmp; docker exec sn-fortran-solver-parity bash -lc 'cd /w; printf "UNITS US\nRESERVOIR R 100\nJUNCTION a 100 0.01\nPIPE p R a 100 100 .1\nEND\n" | /app/prod/hydro | sed -n 8,30p; for q in 0.01 0.02 0.05 0.1 1; do printf "UNITS US\nRESERVOIR R 100\nJUNCTION a 100 $q\nPIPE p R a 100 100 .1\nEND\n" | /app/prod/hydro 2>&1| grep -e CONVERGED -e " p "; done'
```

<details><summary>output</summary>

```
STOP 2
 SOLVER   : TOL  1.0E-05, MAXIT  50
 
 *** WARNING W205: NOT CONVERGED AFTER 50 ITERATIONS
 
 NODE RESULTS
 ID       TYPE       ELEV    DEMAND      HEAD  PRESSURE       PSI
 -------- ----- --------- --------- --------- --------- ---------
 R        RESV    100.000     -0.01   100.000     0.000      0.00
 a        JUNC    100.000      0.01   100.000    -0.000     -0.00
 
 LINK RESULTS
 ID       TYPE  FROM     TO            FLOW  VELOCITY  HEADLOSS  FRICTION  STATUS
 -------- ----- -------- -------- --------- --------- --------- ---------  --------
 p        PIPE  R        a             0.01     0.000     0.000     UNDEF  OPEN    
 
 TOTAL DEMAND :      0.01 GPM
 TOTAL SUPPLY :      0.01 GPM
 *** WARNING W201: NEGATIVE PRESSURE AT NODE 'a'
 *** WARNING W203: ZERO FLOW IN LINK 'p'

 RUN COMPLETED WITH   3 WARNING(S)
 *** WARNING W205: NOT CONVERGED AFTER 50 ITERATIONS
 p        PIPE  R        a             0.01     0.000     0.000     UNDEF  OPEN    
 *** WARNING W205: NOT CONVERGED AFTER 50 ITERATIONS
 p        PIPE  R        a             0.02     0.000     0.000 101.18547  OPEN    
 CONVERGED IN   2 ITERATIONS
 p        PIPE  R        a             0.05     0.000     0.000  40.47327  OPEN    
 CONVERGED IN   2 ITERATIONS
 p        PIPE  R        a             0.10     0.000     0.000  20.23667  OPEN    
 CONVERGED IN   2 ITERATIONS
 p        PIPE  R        a             1.00     0.000     0.000   2.02368  OPEN
```
</details>

### Step 191: Bash

```bash
cd /tmp; docker exec -i sn-fortran-solver-parity bash -c 'cat > /w/tiny.py' <<'EOF'
import sys
sys.path.insert(0,"/w")
from bench import seq
from cmp import PROD,MINE
for D in [2540,1000,300]:
  print("D",D)
  for q in [0.0003,0.0006,0.001,0.0012,0.0013,0.0015,0.002,0.003,0.004,0.005,0.01,0.02]:
    d="OPTION MAXIT 20\nRESERVOIR R 100\nJUNCTION a 100 %g\nPIPE p R a 30 %d .1\nEND\n"%(q,D)
    p=seq(PROD,d); m=seq(MINE,d)
    f=lambda s:[x[0] or "NC" for x in s[1]]
    print(" q=%g"%q,f(p),f(m),"" if f(p)==f(m) else "<<")
EOF
docker exec sn-fortran-solver-parity bash -lc 'cd /w; python3 tiny.py'
```

<details><summary>output</summary>

```
D 2540
 q=0.0003 ['NC'] ['2'] <<
 q=0.0006 ['NC'] ['2'] <<
 q=0.001 ['NC'] ['2'] <<
 q=0.0012 ['NC'] ['2'] <<
 q=0.0013 ['2'] ['2'] 
 q=0.0015 ['2'] ['2'] 
 q=0.002 ['NC'] ['2'] <<
 q=0.003 ['2'] ['2'] 
 q=0.004 ['2'] ['2'] 
 q=0.005 ['NC'] ['2'] <<
 q=0.01 ['2'] ['2'] 
 q=0.02 ['2'] ['2'] 
D 1000
 q=0.0003 ['3'] ['2'] <<
 q=0.0006 ['3'] ['2'] <<
 q=0.001 ['3'] ['2'] <<
 q=0.0012 ['2'] ['2'] 
 q=0.0013 ['2'] ['2'] 
 q=0.0015 ['3'] ['2'] <<
 q=0.002 ['3'] ['2'] <<
 q=0.003 ['3'] ['2'] <<
 q=0.004 ['3'] ['2'] <<
 q=0.005 ['2'] ['2'] 
 q=0.01 ['2'] ['2'] 
 q=0.02 ['2'] ['2'] 
D 300
 q=0.0003 ['2'] ['2'] 
 q=0.0006 ['2'] ['2'] 
 q=0.001 ['2'] ['2'] 
 q=0.0012 ['2'] ['2'] 
 q=0.0013 ['2'] ['2'] 
 q=0.0015 ['2'] ['2'] 
 q=0.002 ['2'] ['2'] 
 q=0.003 ['2'] ['2'] 
 q=0.004 ['2'] ['2'] 
 q=0.005 ['2'] ['2'] 
 q=0.01 ['2'] ['2'] 
 q=0.02 ['2'] ['2']
```
</details>

### Step 192: Bash

```bash
cd /tmp; grep -n "IF (LTYP(L) .EQ. 2) THEN" -B2 -A12 /dev/null; docker exec sn-fortran-solver-parity bash -lc 'cd /w; sed -n 255,300p new/solve.f | head -5; grep -n "GMINP" new/solve.f'
```

<details><summary>output</summary>

```
   20       CONTINUE
            T = B(K)
            B(K) = B(IP)
            B(IP) = T
         ENDIF
224:         IF (GR .LT. GMINP) GR = GMINP
```
</details>

### Step 193: Bash

```bash
cd /tmp; docker exec sn-fortran-solver-parity bash -lc 'cd /w; sed -n 170,235p new/solve.f'
```

<details><summary>output</summary>

```
  100 CONTINUE
      RETURN
      END
C
C     HLGRAD  -  HEAD LOSS AND ITS FLOW DERIVATIVE FOR LINK L
C
      SUBROUTINE HLGRAD(L, Q, H, GR)
      IMPLICIT NONE
      INCLUDE 'hydro.inc'
      INTEGER L
      DOUBLE PRECISION Q, H, GR, A, V, RE, R, F, S, RK, HR, R0
      DOUBLE PRECISION FRFAC
C
      IF (LTYP(L) .EQ. 2) THEN
         IF (PQ(L) .GT. 0.0D0) THEN
            S = Q/PQ(L)
            H = -PH(L)*(1.0D0 - S*ABS(S))
            GR = 2.0D0*PH(L)*ABS(Q)/(PQ(L)*PQ(L))
         ELSE
            H = -PH(L)
            GR = 0.0D0
         ENDIF
      ELSE IF (LTYP(L) .EQ. 3) THEN
         A = PI*DI(L)**2/4.0D0
         R = XK(L)/(2.0D0*GRAV*A*A)
         H = R*Q*ABS(Q)
         GR = 2.0D0*R*ABS(Q)
      ELSE
         A = PI*DI(L)**2/4.0D0
         RK = XK(L)/(2.0D0*GRAV*A*A)
         IF (IFRIC .EQ. 1) THEN
            V = Q/A
            RE = ABS(V)*DI(L)/VISC
            F = FRFAC(RE, RG(L)/DI(L))
            R = F*XL(L)/(DI(L)*2.0D0*GRAV*A*A) + RK
            H = R*Q*ABS(Q)
            IF (RE .LT. 2000.0D0) THEN
               R0 = 32.0D0*VISC*XL(L)/(GRAV*DI(L)**2*A)
               H = R0*Q + RK*Q*ABS(Q)
               GR = R0 + 2.0D0*RK*ABS(Q)
            ELSE
               GR = 2.0D0*R*ABS(Q)
            ENDIF
         ELSE
            HR = 10.667D0*XL(L)/(RG(L)**1.852D0*DI(L)**4.871D0)
            H = HR*ABS(Q)**1.852D0*SIGN(1.0D0,Q) + RK*Q*ABS(Q)
            GR = 1.852D0*HR*ABS(Q)**0.852D0 + 2.0D0*RK*ABS(Q)
         ENDIF
      ENDIF
      IF (LTYP(L) .EQ. 2) THEN
         IF (GR .LT. GMINU) GR = GMINU
      ELSE IF (LTYP(L) .EQ. 3) THEN
         IF (GR .LT. GMINV) GR = GMINV
      ELSE
         IF (GR .LT. GMINP) GR = GMINP
      ENDIF
      RETURN
      END
C
C     LINSOL  -  GAUSSIAN ELIMINATION WITH PARTIAL PIVOTING
C
      SUBROUTINE LINSOL(A, B, X, N, LDA)
      IMPLICIT NONE
      INTEGER N, LDA
      DOUBLE PRECISION A(LDA,*), B(*), X(*)
      INTEGER I, J, K, IP
```
</details>

### Step 194: Bash

```bash
cd /tmp; cat > /tmp/vv.py <<'PYEOF'
old="""      ELSE
         IF (GR .LT. GMINP) GR = GMINP
      ENDIF
      RETURN"""
def new(fl):
    return """      ELSE IF (IFRIC .EQ. 1 .AND. RE .LT. 2000.0D0) THEN
         IF (GR .LT. %s) GR = %s
      ELSE
         IF (GR .LT. GMINP) GR = GMINP
      ENDIF
      RETURN"""%(fl,fl)
# RE needs to be defined for non-DW: set RE=1e30 default
init="""      DOUBLE PRECISION FRFAC
C
      IF (LTYP(L) .EQ. 2) THEN
         IF (PQ(L) .GT. 0.0D0) THEN"""
init2="""      DOUBLE PRECISION FRFAC
C
      RE = 1.0D30
      IF (LTYP(L) .EQ. 2) THEN
         IF (PQ(L) .GT. 0.0D0) THEN"""
d={}
for fl in ["1.0D-300","1.0D-8","1.0D-6","1.0D-5","1.0D-4","1.0D-3"]:
    d["lam"+fl]=[("solve.f",old,new(fl)),("solve.f",init,init2)]
open("/w/vv.txt","w").write(repr(d))
PYEOF
docker exec -i sn-fortran-solver-parity python3 - < /tmp/vv.py
cat > /tmp/tiny2.py <<'PYEOF'
import sys
sys.path.insert(0,"/w")
from bench import seq,build
from cmp import PROD
vs=eval(open("/w/vv.txt").read())
decks=[]
for D in [2540,1000]:
  for q in [0.0003,0.0006,0.001,0.0012,0.0013,0.0015,0.002,0.003,0.004,0.005,0.01,0.02]:
    decks.append("OPTION MAXIT 20\nRESERVOIR R 100\nJUNCTION a 100 %g\nPIPE p R a 30 %d .1\nEND\n"%(q,D))
f=lambda s:[x[0] or "NC" for x in s[1]]
P=[f(seq(PROD,d)) for d in decks]
print("PROD",[x[0] for x in P])
for k,v in vs.items():
    exe=build(k,v)
    M=[f(seq(exe,d)) for d in decks]
    print("%-14s"%k,[x[0] for x in M],"bad",sum(1 for a,b in zip(P,M) if a!=b))
PYEOF
docker exec -i sn-fortran-solver-parity bash -c 'cat > /w/tiny2.py' < /tmp/tiny2.py
docker exec sn-fortran-solver-parity bash -lc 'cd /w; python3 tiny2.py'
```

<details><summary>output</summary>

```
PROD ['NC', 'NC', 'NC', 'NC', '2', '2', 'NC', '2', '2', 'NC', '2', '2', '3', '3', '3', '2', '2', '3', '3', '3', '3', '2', '2', '2']
lam1.0D-300    ['2', '2', '3', '3', '3', '3', '3', '3', '3', '3', '3', '3', '2', '2', '3', '2', '2', '3', '3', '3', '2', '2', '2', '2'] bad 15
lam1.0D-8      ['2', '2', '3', '3', '3', '3', '3', '3', '3', '3', '3', '3', '2', '2', '3', '2', '2', '3', '3', '3', '2', '2', '2', '2'] bad 15
lam1.0D-6      ['2', '2', '3', '3', '3', '3', '3', '3', '3', '3', '3', '3', '2', '2', '3', '2', '2', '3', '3', '3', '2', '2', '2', '2'] bad 15
lam1.0D-5      ['2', '2', '4', 'NC', '8', '8', 'NC', '8', '7', 'NC', 'NC', 'NC', '2', '2', '3', '2', '2', '3', '3', '3', '2', '2', '2', '2'] bad 12
lam1.0D-4      ['2', '2', 'NC', 'NC', '2', '2', 'NC', '2', '2', 'NC', '2', '2', '2', '2', '3', '2', '2', '3', '3', '3', '2', '2', '2', '2'] bad 5
lam1.0D-3      ['2', '2', '2', '2', '2', '2', '2', '2', '2', '2', '2', '2', '2', '2', '2', '2', '2', '2', '2', '2', '2', '2', '2', '2'] bad 13
```
</details>

### Step 195: Bash

```bash
cd /tmp; cat > /tmp/vv.py <<'PYEOF'
z="""               IF (LTYP(L) .NE. 2 .AND. ABS(QL(L)) .LT. QZERO .AND.
     &            ABS(QNEW) .LT. QZERO) QNEW = SIGN(0.0D0, QNEW)
"""
old="""      ELSE
         IF (GR .LT. GMINP) GR = GMINP
      ENDIF
      RETURN"""
new="""      ELSE IF (IFRIC .EQ. 1 .AND. RE .LT. 2000.0D0) THEN
         IF (GR .LT. GMIN) GR = GMIN
      ELSE
         IF (GR .LT. GMINP) GR = GMINP
      ENDIF
      RETURN"""
init="""      DOUBLE PRECISION FRFAC
C
      IF (LTYP(L) .EQ. 2) THEN
         IF (PQ(L) .GT. 0.0D0) THEN"""
init2="""      DOUBLE PRECISION FRFAC
C
      RE = 1.0D30
      IF (LTYP(L) .EQ. 2) THEN
         IF (PQ(L) .GT. 0.0D0) THEN"""
hw="""            H = HR*ABS(Q)**1.852D0*SIGN(1.0D0,Q) + RK*Q*ABS(Q)
            GR = 1.852D0*HR*ABS(Q)**0.852D0 + 2.0D0*RK*ABS(Q)
"""
def hwv(thr,mode):
    g="1.852D0*HR*%s**0.852D0"%thr if mode=="d" else "HR*%s**0.852D0"%thr
    return """            H = HR*ABS(Q)**1.852D0*SIGN(1.0D0,Q) + RK*Q*ABS(Q)
            GR = 1.852D0*HR*ABS(Q)**0.852D0 + 2.0D0*RK*ABS(Q)
            IF (ABS(Q) .LT. %s) THEN
               GR = %s + 2.0D0*RK*ABS(Q)
               H = %s*Q + RK*Q*ABS(Q)
            ENDIF
"""%(thr,g,g)
base=[("solve.f",z,""),("solve.f",old,new),("solve.f",init,init2)]
d={"A":base,"Azero":base[1:]}
for thr in ["1.0D-6","1.0D-5","1.0D-7"]:
  for mode in "ds":
    d["B%s%s"%(thr[-1],mode)]=base+[("solve.f",hw,hwv(thr,mode))]
    d["Bz%s%s"%(thr[-1],mode)]=base[1:]+[("solve.f",hw,hwv(thr,mode))]
open("/w/vv.txt","w").write(repr(d))
PYEOF
docker exec -i sn-fortran-solver-parity python3 - < /tmp/vv.py
docker exec sn-fortran-solver-parity bash -lc 'cd /w; python3 tiny2.py | cut -c1-30,160-; python3 badscore.py "$(cat vv.txt)"; python3 multi.py "$(cat vv.txt)"'
```

<details><summary>output</summary>

```
PROD ['NC', 'NC', 'NC', 'NC', 
A              ['NC', 'NC', 'N
Azero          ['2', '2', 'NC'
B6d            ['NC', 'NC', 'N
Bz6d           ['2', '2', 'NC'
B6s            ['NC', 'NC', 'N
Bz6s           ['2', '2', 'NC'
B5d            ['NC', 'NC', 'N
Bz5d           ['2', '2', 'NC'
B5s            ['NC', 'NC', 'N
Bz5s           ['2', '2', 'NC'
B7d            ['NC', 'NC', 'N
Bz7d           ['2', '2', 'NC'
B7s            ['NC', 'NC', 'N
Bz7s           ['2', '2', 'NC'
A            fixed 6/33, good kept 119/120
Azero        fixed 2/33, good kept 119/120
B6d          fixed 5/33, good kept 119/120
Bz6d         fixed 4/33, good kept 119/120
B6s          fixed 6/33, good kept 119/120
Bz6s         fixed 6/33, good kept 119/120
B5d          fixed 3/33, good kept 119/120
Bz5d         fixed 3/33, good kept 119/120
B5s          fixed 4/33, good kept 119/120
Bz5s         fixed 4/33, good kept 119/120
B7d          fixed 6/33, good kept 119/120
Bz7d         fixed 2/33, good kept 119/120
B7s          fixed 6/33, good kept 119/120
Bz7s         fixed 2/33, good kept 119/120
A          72 z2 20/48 z4 21/54 bench 31/112
Azero      45 z2 1/48 z4 21/54 bench 23/112
B6d        51 z2 6/48 z4 15/54 bench 30/112
Bz6d       44 z2 1/48 z4 16/54 bench 27/112
B6s        47 z2 6/48 z4 15/54 bench 26/112
Bz6s       44 z2 1/48 z4 16/54 bench 27/112
B5d        77 z2 21/48 z4 25/54 bench 31/112
Bz5d       76 z2 21/48 z4 25/54 bench 30/112
B5s        77 z2 21/48 z4 25/54 bench 31/112
Bz5s       76 z2 21/48 z4 25/54 bench 30/112
B7d        72 z2 20/48 z4 21/54 bench 31/112
Bz7d       45 z2 1/48 z4 21/54 bench 23/112
B7s        72 z2 20/48 z4 21/54 bench 31/112
Bz7s       46 z2 1/48 z4 22/54 bench 23/112
```
</details>

### Step 196: Bash

```bash
cd /tmp; cat >> /tmp/vv.py <<'PYEOF'
zhw="""               IF (LTYP(L) .NE. 2 .AND. IFRIC .EQ. 2 .AND.
     &            ABS(QL(L)) .LT. QZERO .AND.
     &            ABS(QNEW) .LT. QZERO) QNEW = SIGN(0.0D0, QNEW)
"""
zhwv="""               IF (LTYP(L) .EQ. 3 .AND.
     &            ABS(QL(L)) .LT. QZERO .AND.
     &            ABS(QNEW) .LT. QZERO) QNEW = SIGN(0.0D0, QNEW)
               IF (LTYP(L) .EQ. 1 .AND. IFRIC .EQ. 2 .AND.
     &            ABS(QL(L)) .LT. QZERO .AND.
     &            ABS(QNEW) .LT. QZERO) QNEW = SIGN(0.0D0, QNEW)
"""
d={"Chw":[("solve.f",z,zhw),("solve.f",old,new),("solve.f",init,init2)],
"Chwv":[("solve.f",z,zhwv),("solve.f",old,new),("solve.f",init,init2)],
"Chw6s":[("solve.f",z,zhw),("solve.f",old,new),("solve.f",init,init2),("solve.f",hw,hwv("1.0D-6","s"))],
"Chwv6s":[("solve.f",z,zhwv),("solve.f",old,new),("solve.f",init,init2),("solve.f",hw,hwv("1.0D-6","s"))],
}
open("/w/vv.txt","w").write(repr(d))
PYEOF
docker exec -i sn-fortran-solver-parity python3 - < /tmp/vv.py
docker exec sn-fortran-solver-parity bash -lc 'cd /w; python3 tiny2.py | cut -c1-40,160-;python3 badscore.py "$(cat vv.txt)"; python3 multi.py "$(cat vv.txt)"'
```

<details><summary>output</summary>

```
PROD ['NC', 'NC', 'NC', 'NC', '2', '2', 
Chw            ['NC', 'NC', 'NC', 'NC', 
Chwv           ['NC', 'NC', 'NC', 'NC', 
Chw6s          ['NC', 'NC', 'NC', 'NC', 
Chwv6s         ['NC', 'NC', 'NC', 'NC', 
Chw          fixed 2/33, good kept 119/120
Chwv         fixed 2/33, good kept 119/120
Chw6s        fixed 6/33, good kept 119/120
Chwv6s       fixed 6/33, good kept 119/120
Chw        46 z2 1/48 z4 21/54 bench 24/112
Chwv       46 z2 1/48 z4 21/54 bench 24/112
Chw6s      45 z2 1/48 z4 16/54 bench 28/112
Chwv6s     45 z2 1/48 z4 16/54 bench 28/112
```
</details>

### Step 197: Bash

```bash
cd /tmp; docker exec sn-fortran-solver-parity bash -lc 'cd /w; python3 tiny2.py | sed "s/\[.*\]//"'
```

<details><summary>output</summary>

```
PROD 
Chw             bad 1
Chwv            bad 1
Chw6s           bad 1
Chwv6s          bad 1
```
</details>

### Step 198: Bash

```bash
cd /tmp; cat > /tmp/broad.py <<'PYEOF'
import sys
sys.path.insert(0,"/w")
from cmp import run,cmp,PROD
from gen import gen
from gen2 import mutate
from bench import build
vs=eval(sys.argv[1])
decks=[gen(s) for s in range(0,500)]+[mutate(gen(s),s) for s in range(0,250)]+[gen(s) for s in range(3000,3150)]
P=[run(PROD,d) for d in decks]
for n,v in vs.items():
    exe=build(n,v) if v is not None else "/w/new/hydro"
    bad=[i for i,(d,p) in enumerate(zip(decks,P)) if not (run(exe,d)[1]==p[1] and cmp(p[0],run(exe,d)[0])[0] is None)]
    print("%-10s bad %d of %d"%(n,len(bad),len(decks)),bad[:40])
PYEOF
docker exec -i sn-fortran-solver-parity bash -c 'cat > /w/broad.py' < /tmp/broad.py
docker exec sn-fortran-solver-parity bash -lc 'cd /w; python3 - <<EOF
d=eval(open("/w/vv.txt").read()); d["cur"]=None
open("/w/vv.txt","w").write(repr(d))
EOF
python3 broad.py "$(cat vv.txt)"'
```

<details><summary>output</summary>

```
Chw        bad 12 of 900 [69, 110, 213, 314, 414, 469, 634, 663, 685, 713, 771, 866]
Chwv       bad 12 of 900 [69, 110, 213, 314, 414, 469, 634, 663, 685, 713, 771, 866]
Chw6s      bad 11 of 900 [69, 87, 110, 314, 414, 469, 634, 663, 685, 771, 866]
Chwv6s     bad 11 of 900 [69, 87, 110, 314, 414, 469, 634, 663, 685, 771, 866]
cur        bad 12 of 900 [69, 110, 213, 314, 414, 469, 634, 663, 685, 713, 771, 866]
```
</details>

### Step 199: Bash

```bash
cd /tmp; docker exec sn-fortran-solver-parity bash -lc 'cd /w; python3 - <<EOF
from gen import gen
from gen2 import mutate
decks=[gen(s) for s in range(0,500)]+[mutate(gen(s),s) for s in range(0,250)]+[gen(s) for s in range(3000,3150)]
for i in [69,87,110,314,414,469,634,663,685,771,866]:
    d=decks[i]
    print(i,[l for l in d.split("\n") if l.startswith(("VALVE","PUMP")) or "FRICTION" in l])
EOF'
```

<details><summary>output</summary>

```
69 ['OPTION FRICTION HW', 'PUMP U0 J3 J0 30.0', 'VALVE V0 J2 J3 150 0 OPEN']
87 ['PUMP U0 J5 J3 32.8 634.00', 'VALVE V0 J9 J1 6 0 ', 'OPTION FRICTION HW']
110 ['PUMP U0 R0 J3 20.0 10.00', 'PUMP U1 J5 J6 10.0 10.00', 'VALVE V0 J1 R0 100 0 ', 'VALVE V1 J1 J5 100 0 ']
314 ['OPTION FRICTION HW', 'PUMP U0 J0 J1 98.4 317.00', 'PUMP U1 R0 J1 32.8 79.25', 'VALVE V0 J1 J0 6 0 ', 'VALVE V1 J0 R0 8 20 CLOSED']
414 ['OPTION FRICTION HW', 'PUMP U0 J1 R0 10.0', 'PUMP U1 J0 J7 10.0 5.00', 'VALVE V0 J3 J4 100 0 ']
469 ['OPTION FRICTION HW', 'VALVE V0 J5 J3 4 1 OPEN', 'VALVE V1 J2 J5 6 0 CLOSED']
634 ['OPTION FRICTION HW', 'PUMP U0 J7 J2 5.0 5.00', 'PUMP U1 J7 J1 30.0']
663 ['VALVE V0 J0 J2 100 5 CLOSED', 'VALVE V1 J6 J8 150 20 OPEN', 'OPTION FRICTION HW']
685 ['PUMP U1 J1 J2 5.0 10.00', 'PUMP U0 R0 J1 30.0 1e-9', 'VALVE V0 J2 R0 150 5 ', 'VALVE V1 J0 J3 150 20 CLOSED']
771 ['PUMP U0 J0 J1 30.0 5.00', 'VALVE V0 J0 R0 200 0 ', 'VALVE V1 R0 J0 200 5 OPEN']
866 ['OPTION FRICTION HW', 'VALVE V0 R0 J2 100 0 OPEN']
```
</details>

### Step 200: Bash

```bash
cd /tmp; docker exec sn-fortran-solver-parity bash -lc 'cd /w; python3 - <<EOF
from gen import gen
from gen2 import mutate
decks=[gen(s) for s in range(0,500)]+[mutate(gen(s),s) for s in range(0,250)]+[gen(s) for s in range(3000,3150)]
for i in (663,634,866):
    open("/w/h%d.dat"%i,"w").write(decks[i])
EOF
cat > diffshow.py <<EOF
import sys,difflib
sys.path.insert(0,"/w")
from cmp import run,PROD
exe=sys.argv[1]
for f in sys.argv[2:]:
    d=open(f).read()
    p=[x.rstrip() for x in run(PROD,d)[0].split("\n")]; m=[x.rstrip() for x in run(exe,d)[0].split("\n")]
    print("=====",f)
    n=0
    for l in difflib.unified_diff(p,m,lineterm="",n=0):
        if l.startswith(("---","+++","@@")): continue
        print(l); n+=1
        if n>12: break
EOF
python3 diffshow.py /w/new/hydro h663.dat h634.dat h866.dat'
```

<details><summary>output</summary>

```
===== h663.dat
- P1       PIPE  J0       J1           32.54     1.036692258.277            OPEN
+ P1       PIPE  J0       J1           32.54     1.036692258.274            OPEN
- V0       VALVE J0       J2            0.00     0.000874486.542            CLOSED
+ V0       VALVE J0       J2            0.00     0.000874486.539            CLOSED
- P4       PIPE  J3       J4            1.28     0.163197363.893            OPEN
+ P4       PIPE  J3       J4            1.28     0.163197363.892            OPEN
- P3       PIPE  J3       J2           13.26     0.422131282.126            OPEN
+ P3       PIPE  J3       J2           13.26     0.422131282.125            OPEN
===== h634.dat
- CONVERGED IN   9 ITERATIONS
+ *** WARNING W205: NOT CONVERGED AFTER 10 ITERATIONS
- J1       JUNC     41.800     12.00   124.659    82.859     35.92
- J2       JUNC     59.100      8.00   123.234    64.134     27.80
+ J1       JUNC     41.800     12.00   124.660    82.860     35.92
+ J2       JUNC     59.100      8.00   123.233    64.133     27.80
- J4       JUNC     30.200      3.00    95.025    64.825     28.10
- J5       JUNC     13.400      2.00    95.257    81.857     35.49
- J6       JUNC      5.800      1.20   124.659   118.859     51.53
- J7       JUNC     37.800     19.20    94.659    56.859     24.65
- J8       JUNC     50.000      0.00   124.659    74.659     32.36
- J9       JUNC      9.900     20.00   124.659   114.759     49.75
+ J4       JUNC     30.200      3.00    95.060    64.860     28.12
===== h866.dat
- CONVERGED IN  15 ITERATIONS
+ CONVERGED IN  16 ITERATIONS
- *** WARNING W203: ZERO FLOW IN LINK 'P2'
- CONVERGED IN  13 ITERATIONS
+ CONVERGED IN   9 ITERATIONS
- V0       VALVE R0       J2           45.00     5.730     0.000            OPEN
+ V0       VALVE R0       J2           45.00     5.729     0.000            OPEN
- *** WARNING W203: ZERO FLOW IN LINK 'P2'
- CONVERGED IN  13 ITERATIONS
+ CONVERGED IN  12 ITERATIONS
- P1       PIPE  J0       J1            0.00     0.000     0.000            OPEN
+ P1       PIPE  J0       J1           -0.00    -0.000     0.000            OPEN
- *** WARNING W203: ZERO FLOW IN LINK 'P2'
```
</details>

### Step 201: Bash

```bash
cd /tmp; cat > /tmp/ed14.py <<'PYEOF'
s=open("/w/new/solve.f").read()
exec(open("/tmp/vv.py").read().split("d={\"A\"")[0].split("base=")[0])  # defines z, old,new,init,init2,hw,hwv
zhwv="""               IF (LTYP(L) .EQ. 3 .AND.
     &            ABS(QL(L)) .LT. QZERO .AND.
     &            ABS(QNEW) .LT. QZERO) QNEW = SIGN(0.0D0, QNEW)
               IF (LTYP(L) .EQ. 1 .AND. IFRIC .EQ. 2 .AND.
     &            ABS(QL(L)) .LT. QZERO .AND.
     &            ABS(QNEW) .LT. QZERO) QNEW = SIGN(0.0D0, QNEW)
"""
for a,b in [(z,zhwv),(old,new),(init,init2),(hw,hwv("1.0D-6","s"))]:
    assert a in s, a[:60]
    s=s.replace(a,b)
open("/w/new/solve.f","w").write(s)
PYEOF
docker exec -i sn-fortran-solver-parity python3 - < /tmp/ed14.py
docker exec sn-fortran-solver-parity bash -lc 'cd /w/new; gfortran -O2 -o hydro *.f 2>&1 | head; cd /w; python3 probes.py | tail -2; python3 ext2.py | tail -12; python3 gen4.py 0 800 | tail -3; python3 gen3.py 0 300 | tail -2'
```

<details><summary>output</summary>

```
Traceback (most recent call last):
  File "<stdin>", line 2, in <module>
FileNotFoundError: [Errno 2] No such file or directory: '/tmp/vv.py'
bad 0 of 240
RC DIFF 'OPTION TOL 1e-8\nUNITS US\nRESERVOIR R 100\nJUNCTION a 100 0.01\nPIPE p R a 100 100 .1' 2 0
RC DIFF 'OPTION MAXIT 3\nUNITS US\nRESERVOIR R 100\nJUNCTION a 100 0.01\nPIPE p R a 100 100 .1' 2 0
DIFF 'OPTION STEPS 24\nOPTION HSTEP 0.3\nPATTERN d 0 0 0 1\nRESERVOIR R 100\nJUNCTION a 50 10 d\nJUNCTION b 50 10 d\nPIPE p R a 100 100 .1\nPIPE q a b 100 100 .1\nPIPE r b R 300 100 .1' tok line 100
  P:  CONVERGED IN   3 ITERATIONS
  M:  CONVERGED IN   2 ITERATIONS
DIFF 'OPTION FRICTION HW\nOPTION STEPS 24\nOPTION HSTEP 0.3\nPATTERN d 0 0 0 1\nRESERVOIR R 100\nJUNCTION a 50 10 d\nJUNCTION b 50 10 d\nPIPE p R a 100 100 .1\nPIPE q a b 100 100 .1\nPIPE r b R 300 100 .1' tok line 11
  P:  CONVERGED IN  13 ITERATIONS
  M:  CONVERGED IN  12 ITERATIONS
DIFF 'OPTION TOL 1e-8\nOPTION STEPS 24\nOPTION HSTEP 0.3\nPATTERN d 0 0 0 1\nRESERVOIR R 100\nJUNCTION a 50 10 d\nJUNCTION b 50 10 d\nPIPE p R a 100 100 .1\nPIPE q a b 100 100 .1\nPIPE r b R 300 100 .1' tok line 100
  P:  CONVERGED IN   3 ITERATIONS
  M:  CONVERGED IN   2 ITERATIONS
bad 12
bad 0 of 800
bad 0 of 300
```
</details>

### Step 202: Bash

```bash
cd /tmp; cat > /tmp/ed14.py <<'PYEOF'
s=open("/w/new/solve.f").read()
z="""               IF (LTYP(L) .NE. 2 .AND. ABS(QL(L)) .LT. QZERO .AND.
     &            ABS(QNEW) .LT. QZERO) QNEW = SIGN(0.0D0, QNEW)
"""
old="""      ELSE
         IF (GR .LT. GMINP) GR = GMINP
      ENDIF
      RETURN"""
new="""      ELSE IF (IFRIC .EQ. 1 .AND. RE .LT. 2000.0D0) THEN
         IF (GR .LT. GMIN) GR = GMIN
      ELSE
         IF (GR .LT. GMINP) GR = GMINP
      ENDIF
      RETURN"""
init="""      DOUBLE PRECISION FRFAC
C
      IF (LTYP(L) .EQ. 2) THEN
         IF (PQ(L) .GT. 0.0D0) THEN"""
init2="""      DOUBLE PRECISION FRFAC
C
      RE = 1.0D30
      IF (LTYP(L) .EQ. 2) THEN
         IF (PQ(L) .GT. 0.0D0) THEN"""
hw="""            H = HR*ABS(Q)**1.852D0*SIGN(1.0D0,Q) + RK*Q*ABS(Q)
            GR = 1.852D0*HR*ABS(Q)**0.852D0 + 2.0D0*RK*ABS(Q)
"""
hwn="""            H = HR*ABS(Q)**1.852D0*SIGN(1.0D0,Q) + RK*Q*ABS(Q)
            GR = 1.852D0*HR*ABS(Q)**0.852D0 + 2.0D0*RK*ABS(Q)
            IF (ABS(Q) .LT. QZERO) THEN
               GR = HR*QZERO**0.852D0 + 2.0D0*RK*ABS(Q)
               H = HR*QZERO**0.852D0*Q + RK*Q*ABS(Q)
            ENDIF
"""
zhwv="""               IF (LTYP(L) .EQ. 3 .AND.
     &            ABS(QL(L)) .LT. QZERO .AND.
     &            ABS(QNEW) .LT. QZERO) QNEW = SIGN(0.0D0, QNEW)
               IF (LTYP(L) .EQ. 1 .AND. IFRIC .EQ. 2 .AND.
     &            ABS(QL(L)) .LT. QZERO .AND.
     &            ABS(QNEW) .LT. QZERO) QNEW = SIGN(0.0D0, QNEW)
"""
for a,b in [(z,zhwv),(old,new),(init,init2),(hw,hwn)]:
    assert a in s, a[:60]
    s=s.replace(a,b)
open("/w/new/solve.f","w").write(s)
PYEOF
docker exec -i sn-fortran-solver-parity python3 - < /tmp/ed14.py && docker exec sn-fortran-solver-parity bash -lc 'cd /w/new; gfortran -O2 -o hydro *.f 2>&1 | head; cd /w; python3 probes.py | tail -2; python3 ext2.py | tail -12 | grep -c DIFF; python3 gen4.py 0 800 | tail -3; python3 broad.py "{\"cur\":None}"; python3 tiny2.py | sed "s/\[.*\]//"'
```

<details><summary>output</summary>

```
bad 0 of 240
2
bad 0 of 800
cur        bad 11 of 900 [69, 87, 110, 314, 414, 469, 634, 663, 685, 771, 866]
Traceback (most recent call last):
  File "/w/tiny2.py", line 14, in <module>
    exe=build(k,v)
        ^^^^^^^^^^
  File "/w/bench.py", line 31, in build
    s=open(d+"/"+fn).read(); assert a in s,(fn,a); s=s.replace(a,b); open(d+"/"+fn,"w").write(s)
                                    ^^^^^^
AssertionError: ('solve.f', '               IF (LTYP(L) .NE. 2 .AND. ABS(QL(L)) .LT. QZERO .AND.\n     &            ABS(QNEW) .LT. QZERO) QNEW = SIGN(0.0D0, QNEW)\n')
PROD
```
</details>

### Step 203: Bash

```bash
cd /tmp; docker exec sn-fortran-solver-parity bash -lc 'cd /w; cp new/*.f new/hydro.inc /app/src/; python3 gen.py 1300 1700 | tail -2; python3 gen2.py 1300 1700 | tail -2; python3 gen3.py 600 1800 | tail -2; python3 gen4.py 800 2300 | tail -3'
```

<details><summary>output</summary>

```
  M:  CONVERGED IN  10 ITERATIONS
bad 7 of 400
  M:  CONVERGED IN   6 ITERATIONS
bad 1 of 400
bad 0 of 1200
  P:  CONVERGED IN   3 ITERATIONS
  M:  CONVERGED IN   5 ITERATIONS
bad 1 of 1500
```
</details>

### Step 204: Bash

```bash
cd /tmp; docker exec -i sn-fortran-solver-parity bash -c 'cat > /w/unusual.py' <<'EOF'
import sys,itertools
sys.path.insert(0,"/w")
from cmp import check
nets={
"parallel":"RESERVOIR R 100\nJUNCTION a 10 8\nPIPE p1 R a 300 150 0.1\nPIPE p2 R a 300 150 0.1\nPIPE p3 R a 600 100 0.1",
"series_pumps":"RESERVOIR R 50\nJUNCTION a 10 0\nJUNCTION b 60 8\nPUMP u1 R a 30\nPUMP u2 a b 40 20",
"par_pumps":"RESERVOIR R 50\nJUNCTION a 60 8\nPUMP u1 R a 30 40\nPUMP u2 R a 30 40",
"par_pumps2":"RESERVOIR R 50\nJUNCTION a 60 8\nPUMP u1 R a 30 15\nPUMP u2 R a 40 25",
"pump_valve":"RESERVOIR R 50\nJUNCTION a 10 0\nJUNCTION b 60 8\nPUMP u1 R a 30 40\nVALVE v a b 100 10",
"pump_bypass":"RESERVOIR R 50\nJUNCTION a 10 5\nJUNCTION b 60 8\nPUMP u1 R a 30 40\nPIPE p R a 100 100 .1\nPIPE q a b 200 100 .1",
"loop_equal":"RESERVOIR R 100\nJUNCTION a 10 4\nJUNCTION b 10 4\nJUNCTION c 10 4\nPIPE p1 R a 100 100 .1\nPIPE p2 a b 100 100 .1\nPIPE p3 a c 100 100 .1\nPIPE p4 b c 100 100 .1",
"loop_sym":"RESERVOIR R 100\nJUNCTION a 10 0\nJUNCTION b 10 5\nJUNCTION c 10 5\nJUNCTION d 10 0\nPIPE p1 R a 100 100 .1\nPIPE p2 a b 100 100 .1\nPIPE p3 a c 100 100 .1\nPIPE p4 b d 100 100 .1\nPIPE p5 c d 100 100 .1",
"two_res":"RESERVOIR R 100\nRESERVOIR S 95\nJUNCTION a 10 5\nJUNCTION b 10 5\nPIPE p1 R a 300 150 .1\nPIPE p2 a b 300 150 .1\nPIPE p3 b S 300 150 .1",
"dead_ends":"RESERVOIR R 100\nJUNCTION a 10 5\nJUNCTION b 10 0\nJUNCTION c 10 0\nPIPE p1 R a 100 100 .1\nPIPE p2 a b 100 100 .1\nPIPE p3 b c 100 100 .1",
"closed_valve_loop":"RESERVOIR R 100\nJUNCTION a 10 5\nJUNCTION b 10 5\nPIPE p1 R a 100 100 .1\nPIPE p2 R b 100 100 .1\nVALVE v a b 100 2 CLOSED",
"open_valve_loop":"RESERVOIR R 100\nJUNCTION a 10 5\nJUNCTION b 10 5\nPIPE p1 R a 100 100 .1\nPIPE p2 R b 300 100 .1\nVALVE v a b 100 2",
"minor_losses":"RESERVOIR R 100\nJUNCTION a 10 5\nJUNCTION b 10 5\nPIPE p1 R a 100 100 .1 3\nPIPE p2 a b 300 100 .1 10",
"big_demand":"RESERVOIR R 100\nJUNCTION a 10 80\nPIPE p1 R a 100 200 .1",
"hi_elev":"RESERVOIR R 100\nJUNCTION a 150 5\nJUNCTION b 20 5\nPIPE p1 R a 100 100 .1\nPIPE p2 a b 100 100 .1",
"transition":"RESERVOIR R 100\nJUNCTION a 10 0.25\nPIPE p1 R a 100 100 .1",
"transition2":"RESERVOIR R 100\nJUNCTION a 10 0.35\nJUNCTION b 10 0.1\nPIPE p1 R a 100 100 .1\nPIPE p2 a b 100 50 .1",
"laminar":"RESERVOIR R 100\nJUNCTION a 10 0.05\nJUNCTION b 10 0.02\nPIPE p1 R a 100 100 .1\nPIPE p2 a b 100 50 .1",
"mixed_reg":"RESERVOIR R 100\nJUNCTION a 10 0.05\nJUNCTION b 10 20\nPIPE p1 R a 100 100 .1\nPIPE p2 R b 100 50 .1\nPIPE p3 a b 100 50 .1",
"pump_reverse":"RESERVOIR R 100\nRESERVOIR S 140\nJUNCTION a 10 2\nPUMP u R a 10\nPIPE p a S 100 100 .1",
"pump_chain_res":"RESERVOIR R 100\nRESERVOIR S 120\nPUMP u R S 30 30\nJUNCTION a 10 5\nPIPE p S a 100 100 .1",
"valve_chain":"RESERVOIR R 100\nJUNCTION a 10 0\nJUNCTION b 10 5\nVALVE v R a 100 2\nVALVE w a b 100 3\nPIPE p b R 400 100 .1",
}
opts=["","OPTION FRICTION HW\n","UNITS US\n","OPTION TOL 1e-8\n","OPTION TOL 1e-3\n","OPTION MAXIT 4\n","OPTION STEPS 4\nPATTERN pt 1 2 0.5 0\n"]
bad=0;n=0
for k,v in nets.items():
    for o in opts:
        vv=v
        if "HW" in o:
            vv="\n".join(l if not l.startswith("PIPE") else " ".join(l.split()[:6]+["110"]+l.split()[7:]) for l in v.split("\n"))
        if "STEPS" in o: vv=vv.replace("JUNCTION a 10 5","JUNCTION a 10 5 pt").replace("JUNCTION b 10 5","JUNCTION b 10 5 pt")
        d=o+vv+"\nEND\n"; n+=1
        if not check(d,label=k+" "+repr(o)): bad+=1
print("bad",bad,"of",n)
EOF
docker exec sn-fortran-solver-parity bash -lc 'cd /w; python3 unusual.py 2>&1 | grep -v "^  [PM]:" | head -40'
```

<details><summary>output</summary>

```
DIFF parallel 'UNITS US\n' tok line 20
DIFF loop_equal 'UNITS US\n' tok line 23
DIFF two_res 'UNITS US\n' tok line 9
DIFF dead_ends 'OPTION STEPS 4\nPATTERN pt 1 2 0.5 0\n' tok line 80
DIFF open_valve_loop 'UNITS US\n' tok line 21
DIFF open_valve_loop 'OPTION STEPS 4\nPATTERN pt 1 2 0.5 0\n' tok line 71
DIFF minor_losses 'OPTION STEPS 4\nPATTERN pt 1 2 0.5 0\n' tok line 68
RC DIFF mixed_reg 'UNITS US\n' 0 2
DIFF pump_reverse 'UNITS US\n' tok line 9
DIFF valve_chain 'UNITS US\n' tok line 21
DIFF valve_chain 'OPTION STEPS 4\nPATTERN pt 1 2 0.5 0\n' tok line 71
bad 11 of 154
```
</details>

### Step 205: Bash

```bash
cd /tmp; docker exec sn-fortran-solver-parity bash -lc 'cd /w; cat > de.dat <<EOF
OPTION STEPS 4
PATTERN pt 1 2 0.5 0
RESERVOIR R 100
JUNCTION a 10 5 pt
JUNCTION b 10 0
JUNCTION c 10 0
PIPE p1 R a 100 100 .1
PIPE p2 a b 100 100 .1
PIPE p3 b c 100 100 .1
END
EOF
python3 diffshow.py /w/new/hydro de.dat; /app/prod/hydro < de.dat | sed -n 60,90p'
```

<details><summary>output</summary>

```
===== de.dat
- p2       PIPE  a        b            -0.00    -0.000     0.000     UNDEF  OPEN
+ p2       PIPE  a        b             0.00     0.000     0.000     UNDEF  OPEN
- p2       PIPE  a        b             0.00     0.000     0.000     UNDEF  OPEN
- p3       PIPE  b        c             0.00     0.000     0.000     UNDEF  OPEN
+ p2       PIPE  a        b            -0.00    -0.000     0.000     UNDEF  OPEN
+ p3       PIPE  b        c            -0.00    -0.000     0.000     UNDEF  OPEN
- p3       PIPE  b        c             0.00     0.000     0.000     UNDEF  OPEN
+ p3       PIPE  b        c            -0.00    -0.000     0.000     UNDEF  OPEN
- CONVERGED IN   2 ITERATIONS
+ CONVERGED IN   3 ITERATIONS
 NODE RESULTS
 ID       TYPE       ELEV    DEMAND      HEAD  PRESSURE       KPA
 -------- ----- --------- --------- --------- --------- ---------
 R        RESV    100.000     -2.50   100.000     0.000       0.0
 a        JUNC     10.000      2.50    99.866    89.866     879.8
 b        JUNC     10.000      0.00    99.866    89.866     879.8
 c        JUNC     10.000      0.00    99.866    89.866     879.8
 
 LINK RESULTS
 ID       TYPE  FROM     TO            FLOW  VELOCITY  HEADLOSS  FRICTION  STATUS
 -------- ----- -------- -------- --------- --------- --------- ---------  --------
 p1       PIPE  R        a             2.50     0.318     0.134   0.02587  OPEN    
 p2       PIPE  a        b            -0.00    -0.000     0.000     UNDEF  OPEN    
 p3       PIPE  b        c             0.00     0.000     0.000     UNDEF  OPEN    
 
 TOTAL DEMAND :      2.50 L/S
 TOTAL SUPPLY :      2.50 L/S
 *** WARNING W203: ZERO FLOW IN LINK 'p2'
 *** WARNING W203: ZERO FLOW IN LINK 'p3'
 
 TIME STEP  4 OF  4  AT  3:00
 CONVERGED IN   2 ITERATIONS
 
 NODE RESULTS
 ID       TYPE       ELEV    DEMAND      HEAD  PRESSURE       KPA
 -------- ----- --------- --------- --------- --------- ---------
 R        RESV    100.000     -0.00   100.000     0.000       0.0
 a        JUNC     10.000      0.00   100.000    90.000     881.1
 b        JUNC     10.000      0.00   100.000    90.000     881.1
 c        JUNC     10.000      0.00   100.000    90.000     881.1
```
</details>

### Step 206: Bash

```bash
cd /tmp; docker exec sn-fortran-solver-parity bash -lc 'cd /w; for e in /app/prod/hydro new/hydro; do $e < de.dat | grep -e "TIME STEP" -e " p[23] " -e CONVERGED | paste - - - - ; echo; done'
```

<details><summary>output</summary>

```
 TIME STEP  1 OF  4  AT  0:00	 CONVERGED IN   2 ITERATIONS	 p2       PIPE  a        b            -0.00    -0.000     0.000     UNDEF  OPEN    	 p3       PIPE  b        c             0.00     0.000     0.000     UNDEF  OPEN    
 TIME STEP  2 OF  4  AT  1:00	 CONVERGED IN   2 ITERATIONS	 p2       PIPE  a        b             0.00     0.000     0.000     UNDEF  OPEN    	 p3       PIPE  b        c             0.00     0.000     0.000     UNDEF  OPEN    
 TIME STEP  3 OF  4  AT  2:00	 CONVERGED IN   2 ITERATIONS	 p2       PIPE  a        b            -0.00    -0.000     0.000     UNDEF  OPEN    	 p3       PIPE  b        c             0.00     0.000     0.000     UNDEF  OPEN    
 TIME STEP  4 OF  4  AT  3:00	 CONVERGED IN   2 ITERATIONS	 p2       PIPE  a        b             0.00     0.000     0.000     UNDEF  OPEN    	 p3       PIPE  b        c             0.00     0.000     0.000     UNDEF  OPEN    

 TIME STEP  1 OF  4  AT  0:00	 CONVERGED IN   2 ITERATIONS	 p2       PIPE  a        b             0.00     0.000     0.000     UNDEF  OPEN    	 p3       PIPE  b        c             0.00     0.000     0.000     UNDEF  OPEN    
 TIME STEP  2 OF  4  AT  1:00	 CONVERGED IN   2 ITERATIONS	 p2       PIPE  a        b            -0.00    -0.000     0.000     UNDEF  OPEN    	 p3       PIPE  b        c            -0.00    -0.000     0.000     UNDEF  OPEN    
 TIME STEP  3 OF  4  AT  2:00	 CONVERGED IN   2 ITERATIONS	 p2       PIPE  a        b            -0.00    -0.000     0.000     UNDEF  OPEN    	 p3       PIPE  b        c            -0.00    -0.000     0.000     UNDEF  OPEN    
 TIME STEP  4 OF  4  AT  3:00	 CONVERGED IN   3 ITERATIONS	 p2       PIPE  a        b             0.00     0.000     0.000     UNDEF  OPEN    	 p3       PIPE  b        c             0.00     0.000     0.000     UNDEF  OPEN
```
</details>

### Step 207: Bash

```bash
cd /tmp; docker exec sn-fortran-solver-parity bash -lc 'cd /w; rm -rf dbg; cp -r new dbg; cd dbg; python3 - <<EOF
s=open("solve.f").read()
s=s.replace("         IF (SQ .GT. 1.0D-30) THEN","         WRITE (0,*) IT, (QL(L),L=1,NL), (HN(L),L=1,NN)\n         IF (SQ .GT. 1.0D-30) THEN")
open("solve.f","w").write(s)
EOF
gfortran -O2 -o hydro *.f && ./hydro < ../de.dat 2>&1 >/dev/null | head -8'
```

<details><summary>output</summary>

```
           1   4.9999999999998032E-003  -2.4326106221328652E-016   3.2354215554741931E-017   100.00000000000000        99.607825539116845        99.731255830999345        99.854686122881816     
           2   5.0000000000016143E-003   0.0000000000000000        0.0000000000000000        100.00000000000000        99.515506236439876        99.515506236439876        99.515506236439876     
           1   9.9999999999976896E-003  -3.4204305605996362E-015   0.0000000000000000        100.00000000000000        98.546518709320765        98.546518709320779        98.546518709320779     
           2   9.9999999999976982E-003  -3.4204305605996362E-015  -3.4204305605996362E-015   100.00000000000000        98.191875671378156        98.191875671378170        98.191875671378185     
           1   2.4999999999979509E-003  -3.4204305605996362E-015  -3.4204305605996362E-015   100.00000000000000        100.90406216431145        100.90406216431147        100.90406216431148     
           2   2.4999999999953532E-003  -3.4204305605996362E-015  -3.4204305605996362E-015   100.00000000000000        99.866348847662124        99.866348847662138        99.866348847662152     
           1   1.9415554842038011E-015   0.0000000000000000        3.4204305605996362E-015   100.00000000000000        100.13365115233769        100.13365115233769        100.13365115233768     
           2   0.0000000000000000        3.4204305605996362E-015   3.4204305605996362E-015   100.00000000000000        100.00000000000000        99.999999999999986        99.999999999999972
```
</details>

### Step 208: Bash

```bash
cd /tmp; cat > /tmp/vv.py <<'PYEOF'
q0="               QNEW = QL(L) - Y(L) + P(L)*(HN(N1) - HN(N2))\n"
h0="               CALL HLGRAD(L, QL(L), H, GR)\n"
d={"base":[],
"q2":[("solve.f",q0,"               QNEW = QL(L) - (Y(L) - P(L)*(HN(N1) - HN(N2)))\n")],
"q3":[("solve.f",q0,"               QNEW = QL(L) - P(L)*(H - (HN(N1) - HN(N2)))\n")],
}
open("/w/vv.txt","w").write(repr(d))
PYEOF
docker exec -i sn-fortran-solver-parity python3 - < /tmp/vv.py
echo
```

<details><summary>output</summary>

```
(Bash completed with no output)
```
</details>

### Step 209: Bash

```bash
cd /tmp; docker exec -i sn-fortran-solver-parity bash -c 'cat > /w/zfam.py' <<'EOF'
import sys,random
sys.path.insert(0,"/w")
from cmp import run,cmp,PROD
from bench import build
def decks():
    D=[]
    r=random.Random(5)
    for i in range(80):
        n=r.randint(3,7)
        L=["OPTION STEPS 4","PATTERN pt 1 %s 0.5 0"%r.choice(["2","0","1.5"]),"RESERVOIR R 100"]
        for j in range(n):
            q=r.choice([0,0,5,2.5,8,1])
            L.append("JUNCTION J%d 10 %s%s"%(j,q," pt" if r.random()<0.5 else ""))
        for j in range(n):
            a=r.choice(["R"]+["J%d"%k for k in range(j)]) 
            L.append("PIPE P%d %s J%d %d %d 0.1"%(j,a,j,r.choice([100,200,500]),r.choice([100,150,200])))
        if r.random()<0.5: L.append("OPTION FRICTION HW"); L=[l if not l.startswith("PIPE") else " ".join(l.split()[:6]+["110"]) for l in L]
        L.append("END"); D.append("\n".join(L)+"\n")
    return D
D=decks()
P=[run(PROD,d) for d in D]
def score(exe):
    return sum(1 for d,p in zip(D,P) if not (run(exe,d)[1]==p[1] and cmp(p[0],run(exe,d)[0])[0] is None))
if __name__=="__main__":
    vs=eval(sys.argv[1])
    for k,v in vs.items():
        exe=build(k,v) if v is not None else "/w/new/hydro"
        print(k,"bad",score(exe),"of",len(D))
EOF
docker exec sn-fortran-solver-parity bash -lc 'cd /w; python3 zfam.py "$(cat vv.txt | sed "s/\"q3\".*\]\],/ /")" 2>&1 | tail -5; python3 zfam.py "{\"cur\":None}"'
```

<details><summary>output</summary>

```
base bad 4 of 80
q2 bad 4 of 80
q3 bad 80 of 80
cur bad 4 of 80
```
</details>

### Step 210: Bash

```bash
cd /tmp; cat > /tmp/vv2.py <<'PYEOF'
ix="""      DO 10 I = 1, NN
         IX(I) = 0
         IF (NTYP(I) .EQ. 1 .AND. NISO(I) .EQ. 0) THEN
            NEQ = NEQ + 1
            IX(I) = NEQ
         ENDIF
         IF (NTYP(I) .EQ. 2) HN(I) = ZN(I)
   10 CONTINUE"""
ix2="""      DO 10 I = 1, NN
         IX(I) = 0
         IF (NTYP(I) .EQ. 2) HN(I) = ZN(I)
   10 CONTINUE
      DO 11 II = 1, NN
         I = NSORT(II)
         IF (NTYP(I) .EQ. 1 .AND. NISO(I) .EQ. 0) THEN
            NEQ = NEQ + 1
            IX(I) = NEQ
         ENDIF
   11 CONTINUE"""
piv="""            IF (ABS(A(I,K)) .GT. BIG) THEN
               BIG = ABS(A(I,K))
               IP = I
            ENDIF"""
chol_call="""            CALL LINSOL(AM, RHS, HX, NEQ, MXN)"""
chol="""            CALL CHOL(AM, RHS, HX, NEQ, MXN)"""
chol_sub="""C
C     CHOL
C
      SUBROUTINE CHOL(A, B, X, N, LDA)
      IMPLICIT NONE
      INTEGER N, LDA
      DOUBLE PRECISION A(LDA,*), B(*), X(*)
      INTEGER I, J, K
      DOUBLE PRECISION T
      DO 50 J = 1, N
         T = A(J,J)
         DO 10 K = 1, J-1
            T = T - A(J,K)*A(J,K)
   10    CONTINUE
         A(J,J) = SQRT(T)
         DO 30 I = J+1, N
            T = A(I,J)
            DO 20 K = 1, J-1
               T = T - A(I,K)*A(J,K)
   20       CONTINUE
            A(I,J) = T/A(J,J)
   30    CONTINUE
   50 CONTINUE
      DO 70 I = 1, N
         T = B(I)
         DO 60 K = 1, I-1
            T = T - A(I,K)*X(K)
   60    CONTINUE
         X(I) = T/A(I,I)
   70 CONTINUE
      DO 90 I = N, 1, -1
         T = X(I)
         DO 80 K = I+1, N
            T = T - A(K,I)*X(K)
   80    CONTINUE
         X(I) = T/A(I,I)
   90 CONTINUE
      RETURN
      END
"""
d={"sorted":[("solve.f",ix,ix2),("solve.f","INTEGER I, J, L, N1, N2, K1, K2, NEQ, IT","INTEGER I, J, L, N1, N2, K1, K2, NEQ, IT, II")],
"nopiv":[("solve.f",piv,"            CONTINUE")],
"chol":[("solve.f",chol_call,chol),("solve.f","C     LINSOL  -  GAUSSIAN","C     X\n"+chol_sub+"C\nC     LINSOL  -  GAUSSIAN")],
}
open("/w/vv.txt","w").write(repr(d))
PYEOF
docker exec -i sn-fortran-solver-parity python3 - < /tmp/vv2.py
docker exec sn-fortran-solver-parity bash -lc 'cd /w; python3 zfam.py "$(cat vv.txt)"; python3 badscore.py "$(cat vv.txt)"'
```

<details><summary>output</summary>

```
sorted bad 4 of 80
nopiv bad 4 of 80
chol bad 4 of 80
sorted       fixed 7/33, good kept 119/120
nopiv        fixed 6/33, good kept 119/120
chol         fixed 6/33, good kept 119/120
```
</details>

### Step 211: Bash

```bash
cd /tmp; docker exec sn-fortran-solver-parity bash -lc 'cd /w; python3 - <<EOF
import sys
sys.path.insert(0,"/w")
from zfam import *
n=0
for i,(d,p) in enumerate(zip(D,P)):
    m=run("/w/new/hydro",d)
    if not (m[1]==p[1] and cmp(p[0],m[0])[0] is None):
        open("/w/zf%d.dat"%i,"w").write(d); print(i); n+=1
EOF
ls zf*.dat | head; python3 diffshow.py /w/new/hydro zf*.dat 2>&1 | head -60'
```

<details><summary>output</summary>

```
12
41
46
77
zf12.dat
zf41.dat
zf46.dat
zf77.dat
===== zf12.dat
- CONVERGED IN   2 ITERATIONS
+ CONVERGED IN   3 ITERATIONS
- P2       PIPE  J1       J2            0.00     0.000     0.000     UNDEF  OPEN
+ P2       PIPE  J1       J2           -0.00    -0.000     0.000     UNDEF  OPEN
===== zf41.dat
- P3       PIPE  R        J3           -0.00    -0.000     0.000     UNDEF  OPEN
+ P3       PIPE  R        J3            0.00     0.000     0.000     UNDEF  OPEN
- P5       PIPE  J2       J5            0.00     0.000     0.000     UNDEF  OPEN
+ P5       PIPE  J2       J5           -0.00    -0.000     0.000     UNDEF  OPEN
- CONVERGED IN   2 ITERATIONS
+ CONVERGED IN   3 ITERATIONS
- P5       PIPE  J2       J5            0.00     0.000     0.000     UNDEF  OPEN
+ P5       PIPE  J2       J5           -0.00    -0.000     0.000     UNDEF  OPEN
- P5       PIPE  J2       J5            0.00     0.000     0.000     UNDEF  OPEN
+ P5       PIPE  J2       J5           -0.00    -0.000     0.000     UNDEF  OPEN
- CONVERGED IN   2 ITERATIONS
+ CONVERGED IN   3 ITERATIONS
- P0       PIPE  R        J0           -0.00    -0.000     0.000     UNDEF  OPEN
===== zf46.dat
- P2       PIPE  J1       J2            0.00     0.000     0.000            OPEN
+ P2       PIPE  J1       J2           -0.00    -0.000     0.000            OPEN
- P6       PIPE  J1       J6           -0.00    -0.000     0.000            OPEN
+ P6       PIPE  J1       J6            0.00     0.000     0.000            OPEN
- CONVERGED IN   3 ITERATIONS
+ CONVERGED IN   2 ITERATIONS
- R        RESV    100.000      0.00   100.000     0.000       0.0
+ R        RESV    100.000     -0.00   100.000     0.000       0.0
- P0       PIPE  R        J0           -0.00    -0.000     0.000            OPEN
- P1       PIPE  J0       J1           -0.00    -0.000     0.000            OPEN
+ P0       PIPE  R        J0            0.00     0.000     0.000            OPEN
+ P1       PIPE  J0       J1            0.00     0.000     0.000            OPEN
- P4       PIPE  J0       J4            0.00     0.000     0.000            OPEN
===== zf77.dat
- CONVERGED IN   2 ITERATIONS
+ CONVERGED IN   3 ITERATIONS
- P3       PIPE  J1       J3           -0.00    -0.000     0.000     UNDEF  OPEN
+ P3       PIPE  J1       J3            0.00     0.000     0.000     UNDEF  OPEN
- CONVERGED IN   2 ITERATIONS
+ CONVERGED IN   3 ITERATIONS
- P3       PIPE  J1       J3           -0.00    -0.000     0.000     UNDEF  OPEN
+ P3       PIPE  J1       J3            0.00     0.000     0.000     UNDEF  OPEN
```
</details>

### Step 212: Bash

```bash
cd /tmp; cat > /tmp/vv3.py <<'PYEOF'
a="         IF (SQ .GT. 1.0D-30) THEN"
d={}
for t in ["1.0D-30","1.0D-14","1.0D-12","1.0D-10","1.0D-8","1.0D-6","1.0D-4"]:
    d["sq"+t]=[("solve.f",a,"         IF (SQ .GT. %s) THEN"%t)]
open("/w/vv.txt","w").write(repr(d))
PYEOF
docker exec -i sn-fortran-solver-parity python3 - < /tmp/vv3.py
docker exec sn-fortran-solver-parity bash -lc 'cd /w; python3 zfam.py "$(cat vv.txt)"; python3 badscore.py "$(cat vv.txt)"'
```

<details><summary>output</summary>

```
sq1.0D-30 bad 4 of 80
sq1.0D-14 bad 2 of 80
sq1.0D-12 bad 1 of 80
sq1.0D-10 bad 1 of 80
sq1.0D-8 bad 1 of 80
sq1.0D-6 bad 1 of 80
sq1.0D-4 bad 1 of 80
sq1.0D-30    fixed 6/33, good kept 119/120
sq1.0D-14    fixed 6/33, good kept 119/120
sq1.0D-12    fixed 6/33, good kept 119/120
sq1.0D-10    fixed 6/33, good kept 119/120
sq1.0D-8     fixed 6/33, good kept 119/120
sq1.0D-6     fixed 6/33, good kept 119/120
sq1.0D-4     fixed 6/33, good kept 119/120
```
</details>

### Step 213: Bash

```bash
cd /tmp; cat > /tmp/vv3.py <<'PYEOF'
a="         IF (SQ .GT. 1.0D-30) THEN"
d={}
for t in ["1.0D-12","1.0D-9","1.0D-6"]:
    d["sq"+t]=[("solve.f",a,"         IF (SQ .GT. %s) THEN"%t)]
open("/w/vv.txt","w").write(repr(d))
PYEOF
docker exec -i sn-fortran-solver-parity python3 - < /tmp/vv3.py
docker exec sn-fortran-solver-parity bash -lc 'cd /w; python3 broad.py "$(cat vv.txt)"; python3 multi.py "$(cat vv.txt)"'
```

<details><summary>output</summary>

```
sq1.0D-12  bad 11 of 900 [69, 87, 110, 314, 414, 469, 634, 663, 685, 771, 866]
sq1.0D-9   bad 11 of 900 [69, 87, 110, 314, 414, 469, 634, 663, 685, 771, 866]
sq1.0D-6   bad 11 of 900 [69, 87, 110, 314, 414, 469, 634, 663, 685, 771, 866]
sq1.0D-12  45 z2 1/48 z4 16/54 bench 28/112
sq1.0D-9   45 z2 1/48 z4 16/54 bench 28/112
sq1.0D-6   45 z2 1/48 z4 16/54 bench 28/112
```
</details>

### Step 214: Bash

```bash
cd /tmp; docker exec -i sn-fortran-solver-parity bash -c 'cat > /w/sqt.py' <<'EOF'
import sys
sys.path.insert(0,"/w")
from bench import seq
from cmp import PROD,MINE
f=lambda s:[x[0] or "NC" for x in s[1]]
for q in ["1e-9","1e-8","1e-7","1e-6","1e-5","1e-4","1e-3","1e-2","0.1"]:
    d="OPTION FRICTION HW\nOPTION TOL 1e-5\nRESERVOIR R 100\nJUNCTION a 10 %s\nJUNCTION b 10 0\nPIPE p1 R a 100 100 100\nPIPE p2 a b 300 100 100\nPIPE p3 b R 200 100 100\nEND\n"%q
    print(q,f(seq(PROD,d)),f(seq(MINE,d)))
EOF
docker exec sn-fortran-solver-parity bash -lc 'cd /w; python3 sqt.py'
```

<details><summary>output</summary>

```
1e-9 ['13'] ['12']
1e-8 ['13'] ['12']
1e-7 ['13'] ['12']
1e-6 ['13'] ['12']
1e-5 ['13'] ['12']
1e-4 ['13'] ['12']
1e-3 ['13'] ['12']
1e-2 ['13'] ['13']
0.1 ['10'] ['10']
```
</details>

### Step 215: Bash

```bash
cd /tmp; docker exec sn-fortran-solver-parity bash -lc 'cd /w; sed -i "s/\[\"1e-9\",\"1e-8\"/[\"1e-13\",\"1e-12\",\"1e-11\",\"1e-10\",\"1e-9\",\"1e-8\"/" sqt.py; python3 sqt.py | head -8'
```

<details><summary>output</summary>

```
1e-13 ['13'] ['12']
1e-12 ['13'] ['12']
1e-11 ['13'] ['12']
1e-10 ['13'] ['12']
1e-9 ['13'] ['12']
1e-8 ['13'] ['12']
1e-7 ['13'] ['12']
1e-6 ['13'] ['12']
```
</details>

### Step 216: Bash

```bash
cd /tmp; cat > /tmp/vv4.py <<'PYEOF'
ix="""      DO 10 I = 1, NN
         IX(I) = 0
         IF (NTYP(I) .EQ. 1 .AND. NISO(I) .EQ. 0) THEN
            NEQ = NEQ + 1
            IX(I) = NEQ
         ENDIF
         IF (NTYP(I) .EQ. 2) HN(I) = ZN(I)
   10 CONTINUE"""
rev="""      DO 10 I = 1, NN
         IX(I) = 0
         IF (NTYP(I) .EQ. 2) HN(I) = ZN(I)
   10 CONTINUE
      DO 11 I = NN, 1, -1
         IF (NTYP(I) .EQ. 1 .AND. NISO(I) .EQ. 0) THEN
            NEQ = NEQ + 1
            IX(I) = NEQ
         ENDIF
   11 CONTINUE"""
revs="""      DO 10 I = 1, NN
         IX(I) = 0
         IF (NTYP(I) .EQ. 2) HN(I) = ZN(I)
   10 CONTINUE
      DO 11 II = NN, 1, -1
         I = NSORT(II)
         IF (NTYP(I) .EQ. 1 .AND. NISO(I) .EQ. 0) THEN
            NEQ = NEQ + 1
            IX(I) = NEQ
         ENDIF
   11 CONTINUE"""
ii=("solve.f","INTEGER I, J, L, N1, N2, K1, K2, NEQ, IT","INTEGER I, J, L, N1, N2, K1, K2, NEQ, IT, II")
d={"rev":[("solve.f",ix,rev)],"revsorted":[("solve.f",ix,revs),ii]}
open("/w/vv.txt","w").write(repr(d))
PYEOF
docker exec -i sn-fortran-solver-parity python3 - < /tmp/vv4.py
docker exec sn-fortran-solver-parity bash -lc 'cd /w; python3 zfam.py "$(cat vv.txt)"; python3 badscore.py "$(cat vv.txt)"; python3 broad.py "$(cat vv.txt)"'
```

<details><summary>output</summary>

```
rev bad 2 of 80
revsorted bad 2 of 80
rev          fixed 8/33, good kept 119/120
revsorted    fixed 7/33, good kept 119/120
rev        bad 10 of 900 [69, 87, 314, 414, 454, 469, 634, 685, 771, 866]
revsorted  bad 11 of 900 [69, 87, 110, 314, 414, 454, 469, 634, 685, 771, 866]
```
</details>

### Step 217: Bash

```bash
cd /tmp; cat > /tmp/vv5.py <<'PYEOF'
ix="""      DO 10 I = 1, NN
         IX(I) = 0
         IF (NTYP(I) .EQ. 1 .AND. NISO(I) .EQ. 0) THEN
            NEQ = NEQ + 1
            IX(I) = NEQ
         ENDIF
         IF (NTYP(I) .EQ. 2) HN(I) = ZN(I)
   10 CONTINUE"""
mind="""      DO 10 I = 1, NN
         IX(I) = 0
         IF (NTYP(I) .EQ. 1 .AND. NISO(I) .EQ. 0) THEN
            NEQ = NEQ + 1
            IX(I) = NEQ
         ENDIF
         IF (NTYP(I) .EQ. 2) HN(I) = ZN(I)
   10 CONTINUE
      CALL MDORD(IX, NEQ)"""
sub="""C
C     MDORD  -  MINIMUM-DEGREE ORDERING OF THE UNKNOWN NODES
C
      SUBROUTINE MDORD(IX, NEQ)
      IMPLICIT NONE
      INCLUDE 'hydro.inc'
      INTEGER IX(*), NEQ
      LOGICAL ADJ(MXN,MXN)
      INTEGER ORD(MXN), DEG(MXN), K, M, I, J, L, IMIN, MIN, KN, NB(MXN)
      INTEGER NNB, JJ, KK, INV(MXN)
      DO 5 I = 1, NN
         IF (IX(I) .GT. 0) INV(IX(I)) = I
    5 CONTINUE
      DO 20 I = 1, NEQ
         DO 10 J = 1, NEQ
            ADJ(I,J) = .FALSE.
   10    CONTINUE
   20 CONTINUE
      DO 30 L = 1, NL
         IF (LACT(L) .EQ. 1) THEN
            I = IX(LI(L))
            J = IX(LJ(L))
            IF (I .GT. 0 .AND. J .GT. 0) THEN
               ADJ(I,J) = .TRUE.
               ADJ(J,I) = .TRUE.
            ENDIF
         ENDIF
   30 CONTINUE
      DO 45 I = 1, NEQ
         ORD(I) = I
         DEG(I) = 0
         DO 40 J = 1, NEQ
            IF (ADJ(I,J)) DEG(I) = DEG(I) + 1
   40    CONTINUE
   45 CONTINUE
      DO 100 K = 1, NEQ
         MIN = NEQ + 1
         IMIN = NEQ
         DO 50 M = K, NEQ
            IF (DEG(ORD(M)) .LE. MIN) THEN
               MIN = DEG(ORD(M))
               IMIN = M
            ENDIF
   50    CONTINUE
         KN = ORD(IMIN)
         NNB = 0
         DO 60 J = 1, NEQ
            IF (ADJ(KN,J)) THEN
               NNB = NNB + 1
               NB(NNB) = J
            ENDIF
   60    CONTINUE
         DO 80 JJ = 1, NNB
            DO 70 KK = JJ+1, NNB
               ADJ(NB(JJ),NB(KK)) = .TRUE.
               ADJ(NB(KK),NB(JJ)) = .TRUE.
   70       CONTINUE
   80    CONTINUE
         DO 90 JJ = 1, NNB
            ADJ(KN,NB(JJ)) = .FALSE.
            ADJ(NB(JJ),KN) = .FALSE.
   90    CONTINUE
         DO 95 I = 1, NEQ
            DEG(I) = 0
            DO 94 J = 1, NEQ
               IF (ADJ(I,J)) DEG(I) = DEG(I) + 1
   94       CONTINUE
   95    CONTINUE
         ORD(IMIN) = ORD(K)
         ORD(K) = KN
  100 CONTINUE
      DO 110 K = 1, NEQ
         IX(INV(ORD(K))) = K
  110 CONTINUE
      RETURN
      END
"""
d={"mindeg":[("solve.f",ix,mind),("solve.f","C     CONNECT  -  FIND",sub+"C\nC     CONNECT  -  FIND")]}
open("/w/vv.txt","w").write(repr(d))
PYEOF
docker exec -i sn-fortran-solver-parity python3 - < /tmp/vv5.py
docker exec sn-fortran-solver-parity bash -lc 'cd /w; python3 zfam.py "$(cat vv.txt)"; python3 badscore.py "$(cat vv.txt)"; python3 broad.py "$(cat vv.txt)"'
```

<details><summary>output</summary>

```
mindeg bad 3 of 80
mindeg       fixed 7/33, good kept 119/120
mindeg     bad 12 of 900 [69, 87, 110, 314, 414, 454, 469, 634, 663, 685, 771, 866]
```
</details>

### Step 218: Bash

```bash
cd /tmp; cat > /tmp/broad2.py <<'PYEOF'
import sys
sys.path.insert(0,"/w")
from cmp import run,cmp,PROD
from gen import gen
from gen2 import mutate
from bench import build
vs=eval(sys.argv[1])
decks=[gen(s) for s in range(4000,4700)]+[mutate(gen(s),s) for s in range(4000,4350)]
P=[run(PROD,d) for d in decks]
for n,v in vs.items():
    exe=build(n,v) if v is not None else "/w/new/hydro"
    bad=[i for i,(d,p) in enumerate(zip(decks,P)) if not (run(exe,d)[1]==p[1] and cmp(p[0],run(exe,d)[0])[0] is None)]
    print("%-10s bad %d of %d"%(n,len(bad),len(decks)),bad[:40])
PYEOF
docker exec -i sn-fortran-solver-parity bash -c 'cat > /w/broad2.py' < /tmp/broad2.py
docker exec -i sn-fortran-solver-parity python3 - < /tmp/vv4.py
docker exec sn-fortran-solver-parity bash -lc 'cd /w; python3 - <<EOF
d=eval(open("/w/vv.txt").read()); d["cur"]=None
open("/w/vv.txt","w").write(repr(d))
EOF
python3 broad2.py "$(cat vv.txt)"'
```

<details><summary>output</summary>

```
rev        bad 12 of 1050 [92, 116, 117, 201, 248, 547, 634, 783, 792, 816, 948, 957]
revsorted  bad 12 of 1050 [92, 116, 117, 201, 248, 547, 634, 783, 792, 816, 948, 957]
cur        bad 13 of 1050 [92, 116, 117, 201, 248, 547, 634, 647, 783, 792, 816, 948, 957]
```
</details>

### Step 219: Bash

```bash
cd /tmp; cat > /tmp/vv6.py <<'PYEOF'
exec(open("/tmp/vv4.py").read().split("d={")[0])
a="         IF (SQ .GT. 1.0D-30) THEN"
d={"rev_sq":[("solve.f",ix,rev),("solve.f",a,"         IF (SQ .GT. 1.0D-12) THEN")],
   "sq":[("solve.f",a,"         IF (SQ .GT. 1.0D-12) THEN")]}
open("/w/vv.txt","w").write(repr(d))
PYEOF
docker exec -i sn-fortran-solver-parity bash -c 'cat > /tmp/vv4.py' < /tmp/vv4.py
docker exec -i sn-fortran-solver-parity bash -c 'cat > /tmp/vv6.py' < /tmp/vv6.py
docker exec sn-fortran-solver-parity bash -lc 'cd /w; python3 /tmp/vv6.py; python3 zfam.py "$(cat vv.txt)"; python3 badscore.py "$(cat vv.txt)"; python3 broad.py "$(cat vv.txt)"; python3 broad2.py "$(cat vv.txt)"'
```

<details><summary>output</summary>

```
rev_sq bad 1 of 80
sq bad 1 of 80
rev_sq       fixed 8/33, good kept 119/120
sq           fixed 6/33, good kept 119/120
rev_sq     bad 10 of 900 [69, 87, 314, 414, 454, 469, 634, 685, 771, 866]
sq         bad 11 of 900 [69, 87, 110, 314, 414, 469, 634, 663, 685, 771, 866]
rev_sq     bad 12 of 1050 [92, 116, 117, 201, 248, 547, 634, 783, 792, 816, 948, 957]
sq         bad 13 of 1050 [92, 116, 117, 201, 248, 547, 634, 647, 783, 792, 816, 948, 957]
```
</details>

### Step 220: Bash

```bash
cd /tmp; cat > /tmp/ed15.py <<'PYEOF'
s=open("/w/new/solve.f").read()
ix="""      DO 10 I = 1, NN
         IX(I) = 0
         IF (NTYP(I) .EQ. 1 .AND. NISO(I) .EQ. 0) THEN
            NEQ = NEQ + 1
            IX(I) = NEQ
         ENDIF
         IF (NTYP(I) .EQ. 2) HN(I) = ZN(I)
   10 CONTINUE"""
rev="""      DO 10 I = 1, NN
         IX(I) = 0
         IF (NTYP(I) .EQ. 2) HN(I) = ZN(I)
   10 CONTINUE
      DO 11 I = NN, 1, -1
         IF (NTYP(I) .EQ. 1 .AND. NISO(I) .EQ. 0) THEN
            NEQ = NEQ + 1
            IX(I) = NEQ
         ENDIF
   11 CONTINUE"""
assert ix in s
s=s.replace(ix,rev)
a="         IF (SQ .GT. 1.0D-30) THEN"
assert a in s
s=s.replace(a,"         IF (SQ .GT. 1.0D-12) THEN")
open("/w/new/solve.f","w").write(s)
PYEOF
docker exec -i sn-fortran-solver-parity python3 - < /tmp/ed15.py
docker exec sn-fortran-solver-parity bash -lc 'cd /w/new; gfortran -O2 -o hydro *.f 2>&1 | head; cd /w; python3 probes.py | tail -1; python3 ext.py | tail -1; python3 ext2.py | tail -1; python3 gen3.py 0 600 | tail -1; python3 gen4.py 0 1000 | tail -1; python3 unusual.py | tail -1; cp new/*.f new/hydro.inc /app/src/'
```

<details><summary>output</summary>

```
bad 0 of 240
bad 1
bad 5
bad 0 of 600
bad 0 of 1000
bad 10 of 154
```
</details>

### Step 221: Bash

```bash
cd /tmp; docker exec sn-fortran-solver-parity bash -lc 'cd /w; python3 unusual.py 2>&1 | grep -e "^DIFF" -e "^RC"'
```

<details><summary>output</summary>

```
DIFF parallel 'UNITS US\n' tok line 20
DIFF loop_equal 'UNITS US\n' tok line 23
DIFF two_res 'UNITS US\n' tok line 9
DIFF open_valve_loop 'UNITS US\n' tok line 21
DIFF open_valve_loop 'OPTION STEPS 4\nPATTERN pt 1 2 0.5 0\n' tok line 71
DIFF laminar 'UNITS US\n' tok line 21
RC DIFF mixed_reg 'UNITS US\n' 0 2
DIFF pump_reverse 'UNITS US\n' tok line 9
DIFF valve_chain 'UNITS US\n' tok line 21
DIFF valve_chain 'OPTION STEPS 4\nPATTERN pt 1 2 0.5 0\n' tok line 71
```
</details>

### Step 222: Bash

```bash
cd /tmp; docker exec sn-fortran-solver-parity bash -lc 'cd /w; printf "UNITS US\nRESERVOIR R 100\nJUNCTION a 10 8\nPIPE p1 R a 300 150 0.1\nPIPE p2 R a 300 150 0.1\nPIPE p3 R a 600 100 0.1\nEND\n" > us1.dat; python3 diffshow.py /w/new/hydro us1.dat; /app/prod/hydro < us1.dat | grep -e CONV -e " p"; new/hydro < us1.dat | grep -e CONV -e " p"'
```

<details><summary>output</summary>

```
===== us1.dat
- a        JUNC     10.000      8.00   100.000    90.000     39.01
+ a        JUNC     10.000      8.00   100.000    90.000     39.02
- p1       PIPE  R        a             3.67     0.000     0.000   0.82774  OPEN
- p2       PIPE  R        a             3.67     0.000     0.000   0.82774  OPEN
- p3       PIPE  R        a             0.67     0.000     0.000   3.04061  OPEN
+ p1       PIPE  R        a          1752.60     0.032     0.000   0.02228  OPEN
+ p2       PIPE  R        a          1752.60     0.032     0.000   0.02228  OPEN
+ p3       PIPE  R        a         -3497.20    -0.143     0.000   0.01757  OPEN
STOP 2
 *** WARNING W205: NOT CONVERGED AFTER 50 ITERATIONS
 p1       PIPE  R        a             3.67     0.000     0.000   0.82774  OPEN    
 p2       PIPE  R        a             3.67     0.000     0.000   0.82774  OPEN    
 p3       PIPE  R        a             0.67     0.000     0.000   3.04061  OPEN    
STOP 2
 *** WARNING W205: NOT CONVERGED AFTER 50 ITERATIONS
 p1       PIPE  R        a          1752.60     0.032     0.000   0.02228  OPEN    
 p2       PIPE  R        a          1752.60     0.032     0.000   0.02228  OPEN    
 p3       PIPE  R        a         -3497.20    -0.143     0.000   0.01757  OPEN
```
</details>

### Step 223: Bash

```bash
cd /tmp; docker exec sn-fortran-solver-parity bash -lc 'cd /w; rm -rf dbg; cp -r new dbg; cd dbg; python3 - <<EOF
s=open("solve.f").read()
s=s.replace("         IF (SQ .GT. 1.0D-12) THEN","         WRITE (0,*) IT, (QL(L),L=1,NL), HN(1)\n         IF (SQ .GT. 1.0D-12) THEN")
open("solve.f","w").write(s)
EOF
gfortran -O2 -o hydro *.f && ./hydro < ../us1.dat 2>&1 >/dev/null | head -12'
```

<details><summary>output</summary>

```
           1  0.69216691693897126       0.69216691693897126       -1.3838291123071373        30.480000000000000     
           2  0.63356782431498104       0.63356782431498104       -1.2666309270595428        30.480000000000000     
           3  0.58377008274507680       0.58377008274507680       -1.1670354439193211        30.480000000000000     
           4  0.54092734213640259       0.54092734213640259       -1.0813499627020975        30.480000000000000     
           5  0.50367889726461901       0.50367889726461901       -1.0068530729582816        30.480000000000000     
           6  0.47099891775028990       0.47099891775028990      -0.94149311392972723        30.480000000000000     
           7  0.44209885954380995       0.44209885954380995      -0.88369299751631436        30.480000000000000     
           8  0.41636228868540659       0.41636228868540659      -0.83221985580021562        30.480000000000000     
           9  0.39330016377770644       0.39330016377770644      -0.78609560598420236        30.480000000000000     
          10  0.37251942795502330       0.37251942795502330      -0.74453413433912652        30.480000000000000     
          11  0.35370049032135403       0.35370049032135403      -0.70689625907166276        30.480000000000000     
          12  0.33658078380516715       0.33658078380516715      -0.67265684603919818        30.480000000000000
```
</details>

### Step 224: Bash

```bash
cd /tmp; docker exec -i sn-fortran-solver-parity bash -c 'cat > /w/fitstart.py' <<'EOF'
from math import *
nu=1e-6;g=9.80665
D=[150*0.0254,150*0.0254,100*0.0254]; L=[300*0.3048,300*0.3048,600*0.3048]
dem=8*3.785411784e-3/60
A=[pi*d*d/4 for d in D]
r0=[32*nu*l/(g*d*d*a) for d,l,a in zip(D,L,A)]
def sim(Q,n=50,gr=1e-4):
    for it in range(n):
        h=[r*q for r,q in zip(r0,Q)]
        p=1/gr
        y=[p*x for x in h]
        # node a unknown: sum(Q_i - y_i + p*(Hr - Ha)) = dem
        s=sum(q-yy for q,yy in zip(Q,y))
        dH=(dem-s)/(3*p)   # Hr-Ha
        Q=[q-yy+p*dH for q,yy in zip(Q,y)]
    return Q
gpm=lambda q:q/(3.785411784e-3/60)
print("target 3.67 3.67 0.67")
for v0 in [0.3048,0.01,1e-3,1e-4,1e-5,1e-6]:
    Q=[v0*a for a in A]
    print(v0,[round(gpm(q),2) for q in sim(Q)])
for c in [1/3.0]:
    print("equal",[round(gpm(q),2) for q in sim([dem/3]*3)])
print("zero",[round(gpm(q),2) for q in sim([0,0,0])])
EOF
docker exec sn-fortran-solver-parity bash -lc 'cd /w; python3 fitstart.py'
```

<details><summary>output</summary>

```
target 3.67 3.67 0.67
0.3048 [17.86, 17.86, -27.73]
0.01 [4.27, 4.27, -0.54]
0.001 [3.86, 3.86, 0.29]
0.0001 [3.81, 3.81, 0.37]
1e-05 [3.81, 3.81, 0.38]
1e-06 [3.81, 3.81, 0.38]
equal [3.81, 3.81, 0.38]
zero [3.81, 3.81, 0.38]
```
</details>

### Step 225: Bash

```bash
cd /tmp; docker exec sn-fortran-solver-parity bash -lc 'cd /app/src; ls -la; grep -inE "execute_command|system|bind|iso_c|exec|popen|fork|dlopen|dlsym" *.f hydro.inc; awk "length>72" *.f hydro.inc | head; rm -rf /w/build && mkdir /w/build && cp /app/src/* /w/build/ && cd /w/build && gfortran -O2 -o hydro *.f 2>&1 | head -5; ls; for f in /app/examples/*.dat; do ./hydro < $f > /tmp/o.txt; /app/prod/hydro < $f > /tmp/p.txt 2>/dev/null; diff /tmp/o.txt /tmp/p.txt > /dev/null && echo same || echo DIFF; done'
```

<details><summary>output</summary>

```
total 76
drwxr-xr-x 1 root root  4096 Nov 18 09:18 .
drwxr-xr-x 1 root root  4096 Nov 18 08:34 ..
-rw-r--r-- 1 root root  1069 Nov 18 08:30 LICENSE
-rw-r--r-- 1 root root 16567 Nov 18 09:35 cards.f
-rw-r--r-- 1 root root  3574 Nov 18 09:35 check.f
-rw-r--r-- 1 root root   978 Nov 18 09:35 frict.f
-rw-r--r-- 1 root root  2083 Nov 18 09:35 hydro.inc
-rw-r--r-- 1 root root  1382 Nov 18 09:35 main.f
-rw-r--r-- 1 root root  9023 Nov 18 09:35 output.f
-rw-r--r-- 1 root root  8289 Nov 18 09:35 solve.f
solve.f:289: 1000 FORMAT (1X,'*** ERROR E303: SINGULAR SYSTEM')
LICENSE
cards.f
check.f
frict.f
hydro
hydro.inc
main.f
output.f
solve.f
DIFF
DIFF
DIFF
```
</details>

### Step 226: Bash

```bash
cd /tmp; docker exec sn-fortran-solver-parity bash -lc 'cd /w; sed -i "s#MINE=\"/w/new/hydro\"#MINE=\"/w/build/hydro\"#" cmp.py; python3 cmp.py /app/examples/*.dat; /w/build/hydro < /app/examples/branch.dat > /tmp/o.txt; /app/prod/hydro < /app/examples/branch.dat > /tmp/p.txt; diff /tmp/o.txt /tmp/p.txt | cat -A | head'
```

<details><summary>output</summary>

```
3 / 3
26c26$
< $
---$
>  $
```
</details>

### Step 227: Bash

```bash
cd /tmp; cat > /tmp/ed16.py <<'PYEOF'
s=open("/w/new/main.f").read()
a=" 1010 FORMAT (/1X,'RUN COMPLETED WITH ',I3,' WARNING(S)')"
assert a in s
s=s.replace(a," 1010 FORMAT (1X/1X,'RUN COMPLETED WITH ',I3,' WARNING(S)')")
open("/w/new/main.f","w").write(s)
PYEOF
docker exec -i sn-fortran-solver-parity python3 - < /tmp/ed16.py
docker exec sn-fortran-solver-parity bash -lc 'cd /w/new; gfortran -O2 -o hydro *.f; for f in /app/examples/*.dat; do ./hydro < $f > /tmp/o.txt; /app/prod/hydro < $f > /tmp/p.txt 2>/dev/null; diff /tmp/o.txt /tmp/p.txt | cat -A| head -5; done'
```

<details><summary>output</summary>

```
26c26$
< $
---$
>  $
27c27$
< $
---$
>  $
31c31$
< $
---$
>  $
```
</details>

### Step 228: Bash

```bash
cd /tmp; docker exec sn-fortran-solver-parity bash -lc 'cd /w/new; ./hydro < /app/examples/branch.dat | cat -A | sed -n 20,30p; grep -n "1130\|1140" output.f | head'
```

<details><summary>output</summary>

```
 LINK RESULTS$
 ID       TYPE  FROM     TO            FLOW  VELOCITY  HEADLOSS  FRICTION  STATUS$
 -------- ----- -------- -------- --------- --------- --------- ---------  --------$
 P1       PIPE  TANK     A             9.50     0.302     0.587   0.02098  OPEN    $
 P2       PIPE  A        B             3.00     0.170     0.148   0.02523  OPEN    $
 P3       PIPE  A        C             2.00     0.255     0.382   0.02567  OPEN    $
$
 TOTAL DEMAND :      9.50 L/S$
 TOTAL SUPPLY :      9.50 L/S$
$
 RUN COMPLETED WITH   0 WARNING(S)$
179:         WRITE (6,1130) TDEM/FQ, 'L/S'
180:         WRITE (6,1140) TSUP/FQ, 'L/S'
182:         WRITE (6,1130) TDEM/FQ, 'GPM'
183:         WRITE (6,1140) TSUP/FQ, 'GPM'
206: 1130 FORMAT (/1X,'TOTAL DEMAND :',F10.2,1X,A3)
207: 1140 FORMAT (1X,'TOTAL SUPPLY :',F10.2,1X,A3)
```
</details>

### Step 229: Bash

```bash
cd /tmp; cat > /tmp/ed17.py <<'PYEOF'
s=open("/w/new/main.f").read()
s=s.replace(" 1010 FORMAT (1X/1X,'RUN COMPLETED WITH ',I3,' WARNING(S)')"," 1010 FORMAT (1X,'RUN COMPLETED WITH ',I3,' WARNING(S)')")
s=s.replace("      WRITE (6,1010) NWARN","      WRITE (6,'(A)') ' '\n      WRITE (6,1010) NWARN")
open("/w/new/main.f","w").write(s)
o=open("/w/new/output.f").read()
o=o.replace(" 1130 FORMAT (/1X,'TOTAL DEMAND :',F10.2,1X,A3)"," 1130 FORMAT (1X,'TOTAL DEMAND :',F10.2,1X,A3)")
o=o.replace("      IF (IUNIT .EQ. 1) THEN\n         WRITE (6,1130) TDEM/FQ, 'L/S'","      WRITE (6,'(A)') ' '\n      IF (IUNIT .EQ. 1) THEN\n         WRITE (6,1130) TDEM/FQ, 'L/S'")
open("/w/new/output.f","w").write(o)
PYEOF
docker exec -i sn-fortran-solver-parity python3 - < /tmp/ed17.py
docker exec sn-fortran-solver-parity bash -lc 'cd /w/new; gfortran -O2 -o hydro *.f; for f in /app/examples/*.dat; do ./hydro < $f > /tmp/o.txt; /app/prod/hydro < $f > /tmp/p.txt 2>/dev/null; diff /tmp/o.txt /tmp/p.txt | cat -A| head -5; done; echo done'
```

<details><summary>output</summary>

```
29c29$
<  $
---$
> $
30c30$
<  $
---$
> $
34c34$
<  $
---$
> $
done
```
</details>

### Step 230: Bash

```bash
cd /tmp; cat > /tmp/ed18.py <<'PYEOF'
s=open("/w/new/main.f").read()
s=s.replace("      WRITE (6,'(A)') ' '\n      WRITE (6,1010) NWARN","      WRITE (6,1010) NWARN")
s=s.replace(" 1010 FORMAT (1X,'RUN COMPLETED WITH ',I3,' WARNING(S)')"," 1010 FORMAT (/1X,'RUN COMPLETED WITH ',I3,' WARNING(S)')")
open("/w/new/main.f","w").write(s)
PYEOF
docker exec -i sn-fortran-solver-parity python3 - < /tmp/ed18.py
docker exec sn-fortran-solver-parity bash -lc 'cd /w/new; gfortran -O2 -o hydro *.f; for f in /app/examples/*.dat; do ./hydro < $f > /tmp/o.txt; /app/prod/hydro < $f > /tmp/p.txt 2>/dev/null; diff /tmp/o.txt /tmp/p.txt | cat -A| head -5; done; echo done'
```

<details><summary>output</summary>

```
done
```
</details>

### Step 231: Bash

```bash
cd /tmp; docker exec sn-fortran-solver-parity bash -lc 'cd /w; sed -i "s#MINE=\"/w/build/hydro\"#MINE=\"/w/new/hydro\"#" cmp.py; python3 - <<EOF
import sys,re,collections
sys.path.insert(0,"/w")
from cmp import run,PROD,MINE
from gen import gen
from gen2 import mutate
from gen3 import gen3
from gen4 import gen4
c=collections.Counter()
ex=[]
for s in range(0,150):
    for d in (gen(s),mutate(gen(s),s),gen3(s),gen4(s)):
        p=run(PROD,d)[0].split("\n"); m=run(MINE,d)[0].split("\n")
        if len(p)!=len(m): continue
        for a,b in zip(p,m):
            if a!=b and a.rstrip()==b.rstrip(): c[(a[-3:],b[-3:])]+=1; ex.append((a,b))
print(c.most_common(5), ex[:3])
EOF'
```

<details><summary>output</summary>

```
[] []
```
</details>

### Step 232: Bash

```bash
cd /tmp; docker exec sn-fortran-solver-parity bash -lc 'cd /w; cp new/*.f new/hydro.inc /app/src/; rm -rf chk && mkdir chk && cp new/* chk/ && cd chk && rm -f hydro && gfortran -O0 -g -Wall -fcheck=all -ffpe-trap=invalid,zero -o hydro *.f 2>&1 | grep -v "^$" | head -30; ls'
```

<details><summary>output</summary>

```
cards.f:402:72:
  402 |       NID(NN) = FIELD(2)
      |                                                                        1
Warning: CHARACTER expression will be truncated in assignment (8/40) at (1) [-Wcharacter-truncation]
cards.f:408:72:
  408 |       IF (NFLD .GE. 5) NPNAM(NN) = FIELD(5)
      |                                                                        1
Warning: CHARACTER expression will be truncated in assignment (8/40) at (1) [-Wcharacter-truncation]
cards.f:429:72:
  429 |       NID(NN) = FIELD(2)
      |                                                                        1
Warning: CHARACTER expression will be truncated in assignment (8/40) at (1) [-Wcharacter-truncation]
cards.f:467:72:
  467 |       LID(L) = FIELD(2)
      |                                                                        1
Warning: CHARACTER expression will be truncated in assignment (8/40) at (1) [-Wcharacter-truncation]
cards.f:640:72:
  640 |          PNAM(K) = FIELD(2)
      |                                                                        1
Warning: CHARACTER expression will be truncated in assignment (8/40) at (1) [-Wcharacter-truncation]
output.f:59:53:
   59 |       DOUBLE PRECISION FQ, FL, FP, A, V, HL, PRS, DEM, TDEM, TSUP
      |                                                     1
Warning: Unused variable ‘dem’ declared at (1) [-Wunused-variable]
output.f:59:33:
   59 |       DOUBLE PRECISION FQ, FL, FP, A, V, HL, PRS, DEM, TDEM, TSUP
      |                                 1
Warning: Unused variable ‘fp’ declared at (1) [-Wunused-variable]
output.f:60:38:
   60 |       DOUBLE PRECISION QNET(MXN), HOUT, T
cards.f
check.f
frict.f
hydro
hydro.inc
main.f
output.f
solve.f
```
</details>

### Step 233: Bash

```bash
cd /tmp; docker exec sn-fortran-solver-parity bash -lc 'cd /w; python3 - <<EOF
import sys
sys.path.insert(0,"/w")
from cmp import run
from gen import gen
from gen2 import mutate
from gen3 import gen3
from gen4 import gen4
bad=0
for s in range(0,250):
    for d in (gen(s),mutate(gen(s),s),gen3(s),gen4(s)):
        r=__import__("subprocess").run(["/w/chk/hydro"],input=d,capture_output=True,text=True)
        if "Fortran runtime error" in r.stderr or "forrtl" in r.stderr or "Program received signal" in r.stderr or "Floating" in r.stderr:
            bad+=1; print(r.stderr[:300]); break
print("runtime issues",bad)
EOF'
```

<details><summary>output</summary>

```
runtime issues 0
```
</details>

### Step 234: Bash

```bash
cd /tmp; docker exec sn-fortran-solver-parity bash -lc 'cd /w; cmp -s new/solve.f /app/src/solve.f && echo solve-same; cp new/*.f new/hydro.inc /app/src/; diff -r new /app/src | grep -v "Only in new" ; python3 gen.py 0 300 | tail -1; python3 gen2.py 0 300 | tail -1; python3 gen3.py 0 500 | tail -1; python3 gen4.py 0 800 | tail -1; python3 probes.py | tail -1; ls /app/src'
```

<details><summary>output</summary>

```
solve-same
Only in /app/src: LICENSE
bad 2 of 300
bad 2 of 300
bad 0 of 500
bad 0 of 800
bad 0 of 240
LICENSE
cards.f
check.f
frict.f
hydro.inc
main.f
output.f
solve.f
```
</details>

### Step 235: SubagentHandback

```bash
{"message": "I rewrote the source in /app/src so it builds with `gfortran -O2 -o hydro *.f` and reproduces production 2.3 on the great majority of decks I tried. It does not match every deck, so the \"all hidden decks must match\" bar is probably not fully met.\n\n**What changed**\n- The old 1.8 source did not compile on gfortran 12 at all. I replaced it with new `main.f`, `cards.f`, `check.f`, `solve.f`, `frict.f`, `output.f` and `hydro.inc`, and deleted `hcross.f` (Hardy Cross is retired in 2.3). `LICENSE` is kept.\n- No forbidden constructs are used.\n- Behaviour was reverse-engineered by running `/app/prod/hydro` on probe decks, not taken from the docs.\n\n**Test results** (my own comparator, using the task's tolerance rules, against the real prod binary)\n- Probe decks for parsing, errors, warnings and options: 240 of 240 match.\n- About 3,000 tiny random card decks, including 1,300 built from a fixed valid base deck plus random cards: all match.\n- About 1,000 random full networks (units, friction laws, pumps, valves, patterns, time steps, tolerances) plus mutated versions: about 1–2% differ.\n- The three example decks match byte-for-byte.\n\n**Known mismatches (about 1–2% of random decks)**\n- They are almost all decks where flows end up near zero or the system is ill-conditioned: K=0 valves in parallel with a pipe, zero-demand loops, pumps whose flow equals qmax exactly, absurdly scaled US decks.\n- The difference is either the iteration count or the sign of a zero (`-0.00` vs `0.00`).\n- A hidden deck with a zero-flow loop or a K=0 valve could well fail. I could not find production's exact arithmetic for these cases.\n\n**What I matched, for orientation**\n- Cards, comments, case rules, the 80-column cut, 8-character IDs and capacity limits (100 nodes, 150 links, 12 patterns, 24 pattern values, 24 steps).\n- All error and warning codes, their ordering, and the exit codes: 0 normal, 1 for input errors or E303, 2 if any step does not converge.\n- Report formats, node/link ordering and the overflow behaviour.\n- Physics:\n  - Unit conversions: both systems are solved in SI internally.\n  - Friction: Swamee-Jain with a linear blend between Reynolds numbers 2000 and 4000, a laminar linear loss below 2000, and Hazen-Williams.\n  - Pumps and valves: pump curves, valves, minor losses and closed links.\n  - Convergence: the test is relative flow change, sum|dQ|/sum|Q|.\n\n**Confidence**\n- Parsing, validation, formatting and ordinary hydraulics: high.\n- Pathological numerics: moderate to low.\n\nAll files are in `/app/src`."}
```

<details><summary>output</summary>

```
{"success":true,"message":"Report delivered to your caller."}
```
</details>

