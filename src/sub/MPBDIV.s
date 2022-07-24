; Naive Division

; This file is part of Color Computer RSA by Don Barber Copyright 2022

; Color Computer RSA is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

; Color Computer RSA is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along with Color Computer RSA. If not, see <https://www.gnu.org/licenses/>.

MPBDIVDIVIDEND	EQU	10
MPBDIVDIVISOR	EQU	8
MPBDIVQUOT	EQU	6
MPBDIVREM	EQU	4
MPBDIVSIZE	EQU	2

MPBDIV					
			LDY	MPBDIVREM,S
			BEQ	mpbdivinitdividenddone
			ldx	MPBDIVSIZE,S
			ldu	MPBDIVDIVIDEND,S
			ldy	MPBDIVREM,S
			sty	MPBDIVDIVIDEND,S
mpbdivinitdividendloop	lda	,u+
			sta	,y+
			leax	-1,x
			bne	mpbdivinitdividendloop	
mpbdivinitdividenddone

;init quotient to 0
			LDX	MPBDIVSIZE,S
			LDY	MPBDIVQUOT,S
mpbdivclearquotloop	CLR	,Y+
			LEAX	-1,X
			BNE	mpbdivclearquotloop

			;check for division by 0
			ldx	MPBDIVSIZE,S
			ldy	MPBDIVDIVISOR,S
			tfr	x,d
			leay	d,y
			leax	-1,x		;go with one less as going to
						;exit at first byte
mpbdivdivisorcheckloop	lda	,-y
			bne	mpbdivdivisornot1or0
			leax	-1,x
			bne	mpbdivdivisorcheckloop
			lda	,-y
			lbeq	mpbdivdivisionby0
			;check for division by 1
			cmpa	#1
			lbeq	mpbdivdivisionby1

mpbdivdivisornot1or0
;count bytes/bits (n)
;count bytes and bits in divisor
			LDX	MPBDIVSIZE,S
			LDY	MPBDIVDIVISOR,S
			TFR	X,D
			LEAY	D,Y
mpbdivcount2loop1	LDA	,-Y
			BNE	mpbdivcount2notempty
			LEAX	-1,X
			BNE	mpbdivcount2loop1

mpbdivcount2notempty	
			LEAX	-1,X
			STX	mpbdivdivisorbytes
			LDB	#0
mpbdivcount2loop2	CMPA	#0
			BEQ	mpbdivcount2done
			LSRA
			INCB
			BRA	mpbdivcount2loop2
mpbdivdivisorbytes	rmd	1
mpbdivdivisorbits	rmb	1
mpbdivcount2done
			STB	mpbdivdivisorbits

;count bytes and bits in dividend
			LDX	MPBDIVSIZE,S
			LDY	MPBDIVDIVIDEND,S
			TFR	X,D
			LEAY	D,Y
mpbdivcount1loop1	LDA	,-Y
			BNE	mpbdivcount1notempty
			LEAX	-1,X
			BNE	mpbdivcount1loop1

mpbdivcount1notempty	
			LEAX	-1,X
			STX	mpbdivdividendbytes
			LDB	#0
mpbdivcount1loop2	CMPA	#0
			BEQ	mpbdivcount1done
			LSRA
			INCB
			BRA	mpbdivcount1loop2
mpbdivdividendbytes	rmd	1
mpbdivdividendbits	rmb	1
mpbdivcount1done
			STB	mpbdivdividendbits

			ldd	mpbdivdividendbytes
			subd	mpbdivdivisorbytes
			ANDCC	#$FE	; multiply by 8
			ROLB	
			ROLA
			ANDCC	#$FE
			ROLB	
			ROLA
			ANDCC	#$FE
			ROLB
			ROLA
			ADDB	mpbdivdividendbits
			ADCA	#0
			SUBB	mpbdivdivisorbits
		        SBCA	#0	

			BITA	#$80
			LBNE	mpbdivfinish
			;BEQ	mpbdivshiftnotneg
			;LDD	#0
mpbdivshiftnotneg

;			PSHS	D

			;shift divisor up to match with dividend
;			LDU	2+MPBDIVDIVISOR,S
;			PSHS	U,D
;			LDX	6+MPBDIVSIZE,S
;			PSHS	X
;			JSR	MPBLSL

;			PULS	D

			TFR	D,X
			LSRA
			RORB
			LSRA
			RORB
			LSRA
			RORB
			STD	mpbdivshiftbytes

			TFR	X,D
			ANDB	#$7
			PSHS	B

			;LDX	#mpbdivshiftbytes
			;LDD	#2
			;JSR	BNHEXOUT
			;JSR	CROUT
			;LEAX	,S
			;LDD	#1
			;JSR	BNHEXOUT
			;JSR	CROUT
		

			LDD	mpbdivshiftbytes
			LDX	1+MPBDIVSIZE,S
			LDU	1+MPBDIVDIVISOR,S
			PSHS	D			;add temporary
			TFR	X,D
			LEAU	D,U
			TFR	U,Y
			LDD	#0	; negate D
			SUBD	,S
			LEAU	D,U

mpbdivbyteshiftloop	
			CMPX	,S
			BEQ	mpbdivbyteclearloop
			LDA	,-U
			STA	,-Y
			LEAX	-1,X
			BRA	mpbdivbyteshiftloop			

mpbdivbyteclearloop	CMPX	#0
			BEQ	mpbdivbyteshiftdone	
			CLR	,-Y
			LEAX 	-1,X
			BRA	mpbdivbyteclearloop
mpbdivbyteshiftdone
			LEAS	2,S 		; remove temp from stack

			;LDX	1+MPBDIVDIVISOR,S
			;LDD	1+MPBDIVSIZE,S
			;JSR	BNHEXOUT
			;JSR	CROUT

			LDY	1+MPBDIVDIVISOR,S
			LDD	mpbdivshiftbytes
			LEAY	D,Y
			LDB	,S	; number of bits left to shift


mpbdivbitshiftouterloop

			BEQ	mpbdivbitshiftdone
			;PSHS	B
			;LEAX	,S
			;LDD	#1
			;JSR	BNHEXOUT
			;JSR	CROUT
			;PULS	B
			TFR	Y,U	
			LDX	mpbdivdivisorbytes
			LEAX	2,X
			ANDCC	#$FE
mpbdivbitshiftinnerloop	
			BEQ	mpbdivbitshiftinnerdone
			LDA	,U
			;PSHS	X,D
			;LDX	MPBDIVDIVISOR,S
			;LDD	MPBDIVSIZE,S
			;JSR	BNHEXOUT
			;PULS	X,D
			ROLA
			STA	,U+
			LEAX	-1,X
			BRA	mpbdivbitshiftinnerloop
mpbdivbitshiftinnerdone
			DECB
			BRA	mpbdivbitshiftouterloop
mpbdivbitshiftdone

			PULS	B
			;DECB
			;INCB
			;CMPB	#0
			;BNE	mpbdivnotbyteboundary
			;LDD	mpbdivshiftbytes
			;ADDD	#1
			;STD	mpbdivshiftbytes
			;LDB	#4
			;STA	mpbdivshiftbit
			;BRA	mpbdivdivloop	

mpbdivnotbyteboundary

			;init quotient mask bit
			LDA	#1
			ANDCC	#$FE
			;CLRA
			;ORCC	#1
			CMPB	#0
mpbdivsetquotbitloop	BEQ	mpbdivsetquotbitdone
			ROLA
			DECB
			BRA	mpbdivsetquotbitloop
mpbdivsetquotbitdone
			STA	mpbdivshiftbit
mpbdivdivloop

			;LDX	MPBDIVDIVIDEND,S
			;LDD	MPBDIVSIZE,S
			;JSR	BNHEXOUT
			;JSR	CROUT
			;LDX	MPBDIVDIVISOR,S
			;LDD	MPBDIVSIZE,S
			;JSR	BNHEXOUT
			;JSR	CROUT
			;LDX	MPBDIVQUOT,S
			;LDD	MPBDIVSIZE,S
			;JSR	BNHEXOUT
			;JSR	CROUT
			;JSR	WAITKEY


			LDX	MPBDIVSIZE,S
			LDU	MPBDIVDIVISOR,S
			LDY	MPBDIVDIVIDEND,S
			TFR	X,D
			LEAU	D,U
			LEAY	D,Y
mpbdivcmploop		LDA	,-U
			CMPA	,-Y
			BHI	mpbdivshiftdownstart
			BLO	mpbdivsubtract
			LEAX	-1,X		; still equal, compare next bytes
			BNE	mpbdivcmploop
			;divisor is <= dividend, so subtract
mpbdivsubtract
			;LDD	mpbdivshiftbytes
			;LDU	MPBDIVDIVIDEND,S
			;LDY	MPBDIVDIVISOR,S
			;LEAU	D,U
			;LEAY	D,Y
			;LDX	mpbdivdivisorbytes
			;LEAX	2,X
			;PSHS	U,Y,X
			;;LDD	MPBDIVSIZE,X
			;;SUBD	mpbdivshiftbytes
			;;PSHS	U,Y,D
			;JSR	MPBSUB

			LDU	MPBDIVDIVIDEND,S
			LDY	MPBDIVDIVISOR,S
			LDX	mpbdivdividendbytes
			LEAX	1,X
			PSHS	U,Y,X
			JSR	MPBSUB

			LDD	mpbdivshiftbytes
			LDY	MPBDIVQUOT,S
			LEAY	D,Y

			LDA	mpbdivshiftbit
			ORA	,Y
			STA	,Y

mpbdivshiftdownstart
			LSR	mpbdivshiftbit
			BNE	mpbdivshiftdown
			LDB	#$80
			STB	mpbdivshiftbit
			LDD	mpbdivshiftbytes
			SUBD	#1
			STD	mpbdivshiftbytes
			BMI	mpbdivfinish
mpbdivshiftdown
			LDX	MPBDIVSIZE,S
			LDU	MPBDIVDIVISOR,S
			TFR	X,D
			LEAU	D,U
			ANDCC	#$FE
			CMPX	#0
mpbdivshiftdownloop	
			BEQ	mpbdivshiftdowndone
			LDA	,-U	
			RORA
			STA	,U
			LEAX	-1,X
			BRA	mpbdivshiftdownloop
mpbdivshiftdowndone
			;LSR	mpbdivshiftbit
			LBRA	mpbdivdivloop

			
mpbdivdivisionby1
			ldx	MPBDIVSIZE,S
			ldu	MPBDIVDIVIDEND,S
			ldy	MPBDIVQUOT,S
mpbdivdivbyoneloop1	lda	,u+
			sta	,y+
			leax	-1,x
			bne	mpbdivdivbyoneloop1
			ldx	MPBDIVSIZE,S
			ldu	MPBDIVREM,S
			clra
mpbdivdivbyoneloop2	sta	,u+
			leax	-1,x
			bne	mpbdivdivbyoneloop2
			bra	mpbdivfinish

mpbdivdivisionby0	
			ANDCC	#$13 ; error out by setting overflow flag
mpbdivfinish
			LDX	,S
			LEAS	12,S
			JMP	,X

mpbdivshiftbit		rmb	1
mpbdivshiftbytes	rmd	1
