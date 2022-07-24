;stub program just to test disk access

; This file is part of Color Computer RSA by Don Barber Copyright 2022

; Color Computer RSA is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

; Color Computer RSA is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along with Color Computer RSA. If not, see <https://www.gnu.org/licenses/>.

MPLEN		equ	8
CR              EQU     13


		org $0E00

start	

		JSR	DSKINIT

		clra
		pshs	a
		ldx	#DIRBUF
		pshs	x
		JSR	DSKDIR

		;clra
		;pshs	a
		;JSR	DSKLOADFAT

		clra			
		pshs	a		; set drive
		ldx	#TSTNAME
		pshs	x		; filename
		lda	#0
		pshs	a		; set read
		ldx	#FCB
		pshs	x
		JSR	DSKFOPEN

		TSTA
		LBNE	exitnotfound

		;LDX	#FCB
		;pshs	x
		;LDD	#0
		;#LDD	#0
		;pshs	d
		;LDA	#20
		;pshs	a
		;JSR	DSKFSEEK

		LDA	#0
		PSHS	A
		LDX	#TSTNAME2
		PSHS	X	
		LDA	#5
		PSHS	A
		LDA	#$FF
		PSHS	A
		JSR	DSKNEWFILE

		PSHS	A
		TFR	S,X
		LDD	#1
		JSR	BNHEXOUT
		LEAS	1,S


		JSR	CROUT

		clra			
		pshs	a		; set drive
		ldx	#TSTNAME2
		pshs	x		; filename
		lda	#2
		pshs	a		; set write
		ldx	#FCB2
		pshs	x
		JSR	DSKFOPEN

rwloop:

		LDX	#FCB
		pshs	x
		LDX	#STRINGBUF
		pshs	x
		;LDX	#256
		LDX	#128
		;LDX	#250
		;LDX	#1
		pshs	x
		JSR	DSKFREAD

bp12		PSHS	D	; store count for later
				; in write

		LDA	STRINGBUF
		CMPA	#$0A
		BNE	notnewline
		LDA	#$0D
notnewline:
		JSR	PUTCHR

		;EXG	A,B
		;PSHS	D
		;TFR	S,X
		;LDD	#2
		;JSR	BNHEXOUT
		;LEAS	2,S

		;JSR	CROUT

;		LDX	#FCB
;		PSHS	X
;		JSR	DSKFTELL

		PULS	D

		CMPD	#0
		BEQ	rwloopdone	; if read 0, then exit

		LDX	#FCB2
		pshs	x
		LDX	#STRINGBUF
		pshs	x
		pshs	d
		JSR	DSKFWRITE

		PSHS	D

		;PSHS	A
		;LDA	#$20
		;JSR	PUTCHR
		;PULS	A

		;EXG	A,B
		;PSHS	D
		;TFR	S,X
		;LDD	#2
		;JSR	BNHEXOUT
		;LEAS	2,S

		;JSR	CROUT

		PULS	D

;		CMPD	#256
;		BNE	rwloopdone	; if write is not 256, then exit

		CMPD	#$FFFF
		BEQ	rwlooperror

		JMP	rwloop

rwlooperror:
		

rwloopdone:

		LDX	#FCB2
		PSHS	X
		JSR	DSKFCLOSE	

		PSHS	A
		TFR	S,X
		LDD	#1
		JSR	BNHEXOUT
		LEAS	1,S

		JSR	CROUT

		CLRA
		PSHS	A
		LDX	#TSTNAME2
		PSHS	X
		LDX	#STATBUF
		PSHS	X
		JSR	DSKSTAT

		LDX	#STATBUF+32
		LDD	#3
		JSR	BNHEXOUT

		JSR	CROUT

;		LDA	#0
;		PSHS	A
;		LDX	#TSTNAME
;		PSHS	X
;		JSR	DSKKILLFILE

		PSHS	A
		TFR	S,X
		LDD	#1
		JSR	BNHEXOUT
		LEAS	1,S

		JSR	CROUT

exitnotfound:

		JSR	DSKTURNOFFMOTORS

		JSR	WAITKEY

                JMP     $A027           ; Restart BASIC
		rts

SEQOFNAME	fcc     "SEQOUT  TXT" ;11 bytes, spaces for null
SEQIFNAME	fcc     "SEQIN   TXT" ;11 bytes, spaces for null
RANDOFNAME	fcc     "RANDOUT TXT" ;11 bytes, spaces for null
RANDIFNAME	fcc     "RANDIN  TXT" ;11 bytes, spaces for null
TSTNAME		fcc     "COPYING    " ;11 bytes, spaces for null
TSTNAME2	fcc     "COPYING2   " ;11 bytes, spaces for null
DIRBUF		rmb	2304 ;9 sectors * 256 bytes per sector
STATBUF		rmb	35
STRINGBUF	rmb	256


FCB		rmb	267	; 0: drive num
				; 1: read (0) or write (1) 
				; 2: Directory entry Sector
				; 3: Directory entry offset
				; 4: start granule # in FAT
				; 5: current granule # in chain 0-indexed,
				; 6: current sector in granule 0-indexed
				; 7: current byte in sector 0-indexed
				; 8-9: bytes in last sector
				; 10: 0: buffer has not been read or flushed
				;     1: buffer has been read from disk
				;     80: buffer ready for writing
				; 11-266: buffer for disk

FCB2		rmb	267

		INCLUDE sub/IO.s
                include sub/DSKIO.s
                include leventhal/BN2HEX.s

		end	start
