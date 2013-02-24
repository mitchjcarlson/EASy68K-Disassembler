*-----------------------------------------------------------
* Title      : Team SaB Disassembler
* Written by : Kyle Rindahl & Mitch Carlson
* Date       : Feb. 22, 2013
* Description: Disassembler v1.0
*-----------------------------------------------------------


*------------------------------------------------------------------------------
*****************************IO Section****************************************
*------------------------------------------------------------------------------
	ORG	$1000
START:									; first instruction of program

			OPT		CRE					*Bring in the Symbol Table
strtAd		EQU		$00002000			*Starting Address
endAd		EQU		$000FFFFF			*Ending Address
invalidS	EQU		$000FFFFE			*Invalid starting Address if GTE 000FFFFE
dollar		EQU		$24					*ASCII $
LF			EQU		$0A					*ASCII value for Line feed
CR			EQU		$0D					*ASCII value for Carriage return
space		EQU		$20					*ASCII value for space
comma		EQU		$2C					*ASCII value for comma
task0		EQU		00					*Task 0
task1		EQU		01					*Task 1
task2		EQU		02					*Task 2
start		EQU		$1000				*Starting address
addSz		EQU		08					*Address Size is 8 bytes
wdSz		EQU		04					*Size of a word == 4 bytes
stack		EQU		$00100000			*Location of Stack
evenAnd		EQU		$00000001			*EvenCk subroutine 
D			EQU		$44					*ASCII value for D
A			EQU		$41					*ASCII value for A
T			EQU		$54					*ASCII value for T
upN			EQU		$4E					*ASCII value for N for User Prompt
lwn			EQU		$6E					*ASCII value for n for User Prompt
upY			EQU		$59					*ASCII value for Y for User Prompt
lwY			EQU		$79					*ASCII value for y for User Prompt
outCt		EQU		25					*Will show 25 lines/screen
region		EQU		80					*decimal number 80 to help fill


			ORG			start			*Program Start
			LEA			stack,SP		*Stack pointer in A7

Greeting	MOVE.B		#task0,D0		*Start of Greeting. D0 holds task0(00)
			LEA			greet,A1		*Greeting address Stored in A1
			MOVE.W		greetL,D1		*Store Greeting length into D1
			TRAP		#15				

			MOVE.B		#task2,D0		*D0 holds task2(02) - Get Input from user
			LEA			decision,A1		*Store input ptr to A1
			TRAP		#15				
			MOVE.B		(A1),D2			*D2 holds first byte of input
			CMPI.B		#upY,D2			*Check if D2 == Y
			BEQ			stSec			*Start disassembling
			CMPI.B		#lwY,D2			*Check if D2 == y
			BEQ			stSec			*Start disassembling
			CMPI.B		#upN,D2			*Check if D2(decision) == N
			BEQ			stp				*Stop disassembler
			CMPI.B		#lwN,D2			*Check if D2(decision) == n
			BEQ			stp				*Stop disassembler
			BRA			greetErr		*Display Error - invalid input	

stSec	    MOVE.B	    #task1,D0		*D0 holds task1(01), print wo CR
			LEA			stAdd,A1		*A1 holds string asking for start
			MOVE.W		stAddL,D1		*D1 holds length of start string
			TRAP		#15				
			MOVE.B		#task2,D0		*D0 holds task2(02), retrieve input
			LEA			data1,A1		*Storage location for input string
			TRAP		#15				
			CMPI.B		#00,D1			*compare value at D1 to 0
			BLE			startErr		*BLE 0 to bad String message (Addr too small) 
			CMPI.B		#addSz,D1		*compare value at D1 to 8
			BGT			startErr		*BGE 0 to badstring message (Addr too big)
			CLR.L		D7				*Remove data from D7
			BSR			a_to_h			*convert to hex
			CMPI.B		#01,D6			*Check if bad value flag == 1 (is set)
			BEQ			startErr		*is bad go to bad String message (bad value flag set)
			CLR.L		D2				*clear register
			MOVE.B		#addSz,D2		*put value 8 in D2
			SUB.B		D1,D2			*subtract length of string from 8
			MULU.W		#4,D2			*multiply by 4
			ROL.L		D2,D7			*move hex over appropriate digits
			BSR			evenCk			*need to check if address is even 
			CMPI.L		#strtAd,D7		*compare start and D7
			BLT			startErr		*if smaller then is a bad address
			CMPI.L		#invalidS,D7	*if end address is smaller, bad
			BGE			startErr		*if start is larger than end, bad
			MOVE.L		D7,istart		*istart holds valid start address in hex
			BRA			endSec			*go to end sequence

endSec		MOVE.B		#task1,D0		*D0 holds task1, print wo CR
			LEA			endAdd,A1		*A1 holds string asking for ending address
			MOVE.W		endAddL,D1		*D1 holds length of ending string
			TRAP		#15				

			MOVE.B		#task2,D0		*D0 holds task2, get input from user
			LEA			data2,A1		*Store input (as ptr) from user into A1
			TRAP		#15				
			CMPI.B		#00,D1			*compare value at D1 to 0
			BLE			endErr			*BLE to 0, branch to Bad Ending Error 
			CMPI.B		#addSz,D1		*compare value at D1 to 8
			BGT			endErr			*BGT to 8, branch to Bad Ending Error
			CLR.L		D7				*clear out D7
			BSR			a_to_h			*convert to hex
			CMPI.B		#01,D6			*Check if bad value flag == 1 (is set)
			BEQ			endErr			*BEQ branch to Bad Ending Error
			CLR.L		D2				*clear out D2
			MOVE.B		#addSz,D2		*put 8 in D2
			SUB.B		D1,D2			*subtract length of string from 8
			MULU.W		#4,D2			*multiply by 4
			ROL.L		D2,D7			*move hex over appropriate digits
			CMPI.L		#endAd,D7		*compare end address and D7
			BGT			endErr			*if larger, it's invalid
			MOVE.L		istart,D6		*move istart to D6
			ADDI.L		#01,D6
			CMP.L		D6,D7			*compare istart and end address
			BLE			endErr			*if it's less than or equal, bad
			MOVE.L		D7,iend			*iend holds valid start address in hex
			*BRA			mkBuff 			*go create buffers
			MOVE.B		#task1,D0		*D0 holds task1, print wo CR
			LEA         tempOut,A1      *Load temporary output to A1
			MOVE.W      tempOutL,D1     *Load the length of the temp message
			TRAP        #15
			BRA         Greeting        *Branch back to Greeting
			
	

****************************** IO Errors **************************************
			
greetErr	MOVE.B		#task0,D0		*D0 holds task2(02), print w CR
			LEA			iError,A1		*A1 holds error string
			MOVE.W		iErrorL,D1		*D1 holds length of start error string
			TRAP		#15				
			BRA			Greeting		*Branch back to Greeting

startErr	MOVE.B		#0,D6			*reset bad flag
			MOVE.B		#task0,D0		*D0 holds task2, print w CR
			LEA			stError,A1		*A1 holds error string
			MOVE.W		stErrorL,D1		*D1 holds length of start error string
			TRAP		#15				
			BRA			stSec			*back to start sequence for reprompt

endErr		MOVE.B		#0,D6			*reset bad flag
			MOVE.B		#task0,D0		*D0 holds task2, print w CR
			LEA			endError,A1		*A1 holds error string
			MOVE.W		endErrorL,D1	*D1 holds length of start error string
			TRAP		#15				
			BRA			endSec			*back to end sequence for repromp
			
bcontnu		MOVE.B		#task0,D0		*D0 holds task2, print w CR
			LEA			iError,A1		*A1 holds error string
			MOVE.W		iErrorL,D1		*D1 holds length of start error string
			TRAP		#15				
			BRA			Greeting		*back to start sequence for reprompt
			
stp		STOP		#$2700		*back to simulator

**************************** IO Variables *************************************
data1		DS.B	    20	        *to hold input of start address
data2		DS.B	    20	        *to hold input of end address
decision	DS.B	    20	        *to hold User's Decision (Y/y or Q/q)
istart		DS.L	    1	        *holds start address in hex
iend		DS.L	    1	        *holds end address in hex

headr		DC.B	    CR,LF,CR,LF,'MEMORY LOCATION   OP-CODE   OPERAND',CR,LF
headrL		DC.W	    42		    *holds length of header string

goodBuf		DS.B	    80		    *reserves 80 bytes to hold good buffer
badBuf		DS.B	    80		    *reserves 80 bytes to hold bad buffer
temp		DS.B	    30		    *reserves 30 bytes 4 prting instrs

imm_str		DS.B  	    8 		    ; immediate hex value string, supports up to 32 bits (8 hex nibbles)

crs			DC.B	    CR
crsl		DC.B	    1
lfs			DC.B	    LF
lfsl		DC.B	    1

****************************** IO Prompts *************************************
greet		DC.B	    'SaB Disassembler - CSS 422 Winter',CR,LF
		    DC.B	    'Would you like to Start Running Disassembler?',CR,LF
		    DC.B	    'Please enter Y for yes, or N for no.' 
greetL      DC.W        121

stAdd		DC.B	    'Please enter a Starting Address',CR,LF
		    DC.B	    'start address must be larger than $00002000 and smaller than $000FFFFF',CR,LF
stAddL      DC.W        105

endAdd		DC.B	    'Please enter an Ending Address.',CR,LF
		    DC.B	    'Address must be below $000FFFFF and at least 1 word larger than Starting Address',CR,LF
endAddL     DC.W        115

stError		DC.B	    'Invalid Starting Address',CR,LF
		    DC.B	    'start address must be above $00002000',CR,LF
		    DC.B	    'and below $000FFFFF',CR,LF
stErrorL    DC.W        86

endError	DC.B	    'Invalid End address',CR,LF
		    DC.B 	    'end address must be at least one word larger than start address',CR,LF
		    DC.B	    'and smaller than $000FFFFF',CR,LF
endErrorL   DC.W        114

iError		DC.B	    'You entered an invalid value, it must be the letter',CR,LF
		    DC.B	    'Y for yes or N for no',CR,LF
iErrorL     DC.W        89

conti		DC.B	    CR,LF,'Continue using Disassembler?',CR,LF
		    DC.B	    'Please enter Y for yes, or N for no',CR,LF
contiL		DC.W	    69 

curbuf		DS.L	    1	        ; current position in the buffer
curct		DS.W	    1	        ; current count inside the good buffer

tempOut     DC.B        'This is where the opcodes are processed',CR,LF
tempOutL    DC.W        41




************************** IO SubRoutines *************************************
*******************************************************************************
* Subroutine:		a_to_h
* Description:		converts a ascii string to a hex value
*******************************************************************************

a_to_h		MOVEM.L		D1/D2,-(SP)		*put utility register on stack
a_to_hSt	CMPI.B		#00,D1			*if D1 is 0 done
			BEQ			hexExit			*if done exit
			SUBI.B		#01,D1			*update counter
			ROL.L		#4,D7			*prepare register to take next hex
			MOVE.B		(A1)+,D2		*D2 holds next byte to convert
			CMPI.B		#$30,D2			*compare 30 to D2 if 
			BLT			badEx			*is ASCII is less than 30 bad
			CMPI.B		#$39,D2			*if equal or less than 39
			BLE			ah_num			*convert a number
			CMPI.B		#$40,D2			*if D2 is $40 invalid
			BLE			badEx			*then bad and exit
			CMPI.B		#$46,D2			*compare D2 to $46
			BLE			ah_uc			*convert to hex letter
			CMPI.B		#$61,D2			*compare D2 to $61
			BLT			badEx			*if less than bad and exit
			CMPI.B		#$66,D2			*compare D2 to $66
			BLE			ah_lc			*if less than or equal convert to HEX
			BRA			badEx			*if haven't coverted here, it's invalid
ah_num		SUBI.B		#$30,D2			*convert a number
			OR.B		D2,D7			*add hex digit to D7
			BRA			a_to_hSt		*back to loop
ah_lc		SUBI.B		#$57,D2			*convert to Hex letter
			OR.B		D2,D7			*add hex digit to D7
			BRA			a_to_hSt		*back to loop
ah_uc		SUBI.B		#$37,D2			*convert to Hex letter
			OR.B		D2,D7			*add hex digit to D7
			BRA			a_to_hSt		*back to loop
badEx		MOVE.B		#01,D6			*set bad flag
			BRA			hexExit			*then exit
hexExit		MOVEM.L		(SP)+,D1/D2		*pop register off stack
			RTS							*return from subroutine	

*******************************************************************************
* Subroutine:		evenCk
* Description:		checks if Hex address is even or odd
*******************************************************************************
evenCk		MOVEM.L		D2,-(SP)		*put utility register on stack
			MOVE.L		D7,D2			*move D7 to D2
			ANDI.L		#evenAnd,D2		*and $00000001 with D2
			CMPI.L		#00,D2			*if D2 is 0 then value was odd
			BEQ			even			*if D2 equals 0 it was even	
			ADDI.L		#01,D7			*if was odd add one to D7 
			BRA			even			*done
even		MOVEM.L	(SP)+,D2			*pop resister off stack		
			RTS							*return from subroutine

*******************************************************************************
* Subroutine:	h_to_a
* Description:	takes Hex value, separates into individual Hex bytes
*******************************************************************************
h_to_a		MOVEM.L		D3/D4/D2,-(SP)		;save D2 and A0
			CMPI.W		#04,D4				*see if D4 is a long or word
			BEQ			moveOvr				*if a word need to shift 
h_to_aSt	CMPI.W		#00,D4				*is count done		
			BEQ			ha_exit				*if done exit subroutine
			ROL.L		#4,D3				*update D3 to next hex
			MOVE.L		D3,D2				*so D3 isn't corrupted
			ANDI.L		#$0000000F,D2		*isolate the last 4 binary digits
			SUBI.B		#1,D4				*update counter
			CMPI.B		#$09,D2				*compare hex 9 and D2
			BLE			num					*if 9 or less it's a number
			BRA			uc					*then is a letter
num			ADDI.W		#$30,D2				*convert a number
			BRA			mem					*now put in  memory
uc			ADDI.W		#$37,D2				*convert to Hex letter
			BRA			mem					*now put in memory
mem			MOVE.B		D2,(A3)+			*save in memory and ++
			BRA			h_to_aSt			*back to top of loop
moveOvr		ROL.L		#08,D3				*move over 2 digits
			ROL.L		#08,D3				*move over 2 digits
			BRA			h_to_aSt			*start the loop
ha_exit		MOVEM.L		(SP)+,D3/D4/D2		;pop off stack
			RTS

*------------------------------------------------------------------------------
***************************** End IO Section **********************************
*------------------------------------------------------------------------------

*******************************************************************************
*                         Test Disassemble Routines
*******************************************************************************
* instructions could contain as many as 5 16-bit words
* e.g. MOVE.L 	$AAAAAAAA,$55555555

	ORG			$7000

* 	Test MOVE with various combinations of the effective address and with
*	different sizes  

*	MOVE 		<ea>,<ea>		; Size = (Byte, Word, Long)

								**DESTINATION**
	MOVE.B 		D0,D1 	 		; Data Register Direct
	MOVE.B 		D0,(A1)	 		; Address Register Indirect
	MOVE.B 		D0,(A1)+ 		; Address Register Indirect with Post increment
	MOVE.B 		D0,-(A1)		; Address Register Indirect with Pre decrement
	MOVE.B 		D0,$AAAA		; Absolute Word Address
	MOVE.B 		D0,$AAAAAAAA 	; Absolute Long Address

	MOVE.W 		D0,D1 	 		; Data Register Direct
	MOVE.W 		D0,(A1)	 		; Address Register Indirect
	MOVE.W 		D0,(A1)+ 		; Address Register Indirect with Post increment
	MOVE.W 		D0,-(A1)		; Address Register Indirect with Pre decrement
	MOVE.W 		D0,$AAAA		; Absolute Word Address
	MOVE.W 		D0,$AAAAAAAA 	; Absolute Long Address

	MOVE.L 		D0,D1 	 		; Data Register Direct
	MOVE.L 		D0,(A1)	 		; Address Register Indirect
	MOVE.L 		D0,(A1)+ 		; Address Register Indirect with Post increment
	MOVE.L 		D0,-(A1)		; Address Register Indirect with Pre decrement
	MOVE.L 		D0,$AAAA		; Absolute Word Address
	MOVE.L 		D0,$AAAAAAAA 	; Absolute Long Address

								**SOURCE**
	MOVE.B 		D0,D1 	 		; Data Register Direct
	MOVE.B 		(A0),D1	 		; Address Register Indirect
	MOVE.B 		#$FF,D1	 		; Immediate Data
	MOVE.B 		(A0)+,D1 		; Address Register Indirect with Post increment
	MOVE.B 		-(A0),D1		; Address Register Indirect with Pre decrement
	MOVE.B 		$AAAA,D0		; Absolute Word Address
	MOVE.B 		$AAAAAAAA,D0 	; Absolute Long Address

	MOVE.W 		D0,D1 	 		; Data Register Direct
	MOVE.W 		A0,D1	 		; Address Register Direct
	MOVE.W 		(A0),D1	 		; Address Register Indirect
	MOVE.W 		#$FFFF,D1		; Immediate Data
	MOVE.W 		(A0)+,D1 		; Address Register Indirect with Post increment
	MOVE.W 		-(A0),D1		; Address Register Indirect with Pre decrement
	MOVE.W 		$AAAA,D0		; Absolute Word Address
	MOVE.W 		$AAAAAAAA,D0 	; Absolute Long Address

	MOVE.L 		D0,D1 	 		; Data Register Direct
	MOVE.L 		A0,D1	 		; Address Register Direct
	MOVE.L 		(A0),D1	 		; Address Register Indirect
	MOVE.L 		#$FFFFFFFF,D1	; Immediate Data
	MOVE.L 		(A0)+,D1 		; Address Register Indirect with Post increment
	MOVE.L 		-(A0),D1		; Address Register Indirect with Pre decrement
	MOVE.L 		$AAAA,D0		; Absolute Word Address
	MOVE.L 		$AAAAAAAA,D0 	; Absolute Long Address

* 	Test MOVEA with various combinations of the effective address and with
*	different sizes  

*	MOVEA		<ea>,An 		; Size = (Word, Long)
								
								**SOURCE**
	MOVEA.W 	D0,A1 			; Data Register Direct
	MOVEA.W		A0,A1	 		; Address Register Direct
	MOVEA.W		(A0),A1	 		; Address Register Indirect
	MOVEA.W		#$FFFF,A1	 	; Immediate Data
	MOVEA.W		(A0)+,A1 		; Address Register Indirect with Post increment
	MOVEA.W		-(A0),A1		; Address Register Indirect with Pre decrement
	MOVEA.W		$AAAA,A1		; Absolute Word Address
	MOVEA.W		$AAAAAAAA,A1	; Absolute Long Address

	MOVEA.L 	D0,A1 			; Data Register Direct
	MOVEA.L		A0,A1	 		; Address Register Direct
	MOVEA.L		(A0),A1	 		; Address Register Indirect
	MOVEA.L		#$FFFFFFFF,A1	; Immediate Data
	MOVEA.L		(A0)+,A1 		; Address Register Indirect with Post increment
	MOVEA.L		-(A0),A1		; Address Register Indirect with Pre decrement
	MOVEA.L		$AAAA,A1		; Absolute Word Address
	MOVEA.L		$AAAAAAAA,A1	; Absolute Long Address

* 	Test ADDA with various combinations of the effective address and with
*	different sizes  

*	ADDA 		<ea>,An 		; Size = (Word, Long)

	ADDA.W 		D0,A1			; Data Register Direct
	ADDA.W 		A0,A1			; Address Register Direct
	ADDA.W 		(A0),A1			; Address Register Indirect
	ADDA.W 		#$FFFF,A1		; Immediate Data
	ADDA.W 		(A0)+,A1		; Address Register Indirect with Post increment
	ADDA.W 		-(A0),A1		; Address Register Indirect with Pre decrement
	ADDA.W 		$AAAA,A1		; Absolute Long Address
	ADDA.W		$AAAAAAAA,A1	; Absolute Long Address

	ADDA.L 		D0,A1			; Data Register Direct
	ADDA.L 		A0,A1			; Address Register Direct
	ADDA.L 		(A0),A1			; Address Register Indirect
	ADDA.L 		#$FFFF,A1		; Immediate Data
	ADDA.L 		(A0)+,A1		; Address Register Indirect with Post increment
	ADDA.L 		-(A0),A1		; Address Register Indirect with Pre decrement
	ADDA.L 		$AAAA,A1		; Absolute Long Address
	ADDA.L		$AAAAAAAA,A1	; Absolute Long Address

*	ADDI 		#<data>,<ea>	; Size = (Byte, Word, Long)
*	ADDQ 		#<data>,<ea>	; Size = (Byte, Word, Long)
*	SUBA 		<ea>,An			; Size = (Word, Long)
*	SUBI 		#<data>,<ea>	; Size = (Byte, Word, Long)
*	NEG 		<ea>			; Size = (Byte, Word, Long)
*	AND 		<ea>,Dn			; Size = (Byte, Word, Long)
*	AND 		Dn,<ea>
*	ANDI 		#<data>,<ea>	; Size = (Byte, Word, Long)
*	OR 			<ea>,Dn			; Size = (Byte, Word, Long)
*	OR 			Dn,<ea>
*	ORI 		#<data>,<ea>	; Size = (Byte, Word, Long)
*	EOR 		Dn,<ea>			; Size = (Byte, Word, Long)
*	EORI 		#<data>,<ea>	; Size = (Byte, Word, Long)

*	ASd where d is direction, L or R
*	ASL 		Dx,Dy 			; Size = (Byte, Word, Long)
*	ASL 		#<data>,Dy
*	ASL 		<ea>
*	ASR 		Dx,Dy 			; Size = (Byte, Word, Long)
*	ASR 		#<data>,Dy
*	ASR 		<ea>

*	ROd where d is direction, L or R 		
*	ROL 		Dx,Dy 			; Size = (Byte, Word, Long)
*	ROL 		#<data>,Dy
*	ROL 		<ea>
*	ROR 		Dx,Dy 			; Size = (Byte, Word, Long)
*	ROR 		#<data>,Dy
*	ROR 		<ea>
*	CMP 		<ea>,Dn 		; Size = (Byte, Word, Long)
*	CMPA 		<ea>,An 		; Size = (Word, Long)
*	CMPI 		#<data>,<ea>	; Size = (Byte, Word, Long)
*	JMP 		<ea>			; Unsized
*	JSR 		<ea>			; Unsized
*	Bcc 		<label>			; Size = (Byte, Word, Long*)
*	NOP 						; Unsized
*	RTS 						; Unsized

; Data Register Direct
; Address Register Direct
; Address Register Indirect
; Immediate Data
; Address Register Indirect with Post increment
; Address Register Indirect with Pre decrement
; Absolute Long Address
; Absolute Word Address

*******************************************************************************
*                       End Test Disassemble Routines
*******************************************************************************

		    END		    start
		    
*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~8~




*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
