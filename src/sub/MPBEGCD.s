; Extended Euclidean Algorithm for Greatest Common Divisor
; and Bezout coefficients
; Adapted from pseudocode at https://en.wikipedia.org/wiki/Extended_Euclidean_algorithm	

; This file is part of Color Computer RSA by Don Barber Copyright 2022

; Color Computer RSA is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

; Color Computer RSA is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along with Color Computer RSA. If not, see <https://www.gnu.org/licenses/>.

;Extended Euclid's algorithm for GCD(A,B) and Bezout integers
;input		6,S is A
;		4,S is B
;		2,S length of multi-precision-byte integer in bytes
;output 	Y is pointer to GCD
;		U is pointer to first Bezout integer

MPBEGCD					

		LDU	6,S		load e into r
		LDY	#egcdr
		LDX	2,S
egcdcopy1	LDA	,U+
		STA	,Y+
		LEAX	-1,X
		BNE	egcdcopy1

		LDU	4,S		load phi into oldr
		LDY	#egcdoldr
		LDX	2,S
egcdcopy2	LDA	,U+
		STA	,Y+
		LEAX	-1,X
		BNE	egcdcopy2
		

		LDY	#egcdoldt	oldt=0
		LDU	#egcdt		t=0
		LDX	2,S
egcdclr2
		CLR	,y+
		CLR	,u+
		leax	-1,x
		BNE	egcdclr2

		lda	#1
		ldy	#egcdt
		sta	,y		t=1

		LEAS	-(2*MPLEN),S		make room on stack for temp vars

egcdloop	



		LDY	#egcdr         do while r!=0
		LDX	2*MPLEN+2,S
egcdrchkloop	lda	,y+
		bne	egcdrchkdone	;any byte is not 0 then continue
		leax	-1,x
		bne	egcdrchkloop
		lbra	egcddone
egcdrchkdone

		LDU	#egcdr         temp_r=r
		LEAY	MPLEN,S
		LDX	2*MPLEN+2,S
egcdcopy4	LDA	,U+
		STA	,Y+
		LEAX	-1,X
		BNE	egcdcopy4

		;LDU	#egcdoldr	quotient=oldr
	 	;LDY	#egcdquotient
		;LDX	2*MPLEN+2,S
egcdcopy3	;LDA	,U+
		;STA	,Y+
		;LEAX	-1,X
		;BNE	egcdcopy3

		;LDX	#egcdoldr
		;LDD	2*MPLEN+2,S
		;JSR	BNHEXOUT
		;JSR	CROUT
		;LEAX	MPLEN,S
		;LDD	2*MPLEN+2,S
		;JSR	BNHEXOUT
		;JSR	CROUT

		LDU	#egcdoldr	quotient = old_r / temp_r
		LEAY	MPLEN,S
		LDX	#egcdquotient
		pshs	u,y,x
		LDX	#egcdr		;store remainder in r
		LDD	2*MPLEN+8,S
		pshs	x,d
		JSR	MPBDIV


		;LDX	#egcdquotient
		;LDD	2*MPLEN+2,S
		;JSR	BNHEXOUT
		;JSR	CROUT
		;LDX	#egcdr
		;LDD	2*MPLEN+2,S
		;JSR	BNHEXOUT
		;JSR	CROUT
		;JSR	WAITKEY

		;LDY	#egcdquotient	quotient = quotient / r
	 	;LDX	#egcdr
		;LDD	2*MPLEN+2,S
		;pshs	y,x,d
		;JSR	MPBDIV

		;LDY	#egcdr		;copy remainder to r
		;LDX	2*MPLEN+2,S
egcdcopyrem1	;LDA	,U+
		;STA	,Y+
		;LEAX	-1,X
		;BNE	egcdcopyrem1

		LEAU	MPLEN,S		old_r=temp_r
		LDY	#egcdoldr
		LDX	2*MPLEN+2,S
egcdcopy5	LDA	,U+
		STA	,Y+
		LEAX	-1,X
		BNE	egcdcopy5

		LDU	#egcdt         copy t to temp_t (on stack)
		LEAY	MPLEN,S
		LDX	2*MPLEN+2,S
egcdcopy6	LDA	,U+
		STA	,Y+
		LEAX	-1,X
		BNE	egcdcopy6

#		LDY	#egcdt	;clear top half of t
#		LDD	2*MPLEN+2,S
#		LSRA
#		RORB
#		TFR	D,X
#		LEAY	D,Y
#egcdclearquot	CLR	,Y+
#		LEAX	-1,X
#		BNE	egcdclearquot

		#LDX	#egcdquotient
		#LDD	2*MPLEN+2,S
		#JSR	BNHEXOUT
		#JSR	CROUT
		#LDX	#egcdt
		#LDD	2*MPLEN+2,S
		#JSR	BNHEXOUT
		#JSR	CROUT

		LDU	#egcdquotient
		LDY	#egcdt
		TFR	S,X			; temp_quotient = quotient * t
		LDD	2*MPLEN+2,S
		LSRA
		RORB
		PSHS	u,y,x,d
		JSR	MPBMULS

		;LEAX	,S
		;LDD	2*MPLEN+2,S
		;JSR	BNHEXOUT
		;JSR	CROUT
		;JSR	WAITKEY

		LDU	#egcdoldt       t=oldt
		LDY	#egcdt
		LDX	2*MPLEN+2,S
egcdcopy8	LDA	,U+
		STA	,Y+
		LEAX	-1,X
		BNE	egcdcopy8

		LDY	#egcdt          t=t-temp_quotient
		TFR	S,X
		LDD	2*MPLEN+2,S
		PSHS	y,x,d
		JSR	MPBSUB

		LEAU	MPLEN,S		oldt=temp_t
		LDY	#egcdoldt
		LDX	2*MPLEN+2,S
egcdcopy9	LDA	,U+
		STA	,Y+
		LEAX	-1,X
		BNE	egcdcopy9

		;LDX	#egcdoldt
		;LDD	2*MPLEN+2,S
		;JSR	BNHEXOUT
		;JSR	CROUT
		;JSR	WAITKEY

		LBRA	egcdloop

egcddone	
		LEAS	(2*MPLEN),S
		LDY	#egcdoldt
		LDX	2,S
		TFR	X,D
		LSRA
		RORB
		SUBD	#1
		LDA	D,Y
		BITA	#$80
		BEQ	egcdnotneg
		LDX	4,S
		LDD	2,S
		PSHS	y,x,d
		JSR	MPBADD	

egcdnotneg

		LDX	,S
		LEAS	8,S
		LDU	#egcdoldt
		LDY	#egcdoldr
		JMP	,X

egcdquotient	rmb	MPLEN
egcdr		rmb	MPLEN
egcdoldr	rmb	MPLEN
egcdt		rmb	MPLEN
egcdoldt	rmb	MPLEN

