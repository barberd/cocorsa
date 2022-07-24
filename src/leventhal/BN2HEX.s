;From "Assembly Language Subroutines For the 6809"
; By Lance A Leventhal

; Available at https://archive.org/details/assembly-language-subroutines-for-the-6809_Leventhal

;Code available on https://github.com/jmatzen/leventhal-6809


;	Title:			Binary to Hex ASCII
;
;	Name:			BN2HEX
;
;	Purpose:		Converts one byte of binary data to two ASCII characters
;
;	Entry:			Register A = Binary data
;
;	Exit:			Register A = ASCII more significant digit
;				Register B = ASCII Less significant digit
;
;	Registers Used:		A,B,CC
;
;	Time:			Approximately 37 cycles
;
;	Size:			Program		27 bytes
;				Data		None
;

BN2HEX:
	;
	; CONVERT MORE SIGNIFICANT DIGIT TO ASCII
	;
	TFR	A,B		; SAVE ORIGINAL BINARY VALUE MOVE HIGH DIGIT TO LOW DIGIT
	LSRA
	LSRA
	LSRA
	LSRA
	CMPA	#9
	BLS	AD30		; BRANCH IF HIGH DIGIT IS DECIMAL
	ADDA	#7		; ELSE ADD 7 S0 AFTER ADDING '0' THE 
				; CHARACTER WILL BE IN 'A'..'F'
AD30:	ADDA	#'0'		; ADD ASCII 0 TO MAKE A CHARACTER
	;
	; CONVERT LESS SIGNIFICANT DIGIT TO ASCII
	; 
	ANDB	#$0F		; MASK OFF LOW DIGIT	
	CMPB	#9		
	BLS	AD30LD		; BRANCH IF LOW DIGIT IS DECIMAL	
	ADDB	#7		; ELSE ADD 7 SO AFTER ADDING '0' THE
				; CHARACTER WILL BE IN 'A'..'F'
AD30LD:	ADDB	#'0'		; ADD ASCII 0 TO MAKE A CHARACTER
	RTS

