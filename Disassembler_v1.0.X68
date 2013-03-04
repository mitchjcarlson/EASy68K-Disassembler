*-----------------------------------------------------------
* Title      : Team SaB Disassembler
* Written by : Kyle Rindahl & Mitch Carlson
* Date       : Feb. 22, 2013
* Description: Disassembler v1.0
*-----------------------------------------------------------


*******************************************************************************
*/////////////////////////////////////////////////////////////////////////////*
*                                  I/O Routine                                *
*\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\*
*******************************************************************************
	ORG	$1000
START:									;first instruction of program

			OPT		CRE					;Bring in the Symbol Table
strtAddr	EQU		$00002000			;Starting Address for user input program
endAddr		EQU		$000FFFFF			;Ending Address - upper bound of input program
badStart	EQU		$000FFFFE			;Invalid starting Address if GTE 000FFFFE
dollar		EQU		$24					;ASCII $
LF			EQU		$0A					;ASCII value for Line feed
CR			EQU		$0D					;ASCII value for Carriage return
space		EQU		$20					;ASCII value for space
comma		EQU		$2C					;ASCII value for comma
task0		EQU		00					;Task0 from Berger, print a string to screen
task1		EQU		01					;Task1 from Berger, prompt for input w/o newline
task2		EQU		02					;Task2 from Berger, prompt and wait for input
start		EQU		$1000				;Starting address of program
addrLen		EQU		08					;Address Length = 8 bytes
wordLen		EQU		04					;Word Length = 4 bytes
stack		EQU		$00100000			;Default Location of Stack
evenAnd		EQU		$00000001			;EvenCk subroutine check if a number is even 
D			EQU		$44					;ASCII value for D
A			EQU		$41					;ASCII value for A
T			EQU		$54					;ASCII value for T
upN			EQU		$4E					;ASCII value for N for User Prompt
lwn			EQU		$6E					;ASCII value for n for User Prompt
upY			EQU		$59					;ASCII value for Y for User Prompt
lwY			EQU		$79					;ASCII value for y for User Prompt
outCt		EQU		25					;Will show 25 lines on each screen, can adjust
region		EQU		80					;decimal number 80 to help fill


			ORG			start			;Program Start
			LEA			stack,SP		;Stack pointer in A7

*Displays greeting to user, prompts to begin
Greeting	MOVE.B		#task0,D0		;Start of Greeting. Loads D0 with text from greeting
			LEA			greet,A1		;Load Greeting address into A1
			MOVE.W		greetL,D1		;Store Greeting length into D1
			TRAP		#15				;Run

			MOVE.B		#task2,D0		;D0 Input from user
			LEA			decision,A1		;Store input ptr to A1
			TRAP		#15				;Run

			MOVE.B		(A1),D2			;D2 holds first byte of input
			CMPI.B		#upY,D2			;Check if D2 == Y
			BEQ			procStart		;Start disassembling
			CMPI.B		#lwY,D2			;Check if D2 == y
			BEQ			procStart		;Start disassembling
			CMPI.B		#upN,D2			;Check if D2(decision) == N
			BEQ			stp				;Stop disassembler
			CMPI.B		#lwN,D2			;Check if D2(decision) == n
			BEQ			stp				;Stop disassembler
			BRA			greetErr		;Display Error - invalid input	

*Prompts and processes Starting Address
procStart   MOVE.B	    #task1,D0		;D0 holds input from user
			LEA			stAdd,A1		;A1 holds string asking for start
			MOVE.W		stAddL,D1		;D1 holds length of start string
			TRAP		#15				;Run

			MOVE.B		#task2,D0		;D0 holds task2(02), retrieve input
			LEA			data1,A1		;Storage location for input string
			TRAP		#15				;Run

			CMPI.B		#00,D1			;Compare starting addr length to 0
			BLE			startErr		;BLE 0 to bad String message (Addr too small) 
			CMPI.B		#addrLen,D1		;compare starting addr length to 8
			BGT			startErr		;BGE 0 to badstring message (Addr too big)
			CLR.L		D7				;Remove data from D7
			BSR			conv_to_hex		;Go to Hex conversion subroutine
			CMPI.B		#01,D6			;Check if bad value flag(D6) == 1 (is set)
			BEQ			startErr		;Branch to Bad String message (bad value flag set)
			CLR.L		D2				;First clear register D2
			MOVE.B		#addrLen,D2		;Then put value 8 in D2
			SUB.B		D1,D2			;Subtract length of string from 8
			MULU.W		#4,D2			;Multiply by 4 to get word
			LSL.L		D2,D7			;Shift value calculated at D2 left, store in D7
			BSR			check_even		;Verify by checking if even
			CMPI.L		#strtAddr,D7	;compare start address and shifted address
			BLT			startErr		;if smaller then is a bad address
			CMPI.L		#badStart,D7	;Too close to highest available address, so invalid
			BGE			startErr		;Start is larger than end, Branch to Error
			MOVE.L		D7,start_hex	;start_hex holds valid start address in hex
			BRA			procEnd			;Branch to procEnd for End Addr validation

*Prompts and processes Ending Address
procEnd		MOVE.B		#task1,D0		;D0 holds task1, print wo CR
			LEA			endAdd,A1		;A1 holds string asking for ending address
			MOVE.W		endAddL,D1		;D1 holds length of ending string
			TRAP		#15				

			MOVE.B		#task2,D0		;D0 holds task2, get input from user
			LEA			data2,A1		;Store input (as ptr) from user into A1
			TRAP		#15				;Run

			CMPI.B		#00,D1			;Compare starting addr length to 0
			BLE			endErr			;BLE 0 to Bad Ending Error (Addr too small)
			CMPI.B		#addrLen,D1		;Compare address size to D1
			BGT			endErr			;BGT value 8, branch to Bad Ending Error
			CLR.L		D7				;Remove data from D7
			BSR			conv_to_hex		;Go to Hex conversion subroutine
			CMPI.B		#01,D6			;Check if bad value flag(D6) == 1 (is set)
			BEQ			endErr			;BEQ branch to Bad Ending Error
			CLR.L		D2				;First clear register D2
			MOVE.B		#addrLen,D2		;Then put value 8 in D2
			SUB.B		D1,D2			;Subtract length of string from 8
			MULU.W		#4,D2			;Multiply by 4 to get word
			LSL.L		D2,D7			;Shift value calculated at D2 left, store in D7
			CMPI.L		#endAddr,D7		;Compare end address and shifted address
			BGT			endErr			;If larger than end address, branch to end error
			MOVE.L		start_hex,D6	;Fill D6 with hex value of starting address
			ADDI.L		#01,D6          ;Add 1 to starting address
			CMP.L		D6,D7			;Compare with end address
			BLE			endErr			;Branch to end error if less than or equal
			MOVE.L		D7,end_hex		;Set end_hex to shifted address value
			MOVE.B		#task1,D0		;Get input from user
			LEA         tempOut,A1      ;Load temporary output to A1
			MOVE.W      tempOutL,D1     ;Load the length of the temp message
			TRAP        #15             ;Run
			BRA         Greeting        ;Branch back to Greeting

*******************************************************************************
*                            I/O Subroutines
*******************************************************************************
*******************************************************************************
* conv_to_hex - Converts an ASCII string to a hex value
*******************************************************************************

conv_to_hex
    		MOVEM.L		D1/D2,-(SP)		;Put utility register on stack
hex_loop	CMPI.B		#00,D1			;If D1 is 0 done
			BEQ			h_return		;If done exit
			SUBI.B		#01,D1			;Update counter
			ROL.L		#4,D7			;Prepare register to take next hex
			MOVE.B		(A1)+,D2		;D2 holds next byte to convert
			CMPI.B		#$30,D2			;Compare 30 to D2 if 
			BLT			badflag			;Is ASCII is less than 30 bad
			CMPI.B		#$39,D2			;If equal or less than 39
			BLE			h_numconv		;Convert a number
			CMPI.B		#$40,D2			;If D2 is $40 invalid
			BLE			badflag			;Then bad and exit
			CMPI.B		#$46,D2			;Compare D2 to $46
			BLE			h_unconv		;Branch to convet hex letter
			CMPI.B		#$61,D2			;Compare D2 to $61
			BLT			badflag			;If less than bad and exit
			CMPI.B		#$66,D2			;Compare D2 to $66
			BLE			h_letconv		;If less than or equal convert to HEX
			BRA			badflag			;If haven't coverted here, it's invalid
h_numconv	SUBI.B		#$30,D2			;Convert a number
			OR.B		D2,D7			;Add hex digit to D7
			BRA			hex_loop		;Back to loop
h_letconv	SUBI.B		#$57,D2			;Convert to Hex letter
			OR.B		D2,D7			;Add hex digit to D7
			BRA			hex_loop		;Back to loop
h_unconv	SUBI.B		#$37,D2			;Convert to Hex letter
			OR.B		D2,D7			;Add hex digit to D7
			BRA			hex_loop		;Back to loop
badflag		MOVE.B		#01,D6			;Set bad flag
			BRA			h_return		;Then exit
h_return	MOVEM.L		(SP)+,D1/D2		;Pop register off stack
			RTS							;Return from subroutine	

*******************************************************************************
* conv_to_ascii - takes Hex value, separates into individual Hex bytes
*******************************************************************************
conv_to_ascii
    		MOVEM.L		D3/D4/D2,-(SP)	;Save D2 and A0
			CMPI.W		#04,D4			;See if D4 is a long or word
			BEQ			a_shift			;If a word need to shift 
ascii_loop	CMPI.W		#00,D4			;Is count done		
			BEQ			a_return		;If done exit subroutine
			ROL.L		#4,D3			;Update D3 to next hex
			MOVE.L		D3,D2			;So D3 isn't corrupted
			ANDI.L		#$0000000F,D2	;Isolate the last 4 binary digits
			SUBI.B		#1,D4			;Update counter
			CMPI.B		#$09,D2			;Compare hex 9 and D2
			BLE			a_numconv		;If 9 or less it's a number
			BRA			a_letconv		;Then is a letter
a_numconv   ADDI.W		#$30,D2			;Convert a number
			BRA			a_save			;Now put in  memory
a_letconv	ADDI.W		#$37,D2			;Convert to Hex letter
			BRA			a_save			;Now put in memory
a_save		MOVE.B		D2,(A3)+		;Save in memory and ++
			BRA			ascii_loop		;Back to top of loop
a_shift		ROL.L		#08,D3			;Move over 2 digits
			ROL.L		#08,D3			;Move over 2 digits
			BRA			ascii_loop		;Start the loop
a_return	MOVEM.L		(SP)+,D3/D4/D2	;Pop off stack
			RTS

*******************************************************************************
*printAsm - Prints the contents of the buffer
*         - Checks Flag Bit  1 -> inValid Buffer   0 -> Valid Buffer
*******************************************************************************
printAsm	MOVEM.L		A0/D0/D1,-(SP)		*Store Registers on Stack
			CMPI.B		#01,D6				*Check Flag
			BEQ			prtInvalid			*Branch to Write Invalid Buffer
			BRA			prtValid			*Branch to Write Valid Buffer
prtInvalid	MOVE.L		#invalidB,A1		*A1 holds Start of invalidB
			MOVE.W		#$13,D1				*Store Counter 
			MOVE.B		#task0,D0			*D0,A1, and D1 sb set up
			TRAP		#15					
			BRA			prtExit				*Exit Subroutine
prtValid	MOVE.L		#validB,A1			*Store String in A1
			MOVE.B		#task0,D0			*D0,A1, and D1 sub set up
			TRAP		#15					
			BRA			prtExit				*Exit Subroutine
prtExit		MOVEM.L		(SP)+,A0/D0/D1		*Clean Up
			RTS								
			
*******************************************************************************
*send_addr_buf - Sends an Address Register to the Buffer
*******************************************************************************
send_addr_buf
            MOVEM.L     D0-D2/A1,-(SP)  ;Send Registers to Stack
            LEA         addr_regs,A1    ;Load Address Registers
            ANDI.W	    #$00FF,D0	    ;Mask Most Significant Bits
		    MULU.W	    #2,D0		    ;Calculate Offset
		    MOVE.W 	    #2,D1 		    ;Store the Length
		    LEA	        (A1,D0.W),A1	;Get Index including Offset
		    BSR	        send_instr_buf	;Send to Buffer    
            MOVEM.L     (SP)+,D0-D2/A1  ;Restore Stack to Registers
            RTS                         ;Return

*******************************************************************************
*send_data_buf - Sends a Data Register to the Buffer
*******************************************************************************
send_data_buf
            MOVEM.L     D0-D2/A1,-(SP)  ;Send Registers to Stack
            LEA         data_regs,A1    ;Load Data Registers
            ANDI.W	    #$00FF,D0	    ;Mask Most Significant Bits
		    MULU.W	    #2,D0		    ;Calculate Offset
		    MOVE.W 	    #2,D1 		    ;Store the Length
		    LEA	        (A1,D0.W),A1	;Get Index including Offset
		    BSR	        send_instr_buf	;Send to Buffer    
            MOVEM.L     (SP)+,D0-D2/A1  ;Restore Stack to Registers
            RTS                         ;Return

*******************************************************************************
*send_byte_buf - Tests and sends a byte within a Register to the Buffer
*******************************************************************************
send_byte_buf
            CMPI        #8,D0           ;Determine if is a Data or Addr Register
            BLT         isdatareg       ;Branch if is in fact a Data Reg
            SUBI        #8,D0           ;Address Register, need to shrink
            BSR         send_addr_buf   ;Branch to Send Addr Register to Buffer
            BRA         byte_buf_done   ;Branch to Exit
            
isdatareg   BSR         send_data_buf   ;Branch to Send Data Register to Buffer

byte_buf_done
            RTS                         ;Return               
            
*******************************************************************************
*check_even - Checks if Hex address is even
*******************************************************************************
check_even
        	MOVEM.L		D2,-(SP)		;Put utility register on stack
			MOVE.L		D7,D2			;Move D7 to D2
			ANDI.L		#evenAnd,D2		;And $00000001 with D2
			CMPI.L		#00,D2			;If D2 is 0 then value was odd
			BEQ			even			;If D2 equals 0 it was even	
			ADDI.L		#01,D7			;If was odd add one to D7 
			BRA			even			;Done
even		MOVEM.L	(SP)+,D2			;Pop resister off stack		
			RTS							;Return from subroutine

*******************************************************************************
*fill_buf - Fills the buffer with spaces
*******************************************************************************
fill_buf
    		CMPI.W		#00,D0			;Check for empty
			BEQ			exit_fill		;Exit
			MOVE.B		#space,(A0)+	;Fill with a space, then increment
			SUBI.W		#01,D0			;Decrement Counter
			BRA			fill_Buf		;Loop to continue filling
exit_fill   RTS							;Return

*******************************************************************************
*send_instr_buf - Sends the value in the Register to the Appropriate Buffer
*               - 0 -> Valid Buffer        1 -> Invalid Buffer
*******************************************************************************
send_instr_buf
        	MOVEM.L		A0/D0/D1,-(SP)	;Write Registers to Stack
			CMPI.B		#01,D6			;Check for Bad Flag
			BEQ			prtInvalid		;If Flagged, send to Invalid Buffer
			BRA			prtValid		;If Not Flagged, send to Valid Buffer
send_inv	MOVE.L		#invalidB,A1	;Start of Invalid Buffer
			MOVE.W		#$13,D1			;Location of Counter
			MOVE.B		#task0,D0		;D0,A1, and D1 sb set up
			TRAP		#15				
			BRA			instr_exit		;Branch to exit
send_val	MOVE.L		#validB,A1		;move A1 to hold string
			MOVE.B		#task0,D0		;D0,A1, and D1 sub set up
			TRAP		#15				
			BRA			instr_exit		;Branch to exit
instr_exit	MOVEM.L		(SP)+,A0/D0/D1	;restore stack
			RTS							;return from subroutine	

****************************** IO Errors **************************************

greetErr	MOVE.B		#task0,D0		;D0 holds task2(02), print w CR
			LEA			iError,A1		;A1 holds error string
			MOVE.W		iErrorL,D1		;D1 holds length of start error string
			TRAP		#15				
			BRA			Greeting		;Branch back to Greeting

startErr	MOVE.B		#0,D6			;Reset bad flag
			MOVE.B		#task0,D0		;D0 holds task2, print w CR
			LEA			stError,A1		;A1 holds error string
			MOVE.W		stErrorL,D1		;D1 holds length of start error string
			TRAP		#15				
			BRA			procStart		;Back to start sequence for reprompt

endErr		MOVE.B		#0,D6			;Reset bad flag
			MOVE.B		#task0,D0		;D0 holds task2, print w CR
			LEA			endError,A1		;A1 holds error string
			MOVE.W		endErrorL,D1	;D1 holds length of start error string
			TRAP		#15				
			BRA			procEnd			;Back to end sequence for repromp

stp		STOP		#$2700		*back to simulator

**************************** IO Variables *************************************
data1               DS.B        20              ;Where Starting Address is stored
data2               DS.B        20              ;Where Ending Address is stored
decision	        DS.B	    20	            ;to hold User's Response           
start_hex           DS.L        1               ;Starting Value in Hex  
end_hex             DS.L        1               ;Ending Value in Hex    
dataSt              DS.B        20              ;Continue Conditional Response
col_template        DC.B        CR,LF,CR,LF,'MEMORY LOCATION    OP-CODE     OPERAND',CR,LF
c_template_len      DC.W        42              ;Length of Column Template

validB              DS.B        80              ;80 Bytes for valid buffer
invalidB            DS.B        80              ;80 Bytes for invalid buffer
temp                DS.B        30              ;30 bytes for instructions
carr_ret            DC.B        CR
carr_retLen         DC.B        1
linefeed            DC.B        LF
linefeedLen         DC.B        1
addr_regs	        DC.B  	'A0','A1','A2','A3','A4','A5','A6','A7'
data_regs	        DC.B  	'D0','D1','D2','D3','D4','D5','D6','D7'


************************ IO Prompts and Messages*******************************
ascii_w     DS.W        1
greet		DC.B	    'SaB Disassembler - CSS 422 Winter',CR,LF
		    DC.B	    'Start Disassembler?',CR,LF
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

curbuf		DS.L	    1	            ;current position in the buffer
curct		DS.W	    1	            ;current count inside the good buffer

tempOut     DC.B        'This is where the opcodes are processed',CR,LF
tempOutL    DC.W        41
			
*******************************************************************************
*                               End I/O Routine
*******************************************************************************


*******************************************************************************
*/////////////////////////////////////////////////////////////////////////////*
*                               Op-Code Routine                               *
*\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\*
*******************************************************************************

* --Receive a pointer to the op-code word in memory, a pointer to the next
*   available space in the buffer, and a good/bad flag (bool bit) from the I/O
*   routine
* --The Word data at the specified address is moved to Data register
* --Move bits from the word to separate data registers for comparison, and/or
*   employ some form of bit masking, shifting, or rolling.
* --If Word cannot be decoded to a matching op-code, set some kind of bool
*   flag/bit and return to I/O
* --If Word can be decoded, then prepare ASCII string to return to I/O
* --Send 6 bits from the EA field of the op-code word, a pointer to the
*   next word after the op-code Word, and a good/bad flag (bool bit) to the
*   EA routine
* --Receive a pointer to the next word after the EA word, a pointer to next
*   available space in the buffer, and a good/bad flag (bool bit) from the EA
*   routine
* --Send a memory pointer to the next op-code word and a good/bad flag 
*   (bool bit) to I/O routine

*******************************************************************************

**Notes for routine**
* --Registers are arbitrary, but all register states except the register used
*   for the pointer to the op-code word (A0 for now) should be saved prior to 
*   op-code routine anyway
* --Universal buffer needs to be established
* --bool bit, still not sure which register to use
* --OCR = Op-code routine
* --JSR OCR is a temporary call, remove when I/O actual utilizes subroutine

OCR ; subroutine called by I/O
            MOVE.L      D3,D1       ; D3 could be any register from I/O      

            MOVEQ       #3,D0       ; Iso-task 3: isolate d12-d15
            BSR         ISO_BITS
                                    **Branches**
            CMP.B       #0,D2
            BEQ         OCR_0       ; ORI, ANDI, SUBI, EORI, COMPI
            CMP.B       #1,D2
            BEQ         OCR_1       ; MOVE.B
            CMP.B       #2,D2
            BEQ         OCR_2       ; MOVE.W, MOVEA.W
            CMP.B       #3,D2
            BEQ         OCR_3       ; MOVE.L, MOVEA.L
            CMP.B       #4,D2
            BEQ         OCR_4       ; NEG,NOP,RTS,JSR,JMP
            CMP.B       #5,D2
            BEQ         OCR_5       ; ADDQ
            CMP.B       #6,D2
            BEQ         OCR_6       ; Bcc
            CMP.B       #8,D2
            BEQ         OCR_8       ; OR
            CMP.B       #9,D2
            BEQ         OCR_9       ; SUBA
            CMP.B       #11,D2
            BEQ         OCR_11      ; EOR, CMP, CMPA
            CMP.B       #12,D2
            BEQ         OCR_12      ; AND
            CMP.B       #13,D2
            BEQ         OCR_13      ; ADDA
            CMP.B       #14,D2
            BEQ         OCR_14      ; ASd, ROd
            BNE         DATA        ; value not recognized

*********************** ORI, ANDI, SUBI, EORI, COMPI **************************
OCR_0
            MOVEQ       #2,D0       ; Iso-task 2: isolate d9-d11
            BSR         ISO_BITS
                                    **Branches**
            CMP.B       #0,D2
            BEQ         OCR_0_0     ; ORI
            CMP.B       #1,D2
            BEQ         OCR_0_1     ; ANDI
            CMP.B       #2,D2
            BEQ         OCR_0_2     ; SUBI
            CMP.B       #5,D2
            BEQ         OCR_0_5     ; EORI
            CMP.B       #6,D2
            BEQ         OCR_0_6     ; CMPI
            BNE         DATA        ; value not recognized

************************************* ORI *************************************
OCR_0_0
            MOVE.W      #_ORI,(A6)+ ; push address of ORI to buffer
            MOVEQ       #1,D0       ; Iso-task 1: isolate bits d6-d7
            BSR         ISO_BITS
            BSR         BWL         ; append .B, .W, or .L
            * Isolate bits d0-d5 and send them to EA routine
            RTS                     ; return to I/O

************************************ ANDI *************************************
OCR_0_1
            MOVE.W      #_ANDI,(A6)+ ; push address of ANDI to buffer
            MOVEQ       #1,D0       ; Iso-task 1: isolate bits d6-d7
            BSR         ISO_BITS
            BSR         BWL         ; append .B, .W, or .L
            * Isolate bits d0-d5 and send them to EA routine
            RTS                     ; return to I/O

************************************ SUBI *************************************
OCR_0_2
            MOVE.W      #_SUBI,(A6)+ ; push address of SUBI to buffer
            MOVEQ       #1,D0       ; Iso-task 1: isolate bits d6-d7
            BSR         ISO_BITS
            BSR         BWL         ; append .B, .W, or .L
            * Isolate bits d0-d5 and send them to EA routine
            RTS                     ; return to I/O

************************************ EORI *************************************
OCR_0_5
            MOVE.W      #_EORI,(A6)+ ; push address of EORI to buffer
            MOVEQ       #1,D0       ; Iso-task 1: isolate bits d6-d7
            BSR         ISO_BITS
            BSR         BWL         ; append .B, .W, or .L
            * Isolate bits d0-d5 and send them to EA routine
            RTS                     ; return to I/O
            
************************************ CMPI *************************************
OCR_0_6
            MOVE.W      #_CMPI,(A6)+ ; push address of CMPI to buffer
            MOVEQ       #1,D0       ; Iso-task 1: isolate bits d6-d7
            BSR         ISO_BITS
            BSR         BWL         ; append .B, .W, or .L
            * Isolate bits d0-d5 and send them to EA routine
            RTS                     ; return to I/O
*******************************************************************************
            
*********************************** MOVE.B ************************************
OCR_1
*******************************************************************************

****************************** MOVE.W, MOVEA.W ********************************
OCR_2
*******************************************************************************

****************************** MOVE.L, MOVEA.L ********************************
OCR_3
*******************************************************************************

************************** NEG, NOP, RTS, JSR, JMP ****************************
OCR_4
            MOVEQ       #2,D0           ; Iso-task 2: isolate d9-d11
            BSR         ISO_BITS
                                        **Branches**
            CMP.B       #2,D2
            BEQ         OCR_4_2         ; NEG
            CMP.B       #7,D2
            BEQ         OCR_4_7         ; NOP, RTS, JSR, JMP
            BNE         DATA            ; value not recognized

************************************* NEG *************************************
OCR_4_2
            MOVE.W      #_NEG,(A6)+     ; push address of NEG to buffer
            MOVEQ       #1,D0           ; Iso-task 1: isolate bits d6-d7
            BSR         ISO_BITS
            BSR         BWL             ; append .B, .W, or .L
            * Isolate bits d0-d5 and send them to EA routine
            RTS                         ; return to I/O

***************************** NOP, RTS, JSR, JMP ******************************
OCR_4_7
            MOVEQ       #1,D0           ; Iso-task 1: isolate bits d6-d7
            BSR         ISO_BITS

            CMP.B       #1,D2
            BEQ         OCR_4_7_1       ; NOP, RTS
            CMP.B       #2,D2     
            BEQ         OCR_4_7_2       ; JSR
            CMP.B       #3,D2     
            BEQ         OCR_4_7_3       ; JMP
            BNE         DATA            ; value not recognized

********************************** NOP, RTS ***********************************
OCR_4_7_1
            MOVEQ       #0,D0           ; Iso-task 0: isolate d0-d5
            BSR         ISO_BITS
            CMP.B       #$31,D2
            BEQ         OCR_4_7_1_31    ; NOP
            CMP.B       #$35,D2     
            BEQ         OCR_4_7_1_35    ; RTS
            BNE         DATA            ; value not recognized

************************************ NOP **************************************
OCR_4_7_1_31
            MOVE.W      #_NOP,(A6)+     ; push address of NOP to buffer
            * Isolate bits d0-d5 and send them to EA routine
            RTS                         ; return to I/O

************************************ RTS **************************************
OCR_4_7_1_35
            MOVE.W      #_RTS,(A6)+     ; push address of RTS to buffer
            * Isolate bits d0-d5 and send them to EA routine
            RTS                         ; return to I/O

************************************ JSR **************************************
OCR_4_7_2
            MOVE.W      #_JSR,(A6)+     ; push address of JSR to buffer
            * Isolate bits d0-d5 and send them to EA routine
            RTS                         ; return to I/O

************************************ JMP **************************************
OCR_4_7_3
            MOVE.W      #_JMP,(A6)+     ; push address of JMP to buffer
            * Isolate bits d0-d5 and send them to EA routine
            RTS                         ; return to I/O
*******************************************************************************

************************************ ADDQ *************************************
OCR_5
            MOVE.W      #_ADDQ,(A6)+    ; push address of ADDQ to buffer
            MOVEQ       #1,D0           ; Iso-task 1: isolate bits d6-d7
            BSR         ISO_BITS
            BSR         BWL             ; append .B, .W, or .L
            * Isolate bits d0-d5 and send them to EA routine
            RTS                         ; return to I/O
*******************************************************************************

************************************ Bcc **************************************
OCR_6 
*******************************************************************************

************************************* OR **************************************
OCR_8
            MOVE.W      #_OR,(A6)+      ; push address of OR to buffer
            MOVEQ       #1,D0           ; Iso-task 1: isolate bits d6-d7
            BSR         ISO_BITS
            BSR         BWL             ; append .B, .W, or .L
            * Isolate bits d0-d5 and send them to EA routine
            RTS                         ; return to I/O
*******************************************************************************

************************************ SUBA *************************************
OCR_9
            MOVE.W      #_SUBA,(A6)+    ; push address of SUBA to buffer
            MOVEQ       #4,D0           ; Iso-task 4: isolate bits d8
            BSR         ISO_BITS
            BSR         WL              ; .W or .L, use WL when isolating d8
            * Isolate bits d0-d5 and send them to EA routine
            RTS                         ; return to I/O
*******************************************************************************

******************************* EOR, CMP, CMPA ********************************
OCR_11
            MOVEQ       #1,D0           ; Iso-task 1: isolate bits d6-d7
            BSR         ISO_BITS

            CMP.B       #3,D2
            BEQ         OCR_11_3        ; CMPA
            BRA         OCR_11_U        ; EOR, CMP

OCR_11_3 ; CMPA
            MOVE.W      #_CMPA,(A6)+    ; push address of CMPA to buffer
            MOVEQ       #4,D0           ; Iso-task 4: isolate bits d8
            BSR         ISO_BITS
            BSR         WL              ; .W or .L, use WL when isolating d8
            * Isolate bits d0-d5 and send them to EA routine
            RTS                         ; return to I/O

OCR_11_U ; EOR, CMP
            MOVEQ       #4,D0           ; Iso-task 4: isolate bits d8
            BSR         ISO_BITS

            CMP.B       #0,D2
            BEQ         OCR_11_U_0      ; CMP
            BRA         OCR_11_U_1      ; EOR

OCR_11_U_0 ; CMP
            MOVE.W      #_CMP,(A6)+ ; push address of CMP to buffer
            MOVEQ       #1,D0       ; Iso-task 1: isolate bits d6-d7
            BSR         ISO_BITS
            BSR         BWL         ; append .B, .W, or .L
            * Isolate bits d0-d5 and send them to EA routine
            RTS                     ; return to I/O

OCR_11_U_1 ; EOR
            MOVE.W      #_EOR,(A6)+ ; push address of EOR to buffer
            MOVEQ       #1,D0       ; Iso-task 1: isolate bits d6-d7
            BSR         ISO_BITS
            BSR         BWL         ; append .B, .W, or .L
            * Isolate bits d0-d5 and send them to EA routine
            RTS                     ; return to I/O

*******************************************************************************

*********************************** AND ***************************************
OCR_12
            MOVE.W      #_AND,(A6)+ ; push address of AND to buffer
            MOVEQ       #1,D0       ; Iso-task 1: isolate bits d6-d7
            BSR         ISO_BITS
            BSR         BWL         ; append .B, .W, or .L
            * Isolate bits d0-d5 and send them to EA routine
            RTS                     ; return to I/O
*******************************************************************************

************************************ ADDA *************************************
OCR_13
            MOVE.W      #_ADDA,(A6)+    ; push address of ADDA to buffer
            MOVEQ       #4,D0           ; Iso-task 4: isolate bits d8
            BSR         ISO_BITS
            BSR         WL              ; .W or .L, use WL when isolating d8
            * Isolate bits d0-d5 and send them to EA routine
            RTS                         ; return to I/O
*******************************************************************************

*******************************************************************************
OCR_14 ; ASd, ROd
*******************************************************************************

*******************************************************************************
DATA ; value not recognized
*******************************************************************************

************************** ISOLATE BITS SUBROUTINE ****************************
ISO_BITS    ; Subroutine: Isolates bits based on the task # assigned to D0
            CMP.B       #0,D0       ; Task 0, isolate d0-d5
            BEQ         d0tod5
            CMP.B       #1,D0       ; Task 1, isolate d6-d7
            BEQ         d6tod7
            CMP.B       #2,D0       ; Task 2, isolate d9-d11
            BEQ         d9tod11
            CMP.B       #3,D0       ; Task 3, isolate d12-d15
            BEQ         d12tod15
            CMP.B       #4,D0
            BEQ         d8          ; Task 4, isolate d8
            RTS

d12tod15    ; Isolate bits d12-d15 and assign them to register D2
            MOVE.W      D1,D2       ; avoid overwrite of original
            ROL.W       #4,D2       ; move d12-d15 -> d0-d3
            ANDI.W      #$F,D2      ; mask to keep only four bits
            RTS

d9tod11     ; Isolate bits d9-d11 and assign them to register D2
            MOVE.W      D1,D2       ; avoid overwrite of original
            ROL.W       #7,D2       ; move d8-d11 -> d0-d2
            ANDI.W      #7,D2       ; mask to keep only three bits
            RTS

d8          ; Isolate bits d8 and assign them to register D2
            MOVE.W      D1,D2       ; avoid overwrite of original
            ROR.W       #8,D2       ; move d8-d11 -> d0-d2
            ANDI.W      #1,D2       ; mask to keep only one bit
            RTS           

d6tod7      ; Isolate bits d6-d7 and assign them to register D2
            MOVE.W      D1,D2       ; avoid overwrite of original
            ROR.W       #6,D2       ; move d6-d7 -> d0-d1
            ANDI.W      #3,D2       ; mask to keep only two bits
            RTS

d0tod5      ; Isolate bits d0-d5 and assign them to register D4
            MOVE.W      D1,D2       ; avoid overwrite of original
            ANDI.W      #$3F,D2     ; mask to keep only six bits
            RTS
*******************************************************************************

*********************** BYTE, WORD, OR LONG SUBROUTINE ************************
BWL
            CMP.B       #0,D2
            BEQ         BYTE 
            CMP.B       #1,D2
            BEQ         WORD 
            CMP.B       #2,D2
            BEQ         LONG
            RTS                     ; RTS assumes that it didn't branch

WL
            CMP.B       #0,D2
            BEQ         WORD 
            CMP.B       #1,D2
            BEQ         LONG 
            RTS                     ; RTS assumes that it didn't branch

BYTE
            MOVE.W      #_B,(A6)+  ; push address of .B to buffer
            RTS                    ; return to OCR_(subroutine that called BWL)

WORD
            MOVE.W      #_W,(A6)+  ; push address of .W to buffer
            RTS                    ; return to OCR_(subroutine that called BWL)

LONG
            MOVE.W      #_L,(A6)+  ; push address of .L to buffer
            RTS                    ; return to OCR_(subroutine that called BWL)
*******************************************************************************

********************************* CONSTANTS ***********************************
_B          DC.L         '.B',0
_W          DC.L         '.W',0
_L          DC.L         '.L',0
_ORI        DC.L         'ORI',0
_ANDI       DC.L         'ANDI',0
_SUBI       DC.L         'SUBI',0
_EORI       DC.L         'EORI',0
_CMPI       DC.L         'CMPI',0
_MOVE       DC.L         'MOVE',0
_MOVEA      DC.L         'MOVEA',0
_NEG        DC.L         'NEG',0
_NOP        DC.L         'NOP',0
_RTS        DC.L         'RTS',0
_JSR        DC.L         'JSR',0
_JMP        DC.L         'JMP',0
_ADDQ       DC.L         'ADDQ',0
_Bcc        DC.L         'Bcc',0
_OR         DC.L         'OR',0
_SUBA       DC.L         'SUBA',0
_EOR        DC.L         'EOR',0
_CMP        DC.L         'CMP',0
_CMPA       DC.L         'CMPA',0
_AND        DC.L         'AND',0
_ADDA       DC.L         'ADDA',0
_ASL        DC.L         'ASL',0
_ASR        DC.L         'ASR',0
_ROL        DC.L         'ROL',0
_ROR        DC.L         'ROR',0
*******************************************************************************

BUFFER      DS.W          80    ; buffer stores addresses of defined constants

*******************************************************************************
*                            End Op-code Routine
*******************************************************************************



*******************************************************************************
*/////////////////////////////////////////////////////////////////////////////*
*                                   EA Routine                                *
*\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\*
*******************************************************************************

; --Receive 6 bits from the EA field of the op-code word, a pointer to the
;   next word after the op-code Word, and a good/bad flag (bool bit) from the
;   op-code routine
; --Effective address is decoded
; --If decode is successful/unsuccessful, set bool/bit flag appropriately 
; --If successful, prepare ASCII string value for display
; --Send a memory pointer to the next word after the EA word, a pointer to the
;   next available space in the buffer, and a good/bad flag (bool bit) back 
;   to op-code routine

*******************************************************************************
*EAR_decode - Decodes the EA field of the op-code word and sets the values 
*             to the buffer for the I/O to Display
*******************************************************************************
EAR_decode  
            MOVEM.L     A1-A3/A5/D0-D2/D4/D5,-(SP)       ;Save data from registers to stack
            LEA         ea_index_table,A1       ;Get reference to the EA Table
            MOVE.W      D0,D2                   ;Get a copy of the six EA bits
            MOVE.B      #3,D1                   ;Store number of bits we wish to shift
            LSR.W       D1,D0                   ;Shift to the Right
            MULU	    #6,D0			        ;Form Offset for passing to Jump Index table
	        JSR	        00(A1,D0)		        ;Now we have the index, back to Index table
	        MOVEM.L     (SP)+,A1-A3/A5/D0-D2/D4/D5       ;Restore registers from stack
	        RTS				                    ;Return 
	        
*Jump Index Table
*Table holding the different EA Modes, will branch to different Index depending on Offset
ea_index_table
            JMP         eaindex000             ;Direct Data Register
            JMP         eaindex001             ;Direct Address Register
            JMP         eaindex010             ;Indirect Address Register
            JMP         eaindex011             ;Indirect Address Register with Post Increment
            JMP         eaindex100             ;Indirect Address Register with Pre Decrement
            JMP         eaindex101             ;Indirect Address Register using Index
            JMP         eaindex110             ;Absolute or Immediate EA
            JMP         eaindex111             ;Not used

******* Direct Data Register - Return the Data Register to the buffer - Dn *********
eaindex000  
            MOVE	    D2,D0		            ;Get EA from D2 (6bits)
	        ANDI	    #7,D0		            ;Grab Register (3bits)
		    BSR	        send_data_buf           ;Send data to buffer
		    RTS                                 ;Return

***** Direct Address Register - Return the Address Register to the buffer - An *****
eaindex001  
            MOVE        D2,D0                   ;Get EA from D2 (6bits)
            ANDI        #7,D0                   ;AND with 3bits to get Register Info
            BSR         send_addr_buf          ;Send Address to buffer
            RTS                                 ;Return
            
****** Indirect Address Register - Returns Address within Parentheses - (An) *******
eaindex010  
            *Get the Open Paren
            LEA	        open_paren,A1	        ;ASCII for Open Paren
		    MOVE.W	    open_parenLen,D1        ;Get the length
		    BSR	        send_instr_buf	        ;Add the Paren to the buffer

            *Get the Address
		    CLR.L	    D0		                ;Empty data register
		    MOVE	    D2,D0		            ;Store EA bits (6bits)
		    ANDI	    #7,D0		            ;AND with 3-bits to get values
		    BSR	        send_addr_buf           ;Add Address to buffer after Open Paren

            *Get the Close Paren
		    CLR.L	    D1		                ;Empty data register
		    LEA	        close_paren,A1	        ;ASCII for Close Paren
		    MOVE.W	    close_parenLen,D1	    ;Get the length
		    BSR	        send_instr_buf          ;Add Close Paren to buffer after addr
            RTS                                 ;Return
            
************** Indirect Address Register with Post-Increment - (An)+ ***************	    
eaindex011  
            *Get the Open Paren
            LEA	        open_paren,A1	        ;ASCII for Open Paren
		    MOVE.W	    open_parenLen,D1	    ;Get the length
		    BSR	        send_instr_buf	        ;Add the Paren to the buffer

            *Get the Address
		    CLR.L	    D0		                ;Empty data register
		    MOVE	    D2,D0		            ;Store EA bits (6bits)
		    ANDI	    #7,D0		            ;AND with 3-bits to get values
		    BSR	        send_addr_buf           ;Add Address to buffer after Open Paren

            *Get the Close Paren
		    CLR.L	    D1		                ;Empty data register
		    LEA	        close_paren,A1	        ;ASCII for Close Paren
		    MOVE.W	    close_parenLen,D1	    ;Get the length
		    BSR	        send_instr_buf          ;Add Close Paren to buffer after addr
            RTS                                 ;Return
            
            *Get the Plus Sign
            CLR.L       D0                      ;Clear Register
            LEA         plus_sign,A1            ;ASCII for Plus Sign
            MOVE.W      plus_signLen,D0         ;Get the length
            BSR         send_instr_buf          ;Add Plus Sign to buffer after Close Paren
            RTS                                 ;Return
            
*************** Indirect Address Register with Pre-Decrement - -(An) ***************
eaindex100  
            *Get Minus Sign
            LEA         minus_sign,A1           ;ASCII for Minus Sign
            MOVE.W      minus_signLen,D1        ;Get the length of the Minus Sign
            BSR         send_instr_buf          ;Add Minus Sign to Buffer

            *Get Open Parentheses Sign
            CLR.L       D1                      ;Clear Register
            LEA	        open_paren,A1	        ;ASCII for Open Paren
		    MOVE.W	    open_parenLen,D1	    ;Get the length
		    BSR	        send_instr_buf	        ;Add the Paren to the buffer

            *Store Address to Buffer
		    CLR.L	    D0		                ;Empty data register
		    MOVE	    D2,D0		            ;Store EA bits (6bits)
		    ANDI	    #7,D0		            ;AND with 3-bits to get values
		    BSR	        send_addr_buf           ;Add Address to buffer after Open Paren

            *Get Close Parentheses Sign
		    CLR.L	    D1		                ;Empty data register
		    LEA	        close_paren,A1	        ;ASCII for Close Paren
		    MOVE.W	    close_parenLen,D1	    ;Get the length
		    BSR	        send_instr_buf          ;Add Close Paren to buffer after addr
            RTS                                 ;Return

******************** Indirect Address Register with an Index ***********************
eaindex101  
            *Get Dollar Sign
            LEA         dollar_sign,A1          ;ASCII for Dollar Sign
            MOVE.W      dollar_signLen,D1       ;Get the length of the Dollar Sign
            BSR         send_instr_buf          ;Add Dollar Sign to Buffer
            
            *Prep for conversion
            MOVE.W      (A5)+,A0                 ;Get 8-bit extension word
            MOVE.L      D0,D3                   ;Back up to D3
            CLR.L       D4                      ;Clear out D4
            MOVE.B      #4,D4                   ;Store the number of bytes (4) in D4
            BSR         conv_to_ascii           ;Branch to ASCII conversion Subroutine
            
            *Move Hex value to Buffer
            MOVEA.L     A3,A1                   ;Move Hex value to A1
            MOVE.W      #$4,D1                  ;Get the length of Hex value - Word
            BSR         send_instr_buf          ;Add Hex value of Address to buffer
            
            *Get Open Parentheses Sign
            CLR.L       D1                      ;Clear Register
            LEA	        open_paren,A1	        ;ASCII for Open Paren
		    MOVE.W	    open_parenLen,D1        ;Get the length
		    BSR	        send_instr_buf	        ;Add the Paren to the buffer
		    
		    *Store Address to Buffer
		    CLR.L	    D0		                ;Empty data register
		    MOVE	    D2,D0		            ;Store EA bits (6bits)
		    ANDI	    #7,D0		            ;AND with 3-bits to get values
		    BSR	        send_addr_buf           ;Add Address to buffer after Open Paren

            *Get the Comma Sign
            CLR.L       D1                      ;Clear Register
            LEA	        comma_sign,A1	        ;ASCII for Comma
		    MOVE.W	    comma_signLen,D1        ;Get the length
		    BSR	        send_instr_buf	        ;Add the Comma to the buffer
		    
		    *Get Index Register
		    MOVE.L      D5,D0                   ;Back up to D0
		    ANDI        #$F000,D0               ;We only need the first byte, hide the rest
		    LSR.L       #8,D0                   ;Shift to Right-most postion
		    LSR.L       #4,D0                   ;Ensure it is in first bit
		    BSR         send_byte_buf           ;Now store the value at this Register to buffer
		    
		    *Get the Type
		    MOVE.L      D5,D0                   ;Back up to D0
		    ANDI        #$0F00,D0               ;We only need the second byte (size)
		    LSR.L       #8,D0                   ;Shift to Right-most position		    
		    CMPI        #8,D0                   ;Compare to see if it is a LONG
		    BEQ         add_long_buf            ;Store .L to buffer
		    CMPI        #0,D0                   ;Compare to see if it is a WORD
		    BEQ         add_word_buf            ;Store .W to buffer
		    MOVE.B      #1,D6                   ;Enable bad flag bit for all other sizes

*Helper Routine to add Data Types to buffer
add_long_buf
            CLR.L       D1                      ;Clear Register
            LEA         long_ext,A1             ;ASCII for .L
            MOVE.W      long_extLen,D1          ;Get the length of Character
            BSR         send_instr_buf          ;Add .L to buffer 
            
            *Get Close Parentheses Sign
		    CLR.L	    D1		                ;Empty data register
		    LEA	        close_paren,A1	        ;ASCII for Close Paren
		    MOVE.W	    close_paren,D1	        ;Get the length
		    BSR	        send_instr_buf          ;Add Close Paren to buffer after addr
		    RTS                                 ;Return
            
add_word_buf
            CLR.L       D1                      ;Clear Register
            LEA         word_ext,A1             ;ASCII for .W
            MOVE.W      word_extLen,D1          ;Get the length of Character
            BSR         send_instr_buf          ;Add .W to buffer 
            
            *Get Close Parentheses Sign
		    CLR.L	    D1		                ;Empty data register
		    LEA	        close_paren,A1	        ;ASCII for Close Paren
		    MOVE.W	    close_paren,D1	        ;Get the length
		    BSR	        send_instr_buf          ;Add Close Paren to buffer after addr
		    RTS                                 ;Return
            		    
********************* PC, Immediate, or Absolute Addressing ************************
eaindex110
            LEA         subindex_tbl,A1         ;Loads the Subindex Jump Table
            MOVE        D2,D0                   ;Store EA original - 6 bits
            MULU        #6,D0                   ;Loads the offset for Jump Table
            JSR         00(A1,D0)               ;To SubIndex Jump Table
            RTS                                 ;Return when done

********************* PC, Immediate, or Absolute Addressing ************************
eaindex111 ;Not Used
            RTS                                 ;Just Return
            
************************* aeindex110 Subindex Jump Table ***************************
subindex_tbl ;Uses Bitmask to differentiate Types
            JMP         easub000                ;Absolute Addressing - Word
            JMP         easub001                ;Absolute Addressing - Long
            JMP         easub010                ;Indirect Program Counter w/ Displacement
            JMP         easub100                ;Immediate Data            

************************** Absolute Addressing - Word *************************
easub000
            *Get Dollar Sign
            LEA         dollar_sign,A1          ;ASCII for Dollar Sign
            MOVE.W      dollar_signLen,D1       ;Get the length of the Dollar Sign
            BSR         send_instr_buf          ;Add Dollar Sign to Buffer
            
            *Prep for Conversion
            MOVE.W      (A5)+,D0                ;Get the WORD data
            MOVE.L      D0,D3                   ;Back up to D3
            CLR.L       D4                      ;Empty Data Register
            MOVE.B      #$4,D4                  ;Get the length of Hex value - WORD
            BSR         conv_to_ascii           ;Branch to convert to ASCII
            
            *Store Hex Address to Buffer
            MOVEA.L     A3,A1                   ;Move ASCII value to A1
            MOVE.W      #$4,D1                  ;Load the length of the word
            BSR         send_instr_buf          ;Send the Address to Buffer
            
            MOVEA.L     #00000000,A4            ;Reset contents of A3
            RTS                                 ;Return
            
************************** Absolute Addressing - Long *************************
easub001
            LEA         ascii_w,A3              ;Get converted address word
            
            *Get Dollar Sign
            LEA         dollar_sign,A1          ;ASCII for Dollar Sign
            MOVE.W      dollar_signLen,D1       ;Get the length of the Dollar Sign
            BSR         send_instr_buf          ;Add Dollar Sign to Buffer
            
            *Prep for Conversion - LONG
            MOVE.L      (A5)+,D0                ;Get the LONG data
            MOVE.L      D0,D3                   ;Back up to D3
            CLR.L       D4                      ;Empty Data Register
            MOVE.B      #$8,D4                  ;Get the length of Hex value - LONG
            BSR         conv_to_ascii           ;Branch to convert to ASCII
            
            *Store Hex Address to Buffer
            MOVEA.L     A3,A1                   ;Move ASCII value to A1
            MOVE.W      #$8,D1                  ;Load the length of the word - LONG
            BSR         send_instr_buf          ;Send the Address to Buffer
            
            MOVEA.L     #00000000,A4            ;Reset contents of A3
            RTS                                 ;Return
            
******************* Program Counter Indirect w/ Displacement ******************
easub010
            MOVE.L      D4,-(SP)                ;Save D4 Register
            LEA         ascii_w,A3              ;Get converted address word
            
            *Get Dollar Sign
            LEA         dollar_sign,A1          ;ASCII for Dollar Sign
            MOVE.W      dollar_signLen,D1       ;Get the length of the Dollar Sign
            BSR         send_instr_buf          ;Add Dollar Sign to Buffer
            
            *Get the Displacement from Extension Word
            ADDI.B      #2,D4                   ;Increment Address Location
            MOVE.W      (A5),D0                 ;Get word data from Extension Word
            ADDI.L      #$FFFF0000,D0           ;Pad to cover Sign
            ADD.L       D4,D0                   ;Now add to get Displacement
            
            *Convert Displacement to Ascii - WORD
            MOVE.L      D0,D3                   ;Put Hex Value in D3
            CLR.L       D4                      ;Empty Data Register
            MOVE.B      #$4,D4                  ;Get the length of Hex Value - WORD
            BSR         conv_to_ascii           ;Convert to ASCII
            
            *Store Hex Address to Buffer
            MOVEA.L     A3,A1                   ;Move ASCII value to A1
            MOVE.W      #$4,D1                  ;Load the length of the word - WORD
            BSR         send_instr_buf          ;Send the Address to Buffer         
            MOVEA.L     #00000000,A3            ;Reset contents of A3
            
            *Add Program Counter to Buffer
            LEA         prog_ctr,A1             ;ASCII value for (PC)
            MOVE.W      prog_ctrLen,D1          ;Get the length of (PC)
            BSR         send_instr_buf          ;Add (PC) to Buffer
            
            MOVE.L      (SP)+,D4                ;Restore register
            RTS                                 ;Return
            
************************ Immediate Addressing w/ Data *************************
easub100
            LEA         ascii_w,A3              ;Get converted Address Word
            CMPI        #2,D5                   ;Check length
            BEQ         easub100_l              ;Branch to Long Subroutine
            CMPI        #3,D5                   ;Check for invalid Length
            BEQ         easub100_badLen         ;Branch to Bad Length Flag Subroutine
            
easub100_l  
            *Get Pound Sign
            LEA         pound_sign,A1           ;ASCII for Pound
            MOVE.W      pound_sign,D1           ;Get the length of the Pound Sign
            BSR         send_instr_buf          ;Add Pound Sign to Buffer
            
            *Get Dollar Sign
            LEA         dollar_sign,A1          ;ASCII for Dollar Sign
            MOVE.W      dollar_signLen,D1       ;Get the length of the Dollar Sign
            BSR         send_instr_buf          ;Add Dollar Sign to Buffer
            
            *Prep for Conversion - LONG
            MOVE.L      (A5)+,D0                ;Get the LONG data
            MOVE.L      D0,D3                   ;Back up to D3
            CLR.L       D4                      ;Empty Data Register
            MOVE.B      #$8,D4                  ;Get the length of Hex value - LONG
            BSR         conv_to_ascii           ;Branch to convert to ASCII
            
            *Store Hex Address to Buffer
            MOVEA.L     A3,A1                   ;Move ASCII value to A1
            MOVE.W      #$8,D1                  ;Load the length of the word - LONG
            BSR         send_instr_buf          ;Send the Address to Buffer
            
            MOVEA.L     #00000000,A4            ;Reset contents of A3
            RTS                                 ;Return           
            
easub100_badLen
            MOVE.B      #1,D6                   ;Enable Bad Flag bit
            RTS                                 ;Return

*******************************************************************************
*EAR_movem - Sends the value of the list of registers found within the Register
*            List Mask Field (RLMF) within the Extension word. 
*          - Will either predecrement or post-increment depending on the 
*            Direction Bit (Bit 10 equals 0 ->predecrement)
*               ~Predecrement: Dn,An        ~Postincrement: An,Dn                                
*******************************************************************************
EAR_movem
            MOVEM.L      D0-D5/A1,-(SP)         ;Save the Registers to the Stack
            MOVE.L      D0,D4                   ;Back up the Direction Bit
            MOVE.W      (A5)+,D1                ;Get the RLMF
            MOVE.L      D1,D5                   ;Back up the RLMF
            CLR.L       D2                      ;Empty Data Register
            CLR.L       D3                      ;Empty Data Register
            CMPI        #0,D0                   ;Check for Predecrement
            BEQ         predec_loop             ;Branch to Predecrement subroutine
            MOVE.B      #15,D2                  ;RLMF counter starts at 15 for Postincrement
            CMPI        #1,D0                   ;Check for Postincrement
            BEQ         post_loop              ;Branch to Postincrement subroutine
            MOVE.B      #1,D6                   ;Enable Bad Flag bit
            RTS                                 ;Return

************************** Postincrement Subroutine ***************************
post_loop
            BTST        D2,D1                   ;Get current bit of RLMF     
            BEQ         post_incr               ;Branch if inactive
            MOVE.B      D3,D0                   ;Prep to write Register to Buffer
            CMPI        #8,D2                   ;Check to see if 8-bits or less
            BLT         post_data               ;If less, it's a Data Register - Branch
            BSR         send_addr_buf           ;If not, send the address register to buffer
            BRA         post_skip               ;Skip to adding slash
post_data
            BSR         send_data_buf           ;Send data register to buffer  
          
post_skip   *Get Forward Slash
            LEA         f_slash,A1              ;ASCII for Forward Slash
            MOVE.W      f_slashLen,D1           ;Get the length of Forward Slash
            BSR         send_instr_buf          ;Send the Slash to the Buffer
            MOVE.L      D5,D1                   ;Get original RLMF 
            
post_incr
            SUBI.B      #1,D2                   ;Decrement the RLMF Counter
            CMPI.B      #0,D2                   ;Range check for RLMF Counter (<16)
            BEQ         movem_exit              ;Exit if full
            ADDI.B      #1,D3                   ;Increment Output Register Counter
            CMPI.B      #8,D3                   ;Range check for Output Register
            BEQ         post_clr                ;Branch to clear register, then loop
            BRA         post_loop               ;Branch to loop without clearing

post_clr  
            CLR.W       D3                      ;Clear the Output Register Counter
            BRA         post_loop               ;Loop again  


*************************** Predecrement Subroutine ***************************
predec_loop
            BTST        D2,D1                   ;Get current bit of RLMF     
            BEQ         predec_incr             ;Branch if inactive
            MOVE.B      D3,D0                   ;Prepare to write to Buffer
            CMPI        #8,D2                   ;Check to see if 8-bits or less
            BLT         predec_data             ;If less, it's a Data Register - Branch
            BSR         send_addr_buf           ;If not, send the address register to buffer
            BRA         predec_skip             ;Skip to adding slash
predec_data
            BSR         send_data_buf           ;Send data register to buffer  

predec_skip          
            *Get Forward Slash
            LEA         f_slash,A1              ;ASCII for Forward Slash
            MOVE.W      f_slashLen,D1           ;Get the length of Forward Slash
            BSR         send_instr_buf          ;Send the Slash to the Buffer
            MOVE.L      D5,D1                   ;Get original RLMF 
            
predec_incr
            ADDI.B      #1,D2                   ;Increment the RLMF Counter
            CMPI.B      #16,D2                  ;Range check for RLMF Counter (<16)
            BEQ         movem_exit              ;Exit if full
            ADDI.B      #1,D3                   ;Increment Output Register Counter
            CMPI.B      #8,D3                   ;Range check for Output Register
            BEQ         predec_clr              ;Branch to clear register, then loop
            BRA         predec_loop             ;Branch to loop without clearing

predec_clr  
            CLR.W       D3                      ;Clear the Output Register Counter
            BRA         predec_loop             ;Loop again           

movem_exit
            MOVEM.L     (SP)+,D0/D1/D3/A1       ;Restore Registers
            RTS
*******************************************************************************
*                                 EA Library
*******************************************************************************
open_paren	    DC.B	'('		    ;Open Parentheses
open_parenLen	DC.W	1	        ;Length of Open Parentheses
close_paren	    DC.B	')'		    ;Close Parentheses
close_parenLen	DC.W	1	        ;Length of Close Parenthese
plus_sign		DC.B	'+'		    ;Increment
plus_signLen	DC.W	1		    ;Length of Increment
minus_sign		DC.B	'-'		    ;Decrement
minus_signLen	DC.W	1		    ;Length of Decrement
dollar_sign	    DC.B	'$'		    ;Dollar Sign
dollar_signLen	DC.W	1	        ;Length of Dollar Sign
comma_sign	    DC.B	','		    ;Comma
comma_signLen	DC.W	1	        ;Length of the Comma
word_ext		DC.B	'.W'	    ;Word Extension Indicator
word_extLen	    DC.W	2	        ;Length of Word Extension
long_ext		DC.B	'.L'	    ;Long Extension Indicator
long_extLen	    DC.W	2	        ;Length of Long Extension
prog_ctr		DC.B	'(PC)'	    ;Program Counter
prog_ctrLen		DC.W	4		    ;Length of Program Couner
f_slash   	    DC.B	'/'		    ;Forward Slash
f_slashLen	    DC.W	1		    ;Length of Forward Slash
pound_sign	    DC.B	'#'		    ;Pound symbol for immediate data
pound_signLen	DC.W	1	        ;Length of pound
           
*******************************************************************************
*                               End EA Routine
*******************************************************************************





*******************************************************************************
*/////////////////////////////////////////////////////////////////////////////*
*       Testing Routines for Disassembler live below here                     *
*\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\*
*******************************************************************************


*******************************************************************************
*                         Test Disassemble Routines
*******************************************************************************
* instructions could contain as many as 5 16-bit words
* e.g. MOVE.L 	$AAAAAAAA,$55555555

                ORG         $7000

*******************************************************************************
*   NOP                                 ; Unsized
*******************************************************************************

    NOP                                 ; first instruction to disassemble

*******************************************************************************
*   NEG         <ea>                    ; Size = (Byte, Word, Long)
*******************************************************************************

    *BYTE*                              **<ea>**
    NEG.B       D0                      ; Data Register Direct
    NEG.B       (A0)                    ; Addr Reg Indirect
    NEG.B       (A0)+                   ; Addr Reg Indirect with Post increment
    NEG.B       -(A0)                   ; Addr Reg Indirect with Pre decrement
    NEG.B       $AAAA                  ; Absolute Word Address
    NEG.B       $AAAAAAAA              ; Absolute Long Address

    *WORD*
    NEG.W       D0                      ; Data Register Direct
    NEG.W       (A0)                    ; Addr Reg Indirect
    NEG.W       (A0)+                   ; Addr Reg Indirect with Post increment
    NEG.W       -(A0)                   ; Addr Reg Indirect with Pre decrement
    NEG.W       $AAAA                  ; Absolute Word Address
    NEG.W       $AAAAAAAA              ; Absolute Long Address

    *LONG*
    NEG.L       D0                      ; Data Register Direct
    NEG.L       (A0)                    ; Addr Reg Indirect
    NEG.L       (A0)+                   ; Addr Reg Indirect with Post increment
    NEG.L       -(A0)                   ; Addr Reg Indirect with Pre decrement
    NEG.L       $AAAA                  ; Absolute Word Address
    NEG.L       $AAAAAAAA              ; Absolute Long Address

*******************************************************************************
*   JMP         <ea>                    ; Unsized
*******************************************************************************

    JMP         (A0)                    ; Addr Reg Indirect
    JMP         $AAAA                   ; Absolute Word Address
    JMP         $AAAAAAAA               ; Absolute Long Address

*******************************************************************************
*   JSR         <ea>                    ; Unsized
*******************************************************************************

    JSR         (A0)                    ; Addr Reg Indirect
    JSR         $AAAA                   ; Absolute Word Address
    JSR         $AAAAAAAA               ; Absolute Long Address

*******************************************************************************
*   RTS                                 ; Unsized
*******************************************************************************

    RTS

*******************************************************************************
*   MOVE        <ea>,<ea>               ; Size = (Byte, Word, Long)
*******************************************************************************

	*BYTE*                              **DESTINATION <ea>**
    MOVE.B      D0,D1                   ; Data Register Direct
    MOVE.B      D0,(A1)                 ; Addr Reg Indirect
    MOVE.B      D0,(A1)+                ; Addr Reg Indirect with Post increment
    MOVE.B      D0,-(A1)                ; Addr Reg Indirect with Pre decrement
    MOVE.B      D0,$AAAA                ; Absolute Word Address
    MOVE.B      D0,$AAAAAAAA            ; Absolute Long Address

    *WORD*
    MOVE.W      D0,D1                   ; Data Register Direct
    MOVE.W      D0,(A1)                 ; Addr Reg Indirect
    MOVE.W      D0,(A1)+                ; Addr Reg Indirect with Post increment
    MOVE.W      D0,-(A1)                ; Addr Reg Indirect with Pre decrement
    MOVE.W      D0,$AAAA                ; Absolute Word Address
    MOVE.W      D0,$AAAAAAAA            ; Absolute Long Address

    *LONG*
    MOVE.L      D0,D1                   ; Data Register Direct
    MOVE.L      D0,(A1)                 ; Addr Reg Indirect
    MOVE.L      D0,(A1)+                ; Addr Reg Indirect with Post increment
    MOVE.L      D0,-(A1)                ; Addr Reg Indirect with Pre decrement
    MOVE.L      D0,$AAAA                ; Absolute Word Address
    MOVE.L      D0,$AAAAAAAA            ; Absolute Long Address

    *BYTE*                              **SOURCE <ea>**
    MOVE.B      D0,D1                   ; Data Register Direct
    MOVE.B      (A0),D1                 ; Addr Reg Indirect
    MOVE.B      (A0)+,D1                ; Addr Reg Indirect with Post increment
    MOVE.B      -(A0),D1                ; Addr Reg Indirect with Pre decrement
    MOVE.B      $AAAA,D0                ; Absolute Word Address
    MOVE.B      $AAAAAAAA,D0            ; Absolute Long Address
    MOVE.B      #$DD,D1                 ; Immediate Data

    *WORD*
    MOVE.W      D0,D1                   ; Data Register Direct
    MOVE.W      A0,D1                   ; Addr Reg Direct
    MOVE.W      (A0),D1                 ; Addr Reg Indirect
    MOVE.W      (A0)+,D1                ; Addr Reg Indirect with Post increment
    MOVE.W      -(A0),D1                ; Addr Reg Indirect with Pre decrement
    MOVE.W      $AAAA,D0                ; Absolute Word Address
    MOVE.W      $AAAAAAAA,D0            ; Absolute Long Address
    MOVE.W      #$DDDD,D1               ; Immediate Data

    *LONG*
    MOVE.L      D0,D1                   ; Data Register Direct
    MOVE.L      A0,D1                   ; Addr Reg Direct
    MOVE.L      (A0),D1                 ; Addr Reg Indirect
    MOVE.L      (A0)+,D1                ; Addr Reg Indirect with Post increment
    MOVE.L      -(A0),D1                ; Addr Reg Indirect with Pre decrement
    MOVE.L      $AAAA,D0                ; Absolute Word Address
    MOVE.L      $AAAAAAAA,D0            ; Absolute Long Address
    MOVE.L      #$DDDDDDDD,D1           ; Immediate Data

*******************************************************************************
*   MOVEA       <ea>,An                 ; Size = (Word, Long)
*******************************************************************************

    *WORD*                              **SOURCE <ea>**
    MOVEA.W     D0,A1                   ; Data Register Direct
    MOVEA.W     A0,A1                   ; Addr Reg Direct
    MOVEA.W     (A0),A1                 ; Addr Reg Indirect
    MOVEA.W     (A0)+,A1                ; Addr Reg Indirect with Post increment
    MOVEA.W     -(A0),A1                ; Addr Reg Indirect with Pre decrement
    MOVEA.W     $AAAA,A1                ; Absolute Word Address
    MOVEA.W     $AAAAAAAA,A1            ; Absolute Long Address
    MOVEA.W     #$DDDD,A1               ; Immediate Data

    *LONG*
    MOVEA.L     D0,A1                   ; Data Register Direct
    MOVEA.L     A0,A1                   ; Addr Reg Direct
    MOVEA.L     (A0),A1                 ; Addr Reg Indirect
    MOVEA.L     (A0)+,A1                ; Addr Reg Indirect with Post increment
    MOVEA.L     -(A0),A1                ; Addr Reg Indirect with Pre decrement
    MOVEA.L     $AAAA,A1                ; Absolute Word Address
    MOVEA.L     $AAAAAAAA,A1            ; Absolute Long Address
    MOVEA.L     #$DDDDDDDD,A1           ; Immediate Data

*******************************************************************************
*   ADDA        <ea>,An                 ; Size = (Word, Long)
*******************************************************************************

    *WORD*                              **SOURCE <ea>**
    ADDA.W      D0,A1                   ; Data Register Direct
    ADDA.W      A0,A1                   ; Addr Reg Direct
    ADDA.W      (A0),A1                 ; Addr Reg Indirect
    ADDA.W      (A0)+,A1                ; Addr Reg Indirect with Post increment
    ADDA.W      -(A0),A1                ; Addr Reg Indirect with Pre decrement
    ADDA.W      $AAAA,A1                ; Absolute Word Address
    ADDA.W      $AAAAAAAA,A1            ; Absolute Long Address
    ADDA.W      #$DDDD,A1               ; Immediate Data

    *LONG*
    ADDA.L      D0,A1                   ; Data Register Direct
    ADDA.L      A0,A1                   ; Addr Reg Direct
    ADDA.L      (A0),A1                 ; Addr Reg Indirect
    ADDA.L      (A0)+,A1                ; Addr Reg Indirect with Post increment
    ADDA.L      -(A0),A1                ; Addr Reg Indirect with Pre decrement
    ADDA.L      $AAAA,A1                ; Absolute Word Address
    ADDA.L      $AAAAAAAA,A1            ; Absolute Long Address
    ADDA.L      #$DDDD,A1               ; Immediate Data

*******************************************************************************
*   ADDI        #<data>,<ea>            ; Size = (Byte, Word, Long)
*******************************************************************************

    *BYTE*                              **DESTINATION <ea>**
    ADDI.B      #$DD,D1                 ; Data Register Direct
    ADDI.B      #$DD,(A1)               ; Addr Reg Indirect
    ADDI.B      #$DD,(A1)+              ; Addr Reg Indirect with Post increment
    ADDI.B      #$DD,-(A1)              ; Addr Reg Indirect with Pre decrement
    ADDI.B      #$DD,$AAAA              ; Absolute Word Address
    ADDI.B      #$DD,$AAAAAAAA          ; Absolute Long Address

    *WORD*
    ADDI.W      #$DDDD,D1               ; Data Register Direct
    ADDI.W      #$DDDD,(A1)             ; Addr Reg Indirect
    ADDI.W      #$DDDD,(A1)+            ; Addr Reg Indirect with Post increment
    ADDI.W      #$DDDD,-(A1)            ; Addr Reg Indirect with Pre decrement
    ADDI.W      #$DDDD,$AAAA            ; Absolute Word Address
    ADDI.W      #$DDDD,$AAAAAAAA        ; Absolute Long Address

    *LONG*
    ADDI.L      #$DDDDDDDD,D1           ; Data Register Direct
    ADDI.L      #$DDDDDDDD,(A1)         ; Addr Reg Indirect
    ADDI.L      #$DDDDDDDD,(A1)+        ; Addr Reg Indirect with Post increment
    ADDI.L      #$DDDDDDDD,-(A1)        ; Addr Reg Indirect with Pre decrement
    ADDI.L      #$DDDDDDDD,$AAAA        ; Absolute Word Address
    ADDI.L      #$DDDDDDDD,$AAAAAAAA    ; Absolute Long Address

*******************************************************************************
*   ADDQ        #<data>,<ea>            ; Size = (Byte, Word, Long)
*******************************************************************************
    
    *BYTE*                              **DESTINATION <ea>**
    ADDQ.B      #8,D1                   ; Data Register Direct
    ADDQ.B      #8,(A1)                 ; Addr Reg Indirect
    ADDQ.B      #8,(A1)+                ; Addr Reg Indirect with Post increment
    ADDQ.B      #8,-(A1)                ; Addr Reg Indirect with Pre decrement
    ADDQ.B      #8,$AAAA                ; Absolute Word Address
    ADDQ.B      #8,$AAAAAAAA            ; Absolute Long Address

    *WORD*
    ADDQ.W      #8,D1                   ; Data Register Direct
    ADDQ.W      #8,A1                   ; Addr Reg Direct
    ADDQ.W      #8,(A1)                 ; Addr Reg Indirect
    ADDQ.W      #8,(A1)+                ; Addr Reg Indirect with Post increment
    ADDQ.W      #8,-(A1)                ; Addr Reg Indirect with Pre decrement
    ADDQ.W      #8,$AAAA                ; Absolute Word Address
    ADDQ.W      #8,$AAAAAAAA            ; Absolute Long Address

    *LONG*
    ADDQ.L      #8,D1                   ; Data Register Direct
    ADDQ.L      #8,A1                   ; Addr Reg Direct
    ADDQ.L      #8,(A1)                 ; Addr Reg Indirect
    ADDQ.L      #8,(A1)+                ; Addr Reg Indirect with Post increment
    ADDQ.L      #8,-(A1)                ; Addr Reg Indirect with Pre decrement
    ADDQ.L      #8,$AAAA                ; Absolute Word Address
    ADDQ.L      #8,$AAAAAAAA            ; Absolute Long Addres

*******************************************************************************
*   SUBA        <ea>,An                 ; Size = (Word, Long)
*******************************************************************************
    
    *WORD*                              **SOURCE <ea>**
    SUBA.W      D0,A1                   ; Data Register Direct
    SUBA.W      A0,A1                   ; Addr Reg Direct
    SUBA.W      (A0),A1                 ; Addr Reg Indirect
    SUBA.W      (A0)+,A1                ; Addr Reg Indirect with Post increment
    SUBA.W      -(A0),A1                ; Addr Reg Indirect with Pre decrement
    SUBA.W      $AAAA,A1                ; Absolute Word Address
    SUBA.W      $AAAAAAAA,A1            ; Absolute Long Address
    SUBA.W      #$DDDD,A1               ; Immediate Data

    *LONG*
    SUBA.L      D0,A1                   ; Data Register Direct
    SUBA.L      A0,A1                   ; Addr Reg Direct
    SUBA.L      (A0),A1                 ; Addr Reg Indirect
    SUBA.L      (A0)+,A1                ; Addr Reg Indirect with Post increment
    SUBA.L      -(A0),A1                ; Addr Reg Indirect with Pre decrement
    SUBA.L      $AAAA,A1                ; Absolute Word Address
    SUBA.L      $AAAAAAAA,A1            ; Absolute Long Address
    SUBA.L      #$DDDDDDDD,A1           ; Immediate Data

*******************************************************************************
*   SUBI        #<data>,<ea>            ; Size = (Byte, Word, Long)
*******************************************************************************

    *BYTE*                              **DESTINATION <ea>**
    SUBI.B      #$DD,D1                 ; Data Register Direct
    SUBI.B      #$DD,(A1)               ; Addr Reg Indirect
    SUBI.B      #$DD,(A1)+              ; Addr Reg Indirect with Post increment
    SUBI.B      #$DD,-(A1)              ; Addr Reg Indirect with Pre decrement
    SUBI.B      #$DD,$AAAA              ; Absolute Word Address
    SUBI.B      #$DD,$AAAAAAAA          ; Absolute Long Address

    *WORD*
    SUBI.W      #$DDDD,D1               ; Data Register Direct
    SUBI.W      #$DDDD,(A1)             ; Addr Reg Indirect
    SUBI.W      #$DDDD,(A1)+            ; Addr Reg Indirect with Post increment
    SUBI.W      #$DDDD,-(A1)            ; Addr Reg Indirect with Pre decrement
    SUBI.W      #$DDDD,$AAAA            ; Absolute Word Address
    SUBI.W      #$DDDD,$AAAAAAAA        ; Absolute Long Address

    *LONG*
    SUBI.L      #$DDDDDDDD,D1           ; Data Register Direct
    SUBI.L      #$DDDDDDDD,(A1)         ; Addr Reg Indirect
    SUBI.L      #$DDDDDDDD,(A1)+        ; Addr Reg Indirect with Post increment
    SUBI.L      #$DDDDDDDD,-(A1)        ; Addr Reg Indirect with Pre decrement
    SUBI.L      #$DDDDDDDD,$AAAA        ; Absolute Word Address
    SUBI.L      #$DDDDDDDD,$AAAAAAAA    ; Absolute Long Address

*******************************************************************************
*   AND         <ea>,Dn                 ; Size = (Byte, Word, Long)
*******************************************************************************

    *BYTE*                              **SOURCE <ea>**
    AND.B       D0,D1                   ; Data Register Direct
    AND.B       (A0),D1                 ; Addr Reg Indirect
    AND.B       (A0)+,D1                ; Addr Reg Indirect with Post increment
    AND.B       -(A0),D1                ; Addr Reg Indirect with Pre decrement
    AND.B       $AAAA,D1                ; Absolute Word Address
    AND.B       $AAAAAAAA,D1            ; Absolute Long Address
    AND.B       #$DD,D1                 ; Immediate Data

    *WORD*
    AND.W       D0,D1                   ; Data Register Direct
    AND.W       (A0),D1                 ; Addr Reg Indirect
    AND.W       (A0)+,D1                ; Addr Reg Indirect with Post increment
    AND.W       -(A0),D1                ; Addr Reg Indirect with Pre decrement
    AND.W       $AAAA,D1                ; Absolute Word Address
    AND.W       $AAAAAAAA,D1            ; Absolute Long Address
    AND.W       #$DD,D1                 ; Immediate Data

    *LONG*
    AND.L       D0,D1                   ; Data Register Direct
    AND.L       (A0),D1                 ; Addr Reg Indirect
    AND.L       (A0)+,D1                ; Addr Reg Indirect with Post increment
    AND.L       -(A0),D1                ; Addr Reg Indirect with Pre decrement
    AND.L       $AAAA,D1                ; Absolute Word Address
    AND.L       $AAAAAAAA,D1            ; Absolute Long Address
    AND.L       #$DD,D1                 ; Immediate Data

*******************************************************************************
*   AND         Dn,<ea>                 ; Size = (Byte, Word, Long)
*******************************************************************************

    *BYTE*                              **DESTINATION <ea>**
    AND.B       D0,(A1)                 ; Addr Reg Indirect
    AND.B       D0,(A1)+                ; Addr Reg Indirect with Post increment
    AND.B       D0,-(A1)                ; Addr Reg Indirect with Pre decrement
    AND.B       D0,$AAAA                ; Absolute Word Address
    AND.B       D0,$AAAAAAAA            ; Absolute Long Address

    *WORD*
    AND.W       D0,(A1)                 ; Addr Reg Indirect
    AND.W       D0,(A1)+                ; Addr Reg Indirect with Post increment
    AND.W       D0,-(A1)                ; Addr Reg Indirect with Pre decrement
    AND.W       D0,$AAAA                ; Absolute Word Address
    AND.W       D0,$AAAAAAAA            ; Absolute Long Address

    *LONG*
    AND.L       D0,(A1)                 ; Addr Reg Indirect
    AND.L       D0,(A1)+                ; Addr Reg Indirect with Post increment
    AND.L       D0,-(A1)                ; Addr Reg Indirect with Pre decrement
    AND.L       D0,$AAAA                ; Absolute Word Address
    AND.L       D0,$AAAAAAAA            ; Absolute Long Address

*******************************************************************************
*   ANDI        #<data>,<ea>            ; Size = (Byte, Word, Long)
*******************************************************************************

    *BYTE*                              **DESTINATION <ea>**
    ANDI.B      #$DD,D1                 ; Data Register Direct
    ANDI.B      #$DD,(A1)               ; Addr Reg Indirect
    ANDI.B      #$DD,(A1)+              ; Addr Reg Indirect with Post increment
    ANDI.B      #$DD,-(A1)              ; Addr Reg Indirect with Pre decrement
    ANDI.B      #$DD,$AAAA              ; Absolute Word Address
    ANDI.B      #$DD,$AAAAAAAA          ; Absolute Long Address

    *WORD*
    ANDI.W      #$DDDD,D1               ; Data Register Direct
    ANDI.W      #$DDDD,(A1)             ; Addr Reg Indirect
    ANDI.W      #$DDDD,(A1)+            ; Addr Reg Indirect with Post increment
    ANDI.W      #$DDDD,-(A1)            ; Addr Reg Indirect with Pre decrement
    ANDI.W      #$DDDD,$AAAA            ; Absolute Word Address
    ANDI.W      #$DDDD,$AAAAAAAA        ; Absolute Long Address

    *LONG*
    ANDI.L      #$DDDDDDDD,D1           ; Data Register Direct
    ANDI.L      #$DDDDDDDD,(A1)         ; Addr Reg Indirect
    ANDI.L      #$DDDDDDDD,(A1)+        ; Addr Reg Indirect with Post increment
    ANDI.L      #$DDDDDDDD,-(A1)        ; Addr Reg Indirect with Pre decrement
    ANDI.L      #$DDDDDDDD,$AAAA        ; Absolute Word Address
    ANDI.L      #$DDDDDDDD,$AAAAAAAA    ; Absolute Long Address

*******************************************************************************
*   OR          <ea>,Dn                 ; Size = (Byte, Word, Long)
*******************************************************************************

    *BYTE*                              **SOURCE <ea>**
    OR.B        D0,D1                   ; Data Register Direct
    OR.B        (A0),D1                 ; Addr Reg Indirect
    OR.B        (A0)+,D1                ; Addr Reg Indirect with Post increment
    OR.B        -(A0),D1                ; Addr Reg Indirect with Pre decrement
    OR.B        $AAAA,D1                ; Absolute Word Address
    OR.B        $AAAAAAAA,D1            ; Absolute Long Address
    OR.B        #$DD,D1                 ; Immediate Data

    *WORD*
    OR.W        D0,D1                   ; Data Register Direct
    OR.W        (A0),D1                 ; Addr Reg Indirect
    OR.W        (A0)+,D1                ; Addr Reg Indirect with Post increment
    OR.W        -(A0),D1                ; Addr Reg Indirect with Pre decrement
    OR.W        $AAAA,D1                ; Absolute Word Address
    OR.W        $AAAAAAAA,D1            ; Absolute Long Address
    OR.W        #$DD,D1                 ; Immediate Data

    *LONG*
    OR.L        D0,D1                   ; Data Register Direct
    OR.L        (A0),D1                 ; Addr Reg Indirect
    OR.L        (A0)+,D1                ; Addr Reg Indirect with Post increment
    OR.L        -(A0),D1                ; Addr Reg Indirect with Pre decrement
    OR.L        $AAAA,D1                ; Absolute Word Address
    OR.L        $AAAAAAAA,D1            ; Absolute Long Address
    OR.L        #$DD,D1                 ; Immediate Data


*******************************************************************************
*   OR           Dn,<ea>                ; Size = (Byte, Word, Long)
*******************************************************************************

    *BYTE*                              **DESTINATION <ea>**
    OR.B         D0,(A1)                ; Addr Reg Indirect
    OR.B         D0,(A1)+               ; Addr Reg Indirect with Post increment
    OR.B         D0,-(A1)               ; Addr Reg Indirect with Pre decrement
    OR.B         D0,$AAAA               ; Absolute Word Address
    OR.B         D0,$AAAAAAAA           ; Absolute Long Address

    *WORD*
    OR.W         D0,(A1)                ; Addr Reg Indirect
    OR.W         D0,(A1)+               ; Addr Reg Indirect with Post increment
    OR.W         D0,-(A1)               ; Addr Reg Indirect with Pre decrement
    OR.W         D0,$AAAA               ; Absolute Word Address
    OR.W         D0,$AAAAAAAA           ; Absolute Long Address

    *LONG*
    OR.L         D0,(A1)                ; Addr Reg Indirect
    OR.L         D0,(A1)+               ; Addr Reg Indirect with Post increment
    OR.L         D0,-(A1)               ; Addr Reg Indirect with Pre decrement
    OR.L         D0,$AAAA               ; Absolute Word Address
    OR.L         D0,$AAAAAAAA           ; Absolute Long Address


*******************************************************************************
*   ORI         #<data>,<ea>            ; Size = (Byte, Word, Long)
*******************************************************************************

    *BYTE*                              **DESTINATION <ea>**
    ORI.B       #$DD,D1                 ; Data Register Direct
    ORI.B       #$DD,(A1)               ; Addr Reg Indirect
    ORI.B       #$DD,(A1)+              ; Addr Reg Indirect with Post increment
    ORI.B       #$DD,-(A1)              ; Addr Reg Indirect with Pre decrement
    ORI.B       #$DD,$AAAA              ; Absolute Word Address
    ORI.B       #$DD,$AAAAAAAA          ; Absolute Long Address

    *WORD*
    ORI.W       #$DDDD,D1               ; Data Register Direct
    ORI.W       #$DDDD,(A1)             ; Addr Reg Indirect
    ORI.W       #$DDDD,(A1)+            ; Addr Reg Indirect with Post increment
    ORI.W       #$DDDD,-(A1)            ; Addr Reg Indirect with Pre decrement
    ORI.W       #$DDDD,$AAAA            ; Absolute Word Address
    ORI.W       #$DDDD,$AAAAAAAA        ; Absolute Long Address

    *LONG*
    ORI.L       #$DDDDDDDD,D1           ; Data Register Direct
    ORI.L       #$DDDDDDDD,(A1)         ; Addr Reg Indirect
    ORI.L       #$DDDDDDDD,(A1)+        ; Addr Reg Indirect with Post increment
    ORI.L       #$DDDDDDDD,-(A1)        ; Addr Reg Indirect with Pre decrement
    ORI.L       #$DDDDDDDD,$AAAA        ; Absolute Word Address
    ORI.L       #$DDDDDDDD,$AAAAAAAA    ; Absolute Long Address

*******************************************************************************
*   EOR        Dn,<ea>                  ; Size = (Byte, Word, Long)
*******************************************************************************

    *BYTE*                              **DESTINATION <ea>**
    EOR.B      D0,D1                    ; Data Register Direct
    EOR.B      D0,(A1)                  ; Addr Reg Indirect
    EOR.B      D0,(A1)+                 ; Addr Reg Indirect with Post increment
    EOR.B      D0,-(A1)                 ; Addr Reg Indirect with Pre decrement
    EOR.B      D0,$AAAA                 ; Absolute Word Address
    EOR.B      D0,$AAAAAAAA             ; Absolute Long Address
    
    *WORD*
    EOR.W      D0,D1                    ; Data Register Direct
    EOR.W      D0,(A1)                  ; Addr Reg Indirect
    EOR.W      D0,(A1)+                 ; Addr Reg Indirect with Post increment
    EOR.W      D0,-(A1)                 ; Addr Reg Indirect with Pre decrement
    EOR.W      D0,$AAAA                 ; Absolute Word Address
    EOR.W      D0,$AAAAAAAA             ; Absolute Long Address

    *LONG*
    EOR.L      D0,D1                    ; Data Register Direct
    EOR.L      D0,(A1)                  ; Addr Reg Indirect
    EOR.L      D0,(A1)+                 ; Addr Reg Indirect with Post increment
    EOR.L      D0,-(A1)                 ; Addr Reg Indirect with Pre decrement
    EOR.L      D0,$AAAA                 ; Absolute Word Address
    EOR.L      D0,$AAAAAAAA             ; Absolute Long Address

*******************************************************************************
*   EORI        #<data>,<ea>            ; Size = (Byte, Word, Long)
*******************************************************************************

    *BYTE*                              **DESTINATION <ea>**
    EORI.B      #$DD,D1                 ; Data Register Direct
    EORI.B      #$DD,(A1)               ; Addr Reg Indirect
    EORI.B      #$DD,(A1)+              ; Addr Reg Indirect with Post increment
    EORI.B      #$DD,-(A1)              ; Addr Reg Indirect with Pre decrement
    EORI.B      #$DD,$AAAA              ; Absolute Word Address
    EORI.B      #$DD,$AAAAAAAA          ; Absolute Long Address

    *WORD*
    EORI.W      #$DDDD,D1               ; Data Register Direct
    EORI.W      #$DDDD,(A1)             ; Addr Reg Indirect
    EORI.W      #$DDDD,(A1)+            ; Addr Reg Indirect with Post increment
    EORI.W      #$DDDD,-(A1)            ; Addr Reg Indirect with Pre decrement
    EORI.W      #$DDDD,$AAAA            ; Absolute Word Address
    EORI.W      #$DDDD,$AAAAAAAA        ; Absolute Long Address

    *LONG*
    EORI.L      #$DDDDDDDD,D1           ; Data Register Direct
    EORI.L      #$DDDDDDDD,(A1)         ; Addr Reg Indirect
    EORI.L      #$DDDDDDDD,(A1)+        ; Addr Reg Indirect with Post increment
    EORI.L      #$DDDDDDDD,-(A1)        ; Addr Reg Indirect with Pre decrement
    EORI.L      #$DDDDDDDD,$AAAA        ; Absolute Word Address
    EORI.L      #$DDDDDDDD,$AAAAAAAA    ; Absolute Long Address

*******************************************************************************
*   ASd where d is direction, L or R
*******************************************************************************

*******************************************************************************
*   ASL         Dx,Dy                   ; Size = (Byte, Word, Long)
*   ASL         #<data>,Dy
*   ASL         <ea>
*******************************************************************************
    
    *BYTE*                              **DESTINATION <ea>**
    ASL.B       D0,D1

    *WORD*
    ASL.W       D0,D1
    ASL.W       #1,D1
    ASL.W       (A1)                    ; Addr Reg Indirect
    ASL.W       (A1)+                   ; Addr Reg Indirect with Post increment
    ASL.W       -(A1)                   ; Addr Reg Indirect with Pre decrement
    ASL.W       $AAAA                   ; Absolute Word Address
    ASL.W       $AAAAAAAA               ; Absolute Long Address

    *LONG*
    ASL.L       D0,D1

*******************************************************************************
*   ASR         Dx,Dy                   ; Size = (Byte, Word, Long)
*   ASR         #<data>,Dy
*   ASR         <ea>
*******************************************************************************

    *BYTE*                              **DESTINATION <ea>**
    ASR.B       D0,D1

    *WORD*
    ASR.W       D0,D1
    ASR.W       #1,D1
    ASR.W       (A1)                    ; Addr Reg Indirect
    ASR.W       (A1)+                   ; Addr Reg Indirect with Post increment
    ASR.W       -(A1)                   ; Addr Reg Indirect with Pre decrement
    ASR.W       $AAAA                   ; Absolute Word Address
    ASR.W       $AAAAAAAA               ; Absolute Long Address

    *LONG*
    ASR.L       D0,D1

*******************************************************************************
*   ROd where d is direction, L or R         
*******************************************************************************

*******************************************************************************
*   ROL         Dx,Dy                   ; Size = (Byte, Word, Long)
*   ROL         #<data>,Dy
*   ROL         <ea>
*******************************************************************************

    *BYTE*                              **DESTINATION <ea>**
    ROL.B       D0,D1

    *WORD*
    ROL.W       D0,D1
    ROL.W       #1,D1
    ROL.W       (A1)                    ; Addr Reg Indirect
    ROL.W       (A1)+                   ; Addr Reg Indirect with Post increment
    ROL.W       -(A1)                   ; Addr Reg Indirect with Pre decrement
    ROL.W       $AAAA                   ; Absolute Word Address
    ROL.W       $AAAAAAAA               ; Absolute Long Address

    *LONG*
    ROL.L       D0,D1

*******************************************************************************
*   ROR         Dx,Dy                   ; Size = (Byte, Word, Long)
*   ROR         #<data>,Dy
*   ROR         <ea>
*******************************************************************************

    *BYTE*                              **DESTINATION <ea>**
    ROR.B       D0,D1

    *WORD*
    ROR.W       D0,D1
    ROR.W       #1,D1
    ROR.W       (A1)                    ; Addr Reg Indirect
    ROR.W       (A1)+                   ; Addr Reg Indirect with Post increment
    ROR.W       -(A1)                   ; Addr Reg Indirect with Pre decrement
    ROR.W       $AAAA                   ; Absolute Word Address
    ROR.W       $AAAAAAAA               ; Absolute Long Address

    *LONG*
    ROR.L       D0,D1

*******************************************************************************
*   CMP         <ea>,Dn                 ; Size = (Byte, Word, Long)
*******************************************************************************

    *BYTE*                              **SOURCE <ea>**
    CMP.B       D0,D1                   ; Data Register Direct
    CMP.B       (A0),D1                 ; Addr Reg Indirect
    CMP.B       (A0)+,D1                ; Addr Reg Indirect with Post increment
    CMP.B       -(A0),D1                ; Addr Reg Indirect with Pre decrement
    CMP.B       $AAAA,D1                ; Absolute Word Address
    CMP.B       $AAAAAAAA,D1            ; Absolute Long Address
    CMP.B       #$DD,D1                 ; Immediate Data

    *WORD*
    CMP.W       D0,D1                   ; Data Register Direct
    CMP.W       A0,D1                   ; Addr Reg Direct
    CMP.W       (A0),D1                 ; Addr Reg Indirect
    CMP.W       (A0)+,D1                ; Addr Reg Indirect with Post increment
    CMP.W       -(A0),D1                ; Addr Reg Indirect with Pre decrement
    CMP.W       $AAAA,D1                ; Absolute Word Address
    CMP.W       $AAAAAAAA,D1            ; Absolute Long Address
    CMP.W       #$DD,D1                 ; Immediate Data

    *LONG*
    CMP.L       D0,D1                   ; Data Register Direct
    CMP.L       A0,D1                   ; Addr Reg Direct
    CMP.L       (A0),D1                 ; Addr Reg Indirect
    CMP.L       (A0)+,D1                ; Addr Reg Indirect with Post increment
    CMP.L       -(A0),D1                ; Addr Reg Indirect with Pre decrement
    CMP.L       $AAAA,D1                ; Absolute Word Address
    CMP.L       $AAAAAAAA,D1            ; Absolute Long Address
    CMP.L       #$DD,D1                 ; Immediate Data

*******************************************************************************
*   CMPA        <ea>,An                 ; Size = (Word, Long)
*******************************************************************************


    *WORD*                              **SOURCE <ea>**
    CMPA.W       D0,A1                  ; Data Register Direct
    CMPA.W       A0,A1                  ; Addr Reg Direct
    CMPA.W       (A0),A1                ; Addr Reg Indirect
    CMPA.W       (A0)+,A1               ; Addr Reg Indirect with Post increment
    CMPA.W       -(A0),A1               ; Addr Reg Indirect with Pre decrement
    CMPA.W       $AAAA,A1               ; Absolute Word Address
    CMPA.W       $AAAAAAAA,A1           ; Absolute Long Address
    CMPA.W       #$DD,A1                ; Immediate Data

    *LONG*
    CMPA.L       D0,A1                  ; Data Register Direct
    CMPA.L       A0,A1                  ; Addr Reg Direct
    CMPA.L       (A0),A1                ; Addr Reg Indirect
    CMPA.L       (A0)+,A1               ; Addr Reg Indirect with Post increment
    CMPA.L       -(A0),A1               ; Addr Reg Indirect with Pre decrement
    CMPA.L       $AAAA,A1               ; Absolute Word Address
    CMPA.L       $AAAAAAAA,A1           ; Absolute Long Address
    CMPA.L       #$DD,A1                ; Immediate Data

*******************************************************************************
*   CMPI        #<data>,<ea>            ; Size = (Byte, Word, Long)
*******************************************************************************

    *BYTE*                              **DESTINATION <ea>**
    CMPI.B      #$DD,D1                 ; Data Register Direct
    CMPI.B      #$DD,(A1)               ; Addr Reg Indirect
    CMPI.B      #$DD,(A1)+              ; Addr Reg Indirect with Post increment
    CMPI.B      #$DD,-(A1)              ; Addr Reg Indirect with Pre decrement
    CMPI.B      #$DD,$AAAA              ; Absolute Word Address
    CMPI.B      #$DD,$AAAAAAAA          ; Absolute Long Address

    *WORD*
    CMPI.W      #$DDDD,D1               ; Data Register Direct
    CMPI.W      #$DDDD,(A1)             ; Addr Reg Indirect
    CMPI.W      #$DDDD,(A1)+            ; Addr Reg Indirect with Post increment
    CMPI.W      #$DDDD,-(A1)            ; Addr Reg Indirect with Pre decrement
    CMPI.W      #$DDDD,$AAAA            ; Absolute Word Address
    CMPI.W      #$DDDD,$AAAAAAAA        ; Absolute Long Address

    *LONG*
    CMPI.L      #$DDDDDDDD,D1           ; Data Register Direct
    CMPI.L      #$DDDDDDDD,(A1)         ; Addr Reg Indirect
    CMPI.L      #$DDDDDDDD,(A1)+        ; Addr Reg Indirect with Post increment
    CMPI.L      #$DDDDDDDD,-(A1)        ; Addr Reg Indirect with Pre decrement
    CMPI.L      #$DDDDDDDD,$AAAA        ; Absolute Word Address
    CMPI.L      #$DDDDDDDD,$AAAAAAAA    ; Absolute Long Address

*******************************************************************************
*   Bcc         <label>                 ; Size = (Byte, Word, Long*)
*******************************************************************************

    BCC         carry_clear
    BCS         carry_set
    BEQ         equal
    BGE         greater_or_equal
    BGT         greater_than
    BHI         high
    BLE         less_or_equal
    BLS         low_or_same
    BLT         less_than
    BMI         minus
    BNE         not_equal
    BPL         plus
    BVC         overflow_clear
    BVS         overflow_set

*******************************************************************************
*                       End Test Disassemble Routines
*******************************************************************************
carry_clear
carry_set
equal
greater_or_equal
greater_than
high
less_or_equal
low_or_same
less_than
minus
not_equal
plus
overflow_clear
overflow_set

            END         start


*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
