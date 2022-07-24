;Stub program just to test modular exponentiation

; This file is part of Color Computer RSA by Don Barber Copyright 2022

; Color Computer RSA is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

; Color Computer RSA is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along with Color Computer RSA. If not, see <https://www.gnu.org/licenses/>.


MPLEN		equ	8
CR              EQU     13


		org $0E00

start	
		clr	65497

		ldx	#base
		ldd	#MPLEN
		jsr	BNHEXOUT		
		jsr	CROUT
		ldx	#exp
		ldd	#MPLEN
		jsr	BNHEXOUT		
		jsr	CROUT
		ldx	#modulus
		ldd	#MPLEN
		jsr	BNHEXOUT		
		jsr	CROUT

		ldd	#base
		pshs	d
		ldd	#exp
		pshs	d
		ldd	#modulus
		pshs	d
		ldd	#result
		pshs	d
		ldd	#MPLEN
		pshs	d
		jsr	MPBMODEXP

		ldx	#result	
		ldd	#MPLEN
		jsr	BNHEXOUT		
		lbsr	CROUT
		lbsr	CROUT

		ldx	#base
		ldd	#MPLEN
		jsr	BNHEXOUT		
		jsr	CROUT
		ldx	#exp
		ldd	#MPLEN
		jsr	BNHEXOUT		
		jsr	CROUT
		ldx	#modulus
		ldd	#MPLEN
		jsr	BNHEXOUT		
		jsr	CROUT

finish		clr	65496
		lbsr	WAITKEY
		JMP     $A027           ; Restart BASIC
*		rts


		INCLUDE leventhal/MPBADD.s
		INCLUDE leventhal/MPBSUB.s
		INCLUDE sub/MPBMUL.s
		INCLUDE leventhal/BN2HEX.s
		INCLUDE sub/MPBMODEXP.s
		INCLUDE sub/MPBREM.s
		INCLUDE sub/MPBDIV.s
		INCLUDE sub/IO.s

base		fqb	$0173c600
base2		fqb	$00000000
exp		fqb	$ab3f0d2b
exp2		fqb	$00000000
modulus		fqb	$adfe34ac
modulus2	fqb	$00000000

result		rmb	MPLEN

		end	start
