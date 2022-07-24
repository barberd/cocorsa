;stub program just to test multiprecisionbyte modulus (remainder)

; This file is part of Color Computer RSA by Don Barber Copyright 2022

; Color Computer RSA is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

; Color Computer RSA is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along with Color Computer RSA. If not, see <https://www.gnu.org/licenses/>.


MPLEN		equ	4
CR              EQU     13


		org $0E00

start	
		clr	65497

		ldx	#dividend
		ldd	#MPLEN
		jsr	BNHEXOUT		
		jsr	CROUT
		ldx	#divisor
		ldd	#MPLEN
		jsr	BNHEXOUT		
		jsr	CROUT

		ldd	#dividend
		pshs	d
		ldd	#divisor
		pshs	d
		ldd	#remainder
		pshs	d
		ldd	#MPLEN
		pshs	d
		jsr	MPBREM
		jsr	CROUT
	
		ldx	#dividend
		ldd	#MPLEN
		jsr	BNHEXOUT		
		lbsr	CROUT
		ldx	#divisor
		ldd	#MPLEN
		jsr	BNHEXOUT		
		lbsr	CROUT
		ldx	#remainder
		ldd	#MPLEN
		jsr	BNHEXOUT		
		lbsr	CROUT

finish		clr	65496
		lbsr	WAITKEY
		JMP     $A027           ; Restart BASIC
*		rts

		INCLUDE sub/MPBREM.s
		INCLUDE leventhal/BN2HEX.s
		INCLUDE leventhal/MPBSUB.s
		INCLUDE sub/IO.s

dividend	fqb	$01000100
;dividend	fqb	$f7f70000
rsad2		fqb	$00000000
;divisor		fqb	$7f000000
divisor		fqb	$c0990000
;divisor		fqb	$83000000
;divisor		fqb	$7f000000
;divisor		fqb	$01000000
rsae2		fqb	$00000000
quotient	fqb	$00000000
quotient2	fqb	$00000000
remainder	fqb	$00000000
remainder2	fqb	$00000000


		end	start
