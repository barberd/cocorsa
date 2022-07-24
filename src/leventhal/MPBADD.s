;Adapted from "Assembly Language Subroutines For the 6809"
; By Lance A Leventhal

; Available at https://archive.org/details/assembly-language-subroutines-for-the-6809_Leventhal

;Code available on https://github.com/jmatzen/leventhal-6809

;Adapted to use 16 bit instead of 8 bit MPLEN by Don Barber 2022

; Title:		Multiple-Precision Binary Addition
; Name:			MPBADD
;
; Purpose:		Add 2 arrays of binary bytes
;			Array1 := Array 1 + Array 2 
;
; Entry:
;			TOP OF STACK
;
;			High byte of return address 
;			Low  byte of return address
;			Length of the arrays in bytes
;			High byte of array 2 address
;			Low  byte of array 2 address
;			High byte of array 1 address
;			Low  byte of array 1 address
;
;			The arrays are unsigned binary numbers
;			with a maximum length of 255 bytes,
;			ARRAY[0] is the least significant
;			byte, and ARRAY[LENGTH-1] is the
;			most significant byte.
;
; Exit:			Array1 := Array1 + Array2
;
; Registers Used:	A,B,CC,U,X,Y
;
; Time:			21 cycles per byte plus 36 cycles overhead
;
; Size:			Program 25 bytes
;

MPBADD:
	;
	; CHECK IF LENGTH OF ARRAYS IS ZERO
	; EXIT WITH CARRY CLEARED IF IT IS
	;
	ANDCC   #$FE		; CLEAR CARRY TO START
	LDX	2,S		; CHECK LENGTH OF ARRAYS
	BEQ	ADEXIT		; BRANCH (EXIT) IF LENGTH IS ZERO
	;
	; ADD ARRAYS ONE BYTE AT A TIME
	;
	LDY	6,S		; GET BASE ADDRESS OF ARRAY 1
	LDU	4,S		; GET BASE ADDRESS OF ARRAY 2
ADDBYT:
	LDA	,U+		; GET BYTE FROM ARRAY 2
	ADCA	,Y		; ADD WITH CARRY TO BYTE FROM ARRAY 1
	STA	,Y+		; SAVE SUM IN ARRAY 1
	LEAX	-1,X
	BNE	ADDBYT		; CONTINUE UNTIL ALL BYTES SUMMED
	;
	; REMOVE PARAMETERS FROM STACK AND EXIT
	;
ADEXIT:
	LDX	,S		; SAVE RETURN ADDRESS
	LEAS	8,S		; REMOVE PARAMETERS FRDM STACK
	JMP	,X		; EXIT TO RETURN ADDRESS

