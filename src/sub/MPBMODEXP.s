; Modular exponentiation using left to right binary method
; Adapted from psuedocode found on
; https://en.wikipedia.org/wiki/Modular_exponentiation

; This file is part of Color Computer RSA by Don Barber Copyright 2022

; Color Computer RSA is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

; Color Computer RSA is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along with Color Computer RSA. If not, see <https://www.gnu.org/licenses/>.

MPBMODEXPSIZE		SET	2*MPLEN+2
MPBMODEXPRESULT		SET	2*MPLEN+4
MPBMODEXPMODULUS	SET	2*MPLEN+6
MPBMODEXPEXPONENT	SET	2*MPLEN+8	
MPBMODEXPBASE		SET	2*MPLEN+10

			;   pow(base,exponent,modulus) == (base**exponent)%modulus
			;   ,S	return address
			;   2,S	mplen
			;   4,S result pointer
			;   6,S modulus pointer
			;   8,S exponent pointer
			;   10,S base pointer

MPBMODEXP
			LEAS	-2*MPLEN,S

			LDX	MPBMODEXPSIZE,S		;set result to 1
			LDY	MPBMODEXPRESULT,S
			LDA	#1
			STA	,Y+
			leax	-1,x
			BEQ	mpbmodexpclrloopdone	;if MPLEN is one byte
			clra
mpbmodexpclrloop	STA	,Y+
			leax	-1,x
			BNE	mpbmodexpclrloop
mpbmodexpclrloopdone

			LDX	MPBMODEXPSIZE,S
			LDU	MPBMODEXPEXPONENT,S
			TFR	X,D
			LEAU	D,U
			LEAX	1,X
mpbmodexpfindmsb	LEAX	-1,X
			LBEQ	mpbmodexpdone		;exponent is 0,exit
			LDA	,-U
			BEQ	mpbmodexpfindmsb	;didnt find first 1
			LDB	#$80			;now test bits
			STB	TESTBIT
			ANDCC	#$FE
mpbmodexpfindfirst1

			BITA	TESTBIT
			BNE	mpbmodexpprocessbit
			ROR	TESTBIT

			BRA	mpbmodexpfindfirst1


mpbmodexpprocessbit	

			PSHS	U,X,A

			LDY	5+MPBMODEXPRESULT,S	;temp_r=r*r
			TFR	Y,U
			LEAX	5,S
			LDD	5+MPBMODEXPSIZE,S
			LSRA
			RORB
			PSHS	U,Y,X,D
			JSR	MPBMULU

			LEAU	5,S
			LDY	5+MPBMODEXPMODULUS,S
			LDX	5+MPBMODEXPRESULT,S     ;r=temp_r%modulus
			LDD	5+MPBMODEXPSIZE,S
			PSHS	U,Y,X,D
			JSR	MPBREM

			LDA	,S
			BITA	TESTBIT
			BEQ	mpbmodexprbdone

			LDU	5+MPBMODEXPBASE,S         temp_r=result*base
			LDY	5+MPBMODEXPRESULT,S
			LEAX	5,S
			LDD	5+MPBMODEXPSIZE,S
			LSRA
			RORB
			PSHS	U,Y,X,D
			JSR	MPBMULU

			LEAU	5,S		     	result = temp_r % modulus
			LDY	5+MPBMODEXPMODULUS,S
			LDX	5+MPBMODEXPRESULT,S 
			LDD	5+MPBMODEXPSIZE,S
			PSHS	U,Y,X,D
			JSR	MPBREM

mpbmodexprbdone

			PULS	U,X,A
			ANDCC	#$FE
			ROR	TESTBIT
			BCS	mpbmodexpnextbyte
			LBRA	mpbmodexpprocessbit
mpbmodexpnextbyte
			ROR	TESTBIT		; rotate back to $80
			LDA	,-U		; load next byte
			LEAX	-1,X
			LBNE	mpbmodexpprocessbit

mpbmodexpdone		
			LEAS	2*MPLEN,S
			LDU	,S
			LEAS	12,S
			JMP	,U

TESTBIT			rmb	1
