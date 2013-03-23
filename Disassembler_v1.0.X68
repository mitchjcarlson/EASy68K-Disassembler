*-----------------------------------------------------------
* Title      : Team SaB Disassembler
* Written by : Kyle Rindahl & Mitch Carlson
* Date       : Feb. 22, 2013
* Description: Disassembler v1.0
*-----------------------------------------------------------
*******************************************************************************
*/////////////////////////////////////////////////////////////////////////////*
*                           Universal Project Notes                           *
*\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\*
*******************************************************************************
*
* A4: Address pointer for disassemble
* A6: used by op-code and EA routine for buffer pointer
* A7: Stack pointer for saving and maintaining registers
* D6: Good/bad flag
*
*******************************************************************************
*/////////////////////////////////////////////////////////////////////////////*
*                                 MAIN PROGRAM                                *
*\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\*
*******************************************************************************

            OPT     CRE                ;Bring in the Symbol Table
            ORG     $1000
START                                   ;first instruction of program
			LEA     stack,SP           ;Stack pointer in A7
            BSR     GREETING
            BSR     CONTROL            ;start process to ocr
            BSR     ADDR_LOOP
            BRA     START

*******************************************************************************
*/////////////////////////////////////////////////////////////////////////////*
*                                  I/O Routine                                *
*\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\*
*******************************************************************************

strtAddr    EQU     $00002000           ;Starting Address for user input program
endAddr     EQU     $000FFFFF           ;Ending Address - upper bound of input program
badStart    EQU     $000FFFFE           ;Invalid starting Address if GTE 000FFFFE
dollar      EQU     $24                 ;ASCII $
LF          EQU     $0A                 ;ASCII value for Line feed
CR          EQU     $0D                 ;ASCII value for Carriage return
space       EQU     $20                 ;ASCII value for space
comma       EQU     $2C                 ;ASCII value for comma
task0       EQU     00                  ;Task0 from Berger, print string w/ newline
task1       EQU     01                  ;Task1 from Berger, prompt for input w/o newline
task2       EQU     02                  ;Task2 from Berger, prompt and wait for input
start       EQU     $1000               ;Starting address of program
addrLen     EQU     08                  ;Address Length = 8 bytes
wordLen     EQU     04                  ;Word Length = 4 bytes
stack       EQU     $00100000           ;Default Location of Stack
evenAnd     EQU     $00000001           ;EvenCk subroutine check if a number is even
D           EQU     $44                 ;ASCII value for D
A           EQU     $41                 ;ASCII value for A
T           EQU     $54                 ;ASCII value for T
upN         EQU     $4E                 ;ASCII value for N for User Prompt
lwn         EQU     $6E                 ;ASCII value for n for User Prompt
upY         EQU     $59                 ;ASCII value for Y for User Prompt
lwY         EQU     $79                 ;ASCII value for y for User Prompt
outCt       EQU     25                  ;Will show 25 lines on each screen, can adjust
region      EQU     80                  ;decimal number 80 to help fill




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
procStart   JSR         clr_regs        ;Clear out data from Registers
            MOVE.B	    #task1,D0		;D0 holds input from user
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
procEnd		MOVE.B      #0,D6           ;Clear Bad Flag
            MOVE.B		#task1,D0		;D0 holds task1, print wo CR
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
            RTS

CONTROL
            ; io branches here after validating addresses
            LEA         start_hex,A4    ;load addr of ptr to addr reg A4
            LEA         end_hex,A5      ;load ending address to A5
            MOVE.L      (A4),A4         ;move start address to ptr
            MOVE.L      (A5),D2         ;move end addr to reg
            MOVE.B		#task0,D0		;D0 holds task2, print w CR
			LEA			col_template,A1	;A1 holds error string
			MOVE.W		c_temp_len,D1   ;D1 holds length of start error string
			TRAP		#15				;Run
			MOVE.L      #1,D0           ;Set to force the buffer to clear
			BSR         clrBuf          ;clear the buffer
			MOVE.L      #$F,D5          ;Load for pagination simulation
            RTS
ADDR_LOOP
            CMPI.W      #$0,D5          ;Compare to page counter
            BEQ         PAGEFULL        ;Wait for user to continue printing
            LEA         end_hex,A5      ;load ending address to A5
            MOVE.L      (A5),D2
            CMPA.L      (A5),A4         ;compare mem ptr to end addr
            BGT         EXIT_IO         ;Move to print buffer
            BSR         OCR             ;Process next OP-Code
            BSR         prtBuf          ;Print value in buffer
            SUBI.B      #$1,D5          ;Decrement page counter
            BRA         ADDR_LOOP       ;Continue processing Address Range
PAGEFULL
            LEA         PAGE_BUFFER,A1  ;task2 puts null at A1
            MOVE.B		#task2,D0		;D0 holds task2, wait for user
			TRAP		#15				;Run
			MOVE.L      #$F,D5          ;Reload for pagination simulation
            NOP
			BRA         ADDR_LOOP
EXIT_IO
            RTS

PAGE_BUFFER     DS.W    10
*******************************************************************************
*                            I/O Subroutines
*******************************************************************************
*******************************************************************************
*printBuf - Prints value in buffer to Console
*******************************************************************************
prtBuf
            MOVEM.L     A0-A3/A5/D0-D5/D7,-(SP)
            LEA         validB,A0       ;Get Buffer Start
            ;LEA         validB_end,A2   ;Get End Buffer
            MOVEQ       #14,D0          ;display NULL terminated string at A1
prtLoop
            CMPI.W      #$FFFF,(A0)
            BEQ         exitBufPrt
            MOVE.W      (A0),A1         ;Store word to write-out register A1
            MOVE.W      #$FFFF,(A0)+    ;clear word in buffer
            ;MOVE.B      #4,D1           ;Length to print
            TRAP        #15             ;Print to console
            BRA         prtLoop
exitBufPrt
            MOVEM.L     (SP)+,A0-A3/A5/D0-D5/D7
            RTS
*******************************************************************************
*clrBuf - Fills buffer with blanks
*******************************************************************************
clrBuf      LEA         validB,A0       ;Get Buffer Start
            LEA         validB_end,A1   ;Get End of buffer
clrLoop     CMPA.L      A0,A1           ;Check if we're at end address of buffer
            BLT         exitBuf         ;End of buffer
            MOVE.L      #$FFFFFFFF,(A0)+ ;Write FFFF to buffer
            BRA         clrLoop
exitBuf		RTS							*return to subroutine

*******************************************************************************
*clear_regs - Clears Out Data/Addresss Registers
*******************************************************************************
clr_regs    CLR.L       D0              ;Clear out D0
            CLR.L       D1              ;Clear out D1
            CLR.L       D2              ;Clear out D2
            CLR.L       D3              ;Clear out D3
            CLR.L       D4              ;Clear out D4
            CLR.L       D5              ;Clear out D5
            CLR.L       D6              ;Clear out D6
            CLR.L       D7              ;Clear out D7
            RTS

*******************************************************************************
* conv_to_hex - Converts an ASCII string to a hex value
*******************************************************************************

conv_to_hex
    		MOVEM.L		D1/D2/D5,-(SP)	;Put utility register on stack
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
h_return	MOVEM.L		(SP)+,D1/D2/D5	;Pop register off stack
			RTS							;Return from subroutine

*******************************************************************************
* conv_to_ascii - takes Hex value, separates into individual Hex bytes
*******************************************************************************
conv_to_ascii
    		MOVEM.L		D3/D4/D5/D2,-(SP)	;Save D2 and A0
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
a_return
            MOVE.B      #$00,(A3)+      ; push NULL value to buffer
            MOVEM.L     (SP)+,D3/D4/D5/D2  ;Pop off stack
			RTS

*******************************************************************************
*send_addr_buf - Sends an Address Register to the Buffer
*******************************************************************************
send_addr_buf
			MOVEM.L		D0-D2/D5/A1-A3/A5,-(SP)	;Send Registers to Stack
			LEA			addr_regs,A1			;Load Address Registers
			ANDI.W		#$00FF,D0				;Mask Most Significant Bits
			MULU.W		#3,D0					;Calculate Offset
			LEA			(A1,D0.W),A1			;Get Index including Offset
			MOVE.W		A1,(A6)+
			MOVEM.L		(SP)+,D0-D2/D5/A1-A3/A5	;Restore Stack to Registers
			RTS									;Return

*******************************************************************************
*send_data_buf - Sends a Data Register to the Buffer
*******************************************************************************
send_data_buf
			MOVEM.L		D0-D2/D5/A1-A3/A5,-(SP)  ;Send Registers to Stack
			LEA			data_regs,A1    ;Load Data Registers
			ANDI.W		#$00FF,D0	    ;Mask Most Significant Bits
			MULU.W		#3,D0		    ;Calculate Offset
			LEA			(A1,D0.W),A1	;Get Index including Offset starting at D0
			MOVE.W		A1,(A6)+
done
			MOVEM.L		(SP)+,D0-D2/D5/A1-A3/A5  ;Restore Stack to Registers
			RTS			;Return

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
col_template        DC.B        CR,LF,'OP-CODE    OPERAND'
c_temp_len          DC.W        20              ;Length of Column Template

validB              DS.B        20              ;20 Bytes for valid buffer
validB_end                                      ;Used for address index
validB_len          EQU         20
invalidB            DS.B        20              ;80 Bytes for invalid buffer
invalidB_end                                    ;Used for address index
invalidB_len        EQU         20
temp                DS.B        30              ;30 bytes for instructions
carr_ret            DC.B        CR
carr_retLen         DC.B        1
linefeed            DC.B        LF
linefeedLen         DC.B        1
;addr_regs           DC.B    'A0','A1','A2','A3','A4','A5','A6','A7'
;data_regs           DC.B    'D0','D1','D2','D3','D4','D5','D6','D7'

ADDR_REGS
_A0                 DC.B        'A0',0
_A1                 DC.B        'A1',0
_A2                 DC.B        'A2',0
_A3                 DC.B        'A3',0
_A4                 DC.B        'A4',0
_A5                 DC.B        'A5',0
_A6                 DC.B        'A6',0
_A7                 DC.B        'A7',0

DATA_REGS
_D0                 DC.B        'D0',0
_D1                 DC.B        'D1',0
_D2                 DC.B        'D2',0
_D3                 DC.B        'D3',0
_D4                 DC.B        'D4',0
_D5                 DC.B        'D5',0
_D6                 DC.B        'D6',0
_D7                 DC.B        'D7',0

************************ IO Prompts and Messages*******************************
ascii_w              DS.W        10
ASCII_IMMEDIATE      DS.W        10
greet		DC.B	    CR,LF,'SaB Disassembler - CSS 422 Winter',CR,LF
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
ASCII_OPCODE_ADDRESS        DS.W        5

OCR ; subroutine called by I/O
            MOVEM.L     A0-A3/A5/D0-D7,-(SP)
            BSR         CLR_REGS   ; clear registers D0-D7, start fresh
            LEA         validB,A6  ; load pointer to good buffer into A6
            MOVE.W      (A4)+,D1   ; A4, universal ptr to next op-code mem addr

            LEA         ASCII_OPCODE_ADDRESS,A3
            MOVE.L      D1,D3               ;Back up to D3
            MOVEQ       #4,D4
            BSR         conv_to_ascii       ;Branch to convert to ASCII

            *Store Hex Address to Buffer
            MOVE.W      #ASCII_OPCODE_ADDRESS,(A6)+  ;Add to buffer
            MOVE.W      #TAB_SIGN,(A6)+     ; Insert tab to print buffer

                                   ; D1 holds original op-code word until
                                   ; routine is finished
            MOVEQ       #3,D0                   ; Iso-task 3: isolate d12-d15
            BSR         ISO_BITS

            ;LEA			LOCAL,A1
           	;MULU		#4,D2
            ;JMP			00(A1,D2)
;LOCAL;
            ;BRA         ORI_ANDI_SUBI_ADDI_EORI_CMPI ; ORI,ANDI,SUBI,EORI,CMPI
            ;BRA         MOVE_MOVEA              ; MOVE, MOVEA
            ;BRA         MOVE_MOVEA              ; MOVE, MOVEA
            ;BRA         MOVE_MOVEA              ; MOVE, MOVEA
            ;BRA         NEG_NOP_RTS_JSR_JMP     ; NEG, NOP, RTS, JSR, JMP
            ;BRA         ADDQ_                   ; ADDQ
            ;BRA         B_                      ; Bcc
            ;BRA         DATA                    ; value not recognized
            ;BRA         OR_                     ; OR
            ;BRA         SUBA_                   ; SUBA
            ;BRA         DATA                    ; value not recognized
            ;BRA         EOR_CMP_CMPA            ; EOR, CMP, CMPA
            ;BRA         AND_                    ; AND
            ;BRA         ADDA_                   ; ADDA
            ;BRA         ASd_ROd                 ; ASd, ROd
            ;BRA         DATA                    ; value not recognized

            CMP.B       #0,D2
            BEQ         ORI_ANDI_SUBI_ADDI_EORI_CMPI ; ORI,ANDI,SUBI,EORI,CMPI
            CMP.B       #3,D2
            BLE         MOVE_MOVEA              ; MOVE, MOVEA
            CMP.B       #4,D2
            BEQ         NEG_NOP_RTS_JSR_JMP     ; NEG, NOP, RTS, JSR, JMP
            CMP.B       #5,D2
            BEQ         ADDQ_                   ; ADDQ
            CMP.B       #6,D2
            BEQ         B_                      ; Bcc
            CMP.B       #8,D2
            BEQ         OR_                     ; OR
            CMP.B       #9,D2
            BEQ         SUBA_                   ; SUBA
            CMP.B       #11,D2
            BEQ         EOR_CMP_CMPA            ; EOR, CMP, CMPA
            CMP.B       #12,D2
            BEQ         AND_                    ; AND
            CMP.B       #13,D2
            BEQ         ADDA_                   ; ADDA
            CMP.B       #14,D2
            BEQ         ASd_ROd                 ; ASd, ROd
            BRA         DATA                    ; value not recognized
END_OCR
            ; end of routine, reload registers
            MOVE.W      #NEW_LINE,(A6)+         ; append to the end of every op
            MOVEM.L     (SP)+,A0-A3/A5/D0-D7
            RTS                                 ; return to I/O

************************ ORI, ANDI, SUBI, EORI, CMPI **************************
ORI_ANDI_SUBI_ADDI_EORI_CMPI
            MOVEQ       #2,D0                   ; Iso-task 2: isolate d9-d11
            BSR         ISO_BITS
                                                **Branches**
            CMP.B       #0,D2
            BEQ         ORI_                    ; ORI
            CMP.B       #1,D2
            BEQ         ANDI_                   ; ANDI
            CMP.B       #2,D2
            BEQ         SUBI_                   ; SUBI
            CMP.B       #3,D2
            BEQ         ADDI_                   ; ADDI
            CMP.B       #5,D2
            BEQ         EORI_                   ; EORI
            CMP.B       #6,D2
            BEQ         CMPI_                   ; CMPI
            BRA         DATA                    ; value not recognized

************************************* ORI *************************************
ORI_
            MOVE.W      #_ORI,(A6)+     ; push address of ORI to buffer
            MOVEQ       #1,D0           ; Iso-task 1: isolate bits d6-d7
            BSR         ISO_BITS
            BSR         BWL             ; append .B, .W, or .L
			BSR			IMMEDIATE_ADDR
            BRA         END_OCR

************************************ ANDI *************************************
ANDI_
            MOVE.W      #_ANDI,(A6)+        ; push address of ANDI to buffer
            MOVEQ       #1,D0               ; Iso-task 1: isolate bits d6-d7
            BSR         ISO_BITS
            BSR         BWL                 ; append .B, .W, or .L
			BSR			IMMEDIATE_ADDR
            BRA         END_OCR

************************************ SUBI *************************************
SUBI_
            MOVE.W      #_SUBI,(A6)+        ; push address of SUBI to buffer
            MOVEQ       #1,D0               ; Iso-task 1: isolate bits d6-d7
            BSR         ISO_BITS
            BSR         BWL                 ; append .B, .W, or .L
			BSR			IMMEDIATE_ADDR
            BRA         END_OCR

************************************ ADDI *************************************
ADDI_
            MOVE.W      #_ADDI,(A6)+        ; push address of ADDI to buffer
            MOVEQ       #1,D0               ; Iso-task 1: isolate bits d6-d7
            BSR         ISO_BITS
            BSR         BWL                 ; append .B, .W, or .L
			BSR			IMMEDIATE_ADDR
            BRA         END_OCR

************************************ EORI *************************************
EORI_
            MOVE.W      #_EORI,(A6)+        ; push address of EORI to buffer
            MOVEQ       #1,D0               ; Iso-task 1: isolate bits d6-d7
            BSR         ISO_BITS
            BSR         BWL                 ; append .B, .W, or .L
			BSR			IMMEDIATE_ADDR
            BRA         END_OCR

************************************ CMPI *************************************
CMPI_
            MOVE.W      #_CMPI,(A6)+        ; push address of CMPI to buffer
            MOVEQ       #1,D0               ; Iso-task 1: isolate bits d6-d7
            BSR         ISO_BITS
            BSR         BWL                 ; append .B, .W, or .L
			BSR			IMMEDIATE_ADDR
            BRA         END_OCR

******************************** MOVE, MOVEA **********************************
MOVE_MOVEA
            MOVEQ       #1,D0               ; Iso-task 1: isolate bits d6-d7
            BSR         ISO_BITS
            CMP.B       #1,D2
            BEQ         MOVEA_
            BRA         MOVE_

*********************************** MOVEA *************************************
MOVEA_
            MOVE.W      #_MOVEA,(A6)+        ; push address of MOVEA to buffer
            MOVEQ       #3,D0               ; Iso-task 3: isolate d12-d15
            BSR         ISO_BITS
            BSR         BLW                 ; append .B, .W, or .L
* Isolate bits d0-d5 and d6-d11, and send them to EA routine before return
            BSR         ISO_D0_TO_D5_FOR_EA     ; send source <ea> bits to EAR
            BSR         ISO_D6_TO_D11_FOR_EA    ; send dest <ea> bits to EAR
   			BSR 		EAR_decode			; call EA subroutine
            BRA         END_OCR

************************************ MOVE *************************************
MOVE_
            MOVE.W      #_MOVE,(A6)+        ; push address of MOVE to buffer
            MOVEQ       #3,D0               ; Iso-task 3: isolate d12-d15
            BSR         ISO_BITS
            BSR         BLW                 ; append .B, .W, or .L
* Isolate bits d0-d5 and d6-d11, and send them to EA routine before return
            BSR         ISO_D0_TO_D5_FOR_EA     ; send source <ea> bits to EAR
            BSR         ISO_D6_TO_D11_FOR_EA    ; send dest <ea> bits to EAR
   			BSR 		EAR_decode			; call EA subroutine
            BRA         END_OCR

************************** NEG, NOP, RTS, JSR, JMP ****************************
NEG_NOP_RTS_JSR_JMP
            MOVEQ       #2,D0               ; Iso-task 2: isolate d9-d11
            BSR         ISO_BITS
                                            **Branches**
            CMP.B       #2,D2
            BEQ         NEG_                ; NEG
            CMP.B       #7,D2
            BEQ         NOP_RTS_JSR_JMP     ; NOP, RTS, JSR, JMP
            BRA         DATA                ; value not recognized

************************************* NEG *************************************
NEG_
            MOVE.W      #_NEG,(A6)+         ; push address of NEG to buffer
            MOVEQ       #1,D0               ; Iso-task 1: isolate bits d6-d7
            BSR         ISO_BITS
            BSR         BWL                 ; append .B, .W, or .L
            BSR         ISO_D0_TO_D5_FOR_EA     ; send source <ea> bits to EAR
            BRA         END_OCR

***************************** NOP, RTS, JSR, JMP ******************************
NOP_RTS_JSR_JMP
            MOVEQ       #1,D0               ; Iso-task 1: isolate bits d6-d7
            BSR         ISO_BITS

            CMP.B       #1,D2
            BEQ         NOP_RTS             ; NOP, RTS
            CMP.B       #2,D2
            BEQ         JSR_                ; JSR
            CMP.B       #3,D2
            BEQ         JMP_                ; JMP
            BRA         DATA                ; value not recognized

********************************** NOP, RTS ***********************************
NOP_RTS
            MOVEQ       #0,D0               ; Iso-task 0: isolate d0-d5
            BSR         ISO_BITS
            CMP.B       #$31,D2
            BEQ         NOP_                ; NOP
            CMP.B       #$35,D2
            BEQ         RTS_                ; RTS
            BRA         DATA                ; value not recognized

************************************ NOP **************************************
NOP_
            MOVE.W      #_NOP,(A6)+         ; push address of NOP to buffer
            BRA         END_OCR

************************************ RTS **************************************
RTS_
            MOVE.W      #_RTS,(A6)+         ; push address of RTS to buffer
            BRA         END_OCR

************************************ JSR **************************************
JSR_
			MOVE.W		#_JSR,(A6)+				; push address of JSR to buffer
			MOVE.W		#SPACING,(A6)+			; even column spacing
			BSR			ISO_D0_TO_D5_FOR_EA		; send source <ea> bits to EAR
			BRA			END_OCR

************************************ JMP **************************************
JMP_
			MOVE.W		#_JMP,(A6)+				; push address of JMP to buffer
			MOVE.W		#SPACING,(A6)+			; even column spacing
			BSR			ISO_D0_TO_D5_FOR_EA		; send source <ea> bits to EAR
			BRA			END_OCR

************************************ ADDQ *************************************
ADDQ_
            MOVE.W      #_ADDQ,(A6)+        ; push address of ADDQ to buffer
            MOVEQ       #1,D0               ; Iso-task 1: isolate bits d6-d7
            BSR         ISO_BITS
            BSR         BWL                 ; append .B, .W, or .L
            BSR         ISO_D0_TO_D5_FOR_EA     ; send source <ea> bits to EAR
            BRA         END_OCR

************************************ Bcc **************************************
B_
            MOVEQ       #5,D0               ; Iso-task 1: isolate bits d6-d7
            BSR         ISO_BITS
                                            **BRANCH**
            CMP.B       #4,D2
            BEQ         BCC_                ; BCC
            CMP.B       #5,D2
            BEQ         BCS_                ; BCS
            CMP.B       #7,D2
            BEQ         BEQ_                ; BEQ
            CMP.B       #8,D2
            BEQ         BVC_                ; BVC
            CMP.B       #9,D2
            BEQ         BVS_                ; BVS
            BRA         DATA                ; value not recognized

BCC_
            MOVE.W      #_BCC,(A6)+         ; push address of BCC to buffer
            MOVE.W      (A4)+,D2
            BRA         END_OCR
BCS_
            MOVE.W      #_BCS,(A6)+         ; push address of BCS to buffer
            MOVE.W      (A4)+,D2
            BRA         END_OCR
BEQ_
            MOVE.W      #_BEQ,(A6)+         ; push address of BEQ to buffer
            MOVE.W      (A4)+,D2
            BRA         END_OCR
BVC_
            MOVE.W      #_BVC,(A6)+         ; push address of BVC to buffer
            MOVE.W      (A4)+,D2
            BRA         END_OCR
BVS_
            MOVE.W      #_BVS,(A6)+         ; push address of BVS to buffer
            MOVE.W      (A4)+,D2
            BRA         END_OCR
************************************* OR **************************************
OR_
            MOVE.W      #_OR,(A6)+          ; push address of OR to buffer
            MOVEQ       #1,D0               ; Iso-task 1: isolate bits d6-d7
            BSR         ISO_BITS
            BSR         BWL                 ; append .B, .W, or .L
            BSR         LOGIC_OP_EA
            BRA         END_OCR
************************************ SUBA *************************************
SUBA_
            MOVE.W      #_SUBA,(A6)+    ; push address of SUBA to buffer
            MOVEQ       #4,D0           ; Iso-task 4: isolate bits d8
            BSR         ISO_BITS
            BSR         WL              ; .W or .L, use WL when isolating d8
* Isolate bits d0-d5 and d6-d11, and send them to EA routine before return
            BSR         ISO_D0_TO_D5_FOR_EA     ; send source <ea> bits to EAR
            BSR         ISO_D6_TO_D11_FOR_EA    ; send dest <ea> bits to EAR
            AND.B       #$0F,D0	; EA uses D0, this masks for address register
   	        BSR         EAR_decode              ; call EA subroutine
            BRA         END_OCR
******************************* EOR, CMP, CMPA ********************************
EOR_CMP_CMPA
            MOVEQ       #1,D0           ; Iso-task 1: isolate bits d6-d7
            BSR         ISO_BITS

            CMP.B       #3,D2
            BEQ         CMPA_           ; CMPA
            BRA         EOR_CMP         ; EOR, CMP

************************************ CMPA *************************************
CMPA_
            MOVE.W      #_CMPA,(A6)+    ; push address of CMPA to buffer
            MOVEQ       #4,D0           ; Iso-task 4: isolate bits d8
            BSR         ISO_BITS
            BSR         WL              ; .W or .L, use WL when isolating d8
* Isolate bits d0-d5 and d6-d11, and send them to EA routine before return
            BSR         ISO_D0_TO_D5_FOR_EA     ; send source <ea> bits to EAR
            BSR         ISO_D6_TO_D11_FOR_EA    ; send dest <ea> bits to EAR
            AND.B       #$0F,D0 ; EA uses D0, this masks for address register
   	        BSR         EAR_decode              ; call EA subroutine
            BRA         END_OCR
********************************** EOR, CMP ***********************************
EOR_CMP
            MOVEQ       #4,D0           ; Iso-task 4: isolate bits d8
            BSR         ISO_BITS

            CMP.B       #0,D2
            BEQ         CMP_            ; CMP
            BRA         EOR_            ; EOR

************************************ CMP **************************************
CMP_
            MOVE.W      #_CMP,(A6)+         ; push address of CMP to buffer
            MOVEQ       #1,D0               ; Iso-task 1: isolate bits d6-d7
            BSR         ISO_BITS
            BSR         BWL                 ; append .B, .W, or .L

* Isolate bits d0-d5 and d6-d11, and send them to EA routine before return
            BSR         ISO_D0_TO_D5_FOR_EA     ; send source <ea> bits to EAR
            BSR         ISO_D6_TO_D11_FOR_EA    ; send dest <ea> bits to EAR
   	        BSR         EAR_decode              ; call EA subroutine
            BRA         END_OCR
************************************ EOR **************************************
EOR_
            MOVE.W      #_EOR,(A6)+     ; push address of EOR to buffer
            MOVEQ       #1,D0           ; Iso-task 1: isolate bits d6-d7
            BSR         ISO_BITS
            BSR         BWL             ; append .B, .W, or .L
            BSR			LOGIC_OP_EA
            BRA         END_OCR
*********************************** AND ***************************************
AND_
            MOVE.W      #_AND,(A6)+     ; push address of AND to buffer
            MOVEQ       #1,D0           ; Iso-task 1: isolate bits d6-d7
            BSR         ISO_BITS
            BSR         BWL             ; append .B, .W, or .L
            BSR			LOGIC_OP_EA
            BRA         END_OCR
************************************ ADDA *************************************
ADDA_
            MOVE.W      #_ADDA,(A6)+    ; push address of ADDA to buffer
            MOVEQ       #4,D0           ; Iso-task 4: isolate bits d8
            BSR         ISO_BITS
            BSR         WL              ; .W or .L, use WL when isolating d8
* Isolate bits d0-d5 and d6-d11, and send them to EA routine before return
            BSR         ISO_D0_TO_D5_FOR_EA     ; send source <ea> bits to EAR
            BSR         ISO_D6_TO_D11_FOR_EA    ; send dest <ea> bits to EAR
            AND.B		#$0F,D0	; EA uses D0, this masks for address register
   			BSR 		EAR_decode			; call EA subroutine
            BRA         END_OCR
********************************** ASd, ROd ***********************************
ASd_ROd
            MOVEQ       #1,D0               ; Iso-task 1: isolate bits d6-d7
            BSR         ISO_BITS
            CMP.B       #3,D2
            BEQ         ASd_ROd_MS
            BRA         ASd_ROd_RS
*******************************************************************************
ASd_ROd_RS
            MOVEQ       #6,D0               ; Iso-task 6: isolate d3-d4
            BSR         ISO_BITS
            CMP.B       #0,D2
            BEQ         ASd_RS               ; ASd
            CMP.B       #3,D2
            BEQ         ROd_RS               ; ROd
            BRA         DATA                ; value not recognized

ASd_RS
            MOVE.W      #_ASd,(A6)+         ; push address of ASd to buffer
            BSR         DIRECTION
            BSR         ASd_ROd_SIZE
            BRA         COMPLEX

            BRA         END_OCR

ROd_RS
            MOVE.W      #_ROd,(A6)+         ; push address of ROd to buffer
            BSR         DIRECTION
            BSR         ASd_ROd_SIZE

COMPLEX
            MOVE.W      #TAB_SIGN,(A6)+
            CMP.B       #1,D2
            BEQ         ROd_WORD
CONT_ROD_REG
            MOVEQ       #2,D0
            BSR         ISO_BITS
            MOVE.B      D2,D0
            BSR         EAR_DECODE

            MOVE.W      #COMMA_SIGN,(A6)+     ; Insert tab to print buffer
CONT_ROD_IND
            MOVEQ       #3,D0               ; return size of source, d12-15
            BSR         ISO_BITS
            MOVE.B      D2,D7               ; store for EA
            ANDI.B      #3,D7   ; isolate to see if immediate is long or word

            MOVEQ       #0,D0               ; Iso-task 0: isolate bits d0-d5
            BSR         ISO_BITS
            ANDI.B      #7,D2
            MOVE.W      D2,D0               ; load to D0 (used by EA)
            BSR         EAR_decode          ; call EA subroutine
            BRA         END_OCR
ROd_WORD
            MOVE.W      D1,D2
            BTST        #5,D2
            BNE         CONT_ROD_REG
            BRA         CONT_ROD_IND

            BRA         END_OCR
*******************************************************************************
ASd_ROd_MS
            MOVEQ       #2,D0       ; isolate d9-d11
            BSR         ISO_BITS
            CMP.B       #0,D2       ;
            BEQ         ASd_MS
            CMP.B       #3,D2
            BEQ         ROd_MS
            BRA         DATA

ASd_MS
            MOVE.W      #_ASd,(A6)+         ; push address of ASd to buffer
            BSR         DIRECTION
            MOVE.W      #_WORD,(A6)+
            BSR         ISO_D0_TO_D5_FOR_EA     ; send source <ea> bits to EAR
            BRA         END_OCR
ROd_MS
            MOVE.W      #_ROd,(A6)+         ; push address of ROd to buffer
            BSR         DIRECTION
            MOVE.W      #_WORD,(A6)+
            BSR         ISO_D0_TO_D5_FOR_EA     ; send source <ea> bits to EAR
            BRA         END_OCR
*******************************************************************************
DIRECTION
            MOVEQ       #4,D0               ; isolate d8
            BSR         ISO_BITS
            BSR         LR                  ; add left or right
            RTS
ASd_ROd_SIZE
            MOVEQ       #1,D0               ; Iso-task 1: isolate bits d6-d7
            BSR         ISO_BITS
            BSR         BWL                 ; append .B, .W, or .L
            RTS

*******************************************************************************
DATA ; value not recognized
            MOVE.W      #_DATA,(A6)+         ; push address of DATA to buffer
            BRA         END_OCR

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
            CMP.B       #4,D0       ; Task 4, isolate d8
            BEQ         d8
            CMP.B       #5,D0       ; Task 5, isolate d8-d11
            BEQ         d8tod11
            CMP.B       #6,D0       ; Task 6, isolate d3-d4
            BEQ         d3tod4
            CMP.B       #7,D0       ; Task 7, isolate d6-d11
            BEQ         d6tod11
            RTS                     ; return to op-code branch

ISO_D0_TO_D5_FOR_EA     ; send source <ea> bits to EAR
			MOVEM.L		D0/D2/D3/D7,-(SP)

			MOVEQ		#3,D0				; return size of source, d12-15
			BSR 		ISO_BITS
			MOVE.B		D2,D7				; store for EA
			ANDI.B		#3,D7	; isolate to see if immediate is long or word

			MOVEQ		#0,D0				; Iso-task 0: isolate bits d0-d5
			BSR 		ISO_BITS
			MOVE.W		D2,D0				; load to D0 (used by EA)
			MOVE.W		#TAB_SIGN,(A6)+		; Insert tab to print buffer
			BSR 		EAR_decode			; call EA subroutine

			MOVEM.L		(SP)+,D0/D2/D3/D7
			RTS 							; return to op-code branch

ISO_D6_TO_D11_FOR_EA    ; send dest <ea> bits to EAR
			MOVEQ		#7,D0				; Iso-task 7: isolate bits d6-d11
			BSR 		ISO_BITS
			BSR 		SWAP_REG_MODE
			MOVE.W		D2,D0				; load iso bits to D0, used by EA
			MOVE.W		#COMMA_SIGN,(A6)+	; Insert a tab
			RTS 							; return to op-code branch

d12tod15    ; Isolate bits d12-d15 and assign them to register D2
            MOVE.W      D1,D2       ; avoid overwrite of original
            ROL.W       #4,D2       ; move d12-d15 -> d0-d3
            ANDI.W      #$F,D2      ; mask to keep only four bits
            RTS                     ; return to op-code branch

d8tod11     ; Isolate bits d8-d11 and assign them to register D2
            MOVE.W      D1,D2       ; avoid overwrite of original
            ROL.W       #8,D2       ; move d8-d11 -> d0-d2
            ANDI.W      #$0F,D2     ; mask to keep only four bits
            RTS                     ; return to op-code branch


d9tod11     ; Isolate bits d9-d11 and assign them to register D2
            MOVE.W      D1,D2       ; avoid overwrite of original
            ROL.W       #7,D2       ; move d9-d11 -> d0-d2
            ANDI.W      #7,D2       ; mask to keep only three bits
            RTS                     ; return to op-code branch

d8          ; Isolate bits d8 and assign them to register D2
            MOVE.W      D1,D2       ; avoid overwrite of original
            LSR.W       #8,D2       ; move d8-d11 -> d0-d2
            ANDI.W      #1,D2       ; mask to keep only one bit
            RTS                     ; return to op-code branch
d6tod11
            MOVE.W      D1,D2       ; avoid overwrite of original
            LSR.W       #6,D2       ; move d6-d11 -> d0-d5
            ANDI.W      #$3F,D2     ; mask to keep only the first six bits
            RTS                     ; return to op-code branch

d6tod7      ; Isolate bits d6-d7 and assign them to register D2
            MOVE.W      D1,D2       ; avoid overwrite of original
            LSR.W       #6,D2       ; move d6-d7 -> d0-d1
            ANDI.W      #3,D2       ; mask to keep only two bits
            RTS                     ; return to op-code branch

d3tod4      ; Isolate bits d0-d5 and assign them to register D2
            MOVE.W      D1,D2       ; avoid overwrite of original
            LSR.W       #3,D2       ; move d3-d4 -> d0-d1
            ANDI.W      #3,D2       ; mask to keep only two bits
            RTS                     ; return to op-code branch

d0tod5      ; Isolate bits d0-d5 and assign them to register D2
            MOVE.W      D1,D2       ; avoid overwrite of original
            ANDI.W      #$3F,D2     ; mask to keep only the first six bits
            RTS                     ; return to op-code branch
*********************** BYTE, WORD, OR LONG SUBROUTINE ************************
BWL                                     ; standard sizing
            CMP.B       #0,D2
            BEQ         BYTE_
            CMP.B       #1,D2
            BEQ         WORD_
            CMP.B       #2,D2
            BEQ         LONG_
            RTS                         ; RTS assumes that it didn't branch

WL                                      ; used exclusively with SUBA,CMPA,ADDA
            CMP.B       #0,D2
            BEQ         WORD_
            CMP.B       #1,D2
            BEQ         LONG_
            RTS                         ; RTS assumes that it didn't branch

BLW                                     ; used exclusively with MOVE and MOVEA
            CMP.B       #1,D2
            BEQ         BYTE_
            CMP.B       #2,D2
            BEQ         LONG_
            CMP.B       #3,D2
            BEQ         WORD_
            RTS                         ; RTS assumes that it didn't branch

BYTE_
            MOVE.W      #_BYTE,(A6)+    ; push address of .B to buffer
            RTS                         ; return to subroutine that called BWL

WORD_
            MOVE.W      #_WORD,(A6)+    ; push address of .W to buffer
            RTS                         ; return to subroutine that called BWL

LONG_
            MOVE.W      #_LONG,(A6)+    ; push address of .L to buffer
            RTS                         ; return to subroutine that called BWL

*************************** LEFT RIGHT SUBROUTINE *****************************
LR
            CMP.B       #0,D2           ; can only be 0 or 1
            BEQ         RIGHT
            BRA         LEFT

RIGHT
            MOVE.W      #_RIGHT,(A6)+   ; push address of 'R' to buffer
            RTS

LEFT
            MOVE.W      #_LEFT,(A6)+    ; push address of 'L' to buffer
            RTS
*******************************************************************************
* (Semi fix for EA)
* Working register is D2.W
SWAP_REG_MODE ; called by ISO_D6_TO_D11_FOR_EA
            MOVEM.L     D3-D5,-(SP)             ; save register states
                                                ; D2:= reg mode
            CLR.L       D3                      ; D3:= reg
            CLR.L       D4                      ; D4:= mode
            CLR.L       D5                      ; D5:= mode reg
            MOVE.W      D2,D3                   ; copy bits
            MOVE.W      D2,D4                   ; copy bits
            ANDI.W      #%00111000,D3           ; mask for left three bits
            ANDI.W      #%00000111,D4           ; mask for right three bits
            LSR.W       #3,D3                   ; swap D3 bits with D4 bits
            LSL.W       #3,D4                   ; swap D4 bits with D3 bits
            OR.W        D3,D5                   ; add to D5
            OR.W        D4,D5                   ; add to D5
            MOVE.W      D5,D2                   ; move D5 to D2 (working reg.)
            MOVEM.L     (SP)+,D3-D5             ; restore register states
            RTS
********************** IMMEDIATE OPERATOR TO EA ROUTINE ***********************
* Used in op-code routine to send bits to EA routine. Used with ORI, ANDI, SUBI
* ADDI, EORI, CMPI
IMMEDIATE_ADDR
            * SOURCE
            MOVE.B		D2,D7
			MOVE.W		#TAB_SIGN,(A6)+		; push tab to print buffer
            MOVE.B		#$3C,D0
            BSR			EAR_DECODE			; push ASCII to print buffer
			MOVE.W		#COMMA_SIGN,(A6)+	; Insert a tab

            * DESTINATION
			MOVEQ		#0,D0				; Iso-task 0: isolate bits d0-d5
			BSR 		ISO_BITS
			MOVE.W		D2,D0				; load to D0 (used by EA)
            BSR			EAR_DECODE
            RTS
*********************** LOGIC OPERATOR TO EA ROUTINE **************************
* Used in op-code routine when op-code is AND, OR, EOR, etc...
LOGIC_OP_EA
           	MOVEQ		#4,D0			; task 4: isolate d8
           	BSR			ISO_BITS
           	MULU		#4,D2			; jump setup

            LEA			LOGIC_TABLE,A1
            JMP			00(A1,D2)		; jump relative to d8
LOGIC_TABLE
			BRA			LOGIC_SOURCE
			BRA			LOGIC_DESTINATION
LOGIC_SOURCE
            * SOURCE
            BSR         ISO_D0_TO_D5_FOR_EA ; send source <ea> bits to EAR
            								; then send destination
            * DESTINATION
			MOVE.W		#COMMA_SIGN,(A6)+	; Insert a tab
			MOVEQ		#7,D0				; Iso-task 7: isolate bits d6-d11
			BSR 		ISO_BITS
			BSR 		SWAP_REG_MODE		; standardize format for EA
			ANDI.W		#7,D2				; keep 3-bits to show which reg.
			MOVE.W		D2,D0				; load iso bits to D0, used by EA
            BRA			END_LOGIC

LOGIC_DESTINATION
			* SOURCE
			MOVE.W		#TAB_SIGN,(A6)+		; push tab to print buffer
			MOVEQ		#7,D0				; Iso-task 7: isolate bits d6-d11
			BSR 		ISO_BITS
			BSR 		SWAP_REG_MODE		; standardize format for EA
			ANDI.W		#7,D2				; keep 3-bits to show which reg.
			MOVE.W		D2,D0				; load iso bits to D0, used by EA
            BSR			EAR_DECODE			; push ASCII to print buffer

            * DESTINATION
			MOVE.W		#COMMA_SIGN,(A6)+	; Insert a tab
			MOVEQ		#3,D0				; return size of source, d12-15
			BSR 		ISO_BITS
			MOVE.B		D2,D7				; store for EA
			ANDI.B		#3,D7	; isolate to see if immediate is long or word

			MOVEQ		#0,D0				; Iso-task 0: isolate bits d0-d5
			BSR 		ISO_BITS
			MOVE.W		D2,D0				; load to D0 (used by EA)


END_LOGIC
   			BSR 		EAR_decode			; call EA subroutine
            RTS
********************************* CONSTANTS ***********************************
SPACING		DC.B		'  ',0 ; used to give uniform column look when printing
_BYTE       DC.B        '.B',0
_WORD       DC.B        '.W',0
_LONG       DC.B        '.L',0
_ORI        DC.B        'ORI',0
_ANDI       DC.B        'ANDI',0
_SUBI       DC.B        'SUBI',0
_ADDI       DC.B        'ADDI',0
_EORI       DC.B        'EORI',0
_CMPI       DC.B        'CMPI',0
_MOVE       DC.B        'MOVE',0
_MOVEA      DC.B        'MOVEA',0
_NEG        DC.B        'NEG',0
_NOP        DC.B        'NOP',0
_RTS        DC.B        'RTS',0
_JSR        DC.B        'JSR',0
_JMP        DC.B        'JMP',0
_ADDQ       DC.B        'ADDQ',0
_BCC        DC.B        'BCC',0
_BCS        DC.B        'BCS',0
_BEQ        DC.B        'BEQ',0
_BVC        DC.B        'BVC',0
_BVS        DC.B        'BVS',0
_OR         DC.B        'OR',0
_SUBA       DC.B        'SUBA',0
_EOR        DC.B        'EOR',0
_CMP        DC.B        'CMP',0
_CMPA       DC.B        'CMPA',0
_AND        DC.B        'AND',0
_ADDA       DC.B        'ADDA',0
_ASd        DC.B        'AS',0
_ROd        DC.B        'RO',0
_LEFT       DC.B        'L',0
_RIGHT      DC.B        'R',0
_DATA       DC.B        'DATA',0
NEW_LINE    DC.W        $0D0A,0

*********************************** OTHER *************************************
CR          EQU         $0D
LF          EQU         $0A

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
            MOVEM.L     A0-A3/A5/D0-D5/D7,-(SP) ;Save data from registers to stack

            LEA         ea_index_table,A1       ;Get reference to the EA Table
            CLR.L       D1
            MOVE.W      D0,D2                   ;Get a copy of the six EA bits
            MOVE.B      #3,D1                   ;Store number of bits we wish to shift
            LSR.W       D1,D0                   ;Shift to the Right
            MULU	    #6,D0			        ;Form Offset for passing to Jump Index table
	        JSR	        00(A1,D0)		        ;Now we have the index, back to Index table
	        MOVEM.L     (SP)+,A0-A3/A5/D0-D5/D7 ;Restore registers from stack
            RTS                                 ;Return

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

******* Direct Data Register - Return the Data Register to the buffer - Dn ****
eaindex000
            MOVE	    D2,D0		            ;Get EA from D2 (6bits)
	        ANDI	    #7,D0		            ;Grab Register (3bits)
	        ;MOVE.W      #tab_sign,(A6)+         ;Insert a tab
		    BSR	        send_data_buf           ;Send data to buffer
		    RTS                                 ;Return

***** Direct Address Register - Return the Address Register to the buffer - An
eaindex001
            MOVE        D2,D0                   ;Get EA from D2 (6bits)
            ANDI        #7,D0                   ;AND with 3bits to get Register Info
            BSR         send_addr_buf          ;Send Address to buffer
            RTS                                 ;Return

****** Indirect Address Register - Returns Address within Parentheses - (An) **
eaindex010
            *Get the Open Paren
		    MOVE.W      #OPEN_PAREN,(A6)+		;Load close Paren to buffer

            *Get the Address
		    CLR.L	    D0		                ;Empty data register
		    MOVE	    D2,D0		            ;Store EA bits (6bits)
		    ANDI	    #7,D0		            ;AND with 3-bits to get values
		    BSR	        send_addr_buf           ;Add Address to buffer after Open Paren

            *Get the Close Paren
		    MOVE.W      #CLOSE_PAREN,(A6)+		;Load close Paren to buffer
            RTS                                 ;Return

************** Indirect Address Register with Post-Increment - (An)+ **********
eaindex011
            *Get the Open Paren
		    MOVE.W      #OPEN_PAREN,(A6)+		;Load close Paren to buffer

            *Get the Address
		    CLR.L	    D0		                ;Empty data register
		    MOVE	    D2,D0		            ;Store EA bits (6bits)
		    ANDI	    #7,D0		            ;AND with 3-bits to get values
		    BSR	        send_addr_buf           ;Add Address to buffer after Open Paren

            *Get the Close Paren
		    MOVE.W      #CLOSE_PAREN,(A6)+		;Load close Paren to buffer

            *Get the Plus Sign
            MOVE.W      #PLUS_SIGN,(A6)+                ;Add to buffer
            RTS                                 ;Return

*************** Indirect Address Register with Pre-Decrement - -(An) **********
eaindex100
            *Get Minus Sign
            MOVE.W      #MINUS_SIGN,(A6)+                ;Add to buffer

            *Get Open Parentheses Sign
		    MOVE.W      #OPEN_PAREN,(A6)+		;Load close Paren to buffer

            *Store Address to Buffer
		    CLR.L	    D0		                ;Empty data register
		    MOVE	    D2,D0		            ;Store EA bits (6bits)
		    ANDI	    #7,D0		            ;AND with 3-bits to get values
		    BSR	        send_addr_buf           ;Add Address to buffer after Open Paren

            *Get Close Parentheses Sign
		    MOVE.W      #CLOSE_PAREN,(A6)+		;Load close Paren to buffer
            RTS                                 ;Return

******************** Indirect Address Register with an Index ******************
eaindex101

            *Get Dollar Sign
            MOVE.W      #DOLLAR_SIGN,(A6)+                ;Add to buffer

            *Prep for conversion
            MOVE.W      (A5)+,A0                 ;Get 8-bit extension word
            MOVE.L      D0,D3                   ;Back up to D3
            CLR.L       D4                      ;Clear out D4
            MOVE.B      #4,D4                   ;Store the number of bytes (4) in D4
            BSR         conv_to_ascii           ;Branch to ASCII conversion Subroutine

            *Move Hex value to Buffer
            MOVEA.L     A3,A1                   ;Move Hex value to A1
            MOVE.W      A1,(A6)+                ;Add to buffer

            *Get Open Parentheses Sign
		    MOVE.W      #OPEN_PAREN,(A6)+                ;Add to buffer

		    *Store Address to Buffer
		    CLR.L	    D0		                ;Empty data register
		    MOVE	    D2,D0		            ;Store EA bits (6bits)
		    ANDI	    #7,D0		            ;AND with 3-bits to get values
		    BSR	        send_addr_buf           ;Add Address to buffer after Open Paren

            *Get the Comma Sign
		    MOVE.W      COMMA_SIGN,(A6)+                ;Add to buffer

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
            MOVE.W      #LONG_EXT,(A6)+         ;Add to buffer

            *Get Close Parentheses Sign
		    MOVE.W      #CLOSE_PAREN,(A6)+		;Load close Paren to buffer
		    RTS                                 ;Return

add_word_buf
            MOVE.W      WORD_EXT,(A6)+          ;Add to buffer

            *Get Close Parentheses Sign
		    MOVE.W      #CLOSE_PAREN,(A6)+		;Load close Paren to buffer
		    RTS                                 ;Return

********************* PC, Immediate, or Absolute Addressing *******************
eaindex110
            LEA         subindex_tbl,A1         ;Loads the Subindex Jump Table
            MOVE        D2,D0                   ;Store EA original - 6 bits
            MULU        #6,D0                   ;Loads the offset for Jump Table
            JSR         00(A1,D0)               ;To SubIndex Jump Table
            RTS                                 ;Return when done

********************* PC, Immediate, or Absolute Addressing *******************
eaindex111
            LEA         subindex_tbl,A1         ;Loads the Subindex Jump Table
            MOVE        D2,D0                   ;Store EA original - 6 bits
            ANDI        #7,D0                   ;Get the Register bits
            MULU        #6,D0
            JSR         00(A1,D0)               ;To SubIndex Jump Table
            RTS                                 ;Just Return

************************* aeindex110 Subindex Jump Table **********************
subindex_tbl ;Uses Bitmask to differentiate Types
            JMP         easub000                ;Absolute Addressing - Word
            JMP         easub001                ;Absolute Addressing - Long
            JMP         easub010                ;Indirect Program Counter w/ Displacement
            JMP         easub011                ;Unused
            JMP         easub100                ;Immediate Data
            JMP         easub101                ;Unused
            JMP         easub110                ;Unused
            JMP         easub111                ;Unused

************************** Absolute Addressing - Word *************************
easub000
			MOVEM.L		A1/A3/D0/D3/D4,-(SP)
            *Get Dollar Sign
            MOVE.W      #DOLLAR_SIGN,(A6)+                ;Add to buffer

            *Prep for Conversion - Word
            LEA         ascii_w,A3              ;Load variable for ascii storage
            MOVE.W      (A4)+,D4                ;Clear Word from pointer stack
            MOVE.W      (A4)+,D0                ;Get the WORD data
            MOVE.W      D0,D3                   ;Back up to D3
            CLR.L       D4                      ;Empty Data Register
            MOVE.B      #4,D4              ;Get the length of Hex value - WORD
            BSR         conv_to_ascii           ;Branch to convert to ASCII

            LEA         ascii_w,A1
            MOVE.L      A1,(A6)+                ;Add to buffer

			MOVEM.L		(SP)+,A1/A3/D0/D3/D4
            RTS                                 ;Return

************************** Absolute Addressing - Long *************************
easub001
			MOVEM.L		A1/A3/D0/D3/D4,-(SP)

            *Get Dollar Sign
            MOVE.W      #DOLLAR_SIGN,(A6)+                ;Add to buffer

            *Prep for Conversion - LONG
            LEA         ascii_w,A3			;Load variable for ascii storage
            MOVE.W      (A4)+,D0                ;Get the LONG data
            CMP.W		#0,D0
            BEQ			SKIP

            MOVE.W      D0,D3                   ;Back up to D3
            CLR.L       D4                      ;Empty Data Register
            MOVE.B      #4,D4               ;Get the length of Hex value - LONG
            BSR         conv_to_ascii           ;Branch to convert to ASCII

            *Store Hex Address to Buffer
            LEA         ascii_w,A1
            MOVE.W      A1,(A6)+                ;Add to buffer
SKIP
            MOVE.W      (A4)+,D0                ;Get the LONG data
            MOVE.W      D0,D3                   ;Back up to D3
            CLR.L       D4                      ;Empty Data Register
            MOVE.B      #4,D4               ;Get the length of Hex value - LONG
            BSR         conv_to_ascii           ;Branch to convert to ASCII


            *Store Hex Address to Buffer
            LEA         ascii_w,A1
            MOVE.W      A1,(A6)+                ;Add to buffer

			MOVEM.L		(SP)+,A1/A3/D0/D3/D4
            RTS                                 ;Return

******************* Program Counter Indirect w/ Displacement ******************
easub010
            MOVEM.L     A1/A3/D0/D3/D4,-(SP)                ;Save D4 Register
            LEA         ascii_w,A3              ;Get converted address word

            *Get Dollar Sign
            MOVE.W      #DOLLAR_SIGN,(A6)+      ;Add to buffer

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
            MOVE.W      A1,(A6)+                ;Load into buffer
            MOVEA.L     #$00000000,A3           ;Reset contents of A3

            *Add Program Counter to Buffer
            LEA         prog_ctr,A1             ;ASCII value for (PC)
            MOVE.W      A1,(A6)+                ;Load into buffer

			MOVEM.L		(SP)+,A1/A3/D0/D3/D4
            RTS                                 ;Return

************************ Immediate Addressing w/ Data *************************
easub100
			MOVEM.L		A1/A3/D0/D3/D4,-(SP)

            LEA         ASCII_IMMEDIATE,A3      ;Get converted Address Word
            CMPI        #2,D5                   ;Check length
            BEQ         easub100_l              ;Branch to Long Subroutine
            CMPI        #3,D5                   ;Check for invalid Length
            BEQ         easub100_badLen         ;Branch to Bad Length Flag Subroutine

easub100_l
			*Get Pound Sign
			MOVE.W		#POUND_SIGN,(A6)+

			*Get Dollar Sign
			MOVE.W		#DOLLAR_SIGN,(A6)+

			CLR.L       D4                      ;Empty Data Register
			CMP.B		#2,D7
			BEQ			LONG
			BRA			WORD

LONG
			MOVE.B      #8,D4				;Get the length of Hex value - LONG
			MOVE.L		(A4)+,D0			;Get the LONG data
			BRA			NEXT
WORD
			MOVE.B      #4,D4				;Get the length of Hex value - WORD
			MOVE.W		(A4)+,D0			;Get the WORD data
			BNE			NEXT				;Branch if not zeros
			MOVE.W		(A4)+,D0			;Get the WORD data
NEXT
			MOVE.L		D0,D3				;Back up to D3
			BSR         conv_to_ascii		;Branch to convert to ASCII

			*Store Hex Address to Buffer
            MOVE.W      #ASCII_IMMEDIATE,(A6)+  ;Add to buffer

			MOVEM.L		(SP)+,A1/A3/D0/D3/D4

			RTS                                 ;Return

easub100_badLen
            MOVE.B      #1,D6                   ;Enable Bad Flag bit
            RTS                                 ;Return

easub011    RTS
easub101    RTS
easub110    RTS
easub111    RTS
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
            MOVE.W      #F_SLASH,(A6)+          ;Move forward slash to buffer
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
            MOVE.W      #F_SLASH,(A6)+          ;Move forward slash to buffer
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
open_paren	    DC.B	'(',0		;Open Parentheses
open_parenLen	DC.W	1	        ;Length of Open Parentheses
close_paren	    DC.B	')',0		;Close Parentheses
close_parenLen	DC.W	1	        ;Length of Close Parenthese
plus_sign		DC.B	'+',0		;Increment
plus_signLen	DC.W	1		    ;Length of Increment
minus_sign		DC.B	'-',0		;Decrement
minus_signLen	DC.W	1		    ;Length of Decrement
dollar_sign	    DC.B	'$',0		;Dollar Sign
dollar_signLen	DC.W	1	        ;Length of Dollar Sign
comma_sign	    DC.B	',',0		;Comma
comma_signLen	DC.W	1	        ;Length of the Comma
word_ext		DC.B	'.W',0	    ;Word Extension Indicator
word_extLen	    DC.W	2	        ;Length of Word Extension
long_ext		DC.B	'.L',0	    ;Long Extension Indicator
long_extLen	    DC.W	2	        ;Length of Long Extension
prog_ctr		DC.B	'(PC)',0	;Program Counter
prog_ctrLen		DC.W	4		    ;Length of Program Couner
f_slash   	    DC.B	'/',0		;Forward Slash
f_slashLen	    DC.W	1		    ;Length of Forward Slash
pound_sign	    DC.B	'#',0		;Pound symbol for immediate data
pound_signLen	DC.W	1	        ;Length of pound
tab_sign        DC.W    '    ',0
tab_Len         DC.B    4

asc_wrd		    DS.W	1           ;Word converted to ASCII
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
