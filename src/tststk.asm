;stub program just to test multiprecisionbyte multiplication

; This file is part of Color Computer RSA by Don Barber Copyright 2022

; Color Computer RSA is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

; Color Computer RSA is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along with Color Computer RSA. If not, see <https://www.gnu.org/licenses/>.


MPLEN		equ	8
CR              EQU     13


		org $0E00

start	

		tfr	s,x
		pshs	x
		leax	,s
		ldd	#2
		jsr	BNHEXOUT
		puls	x

finish		
		lbsr	WAITKEY
		JMP     $A027           ; Restart BASIC
*		rts

		INCLUDE leventhal/BN2HEX.s
		INCLUDE sub/IO.s

		end	start
