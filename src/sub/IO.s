; Keyboard/Screen IO routines

; This file is part of Color Computer RSA by Don Barber Copyright 2022

; Color Computer RSA is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

; Color Computer RSA is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along with Color Computer RSA. If not, see <https://www.gnu.org/licenses/>.

BS			EQU	8
SPACE			EQU	$20
CURPOS			EQU	$0088
VIDRAM			EQU	$0400
CASFLG			EQU	$011A
DEBVAL			EQU	$011B
PIA0			EQU	$FF00
KEYBUF			EQU	$0152

HCRSLOC			EQU	$FE00
HCURSX			EQU	$FE02
HCOLUMN			EQU	$FE04

HRWIDTH			EQU	$E7

;output C-style (trailing NUL) string
STROUT		pshs	x,d
		clr	$6F		set output devnum to 0
		lda	,x+
		cmpa	#0
		beq	stroutfinish
stroutloop	
		;anda	#32     	try to force uppercase?
		jsr	PUTCHR
		lda	,x+
		cmpa	#0		found trailing NUL, exit loop
		bne	stroutloop
stroutfinish
		puls	x,d
		rts

STROUTWRAP		pshs	u,y,x,d
			clr	$6F		set output devnum to 0
			LDA	#$FF
			STA	stroutcoco3flag
			LDD	$FFFE
			CMPD	#$8C1B
			BNE	stroutwrapnotcoco3	
			CLR	stroutcoco3flag
			LDA	#$08
			STA	$FF22
			TST	HRWIDTH
			BNE	stroutwraphr
stroutwrapnotcoco3:
			lda	,x+
			cmpa	#0
			beq	stroutwrapfinish

stroutwraploop		
			CMPA	#$60
			BNE	stroutwrapnotquote
			LDA	#$27
			BRA	stroutwrapni
stroutwrapnotquote	
			;TST	stroutcoco3flag
			;BEQ	stroutwrapni
			CMPA	#$61
			BLT	stroutwrapni
			CMPA	#$7A
			BGT	stroutwrapni
			SUBA	#$20		;make capital (not inverted)
stroutwrapni					;not inverted (anymore)

			jsr	PUTCHR

			ldd	CURPOS
			BITB	#$1F
			bne	stroutwrapnoteol
			tfr	d,y
			lda	,-y
			cmpa	#$60
			beq	stroutwrapnoteol
			ldu	#0
stroutwrapfindspace	
			lda	,-y
			leau	1,u
			;cmpa	#'L
			cmpa	#$60
			BEQ	stroutwrapfoundspace
			cmpu	#31			;didnt find space on line
			BEQ	stroutwrapnoteol
			BRA	stroutwrapfindspace
stroutwrapfoundspace
			pshs	x	
			tfr	u,x
			ldu	CURPOS
			ldb	#$60
			leay	1,y
stroutwrapcopyloop	lda	,y
			stb	,y+
			sta	,u+
			leax	-1,x
			bne	stroutwrapcopyloop
			stu	CURPOS
			puls	x

stroutwrapnoteol	lda	,x+
			cmpa	#0		found trailing NUL, exit loop
			bne	stroutwraploop
stroutwrapfinish
			puls	u,y,x,d
			rts
stroutcoco3flag		rmb	1
stroutwraphr
			;LDB	#1
			CLRB
			PSHS	X
stroutwraphrcount:
			LDA	,X+
			CMPA	#$20
			BEQ	stroutwraphrdonecount
			CMPA	#$0A
			BEQ	stroutwraphrdonecount
			CMPA	#$0D
			BEQ	stroutwraphrdonecount
			CMPA	#$00
			BEQ	stroutwraphrdonecount
			INCB
			JMP	stroutwraphrcount

stroutwraphrdonecount:	PULS	X

			CMPB	HCOLUMN
			BGE	stroutwraphroutword

			ADDB	HCURSX
			CMPB	HCOLUMN
			BLT	stroutwraphroutword
			JSR	CROUT
			JMP	stroutwraphr

stroutwraphroutword:	
			LDA	,X+
			JSR	PUTCHR	
			CMPA	#$20
			BEQ	stroutwraphr
			CMPA	#$0A
			BEQ	stroutwraphr
			CMPA	#$0D
			BEQ	stroutwraphr
			CMPA	#$0
			BEQ	stroutwrapfinish
			JMP	stroutwraphr

;just loop until key is hit
WAITKEY
		pshs	dp,cc,x,y,u,d
waitkeyfinish	jsr     KEYIN        ; Read keyboard
		beq     waitkeyfinish  ; No key pressed, wait for keypress
		puls	dp,cc,x,y,u,d
		rts

;output carriage return
CROUT		pshs    a
                lda     #13
                jsr     PUTCHR
                puls    a
		rts

;output multiprecision binary number in hex
BNHEXOUT	pshs	x,y,d
		leax	d,x
		tfr	d,y
bnhexoutloop	lda	,-x
		jsr	BN2HEX
                jsr     PUTCHR
		tfr	b,a
                jsr     PUTCHR
		leay	-1,y
		bne	bnhexoutloop
		puls	x,y,d
		rts

PUTCHR			JMP	[$A002]
KEYIN			JMP	[$A000]

