; pretty standard pseudo RNG
; Algorithm probably originally from Knuth

; This file is part of Color Computer RSA by Don Barber Copyright 2022

; Color Computer RSA is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

; Color Computer RSA is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along with Color Computer RSA. If not, see <https://www.gnu.org/licenses/>.


RANDOM				; 16-bit pseudorandom generator
				; seed comes from d register
		ldd	SEED	
		pshs	d
                adda    1,S	; d = old random * $101
                aslb            ; d = old random * $202
                rola
                adda    1,S	; d = old random * $302
                aslb            ; d = old random * $604
                rola
                addd    ,S      ; d = old random * $605
                addd    #13849 	; d is now new random number
		std	SEED
		leas	2,s
                rts

SEEDRANDOM	
		lda	275	; load from timer
		ldb	275
		std	SEED
		rts

SEED		rmd	1

