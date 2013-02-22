*-----------------------------------------------------------
* Title      : Pasta 2.0
* Written by : Mitch Carlson & Kyle Rindahl
* Date       : 2/19/13
* Description: 
*-----------------------------------------------------------
            OPT	    CRE
START       ORG	    $1000

            LEA     WELCOME_MSG,A2  ; Load address of welcome message

            MOVEA.W (A2)+,A1        ; Welcome message
            MOVEQ   #13, D0         ; Trap task #13: Display A1 with CR and LF
            TRAP    #15             ; I/O
            
            MOVEA.W (A2)+,A1        ; Ask for starting address for range
            MOVEQ   #14, D0         ; Trap task #14: Display A1 w/out CR and LF
            TRAP    #15             ; I/O
            
            MOVEQ   #2,D0           ; Trap task #2: Get starting address
            LEA     S_ADDR,A1
            TRAP    #15             ; Read from keyboard to D1
            
            MOVEA.W (A2)+,A1        ; Ask for ending address for range
            MOVEQ   #14, D0         ; Trap task #14: Display A1 w/out CR and LF
            TRAP    #15             ; I/O

            MOVEQ   #2,D0           ; Get ending address
            LEA     E_ADDR,A1
            TRAP    #15             ; Read from keyboard to D1
            
LF          EQU     $0A             ; Line feed
CR          EQU     $0D             ; Carriage return
W0          DC.W    'Welcome! Lets disassemble some code.',0
W1          DC.W    'Please enter the starting address: ',0
W2          DC.W    'Please enter the ending address: ',0
WELCOME_MSG DC.W    W0,W1,W2        ; message array
S_ADDR      DS.L    2               ; Start address storage, stored as string. 
                                    ; Need to find a way to store as hex 
                                    ; address, or translate to hex
E_ADDR      DS.L    2               ; End address storage

            END     START



*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
