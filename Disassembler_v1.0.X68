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
strtAd		EQU		$00002000			*Starting Address for user input program
endAd		EQU		$000FFFFF			*Ending Address - upper bound of input program
invalidS	EQU		$000FFFFE			*Invalid starting Address if GTE 000FFFFE
dollar		EQU		$24					*ASCII $
LF			EQU		$0A					*ASCII value for Line feed
CR			EQU		$0D					*ASCII value for Carriage return
space		EQU		$20					*ASCII value for space
comma		EQU		$2C					*ASCII value for comma
task0		EQU		00					*Task0 from Berger, print a string to screen
task1		EQU		01					*Task1 from Berger, prompt for input w/o newline
task2		EQU		02					*Task2 from Berger, prompt and wait for input
start		EQU		$1000				*Starting address of program
addrSz		EQU		08					*Address Size = 8 bytes
wdSz		EQU		04					*Word Size = 4 bytes
stack		EQU		$00100000			*Default Location of Stack
evenAnd		EQU		$00000001			*EvenCk subroutine check if a number is even 
D			EQU		$44					*ASCII value for D
A			EQU		$41					*ASCII value for A
T			EQU		$54					*ASCII value for T
upN			EQU		$4E					*ASCII value for N for User Prompt
lwn			EQU		$6E					*ASCII value for n for User Prompt
upY			EQU		$59					*ASCII value for Y for User Prompt
lwY			EQU		$79					*ASCII value for y for User Prompt
outCt		EQU		25					*Will show 25 lines on each screen, can adjust
region		EQU		80					*decimal number 80 to help fill


			ORG			start			*Program Start
			LEA			stack,SP		*Stack pointer in A7

*Displays greeting to user, prompts to begin
Greeting	MOVE.B		#task0,D0		*Start of Greeting. Loads D0 with text from greeting
			LEA			greet,A1		*Load Greeting address into A1
			MOVE.W		greetL,D1		*Store Greeting length into D1
			TRAP		#15				*Run
			
			MOVE.B		#task2,D0		*D0 Input from user
			LEA			decision,A1		*Store input ptr to A1
			TRAP		#15				*Run
			
			MOVE.B		(A1),D2			*D2 holds first byte of input
			CMPI.B		#upY,D2			*Check if D2 == Y
			BEQ			procStart		*Start disassembling
			CMPI.B		#lwY,D2			*Check if D2 == y
			BEQ			procStart		*Start disassembling
			CMPI.B		#upN,D2			*Check if D2(decision) == N
			BEQ			stp				*Stop disassembler
			CMPI.B		#lwN,D2			*Check if D2(decision) == n
			BEQ			stp				*Stop disassembler
			BRA			greetErr		*Display Error - invalid input	

*Prompts and processes Starting Address
procStart   MOVE.B	    #task1,D0		*D0 holds input from user
			LEA			stAdd,A1		*A1 holds string asking for start
			MOVE.W		stAddL,D1		*D1 holds length of start string
			TRAP		#15				*Run
			
			MOVE.B		#task2,D0		*D0 holds task2(02), retrieve input
			LEA			data1,A1		*Storage location for input string
			TRAP		#15				*Run
			
			CMPI.B		#00,D1			*Compare starting addr length to 0
			BLE			startErr		*BLE 0 to bad String message (Addr too small) 
			CMPI.B		#addrSz,D1		*compare starting addr length to 8
			BGT			startErr		*BGE 0 to badstring message (Addr too big)
			CLR.L		D7				*Remove data from D7
			BSR			a_to_h			*Go to Hex conversion subroutine
			CMPI.B		#01,D6			*Check if bad value flag(D6) == 1 (is set)
			BEQ			startErr		*Branch to Bad String message (bad value flag set)
			CLR.L		D2				*First clear register D2
			MOVE.B		#addrSz,D2		*Then put value 8 in D2
			SUB.B		D1,D2			*Subtract length of string from 8
			MULU.W		#4,D2			*Multiply by 4 to get word
			LSL.L		D2,D7			*Shift value calculated at D2 left, store in D7
			BSR			evenCk			*Verify by checking if even
			CMPI.L		#strtAd,D7		*compare start address and shifted address
			BLT			startErr		*if smaller then is a bad address
			CMPI.L		#invalidS,D7	*Too close to highest available address, so invalid
			BGE			startErr		*Start is larger than end, Branch to Error
			MOVE.L		D7,istart		*istart holds valid start address in hex
			BRA			procEnd			*Branch to procEnd for End Addr validation

*Prompts and processes Ending Address
procEnd		MOVE.B		#task1,D0		*D0 holds task1, print wo CR
			LEA			endAdd,A1		*A1 holds string asking for ending address
			MOVE.W		endAddL,D1		*D1 holds length of ending string
			TRAP		#15				

			MOVE.B		#task2,D0		*D0 holds task2, get input from user
			LEA			data2,A1		*Store input (as ptr) from user into A1
			TRAP		#15				*Run
			
			CMPI.B		#00,D1			*Compare starting addr length to 0
			BLE			endErr			*BLE 0 to Bad Ending Error (Addr too small)
			CMPI.B		#addrSz,D1		*Compare address size to D1
			BGT			endErr			*BGT value 8, branch to Bad Ending Error
			CLR.L		D7				*Remove data from D7
			BSR			a_to_h			*Go to Hex conversion subroutine
			CMPI.B		#01,D6			*Check if bad value flag(D6) == 1 (is set)
			BEQ			endErr			*BEQ branch to Bad Ending Error
			CLR.L		D2				*First clear register D2
			MOVE.B		#addrSz,D2		*Then put value 8 in D2
			SUB.B		D1,D2			*Subtract length of string from 8
			MULU.W		#4,D2			*Multiply by 4 to get word
			LSL.L		D2,D7			*Shift value calculated at D2 left, store in D7
			CMPI.L		#endAd,D7		*Compare end address and shifted address
			BGT			endErr			*If larger than end address, branch to end error
			MOVE.L		istart,D6		*Fill D6 with hex value of starting address
			ADDI.L		#01,D6          *Add 1 to starting address
			CMP.L		D6,D7			*Compare with end address
			BLE			endErr			*Branch to end error if less than or equal
			MOVE.L		D7,iend			*Set iend to shifted address value
			MOVE.B		#task1,D0		*Get input from user
			LEA         tempOut,A1      *Load temporary output to A1
			MOVE.W      tempOutL,D1     *Load the length of the temp message
			TRAP        #15             *Run
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
			BRA			procStart		*back to start sequence for reprompt

endErr		MOVE.B		#0,D6			*reset bad flag
			MOVE.B		#task0,D0		*D0 holds task2, print w CR
			LEA			endError,A1		*A1 holds error string
			MOVE.W		endErrorL,D1	*D1 holds length of start error string
			TRAP		#15				
			BRA			procEnd			*back to end sequence for repromp
			
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

************************ IO Prompts and Messages*******************************
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

*******************************************************************************
*	MOVE 		<ea>,<ea>				; Size = (Byte, Word, Long)
*******************************************************************************

	*BYTE*								**DESTINATION**
	MOVE.B 		D0,D1 	 				; Data Register Direct
	MOVE.B 		D0,(A1)	 				; Addr Reg Indirect
	MOVE.B 		D0,(A1)+ 				; Addr Reg Indirect with Post increment
	MOVE.B 		D0,-(A1)				; Addr Reg Indirect with Pre decrement
	MOVE.B 		D0,$AAAA				; Absolute Word Address
	MOVE.B 		D0,$AAAAAAAA 			; Absolute Long Address

	*WORD*
	MOVE.W 		D0,D1 	 				; Data Register Direct
	MOVE.W 		D0,(A1)	 				; Addr Reg Indirect
	MOVE.W 		D0,(A1)+ 				; Addr Reg Indirect with Post increment
	MOVE.W 		D0,-(A1)				; Addr Reg Indirect with Pre decrement
	MOVE.W 		D0,$AAAA				; Absolute Word Address
	MOVE.W 		D0,$AAAAAAAA 			; Absolute Long Address

	*LONG*
	MOVE.L 		D0,D1 	 				; Data Register Direct
	MOVE.L 		D0,(A1)	 				; Addr Reg Indirect
	MOVE.L 		D0,(A1)+ 				; Addr Reg Indirect with Post increment
	MOVE.L 		D0,-(A1)				; Addr Reg Indirect with Pre decrement
	MOVE.L 		D0,$AAAA				; Absolute Word Address
	MOVE.L 		D0,$AAAAAAAA 			; Absolute Long Address

	*BYTE*								**SOURCE**
	MOVE.B 		D0,D1 	 				; Data Register Direct
	MOVE.B 		(A0),D1	 				; Addr Reg Indirect
	MOVE.B 		(A0)+,D1 				; Addr Reg Indirect with Post increment
	MOVE.B 		-(A0),D1				; Addr Reg Indirect with Pre decrement
	MOVE.B 		$AAAA,D0				; Absolute Word Address
	MOVE.B 		$AAAAAAAA,D0 			; Absolute Long Address
	MOVE.B 		#$DD,D1	 				; Immediate Data

	*WORD*
	MOVE.W 		D0,D1 	 				; Data Register Direct
	MOVE.W 		A0,D1	 				; Addr Reg Direct
	MOVE.W 		(A0),D1	 				; Addr Reg Indirect
	MOVE.W 		(A0)+,D1 				; Addr Reg Indirect with Post increment
	MOVE.W 		-(A0),D1				; Addr Reg Indirect with Pre decrement
	MOVE.W 		$AAAA,D0				; Absolute Word Address
	MOVE.W 		$AAAAAAAA,D0 			; Absolute Long Address
	MOVE.W 		#$DDDD,D1				; Immediate Data

	*LONG*
	MOVE.L 		D0,D1 	 				; Data Register Direct
	MOVE.L 		A0,D1	 				; Addr Reg Direct
	MOVE.L 		(A0),D1	 				; Addr Reg Indirect
	MOVE.L 		(A0)+,D1 				; Addr Reg Indirect with Post increment
	MOVE.L 		-(A0),D1				; Addr Reg Indirect with Pre decrement
	MOVE.L 		$AAAA,D0				; Absolute Word Address
	MOVE.L 		$AAAAAAAA,D0 			; Absolute Long Address
	MOVE.L 		#$DDDDDDDD,D1			; Immediate Data

*******************************************************************************
*	MOVEA		<ea>,An 				; Size = (Word, Long)
*******************************************************************************
								
										**SOURCE**
	*WORD*
	MOVEA.W 	D0,A1 					; Data Register Direct
	MOVEA.W		A0,A1	 				; Addr Reg Direct
	MOVEA.W		(A0),A1	 				; Addr Reg Indirect
	MOVEA.W		(A0)+,A1 				; Addr Reg Indirect with Post increment
	MOVEA.W		-(A0),A1				; Addr Reg Indirect with Pre decrement
	MOVEA.W		$AAAA,A1				; Absolute Word Address
	MOVEA.W		$AAAAAAAA,A1			; Absolute Long Address
	MOVEA.W		#$DDDD,A1	 			; Immediate Data

	*LONG*
	MOVEA.L 	D0,A1 					; Data Register Direct
	MOVEA.L		A0,A1	 				; Addr Reg Direct
	MOVEA.L		(A0),A1	 				; Addr Reg Indirect
	MOVEA.L		(A0)+,A1 				; Addr Reg Indirect with Post increment
	MOVEA.L		-(A0),A1				; Addr Reg Indirect with Pre decrement
	MOVEA.L		$AAAA,A1				; Absolute Word Address
	MOVEA.L		$AAAAAAAA,A1			; Absolute Long Address
	MOVEA.L		#$DDDDDDDD,A1			; Immediate Data

*******************************************************************************
*	ADDA 		<ea>,An 				; Size = (Word, Long)
*******************************************************************************

	*WORD*
	ADDA.W 		D0,A1					; Data Register Direct
	ADDA.W 		A0,A1					; Addr Reg Direct
	ADDA.W 		(A0),A1					; Addr Reg Indirect
	ADDA.W 		(A0)+,A1				; Addr Reg Indirect with Post increment
	ADDA.W 		-(A0),A1				; Addr Reg Indirect with Pre decrement
	ADDA.W 		$AAAA,A1				; Absolute Word Address
	ADDA.W		$AAAAAAAA,A1			; Absolute Long Address
	ADDA.W 		#$DDDD,A1				; Immediate Data

	*LONG*
	ADDA.L 		D0,A1					; Data Register Direct
	ADDA.L 		A0,A1					; Addr Reg Direct
	ADDA.L 		(A0),A1					; Addr Reg Indirect
	ADDA.L 		(A0)+,A1				; Addr Reg Indirect with Post increment
	ADDA.L 		-(A0),A1				; Addr Reg Indirect with Pre decrement
	ADDA.L 		$AAAA,A1				; Absolute Word Address
	ADDA.L		$AAAAAAAA,A1			; Absolute Long Address
	ADDA.L 		#$DDDD,A1				; Immediate Data

*******************************************************************************
*	ADDI 		#<data>,<ea>			; Size = (Byte, Word, Long)
*******************************************************************************

	*BYTE*
	ADDI.B 		#$DD,D1					; Data Register Direct
	ADDI.B 		#$DD,(A1)				; Addr Reg Indirect
	ADDI.B 		#$DD,(A1)+				; Addr Reg Indirect with Post increment
	ADDI.B 		#$DD,-(A1)				; Addr Reg Indirect with Pre decrement
	ADDI.B 		#$DD,$AAAA				; Absolute Word Address
	ADDI.B 		#$DD,$AAAAAAAA			; Absolute Long Address

	*WORD*
	ADDI.W 		#$DDDD,D1				; Data Register Direct
	ADDI.W 		#$DDDD,(A1)				; Addr Reg Indirect
	ADDI.W 		#$DDDD,(A1)+			; Addr Reg Indirect with Post increment
	ADDI.W 		#$DDDD,-(A1)			; Addr Reg Indirect with Pre decrement
	ADDI.W 		#$DDDD,$AAAA			; Absolute Word Address
	ADDI.W 		#$DDDD,$AAAAAAAA 		; Absolute Long Address

	*LONG*
	ADDI.L 		#$DDDDDDDD,D1			; Data Register Direct
	ADDI.L 		#$DDDDDDDD,(A1)			; Addr Reg Indirect
	ADDI.L 		#$DDDDDDDD,(A1)+		; Addr Reg Indirect with Post increment
	ADDI.L 		#$DDDDDDDD,-(A1) 		; Addr Reg Indirect with Pre decrement
	ADDI.L 		#$DDDDDDDD,$AAAA 		; Absolute Word Address
	ADDI.L 		#$DDDDDDDD,$AAAAAAAA 	; Absolute Long Address

*******************************************************************************
*	ADDQ 		#<data>,<ea>			; Size = (Byte, Word, Long)
*******************************************************************************
	
	*BYTE*
	ADDQ.B 		#8,D1					; Data Register Direct
*ERROR*	ADDQ.B 		#8,A1					; Addr Reg Direct
	ADDQ.B 		#8,(A1)					; Addr Reg Indirect
	ADDQ.B 		#8,(A1)+				; Addr Reg Indirect with Post increment
	ADDQ.B 		#8,-(A1)				; Addr Reg Indirect with Pre decrement
	ADDQ.B 		#8,$AAAA				; Absolute Word Address
	ADDQ.B 		#8,$AAAAAAAA			; Absolute Long Address

	*WORD*
	ADDQ.W 		#8,D1					; Data Register Direct
	ADDQ.W 		#8,A1					; Addr Reg Direct
	ADDQ.W 		#8,(A1)					; Addr Reg Indirect
	ADDQ.W 		#8,(A1)+				; Addr Reg Indirect with Post increment
	ADDQ.W 		#8,-(A1)				; Addr Reg Indirect with Pre decrement
	ADDQ.W 		#8,$AAAA				; Absolute Word Address
	ADDQ.W 		#8,$AAAAAAAA			; Absolute Long Address

	*LONG*
	ADDQ.L 		#8,D1					; Data Register Direct
	ADDQ.L 		#8,A1					; Addr Reg Direct
	ADDQ.L 		#8,(A1)					; Addr Reg Indirect
	ADDQ.L 		#8,(A1)+				; Addr Reg Indirect with Post increment
	ADDQ.L 		#8,-(A1)				; Addr Reg Indirect with Pre decrement
	ADDQ.L 		#8,$AAAA				; Absolute Word Address
	ADDQ.L 		#8,$AAAAAAAA			; Absolute Long Addres

*******************************************************************************
*	SUBA 		<ea>,An					; Size = (Word, Long)
*******************************************************************************
	
	*WORD*
	SUBA.W 		D0,A1					; Data Register Direct
	SUBA.W 		A0,A1					; Addr Reg Direct
	SUBA.W 		(A0),A1					; Addr Reg Indirect
	SUBA.W 		(A0)+,A1				; Addr Reg Indirect with Post increment
	SUBA.W 		-(A0),A1				; Addr Reg Indirect with Pre decrement
	SUBA.W 		$AAAA,A1				; Absolute Word Address
	SUBA.W 		$AAAAAAAA,A1			; Absolute Long Address
	SUBA.W 		#$DDDD,A1				; Immediate Data

	*LONG*
	SUBA.L 		D0,A1					; Data Register Direct
	SUBA.L 		A0,A1					; Addr Reg Direct
	SUBA.L 		(A0),A1					; Addr Reg Indirect
	SUBA.L 		(A0)+,A1				; Addr Reg Indirect with Post increment
	SUBA.L 		-(A0),A1				; Addr Reg Indirect with Pre decrement
	SUBA.L 		$AAAA,A1				; Absolute Word Address
	SUBA.L 		$AAAAAAAA,A1			; Absolute Long Address
	SUBA.L 		#$DDDDDDDD,A1			; Immediate Data

*******************************************************************************
*	SUBI 		#<data>,<ea>			; Size = (Byte, Word, Long)
*******************************************************************************

	*BYTE*
	SUBI.B 		#$DD,D1 				; Data Register Direct
	SUBI.B 		#$DD,(A1) 				; Addr Reg Indirect
	SUBI.B 		#$DD,(A1)+				; Addr Reg Indirect with Post increment
	SUBI.B 		#$DD,-(A1) 				; Addr Reg Indirect with Pre decrement
	SUBI.B 		#$DD,$AAAA 				; Absolute Word Address
	SUBI.B 		#$DD,$AAAAAAAA			; Absolute Long Address

	*WORD*
	SUBI.W 		#$DDDD,D1 				; Data Register Direct
	SUBI.W 		#$DDDD,(A1) 			; Addr Reg Indirect
	SUBI.W 		#$DDDD,(A1)+			; Addr Reg Indirect with Post increment
	SUBI.W 		#$DDDD,-(A1) 			; Addr Reg Indirect with Pre decrement
	SUBI.W 		#$DDDD,$AAAA 			; Absolute Word Address
	SUBI.W 		#$DDDD,$AAAAAAAA		; Absolute Long Address

	*LONG*
	SUBI.L 		#$DDDDDDDD,D1 			; Data Register Direct
	SUBI.L 		#$DDDDDDDD,(A1) 		; Addr Reg Indirect
	SUBI.L 		#$DDDDDDDD,(A1)+		; Addr Reg Indirect with Post increment
	SUBI.L 		#$DDDDDDDD,-(A1) 		; Addr Reg Indirect with Pre decrement
	SUBI.L 		#$DDDDDDDD,$AAAA 		; Absolute Word Address
	SUBI.L 		#$DDDDDDDD,$AAAAAAAA	; Absolute Long Address

*******************************************************************************
*	NEG 		<ea>					; Size = (Byte, Word, Long)
*******************************************************************************

	*BYTE*
	NEG.B 		D0						; Data Register Direct
	NEG.B 		(A0)					; Addr Reg Indirect
	NEG.B 		(A0)+					; Addr Reg Indirect with Post increment
	NEG.B 		-(A0)					; Addr Reg Indirect with Pre decrement
*ERROR*	NEG.B 		#$AAAA					; Absolute Word Address
*ERROR*	NEG.B 		#$AAAAAAAA				; Absolute Long Address

	*WORD*
	NEG.W 		D0						; Data Register Direct
	NEG.W 		(A0)					; Addr Reg Indirect
	NEG.W 		(A0)+					; Addr Reg Indirect with Post increment
	NEG.W 		-(A0)					; Addr Reg Indirect with Pre decrement
*ERROR*	NEG.W 		#$AAAA					; Absolute Word Address
*ERROR*	NEG.W 		#$AAAAAAAA				; Absolute Long Address

	*LONG*
	NEG.L 		D0						; Data Register Direct
	NEG.L 		(A0)					; Addr Reg Indirect
	NEG.L 		(A0)+					; Addr Reg Indirect with Post increment
	NEG.L 		-(A0)					; Addr Reg Indirect with Pre decrement
*ERROR*	NEG.L 		#$AAAA					; Absolute Word Address
*ERROR*	NEG.L 		#$AAAAAAAA				; Absolute Long Address

*******************************************************************************
*	AND 		<ea>,Dn					; Size = (Byte, Word, Long)
*******************************************************************************

	*BYTE*								*SOURCE*
	AND.B 		D0,D1					; Data Register Direct
	AND.B 		(A0),D1 				; Addr Reg Indirect
	AND.B 		(A0)+,D1 				; Addr Reg Indirect with Post increment
	AND.B 		-(A0),D1 				; Addr Reg Indirect with Pre decrement
	AND.B 		$AAAA,D1 				; Absolute Word Address
	AND.B 		$AAAAAAAA,D1 			; Absolute Long Address
	AND.B 		#$DD,D1 				; Immediate Data

	*WORD*
	AND.W 		D0,D1					; Data Register Direct
	AND.W 		(A0),D1 				; Addr Reg Indirect
	AND.W 		(A0)+,D1 				; Addr Reg Indirect with Post increment
	AND.W 		-(A0),D1 				; Addr Reg Indirect with Pre decrement
	AND.W 		$AAAA,D1 				; Absolute Word Address
	AND.W 		$AAAAAAAA,D1 			; Absolute Long Address
	AND.W 		#$DD,D1 				; Immediate Data

	*LONG*
	AND.L 		D0,D1					; Data Register Direct
	AND.L 		(A0),D1 				; Addr Reg Indirect
	AND.L 		(A0)+,D1 				; Addr Reg Indirect with Post increment
	AND.L 		-(A0),D1 				; Addr Reg Indirect with Pre decrement
	AND.L 		$AAAA,D1 				; Absolute Word Address
	AND.L 		$AAAAAAAA,D1 			; Absolute Long Address
	AND.L 		#$DD,D1 				; Immediate Data

*******************************************************************************
*	AND 		Dn,<ea>					; Size = (Byte, Word, Long)
*******************************************************************************

	*BYTE*								*DESTINATION*
	AND.B 		D0,(A1)					; Addr Reg Indirect
	AND.B 		D0,(A1)+				; Addr Reg Indirect with Post increment
	AND.B 		D0,-(A1)				; Addr Reg Indirect with Pre decrement
	AND.B 		D0,$AAAA				; Absolute Word Address
	AND.B 		D0,$AAAAAAAA			; Absolute Long Address

	*WORD*
	AND.W 		D0,(A1)					; Addr Reg Indirect
	AND.W 		D0,(A1)+				; Addr Reg Indirect with Post increment
	AND.W 		D0,-(A1)				; Addr Reg Indirect with Pre decrement
	AND.W 		D0,$AAAA				; Absolute Word Address
	AND.W 		D0,$AAAAAAAA			; Absolute Long Address

	*LONG*
	AND.L 		D0,(A1)					; Addr Reg Indirect
	AND.L 		D0,(A1)+				; Addr Reg Indirect with Post increment
	AND.L 		D0,-(A1)				; Addr Reg Indirect with Pre decrement
	AND.L 		D0,$AAAA				; Absolute Word Address
	AND.L 		D0,$AAAAAAAA			; Absolute Long Address

*******************************************************************************
*	ANDI 		#<data>,<ea>			; Size = (Byte, Word, Long)
*******************************************************************************

; Data Register Direct
; Addr Reg Direct
; Addr Reg Indirect
; Addr Reg Indirect with Post increment
; Addr Reg Indirect with Pre decrement
; Absolute Word Address
; Absolute Long Address
; Immediate Data

*******************************************************************************
*	OR 			<ea>,Dn					; Size = (Byte, Word, Long)
*******************************************************************************

; Data Register Direct
; Addr Reg Direct
; Addr Reg Indirect
; Addr Reg Indirect with Post increment
; Addr Reg Indirect with Pre decrement
; Absolute Word Address
; Absolute Long Address
; Immediate Data

*******************************************************************************
*	OR 			Dn,<ea>
*******************************************************************************

; Data Register Direct
; Addr Reg Direct
; Addr Reg Indirect
; Addr Reg Indirect with Post increment
; Addr Reg Indirect with Pre decrement
; Absolute Word Address
; Absolute Long Address
; Immediate Data

*******************************************************************************
*	ORI 		#<data>,<ea>			; Size = (Byte, Word, Long)
*******************************************************************************

; Data Register Direct
; Addr Reg Direct
; Addr Reg Indirect
; Addr Reg Indirect with Post increment
; Addr Reg Indirect with Pre decrement
; Absolute Word Address
; Absolute Long Address
; Immediate Data

*******************************************************************************
*	EOR 		Dn,<ea>					; Size = (Byte, Word, Long)
*******************************************************************************

; Data Register Direct
; Addr Reg Direct
; Addr Reg Indirect
; Addr Reg Indirect with Post increment
; Addr Reg Indirect with Pre decrement
; Absolute Word Address
; Absolute Long Address
; Immediate Data

*******************************************************************************
*	EORI 		#<data>,<ea>			; Size = (Byte, Word, Long)
*******************************************************************************

; Data Register Direct
; Addr Reg Direct
; Addr Reg Indirect
; Addr Reg Indirect with Post increment
; Addr Reg Indirect with Pre decrement
; Absolute Word Address
; Absolute Long Address
; Immediate Data

*******************************************************************************
*	ASd where d is direction, L or R
*******************************************************************************

*******************************************************************************
*	ASL 		Dx,Dy 					; Size = (Byte, Word, Long)
*	ASL 		#<data>,Dy
*	ASL 		<ea>
*******************************************************************************

; Data Register Direct
; Addr Reg Direct
; Addr Reg Indirect
; Addr Reg Indirect with Post increment
; Addr Reg Indirect with Pre decrement
; Absolute Word Address
; Absolute Long Address
; Immediate Data

*******************************************************************************
*	ASR 		Dx,Dy 					; Size = (Byte, Word, Long)
*	ASR 		#<data>,Dy
*	ASR 		<ea>
*******************************************************************************

; Data Register Direct
; Addr Reg Direct
; Addr Reg Indirect
; Addr Reg Indirect with Post increment
; Addr Reg Indirect with Pre decrement
; Absolute Word Address
; Absolute Long Address
; Immediate Data

*******************************************************************************
*	ROd where d is direction, L or R 		
*******************************************************************************

*******************************************************************************
*	ROL 		Dx,Dy 					; Size = (Byte, Word, Long)
*	ROL 		#<data>,Dy
*	ROL 		<ea>
*******************************************************************************

; Data Register Direct
; Addr Reg Direct
; Addr Reg Indirect
; Addr Reg Indirect with Post increment
; Addr Reg Indirect with Pre decrement
; Absolute Word Address
; Absolute Long Address
; Immediate Data

*******************************************************************************
*	ROR 		Dx,Dy 					; Size = (Byte, Word, Long)
*	ROR 		#<data>,Dy
*	ROR 		<ea>
*******************************************************************************

; Data Register Direct
; Addr Reg Direct
; Addr Reg Indirect
; Addr Reg Indirect with Post increment
; Addr Reg Indirect with Pre decrement
; Absolute Word Address
; Absolute Long Address
; Immediate Data

*******************************************************************************
*	CMP 		<ea>,Dn 				; Size = (Byte, Word, Long)
*******************************************************************************

; Data Register Direct
; Addr Reg Direct
; Addr Reg Indirect
; Addr Reg Indirect with Post increment
; Addr Reg Indirect with Pre decrement
; Absolute Word Address
; Absolute Long Address
; Immediate Data

*******************************************************************************
*	CMPA 		<ea>,An 				; Size = (Word, Long)
*******************************************************************************

; Data Register Direct
; Addr Reg Direct
; Addr Reg Indirect
; Addr Reg Indirect with Post increment
; Addr Reg Indirect with Pre decrement
; Absolute Word Address
; Absolute Long Address
; Immediate Data

*******************************************************************************
*	CMPI 		#<data>,<ea>			; Size = (Byte, Word, Long)
*******************************************************************************

; Data Register Direct
; Addr Reg Direct
; Addr Reg Indirect
; Addr Reg Indirect with Post increment
; Addr Reg Indirect with Pre decrement
; Absolute Word Address
; Absolute Long Address
; Immediate Data

*******************************************************************************
*	JMP 		<ea>					; Unsized
*******************************************************************************

; Data Register Direct
; Addr Reg Direct
; Addr Reg Indirect
; Addr Reg Indirect with Post increment
; Addr Reg Indirect with Pre decrement
; Absolute Word Address
; Absolute Long Address
; Immediate Data

*******************************************************************************
*	JSR 		<ea>					; Unsized
*******************************************************************************

; Data Register Direct
; Addr Reg Direct
; Addr Reg Indirect
; Addr Reg Indirect with Post increment
; Addr Reg Indirect with Pre decrement
; Absolute Word Address
; Absolute Long Address
; Immediate Data

*******************************************************************************
*	Bcc 		<label>					; Size = (Byte, Word, Long*)
*******************************************************************************

; Data Register Direct
; Addr Reg Direct
; Addr Reg Indirect
; Addr Reg Indirect with Post increment
; Addr Reg Indirect with Pre decrement
; Absolute Word Address
; Absolute Long Address
; Immediate Data

*******************************************************************************
*	NOP 								; Unsized
*******************************************************************************

; Data Register Direct
; Addr Reg Direct
; Addr Reg Indirect
; Addr Reg Indirect with Post increment
; Addr Reg Indirect with Pre decrement
; Absolute Word Address
; Absolute Long Address
; Immediate Data

*******************************************************************************
*	RTS 								; Unsized
*******************************************************************************

; Data Register Direct
; Addr Reg Direct
; Addr Reg Indirect
; Addr Reg Indirect with Post increment
; Addr Reg Indirect with Pre decrement
; Absolute Word Address
; Absolute Long Address
; Immediate Data

*******************************************************************************
*                       End Test Disassemble Routines
*******************************************************************************

		    END		    start
		    
*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
