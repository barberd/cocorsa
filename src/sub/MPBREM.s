; Modulus through naive Division
; Inspired by libtommath's s_mp_div_small.c's algorithm
; at https://github.com/libtom/libtommath

; This file is part of Color Computer RSA by Don Barber Copyright 2022

; Color Computer RSA is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

; Color Computer RSA is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along with Color Computer RSA. If not, see <https://www.gnu.org/licenses/>.

MPBREMDIVIDEND	EQU	8
MPBREMDIVISOR	EQU	6
MPBREMREM	EQU	4
MPBREMSIZE	EQU	2

MPBREM					
			LDY	MPBREMREM,S
			BEQ	mpbreminitdividenddone ; storing remainder back
						       ; into dividend so no
						       ; need to copy
			ldu	MPBREMDIVIDEND,S
			sty	MPBREMDIVIDEND,S
			ldx	MPBREMSIZE,S
mpbreminitdividendloop	lda	,u+
			sta	,y+
			leax	-1,x
			bne	mpbreminitdividendloop	
mpbreminitdividenddone

			;check for division by 0
			ldx	MPBREMSIZE,S
			ldy	MPBREMDIVISOR,S
			tfr	x,d
			leay	d,y
			leax	-1,x		;go with one less as going to
						;exit at first byte
mpbremdivisorcheckloop	lda	,-y
			bne	mpbremdivisornot1or0
			leax	-1,x
			bne	mpbremdivisorcheckloop
			lda	,-y
			lbeq	mpbremdivisionby0
			;check for division by 1
			cmpa	#1
			lbeq	mpbremdivisionby1

mpbremdivisornot1or0
;count bytes/bits (n)
;count bytes and bits in divisor
			LDX	MPBREMSIZE,S
			LDY	MPBREMDIVISOR,S
			TFR	X,D
			LEAY	D,Y
mpbremcount2loop1	LDA	,-Y
			BNE	mpbremcount2notempty
			LEAX	-1,X
			BNE	mpbremcount2loop1

mpbremcount2notempty	
			LEAX	-1,X
			STX	mpbremdivisorbytes
			LDB	#0
mpbremcount2loop2	CMPA	#0
			BEQ	mpbremcount2done
			LSRA
			INCB
			BRA	mpbremcount2loop2
mpbremdivisorbytes	rmd	1
mpbremdivisorbits	rmb	1
mpbremcount2done
			STB	mpbremdivisorbits

;count bytes and bits in dividend
			LDX	MPBREMSIZE,S
			LDY	MPBREMDIVIDEND,S
			TFR	X,D
			LEAY	D,Y
mpbremcount1loop1	LDA	,-Y
			BNE	mpbremcount1notempty
			LEAX	-1,X
			BNE	mpbremcount1loop1

mpbremcount1notempty	
			LEAX	-1,X
			STX	mpbremdividendbytes
			LDB	#0
mpbremcount1loop2	CMPA	#0
			BEQ	mpbremcount1done
			LSRA
			INCB
			BRA	mpbremcount1loop2
mpbremdividendbytes	rmd	1
mpbremdividendbits	rmb	1
mpbremcount1done
			STB	mpbremdividendbits

			ldd	mpbremdividendbytes
			subd	mpbremdivisorbytes
			ANDCC	#$FE	; multiply by 8
			ROLB	
			ROLA
			ANDCC	#$FE
			ROLB	
			ROLA
			ANDCC	#$FE
			ROLB
			ROLA
			ADDB	mpbremdividendbits
			ADCA	#0
			SUBB	mpbremdivisorbits
		        SBCA	#0	

			BITA	#$80
			LBNE	mpbremfinish

			;shift divisor up to match with dividend
;			LDU	2+MPBREMDIVISOR,S
;			PSHS	U,D
;			LDX	6+MPBREMSIZE,S
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
			STD	mpbremshiftbytes

			TFR	X,D
			ANDB	#$7
			PSHS	B

			LDD	mpbremshiftbytes
			LDX	1+MPBREMSIZE,S
			LDU	1+MPBREMDIVISOR,S
			PSHS	D			;add temporary
			TFR	X,D
			LEAU	D,U
			TFR	U,Y
			LDD	#0	; negate D
			SUBD	,S
			LEAU	D,U

mpbrembyteshiftloop	
			CMPX	,S
			BEQ	mpbrembyteclearloop
			LDA	,-U
			STA	,-Y
			LEAX	-1,X
			BRA	mpbrembyteshiftloop			

mpbrembyteclearloop	CMPX	#0	
			BEQ	mpbrembyteshiftdone
			CLR	,-Y
			LEAX 	-1,X
			BRA	mpbrembyteclearloop
mpbrembyteshiftdone
			LEAS	2,S 		; remove temp from stack

			;LDX	1+MPBREMDIVISOR,S
			;LDD	1+MPBREMSIZE,S
			;JSR	BNHEXOUT
			;JSR	CROUT

			LDY	1+MPBREMDIVISOR,S
			LDD	mpbremshiftbytes
			LEAY	D,Y
			LDB	,S	; number of bits left to shift

mpbrembitshiftouterloop
			BEQ	mpbrembitshiftdone
			TFR	Y,U	
			LDX	mpbremdivisorbytes
			ANDCC	#$FE
			LEAX	2,X
mpbrembitshiftinnerloop	
			BEQ	mpbrembitshiftinnerdone
			LDA	,U
			;PSHS	X,D
			;LDX	MPBREMDIVISOR,S
			;LDD	MPBREMSIZE,S
			;JSR	BNHEXOUT
			;PULS	X,D
			ROLA
			STA	,U+
			LEAX	-1,X
			BRA	mpbrembitshiftinnerloop
mpbrembitshiftinnerdone
			DECB
			BRA	mpbrembitshiftouterloop
mpbrembitshiftdone

			PULS	B
			;DECB
			;INCB
			;CMPB	#0
			;BNE	mpbremnotbyteboundary
			;LDD	mpbremshiftbytes
			;ADDD	#1
			;STD	mpbremshiftbytes
			;LDB	#4
			;STA	mpbremshiftbit
			;BRA	mpbremdivloop	

mpbremnotbyteboundary

			;init quotient mask bit
			LDA	#1
			ANDCC	#$FE
			;CLRA
			;ORCC	#1
			CMPB	#0
mpbremsetquotbitloop	BEQ	mpbremsetquotbitdone
			ROLA
			DECB
			BRA	mpbremsetquotbitloop
mpbremsetquotbitdone
			STA	mpbremshiftbit

			;LDX	MPBREMDIVIDEND,S
			;LDD	MPBREMSIZE,S
			;JSR	BNHEXOUT
			;JSR	CROUT
			;LDX	MPBREMDIVISOR,S
			;LDD	MPBREMSIZE,S
			;JSR	BNHEXOUT
			;JSR	CROUT

mpbremdivloop
mpbremdivloopcont

			LDX	MPBREMSIZE,S
			LDU	MPBREMDIVISOR,S
			LDY	MPBREMDIVIDEND,S
			TFR	X,D
			LEAU	D,U
			LEAY	D,Y
mpbremcmploop		LDA	,-U
			CMPA	,-Y
			BHI	mpbremshiftdownstart
			BLO	mpbremsubtract
			LEAX	-1,X		; still equal, compare next bytes
			BNE	mpbremcmploop
			;divisor is <= dividend, so subtract
mpbremsubtract
			LDU	MPBREMDIVIDEND,S
			LDY	MPBREMDIVISOR,S
			LDX	mpbremdividendbytes
			LEAX	1,X
			PSHS	U,Y,X
			JSR	MPBSUB

			;BRA	mpbremdivloop

mpbremshiftdownstart
			;CMP	mpbremshiftbit
			LSR	mpbremshiftbit
			BNE	mpbremshiftdown
			LDB	#$80
			STB	mpbremshiftbit
			LDD	mpbremshiftbytes
			SUBD	#1
			STD	mpbremshiftbytes
			BMI	mpbremfinish
mpbremshiftdown
			LDX	MPBREMSIZE,S
			LDU	MPBREMDIVISOR,S
			TFR	X,D
			LEAU	D,U
			ANDCC	#$FE
			CMPX	#0
mpbremshiftdownloop	
			BEQ	mpbremshiftdowndone
			LDA	,-U	
			RORA
			STA	,U
			LEAX	-1,X
			BRA	mpbremshiftdownloop
mpbremshiftdowndone
			;LSR	mpbremshiftbit
			LBRA	mpbremdivloop

			
mpbremdivisionby1
			ldx	MPBREMSIZE,S
			ldu	MPBREMREM,S
			clra
mpbremdivbyoneloop2	sta	,u+
			leax	-1,x
			bne	mpbremdivbyoneloop2
			bra	mpbremfinish

mpbremdivisionby0	
			ANDCC	#$13 ; error out by setting overflow flag
mpbremfinish
			LDX	,S
			LEAS	10,S
			JMP	,X

mpbremshiftbit		rmb	1
mpbremshiftbytes	rmd	1
