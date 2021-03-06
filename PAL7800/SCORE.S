*         1820    040784
*
*
** SCORE.S **
** ASTEROIDS FOR THE ATARI 3600 **
** THIS FILE CONTAINS PLAYER POINT TOTALLER AND SCORE DRIVER. **
** HANDLES PLAYER1 AND PLAYER2 SCORES **
**         EXTRA SHIPS AND HIGH SCORE **
**         COMBINED SCORE AND COMBINED EXTRA SHIPS **

** TRASHES ACC, TEMP+12, TEMP+13, TEMP+14, AND TEMP+15 **
** USES TEMP+12 AS COMPARE VALUE = 4 FOR SCORER 0 AND 8 FOR SCORER 1 **
** USES TEMP+15 FOR POINTER INTO CHARACTER MAP, NEXT POSITION FOR CHARACTER **
** SAVES X AND Y IN TEMP+13 AND TEMP+14 **

** PLAYER ONE     SET SCORER TO 0   **
**                SCORE THRU SCORE+3     CURRENT SCORE **
**                MENLEFT                NUMBER OF SHIPS REMAINING **
**                                       ONLY MAXIMUM OF 3 ARE SHOWN **
**                SCORMAP1               PLAYER1 SCORE CHARACTER MAP **

** PLAYER TWO     SET SCORER TO 1   **
**                SCORE2 THRU SCORE2+3   CURRENT SCORE **
**                MENLEFT2               NUMBER OF SHIPS REMAINING **
**                SCORMAP2               PLAYER2 SCORE CHARACTER MAP **

** HIGHSCORE      HISCORE                CURRENT HIGH SCORE **
**                SCORCMHS               HISCORE CHARACTER MAP **

** COMBINED SCORE COMBSCOR               COMBINED PLAYER 1 AND PLAYER 2 SCORES
**	      SCORECMC	     COMBINED SCORE CHARACTER MAP **

ADDPOINT:
	LDA	GAMSTATE	;ONLY SCORE DURING GAME PLAY STATE
	CMP	#PLAYST
	BNE	ADDRTS
	JSR	ADDSCORE	;SCORE THE SCORER
	LDA	MODE		;IN TEAMPLAY, SCORE THE TEAM
	CMP	#1
	BNE	ADDRTS
	LDA	#2		;2 = TEAM ENTITY
	STA	SCORER
	JSR	ADDSCORE
ADDRTS:
	RTS

ADDSCORE:
	STX	TEMP+13		;SAVE REGISTERS
	STY	TEMP+14

	;EACH TIME SOMEONE SCORES, RESET UFOTIMER
;	    LDA	#0
;	    STA	UFOTIMER	;INCREMENTED ONLY WHILE "LURKING"

	LDA	SCORER	;CALCULATE OFFSET INTO SCORE
	ASL
	ASL
	TAY

	SED			;DO ARITHMETIC IN DECIMAL MODE
	CLC
	LDA	LOSCOTAB,X	;GET OBJECT SCORE VALUE
	ADC	SCORE+3,Y	;ADD LOWEST BYTE
	STA	SCORE+3,Y
	LDA	HISCOTAB,X
	ADC	SCORE+2,Y	;ADD NEXT BYTE WITH CARRY
	STA	SCORE+2,Y
	BCC	NOADD		;EVERY 10000 POINTS GET ADDITIONAL MAN

	LDA	MODE	;DON'T DO FOR TEAM PLAY INDIV SCORES
	CMP	#1
	BNE	DOINCM
	LDA	SCORER
	CMP	#2
	BNE	TEAMCK

DOINCM:
	CLD

	LDA	#0		;TYPE 0 = POINTS INCREMENT
	JSR	INCLVL

	LDX	SCORER
	INC	MENLEFT,X
	JSR	PUTMEN		;PUT UP EXTRA MAN
	LDA	#4		;EXTRA SHIP FANFARE
	JSR	DOTUNE

	LDA	SCORER
	ASL
	ASL
	TAY
TEAMCK:
	SEC
NOADD:
	LDA	#0
	SED
	ADC	SCORE+1,Y	;ADD NEXT BYTE WITH CARRY
	STA	SCORE+1,Y
	LDA	#0
	ADC	SCORE,Y		;ADD HIGHEST BYTE WITH CARRY
	STA	SCORE,Y
	CLD			;RETURN FROM DECIMAL MODE
	JSR	PUTSCRNS

DONESCOR:
	LDX	TEMP+13		;DONE RESTORE REGISTERS
	LDY	TEMP+14
	RTS

** PUTSCORE, ROUTINE TO PUT SCORE INTO PLAYERS CHARACTER MAP **

PUTSCORE:
	STX	TEMP+13		;SAVE REGISTERS
	STY	TEMP+14
PUTSCRNS:
	LDA	SCORER		;CALCULATE OFFSET 0 OR 4
	ASL
	ASL
	TAX			;PUT IN X
	ASL			;CALCULATE OFFSET 0 OR 16
	ASL
	STA	TEMP+15		;PUT INTO TEMP+15
	TXA
	CLC			;COMPARE VALUE FOR TERMINATION
	ADC	#4
	STA	TEMP+12
SCORLOOP:
	LDA	SCORE,X		;GET NEXT BYTE OF SCORE
	LSR
	LSR
	LSR
	LSR			;GET HIGH NYBBLE
	BNE	PUTHINUM	;IF NOT ZERO PUT NUMBER FROM HI NYBBLE
	JSR	PUTBLANK	;IF ZERO PUT IN BLANK
	LDA	SCORE,X
	AND	#$F		;GET LO NYBBLE
	BNE	PUTLONUM	;IF NOT ZERO PUT NUMBER FROM LO NYBBLE
	JSR	PUTBLANK	;IF ZERO PUT IN BLANK
	INX
	CPX	TEMP+12		;4 BYTES OF SCORE
	BMI	SCORLOOP
	LDA	#CHARS+1 & 255	;PUT UP A ZERO IF NO POINTS YET
	DEC	TEMP+15
	JSR	WRTCHAR

	RTS


** PUTNUMS, ROUTINE TO PUT NUMBERS FROM PLAYERS SCORE INTO CHARACTER MAP **
PUTNUMS:
	LDA	SCORE,X		;GET NEXT BYTE OF SCORE
	LSR
	LSR
	LSR
	LSR			;GET HI NYBBLE

** PUTHINUM, ROUTINE TO PUT HIGH BYTE NUMBERS INTO CHARACTER MAP **
PUTHINUM:
	CLC			;POINT TO NUMBER IN CHARS
	ADC	#(CHARS+1) & 255
	JSR	WRTCHAR		;WRITE CHAR IN CHARACTER MAP
	LDA	SCORE,X		;GET NEXT, ONCE A NUMBER IS FOUND,
;				; NEVER WORRY ABOUT FINDING A BLANK.
	AND	#$F		;GET LO NYBBLE

** PUTLONUM, ROUTINE TO PUT LOW BYTE NUMBERS INTO CHARACTER MAP **
PUTLONUM:
	CLC			;POINT TO NUMBER IN CHARS
	ADC	#(CHARS+1) & 255
	JSR	WRTCHAR		;WRITE CHAR IN CHARACTER MAP
	INX
	CPX	TEMP+12		;4 BYTE OF SCORE DATA
	BMI	PUTNUMS
	RTS

** PUTBLANK, ROUTINE TO PUT A BLANK SPACE INTO NEXT POS IN CMAP1 **
PUTBLANK:
	LDA	#(CHARS) & 255	;FIRST CHARACTER IN CHARS IS A BLANK

** WRTCHAR, ROUTINE TO WRITE A CHARACTER INTO NEXT POS IN CMAP1 **
**	   ACC MUST BE LOW BYTE OF CHARACTER. **
WRTCHAR:
	LDY	TEMP+15		;POSITION
	STA	CHARMAPS,Y	;PUT CHAR IN CHARACTER MAP
	INC	TEMP+15
	RTS

** PUTMEN, ROUTINE TO PUT PLAYERS MENLEFT INTO CHARACTER MAPS. **

PUTMEN:
	LDX	SCORER		;WHICH SCORER
	TXA
	ASL			;COMPUTE INDICES AND POINTERS
	ASL
	ASL
	ASL
	CLC
	ADC	#8
	TAY
	LDA	#CHARS & 255	;PAD WITH BLANK, ONE FOR SPACE
	STA	CHARMAPS,Y
	INY
	STY	TEMP+15
	STA	CHARMAPS,Y
	INY
	STA	CHARMAPS,Y
	INY
	STA	CHARMAPS,Y
	INY
	STA	CHARMAPS,Y
	LDX	SCORER
	LDA	MENLEFT,X	;PUT UP ONE SHIP FOR EACH MAN LEFT
	BEQ	DONEPUTM
	CMP	#5		;DISPLAY ONLY 4 SHIPS MAXIMUM
	BCC	PUTMENUP
	LDA	#4
PUTMENUP:
	TAX
PUTMENLP:
	LDA	#(CHARS+11) & 255	;POINT TO SMALL SHIP SYMBOL
	JSR	WRTCHAR			;PUT IT IN CMAP1
	DEX
	BNE	PUTMENLP		;CONTINUE UNTIL MENLEFT IS ZERO
DONEPUTM:
	RTS

** HIGH SCORE ROUTINES. **
PUTHISCR:
	LDX	#0
	STX	TEMP+15	;START AT BEGINNING AND REMOVE ZEROS.
HISCRLP:
	LDA	HISCORE,X	;GET NEXT BYTE OF SCORE
	LSR
	LSR
	LSR
	LSR			;GET HIGH NYBBLE
	BNE	PUTHNUMH	;IF NOT ZERO PUT NUMBER FROM HI NYBBLE
	JSR	PUTBLKHS	;IF ZERO PUT IN BLANK
	LDA	HISCORE,X
	AND	#$F		;GET LO NYBBLE
	BNE	PUTLNUMH	;IF NOT ZERO PUT NUMBER FROM LO NYBBLE
	JSR	PUTBLKHS	;IF ZERO PUT IN BLANK
	INX
	CPX	#4		;4 BYTES OF SCORE
	BMI	HISCRLP
	JMP	DONEHSCR	;DONE WITH HIGH SCORE


PUTHSNUM:
	LDA	HISCORE,X	;GET NEXT BYTE OF SCORE
	LSR
	LSR
	LSR
	LSR			;GET HI NYBBLE

PUTHNUMH:
	CLC			;POINT TO NUMBER IN CHARS
	ADC	#(CHARS+12) & 255
	JSR	WRTCHRHS	;WRITE CHAR IN CHARACTER MAP
	LDA	HISCORE,X	;GET NEXT, ONCE A NUMBER IS FOUND,
;				; NEVER WORRY ABOUT FINDING A BLANK.
	AND	#$F		;GET LO NYBBLE

PUTLNUMH:
	CLC			;POINT TO NUMBER IN CHARS
	ADC	#(CHARS+12) & 255
	JSR	WRTCHRHS	;WRITE CHAR IN CHARACTER MAP
	INX
	CPX	#4		;4 BYTE OF SCORE DATA
	BMI	PUTHSNUM

DONEHSCR:
	RTS

PUTBLKHS:
	LDA	#CHARS & 255	;FIRST CHARACTER IN CHARS IS A BLANK

WRTCHRHS:
	LDY	TEMP+15		;POSITION
	STA	SCORCMHS,Y	;PUT CHAR IN CHARACTER MAP
	INC	TEMP+15
	RTS


** HIGHSCORE HANDLING ROUTINE TO CHECK FOR NEW HIGHSCORE. **

HIGHSCOR:
	LDY	#0		;0 = PLAYER 1 SCORE
	LDA	MODE
	BMI	HSONE		;ONE PLAYER ONLY
	LDY	#8		;8 = COMBINED SCORE
	CMP	#1		;MODE 1 WE USE COMBINED SCORE
	BEQ	HSONE		; AND AS ONE PLAYER ONLY
	LDY	#0		;CHECK BOTH PLAYERS
	JSR	CKHISCOR
	LDY	#4		;4 = PLAYER 2 SCORE
HSONE:
	JSR	CKHISCOR
	JSR	PUTHISCR	;UPDATE HIGHSCORE ON SCREEN
	RTS

* CKHISCOR -- ROUTINE TO DO THE ACTUAL CHECK.  ON ENTRY, Y CONTAINS SCORE OFFSET
CKHISCOR:
	LDX	#0
HSLOOP:
	LDA	SCORE,Y
	CMP	HISCORE,X
	BCC	HSRTS		;LOWER: WE'RE DONE.
	BEQ	HSLOOPCK	;EQUAL PLACE: PROCEED TO NEXT PLACE
NEWHIGH:
	STA	HISCORE,X	;HIGHER: BEGIN REPLACING HIGH SCORE
	INY
	INX
	LDA	SCORE,Y
	CPX	#4
	BCC	NEWHIGH
	RTS

HSLOOPCK:
	INY
	INX
	CPX	#4
	BCC	HSLOOP
HSRTS:
	RTS

** ROUTINE TO UPDATE THE MENLEFT DISPLAY AFTER MENLEFT,X IS DECREMENTED. **
UPDATMEN:
	LDA	MODE		;ONE POOL OF LIVES FOR TEAM PLAY
	CMP	#1
	BNE	UPPLMEN
	LDA	#2
	STA	SCORER
	JSR	PUTMEN
	RTS

UPPLMEN:
	LDA	#0
	STA	SCORER
	JSR	PUTMEN

	LDA	MODE		;DON'T DISPLAY PLAYER2 FOR SINGLE PLAY
	BPL	UPDATPL2
	RTS

UPDATPL2:
	LDA	#1
	STA	SCORER
	JSR	PUTMEN
BYEBYE:
	RTS

** MESSAGE HANDLING ROUTINE TO FACILITATE PUTING MESSAGE ON SCREEN. **
* LOAD X WITH MESSAGE NUMBER. *
*	    MESSAGE 0		  PLAYER 1
*	    MESSAGE 1		  PLAYER 2
*	    MESSAGE 2		  GAME OVER
*	    MESSAGE 3		  WINS

SETMSG:
	LDA	GAMSTATE	;NO MESSAGES UNLESS IN GAME
	CMP	#PLAYST
	BNE	BYEBYE
	TXA			;SET UP X AND Y FOR DOICON
	CLC
	ADC	#18
	TAY
	TXA
	CMP	#2
	BCS	ZFOO
	LDX	#34
	BPL	ZMOO		;= JMP
ZFOO:
	LDX	#35
ZMOO:
	JMP	DOICON		; SAVE A BYTE


ENDSCOR:
	DS.B	0
