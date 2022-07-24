;stub program just to test multiprecisionbyte multiplication

; This file is part of Color Computer RSA by Don Barber Copyright 2022

; Color Computer RSA is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

; Color Computer RSA is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along with Color Computer RSA. If not, see <https://www.gnu.org/licenses/>.


MPLEN		equ	8
CR              EQU     13


		org $0E00

start	
		clr	65497

		ldx	#rsad
		ldd	#MPLEN/2
		jsr	BNHEXOUT		
		jsr	CROUT
		ldx	#rsae
		ldd	#MPLEN/2
		jsr	BNHEXOUT		
		jsr	CROUT

		ldd	#rsae
		pshs	d
		ldd	#rsad
		pshs	d
		ldd	#prod
		pshs	d
		ldd	#MPLEN/2
		pshs	d
		jsr	MPBMULU
	
		ldx	#prod
		ldd	#MPLEN
		jsr	BNHEXOUT		
		lbsr	CROUT

finish		clr	65496
		lbsr	WAITKEY
		JMP     $A027           ; Restart BASIC
*		rts

		INCLUDE sub/MPBMUL.s
		INCLUDE leventhal/BN2HEX.s
		INCLUDE leventhal/MPBADD.s
		INCLUDE sub/IO.s

rsad		fqb	$0173c699
;rsad		fqb	$c6990000
rsad2		fqb	$00000000
rsae		fqb	$adfe34ac
;rsae		fqb	$34c00000
rsae2		fqb	$00000000
prod		fqb	$00000000
prod2		fqb	$00000000

		end	start
