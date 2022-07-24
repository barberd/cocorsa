;Color Computer RSA main routine

; This file is part of Color Computer RSA by Don Barber Copyright 2022

; Color Computer RSA is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

; Color Computer RSA is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along with Color Computer RSA. If not, see <https://www.gnu.org/licenses/>.

					;MPLEN needs to be PRIME LENGTH * 4
					;as to not overflow N=P*Q
					;and modular exponentiation which does
					;N*N

MPLEN		EQU	512		;largest key possible is MPLEN/2
					;so this means 256 bytes aka 2048 bits
CR		EQU	13
		;org	$0182
		;jmp	start

                org $0e00 ; start of free RAM

start
		;lds	#$c000

		;uncomment to see stack location when first starting
		;TFR	S,D
		;EXG	A,B
		;PSHS	D
		;TFR	S,X
		;LDD	#2
		;JSR	BNHEXOUT
		;LEAS	2,S
		;JSR	CROUT

		LDA	#$FF
		STA	coco3flag
		LDD	$FFFE
		CMPD	#$8C1B
		BNE	notcoco3
		CLRA
		STA	coco3flag
		STA	$FFD9		; set hi MPU speed
		LDA	#$E0
		STA	$FF22
		STA	$FFC0
		STA	$FFC2
		STA	$FFC4
notcoco3:

		clr	PRIVKEYLOADED
		clr	PUBKEYLOADED

		jsr	SEEDRANDOM	; seed random number generator

		ldx	#STRSTART	; output start screen
		jsr	STROUTWRAP

		jsr	DSKINIT		; init disk routines

waitentry1	
		jsr	RANDOM		; continually run pseudorandom
		jsr	KEYIN		; generator until user hits a key
		beq	waitentry1	; to exit the start screen
		JSR	CROUT
mainmenu	LDX	#STRMAINMENU
		JSR	STROUTWRAP	; show main menu

waitmenu
		jsr	RANDOM		; keep on generating pseudorandom
		jsr	KEYIN		; numbers while menu is chosen
		beq	waitmenu	
		suba	#'0		; remove ascii bias
		BMI	waitmenu
		cmpa	#8		; if greater than last menu selection,
					; keep waiting
		BGT	waitmenu	; for valid entry
		ANDCC	#$FE
		ROLA
		LDX	#menutable
		LDX	A,X
		JSR	,X
		LDX	#STRHITKEY
		JSR	STROUTWRAP
		JSR	WAITKEY	
		JSR	CROUT
		JMP	mainmenu

EXIT		

		ldy	#dbstart	; fill data section with random numbers
		ldx	#dblen
fillrandloop
		jsr	RANDOM
		cmpx	#1
		bne	fillrandloopnotone
		sta	,y
		bra	fillrandloopdone
fillrandloopnotone	std	,y++
		leax	-2,x
		bne	fillrandloop
fillrandloopdone			

		TST	coco3flag
		BNE	notcoco3again
		clr	$ffd8		; lower to standard(slow) MPU speed
notcoco3again:
		JMP     $A027           ; Restart BASIC
		;clr	$0071
		;clr	$0072
		;JMP     [$FFFE]	; Restart BASIC
		rts

SHOWLICENSE

                LEAS    -267,S
                TFR     S,U

		TST	coco3flag
		BNE	showlicnotcoco3
                LDA     HRWIDTH
                BNE     showlicnot32    ;32 column
showlicnotcoco3:
                LDA     #15
                LDB     #32
                JMP     showlicdonesize
showlicnot32:
                CMPA    #1
                BNE     showlicnot40    ;40 column
                LDA     #23
                LDB     #40
                JMP     showlicdonesize
showlicnot40:
                LDA     #23
                LDB     #80
showlicdonesize:

                STA     SCRHEIGHT
                STB     SCRWIDTH

                LEAS    -256,S

                LDA     DEFDRV
                PSHS    A
                ldx     #COPYINGFNAME
                PSHS    X
                CLRA
                PSHS    A
                PSHS    U
                JSR     DSKFOPEN
                TSTA
                LBNE    showlicenseerror

                CLR     CURLINE
                CLR     CURCOL
		LDD	#0		; initial buffer to read

showlicreadbuf: 
		LEAY	D,S
		PSHS	D
		LDD	#256
		SUBD	,S++	
		PSHS    U,Y,D
                JSR     DSKFREAD
                CMPD    #0
                LBEQ    showlicdoneread
		TFR	D,X

showlicinnerloop:
		LDA	,Y+

		CMPA	#$60		; open single quote does not show
		BNE	showlicnot60	; correctly on the coco. Instead replace
		LDA	#$27		; it with a single quote.
showlicnot60:
		
		CMPA	#$0A
		BNE	showlicnotlf

		LDB	HRWIDTH
		CMPB	#$02
		BEQ	showlicis80
		CMPA	-2,Y 
		BNE	showlicnot80
		JSR	CROUT
		INC	CURLINE
showlicis80:
		JSR	CROUT
		INC	CURLINE
		CLR	CURCOL
		JMP	showlicchecknewline
showlicnot80:
		LDA	#$20
		JMP	showlicnot80tstsp
showlicnotlf:
		LDB	HRWIDTH
		CMPB	#$02
		BEQ	showlicnotni

		CMPA	#$20
		BNE	showlicnotsp

		LDB	-2,Y
		CMPB	#$20
		LBEQ	showlicnonp
		CMPB	#$0A
		BEQ	showlicnonp

showlicnot80tstsp:

		TST	CURCOL		; if in width 32 or 40 modes 
		BEQ	showlicnonp	; and space is beginning of line
					; don't output
showlicnotsp:


		TST	coco3flag
		BNE	showliccoco12
		TST	HRWIDTH
                BNE     showlicnotni
showliccoco12:
                CMPA    #$61
                BLT     showlicnotni
                CMPA    #$7A
                BGT     showlicnotni
                SUBA    #$20            ;make capital (not inverted)
showlicnotni:

                JSR     PUTCHR
		LDB	CURCOL
		INCB
		STB	CURCOL
		CMPB	SCRWIDTH
		BCS	showlicnonp
		CLR	CURCOL
		INC	CURLINE

		CMPA	#$20
		BEQ	showlicnowrap

		LDB	,Y
		CMPB	#$0A
		BEQ	showlicnowrap
		CMPB	#$20
		BEQ	showlicnowrap

		PSHS	Y,X		; store Y and X here
		LEAY	4,S
		PSHS	Y
		LDY	4,S
		CLRB
showlicfindsp:	
		CMPY	,S		; check if Y buffer back at beginning
		BEQ	showlicfoundsp  ; if so then quit looking for space
		LDA	,-Y
		LEAX	1,X
		CMPA	#$0A
		BEQ	showlicfoundsp
		CMPA	#$20	
		BEQ	showlicfoundsp
		INCB
		CMPB	SCRWIDTH        ; if already backspaced the whole line
		BEQ	showlictoolong  ; then quit looking for space
		JMP	showlicfindsp
showlictoolong:
		LEAS	2,S
		PULS	Y,X
		JMP	showlicnowrap	

showlicfoundsp:	
		LEAS	6,S		; get rid of original Y location
	
		LDA	#$08
showlicbackspace:				
		JSR	PUTCHR
		DECB
		BNE	showlicbackspace	

		JSR	CROUT
		;INC	CURLINE
		;CLR	CURCOL
		LDA	#$20
showlicnowrap:

showlicchecknewline:
		LDA	CURLINE
		CMPA	SCRHEIGHT
		BCC	showlicprompt
showlicnonp:
		LEAX	-1,X
		LBNE	showlicinnerloop
		LDD	#0
		JMP	showlicreadbuf

showlicprompt:
                JSR     DSKTURNOFFMOTORS
		PSHS	U,Y,X
showlicpromptloop:
                JSR     KEYIN
                BEQ     showlicpromptloop
		PULS	U,Y,X
                CMPA    #'Q
                BEQ     showlicdoneread
                CMPA    #'q
                BEQ     showlicdoneread
                CMPA    #$03
                BEQ     showlicdoneread
		CLR	CURCOL
		CLR	CURLINE
		JMP	showlicnonp
showlicdoneread:
		JSR	CROUT
                PSHS    U
                JSR     DSKFCLOSE
                JMP     showlicensedone
showlicenseerror:
               	LDX     #STRFOPENERROR
                JSR     STROUTWRAP
                JSR     CROUT
showlicensedone:
                JSR     DSKTURNOFFMOTORS
                LEAS    256,S
                LEAS    267,S
		RTS
CURCOL		rmb	1
CURLINE		rmb	1
SCRWIDTH	rmb	1
SCRHEIGHT	rmb	1

GENERATEKEY
		ldx	#STRGENCHOICE
		jsr	STROUTWRAP

waitentry2
		jsr	RANDOM		; Keep generating pseudorandom
		jsr	KEYIN		; numbers until user selects menu
		beq	waitentry2	
		CMPA	#3
		LBEQ	generatekeydone
		CMPA	#'Q
		LBEQ	generatekeydone
		suba	#'0		; remove ascii bias
		BMI	waitentry2
		cmpa	#7		; if invalid then ignore
		BGT	waitentry2

		ldx	#STRYOUCHOSE	; show user what they chose
		jsr	STROUTWRAP
		pshs	a
		adda	#'0
		jsr	PUTCHR
		jsr	CROUT

		puls	a

		ASLA
		PSHS	A
		LDX	#primestatarray
		LDD	A,X
		STD	primestat
		PULS	A

		LDX	#choicearray
		LDD	A,X

		STD	PLENGTH		; store chosen prime length
		ANDCC	#$FE
		ROLB
		ROLA
		STD	PRIVKEYLENGTH	; and key length
		ANDCC	#$FE
		ROLB
		ROLA
		STD	PRIVKEYLENGTH2	; and key length*2
					; (need twice as much room for
					; multiplication results)

		ldy	#dbstart	; clear data section
		ldx	#dblen
cleardbloop:	CLR	,Y+
		LEAX	-1,X
		BNE	cleardbloop

		LDX	#STRPROVIDERAND
		JSR	STROUTWRAP

		ldy	#rsap		; fill rsap and rsaq with random numbers
		ldx	PRIVKEYLENGTH
		LEAS	-8,S
		CLR	,S	; make sure leading 0 for first run

randploopo
		CMPX	PLENGTH
		BNE	randploopon
		LDY	#rsaq
randploopon
		PSHS	Y,X,D
		LEAX	6,S
randploopruboutloop:
		LDA	,X+
		BEQ	randploopruboutdone	
		LDA	#$08		; backspace
		JSR	PUTCHR
		JMP	randploopruboutloop
randploopruboutdone	
		LDD	2,S
		LSRA
		RORB
		LEAX	6,S
		JSR	BN2DEC
		LEAX	6,S
		JSR	STROUT
		PULS	Y,X,D
randploopi
		JSR	RANDOM
		PSHS	D
		JSR	KEYIN
		PULS	D	
		BEQ	randploopi
randploopnotone	std	,y++
		leax	-2,x
		bne	randploopo
randploopdone			
		LEAS	8,S
		LDA	#$08
		JSR	PUTCHR
		LDA	#'0
		JSR	PUTCHR
		JSR	CROUT

		ldx	#rsap		; ensure MSB is at least $B6
		ldd	PLENGTH		; so multiplication leads to 
		subd	#1		; leading bit of key is 1
		leax	D,X		; and key will be n bits not n-1 bits 
randphighbyte	lda	,x
		cmpa	#$B6
		BHS	randphighbytedone
		jsr	RANDOM
		sta	,x
		bra	randphighbyte
randphighbytedone

						; now do same thing for rsaq

		ldx	#rsaq			; also make sure leading byte
		ldd	PLENGTH			; is $B6 or higher
		subd	#1			; so key's leading bit is 1
		leax	D,x
randqhighbyte	lda	,x
		cmpa	#$B6
		BHS	randqhighbytedone
		jsr	RANDOM
		sta	,x
		bra	randqhighbyte
randqhighbytedone

		LDX	#STRGENERATING
		JSR	STROUTWRAP

		ldx	#rsap
		ldd	PLENGTH
		jsr	BNHEXOUT
		jsr	CROUT

		ldx	#rsap		; now call subroutine to increment
		ldd	PRIVKEYLENGTH	; rsap until its found to be prime
		pshs	x,d
		jsr	MPBNEXTPRIME

		ldx	#rsaq
		ldd	PLENGTH
		jsr	BNHEXOUT
		jsr	CROUT

		ldx	#rsaq			; increment rsaq until found
		ldd	PRIVKEYLENGTH		; to be prime
		pshs	x,d
		jsr	MPBNEXTPRIME

		ldx	#STRP			; inform user of P
		jsr	STROUTWRAP
		ldx	#rsap
		ldd	PLENGTH
		jsr	BNHEXOUT
		jsr	CROUT

		ldx	#STRQ			; inform user of Q
		jsr	STROUTWRAP
		ldx	#rsaq
		ldd	PLENGTH
		jsr	BNHEXOUT
		jsr	CROUT

		ldu	#rsap			; multiply P and Q
		ldy	#rsaq			; and store in N
		ldx	#privrsan
		ldd	PLENGTH
		pshs	u,y,x,d
		jsr	MPBMULU

		ldx	#STRN			; output N to user
		jsr	STROUTWRAP
		ldx	#privrsan
		ldd	PRIVKEYLENGTH
		jsr	BNHEXOUT
		jsr	CROUT

;Calculate Totient via
; tot = ((p-1)*(q-1))/gcd(p-1,q-1) 

		LDD	PRIVKEYLENGTH2
		ANDCC	#$FE
		ROLB
		ROLA	
		PSHS	D
		LDD	#0
		SUBD	,S++

		LEAS	D,S		; make room on stack

		LDU	#rsap			; copy P to stack (P')
		TFR	S,Y
		LDX	PRIVKEYLENGTH
copyphi1	LDA	,u+
		STA	,y+
		leax	-1,x
		BNE	copyphi1

		LDD	PRIVKEYLENGTH
		LDU	#rsaq			; copy Q to stack (Q')
		LEAY	D,S
		TFR	D,X
copyphi2	LDA	,u+
		STA	,y+
		leax	-1,x
		BNE	copyphi2

		TFR	S,Y			; P' = P' - 1
		LDX	PLENGTH
decploop	LDA	,Y
		SUBA	#1
		STA	,Y+
		BCC	decpdone
		leax	-1,x
		BNE	decploop	
decpdone

		LDD	PRIVKEYLENGTH
		LEAY	D,S			; Q' = Q' - 1
		LDX	PLENGTH
decqloop	LDA	,Y
		SUBA	#1
		STA	,Y+
		BCC	decqdone
		leax	-1,x
		BNE	decploop
decqdone
		TFR	S,U			; PHI = P' * Q'
		LDD	PRIVKEYLENGTH2
		LEAX	D,S			; PHI is at PRIVKEYLENGTH2,S
		LDD	PRIVKEYLENGTH
		LEAY	D,S
		PSHS	u,y,x,d
		JSR	MPBMULU

		TFR	S,U
		LDD	PRIVKEYLENGTH
		LEAY	D,S
		PSHS	U,Y,D
		JSR	MPBEGCD

		LDX	PRIVKEYLENGTH
		TFR	S,U
copygcdloop1:	LDA	,Y+
		STA	,U+
		LEAX	-1,X
		BNE	copygcdloop1

		LDX	PRIVKEYLENGTH
		CLRA
copygcdloop2:	STA	,U+		;init rest of GCD to 0s
		LEAX	-1,X
		BNE	copygcdloop2

		LDD	PRIVKEYLENGTH2
		LEAU	D,S
		TFR	S,Y
		LDX	#rsatot		; finally store totient here
		PSHS	U,Y,X
		LDX	#HEAP		; throw remainder away, don't need it
		PSHS	X,D
		JSR	MPBDIV

		LDD	PRIVKEYLENGTH2
		ANDCC	#$FE
		ROLB
		ROLA	
		LEAS	D,S			; shrink stack 

		ldx	#STRTOT			; output totient to user
		jsr	STROUTWRAP
		ldx	#rsatot
		ldd	PRIVKEYLENGTH
		jsr	BNHEXOUT
		jsr	CROUT

		lda	#1			; set E = 0x10001
		ldx	#privrsae
		sta	,X
		sta	2,X

rsaeloop	ldx	#rsatot
		ldy	#privrsae
		ldd	PRIVKEYLENGTH2
		pshs	y,x,d
		jsr	MPBEGCD			;GCD is in ,Y
						;coefficent from EGCD is rsad

		ldy	#rsad
		ldx	PRIVKEYLENGTH
copydloop	lda	,u+
		sta	,y+
		leax	-1,x
		bne	copydloop

		ldx	#STRD
		jsr	STROUTWRAP
		ldx	#rsad
		ldd	PRIVKEYLENGTH
		jsr	BNHEXOUT
		jsr	CROUT

		ldx	#STRE
		jsr	STROUTWRAP
		ldx	#privrsae
		ldd	#4
		jsr	BNHEXOUT
		jsr	CROUT

		ldx	#STRDP
		jsr	STROUTWRAP

		ldu	#rsad
		ldy	#rsadq
		ldx	PRIVKEYLENGTH
copydloop2	lda	,u+
		sta	,y+
		leax	-1,x
		bne	copydloop2

		ldu	#rsad
		ldy	#rsadp
		ldx	PRIVKEYLENGTH
copydloop3	lda	,u+
		sta	,y+
		leax	-1,x
		bne	copydloop3

		LDD	#0
		SUBD	PRIVKEYLENGTH
		LEAS	D,S

		ldu	#rsap		;make dp
		TFR	S,Y
		ldx	PRIVKEYLENGTH
copyploop	lda	,u+
		sta	,y+
		leax	-1,x
		bne	copyploop

		TFR	S,Y
		ldx	PRIVKEYLENGTH
decploop2	lda	,y
		suba	#1
		sta	,y+
		bcc	decpdone2
		leax	-1,x
		bne	decploop2
decpdone2

		ldu	#rsadp
		TFR	S,Y
		ldx	#0
		ldd	PRIVKEYLENGTH
		pshs	u,y,x,d
		jsr	MPBREM

		ldx	#rsadp
		ldd	PLENGTH
		jsr	BNHEXOUT
		jsr	CROUT

		ldx	#STRDQ
		jsr	STROUTWRAP

		ldu	#rsaq		;make dq
		TFR	S,Y
		ldx	PRIVKEYLENGTH
copyqloop	lda	,u+
		sta	,y+
		leax	-1,x	
		bne	copyqloop

		TFR	S,Y
		ldx	PRIVKEYLENGTH
decqloop2	lda	,y
		suba	#1
		sta	,y+
		bcc	decqdone2
		leax	-1,x
		bne	decqloop2
decqdone2
		ldu	#rsadq
		TFR	S,Y
		ldx	#0
		ldd	PRIVKEYLENGTH
		pshs	u,y,x,d
		jsr	MPBREM

		LDD	PRIVKEYLENGTH
		LEAS	D,S

		ldx	#rsadq
		ldd	PLENGTH
		jsr	BNHEXOUT
		jsr	CROUT
		ldx	#STRQINV
		jsr	STROUTWRAP


		ldy	#rsaq
		ldx	#rsap
		ldd	PRIVKEYLENGTH
		pshs	y,x,d
		jsr	MPBEGCD		;GCD is in ,Y

		ldy	#rsaqinv
		ldx	PRIVKEYLENGTH
copyqinvloop	lda	,u+
		sta	,y+
		leax	-1,x
		bne	copyqinvloop

		ldx	#rsaqinv
		ldd	PLENGTH
		jsr	BNHEXOUT
		jsr	CROUT

		LDA	#$FF
		STA	PRIVKEYLOADED
		JSR	COPYPRIVTOPUB

		LEAS	-14,S

startpubkeyfname:
		LDX	#STRPUBKEYFNAME
		jsr	STROUTWRAP
		jsr	CROUT

		TFR	S,U
		LDX	#14
		JSR	INPUTSTR
		JSR	CROUT

		LDA	,S
		BNE	notdefaultpubkey
		LDY	#DEFPUBKEYFNAME
		TFR	S,U
copypubkeyfname:
		LDA	,Y+
		STA	,U+
		BNE	copypubkeyfname
notdefaultpubkey:
		CMPA	#$03
		BEQ	startpubkeyfname

		TFR	S,U
		LDY	#PUBKEYFNAME
		JSR	FORMATFNAME
		BEQ	goodpubkeyfname
		JMP	startpubkeyfname
goodpubkeyfname:

startprivkeyfname:
		LDX	#STRPRIVKEYFNAME
		jsr	STROUTWRAP
		jsr	CROUT

		TFR	S,U
		LDX	#14
		JSR	INPUTSTR
		JSR	CROUT
	
		LDA	,S
		BNE	notdefaultprivkey

		LDY	#DEFPRIVKEYFNAME
		TFR	S,U
copyprivkeyfname:
		LDA	,Y+
		STA	,U+
		BNE	copyprivkeyfname
notdefaultprivkey:
		CMPA	#$03
		BEQ	startpubkeyfname

		TFR	S,U
		LDY	#PRIVKEYFNAME
		JSR	FORMATFNAME
		BEQ	goodprivkeyfname
		JMP	startprivkeyfname
goodprivkeyfname:

		LEAS	14,S

		ldx	#STRSAVING
		JSR	STROUTWRAP

		LDU	#HEAP

		ldy	#pubrsan
		ldd	PUBKEYLENGTH
		JSR	ASN1OUTMPBINT

		ldy	#pubrsae
		ldd	PUBKEYLENGTH
		JSR	ASN1OUTMPBINT

		LDA	PUBKEYFNAME
		PSHS	A
		LDX	#PUBKEYFNAME+1
		PSHS	X
		LDD	#$0005
		PSHS	D
		JSR	DSKNEWFILE

		LEAS	-267,S		; make room on stack for FCB
		TFR	S,Y
		
		LDA	DEFDRV
		PSHS	A
		LDX	#PUBKEYFNAME+1
		PSHS	X
		LDA	#1
		PSHS	A
		PSHS	Y
		JSR	DSKFOPEN

		TFR	U,D
		SUBD	#HEAP		; this is length of N+E output
		PSHS	U,D             ; start of sequence+length N+E		
		LDA	#$30
		STA	,U+
		LDD	,S
		JSR	ASN1SETSIZE
		TFR	U,D
		SUBD	2,S
		PSHS	U,D		;start of bitsequence+length sequence
		LDA	#$03
		STA	,U+
		TFR	U,D
		SUBD	#HEAP
		JSR	ASN1SETSIZE
		CLR	,U+
		TFR	U,D
		SUBD	2,S
		PSHS	U,D		;start of sequence0+length bitsequence

		TFR	U,D
		SUBD	#HEAP		;total size so far
		PSHS	D		
		LDA	#$30
		STA	,U+
		PULS	D
		ADDD	#pubheaderlength	; add pubheaderlength
		JSR	ASN1SETSIZE

		TFR	U,D		; write out sequence0
		SUBD	2,S
		LEAU	12,S
		LDY	2,S
		PSHS	U,Y,D
		JSR	DSKFWRITE

		LDY	#pubheader	; write out pubheader
		LDD	#pubheaderlength
		PSHS	U,Y,D
		JSR	DSKFWRITE

		LDY	6,S		; write out bitsequence
		LDD	,S
		PSHS	U,Y,D
		JSR	DSKFWRITE

		LDY	10,S		; write out sequence
		LDD	4,S
		PSHS	U,Y,D
		JSR	DSKFWRITE
		
		LDY	#HEAP		; write out N+E
		LDD	8,S
		PSHS	U,Y,D
		JSR	DSKFWRITE	

		PSHS	U
		jsr	DSKFCLOSE

		LEAS	279,S

		LDU	#HEAP

		lda	#$02
		STA	,U+
		lda	#$01
		STA	,U+
		lda	#$00
		STA	,U+

		ldy	#privrsan
		ldd	PRIVKEYLENGTH
		JSR	ASN1OUTMPBINT

		ldy	#privrsae
		ldd	PRIVKEYLENGTH
		JSR	ASN1OUTMPBINT

		ldy	#rsad
		ldd	PRIVKEYLENGTH
		JSR	ASN1OUTMPBINT

		ldy	#rsap
		ldd	PLENGTH
		JSR	ASN1OUTMPBINT

		ldy	#rsaq
		ldd	PLENGTH
		JSR	ASN1OUTMPBINT

		ldy	#rsadp
		ldd	PLENGTH
		JSR	ASN1OUTMPBINT

		ldy	#rsadq
		ldd	PLENGTH
		JSR	ASN1OUTMPBINT

		ldy	#rsaqinv
		ldd	PLENGTH
		JSR	ASN1OUTMPBINT

		LDA	PRIVKEYFNAME
		PSHS	A
		LDX	#PRIVKEYFNAME+1
		PSHS	X
		LDD	#$0005
		PSHS	D
		JSR	DSKNEWFILE

		LEAS	-267,S
		TFR	S,Y
		
		LDA	DEFDRV
		PSHS	A
		LDX	#PRIVKEYFNAME+1
		PSHS	X
		LDA	#1
		PSHS	A
		PSHS	Y
		JSR	DSKFOPEN

		PSHS	U

		TFR	U,D
		SUBD	#HEAP
		PSHS	D
		LDA	#$30
		STA	,U+
		PULS	D
		JSR	ASN1SETSIZE

		TFR	U,D
		SUBD	,S
		LDU	,S
		PSHS	Y
		PSHS	U,D
		JSR	DSKFWRITE

saveprivkeyclearseq
		CLR	,U+
		SUBD	#1
		BNE	saveprivkeyclearseq

		PULS	U

		TFR	U,D
		SUBD	#HEAP
		PSHS	D		; store length on stack

		LDX	#HEAP
		PSHS	Y
		PSHS	X
		PSHS	D
		JSR	DSKFWRITE	

		PSHS	Y
		JSR	DSKFCLOSE
		JSR	DSKTURNOFFMOTORS

		PULS	X		; restore length
		LDU	#HEAP
		CLRA
generatekeyclearheaploop:
		STA	,U+
		LEAX	-1,X
		BNE	generatekeyclearheaploop

		LEAS	267,S

		ldx	#STRDONE
		JSR	STROUTWRAP
		JSR	CROUT
generatekeydone:
		rts

ENCRYPTMESSAGE

		TST	PUBKEYLOADED
		BNE	encryptmessagekeyloaded
		LDX	#STRNOPUBKEY
		JSR	STROUTWRAP
		JSR	CROUT
		RTS

encryptmessagekeyloaded:

		LDX	#STRINFORMLIMIT
		JSR	STROUTWRAP
		JSR	CROUT	

		ldu	#rsam
		ldx	PUBKEYLENGTH2
clrrsamloop	clr	,u+
		leax	-1,x
		bne	clrrsamloop

		LDX	#STRENTERMESSAGE
		JSR	STROUTWRAP
		JSR	CROUT

		LDU	#HEAP
		LDX	PUBKEYLENGTH
		JSR	INPUTSTR
		LDA	HEAP
		CMPA	#$03
		BEQ	generatekeydone

;entry point for encrypting file
;U should be pointer to END of buffer
;X should be remaining bytes between collected buffer and KEYLENGTH
encryptmessageloadfromheap:
		LDY	#rsam
		TFR	X,D
		LEAY	D,Y

		PSHS	X
		LDD	PUBKEYLENGTH
		SUBD	,S++
		TFR	D,X

encryptmessagersamloop:
		LDA	,-U
		STA	,Y+
		LEAX	-1,X
		BNE	encryptmessagersamloop

		JSR	CROUT

		ldx	#STRM
		jsr	STROUTWRAP
		ldx	#rsam
		ldd	PUBKEYLENGTH
		jsr	BNHEXOUT
		jsr	CROUT

		ldx	#STRC
		jsr	STROUTWRAP

		ldy	#rsam
		ldx	#pubrsae
		pshs	y,x
		ldy	#pubrsan
		ldx	#rsac
		ldd	PUBKEYLENGTH2
		pshs	y,x,d
		jsr	MPBMODEXP

		ldx	#rsac
		ldd	PUBKEYLENGTH
		jsr	BNHEXOUT
		jsr	CROUT

		LDX	#STRSAVEYN
		JSR	STROUTWRAP

encryptmessagesaveyn:
		JSR	KEYIN
		CMPA	#'N
		LBEQ	encryptmessagedone
		CMPA	#'n
		LBEQ	encryptmessagedone
		CMPA	#'Y
		BEQ	encryptmessagesavemessage
		CMPA	#'y
		BEQ	encryptmessagesavemessage
		JMP	encryptmessagesaveyn
encryptmessagesavemessage:

		JSR	CROUT

		LEAS	-293,S		; 1 byte for drive, 11 bytes for fname
					; 14 for input string
					; 267 for FCB
encryptmessagegetfname:
		LDX	#STRENTERNAME
		JSR	STROUTWRAP
		LEAU	12,S
		LDX	#14
		JSR	INPUTSTR
		TFR	S,Y
		LEAU	12,S
		LDA	,U
		CMPA	#$03
		BEQ	encryptmessagegetfname
		JSR	FORMATFNAME	
		TSTA
		BNE	encryptmessagegetfname

		LDA	,S
		LEAX	1,S
		PSHS	A
		PSHS	X
		LDD	#$0006
		PSHS	D
		JSR	DSKNEWFILE

		LDA	,S
		LEAX	1,S
		LEAU	26,S
		PSHS	A
		PSHS	X
		LDA	#1			; open as write
		PSHS	A
		PSHS	U
		JSR	DSKFOPEN	
		TSTA
		BNE	encryptmessagesaveerror

		LEAU	26,S
		LDD	PUBKEYLENGTH
		LDY	#rsac
		LEAY	D,Y
encryptmessagesaveloop:
		LEAY	-1,Y
		PSHS	D
		LDX	#1
		PSHS	U,Y,X
		JSR	DSKFWRITE
		PULS	D
		SUBD	#1
		BNE	encryptmessagesaveloop
	
		LEAU	26,S
		PSHS	U
		JSR	DSKFCLOSE
		JSR	DSKTURNOFFMOTORS

		LEAS	293,S	
		JMP	encryptmessagedone

encryptmessagesaveerror:
		JSR	DSKTURNOFFMOTORS
		LDX	#STRSAVEERROR
		JSR	STROUTWRAP
		JSR	CROUT
		LEAS	293,S	


;		ldx	#STRDONE
;		JSR	STROUTWRAP
;		JSR	CROUT
encryptmessagedone:
		LDU	#HEAP
		LDX	PUBKEYLENGTH
		CLRA
encryptmessageclearloop:
		STA	,U+
		LEAX	-1,X
		BNE	encryptmessageclearloop		
		JSR	CROUT
		rts

DECRYPTMESSAGE

		TST	PRIVKEYLOADED
		BNE	decryptmessagekeyloaded
		LDX	#STRNOPRIVKEY
		JSR	STROUTWRAP
		JSR	CROUT
		RTS
decryptmessagekeyloaded:

		ldy	#rsac			; clear top half of C
		ldx	PRIVKEYLENGTH
		tfr	x,d
		leay	d,y
clearrsachighlp	clr	,y+
		leax	-1,x
		bne	clearrsachighlp

		ldx	#STRC
		jsr	STROUTWRAP

		ldx	#rsac
		ldd	PRIVKEYLENGTH
		jsr	BNHEXOUT
		jsr	CROUT

		ldx	#STRMD
		jsr	STROUTWRAP


;Original RSA decryption here using m=c^d mod n
;Replaced with faster CRT version below
;		ldy	#rsac
;		ldx	#rsad
;		pshs	y,x
;		ldy	#privrsan
;		ldx	#rsam
;		ldd	PRIVKEYLENGTH2
;		pshs	y,x,d
;		jsr	MPBMODEXP

;Decryption using Chinese Remainder Theorem here
;This is faster as power of dp and dq are faster than power to d
;Using a 512bit key this took about 80% of the time of original RSA

;m1 = c^dp % p
;m2 = c^dq % q
;h = (qinv*(m1-m2)) % p
;m = m2 + h*q

		CLR	,-S		; set flag for not negative H

		LDD	PRIVKEYLENGTH2
		ANDCC	#$FE
		ROLB
		ROLA
		PSHS	D
		LDD	#0
		SUBD	,S++
		LEAS	D,S

		LDU	#rsam
		TFR	S,Y			; rsam2 on stack
		#LDY	#rsam2
		LDX	PRIVKEYLENGTH2		; clears both rsam and rsam2
		CLRA
decryptmessageclearrsam:
		STA	,U+
		STA	,Y+
		LEAX	-1,X
		BNE	decryptmessageclearrsam

;m1 = c^dp % p

		LDU	#rsac
		LDY	#rsadp
		LDX	#rsap
		PSHS	U,Y,X
		LDX	#rsam
		LDD	PRIVKEYLENGTH2
		PSHS	X,D
		JSR	MPBMODEXP

;m2 = c^dq % q

		LDU	#rsac
		LDY	#rsadq
		LDX	#rsaq
		PSHS	U,Y,X
		LEAX	6,S
		#LDX	#rsam2
		LDD	PRIVKEYLENGTH2
		PSHS	X,D
		JSR	MPBMODEXP

;h = (qinv*(m1-m2)) % p

		LDU	#rsam
		LDD	PRIVKEYLENGTH
		TFR	S,Y
		#LDY	#rsam2
		PSHS	U,Y,D
		JSR	MPBSUB	


		LDU	#rsam-1
		LDD	PRIVKEYLENGTH
		LDA	D,U
		BITA	#$80		; test if rsam is negative
		BEQ	decryptmessagersamnotneg

		LDD	PRIVKEYLENGTH2	; set flag for negative H
		ADDD	PRIVKEYLENGTH2
		COM	D,S

		LDU	#rsam
		LDX	PRIVKEYLENGTH
decryptmessagecomrsam
		COM	,U+
		LEAX	-1,X
		BNE	decryptmessagecomrsam

		LDU	#rsam
		LDX	PRIVKEYLENGTH
decryptmessagersamnegripple
                INC     ,U+
                BNE     decryptmessagersamnegfinish
                LEAX    -1,X
                BNE     decryptmessagersamnegripple
decryptmessagersamnegfinish:
decryptmessagersamnotneg:

		LDU	#rsam
		LDY	#rsaqinv
		LDD	PRIVKEYLENGTH2
		LEAX	D,S
		LDD	PRIVKEYLENGTH
		PSHS	U,Y,X,D
		JSR	MPBMULS

		LDD	PRIVKEYLENGTH2
		LEAU	D,S
		LDD	PRIVKEYLENGTH
		LDY	#rsap
		LDX	#0
		PSHS	U,Y,X,D
		JSR	MPBREM

		LDD	PRIVKEYLENGTH2		; test flag for negative H
		ANDCC	#$FE
		ROLB
		ROLA
		LDA	D,S
		TSTA
		BEQ	decryptmessagehnotneg

		LDD	PRIVKEYLENGTH2
		LEAU	D,S
		LDD	PRIVKEYLENGTH
		LDY	#rsap
		PSHS	U,Y,D
		JSR	MPBSUB

		LDD	PRIVKEYLENGTH2
		LEAU	D,S
		LDX	PRIVKEYLENGTH
decryptmessagecomh
		COM	,U+
		LEAX	-1,X
		BNE	decryptmessagecomh

		LDD	PRIVKEYLENGTH2
		LEAU	D,S
		LDX	PRIVKEYLENGTH
decryptmessagehnegripple
                INC     ,U+
                BNE     decryptmessagehnegfinish
                LEAX    -1,X
                BNE     decryptmessagehnegripple
decryptmessagehnegfinish:
decryptmessagehnotneg:
;m = m2 + h*q
		LDD	PRIVKEYLENGTH2
		LEAU	D,S
		LDD	PRIVKEYLENGTH
		LDY	#rsaq
		LDX	#rsam
		PSHS	U,Y,X,D
		JSR	MPBMULU
	
		LDU	#rsam
		TFR	S,Y
		#LDY	#rsam2
		LDD	PRIVKEYLENGTH
		PSHS	U,Y,D
		JSR	MPBADD	

		LDD	PRIVKEYLENGTH2
		ANDCC	#$FE
		ROLB
		ROLA
		ADDD	#1		; flag for H too
		LEAS	D,S

		ldx	#rsam
		ldd	PRIVKEYLENGTH
		jsr	BNHEXOUT
		jsr	CROUT

		LDX	#STRDISPMSGYN
		JSR	STROUTWRAP
		JSR	CROUT

decryptmessagedispmsgin:
		JSR	KEYIN
		CMPA	#'Y
		BEQ	decryptmessagedispmsg
		CMPA	#'y
		BEQ	decryptmessagedispmsg
		CMPA	#'N
		BEQ	decryptmessagedispmsgdone
		CMPA	#'n
		BEQ	decryptmessagedispmsgdone
		JMP	decryptmessagedispmsgin
decryptmessagedispmsg:
		LDY	#rsam
		LDX	PRIVKEYLENGTH
		TFR	X,D
		LEAY	D,Y
decryptmessagedispmsgloop:
		LDA	,-Y
		JSR	PUTCHR
		LEAX	-1,X
		BNE	decryptmessagedispmsgloop
		JSR	CROUT
decryptmessagedispmsgdone:

		LDX	#STRSAVEMSGYN
		JSR	STROUTWRAP
		JSR	CROUT

decryptmessagesavemsgin:
		JSR	KEYIN
		CMPA	#'Y
		BEQ	decryptmessagesavemsg
		CMPA	#'y
		BEQ	decryptmessagesavemsg
		CMPA	#'N
		LBEQ	decryptmessagesavemsgdone
		CMPA	#'n
		LBEQ	decryptmessagesavemsgdone
		JMP	decryptmessagesavemsgin
decryptmessagesavemsg:

		LEAS	-293,S
decryptmessagegetfname:
		LDX	#STRENTERNAME
		JSR	STROUTWRAP
		LEAU	12,S
		LDX	#14
		JSR	INPUTSTR
		TFR	S,Y
		LEAU	12,S
		LDA	,U
		CMPA	#$03
		BEQ	decryptmessagegetfname
		JSR	FORMATFNAME	
		TSTA
		BNE	decryptmessagegetfname
		JSR	CROUT

		LDA	,S
		LEAX	1,S
		PSHS	A
		PSHS	X
		LDD	#$FF01
		PSHS	D
		JSR	DSKNEWFILE

		LDA	,S
		LEAX	1,S
		LEAU	26,S
		PSHS	A
		PSHS	X
		LDA	#1			; open as write
		PSHS	A
		PSHS	U
		JSR	DSKFOPEN	
		TSTA
		LBNE	encryptmessagesaveerror

		LEAU	26,S
		LDD	PRIVKEYLENGTH
		LDY	#rsam-1
		LEAY	D,Y

decryptmessagesaveloop:
		PSHS	D
		LDX	#1
		PSHS	U,Y,X
		JSR	DSKFWRITE
		PULS	D
		LEAY	-1,Y
		SUBD	#1
		BNE	decryptmessagesaveloop
	
		LEAU	26,S
		PSHS	U
		JSR	DSKFCLOSE

		LEAS	293,S
		JSR	DSKTURNOFFMOTORS

		LDX	#STRDONE
		JSR	STROUTWRAP
		JSR	CROUT

decryptmessagesavemsgdone:
		rts

INPUTSTR
		PSHS	X
inputstrloop
		JSR	KEYIN
		BEQ	inputstrloop
		CMPA	#$08
		BEQ	inputstrbackspace
		CMPA	#$0D
		BEQ	inputstrdone	
		CMPA	#$03
		BEQ	inputstrbreak
		CMPX	#0
		BEQ	inputstrloop
		STA	,U+
		JSR	PUTCHR
		LEAX	-1,X
		JMP	inputstrloop
inputstrbackspace
		CMPX	,S
		BEQ	inputstrloop
		JSR	PUTCHR
		LEAU	-1,U
		LEAX	1,X
		JMP	inputstrloop
inputstrdone	
		CLR	,U
		LEAS	2,S		; get rid of stored length
		RTS
inputstrbreak
		CMPX	,S
		BEQ	inputstrbreakgo
		LEAU	-1,U
		LEAX	1,X
		JMP	inputstrbreak
inputstrbreakgo:
		LDA	#$03
		STA	,U+
		JMP	inputstrdone
		

;input: Source string pointer in U register
;       Destination buffer pointer in Y register
;Return Success ($00) or Failure ($FF) in A register

FORMATFNAME
		PSHS	U,Y,X,B
		CLR	,-S
		LDA	DEFDRV
		STA	,Y+
		LDD	#$200B		; store 11 blanks into filename
formatfnameblank:
		STA	,Y+
		DECB
		BNE	formatfnameblank
		LDY	4,S
		LEAY	1,Y		; increment one char past drvnum
		
		CLRB
formatfnamelengthloop:
		LDA	,U+
		BEQ	formatfnamelengthend
		INCB
		JMP	formatfnamelengthloop
formatfnamelengthend:
		CMPB	#02
		BLO	formatfnameleadingdrivedone
		LDU	6,S
		LDA	1,U
		CMPA	#':
		BNE	formatfnameleadingdrivedone
		LDA	,U
		CMPA	#'0
		BLO	formatfnameleadingdrivedone
		CMPA	#'3
		BHI	formatfnameleadingdrivedone
		BSR	formatfnamegetdrivenum
formatfnameleadingdrivedone:
		INCB
formatfnamegetnextchar
		DECB
		BNE	formatfnameprocesschar
formatfnamecheckfile:
		LDX	4,S
		LEAX	1,X
		PSHS	X
		CMPY	,S++		; if not empty filename
		BNE	formatfnamedone
formatfnamebadfname:
		LDA	#$FF
		JMP	formatfnameerror
formatfnameprocesschar:
		LDA	,U+
		CMPA	#'.
		BEQ	formatfnamegrabext
		CMPA	#'/
		BEQ	formatfnamegrabext
		CMPA	#':
		BEQ	formatfnamepostdrive
		LDX	4,S
		LEAX	9,X
		PSHS	X
		CMPY	,S++
		BEQ	formatfnamebadfname
		BSR	formatfnameaddchar
		BRA	formatfnamegetnextchar
formatfnamepostdrive:
		BSR	formatfnamecheckfilesub
		BSR	formatfnamegetdrivenum
		TSTB
		BNE	formatfnamebadfname
formatfnamedone:
		LDA	#0
formatfnameerror:
		LEAS	1,S	
		PULS	U,Y,X,B,PC

formatfnamegetdrivenum
		COM	2+0,S
		BEQ	formatfnamegdnbadfname
		LDA	,U++
		SUBB	#2
		SUBA	#'0
		BLO	formatfnamegdnbadfname
		CMPA	#$03
		BHI	formatfnamegdnbadfname
		LDX	2+4,S
		STA	,X
		RTS
formatfnamegdnbadfname:
		LEAS	2,S		; fix stack from this subroutine call
		JMP formatfnamebadfname

formatfnamegrabext:
		BSR	formatfnamecheckfilesub
		LDY	4,S
		LEAY	9,Y	
formatfnameextloop:
		DECB
		BEQ	formatfnamedone
		LDA	,U+
		CMPA	#':
		BEQ	formatfnamepostdrive
		LDX	4,S
		LEAX	12,X
		PSHS	X
		CMPY	,S++
		BEQ	formatfnamebadfname
		BSR	formatfnameaddchar
		BRA	formatfnameextloop

formatfnameaddchar:
		STA	,Y+
		BEQ	formatfnamegdnbadfname
		CMPA	#'.
		BEQ	formatfnamegdnbadfname
		CMPA	#'/
		BEQ	formatfnamegdnbadfname
		INCA
		BEQ	formatfnamegdnbadfname
formatfnamerts	RTS

formatfnamecheckfilesub:
		LDX	6,S
		LEAX	1,X
		PSHS	X
		CMPY	,S++		; if not empty filename
		BNE	formatfnamerts
		LEAS	2,S		; clean up stack for error
		JMP 	formatfnamebadfname

ENCRYPTFILE
		TST	PUBKEYLOADED
		BNE	encryptfilekeyloaded
		LDX	#STRNOPUBKEY
		JSR	STROUTWRAP
		JSR	CROUT
		RTS
encryptfilekeyloaded:

		LEAS	-293,S

		LDX	#STRINFORMLIMIT
		JSR	STROUTWRAP
		JSR	CROUT	
	
encryptfilegetfname:
		LDX	#STRENTERNAME
		JSR	STROUTWRAP
		LEAU	12,S
		LDX	#14
		JSR	INPUTSTR
		TFR	S,Y
		LEAU	12,S
		LDA	,U
		CMPA	#$03
		BEQ	encryptfileerror
		JSR	FORMATFNAME	
		TSTA
		BNE	encryptfilegetfname

		JSR	CROUT

		LDA	,S
		LEAX	1,S
		LEAU	26,S
		PSHS	A
		PSHS	X
		CLRA			;open as read
		PSHS	A
		PSHS	U
		JSR	DSKFOPEN	
		TSTA
		BNE	encryptfileerror

		LEAU	26,S
		LDX	#HEAP
		LDD	PUBKEYLENGTH
		PSHS	U,X,D
		JSR	DSKFREAD
		PSHS	D

		LEAU	2+26,S	
		PSHS	U
		JSR	DSKFCLOSE

		JSR	DSKTURNOFFMOTORS

		LDD	,S
		LDU	#HEAP
		LEAU	D,U	
		LDD	PUBKEYLENGTH
		SUBD	,S++
		TFR	D,X
		LEAS	293,S

		JMP	encryptmessageloadfromheap

encryptfileerror

		LEAS	293,S
		RTS

DECRYPTFILE	
		TST	PRIVKEYLOADED
		BNE	decryptkeyloaded
		LDX	#STRNOPRIVKEY
		JSR	STROUTWRAP
		JSR	CROUT
		RTS
decryptkeyloaded:

		LEAS	-293,S

decryptfilegetfname:
		LDX	#STRENTERNAME
		JSR	STROUTWRAP
		LEAU	12,S
		LDX	#14
		JSR	INPUTSTR
		TFR	S,Y
		LEAU	12,S
		LDA	,U
		CMPA	#$03
		BEQ	encryptfileerror
		JSR	FORMATFNAME	
		TSTA
		BNE	decryptfilegetfname

		JSR	CROUT

		LDA	,S
		LEAX	1,S
		LEAU	26,S
		PSHS	A
		PSHS	X
		CLRA			;open as read
		PSHS	A
		PSHS	U
		JSR	DSKFOPEN	
		TSTA
		BNE	encryptfileerror

		LEAU	26,S
		LDX	#HEAP
		LDD	PRIVKEYLENGTH
		PSHS	U,X,D
		JSR	DSKFREAD
		PSHS	D

		LEAU	2+26,S	
		PSHS	U
		JSR	DSKFCLOSE

		JSR	DSKTURNOFFMOTORS

		LDY	#rsac
		LDX	PRIVKEYLENGTH2
decryptfileclearcloop:
		CLR	,Y+
		LEAX	-1,X
		BNE	decryptfileclearcloop

		LDU	#HEAP
		LDY	#rsac
		PULS	D
		TFR	D,X
		LEAU	D,U
	
decryptfilecopyloop:	
		LDA	,-U
		CLR	,U
		STA	,Y+
		LEAX	-1,X
		BNE	decryptfilecopyloop

		LEAS	293,S
		JMP	DECRYPTMESSAGE

LOADPRIVKEY
		LEAS	-293,S

loadprivkeygetfname:
		LDX	#STRPRIVKEYFNAME
		JSR	STROUTWRAP
		LEAU	12,S
		LDX	#14
		JSR	INPUTSTR

		JSR	CROUT

		LDA	12,S
		BNE	loadprivkeynotdefault

		LDY	#DEFPRIVKEYFNAME
		LEAU	12,S
loadprivkeycopydeffname:
		LDA	,Y+
		STA	,U+
		BNE	loadprivkeycopydeffname

loadprivkeynotdefault:

		CMPA	#$03
		LBEQ	loadkeyfileerror

		TFR	S,Y
		LEAU	12,S
		JSR	FORMATFNAME	
		TSTA
		BNE	loadprivkeygetfname


		LDA	,S
		LEAX	1,S
		LEAU	26,S
		PSHS	A
		PSHS	X
		CLRA			;open as read
		PSHS	A
		PSHS	U
		JSR	DSKFOPEN	
		TSTA
		LBNE	loadkeyfileerror

		LEAU	26,S
		LDX	#HEAP+2
		TFR	S,D
		SUBD	#HEAP+6 ; max size is stack minus heap minus 4 bytes
		PSHS	U,X,D
		JSR	DSKFREAD
		PSHS	D	; push size read onto stack
		ADDD	#HEAP+2
		STD	HEAP	; store end pointer at beginning of HEAP

		LEAU	2+26,S	
		PSHS	U
		JSR	DSKFCLOSE

		JSR	DSKTURNOFFMOTORS

		LDU	#privkeystart
		LDX	#privkeylen
loadprivkeyclearkey:
		CLR	,U+
		LEAX	-1,X
		BNE	loadprivkeyclearkey

		LDU	#HEAP+2
		CMPU	HEAP
		LBGT	loadkeyloaderror	; reading past file read
		LDA	,U+
		CMPA	#$30
		LBNE	loadkeyloaderror
		JSR	ASN1GETSIZE

		;privkey version load
		CMPU	HEAP
		LBGT	loadkeyloaderror	; reading past file read
		LDA	,U+	
		CMPA	#$02
		LBNE	loadkeyloaderror
		JSR	ASN1GETSIZE
		TFR	D,X
loadprivkeyverloop:
		CMPU	HEAP
		LBGT	loadkeyloaderror	; reading past file read
		LDA	,U+
		LEAX	-1,X
		BNE	loadprivkeyverloop

		; N load
		CMPU	HEAP
		LBGT	loadkeyloaderror	; reading past file read
		LDA	,U+	
		CMPA	#$02
		LBNE	loadkeyloaderror
		JSR	ASN1GETSIZE
		TFR	D,X
		LDY	#privrsan
		LEAY	D,Y
		TST	,U
		BNE	loadprivkeynotleading0
		SUBD	#1
loadprivkeynotleading0
		CMPD	#MPLEN/2
		LBGT	loadkeyloaderror
		STD	PRIVKEYLENGTH
		ANDCC	#$FE		; multiply by two by shifting
		ROLB
		ROLA
		STD	PRIVKEYLENGTH2
loadprivkeynloop:
		CMPU	HEAP
		LBGT	loadkeyloaderror	; reading past file read
		LDA	,U+
		STA	,-Y
		LEAX	-1,X
		BNE	loadprivkeynloop

		; E load
		CMPU	HEAP
		LBGT	loadkeyloaderror	; reading past file read
		LDA	,U+	
		CMPA	#$02
		LBNE	loadkeyloaderror
		JSR	ASN1GETSIZE
		TFR	D,X
		LDY	#privrsae
		LEAY	D,Y
loadprivkeyeloop:
		CMPU	HEAP
		LBGT	loadkeyloaderror	; reading past file read
		LDA	,U+
		STA	,-Y
		LEAX	-1,X
		BNE	loadprivkeyeloop

		; D load
		CMPU	HEAP
		LBGT	loadkeyloaderror	; reading past file read
		LDA	,U+	
		CMPA	#$02
		LBNE	loadkeyloaderror
		JSR	ASN1GETSIZE
		TFR	D,X
		LDY	#rsad
		LEAY	D,Y
loadprivkeydloop:
		CMPU	HEAP
		LBGT	loadkeyloaderror	; reading past file read
		LDA	,U+
		STA	,-Y
		LEAX	-1,X
		BNE	loadprivkeydloop

		; P load
		CMPU	HEAP
		LBGT	loadkeyloaderror	; reading past file read
		LDA	,U+	
		CMPA	#$02
		LBNE	loadkeyloaderror
		JSR	ASN1GETSIZE
		TFR	D,X
		LDY	#rsap+1
		PSHS	D
		LDA	D,Y
		BNE	loadprivkeypnoleading0	
		PULS	D
		SUBD	#1
		JMP	loadprivkeypready
loadprivkeypnoleading0:
		PULS	D
loadprivkeypready:
		STD	PLENGTH
		LEAY	D,Y
loadprivkeyploop:
		CMPU	HEAP
		LBGT	loadkeyloaderror	; reading past file read
		LDA	,U+
		STA	,-Y
		LEAX	-1,X
		BNE	loadprivkeyploop

		; Q load
		CMPU	HEAP
		LBGT	loadkeyloaderror	; reading past file read
		LDA	,U+	
		CMPA	#$02
		LBNE	loadkeyloaderror
		JSR	ASN1GETSIZE
		TFR	D,X
		LDY	#rsaq+1

		PSHS	D
		LDA	D,Y
		BNE	loadprivkeyqnoleading0	
		PULS	D
		SUBD	#1
		JMP	loadprivkeyqready
loadprivkeyqnoleading0:
		PULS	D
loadprivkeyqready:
		CMPD	PLENGTH			; store new plength is bigger
		BHI	loadprivkeycmpplength  ; than what earlier P prime was
		STD	PLENGTH
loadprivkeycmpplength:
		LEAY	D,Y
loadprivkeyqloop:
		CMPU	HEAP
		BGT	loadkeyloaderror	; reading past file read
		LDA	,U+
		STA	,-Y
		LEAX	-1,X
		BNE	loadprivkeyqloop

		; dp load
		CMPU	HEAP
		BGT	loadkeyloaderror	; reading past file read
		LDA	,U+	
		CMPA	#$02
		BNE	loadkeyloaderror
		JSR	ASN1GETSIZE
		TFR	D,X
		LDY	#rsadp
		LEAY	D,Y
loadprivkeydploop:
		CMPU	HEAP
		BGT	loadkeyloaderror	; reading past file read
		LDA	,U+
		STA	,-Y
		LEAX	-1,X
		BNE	loadprivkeydploop

		; dq load
		CMPU	HEAP
		BGT	loadkeyloaderror	; reading past file read
		LDA	,U+	
		CMPA	#$02
		BNE	loadkeyloaderror
		JSR	ASN1GETSIZE
		TFR	D,X
		LDY	#rsadq
		LEAY	D,Y
loadprivkeydqloop:
		CMPU	HEAP
		BGT	loadkeyloaderror	; reading past file read
		LDA	,U+
		STA	,-Y
		LEAX	-1,X
		BNE	loadprivkeydqloop

		; qinv load
		CMPU	HEAP
		BGT	loadkeyloaderror	; reading past file read
		LDA	,U+	
		CMPA	#$02
		BNE	loadkeyloaderror
		JSR	ASN1GETSIZE
		TFR	D,X
		LDY	#rsaqinv
		LEAY	D,Y
loadprivkeyqinvloop:
		CMPU	HEAP
		BGT	loadkeyloaderror	; reading past file read
		LDA	,U+
		STA	,-Y
		LEAX	-1,X
		BNE	loadprivkeyqinvloop

		LDA	#$FF
		STA	PRIVKEYLOADED

		JMP	loadkeyloaddone
loadkeyloaderror:
		LDX	#STRBADKEYFILE
		JSR	STROUTWRAP
		JSR	CROUT	
loadkeyloaddone:
		;clear file read into memory here
		PULS	X
		LEAX	2,X
		LDU	#HEAP
loadkeyclearheaploop:
		CLR	,U+
		LEAX	-1,X
		BNE	loadkeyclearheaploop

		LEAS	293,S

		JMP	loadkeydone
loadkeyfileerror:
		LEAS	293,S
		LDX	#STRFOPENERROR
		JSR	STROUTWRAP
		JSR	CROUT
loadkeydone:
		rts

;input: U register with pointer to buffer to write
;       Y register with MP INT pointer
;       D length of MP
;output: U register with pointer to end of buffer
ASN1OUTMPBINT
	PSHS	Y,X,D
	TFR	D,X
	LEAY	D,Y
asn1outmpintfindfront:
	LDA	,-Y
	BNE	asn1outmpintfoundfront
	LEAX	-1,X
	BNE	asn1outmpintfindfront
	LDX	#1	; if length and int is 0, set length to 1
asn1outmpintfoundfront:
	BITA	#$80
	BEQ	asn1outmpintnotleadingbit
	LEAY	1,Y
	LEAX	1,X
asn1outmpintnotleadingbit:	
	LDA	#$02
	STA	,U+
	TFR	X,D
	JSR	ASN1SETSIZE
	LDA	,Y
	STA	,U+
	LEAX	-1,X
asn1outmpintloop:
	LDA	,-Y	
	STA	,U+
	LEAX	-1,X
	BNE	asn1outmpintloop
	PULS	Y,X,D,PC

ASN1SETSIZE
		CMPD	#127
		BCS	asn1setsizeunder128
		CMPD	#255
		BCS	asn1setsizeunder256
		PSHS	D
		LDA	#$82
		STA	,U+
		PULS	D
		STD	,U++
		RTS
asn1setsizeunder256:
		LDA	#$81
		STA	,U+
		STB	,U+
		RTS
asn1setsizeunder128:
		STB	,U+
		RTS

ASN1GETSIZE
		LDB	,U+
		BITB	#$80
		BNE	asn1getsizegt128
		CLRA
		JMP	asn1getsizedone
asn1getsizegt128
		ANDB	#$7F
		BEQ	asn1getsizeerror
		CMPB	#1
		BGT	asn1getsizegt1
		CLRA
		LDB	,U+
		JMP	asn1getsizedone
asn1getsizegt1
		CMPB	#2
		BGT	asn1getsizeerror	; can only handle up to 2 bytes
		LDD	,U++	
		JMP	asn1getsizedone
asn1getsizeerror:
		LDD	#0	
asn1getsizedone:
		RTS


LOADPUBKEY
		LEAS	-293,S

loadpubkeygetfname:
		LDX	#STRPUBKEYFNAME
		JSR	STROUTWRAP
		LEAU	12,S
		LDX	#14
		JSR	INPUTSTR

		JSR	CROUT

		LDA	12,S
		BNE	loadpubkeynotdefault

		LDY	#DEFPUBKEYFNAME
		LEAU	12,S
loadpubkeycopydeffname:
		LDA	,Y+
		STA	,U+
		BNE	loadpubkeycopydeffname

loadpubkeynotdefault:

		CMPA	#$03
		LBEQ	loadkeyfileerror

		TFR	S,Y
		LEAU	12,S
		JSR	FORMATFNAME	
		TSTA
		BNE	loadpubkeygetfname

		LDA	,S
		LEAX	1,S
		LEAU	26,S
		PSHS	A
		PSHS	X
		CLRA			;open as read
		PSHS	A
		PSHS	U
		JSR	DSKFOPEN	
		TSTA
		LBNE	loadkeyfileerror

		LEAU	26,S
		LDX	#HEAP+2
		TFR	S,D
		SUBD	#HEAP+6 ; max size is stack minus heap minus 6 bytes
		PSHS	U,X,D
		JSR	DSKFREAD
		PSHS	D	; push size read onto stack
		ADDD	#HEAP+2
		STD	HEAP	; store end pointer at beginning of HEAP

		LEAU	2+26,S	
		PSHS	U
		JSR	DSKFCLOSE

		JSR	DSKTURNOFFMOTORS

		LDU	#pubkeystart
		LDX	#pubkeylen
loadpubkeyclearkey:
		CLR	,U+
		LEAX	-1,X
		BNE	loadpubkeyclearkey

		LDU	#HEAP+2
		CMPU	HEAP
		LBGT	loadkeyloaderror	; reading past file read
		LDA	,U+
		CMPA	#$30
		LBNE	loadkeyloaderror
		JSR	ASN1GETSIZE

		LDY	#pubheader
		LDX	#pubheaderlength
loadpubkeyheaderloop:
		CMPU	HEAP
		LBGT	loadkeyloaderror	; reading past file read
		LDA	,U+
		CMPA	,Y+
		LBNE	loadkeyloaderror
		LEAX	-1,X
		BNE	loadpubkeyheaderloop

		CMPU	HEAP
		LBGT	loadkeyloaderror	; reading past file read
		LDA	,U+
		CMPA	#$03
		LBNE	loadkeyloaderror
		JSR	ASN1GETSIZE
		CMPU	HEAP
		LBGT	loadkeyloaderror	; reading past file read
		LDA	,U+
		CMPA	#$00
		LBNE	loadkeyloaderror
		CMPU	HEAP
		LBGT	loadkeyloaderror	; reading past file read
		LDA	,U+
		CMPA	#$30
		LBNE	loadkeyloaderror
		JSR	ASN1GETSIZE

		CMPU	HEAP
		LBGT	loadkeyloaderror	; reading past file read
		LDA	,U+
		CMPA	#$02
		LBNE	loadkeyloaderror
		JSR	ASN1GETSIZE
		
		TFR	D,X
		LDY	#pubrsan
		LEAY	D,Y
		TST	,U
		BNE	loadpubkeynotleading0
		SUBD	#1
loadpubkeynotleading0
		CMPD	#MPLEN/2
		LBGT	loadkeyloaderror
		STD	PUBKEYLENGTH
		ANDCC	#$FE		; multiply by two by shifting
		ROLB
		ROLA
		STD	PUBKEYLENGTH2
loadpubkeynloop:
		CMPU	HEAP
		LBGT	loadkeyloaderror	; reading past file read
		LDA	,U+
		STA	,-Y
		LEAX	-1,X
		BNE	loadpubkeynloop

		CMPU	HEAP
		LBGT	loadkeyloaderror	; reading past file read
		LDA	,U+
		CMPA	#$02
		LBNE	loadkeyloaderror
		JSR	ASN1GETSIZE

		TFR	D,X
		LDY	#pubrsae
		LEAY	D,Y
loadpubkeyeloop:
		CMPU	HEAP
		LBGT	loadkeyloaderror	; reading past file read
		LDA	,U+
		STA	,-Y
		LEAX	-1,X
		BNE	loadpubkeyeloop

		LDA	#$FF
		STA	PUBKEYLOADED

		JMP	loadkeyloaddone

COPYPRIVTOPUB
		TST	PRIVKEYLOADED
		BNE	copyprivtopubkeyloaded
		LDX	#STRNOPRIVKEY
		JSR	STROUTWRAP
		JSR	CROUT
		RTS
copyprivtopubkeyloaded:

		LDX	#STRPRIVTOPUB
		JSR	STROUTWRAP
		LDX	PRIVKEYLENGTH2
		STX	PUBKEYLENGTH2
		LDU	#privrsan
		LDY	#pubrsan
copyprivtopubnloop:
		LDA	,U+
		STA	,Y+
		LEAX	-1,X
		BNE	copyprivtopubnloop

		LDX	PRIVKEYLENGTH2
		LDU	#privrsae
		LDY	#pubrsae
copyprivtopubeloop:
		LDA	,U+
		STA	,Y+
		LEAX	-1,X
		BNE	copyprivtopubeloop

		LDD	PRIVKEYLENGTH
		STD	PUBKEYLENGTH

		LDA	PRIVKEYLOADED
		STA	PUBKEYLOADED
		LDX	#STRDONE
		JSR	STROUTWRAP
		JSR	CROUT
		RTS

PRIVKEYLOADED	rmb	1
PUBKEYLOADED	rmb	1
PLENGTH		rmd	1	length of prime in bytes
PUBKEYLENGTH	rmd	1	length of key in bytes
PRIVKEYLENGTH	rmd	1	length of key in bytes
PUBKEYLENGTH2	rmd	1	double keylength, needed for multiplication
PRIVKEYLENGTH2	rmd	1	double keylength, needed for multiplication

dbstart:
;public key
pubkeystart:
pubrsae		rmb	MPLEN
pubrsan		rmb	MPLEN
pubkeyend:
pubkeylen	EQU	pubkeyend-pubkeystart
;private key
privkeystart:
rsap		rmb	MPLEN
rsaq		rmb	MPLEN
rsad		rmb	MPLEN
rsatot		rmb	MPLEN
privrsan	rmb	MPLEN
privrsae	rmb	MPLEN
rsadp		rmb	MPLEN
rsadq		rmb	MPLEN
rsaqinv		rmb	MPLEN
privkeylen	EQU	privkeyend-privkeystart
privkeyend:
rsam		rmb	MPLEN
rsac		rmb	MPLEN
dbend:
dblen		EQU	dbend-dbstart
STRGENERATING	fcc	"Generating primes. Hold a key for a few seconds to see percentile completion of the likely range for a prime."
		fcb	CR,0		
STRNOPRIVKEY	fcn	"No private key in memory. Either generate a key or load a private key."
STRNOPUBKEY	fcn	"No public key in memory. Either generate a key or load a public key."
STRSAVEYN	fcn	"Save to disk? (Y/N)"
STRENTERNAME	fcn	"Enter filename: "
STRQ		fcn	"Q Prime: "
STRP		fcn	"P Prime: "
STRN		fcn	"Public Key Modulus: "
STRTOT		fcn	"Totient: "
STRE		fcn	"Public Key Exponent: "
STRD		fcn	"Private Key: "
STRDQ		fcn	"DQ: "
STRDP		fcn	"DP: "
STRQINV		fcn	"QInv: "
STRENTERMESSAGE	fcn	"Enter message to encrypt. This is limited to the same length as the public key:"
STRM		fcn	"Message: "
STRC		fcn	"Ciphertext: "
STRMD		fcc	"This may take a while."
		fcb	CR
		fcn	"Decrypted: "
COPYINGFNAME	fcc	"COPYING    " ;11 bytes, spaces for null
PRIVKEYFNAME	rmb	12
PUBKEYFNAME	rmb	12
DEFPRIVKEYFNAME	fcn	"PRIVKEY.DER"
DEFPUBKEYFNAME	fcn	"PUBKEY.DER"
STRSTART	fcc	"     Color Computer RSA"
		fcb	CR	
		fcc	"Copyright (C) 2022 Don Barber"
		fcb	CR,CR
		fcc	"THIS PROGRAM COMES WITH ABSOLUTELY NO WARRANTY."
		fcb	CR,CR
		fcc	"This is free software, and you are welcome to redistribute it under certain conditions; select 'Show license' at the menu for details."
		fcb	CR,CR
STRHITKEY	fcc	"Hit any key to continue."
		fcb	0

menutable:	
		fdb	GENERATEKEY
		fdb	LOADPRIVKEY
		fdb	LOADPUBKEY
		fdb	COPYPRIVTOPUB
		fdb	ENCRYPTMESSAGE
		fdb	ENCRYPTFILE
		fdb	DECRYPTFILE
		fdb	SHOWLICENSE
		fdb	EXIT

STRMAINMENU	fcc	"Select a function:"
		fcb	CR
		fcc	"0) Generate and save public-private keypair"
		fcb	CR	
		fcc	"1) Load new private key from disk"
		fcb	CR
		fcc	"2) Load new public key from disk"
		fcb	CR
		fcc	"3) Copy private key to public key"
		fcb	CR
		fcc	"4) Encrypt message"
		fcb	CR
		fcc	"5) Encrypt file"
		fcb	CR
		fcc	"6) Decrypt file"
		fcb	CR
		fcc	"7) Show license"
		fcb	CR
		fcc	"8) Exit program"
		fcb	CR,0
STRGENCHOICE	fcc	"Choose Key Length:"
		fcb	CR	
		fcc	"0) 32 bits/4 bytes (seconds)"
		fcb	CR	
		fcc	"1) 64 bits/8 bytes"
		fcb	CR	
		fcc	"2) 128 bits/16 bytes (minutes)"
		fcb	CR	
		fcc	"3) 256 bits/32 bytes"
		fcb	CR	
		fcc	"4) 512 bits/64 bytes (hours)"
		fcb	CR
		fcc	"5) 1024 bits/128 bytes (days)"
		fcb	CR
		fcc	"6) 1536 bits/192 bytes"
		fcb	CR
		fcc	"7) 2048 bits/256 bytes (weeks)"
		;fcb	CR
		;fcc	"8) 3072 bits/384 bytes"
		;fcb	CR
		;fcc	"9) 4096 bits/512 bytes (months)"
		fcb	CR,0
STRYOUCHOSE	fcn	"You chose: "
STRSAVING	fcn	"Saving key to disk..."
STRDONE		fcn	"Done!"
STRPUBKEYFNAME	fcn	"Enter Public Key filename (enter for default PUBKEY.DER): "
STRPRIVKEYFNAME	fcn	"Enter Private Key filename (enter for default PRIVKEY.DER): "
STRINFORMLIMIT	fcn	"The message size is limited to the size of the key. If the message is shorter than the key, it is padded with null bytes."
STRFOPENERROR	fcn	"Error opening file."
STRSAVEMSGYN	fcn	"Save message to disk? (Y/N)"
STRDISPMSGYN	fcn	"Display message? (Y/N) Warning: this may not be valid text."
STRSAVEERROR	fcn	"Error saving. Bad or full disk?"
STRPRIVTOPUB	fcn	"Copying private key to public key..."
STRBADKEYFILE	fcn	"Bad key file format or key too big."
STRPROVIDERAND	fcn	"Need to collect entropy for prime key generation. Please enter random keyboard input until the counter reaches 0: "
choicearray	fdb	2,4,8,16,32,64,96,128,192,256	; size of prime
							; will be shifted to get
							; size of key
primestatarray	fdb	11,22,44,89,177,355,532,710,1064,1420
primestat	rmd	1

pubheader		fcb	$30,$0d,$06,$09,$2a,$86,$48,$86,$f7,$0d,$01,$01,$01,$05,$00
pubheaderlength	SET	15
coco3flag	rmb	1

		include sub/IO.s
		include	sub/MPBREM.s
		include	sub/MPBMUL.s
		include	sub/MPBDIV.s
		include	leventhal/MPBADD.s
		include	leventhal/MPBSUB.s
		include	leventhal/BN2HEX.s
		include	leventhal/BN2DEC.s
		include	sub/MPBPRIME.s
		include	sub/MPBEGCD.s
		include	sub/MPBMODEXP.s
		include	sub/RANDOM.s
		include	sub/DSKIO.s
heaplength	rmd	1
HEAP
		end	start

