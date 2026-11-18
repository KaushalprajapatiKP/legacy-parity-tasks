C     ==================================================================
C     HYDRO 2.3  -  INPUT DECK READER
C     ==================================================================
C
      SUBROUTINE READIN
      INCLUDE 'hydro.inc'
      CHARACTER*80 LINE
      CHARACTER*16 KW
      INTEGER IOS, LNB
   10 CONTINUE
      READ (5,'(A)',IOSTAT=IOS) LINE
      IF (IOS .NE. 0) GOTO 90
      LINENO = LINENO + 1
      IF (LINE(1:1) .EQ. '*') GOTO 10
      CALL DETAB(LINE)
      CALL STRIPC(LINE)
      CARD = LINE
      CALL TOKENS(LINE)
      IF (NTOK .EQ. 0) GOTO 10
      KW = TOK(1)
      CALL UPCASE(KW)
      IF (KW .EQ. 'END') THEN
         ENDSEN = .TRUE.
         GOTO 99
      ELSE IF (KW .EQ. 'TITLE') THEN
         IF (NTOK .GE. 2) THEN
            TITLE = CARD(TPOS(2):)
         ELSE
            TITLE = ' '
         ENDIF
      ELSE IF (KW .EQ. 'UNITS') THEN
         CALL CUNITS
      ELSE IF (KW .EQ. 'OPTION') THEN
         CALL COPT
      ELSE IF (KW .EQ. 'JUNCTION') THEN
         CALL CJUNC
      ELSE IF (KW .EQ. 'RESERVOIR') THEN
         CALL CRES
      ELSE IF (KW .EQ. 'PIPE') THEN
         CALL CLINK(1)
      ELSE IF (KW .EQ. 'PUMP') THEN
         CALL CLINK(2)
      ELSE IF (KW .EQ. 'VALVE') THEN
         CALL CLINK(3)
      ELSE IF (KW .EQ. 'PATTERN') THEN
         CALL CPATT
      ELSE
         CALL ERRMSG('E101', LINENO,
     &      'UNKNOWN CARD '''//KW(1:LNB(KW))//'''')
      ENDIF
      GOTO 10
   90 CONTINUE
      CALL WARNMS('W208', 0, 'END CARD MISSING')
   99 RETURN
      END
C
C     EXTRA  -  W209 WHEN A CARD CARRIES MORE FIELDS THAN IT USES
C
      SUBROUTINE EXTRA(NMAX)
      INCLUDE 'hydro.inc'
      INTEGER NMAX
      IF (NTOK .GT. NMAX)
     &   CALL WARNMS('W209', LINENO, 'EXTRA FIELDS IGNORED')
      RETURN
      END
C
C     UNITS SI|US
C
      SUBROUTINE CUNITS
      INCLUDE 'hydro.inc'
      CHARACTER*40 V
      INTEGER LNB
      IF (NTOK .LT. 2) THEN
         CALL ERRMSG('E105', LINENO, 'MISSING FIELD(S)')
         RETURN
      ENDIF
      V = TOK(2)
      CALL UPCASE(V)
      IF (V .EQ. 'SI') THEN
         IUNIT = 1
      ELSE IF (V .EQ. 'US') THEN
         IUNIT = 2
      ELSE
         CALL ERRMSG('E108', LINENO,
     &      'INVALID OPTION VALUE '''//TOK(2)(1:LNB(TOK(2)))//'''')
         RETURN
      ENDIF
      CALL EXTRA(2)
      RETURN
      END
C
C     OPTION NAME VALUE
C
      SUBROUTINE COPT
      INCLUDE 'hydro.inc'
      CHARACTER*40 NM, V
      DOUBLE PRECISION X
      INTEGER LNB
      LOGICAL GETNUM
      IF (NTOK .LT. 3) THEN
         CALL ERRMSG('E105', LINENO, 'MISSING FIELD(S)')
         RETURN
      ENDIF
      NM = TOK(2)
      CALL UPCASE(NM)
      V = TOK(3)
      CALL UPCASE(V)
      IF (NM .EQ. 'TOL') THEN
         IF (.NOT. GETNUM(3, X)) RETURN
         IF (X .LE. 0D0) GOTO 80
         TOL = X
      ELSE IF (NM .EQ. 'MAXIT') THEN
         IF (.NOT. GETNUM(3, X)) RETURN
         IF (X .LT. 1D0 .OR. X .NE. AINT(X)) GOTO 80
         IF (X .GT. 200D0) THEN
            MAXIT = 200
            CALL WARNMS('W206', LINENO, 'MAXIT LIMITED TO 200')
         ELSE
            MAXIT = INT(X)
         ENDIF
      ELSE IF (NM .EQ. 'FRICTION') THEN
         IF (V .EQ. 'DW') THEN
            IFRIC = 1
         ELSE IF (V .EQ. 'HW') THEN
            IFRIC = 2
         ELSE
            GOTO 80
         ENDIF
      ELSE IF (NM .EQ. 'STEPS') THEN
         IF (.NOT. GETNUM(3, X)) RETURN
         IF (X .LT. 1D0 .OR. X .GT. 24D0 .OR. X .NE. AINT(X)) GOTO 80
         NSTEP = INT(X)
      ELSE IF (NM .EQ. 'HSTEP') THEN
         IF (.NOT. GETNUM(3, X)) RETURN
         IF (X .LE. 0D0 .OR. X .GT. 24D0) GOTO 80
         HSTEP = X
      ELSE
         CALL ERRMSG('E109', LINENO,
     &      'UNKNOWN OPTION '''//NM(1:LNB(NM))//'''')
         RETURN
      ENDIF
      CALL EXTRA(3)
      RETURN
   80 CALL ERRMSG('E108', LINENO,
     &   'INVALID OPTION VALUE '''//TOK(3)(1:LNB(TOK(3)))//'''')
      RETURN
      END
C
C     JUNCTION ID ELEV [DEMAND [PATTERN]]
C
      SUBROUTINE CJUNC
      INCLUDE 'hydro.inc'
      DOUBLE PRECISION E, D
      INTEGER IFINDN, LNB
      LOGICAL GETNUM, OKID
      IF (NTOK .LT. 3) THEN
         CALL ERRMSG('E105', LINENO, 'MISSING FIELD(S)')
         RETURN
      ENDIF
      IF (.NOT. OKID(TOK(2))) RETURN
      IF (NTOK .GE. 5) THEN
         IF (.NOT. OKID(TOK(5))) RETURN
      ENDIF
      IF (IFINDN(TOK(2)) .GT. 0) THEN
         CALL ERRMSG('E102', LINENO,
     &      'DUPLICATE ID '''//TOK(2)(1:LNB(TOK(2)))//'''')
         RETURN
      ENDIF
      IF (NNODE .GE. MAXN) THEN
         CALL ERRMSG('E111', LINENO, 'TOO MANY NODES')
         RETURN
      ENDIF
      IF (.NOT. GETNUM(3, E)) RETURN
      D = 0D0
      IF (NTOK .GE. 4) THEN
         IF (.NOT. GETNUM(4, D)) RETURN
      ENDIF
      NNODE = NNODE + 1
      NID(NNODE)  = TOK(2)
      NTYP(NNODE) = 1
      ELEV(NNODE) = E
      BDEM(NNODE) = D
      NLIN(NNODE) = LINENO
      NPID(NNODE) = ' '
      IF (NTOK .GE. 5) NPID(NNODE) = TOK(5)
      CALL EXTRA(5)
      RETURN
      END
C
C     RESERVOIR ID HEAD
C
      SUBROUTINE CRES
      INCLUDE 'hydro.inc'
      DOUBLE PRECISION H
      INTEGER IFINDN, LNB
      LOGICAL GETNUM, OKID
      IF (NTOK .LT. 3) THEN
         CALL ERRMSG('E105', LINENO, 'MISSING FIELD(S)')
         RETURN
      ENDIF
      IF (.NOT. OKID(TOK(2))) RETURN
      IF (IFINDN(TOK(2)) .GT. 0) THEN
         CALL ERRMSG('E102', LINENO,
     &      'DUPLICATE ID '''//TOK(2)(1:LNB(TOK(2)))//'''')
         RETURN
      ENDIF
      IF (NNODE .GE. MAXN) THEN
         CALL ERRMSG('E111', LINENO, 'TOO MANY NODES')
         RETURN
      ENDIF
      IF (.NOT. GETNUM(3, H)) RETURN
      NNODE = NNODE + 1
      NRES  = NRES + 1
      NID(NNODE)  = TOK(2)
      NTYP(NNODE) = 2
      ELEV(NNODE) = H
      BDEM(NNODE) = 0D0
      NLIN(NNODE) = LINENO
      NPID(NNODE) = ' '
      CALL EXTRA(3)
      RETURN
      END
C
C     PIPE  ID N1 N2 LENGTH DIAM ROUGH [K]
C     PUMP  ID N1 N2 H0 [QMAX]
C     VALVE ID N1 N2 DIAM K [OPEN|CLOSED]
C
      SUBROUTINE CLINK(ITYP)
      INCLUDE 'hydro.inc'
      INTEGER ITYP
      INTEGER NMIN(3), NMAX(3), I, NV, IST, IFINDL, LNB
      DOUBLE PRECISION V(4)
      CHARACTER*40 S
      LOGICAL GETNUM, OKID, BAD
      DATA NMIN /7, 5, 6/
      DATA NMAX /8, 6, 7/
      IF (NTOK .LT. NMIN(ITYP)) THEN
         CALL ERRMSG('E105', LINENO, 'MISSING FIELD(S)')
         RETURN
      ENDIF
      IF (.NOT. OKID(TOK(2))) RETURN
      IF (.NOT. OKID(TOK(3))) RETURN
      IF (.NOT. OKID(TOK(4))) RETURN
      IF (IFINDL(TOK(2)) .GT. 0) THEN
         CALL ERRMSG('E102', LINENO,
     &      'DUPLICATE ID '''//TOK(2)(1:LNB(TOK(2)))//'''')
         RETURN
      ENDIF
      IF (NLINK .GE. MAXL) THEN
         CALL ERRMSG('E111', LINENO, 'TOO MANY LINKS')
         RETURN
      ENDIF
      IF (TOK(3) .EQ. TOK(4)) THEN
         CALL ERRMSG('E110', LINENO, 'LINK CONNECTS NODE TO ITSELF')
         RETURN
      ENDIF
C     NUMERIC FIELDS
      NV = NMIN(ITYP) - 4
      IF (ITYP .EQ. 1 .AND. NTOK .GE. 8) NV = 4
      IF (ITYP .EQ. 2 .AND. NTOK .GE. 6) NV = 2
      V(1) = 0D0
      V(2) = 0D0
      V(3) = 0D0
      V(4) = 0D0
      DO 10 I = 1, NV
         IF (.NOT. GETNUM(4+I, V(I))) RETURN
   10 CONTINUE
      IST = 1
      IF (ITYP .EQ. 3 .AND. NTOK .GE. 7) THEN
         S = TOK(7)
         CALL UPCASE(S)
         IF (S .EQ. 'OPEN') THEN
            IST = 1
         ELSE IF (S .EQ. 'CLOSED') THEN
            IST = 0
         ELSE
            CALL ERRMSG('E108', LINENO,
     &         'INVALID OPTION VALUE '''//TOK(7)(1:LNB(TOK(7)))//'''')
            RETURN
         ENDIF
      ENDIF
C     RANGES
      BAD = .FALSE.
      IF (ITYP .EQ. 1) THEN
         IF (V(1) .LE. 0D0 .OR. V(2) .LE. 0D0) BAD = .TRUE.
         IF (V(3) .LT. 0D0 .OR. V(4) .LT. 0D0) BAD = .TRUE.
      ELSE IF (ITYP .EQ. 2) THEN
         IF (V(1) .LE. 0D0) BAD = .TRUE.
         IF (NV .EQ. 2 .AND. V(2) .LE. 0D0) BAD = .TRUE.
      ELSE
         IF (V(1) .LE. 0D0 .OR. V(2) .LT. 0D0) BAD = .TRUE.
      ENDIF
      IF (BAD) THEN
         CALL ERRMSG('E107', LINENO, 'VALUE OUT OF RANGE')
         RETURN
      ENDIF
      NLINK = NLINK + 1
      LID(NLINK)  = TOK(2)
      LNM1(NLINK) = TOK(3)
      LNM2(NLINK) = TOK(4)
      LTYP(NLINK) = ITYP
      LSTA(NLINK) = IST
      LLIN(NLINK) = LINENO
      LLEN(NLINK) = 0D0
      LDIA(NLINK) = 0D0
      LRGH(NLINK) = 0D0
      LKM(NLINK)  = 0D0
      PH0(NLINK)  = 0D0
      PQM(NLINK)  = 0D0
      FF(NLINK)   = 0D0
      IF (ITYP .EQ. 1) THEN
         LLEN(NLINK) = V(1)
         LDIA(NLINK) = V(2)
         LRGH(NLINK) = V(3)
         LKM(NLINK)  = V(4)
      ELSE IF (ITYP .EQ. 2) THEN
         PH0(NLINK) = V(1)
         PQM(NLINK) = V(2)
      ELSE
         LDIA(NLINK) = V(1)
         LKM(NLINK)  = V(2)
      ENDIF
      CALL EXTRA(NMAX(ITYP))
      RETURN
      END
C
C     PATTERN ID M1 [M2 ...]   (REPEATED CARDS EXTEND THE PATTERN)
C
      SUBROUTINE CPATT
      INCLUDE 'hydro.inc'
      DOUBLE PRECISION V(MAXT)
      INTEGER I, N, IP, IFINDP
      LOGICAL GETNUM, OKID
      IF (NTOK .LT. 3) THEN
         CALL ERRMSG('E105', LINENO, 'MISSING FIELD(S)')
         RETURN
      ENDIF
      IF (.NOT. OKID(TOK(2))) RETURN
      N = NTOK - 2
      DO 10 I = 1, N
         IF (.NOT. GETNUM(I+2, V(I))) RETURN
         IF (V(I) .LT. 0D0) THEN
            CALL ERRMSG('E107', LINENO, 'VALUE OUT OF RANGE')
            RETURN
         ENDIF
   10 CONTINUE
      IP = IFINDP(TOK(2))
      IF (IP .EQ. 0) THEN
         IF (NPATT .GE. MAXP) THEN
            CALL ERRMSG('E111', LINENO, 'TOO MANY PATTERNS')
            RETURN
         ENDIF
         NPATT = NPATT + 1
         IP = NPATT
         PID(IP) = TOK(2)
         PLEN(IP) = 0
      ENDIF
      IF (PLEN(IP) + N .GT. MAXM) THEN
         CALL ERRMSG('E113', LINENO, 'PATTERN TOO LONG')
         RETURN
      ENDIF
      DO 20 I = 1, N
         PMUL(PLEN(IP)+I, IP) = V(I)
   20 CONTINUE
      PLEN(IP) = PLEN(IP) + N
      RETURN
      END
