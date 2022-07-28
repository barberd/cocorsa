; Disk IO Routines

; This file is part of Color Computer RSA by Don Barber Copyright 2022

; Color Computer RSA is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

; Color Computer RSA is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along with Color Computer RSA. If not, see <https://www.gnu.org/licenses/>. 

; Also its easy to overwrite the needed portions of basic in RAM
; if you aren't careful with the stack size or location
; eg, make sure the disk basic rom in C000-DFFF is not overwritten or paged out
; as the DSKCON function is used

; Note also that the DSKRWSEC routine checks a 'cpu6309flag'
; If you are using this routine outside of Color Computer RSA
; you'll need to handle this yourself
; Perhaps with a 6309 check inside the DSKINIT routine to set the flag

; The file handler (or file control block, FCB) needs 267 bytes:
			        ; 0: drive num
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


;equates used for DSKCON
;see page 60 in the Color Computer Disk System Guide, available at
;https://colorcomputerarchive.com/repo/Documents/Manuals/Hardware/Color%20Computer%20Disk%20System%20(Tandy).pdf
DCOPC	equ	0
DCDRV	equ	1
DCTRK	equ	2
DCSEC	equ	3
DCBPT	equ	4
DCSTA	equ	6

DEFDRV	equ	$095A

;initialize the FAT to all 0s
DSKINIT
	PSHS	X,U
	LDU	#FAT
	LDX	#(70*4)
dskinitloop:
	CLR	,U+
	LEAX	-1,X
	BNE	dskinitloop	
	CLR	DSKERROR
	PULS	U,X,PC

;input: operation       1+7,S 
;	drive number    1+6,S
;       track number    1+5,S
;       sector number   1+4,S
;       buffer pointer  1+2,S
;output: success or failure 0 is success, error otherwise
DSKRWSEC
	PSHS	B
	LDX	$C006
	LDA	1+7,S
	STA	,X		;DCOPC 2=READ 3=WRITE
	LDA	1+6,S
	STA	DCDRV,X
	LDA	1+5,S	
	STA	DCTRK,X
	LDA	1+4,S
	STA	DCSEC,X
	LDD	1+2,S
	STD	DCBPT,X
	;return to emulation mode temporarily if running on a 6309
	TST	cpu6309flag
	BNE	dskrwsecnot6309
	LDMD	#$0
	JSR	[$C004]
	LDMD	#$1
	JMP	dskrwsecdonerw
dskrwsecnot6309:
	JSR	[$C004]
dskrwsecdonerw:
	LDA	DCSTA,X
	STA	DSKERROR
	PULS	B
        LDX     ,S
        LEAS    8,S
        JMP     ,X

; input: 
;       drive number                  5+7,S
;	pointer to filename           5+5,S
;       read, write, or append flag   5+4,S
;       pointer to buffer for FCB     5+2,S
; output: success or failure
DSKFOPEN
	CLR	DSKERROR
	PSHS	U,Y,B
	; find entry in directory 
	LEAS	-256,S
	TFR	S,U
	LDA	256+5+7,S
	PSHS	A
	LDX	1+256+5+5,S	; load filename
	PSHS	X
	PSHS	U
	JSR	DSKFINDFILE
	TSTA
	BNE	dskfopenfoundfile
	LDA	#$FE			; file not found
	STA	DSKERROR
	JMP	dskfopenerror
dskfopenfoundfile:
	PSHS	A
	CLRA
	LEAU	D,U	
	PULS	A
	; entry is in U
	;13,U byte is first granule
	;14,U double is # of bytes in last sector
	; set up FCB
	LDX	256+5+2,S	
	STA	2,X	; store sector
	STB	3,X	; store entry offset
	LDA	256+5+7,S
	STA	,X	; store drive num
	LDA	13,U	; store first granule
	STA	4,X
	LDD	14,U
	STD	8,X	; store # of bytes in last sector
	; set read or write flag
	LDA	256+5+4,S
	STA	1,X
	;set buffer as not read nor ready to write
	CLR	10,X
	LDA	,X		; load drive num as param
	PSHS	X
	PSHS	A
	JSR	DSKLOADFAT	; load FAT into memory
	PULS	X
	INC	,Y		; increment open file count
	LDA	1,X		; load open type
	CMPA	#2		; check for append
	BEQ	dskfopenappend
	; set position to 0
	LDD	#0	; next three bytes is position in file
	STD	5,X	; granule and sector
	STA	7,X 	; this is byte # in last sector
	;if write, then free up all granules except for first, and set
	;first granule to $C1
	TST	1,X		; only free up granules if opened as write
	BEQ	dskfopendonepos ; so skip if opened as read

	LEAY	3,Y		; now at FAT
	LDA	4,X
	LDB	A,Y
	PSHS	B
	LDB	#$C1
	STB	A,Y
	STB	-1,Y		; mark fat as needing flushed
	PULS	B
	CMPB	#$C0
	BCC	dskfopendonepos
dskfopengranloop:
	LDA	B,Y
	PSHS	A
	LDA	#$FF
	STA	B,Y
	PULS	B
	CMPB	#$C0
	BCS	dskfopengranloop
	JMP	dskfopendonepos
dskfopenappend:
	LDA	#1	; since append is write from eof, adjust flag to write
	STA	1,X	
	; first two bytes = (granules-1) * 9 + sector count in last granule - 1
	; next byte is bytes in last sector
	LDB	13,U	; load first granule
	LEAY	3,Y	; move to beginning of granule table
	LDA	#-1
dskfopengranulechainloop:
	INCA
	LDB	B,Y
	CMPB	#$C0
	BCS	dskfopengranulechainloop

	ANDB	#$3F
	DECB
	LDY	14,U
	CMPY	#256
	BNE	dskfopennonewsector
	INCB
	CMPB	#10
	BNE	dskfopennonewgranule
	INCA
dskfopennonewgranule:
dskfopennonewsector:
	STA	5,X	; store position in granule chain (granule #)
	STB	6,X	; store sector in granule
	TFR	Y,D	; load # of bytes in the last sector
	STB	7,X	; store # of bytes in last sector
dskfopennonewsector2:
dskfopennonewgranule2:
dskfopendonepos:
	CLRA
dskfopenerror:
	LEAS	256,S
	PULS	U,Y,B
	LDX	,S
	LEAS	8,S
	JMP	,X

; input: pointer to FCB     3+2,S
; output: boolean on if at EOF or not
DSKFEOF
	CLR	DSKERROR
	PSHS	Y,B
	LDX	3+2,S
	;error if past EOF and set to end
	LDA	,X
	LDB	#70
	MUL
	LDY	#FAT+3
	LEAY	D,Y
	LDA	4,X
	LDB	#-1
dskfeoffollowgranule
	INCB
	LDA	A,Y
	CMPA	#$C0
	BCS	dskfeoffollowgranule

	CMPB	5,X
	BNE	dskfeofnoteof ; if lower granule, keep going
	ANDA	#$3F
	DECA
	CMPA	6,X
	BNE	dskfeofnoteof ; if lower sector, keep going

	CLRA
	LDB	7,X
	PSHS	D
	LDD	8,X
	CMPD	,S++
	BNE	dskfeofnoteof ; if lower sector, keep going
	LDA	#1
	JMP	dskfeofdone
dskfeofnoteof:
	CLRA
dskfeofdone:
	PULS	Y,B
	LDX	,S
	LEAS	3,S
	JMP	,X

; input: pointer to FCB   1+2,S
; output: location in file (three bytes) registers Y and A
DSKFTELL
	CLR	DSKERROR
	PSHS	B
	LDX	1+2,S
	CLRA
	LDB	6,X
	PSHS	D
	LDB	5,X
	LDA	#9
	MUL
	ADDD	,S++
	TFR	D,Y
	LDA	7,X
	PULS	B
	LDX	,S
	LEAS	4,S
	JMP	,X

; Update FCB with new position
; Flush if changes current granule/sector and needs written
; input: pointer to FCB		3+5,S
;        location in file	3+3,S (sectors-1) and 
;				3+2,S (byte in last sector)
; output: success or failure
; Note this does NOT allocate new granules (that is done in DSKFWRITE)
; so this function may return success even when disk space is not
; available when seeking past EOF
DSKFSEEK
	CLR	DSKERROR
	PSHS	Y,B
	; three-byte position to granule math is:
	; byte 0,1 double is sectors-1
	; byte 2 is bytes in last sector

	; This next bit of code divides the sector count by 9 in order
	; to get granules.		
	; Magic number for this is multiply by 57 and shift down by 9.
	; q = (n*57)>>9 = (n<<5 + n<<4 + n<<3 + n)>>9
	; Shifting down by 9 is just taking the top half of
	; D register (the A register) to lose 8 bits and then shift down by 
	; 1 bit
	; Remainder is sectors in last granule - 1
	; r = n - q<<3 - q

	LDD	3+3,S
	TFR	D,Y	; store N
	PSHS	D	; store N on stack as well
	ANDCC	#$FE
	ROLB
	ROLA
	ANDCC	#$FE
	ROLB
	ROLA
	ANDCC	#$FE
	ROLB
	ROLA
	PSHS	D	; store N<<3
	ANDCC	#$FE
	ROLB
	ROLA
	PSHS	D	; store N<<4
	ANDCC	#$FE
	ROLB
	ROLA
	; now at N<<5
	ADDD	,S++	; add N<<4
	ADDD	,S++	; add N<<3
	ADDD	,S++	; add N
	; shift A register down by one bit
	ANDCC	#$FE
	RORA	
	; A now contains quotient, which is the granule #
	TFR	D,X	; X MSB now contains granule, 0-indexed

	; Now multiply Q by 9 then 
	LDB	#9
	MUL
	PSHS	D
	TFR	Y,D
	SUBD	,S++	; B has sector #, 0-indexed

	PSHS	B
	TFR	X,D	; A has granule #, 0-indexed
	PULS	B	; A has granule, B has sector

	LDX	3+5,S
	CMPB	6,X	
	BNE	dskfseekchanged	; so will avoid one compare
	CMPA	5,X
	BNE	dskfseekchanged
	JMP	dskfseeknotchanged
dskfseekchanged:	
	;its changed!  flush out disk if needed.
	PSHS	A
	LDA	10,X
	BITA	#$80
	PULS	A
	BEQ	dskfseeknoflush
	PSHS	X
	PSHS	X
	JSR	DSKFFLUSH
	PULS	X
dskfseeknoflush:		
	STA	5,X
	STB	6,X
	CLR	10,X 	; clear so has not been read nor changed for write
dskfseeknotchanged:
	;store byte position in last sector
	LDA	3+2,S
	STA	7,X

	LDA	1,X		; only check if past EOF if read-only
	BNE	dskfseekdone	; if read/append then skip to done

	;error if past EOF and set to end
	LDA	,X
	LDB	#70
	MUL
	LDY	#FAT+3
	LEAY	D,Y
	LDA	4,X
	LDB	#-1
dskfseekfollowgranule
	INCB
	LDA	A,Y
	CMPA	#$C0
	BCS	dskfseekfollowgranule

	CMPB	5,X
	BHI	dskfseeknoteof ; if lower granule, keep going
	ANDA	#$3F
	DECA
	CMPA	6,X
	BHI	dskfseeknoteof ; if lower sector, keep going

	;set position to EOF
	STB	5,X
	STA	6,X
	LDD	8,X
	; handle special case where final sector is completely full
	; by rolling over to next sector, which may roll over granule
	CMPD	#256
	BNE	dskfseeknotendofsector
	LDA	6,X
	INCA
	STA	6,X
	CMPA	#9
	BCS	dskfseeknonewgranule
	CLR	6,X
	INC	5,X
dskfseeknonewgranule:
dskfseeknotendofsector:
	STB	7,X
	LDA	#$FF
	STA	DSKERROR
	JMP	dskfseekerror
dskfseeknoteof:
dskfseekdone:
	CLRA
dskfseekerror:	
	PULS	Y,B
	LDX	,S
	LEAS	3,S
	JMP	,X	

;input drive num
;output granule number in A

;start check at granule 35, once reached 68 then roll over to granule 0
;and check until reaching 34, then return error that disk is full
DSKGETFREEGRANULE
	CLR	DSKERROR
	LDA	2,S
	PSHS	U,B
	LDB	#70
	MUL
	LDU	#FAT+3
	LEAU	D,U
	LDA	#35
dskgetfreegranloop:
	LDB	A,U
	CMPB	#$FF
	BEQ	dskgetfreegrandone
	CMPA	#34
	BEQ	dskgetfreeerror
	INCA
	CMPA	#68
	BNE	dskgetfreegranloop
	LDA	#0
	JMP	dskgetfreegranloop
dskgetfreeerror:
	LDA	#$FB
	STA	DSKERROR
dskgetfreegrandone:
	PULS	U,B
	LDX	,S
	LEAS	3,S
	JMP	,X	

;input: pointer to FCB			6+6,S
;       pointer to buffer		6+4,S
;       length of data to write		6+2,S
; output: bytes written
DSKFWRITE
	CLR	DSKERROR
	PSHS	U,Y
	LDD	#0
	PSHS	D
	LDX	6+6,S	; load FCB

	LDA	1,X		; check if read or write mode
	BNE	dskfwritecont	; if read-only then exit
	LDA	#$FC		; attemping to write on read-only
	STA	DSKERROR
	JMP	dskfwriteerror
dskfwritecont:
dskfwriterestart:
	;figure out if trying to write past EOF and allocate new granule 
	;if needed
	LDA	,X		; load drive number
	LDB	#70
	MUL
	LDU	#FAT+3
	LEAU	D,U		; load FAT location into U
	PSHS	X
	LDB	4,X		; start granule 
	PSHS	B
	CLRA
	LDB	5,X		; load granule chain # we're supposed to be on
	TFR	D,X	
	PULS	B
	LEAX	1,X
dskfwritefollowgranule
	LEAX	-1,X
	BEQ	dskfwritechksect ; we're not past allocated granules but
				; we've loaded the one we want, so
				; skip allocation
	TFR	B,A
	LDB	A,U		; load next granule in chain into A
	CMPB	#$C0		; check if on final granule
	BCS	dskfwritefollowgranule	; its not, loop again
	PSHS	A		; A is last granule
	TFR	X,D		; B is count of granules still needed
	PULS	A,X
	; we're on the last allocated granule but haven't gotten to the
	; granule number we want. So need to allocate more.

	;A is now last granule, B is number of granules needed

dskfwriteallocgranuleloop:
	PSHS	B
	PSHS	X,A
	LDA	,X
	PSHS	A
	JSR	DSKGETFREEGRANULE
	CMPA	#$FF
	BNE	dskfwriteallocgranule
	LDX	1,S
	LEAS	4,S
	LDD	#256
	STD	8,X
	LDA	#$FB
	STA	DSKERROR
	JMP	dskfwriteerror
dskfwriteallocgranule
	LDB	#$C1
	STB	A,U
	PULS	B	
	STA	B,U
	LDB	#$FF
	STB	-1,U		; mark FAT as needing flushed
	PULS	X
	PULS	B
	DECB
	BNE	dskfwriteallocgranuleloop	
	JMP	dskfwriteallocgranuledone
dskfwritechksect:
	PULS	X
dskfwriteallocgranuledone:
	;check if pointer is at beginning of sector
	;and data to write is at least 256 bytes
	;if so, then no need to fill the buffer first
	LDA	7,X
	BNE	dskfwriteneedbuf
	LDD	6+2,S
	CMPD	#256
	BGT	dskfwritebufgood
dskfwriteneedbuf
	LDA	10,X
	BITA	#$01
	BNE	dskfwritebufgood
	;read from disk to fill buffer here
	PSHS	X
	PSHS	X
	JSR	DSKFFILLBUF	
	PULS	X
dskfwritebufgood:
	
	LEAY	11,X		; load destination buffer address into Y
	CLRA	
	LDB	7,X
	LEAY	D,Y		; move pointer to current location in buffer

	CLRA
	PSHS	D
	LDD	#256
	SUBD	,S++		; calculate bytes left in sector

	PSHS	U,X,D		; store this-sector buffer length and FCB pointer
	LDU	6+6+4,S		; load in source buffer

	TFR	D,X
	CMPD	6+6+2,S
	BCS	dskfwritedocopy
	LDX	6+6+2,S
dskfwritedocopy:
	LDD	6,S	; add amount written for return
	PSHS	X
	ADDD	,S++
	STD	6,S

dskfwritecopy2buf
	LDA	,U+	; load from source buffer
	STA	,Y+	; store in dest buffer (FCB)
	LEAX	-1,X
	BNE	dskfwritecopy2buf
	STU	6+6+4,S		; update new buffer pointer

	PULS	U,X,D		; restore this-sector buffer length and FCB pointer
	PSHS	A
	LDA	10,X		; set that buffer needs flushed to disk
	ORA	#$80
	STA	10,X
	PULS	A

	CMPD	6+2,S
	BCS	dskfwritemultisector

	; this block is for rest of write is in same buffer and doesn't fill
	; buffer enough to roll over to next one

	;update FCB current byte position in sector to new position
	CLRA
	LDB	7,X
	PSHS	D
	LDD	2+6+2,S
	ADDD	,S++
	STB	7,X

	;LDD	#0
	;STD	6+2,S		; set remaining byte to read to 0
	CLR	6+2,S
	CLR	6+2+1,S

	CMPD	#256
	BCC	dskfwritenewsector
	
	; update FAT and FCB if writing past EOF
	; this doesn't allocate new granule (that was done earlier)
	; it just updates the # of sectors in the granule
	; and the number of bytes in the last sector in the directory entry
	LDA	4,X	; start granule
	LDB	5,X	; number of granules to load
dskfwritegranuleloop:
	BEQ	dskfwritegranuleloopdone
	LDA	A,U			; U is FAT
	DECB
	JMP	dskfwritegranuleloop
dskfwritegranuleloopdone:	

	;A is current granule
	LDB	A,U
	CMPB	#$C0			; checking if granule is final
	BCS	dskfwritefinalsectordone		; if not, move on
	ANDB	#$3F			; check if accessing past final sector
	DECB				; decrement to get 0-indexed
	CMPB	6,X
	BHI	dskfwritefinalsectordone		; if not, move on
	BNE	dskfwritenewsect
	;if here, then writing to last sector, so check to see if
	;end pointer is past the old 'bytes in last sector'
	;and update the 'bytes in last sector' to match
	CLRA
	LDB	7,X
	CMPD	8,X			; if pointer is less than last sector
	BCS	dskfwritefinalsectordone		; byte then do nothing
	STD	8,X			; otherwise store new pointer
	JMP dskfwritefinalsectordone
dskfwritenewsect:	
	;if here, then this is a new sector inside the granule so update both
	;sector in FAT and new pointer in FCB
	LDB	6,X
	INCB				; increment again as stored 1-indexed
	ORB	#$C0
	STB	A,U			; update final sector in FAT
	CLRA
	LDB	7,X
	STD	8,X	
dskfwritefinalsectordone
	PULS	D
	JMP dskfwritedone

dskfwritemultisector:

	; this block is when write will go past the current buffer
	; D has length of current buffer
	;set up stack to loop with new numbers and location	
	PSHS	D
	LDD	2+6+2,S
	SUBD	,S++		; subtract count by current byte-in-sector count
	STD	6+2,S		; and store in new count

dskfwritenewsector:

	;done with this sector so flush to disk here
	PSHS	X
	LDX	2+6+6,S
	PSHS	X
	JSR	DSKFFLUSH
	PULS	X

	
	CLR	10,X		; new sector, buffer needs filled and shouldnt
				; be written

	; update sector count in FCB and granule if necessary
	LDA	6,X
	INCA
	CMPA	#9
	BCS	dskfwritesamegranule
	INC	5,X		; increment granule
	CLRA			; set sector to 0
dskfwritesamegranule:
	STA	6,X		; store new sector

	LDA	4,X	; start granule
	LDB	5,X	; number of granules to load
dskfwritegranuleloop2:
	BEQ	dskfwritegranuleloopdone2
	LDA	A,U			; U is FAT
	CMPA	#$C0			; hit end granule before finished loop
	BCC	dskfwritenewsectoreof	; which means we're past EOF
	DECB
	JMP	dskfwritegranuleloop2
dskfwritegranuleloopdone2:	
	;A is current granule
	LDB	A,U
	CMPB	#$C0			; checking if granule is final
	BCS	dskfwritenewsectornoteof		; if not, move on
	ANDB	#$3F			; check if accessing past final sector
	DECB				; decrement to get 0-indexed
	CMPB	6,X
	BCC	dskfwritenewsectornoteof ; eof sector is higher or same
					 ; so NOT eof
dskfwritenewsectoreof:
	LDD	#256			 ; its EOF, so update EOF final
	STD	8,X			 ; sector count
dskfwritenewsectornoteof:

	LDD	6+2,S
	CMPD	#0
	LBNE	dskfwriterestart

	; All done!  Pull the total count off the stack so we can return it
	PULS	D
	JMP	dskfwritedone
dskfwriteerror:
	LDD	#$FFFF
	LEAS	2,S
dskfwritedone:
	PULS	U,Y
	LDX	,S
	LEAS	8,S
	JMP	,X

;input: pointer to FCB			6+6,S
;       pointer to buffer		6+4,S
;       length of data to read		6+2,S
; output: number of bytes read
DSKFREAD
	CLR	DSKERROR
	PSHS	U,Y
	LDD	#0
	PSHS	D	
dskfreadrestart:
	LDX	6+6,S	; load FCB
	LDA	10,X
	BITA	#$01
	BNE	dskfreadbufgood
	;read from disk to fill buffer here
	PSHS	X
	PSHS	X
	JSR	DSKFFILLBUF	
	PULS	X
dskfreadbufgood:
	LDA	,X
	LDB	#70
	MUL
	LDU	#FAT+3
	LEAU	D,U

	LDA	4,X
	LDB	#-1
dskfreadfollowgranule
	INCB
	LDA	A,U
	CMPA	#$C0
	BCS	dskfreadfollowgranule

	; set up Y and U source and destination buffers
	LEAY	11,X		; load source buffer address into Y
	TFR	D,U		; store D
	CLRA
	LDB	7,X
	LEAY	D,Y		; move point to current location in buffer
	TFR	U,D		; restore D

	LDU	6+4,S		; load in destination buffer

	; now check if going past eof or not
	CMPB	5,X
	BHI	dskfreadnoteof 	; if lower granule, keep going
	ANDA	#$3F
	DECA			; make 0-indexed
	CMPA	6,X
	BHI	dskfreadnoteof ; if lower sector, keep going
	;since there shouldn't be a way for
	;dskfreadf to get into a state where its a greater
	;granule or sector than the end of file, therefore
	;we must be on the last granule and the last sector
	;so need to check if the 
	;current position + bytes to read > bytes in last sector
	CLRA
	LDB	7,X
	PSHS	D
	LDD	2+6+2,S
	ADDD	,S++		; this would be final position
	CMPD	8,X		; this is last byte in sector
	BCS	dskfreadnoteof	; we're not going to read past eof
				; so we're fine
	CLRA			
	LDB	7,X		; we're going to read past eof
	PSHS	D		; so let's subtract current pos
	LDD	8,X		; from bytes in sector
	SUBD	,S++		; and store that as the 
	STD	6+2,S		; amount to read
	JMP	dskfreadonebuffer

dskfreadnoteof:
	CLRA
	LDB	7,X
	PSHS	D
	LDD	#256
	SUBD	,S++		; calculate bytes left in sector

	CMPD	6+2,S		; if amount to read is greater than remaining
	BCS	dskfreadmultisector ; in sector, then follow multisector code
				; otherwise keep going with one buffer

dskfreadonebuffer:
	; this block is for rest of read is in same buffer
	; update FCB current byte position in sector to new position
	CLRA
	LDB	7,X
	PSHS	D
	LDD	2+6+2,S
	ADDD	,S++

	STB	7,X	

	CMPD	#256
	BNE	dskfreadsamesector
	LDD	6+2,S
	CLR	6+2,S			; set remaining bytes to read to 0
	CLR	6+3,S
	JMP	dskfreadnewsector

dskfreadsamesector:
	LDX	6+2,S
	CLR	6+2,S
	CLR	6+3,S
	JMP dskfreaddoread

dskfreadmultisector:

	; this block is when read will go past the current buffer
	; D has length of current buffer

	;set up stack to loop with new numbers and location	
	; subtract count by length of current buffer left
	; (should be 0 if done)

	PSHS	D
	LDD	2+6+2,S
	SUBD	,S
	STD	2+6+2,S		; and store in new count
	PULS	D

dskfreadnewsector:
	PSHS	U,D
	; update sector count in FCB and granule if necessary
	LDA	6,X
	INCA
	CMPA	#9
	BCS	dskfreadsamegranule
	INC	5,X		; increment granule
	CLRA			; set sector to 0
dskfreadsamegranule:
	STA	6,X		; store new sector
	CLR	7,X		; store byte position as 0
	CLR	10,X		; mark buffer as needing filled
	PULS	X,U	; pull to X instead of D

dskfreaddoread:
	CMPX	#0
	BEQ	dskfreaddone	; bail out if 0 bytes to read
	LDD	,S	; update total read count
	PSHS	X
	ADDD	,S++
	STD	,S
dskfreadcopy2buf
	LDA	,Y+
	STA	,U+
	LEAX	-1,X
	BNE	dskfreadcopy2buf

	STU	6+4,S		; store new buffer pointer
	LDD	6+2,S
	LBNE	dskfreadrestart	; loop around again with new 
				; granule/sector/bytes/dest
dskfreaddone
	PULS	U,Y,D
	LDX	,S
	LEAS	8,S
	JMP	,X

;input: pointer to FCB		4+2,S
;output: success or failure
DSKFCLOSE
	CLR	DSKERROR
	PSHS	Y,D
	LDX	6,S
	LDA	1,X			; check if read or write
	BEQ	dskfclosefilefat	; if read, then skip flush check
	; flush out FCB buffer if data needs written
	LDA	10,X			; it not dirty, no need to flush
	BITA	#$80
	BEQ	dskfclosenoflush
	TFR	X,Y
	PSHS	X			; push FCB and flush
	JSR	DSKFFLUSH	
	TFR	Y,X
dskfclosenoflush:
	;update directory entry with new # of bytes in last sector
	; from 8-9,S in FCB
	LEAS	-256,S		; make room on stack
	TFR	S,Y
	PSHS	X		; store FCB for later
	LDB	#2		; set operation to read
	LDA	,X		; drive num
	PSHS	D
	LDB	#17		; load track 17
	LDA	2,X		; sector for entry
	PSHS	D
	PSHS	Y
	JSR	DSKRWSEC	; directory sector now in memory
	PULS	X		; restore FCB
	CLRA
	LDB	3,X		; offset for entry
	LEAY	D,Y		; y now points at exact entry

	LDD	8,X		;update last bytes entry
	CMPD	14,Y		;compare to whats in the directory
	BEQ	dskfcloseskipupdate ; skip update if same	
	STD	14,Y
	TFR	S,Y
	PSHS	X		; store FCB for later
	LDB	#3		; write sector
	LDA	,X		; drive num
	PSHS	D
	LDB	#17		; store track 17
	LDA	2,X		; sector for entry
	PSHS	D
	PSHS	Y
	JSR	DSKRWSEC	; directory sector now in memory
	PULS	X		; restore FCB
dskfcloseskipupdate:
	LEAS	256,S		; free up stack of directory sector buffer
dskfclosefilefat:
	; decrement open files for drive fat buffers
	LDA	,X	; load drive num
	LDB	#70	; FAT entry is 70 bytes per drive
	MUL
	LDY	#FAT	; decrement from FAT record
	LEAY	D,Y
	DEC	,Y
	LDA	,X
	PSHS	A
	JSR	DSKFATFLUSH	; flush out even if still open by another file
;dskfclosefatstillopen
	PULS	D,Y
	LDX	,S
	LEAS	4,S
	JMP	,X
	
;input: drive num	5+6,S
;	new filename	5+4,S
;	file type	5+3,S	0=Basic program, 1=Basic data, 
;				2=ML program, 3=Text editor source file
;	ascii flag 	5+2,S   0=Binary, FF=Ascii
;output: success or failure
DSKNEWFILE
	CLR	DSKERROR
	;find available directory entry
	;allocate one granule
	;write appropriate entry
	; call disk fat buffer flush check
	PSHS	U,Y,B
	LEAS	-256,S
	TFR	S,U
	
	LDA	256+5+6,S		; drive number
	PSHS	A
	LDX	1+256+5+4,S		; new filename
	PSHS	X
	PSHS	U
	JSR	DSKFINDFILE
	TSTA
	BEQ	dsknewfilenewfile
	LDA	#$FD			; file already exists
	STA	DSKERROR
	LEAS	256,S
	JMP	dsknewfileerror
dsknewfilenewfile:
	;allocate 1 free granule and set to #$C0

	LDA	256+5+6,S
	PSHS	A		
	JSR	DSKLOADFAT
	LEAY	3,Y			; move to granule chain in FAT

	LDA	256+5+6,S
	PSHS	A
	JSR	DSKGETFREEGRANULE

	CMPA	#$FF
	BNE	dsknewfilefoundgran
	LDA	#$FB			; disk full
	STA	DSKERROR
	JMP	dsknewfileerror
	
dsknewfilefoundgran:
	LDB	#$C1
	STB	A,Y			; allocated granule
	STB	-1,Y			; mark FAT as dirty and needing flushed

	PSHS	A			; store granule location for later

	;loop over directory sectors and find a free entry
	;populate entry and rewrite to dsk
	LDB	#3

dsknewfilenewentryol:
	LDA	#2			; read sector
	PSHS	A
	LDA	2+256+5+6,S			; from drive #
	PSHS	A
	LDA	#17			; read track 17
	PSHS	A
	PSHS	B			; read track (starting with 3)
	PSHS	U
	JSR	DSKRWSEC
	PSHS	U,B
	LDB	#8
dsknewfilenewentryil:
	LDA	,U
	BEQ	dsknewfilefoundempty	; found entry starting with nul
	CMPA	#$FF
	BEQ	dsknewfilefoundempty	; found never-used entry
	LEAU	32,U
	DECB
	BNE	dsknewfilenewentryil	
	PULS	B,U
	INCB
	CMPB	#12	;if past sector 11 then stop
	BNE	dsknewfilenewentryol	
	LDA	#$FA			; directory full error
					; should never get this
					; as there are more possible entries
					; than granules
	STA	DSKERROR
	LEAS	257,S
	JMP	dsknewfileerror
dsknewfilefoundempty

	; fill out entry
	LDX	4+256+5+4,S
	LDB	#11
dsknewfilecopyfilenameloop:	
	LDA	,X+
	STA	,U+
	DECB
	BNE	dsknewfilecopyfilenameloop

	LDA	4+256+5+3,S
	STA	,U+			; store file type
	LDA	4+256+5+2,S
	STA	,U+			; store ascii flag
	# new granule here
	LDA	3,S
	STA	,U+			; store granule
	LDD	#0
	LDX	#9
dsknewfileloop:
	STD	,U++
	LEAX	-1,X
	BNE	dsknewfileloop

	PULS	B
	PULS	U
	LEAS	1,S			; don't need granule anymore
	;write sector back to disk			
	LDA	#3			; write
	PSHS	A
	LDA	1+256+5+6,S			; drive #
	PSHS	A
	LDA	#17			; write track 17
	PSHS	A
	PSHS	B			; write sector
	PSHS	U			; write buffer
	JSR	DSKRWSEC

	LEAS	256,S			; remove buffer from stack
	LDA	5+6,S
	PSHS	A
	JSR	DSKFATFLUSH		; store fat with new allocation to disk
	CLRA
dsknewfileerror:
	PULS	B,Y,U
	LDX	,S
	LEAS	7,S
	JMP	,X	

;input: drive num			5+4,S
;	filename of file to erase	5+2,S
;output: success or failure
DSKKILLFILE
	CLR	DSKERROR
	; find directory entry
	; replace first byte with \0
	; find granule chain and replace all with FF
	; call disk fat buffer flush check
	PSHS	U,Y,B
	LEAS	-256,S
	TFR	S,U
	
	LDA	256+5+4,S
	PSHS	A
	LDX	1+256+5+2,S
	PSHS	X
	PSHS	U
	JSR	DSKFINDFILE
	TSTA
	BNE	dskkillfilefound
	LDA	#$FE			;file not found
	STA	DSKERROR
	JMP	dskkillerror
dskkillfilefound:
	PSHS	A
	CLRA
	LEAY	D,U
	PULS	A
	CLR	,Y			;set first char to \0

	;write sector back to drive
	LDB	#17
	TFR	D,X			; sector in X MSB, in D LSB

	LDB	#3			;write operation
	LDA	256+5+4,S		;load drive num
	PSHS	D
	PSHS	X			;push sector and track
	PSHS	U
	JSR	DSKRWSEC	

	LDA	256+5+4,S		;load drive num
	LDB	#70
	MUL
	LDU	#FAT+3
	LEAU	D,U			; U is now pointer to fat
	LDB	13,Y
	LDA	#$FF
dskkillgranloop:	
	LEAX	B,U
	LDB	,X
	STA	,X
	CMPB	#$C0
	BCS	dskkillgranloop

	LDA	#$FF
	STA	-1,U			; mark FAT as needing flushed
	LDA	256+5+4,S
	PSHS	A
	JSR	DSKFATFLUSH
	CLRA
dskkillerror:
	LEAS	256,S
	PULS	B,Y,U
	LDX	,S
	LEAS	5,S
	JMP	,X

;input: drive number 4+4,S
;       pointer to results buffer. Must be 2176 (68*32) bytes long 4+2,S
;output: success or failure
DSKDIR
	CLR	DSKERROR
	; start with track 17 sector 3, loop until sector 11
	; copy data to buffer
	PSHS	U,D

	LDB	#3	; set sector
	LDU	6,S
dirloop	LDA	#2	;read
	PSHS	A
	LDA	1+4+4,S	;set drive
	PSHS	A
	LDA	#17	; set track
	PSHS	A
	PSHS	B
	PSHS	U	;set destination buffer
	JSR	DSKRWSEC
	LEAU	256,U	;increment buffer by sector size
	INCB		;increment sector
	CMPB	#12	;if past sector 11 then stop
	BNE	dirloop
	PULS	U,D
	LDX	,S
	LEAS	5,S
	JMP	,X

;input	drive num				4+6,S	
;	filename pointer			4+4,S
;	buffer for directory entry		4+2,S
;output	A register: sector number or 0x00 for not found
;	B register: offset for entry
DSKFINDFILE
	CLR	DSKERROR
	PSHS	U,Y
	LDB	#3
dskfindfileloop:
	LDA	#2
	PSHS	A     ; set read
	LDA	1+4+6,S
	PSHS	A     ; set drive
	LDA	#17
	PSHS	A     ;set track
	PSHS	B     ;set sector
	LDU	4+4+2,S
	PSHS	U	;set destination buffer
	JSR	DSKRWSEC
	TSTA
	BNE	dskfindfileerror
	PSHS	B
	LDB	#8
dskfindfilefnamecheckol:
	LDA	,U
	CMPA	#$FF
	BNE	dskfindfilegoodentry
	LEAS	1,S
	JMP	dskfindfilefilenotfound
dskfindfilegoodentry:
	LDX	#11
	LDY	1+4+4,S	; load fname
	PSHS	U
dskfindfilefnamecheckil:
	LDA	,Y+
	CMPA	,U+
	BNE	dskfindfilenotthisfile
	LEAX	-1,X
	BNE	dskfindfilefnamecheckil
	PULS	U
	JMP	dskfindfilefoundfile
dskfindfilenotthisfile:
	PULS	U
	LEAU	32,U	
	DECB
	BNE	dskfindfilefnamecheckol	
	PULS	B
	INCB		;increment sector
	CMPB	#12	;if past sector 11 then stop
	BNE	dskfindfileloop	
dskfindfilefilenotfound
	LDA	#$FE	; file not found
	STA	DSKERROR
	JMP	dskfindfileerror
dskfindfilefoundfile:
	LDD	1+4+2,S	; subtract sector start from U
	PSHS	D
	TFR	U,D
	SUBD	,S++	; B is now entry offset
	PULS	A
	JMP	dskfindfiledone
dskfindfileerror:
	CLRA
dskfindfiledone:
	PULS	U,Y
	LDX	,S
	LEAS	7,S
	JMP	,X	

;input: drive					5+6,S
;	filename of file to stat		5+4,S
;	buffer for results (35 bytes long - 32 bytes from directory entry
;	plus three bytes for size)		5+2,S
;output: success or failure
DSKSTAT
	CLR	DSKERROR
	PSHS	U,Y,B
	LEAS	-256,S
	TFR	S,U
	LDA	256+5+6,S
	PSHS	A
	LDD	1+256+5+4,S
	PSHS	D
	PSHS	U
	JSR	DSKFINDFILE
	TSTA
	BEQ	dskstaterror
	CLRA
	LEAU	D,U			;now pointing at entry
	LDY	256+5+2,S
	PSHS	Y
	LDB	#32
dskstatcopybufferloop:
	LDA	,U+
	STA	,Y+
	DECB
	BNE	dskstatcopybufferloop
	PULS	Y
	LEAS	256,S			; free up temp buffer
	PSHS	Y			; store buffer pointer
	LDA	2+5+6,S			; load drive number
	PSHS	A
	JSR	DSKLOADFAT		; returns FAT pointer in Y
	LEAY	3,Y			; points to granule chain
	LDA	#-1
	PULS	U
	LDB	13,U
dskstatgranloop:
	INCA
	LDB	B,Y		; load granule
	CMPB	#$C0
	BCS	dskstatgranloop
	ANDB	#$3F		; get number of sectors in last granule
	DECB			; make 0-indexed
	PSHS	B
	LDB	#9
	MUL			; multiply by 9 to get # of sectors
				; up to last granule
	TFR	D,X
	PULS	B
	LEAX	B,X		; add in sectors in last granule
	LDD	14,U
	CMPD	#256
	BNE	dskstatnotfullsector	; if last sector is full then increment
					; # of sectors
	LEAX	1,X
dskstatnotfullsector:
	; here X is sectors, B is bytes in last sector	
	STX	32,U
	STB	34,U	
	CLRA
	JMP	dskstatdone
dskstaterror:
	LDA	#$FE		; file not found
dskstatdone:
	PULS	U,Y,B
	LDX	,S
	LEAS	7,S
	JMP	,X

;input:		4+2,S drive num
;output:	FAT cache pointer in Y
DSKLOADFAT
	CLR	DSKERROR
	PSHS	U,D
	LDA	6,S
	LDB	#70
	MUL
	LDY	#FAT
	LEAY	D,Y
	LDA	,Y
	BNE	dskloadfatdone	; already loaded
	LDA	6,S		; load drive num
	LDB	#2		; read operation
	LEAS	-256,S		; make room on stack
	TFR	S,X
	PSHS	D
	LDA	#2
	LDB	#17
	PSHS	D
	PSHS	X
	JSR	DSKRWSEC	; read into tempbuf
	TFR	S,X
	PSHS	Y		; save Y pointer
	LEAY	3,Y		; copy into right spot in FAT cache
	LDB	34
fatloadloop:
	LDU	,X++
	STU	,Y++
	DECB
	BNE	fatloadloop
	PULS	Y
	LEAS	256,S
dskloadfatdone:
	PULS	D,U
	LDX	,S
	LEAS	3,S
	JMP	,X

;input: FCB	6+2,S
;output: success or failure
DSKFFILLBUF
	CLR	DSKERROR
	PSHS	U,Y,D
	LDU	6+2,S
	LDA	10,U			; flush first if needed
	BITA	#$80			; should never get here where $80
	BEQ	dskffillbufnoflush	; is set without the buffer already
	PSHS	U
	JSR	DSKFFLUSH
dskffillbufnoflush:
	LDA	,U		; load drive num
	LDB	#2		; set read
	PSHS	D
	; calculate track and sector
	LDB	#70		; each drive FAT is 70 bytes
	MUL
	LDY	#FAT+3
	LEAY	D,Y
	LDA	5,U		; load current granule #
	INCA
	; follow granule chain to get to correct granule
	LDB	4,U		; load start granule
dskfillbuffindgranule:
	DECA
	BEQ	dskfillbuffoundgranule
	LDB	B,Y
	JMP	dskfillbuffindgranule
dskfillbuffoundgranule	
	LDA	#1
	BITB	#1
	BEQ	dskffillbufevengranule
	LDA	#10
dskffillbufevengranule:
	ADDA	6,U	; add in sector, 0 indexed
        ANDCC   #$FE
	RORB		; divide granule by 2 so we get track
	CMPB	#17
	BCS	dskffillbuflt17
	INCB		; increment if got track 17 or higher
dskffillbuflt17
	PSHS	D
	LEAY	11,U
	PSHS	Y
	JSR	DSKRWSEC
	LDA	#1
	STA	10,U	; mark as filled
	PULS	U,Y,D
	LDX	,S
	LEAS	4,S
	JMP	,X

;input: FCB	6+2,S
;output: none
DSKFFLUSH
	CLR	DSKERROR
	PSHS	U,Y,D
	LDY	6+2,S
	LDA	1,Y		; check if read or write mode
	BEQ	dskfflushdone	; if read-only then exit
	LDA	10,Y
	BITA	#$80
	BEQ	dskfflushdone

	LDA	,Y		; load drive num
	LDB	#3		; set write
	PSHS	D

	; calculate track and sector

	LDB	#70
	MUL
	LDU	#FAT+3
	LEAU	D,U		; load FAT location into U
        LDB     4,X             ; start granule 
        LDA     5,X             ; load granule chain # we're supposed to be on
	BEQ	dskfflushgranloopdone
dskfflushgranloop:
	LDB	B,U
	DECA
	BNE	dskfflushgranloop
dskfflushgranloopdone:

	LDA	#1
	BITB	#1
	BEQ	dskfflushevengranule
	LDA	#10
dskfflushevengranule:
	ADDA	6,Y
        ANDCC   #$FE
	RORB		; divide granule by 2 so we get track
	CMPB	#17
	BCS	dskfflushlt17
	INCB		; increment if got track 17 or higher
dskfflushlt17
	PSHS	D	
	LEAX	11,Y
	PSHS	X
	JSR	DSKRWSEC
	LDA	#1
	STA	10,Y	; mark as flushed but buffer is filled
dskfflushdone:
	PULS	U,Y,D
	LDX	,S
	LEAS	4,S
	JMP	,X

;input: drive number 6+2,S
DSKFATFLUSH
	CLR	DSKERROR
	; write FAT buffer to drive
	; update buffer byte to clean
	PSHS	U,Y,D
	LDA	6+2,S	
	LDB	#70	; FAT entry is 70 bytes per drive
	MUL
	LDY	#FAT	; get cached record in memory
	LEAY	D,Y
	TST	2,Y
	BEQ	dskfatflushdone
	PSHS	Y
	LEAY	3,Y	; move to granule chain
	LEAS	-256,S  ; make room on stack for sector
	TFR	S,U
	LDX	#34
dskfatflushcopyloop1
	LDD	,Y++
	STD	,U++
	LEAX	-1,X
	BNE	dskfatflushcopyloop1
	LDX	#94
	LDD	#0
dskfatflushcopyloop2
	STD	,U++
	LEAX	-1,X
	BNE	dskfatflushcopyloop2
	TFR	S,X	
	LDA	256+2+6+2,S	; load drive num
	LDB	#3	; write
	PSHS	D
	LDB	#17	; write to track 17
	LDA	#2	; sector 2
	PSHS	D
	PSHS	X	
	JSR	DSKRWSEC	
	LEAS	256,S
	PULS	Y
	CLR	2,Y	; mark memory cache as flushed to disk
dskfatflushdone:
	PULS	D,Y,U
	LDX	,S
	LEAS	3,S
	JMP	,X

DSKTURNOFFMOTORS
	PSHS	A
	LDA	#$00
	STA	$FF40
	PULS	A,PC

FAT		rmb	70*4 ; FAT buffer for four drives
			      ; byte 0: how many files are open on this disk
			      ; byte 1: unused
			      ; byte 2: is this dirty and need flushed?
			      ; bytes 3-70: mapping for 68 granules
			      ; this is a copy of the bytes found in disk 
			      ; track 17 sector 2
DSKERROR	rmb	1
		; $00 No error
		; $04 Lost Data
		; $08 CRC Error
                ; $10 Seek Error or Record Not Found
                ; $20 Write fault
                ; $40 Write protect
		; $80 Drive not ready
		; $FA Directory full
		; $FB Disk full
		; $FC Writing to a read-only file handle
		; $FD File already exists
		; $FE File not found

