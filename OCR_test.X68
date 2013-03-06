
            OPT         CRE
            ORG         $1000
START
*************************** DEV TEST PURPOSES ONLY ****************************
            LEA         INPUT,A4
NEXT
            BSR         OCR
            BSR         DISPLAY
            MOVEQ       #1,D0
            CMP.B       #79,D0
            BNE         NEXT
            STOP        #$2700

DISPLAY
            LEA         validB,A2   ; load register for increment
LOOP
            MOVEA.W     (A2),A1     ; move reg addr value for display
            MOVE.W      #$FFFF,(A2)+
            CMPA        #$FFFF,A1   ; check for end
            BEQ         QUIT
            BSR         TO_CONSOLE
            BRA         LOOP
TO_CONSOLE            
            MOVEQ       #14,D0      ; load trap task to display
            TRAP        #15         ; display
            RTS
QUIT
            RTS

EAR_decode
            MOVEM.L     D0/D1,-(SP)
            CMPI.B      #0,D1
            BEQ         SRCE
            CMPI.B      #1,D1
            BEQ         DEST
EAR_DONE
            MOVEM.L     (SP)+,D0/D1
            RTS
SRCE
            MOVE.W      #_SRCE,(A6)+        ; push address of ANDI to buffer
            BRA         EAR_DONE
DEST
            MOVE.W      #_DEST,(A6)+        ; push address of ANDI to buffer
            BRA         EAR_DONE

_SRCE        DC.B        ' <SRCE>',0
_DEST        DC.B        ',<DEST>',0

validB      DS.W        10   ; buffer stores addresses of defined constants
INPUT       DC.W        $4E71,$4400,$4450,$44A0,$4EF9,$4E90,$4E75,$12C0
            DC.W        $3300,$22C0,$1218,$3208,$2218,$3240,$2248,$D2D0
            DC.W        $D3D8,$0619,$0651,$06A1,$5011,$5041,$5099,$92D8
            DC.W        $93D8,$0411,$0441,$0491,$C218,$C240,$C2B9,$C119
            DC.W        $C159,$C1B9,$0211,$0251,$0299,$8220,$8240,$8298
            DC.W        $8139,$8161,$8199,$0021,$0051,$00A1,$B119,$B159
            DC.W        $B199,$0A01,$0A41,$0A99,$E121,$E161,$E1A1,$E021
            DC.W        $E241,$E0A1,$E139,$E359,$E1B9,$E039,$E259,$E0B9
            DC.W        $B210,$B240,$B298,$B2C0,$B3D8,$0C11,$0C41,$0CB9
            DC.W        $6400,$6500,$6700,$6800,$6900,$6F00,$2700

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
            MOVEM.L     A0-A3/A5-A6/D0-D7,-(SP)
            LEA         validB,A6  ; load good buffer to A6
            MOVE.W      (A4)+,D1   ; A4, universal ptr to next op-code mem addr
                                   ; D1 holds original op-code word until
                                   ; routine is finished

            MOVEQ       #3,D0                   ; Iso-task 3: isolate d12-d15
            BSR         ISO_BITS
                                                **Branches**
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
            MOVEM.L     (SP)+,A0-A3/A5-A6/D0-D7
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
    * Isolate bits d0-d5 and send them to EA routine before return
            BSR         ISO_D0_TO_D5_FOR_EA     ; send source <ea> bits to EAR
            BRA         END_OCR

************************************ ANDI *************************************
ANDI_
            MOVE.W      #_ANDI,(A6)+        ; push address of ANDI to buffer
            MOVEQ       #1,D0               ; Iso-task 1: isolate bits d6-d7
            BSR         ISO_BITS
            BSR         BWL                 ; append .B, .W, or .L
    * Isolate bits d0-d5 and send them to EA routine before return
            BSR         ISO_D0_TO_D5_FOR_EA     ; send source <ea> bits to EAR
            BRA         END_OCR

************************************ SUBI *************************************
SUBI_
            MOVE.W      #_SUBI,(A6)+        ; push address of SUBI to buffer
            MOVEQ       #1,D0               ; Iso-task 1: isolate bits d6-d7
            BSR         ISO_BITS
            BSR         BWL                 ; append .B, .W, or .L
    * Isolate bits d0-d5 and send them to EA routine before return
            BSR         ISO_D0_TO_D5_FOR_EA     ; send source <ea> bits to EAR
            BRA         END_OCR

************************************ ADDI *************************************
ADDI_
            MOVE.W      #_ADDI,(A6)+        ; push address of ADDI to buffer
            MOVEQ       #1,D0               ; Iso-task 1: isolate bits d6-d7
            BSR         ISO_BITS
            BSR         BWL                 ; append .B, .W, or .L
    * Isolate bits d0-d5 and send them to EA routine before return
            BSR         ISO_D0_TO_D5_FOR_EA     ; send source <ea> bits to EAR
            BRA         END_OCR

************************************ EORI *************************************
EORI_
            MOVE.W      #_EORI,(A6)+        ; push address of EORI to buffer
            MOVEQ       #1,D0               ; Iso-task 1: isolate bits d6-d7
            BSR         ISO_BITS
            BSR         BWL                 ; append .B, .W, or .L
    * Isolate bits d0-d5 and send them to EA routine before return
            BSR         ISO_D0_TO_D5_FOR_EA     ; send source <ea> bits to EAR
            BRA         END_OCR            

************************************ CMPI *************************************
CMPI_
            MOVE.W      #_CMPI,(A6)+        ; push address of CMPI to buffer
            MOVEQ       #1,D0               ; Iso-task 1: isolate bits d6-d7
            BSR         ISO_BITS
            BSR         BWL                 ; append .B, .W, or .L
    * Isolate bits d0-d5 and send them to EA routine before return
            BSR         ISO_D0_TO_D5_FOR_EA     ; send source <ea> bits to EAR
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
    * Isolate bits d0-d5 and send them to EA routine before return
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
            MOVE.W      #_JSR,(A6)+         ; push address of JSR to buffer
    * Isolate bits d0-d5 and send them to EA routine before return
            BSR         ISO_D0_TO_D5_FOR_EA     ; send source <ea> bits to EAR
            BRA         END_OCR

************************************ JMP **************************************
JMP_
            MOVE.W      #_JMP,(A6)+         ; push address of JMP to buffer
    * Isolate bits d0-d5 and send them to EA routine before return
            BSR         ISO_D0_TO_D5_FOR_EA     ; send source <ea> bits to EAR
            BRA         END_OCR

************************************ ADDQ *************************************
ADDQ_
            MOVE.W      #_ADDQ,(A6)+        ; push address of ADDQ to buffer
            MOVEQ       #1,D0               ; Iso-task 1: isolate bits d6-d7
            BSR         ISO_BITS
            BSR         BWL                 ; append .B, .W, or .L
    * Isolate bits d0-d5 and send them to EA routine before return
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
    * need to calculate displacement
            BRA         END_OCR
BCS_
            MOVE.W      #_BCS,(A6)+         ; push address of BCS to buffer
    * need to calculate displacement
            BRA         END_OCR
BEQ_
            MOVE.W      #_BEQ,(A6)+         ; push address of BEQ to buffer
    * need to calculate displacement
            BRA         END_OCR
BVC_
            MOVE.W      #_BVC,(A6)+         ; push address of BVC to buffer
    * need to calculate displacement
            BRA         END_OCR
BVS_
            MOVE.W      #_BVS,(A6)+         ; push address of BVS to buffer
    * need to calculate displacement
            BRA         END_OCR
************************************* OR **************************************
OR_
            MOVE.W      #_OR,(A6)+          ; push address of OR to buffer
            MOVEQ       #1,D0               ; Iso-task 1: isolate bits d6-d7
            BSR         ISO_BITS
            BSR         BWL                 ; append .B, .W, or .L
    * Isolate bits d0-d5 and d6-d11, and send them to EA routine before return
            BSR         ISO_D0_TO_D5_FOR_EA     ; send source <ea> bits to EAR
            BSR         ISO_D6_TO_D11_FOR_EA    ; send dest <ea> bits to EAR
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
            MOVE.W      #_CMP,(A6)+     ; push address of CMP to buffer
            MOVEQ       #1,D0           ; Iso-task 1: isolate bits d6-d7
            BSR         ISO_BITS
            BSR         BWL             ; append .B, .W, or .L
    * Isolate bits d0-d5 and d6-d11, and send them to EA routine before return
            BSR         ISO_D0_TO_D5_FOR_EA     ; send source <ea> bits to EAR
            BSR         ISO_D6_TO_D11_FOR_EA    ; send dest <ea> bits to EAR
            BRA         END_OCR
************************************ EOR **************************************
EOR_
            MOVE.W      #_EOR,(A6)+     ; push address of EOR to buffer
            MOVEQ       #1,D0           ; Iso-task 1: isolate bits d6-d7
            BSR         ISO_BITS
            BSR         BWL             ; append .B, .W, or .L
    * Isolate bits d0-d5 and d6-d11, and send them to EA routine before return
            BSR         ISO_D0_TO_D5_FOR_EA     ; send source <ea> bits to EAR
            BSR         ISO_D6_TO_D11_FOR_EA    ; send dest <ea> bits to EAR
            BRA         END_OCR
*********************************** AND ***************************************
AND_
            MOVE.W      #_AND,(A6)+     ; push address of AND to buffer
            MOVEQ       #1,D0           ; Iso-task 1: isolate bits d6-d7
            BSR         ISO_BITS
            BSR         BWL             ; append .B, .W, or .L
    * Isolate bits d0-d5 and d6-d11, and send them to EA routine before return
            BSR         ISO_D0_TO_D5_FOR_EA     ; send source <ea> bits to EAR
            BSR         ISO_D6_TO_D11_FOR_EA    ; send dest <ea> bits to EAR
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
            BRA         END_OCR
********************************** ASd, ROd ***********************************
ASd_ROd
            MOVEQ       #1,D0               ; Iso-task 1: isolate bits d6-d7
            BSR         ISO_BITS
            CMP.B       #3,D2
            BLT         WHICHONE
            BRA         DATA
                                            **Branches**
WHICHONE
            MOVEQ       #6,D0               ; Iso-task 6: isolate d3-d4
            BSR         ISO_BITS

            CMP.B       #0,D2
            BEQ         ASd_               ; ASd
            CMP.B       #3,D2
            BEQ         ROd_               ; ROd
            BRA         DATA                ; value not recognized

ASd_
            MOVE.W      #_ASd,(A6)+         ; push address of ASd to buffer
            MOVEQ       #4,D0               ; Iso-task 4: isolate bits d8
            BSR         ISO_BITS
            BSR         LR                  ; add left or right
            MOVEQ       #1,D0               ; Iso-task 1: isolate bits d6-d7
            BSR         ISO_BITS
            BSR         BWL                 ; append .B, .W, or .L           
    * Isolate bits d0-d5 and send them to EA routine before return
            BSR         ISO_D0_TO_D5_FOR_EA     ; send source <ea> bits to EAR
            BRA         END_OCR
ROd_
            MOVE.W      #_ROd,(A6)+         ; push address of ROd to buffer
            MOVEQ       #4,D0               ; Iso-task 4: isolate bits d8
            BSR         ISO_BITS
            BSR         LR                  ; add left or right
            MOVEQ       #1,D0               ; Iso-task 1: isolate bits d6-d7
            BSR         ISO_BITS
            BSR         BWL                 ; append .B, .W, or .L           
    * Isolate bits d0-d5 and send them to EA routine before return
            BSR         ISO_D0_TO_D5_FOR_EA     ; send source <ea> bits to EAR
            BRA         END_OCR
*******************************************************************************
DATA ; value not recognized
            MOVE.W      #_DATA,(A6)+         ; push address of DATA to buffer
            RTS

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
            MOVEQ       #0,D0           ; Iso-task 0: isolate bits d0-d5
            BSR         ISO_BITS
            MOVEM.L     D0/D1,-(SP)     ; save reg state before subroutine
            MOVE.B      D2,D0           ; load isolated bits to D0, used by EA
            MOVE.L      #0,D1
            BSR         EAR_decode      ; call EA subroutine
            MOVEM.L     (SP)+,D0/D1     ; restore reg state after subroutine
            RTS                         ; return to op-code branch

ISO_D6_TO_D11_FOR_EA    ; send dest <ea> bits to EAR
            MOVEQ       #7,D0           ; Iso-task 7: isolate bits d6-d11
            BSR         ISO_BITS
            MOVEM.L     D0/D1,-(SP)     ; save reg state before subroutine
            MOVE.W      D2,D0           ; load isolated bits to D0, used by EA
            MOVE.L      #1,D1
            BSR         EAR_decode      ; call EA subroutine
            MOVEM.L     (SP)+,D0/D1     ; restore reg state after subroutine
            RTS                         ; return to op-code branch

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
            ROR.W       #8,D2       ; move d8-d11 -> d0-d2
            ANDI.W      #1,D2       ; mask to keep only one bit
            RTS                     ; return to op-code branch
d6tod11
            MOVE.W      D1,D2       ; avoid overwrite of original
            ROR.W       #6,D2       ; move d6-d11 -> d0-d5
            ANDI.W      #$3F,D2     ; mask to keep only three bits
            RTS                     ; return to op-code branch

d6tod7      ; Isolate bits d6-d7 and assign them to register D2
            MOVE.W      D1,D2       ; avoid overwrite of original
            ROR.W       #6,D2       ; move d6-d7 -> d0-d1
            ANDI.W      #3,D2       ; mask to keep only two bits
            RTS                     ; return to op-code branch

d3tod4      ; Isolate bits d0-d5 and assign them to register D2
            MOVE.W      D1,D2       ; avoid overwrite of original
            ROR.W       #3,D2       ; move d3-d4 -> d0-d1
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

********************************* CONSTANTS ***********************************
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
NEW_LINE    DC.B        CR,LF,0

*********************************** OTHER *************************************
CR          EQU         $0D
LF          EQU         $0A

*******************************************************************************
*                            End Op-code Routine
*******************************************************************************
            END           START


*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
