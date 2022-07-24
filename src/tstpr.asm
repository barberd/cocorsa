;stub program just to test prime generation

; This file is part of Color Computer RSA by Don Barber Copyright 2022

; Color Computer RSA is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

; Color Computer RSA is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along with Color Computer RSA. If not, see <https://www.gnu.org/licenses/>.

SCREEN		equ	00
CR              EQU     13

MPLEN		equ	16

		org $0E00

start	
		clr	65497

		ldx	#rsap
		ldd	#MPLEN/4
		jsr	BNHEXOUT		
		jsr	CROUT

		jsr	SEEDRANDOM

		ldd	#rsap
		pshs	d
		ldd	#MPLEN/2
		pshs	d
		jsr	MPBNEXTPRIME

		ldx	#rsap		
		ldd	#MPLEN/4
		jsr	BNHEXOUT		
		lbsr	CROUT

finish		clr	65496
		lbsr	WAITKEY
		JMP     $A027           ; Restart BASIC
*		rts

		INCLUDE leventhal/MPBADD.s
		INCLUDE leventhal/MPBSUB.s
		INCLUDE leventhal/BN2HEX.s
		INCLUDE sub/MPBMUL.s
		INCLUDE sub/MPBREM.s
		INCLUDE sub/MPBDIV.s
		INCLUDE sub/MPBPRIME.s
		INCLUDE sub/MPBMODEXP.s
		INCLUDE sub/IO.s
		INCLUDE	sub/RANDOM.s
		include	leventhal/BN2DEC.s


rsap		fqb	$794e68fb
;rsap		fqb	$55e20000
rsap2		fqb	$00000000
rsap3		fqb	$00000000
rsap4		fqb	$00000000

primestatarray  fdb     11,22,44,89,177,355,532,710,1064,1420
primestat       rmd     1


		org     $0182
                jmp     start
		end	start
