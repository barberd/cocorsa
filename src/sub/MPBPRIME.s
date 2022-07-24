; Prime number Generator 
; first test for primality by naive modulus on several small primes
; then move on to using Miller-Rabin method
; adapted from pseudocode available at
; https://en.wikipedia.org/wiki/Miller%E2%80%93Rabin_primality_test

; This file is part of Color Computer RSA by Don Barber Copyright 2022

; Color Computer RSA is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

; Color Computer RSA is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along with Color Computer RSA. If not, see <https://www.gnu.org/licenses/>.

IRQVEC		SET	$010C

MPBNEXTPRIME       
		ldx	4,S		;make sure is odd
		lda	,x
		ora     #1
		sta	,x
		ldd	#0			; initialize counter
		std	mpbnextprimenum		; for showing % complete
						; within likely range
		clr	PIA0+2			; set up irq vectors
		ldx	IRQVEC+1		; so every timer fires
		stx	mpbnextprimeirq		; calls MPBPRIMESTAT
		ldx	#MPBPRIMESTAT
		stx	IRQVEC+1
mpbnextprimeloop  	
		ldd	mpbnextprimenum		; increment counter for stats
		addd	#1
		std	mpbnextprimenum

		lda	#'.			; output a . to show progress
		jsr	PUTCHR

		ldy	4,S			; check to see if current
		ldd	2,S			; is prime
		pshs	y,d
		jsr	MPBISPRIME
		beq	mpbnextprimedone

		ldy	4,S			; its not prime
		ldx	2,S 			; so increment by 2
		lda	,y
                adda    #2
		sta	,y+
		bcc	mpbnextprimeloop
		leax	-1,x
		beq	mpbnextprimeloop   	;must only be 1 byte long?
mpbnpaddloop					;ripple carry through
		lda	,y
		adda	#1
		sta	,y+
		bcc	mpbnextprimeloop
		leax	-1,x
		bne	mpbnpaddloop
                bcc     mpbnextprimeloop
					;if got here, its because it overflowed.
	  	lda	#$B6		;so set highest byte to B6
		sta	,-y		;rest should be 0 (lsb is 1) and cont
                bra     mpbnextprimeloop

mpbnextprimedone   
		jsr	CROUT
		ldx	mpbnextprimeirq		; clean up irq vectors
		stx	IRQVEC+1		; to remove MPBPRIMESTAT
		ldu	,s
		leas	6,s
		jmp	,u
mpbnextprimenum	rmd	1
mpbnextprimeirq	rmd	1

MPBPRIMESTAT
		#LDA	PIA0+3
		#BPL	mpbprimestatfin
		dec	counter
		BNE	mpbprimestatfin
		com	counter		;only checks every 4.25 (255/60) seconds
		lda	PIA0		;check if key is down
		#jsr	KEYIN		
		#cmpa	#3
		coma
		bne	mpbprimestatshow
		jmp	mpbprimestatfin
mpbprimestatshow:
		LEAS	-12,S
		ldd	#$6400			; multiply status count
		pshs	d			; by 100 ($64)
		LDD	mpbnextprimenum
		exg	a,b
		pshs	d
		leax	2,s
		pshs	x
		leax	2,s
		pshs	x
		LEAX	8,S
		pshs	x
		ldx	#2
		pshs	x
		jsr	MPBMULU
		LEAS	4,S			pull off num and $64

		TFR	S,X
		pshs	x
		ldd	primestat
		leax	6,S
		stb	,x
		sta	1,x
		clr	2,x
		clr	3,x
		pshs	x
		leax	4,x
		pshs	x
		ldd	#0
		pshs	d
		ldd	#4
		pshs	d
		jsr	MPBDIV
		ldd	8,S
		exg	a,b
		TFR	S,X
		jsr	BN2DEC
		leax	,s
		jsr	STROUT
		lda	#'%
		jsr	PUTCHR
		LEAS	12,S
		

		#ldx	#mpbnextprimenum
		#ldd	#2
		#jsr	BNHEXOUT
		#lda	#'/
		#jsr	PUTCHR
		#ldx	#primestat
		#ldd	#2
		#jsr	BNHEXOUT
mpbprimestatfin	ldx	mpbnextprimeirq
		jmp	,x
counter		rmb	1

MPBISPRIME				
					; first test divide small primes
					; Then try Miller-Rabin algorithm
					; for testing pseudoprime
					; makes assumption that input N
					; is odd!

SIZE	SET	2*MPLEN+10 ; value   use ld
PTRN	SET	2*MPLEN+12 ; pointer use ld
VARN1	SET	0	  ; buffer  use lea
VARX	SET	MPLEN/2     ; buffer  use lea
VARA	SET	MPLEN   ; buffer  use lea
VARD	SET	3*MPLEN/2	  ; buffer use lea
VARR	SET	2*MPLEN ; value use ld
VARRT	SET	2*MPLEN+2 ; value use ld	
VARK	SET	2*MPLEN+4 ; value use ld	
VARBL	SET	2*MPLEN+6 ; value use ld	byte length of prime

			LEAS	-(2*MPLEN+8),S
			
			;clear vara
			leay	VARA,S
			ldx	SIZE,S
			clra
mpbisprimeclraloop	sta	,y+
			leax	-1,x
			bne	mpbisprimeclraloop

			ldd	#PRIMELISTLENGTH
			std	VARK,S

mpbisprimesmallprloop	
			ldx	#SMALLPRIMELIST
			leay	VARA,S
			ldd	VARK,S
			subd	#2

			ldd	d,x
			std	,y

			;ldx	PTRN,S
			;ldd	SIZE,S
			;jsr	BNHEXOUT
			;jsr	CROUT
			;leax	VARA,S
			;ldd	SIZE,S
			;jsr	BNHEXOUT
			;jsr	CROUT
			;jsr	WAITKEY

			;lda	#'*
			;jsr	PUTCHR

			ldu	PTRN,S
			;y is still VARA
			leax	VARX,S
			ldd	SIZE,S
			pshs	u,y,x,d
			jsr	MPBREM

			;ldx	PTRN,S
			;ldd	SIZE,S
			;jsr	BNHEXOUT
			;jsr	CROUT
			;leax	VARA,S
			;ldd	SIZE,S
			;jsr	BNHEXOUT
			;jsr	CROUT
			;leax	VARX,S
			;ldd	SIZE,S
			;jsr	BNHEXOUT
			;jsr	CROUT
			;jsr	WAITKEY
			;jsr	CROUT
			;jsr	CROUT


			ldx	#2		;check remainder in VARX
						;size must be 2 bytes or smaller
						;as this is length of
						;SMALLPRIMELIST entries
	
			leau	VARX,S
			lda	,u+
			bne	mpbisprimesmallprnext
			lda	,u
			bne	mpbisprimesmallprnext
			bra	mpbisprimefoundsmall ; entire remainder is 0!
mpbisprimesmallprnext	
			ldd	VARK,S
			subd	#2
			std	VARK,S
			bne	mpbisprimesmallprloop
			bra	mpbisprimesmallprend ; made it through
						     ; all small primes

mpbisprimefoundsmall	
			andcc	#%11111011	; clear z flag as found factor
			;andcc	#$FB	; clear z flag as found factor
			lbra	mpbisprimedone
mpbisprimesmallprend			

			ldu	PTRN,S
			leay	VARN1,S
			ldx	SIZE,S
mpbisprimeinitn1loop	lda	,u+
			sta	,y+
			leax	-1,x
			bne	mpbisprimeinitn1loop
			
			leax	VARN1,S	#N is odd, so remove to get N1=N-1
			lda	,x
			anda	#$FE
			sta	,x

			leau	VARN1,S		; copy N1 to D
			leay	VARD,S
			ldx	SIZE,S
mpbisprimeinitdloop	lda	,u+
			sta	,y+
			leax	-1,x
			bne	mpbisprimeinitdloop

			ldd	#0		;r=0
			std	VARR,S
mpbisprimefindd		leay	VARD,S
			ldx	SIZE,S
			tfr	x,d
			leay	d,y
			ANDCC   #$FE
mpbisprimerordloop	ror	,-y
			leax	-1,x
			bne	mpbisprimerordloop
			ldd	VARR,S		;increment R for every pow of 2
			addd	#1
			std	VARR,S
			lda	,y
			anda	#$1
			beq	mpbisprimefindd

			ldd	VARR,S		;r=r-1
			subd	#1		
			std	VARR,S

			ldd	#6		;k=6
			std	VARK,S

			leay	VARN1,S
			ldx	SIZE,S
			tfr	x,d
			leay	d,y
mpbisprimen1sbcount	tst	,-y
			bne	mpbisprimen1sbcountdone
			subd	#1
			leax	-1,x
			bne	mpbisprimen1sbcount	
mpbisprimen1sbcountdone	
			std	VARBL,S

mpbisprimewitnessloop

			lda	#'+
			jsr     PUTCHR


mpbisprimefilla
			ldx	VARBL,S
			leay	VARA,S

mpbisprimefillaloop	jsr	RANDOM	; fill d with random bits
			cmpx	#1
			bne	mpbisprimefillanotone  ; if requesting
			sta	,y                     ; an odd number of bytes
			bra	mpbisprimefilladone
mpbisprimefillanotone	std	,y++
			leax	-2,x
			bne	mpbisprimefillaloop	
mpbisprimefilladone

			leau	VARA,S
			leay	VARN1,S
			ldx	VARBL,S
			tfr	x,d
			leau	d,u
			leay	d,y
mpbisprimecmpanloop	lda	,-u
			cmpa	,-y
			bhi	mpbisprimefilla	; A>N1 so find new a
			blo	mpbcmpandone	; A<N1 so keep going
						; else A=N1 (so far) keep
						; looping to next byte
			leax	-1,x
			bne	mpbisprimecmpanloop
			bra	mpbisprimefilla	; A=N1 so find new a
mpbcmpandone			

			leay	VARA,S        	; VARX=(VARA^VARD)%PTRN
			leax	VARD,S		; RESULT=(BASE^EXP)%MODULUS
			pshs	y,x
			ldy	4+PTRN,S
			leax	4+VARX,S
			ldd	4+SIZE,S
			pshs	y,x,d
			jsr	MPBMODEXP

			leay	VARX,S		; check if X is 1
			ldx	SIZE,S
			lda	,Y+
			cmpa	#1		; check first byte for 1
			bne	mpbisprimexnotone
			leax	-1,x
mpbcheckxloop		lda	,Y+		
			bne	mpbisprimexnotone ; check remaining bytes for 0
			leax	-1,x
			bne	mpbcheckxloop
			lbra	mpbisprimecontwitness
mpbisprimexnotone


			leau	VARX,S
			leay	VARN1,S
			ldx	SIZE,S
mpbisprimecmpn1loop	lda	,u+
			cmpa	,y+
			bne	mpbisprimenotn1		; if X!=N1, bail
			leax	-1,x
			bne	mpbisprimecmpn1loop
			lbra	mpbisprimecontwitness 	; X=N1 for all bytes
							; go to next iteration
mpbisprimenotn1

			LEAS	-(MPLEN/2),S	
			ldd	MPLEN/2+VARR,S
			std	MPLEN/2+VARRT,S
			lbeq	mpbisprimerloopend	
mpbisprimerloop

			LEAU	MPLEN/2+VARX,S
			TFR	U,Y
			TFR	S,X		;tempx = x*x
			LDD	MPLEN/2+SIZE,S
			LSRA
			RORB
			PSHS	U,Y,X,D
			JSR	MPBMULU
			TFR	S,U
			LDY	MPLEN/2+PTRN,S varx = tempx % ptrn
			LEAX	MPLEN/2+VARX,S
			LDD	MPLEN/2+SIZE,S
			PSHS	U,Y,X,D
			JSR	MPBREM

			;LEAY	,S
			;LDX	MPLEN/2+PTRN,S ; tempx=tempx/N
			;LDD	MPLEN/2+SIZE,S
			;PSHS	Y,X,D
			;JSR	MPBDIV	

			;LEAY	MPLEN/2+VARX,S	; copy remainder(ptr in reg u) 
						; over varx
			;LDX	MPLEN/2+SIZE,S  ; so x=x^2%n
mpbisprimecpyxmodn	;LDA	,U+
			;STA	,Y+
			;LEAX	-1,X
			;BNE	mpbisprimecpyxmodn

			LEAY	MPLEN/2+VARX,S
			LEAU	MPLEN/2+VARN1,S
			LDX	MPLEN/2+SIZE,S
mpbisprimexn1cmploop	LDA	,Y+
			CMPA	,U+
			BNE	mpbisprimexn1cmpdone
			LEAX	-1,X
			BNE	mpbisprimexn1cmploop
			;x=n1 so remove temp vars and continue
			LEAS	MPLEN/2,S	
			BRA	mpbisprimecontwitness
mpbisprimexn1cmpdone

			LDD	MPLEN/2+VARRT,S
			SUBD	#1
			STD	MPLEN/2+VARRT,S
			LBNE	mpbisprimerloop
mpbisprimerloopend
			LEAS	MPLEN/2,S	; completed r loop
			andcc	#%11111011	; clear z flag as
						; its composite
			bra	mpbisprimedone
mpbisprimecontwitness	
			ldd	VARK,S
			subd	#1
			std	VARK,S
			lbne	mpbisprimewitnessloop
			;finished all k loops
			orcc    #%00000100	; set z flag as
						; its probably prime
mpbisprimedone     	
			TFR	cc,a
			LEAS	2*MPLEN+8,S
			LDU	,s
			LEAS	6,s
			TFR	a,cc
			JMP	,u

SMALLPRIMELIST		FDB	$ff04,$fd04,$eb04,$e104,$d504,$cf04,$cd04,$c704,$c104,$bd04,$b104,$a904,$a304,$9d04,$9304,$8b04,$8104,$7f04,$6904,$6304,$5d04,$5504,$4f04,$4904,$4504,$4304,$3f04,$2d04,$2704,$2504,$1b04,$1904,$0f04,$0904,$0704,$fd03,$fb03,$f503,$f103,$e503,$df03,$d703,$d103,$cb03,$c703,$b903,$b303,$ad03,$a903,$a103,$9703,$8f03,$8b03,$7703,$7303,$7103,$6d03,$5f03,$5b03,$5903,$5503,$4703,$3d03,$3b03,$3703,$3503,$2b03,$2903,$1d03,$1303,$0503,$0103,$f902,$f502,$ef02,$e702,$e302,$dd02,$d702,$cf02,$c502,$bd02,$b302,$ab02,$a502,$a102,$9502,$9302,$8d02,$8702,$8302,$8102,$7702,$6b02,$6902,$6502,$5f02,$5902,$5702,$5102,$4b02,$4102,$3b02,$3902,$3302,$2d02,$2302,$1d02,$0b02,$0902,$fd01,$f701,$f301,$eb01,$e701,$df01,$d301,$cf01,$cd01,$c901,$c101,$bb01,$b701,$b101,$af01,$a501,$a301,$9901,$9101,$8d01,$8501,$7f01,$7b01,$7501,$6f01,$6701,$6101,$5d01,$5b01,$5101,$4b01,$3d01,$3901,$3701,$3301,$2501,$1b01,$1901,$1501,$0f01,$0d01,$0701,$0101,$fb00,$f100,$ef00,$e900,$e500,$e300,$df00,$d300,$c700,$c500,$c100,$bf00,$b500,$b300,$ad00,$a700,$a300,$9d00,$9700,$9500,$8b00,$8900,$8300,$7f00,$7100,$6d00,$6b00,$6700,$6500,$6100,$5900,$5300,$4f00,$4900,$4700,$4300,$3d00,$3b00,$3500,$2f00,$2b00,$2900,$2500,$1f00,$1d00,$1700,$1300,$1100,$0d00,$0b00,$0700,$0500,$0300
				;lots of primes
				;note reverse order
				;and least-significant-byte first ordering
ENDPRIMELIST
PRIMELISTLENGTH		SET	ENDPRIMELIST-SMALLPRIMELIST

