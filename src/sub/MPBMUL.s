; Multiplication Routine
; Uses Karatsuba algorithm for anything above 2 bytes

; This file is part of Color Computer RSA by Don Barber Copyright 2022

; Color Computer RSA is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

; Color Computer RSA is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along with Color Computer RSA. If not, see <https://www.gnu.org/licenses/>.

MPBMULX		EQU	6+8
MPBMULY		EQU	6+6
MPBMULPROD	EQU	6+4
MPBMULSIZE	EQU	6+2

;Copy X and Y onto stack before negating so to not modify original

MPBMULS			PSHS	U,Y,D
			LDA	#$FF
			PSHS	A

			TFR	S,U
			LDD	1+MPBMULSIZE,U
			LDX	1+MPBMULX,U
			LEAX	D,X
			LDA	,-X
			BPL	mpbmulsxnotneg
			COM	,U
			LDD	#0
			SUBD	1+MPBMULSIZE,U
			LEAS	D,S
			LDY	1+MPBMULX,U
			STS	1+MPBMULX,U	
			LDX	1+MPBMULSIZE,U
			PSHS	U
			LEAU	2,S
mpbmulscpyloop1		LDA	,Y+
			STA	,U+
			LEAX	-1,X
			BNE	mpbmulscpyloop1
			PULS	U

			LDY	1+MPBMULX,U
			LDX	1+MPBMULSIZE,U

			JSR	MPBNEG
mpbmulsxnotneg		LDX	1+MPBMULY,U
			LDD	1+MPBMULSIZE,U
			LEAX	D,X
			LDA	,-X
			BPL	mpbmulsynotneg
			COM	,U
			LDD	#0
			SUBD	1+MPBMULSIZE,U
			LEAS	D,S
			LDY	1+MPBMULY,U
			STS	1+MPBMULY,U	
			LDX	1+MPBMULSIZE,U
			PSHS	U
			LEAU	2,S
mpbmulscpyloop2		LDA	,Y+
			STA	,U+
			LEAX	-1,X
			BNE	mpbmulscpyloop2
			PULS	U
			LDY	1+MPBMULY,U
			LDX	1+MPBMULSIZE,U
			JSR	MPBNEG
mpbmulsynotneg		

			LDY	1+MPBMULX,U
			LDX	1+MPBMULY,U
			PSHS	Y,X
			LDX	1+MPBMULPROD,U
			LDD	1+MPBMULSIZE,U
			PSHS	X,D
			JSR	MPBMULU
			TFR	U,S			;restore stack
			TST	,S
			BNE	mpbmulsfinish
			LDY	1+MPBMULPROD,S
			;LDX	1+MPBMULSIZE,S
			LDD	1+MPBMULSIZE,S
			ANDCC	#$FE			;multiply by 2
			ROLB				;to negate entire 
			ROLA				;length
			TFR	D,X
			JSR	MPBNEG
mpbmulsfinish		LEAS	1,S			; pull off flag
			PULS	U,Y,D
			LDX	,S
			LEAS	10,S
			JMP	,X

MPBNEG
			PSHS	Y,X

mpbnegloop		COM	,Y+
			LEAX	-1,X
			BNE	mpbnegloop
			PULS	Y,X
mpbnegripple		
			INC	,Y+
			BNE	mpbnegfinish
			LEAX	-1,X
			BNE	mpbnegripple
mpbnegfinish		RTS


MPBMULU			PSHS	U,Y,D

			LDD	MPBMULSIZE,S
			CMPD	#1
			BNE	mpbmulkaratsuba
			LDX	MPBMULX,S
			LDA	,X
			LDX	MPBMULY,S
			LDB	,X
			MUL
			LDX	MPBMULPROD,S
			STB	,X+
			STA	,X
			LBRA	mpbmulfinish
mpbmulkaratsuba
			BITB	#1
			BEQ	mpbmulsizeeven
			ADDD	#1
			STD	MPBMULSIZE,S
mpbmulsizeeven

			LDX	MPBMULPROD,S		; get top half of MPBMULPROD
			LEAX	D,X

			; now half size again for next iter
			LSRA
			RORB		

			LDU	MPBMULX,S		Xl*Yl
			LEAU	D,U
			LDY	MPBMULY,S
			LEAY	D,Y
			PSHS	U,Y,X,D
			JSR	MPBMULU

			LDU	MPBMULX,S		Xr*Yr
			LDY	MPBMULY,S
			LDX	MPBMULPROD,S
			PSHS	U,Y,X,D
			JSR	MPBMULU

			PSHS	D			; store halfsize on stack

			TFR	S,U

			LDD	2+MPBMULSIZE,S		; make room for entire new product
			ANDCC	#$FE			; on stack
			ROLB
			ROLA
			PSHS	D
			LDD	#2			;start with 2 to clear just pushed D
			SUBD	,S
			LEAS	D,S

			TFR	D,X			;clear new stack space	
			TFR	S,Y
mpbmulcleartemp		CLR	,Y+
			LEAX	1,X
			BNE	mpbmulcleartemp

			LDD	,U			;pull in half size again

			LDY	2+MPBMULX,U		Xl*Yr
			LEAY	D,Y
			LDX	2+MPBMULY,U
			PSHS	Y,X
			LEAX	4,S
			PSHS	X,D
			JSR	MPBMULU

			LDD	,U

			PSHS	U
			LDY	2+MPBMULPROD,U		; start .5 into prod
			LEAY	D,Y
			LEAX	2,S
			LDD	2+MPBMULSIZE,U
			ADDD	,U				; size*1.5
			PSHS	Y,X,D
			JSR	MPBADD
			PULS	U

			LDD	,U				;load halfsize again

			LDY	2+MPBMULX,U		Xr*Yl
			LDX	2+MPBMULY,U
			LEAX	D,X
			PSHS	Y,X
			LEAX	4,S
			PSHS	X,D
			JSR	MPBMULU

			LDD	,U

			PSHS	U
			LDY	2+MPBMULPROD,U		; start .5 into prod
			LEAY	D,Y
			LEAX	2,S
			LDD	2+MPBMULSIZE,U
			ADDD	,U				; size*1.5
			PSHS	Y,X,D
			JSR	MPBADD
			PULS	U
		
			TFR	U,S			; forget popping everything
			LEAS	2,S			; just pull off the halfsize

mpbmulfinish
			PULS	U,Y,D
			LDX	,S
			LEAS	10,S
			JMP	,X

