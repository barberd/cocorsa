;stub program just to test reforming the license file on the fly

; This file is part of Color Computer RSA by Don Barber Copyright 2022

; Color Computer RSA is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

; Color Computer RSA is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along with Color Computer RSA. If not, see <https://www.gnu.org/licenses/>.

CR              EQU     13


		org $0E00

start	

;		LDA	$FF90		; trying to get into coco3 text mode for 
;		ANDA	#$7F		; 32-character wide screen  with lowercase
;		ORA	#$40
;		STA	$FF90

;		LDA	#$10
;		STA	$FF22

		JSR	DSKINIT

                LEAS    -267,S
                TFR     S,U

                LDA     HRWIDTH
                BNE     showlicnot32    ;32 column
                LDA     #15
                LDB     #32
                JMP     showlicdonesize
showlicnot32:
                CMPA    #1
                BNE     showlicnot40    ;40 column
                LDA     #23
                LDB     #40
                JMP     showlicdonesize
showlicnot40:
                LDA     #23
                LDB     #80
showlicdonesize:

                STA     SCRHEIGHT
                STB     SCRWIDTH

                LEAS    -256,S

                LDA     DEFDRV
                PSHS    A
                ldx     #COPYINGFNAME
                PSHS    X
                CLRA
                PSHS    A
                PSHS    U
                JSR     DSKFOPEN
                TSTA
                LBNE    showlicenseerror

                CLR     CURLINE
                CLR     CURCOL
		LDD	#0		; initial buffer to read

showlicreadbuf: 
		LEAY	D,S
		PSHS	D
		LDD	#256
		SUBD	,S++	
bp0		PSHS    U,Y,D
                JSR     DSKFREAD
                CMPD    #0
                LBEQ    showlicdoneread
		TFR	D,X

showlicinnerloop:
		LDA	,Y+

		CMPA	#$60
		BNE	showlicnot60
		LDA	#$27
showlicnot60:
		
		CMPA	#$0A
		BNE	showlicnotlf

		LDB	HRWIDTH
		CMPB	#$02
		BEQ	showlicis80
bp2		CMPA	-2,Y 
		BNE	showlicnot80
		JSR	CROUT
		INC	CURLINE
showlicis80:
		JSR	CROUT
		INC	CURLINE
		CLR	CURCOL
		JMP	showlicchecknewline
showlicnot80:
		LDA	#$20
		JMP	showlicnot80tstsp
showlicnotlf:
		LDB	HRWIDTH
		CMPB	#$02
		BEQ	showlicnotni

		CMPA	#$20
		BNE	showlicnotsp

		LDB	-2,Y
		CMPB	#$20
		LBEQ	showlicnonp
		CMPB	#$0A
		BEQ	showlicnonp

showlicnot80tstsp:

		TST	CURCOL		; if in width 32 or 40 modes 
		BEQ	showlicnonp	; and space is beginning of line
					; don't output
showlicnotsp:

		JMP	showlicnotni
		TST	HRWIDTH
                BNE     showlicnotni
                CMPA    #$61
                BLT     showlicnotni
                CMPA    #$7A
                BGT     showlicnotni
                SUBA    #$20            ;make capital (not inverted)
showlicnotni:

                JSR     PUTCHR
		LDB	CURCOL
		INCB
		STB	CURCOL
		CMPB	SCRWIDTH
		BCS	showlicnonp
		CLR	CURCOL
		INC	CURLINE

		CMPA	#$20
		BEQ	showlicnowrap

		LDB	,Y
		CMPB	#$0A
		BEQ	showlicnowrap
		CMPB	#$20
		BEQ	showlicnowrap

		;JMP	showlicnotcol0

		PSHS	Y,X		; store Y and X here
		LEAY	4,S
		PSHS	Y
		LDY	4,S
		CLRB
showlicfindsp:	
		CMPY	,S		; check if Y buffer back at beginning
		BEQ	showlicfoundsp  ; if so then quit looking for space
		LDA	,-Y
		LEAX	1,X
		CMPA	#$0A
		BEQ	showlicfoundsp
		CMPA	#$20	
		BEQ	showlicfoundsp
		INCB
		CMPB	SCRWIDTH        ; if already backspaced the whole line
		BEQ	showlictoolong  ; then quit looking for space
		JMP	showlicfindsp
showlictoolong:
		LEAS	2,S
		PULS	Y,X
		JMP	showlicnowrap	

showlicfoundsp:	
		LEAS	6,S		; get rid of original Y location
	
		LDA	#$08
showlicbackspace:				
		JSR	PUTCHR
		DECB
		BNE	showlicbackspace	

		JSR	CROUT
		;INC	CURLINE
		;CLR	CURCOL
		LDA	#$20
showlicnowrap:

showlicchecknewline:
		LDA	CURLINE
		CMPA	SCRHEIGHT
		BCC	showlicprompt
showlicnonp:
		LEAX	-1,X
bp1		LBNE	showlicinnerloop
		LDD	#0
		JMP	showlicreadbuf

showlicprompt:
                JSR     DSKTURNOFFMOTORS
		PSHS	U,Y,X
showlicpromptloop:
                JSR     KEYIN
                BEQ     showlicpromptloop
		PULS	U,Y,X
                CMPA    #'Q
                BEQ     showlicdoneread
                CMPA    #'q
                BEQ     showlicdoneread
                CMPA    #$03
                BEQ     showlicdoneread
		CLR	CURCOL
		CLR	CURLINE
		JMP	showlicnonp
showlicdoneread:
                PSHS    U
                JSR     DSKFCLOSE
                JMP     showlicensedone
showlicenseerror:
               	LDX     #STRFOPENERROR
                JSR     STROUTWRAP
                JSR     CROUT
showlicensedone:
                JSR     DSKTURNOFFMOTORS
                LEAS    256,S
                LEAS    267,S

		JMP	WAITKEY

                JMP     $A027           ; Restart BASIC
		rts

CURLINE         rmb     1
CURCOL		rmb	1
SCRWIDTH        rmb     1
SCRHEIGHT       rmb     1
COPYINGFNAME		fcc     "COPYING    " ;11 bytes, spaces for null
STRFOPENERROR	fcn	"Error opening file."
STRINGBUF	rmb	80


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

		INCLUDE sub/IO.s
                include sub/DSKIO.s
                include leventhal/BN2HEX.s

		end	start
