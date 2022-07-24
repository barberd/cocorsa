;Adapted from "Assembly Language Subroutines For the 6809"
; By Lance A Leventhal

; Available at https://archive.org/details/assembly-language-subroutines-for-the-6809_Leventhal

;Code available on https://github.com/jmatzen/leventhal-6809

;Adapted to use 16 bit instead of 8 bit MPLEN by Don Barber 2022

; Title:		Multiple-Precision Binary Subtraction
;
; Name:			MPBSUB
;
; Purpose:		Subtract 2 arrays of binary bytes
;			Minuend := Minuend - Subtrahend
;
; Entry:		TOP OF STACK
;			High byte of return address
;			Low  byte of return address
;			Length of the arrays in bytes
;			High byte of subtrahend address
;			Low  byte of subtrahend address
;			High byte of minuend address
;			Low  byte of minuend address
;
;			The arrays are unsigned binary numbers
;			with a maximum length of 255 bytes,
;			ARRAY[0]	is the least significant byte, and
;			ARRAY[LENGTH-1]	is the most significant byte.
;
; Exit:			Minuend := Minuend - Subtrahend
;
; Registers Used:	A,B,CC,U,X
;
; Time:			21 cycles per byte plus 36 cycles overhead
; 
;
; Size:			Program 25 bytes
;

MPBSUB:
	;
	; CHECK IF LENGTH OF ARRAYS IS ZERO
	; EXIT WITH CARRY CLEARED IF IT IS
	;
	ANDCC   #$FE		; CLEAR CARRY TO START
	LDX	2,S		; CHECK LENGTH OF ARRAYS
	BEQ	SBEXIT		; BRANCH (EXIT) IF LENGTH IS ZERO
				; SUBTRACT ARRAYS ONE BYTE AT A TIME
	LDY	4,S		; GET BASE ADDRESS OF SUBTRAHEND
	LDU	6,S		; GET BASE ADDRESS OF MINUEND
SUBBYT:
	LDA	,U		; GET BYTE OF MINUEND
	SBCA	,Y+		; SUBTRACT BYTE OF SUBTRAHEND WITH BORROW
	STA	,U+		; SAVE DIFFERENCE IN MINUEND
	LEAX	-1,X
	BNE	SUBBYT		; CONTINUE UNTIL ALL BYTES SUBTRACTED
	;
	; REMOVE PARAMETERS FROM STACK AND EXIT
	;
SBEXIT:
	LDX	,S		; SAVE RETURN ADDRESS
	LEAS	8,S		; REMOVE PARAMETERS FROM STACK
	JMP	,X		; EXIT TO RETURN ADDRESS

