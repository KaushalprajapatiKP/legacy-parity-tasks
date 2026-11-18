C     ==================================================================
C     HYDRO 2.3  -  CARD SCANNING, LOOKUP AND MESSAGE UTILITIES
C     ==================================================================
C
C     TOKENS  -  SPLIT A CARD INTO BLANK-SEPARATED TOKENS
C
      SUBROUTINE TOKENS(LINE)
      INCLUDE 'hydro.inc'
      CHARACTER*(*) LINE
      INTEGER I, N, IST
      LOGICAL INTOK
      NTOK = 0
      INTOK = .FALSE.
      N = LEN(LINE)
      IST = 1
      DO 10 I = 1, N
         IF (LINE(I:I) .NE. ' ') THEN
            IF (.NOT. INTOK) THEN
               INTOK = .TRUE.
               IST = I
            ENDIF
         ELSE
            IF (INTOK) THEN
               INTOK = .FALSE.
               CALL ADDTOK(LINE, IST, I-1)
            ENDIF
         ENDIF
   10 CONTINUE
      IF (INTOK) CALL ADDTOK(LINE, IST, N)
      RETURN
      END
C
      SUBROUTINE ADDTOK(LINE, I1, I2)
      INCLUDE 'hydro.inc'
      CHARACTER*(*) LINE
      INTEGER I1, I2
      IF (NTOK .GE. MAXT) RETURN
      NTOK = NTOK + 1
      TOK(NTOK) = LINE(I1:I2)
      TPOS(NTOK) = I1
      RETURN
      END
C
C     DETAB  -  REPLACE TAB CHARACTERS BY BLANKS
C
      SUBROUTINE DETAB(LINE)
      CHARACTER*(*) LINE
      INTEGER I
      DO 10 I = 1, LEN(LINE)
         IF (ICHAR(LINE(I:I)) .EQ. 9) LINE(I:I) = ' '
   10 CONTINUE
      RETURN
      END
C
C     STRIPC  -  REMOVE AN INLINE COMMENT STARTING WITH '!'
C
      SUBROUTINE STRIPC(LINE)
      CHARACTER*(*) LINE
      INTEGER I
      I = INDEX(LINE, '!')
      IF (I .GT. 0) LINE(I:) = ' '
      RETURN
      END
C
C     UPCASE  -  FOLD A STRING TO UPPER CASE
C
      SUBROUTINE UPCASE(S)
      CHARACTER*(*) S
      INTEGER I, IC
      DO 10 I = 1, LEN(S)
         IC = ICHAR(S(I:I))
         IF (IC .GE. 97 .AND. IC .LE. 122) S(I:I) = CHAR(IC-32)
   10 CONTINUE
      RETURN
      END
C
C     LNB  -  POSITION OF THE LAST NON-BLANK CHARACTER (AT LEAST 1)
C
      INTEGER FUNCTION LNB(S)
      CHARACTER*(*) S
      INTEGER I
      DO 10 I = LEN(S), 1, -1
         IF (S(I:I) .NE. ' ') THEN
            LNB = I
            RETURN
         ENDIF
   10 CONTINUE
      LNB = 1
      RETURN
      END
C
C     ISNUM  -  TRUE IF THE TOKEN IS A DECIMAL NUMBER
C              [SIGN] DIGITS [. DIGITS] [E|D [SIGN] DIGITS]
C
      LOGICAL FUNCTION ISNUM(S)
      CHARACTER*(*) S
      INTEGER I, N, ND, NE, LNB
      CHARACTER C
      ISNUM = .FALSE.
      N = LNB(S)
      I = 1
      ND = 0
      C = S(1:1)
      IF (C .EQ. '+' .OR. C .EQ. '-') I = 2
   10 IF (I .LE. N) THEN
         IF (LGE(S(I:I),'0') .AND. LLE(S(I:I),'9')) THEN
            ND = ND + 1
            I = I + 1
            GOTO 10
         ENDIF
      ENDIF
      IF (I .LE. N) THEN
         IF (S(I:I) .EQ. '.') THEN
            I = I + 1
   20       IF (I .LE. N) THEN
               IF (LGE(S(I:I),'0') .AND. LLE(S(I:I),'9')) THEN
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
         IF (C.NE.'E' .AND. C.NE.'e' .AND. C.NE.'D' .AND. C.NE.'d')
     &      RETURN
         I = I + 1
         IF (I .LE. N) THEN
            IF (S(I:I).EQ.'+' .OR. S(I:I).EQ.'-') I = I + 1
         ENDIF
         NE = 0
   30    IF (I .LE. N) THEN
            IF (LGE(S(I:I),'0') .AND. LLE(S(I:I),'9')) THEN
               NE = NE + 1
               I = I + 1
               GOTO 30
            ENDIF
         ENDIF
         IF (NE .EQ. 0) RETURN
      ENDIF
      IF (I .LE. N) RETURN
      ISNUM = .TRUE.
      RETURN
      END
C
C     GETNUM  -  CONVERT TOKEN I TO A NUMBER, E104 IF IT IS NOT ONE
C
      LOGICAL FUNCTION GETNUM(I, X)
      INCLUDE 'hydro.inc'
      INTEGER I, LNB
      DOUBLE PRECISION X
      LOGICAL ISNUM
      GETNUM = .FALSE.
      IF (.NOT. ISNUM(TOK(I))) THEN
         CALL ERRMSG('E104', LINENO,
     &      'BAD NUMBER '''//TOK(I)(1:LNB(TOK(I)))//'''')
         RETURN
      ENDIF
      READ (TOK(I),*) X
      GETNUM = .TRUE.
      RETURN
      END
C
C     OKID  -  CHECK THE LENGTH OF AN IDENTIFIER, E106 IF TOO LONG
C
      LOGICAL FUNCTION OKID(S)
      INCLUDE 'hydro.inc'
      CHARACTER*(*) S
      INTEGER LNB
      OKID = .TRUE.
      IF (LNB(S) .GT. 8) THEN
         OKID = .FALSE.
         CALL ERRMSG('E106', LINENO,
     &      'ID TOO LONG '''//S(1:LNB(S))//'''')
      ENDIF
      RETURN
      END
C
C     ERRMSG / WARNMS  -  NUMBERED DIAGNOSTICS
C
      SUBROUTINE ERRMSG(CODE, LN, MSG)
      INCLUDE 'hydro.inc'
      CHARACTER*(*) CODE, MSG
      INTEGER LN
      NERR = NERR + 1
      IF (LN .GT. 0) THEN
         WRITE (6,900) CODE, LN, MSG
      ELSE
         WRITE (6,910) CODE, MSG
      ENDIF
      RETURN
  900 FORMAT (1X,'*** ERROR ',A4,' LINE',I4,': ',A)
  910 FORMAT (1X,'*** ERROR ',A4,': ',A)
      END
C
      SUBROUTINE WARNMS(CODE, LN, MSG)
      INCLUDE 'hydro.inc'
      CHARACTER*(*) CODE, MSG
      INTEGER LN
      NWARN = NWARN + 1
      IF (LN .GT. 0) THEN
         WRITE (6,900) CODE, LN, MSG
      ELSE
         WRITE (6,910) CODE, MSG
      ENDIF
      RETURN
  900 FORMAT (1X,'*** WARNING ',A4,' LINE',I4,': ',A)
  910 FORMAT (1X,'*** WARNING ',A4,': ',A)
      END
C
C     LOOKUPS BY IDENTIFIER (0 WHEN NOT FOUND)
C
      INTEGER FUNCTION IFINDN(S)
      INCLUDE 'hydro.inc'
      CHARACTER*(*) S
      INTEGER I
      IFINDN = 0
      DO 10 I = 1, NNODE
         IF (NID(I) .EQ. S) THEN
            IFINDN = I
            RETURN
         ENDIF
   10 CONTINUE
      RETURN
      END
C
      INTEGER FUNCTION IFINDL(S)
      INCLUDE 'hydro.inc'
      CHARACTER*(*) S
      INTEGER I
      IFINDL = 0
      DO 10 I = 1, NLINK
         IF (LID(I) .EQ. S) THEN
            IFINDL = I
            RETURN
         ENDIF
   10 CONTINUE
      RETURN
      END
C
      INTEGER FUNCTION IFINDP(S)
      INCLUDE 'hydro.inc'
      CHARACTER*(*) S
      INTEGER I
      IFINDP = 0
      DO 10 I = 1, NPATT
         IF (PID(I) .EQ. S) THEN
            IFINDP = I
            RETURN
         ENDIF
   10 CONTINUE
      RETURN
      END
