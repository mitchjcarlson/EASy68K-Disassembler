
            OPT         CRE
            ORG         $1000
START
*************************** DEV TEST PURPOSES ONLY ****************************
            LEA         INPUT,A4
            LEA         END_INPUT,A5
NEXT
            BSR         OCR
            BSR         DISPLAY
            CMPA.L      A5,A4
            BLE         NEXT
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

validB      DS.W        6   ; buffer stores addresses of defined constants
INPUT
            DC.W        $4E71,$4400,$4410,$4418,$4420,$4439,$4439,$4440,$4450
            DC.w   $4458,$4460,$4479,$4479,$4480,$4490,$4498,$44A0,$44B9,$44B9
            DC.w   $4ED0,$4EF9,$4EF9,$4E90,$4EB9,$4EB9,$4E75,$1200,$1280,$12C0
            DC.w   $1300,$13C0,$13C0,$3200,$3280,$32C0,$3300,$33C0,$33C0,$2200
            DC.w   $2280,$22C0,$2300,$23C0,$23C0,$1200,$1210,$1218,$1220,$1039
            DC.w   $1039,$123C,$3200,$3208,$3210,$3218,$3220,$3039,$3039,$323C
            DC.w   $2200,$2208,$2210,$2218,$2220,$2039,$2039,$223C,$3240,$3248
            DC.w   $3250,$3258,$3260,$3279,$3279,$327C,$2240,$2248,$2250,$2258
            DC.w   $2260,$2279,$2279,$227C,$D2C0,$D2C8,$D2D0,$D2D8,$D2E0,$D2F9
            DC.w   $D2F9,$D2FC,$D3C0,$D3C8,$D3D0,$D3D8,$D3E0,$D3F9,$D3F9,$D3FC
            DC.w   $0601,$0611,$0619,$0621,$0639,$0639,$0641,$0651,$0659,$0661
            DC.w   $0679,$0679,$0681,$0691,$0699,$06A1,$06B9,$06B9,$5001,$5011
            DC.w   $5019,$5021,$5039,$5039,$5041,$5049,$5051,$5059,$5061,$5079
            DC.w   $5079,$5081,$5089,$5091,$5099,$50A1,$50B9,$50B9,$92C0,$92C8
            DC.w   $92D0,$92D8,$92E0,$92F9,$92F9,$92FC,$93C0,$93C8,$93D0,$93D8
            DC.w   $93E0,$93F9,$93F9,$93FC,$0401,$0411,$0419,$0421,$0439,$0439
            DC.w   $0441,$0451,$0459,$0461,$0479,$0479,$0481,$0491,$0499,$04A1
            DC.w   $04B9,$04B9,$C200,$C210,$C218,$C220,$C239,$C239,$C23C,$C240
            DC.w   $C250,$C258,$C260,$C279,$C279,$C27C,$C280,$C290,$C298,$C2A0
            DC.w   $C2B9,$C2B9,$C2BC,$C111,$C119,$C121,$C139,$C139,$C151,$C159
            DC.w   $C161,$C179,$C179,$C191,$C199,$C1A1,$C1B9,$C1B9,$0201,$0211
            DC.w   $0219,$0221,$0239,$0239,$0241,$0251,$0259,$0261,$0279,$0279
            DC.w   $0281,$0291,$0299,$02A1,$02B9,$02B9,$8200,$8210,$8218,$8220
            DC.w   $8239,$8239,$823C,$8240,$8250,$8258,$8260,$8279,$8279,$827C
            DC.w   $8280,$8290,$8298,$82A0,$82B9,$82B9,$82BC,$8111,$8119,$8121
            DC.w   $8139,$8139,$8151,$8159,$8161,$8179,$8179,$8191,$8199,$81A1
            DC.w   $81B9,$81B9,$0001,$0011,$0019,$0021,$0039,$0039,$0041,$0051
            DC.w   $0059,$0061,$0079,$0079,$0081,$0091,$0099,$00A1,$00B9,$00B9
            DC.w   $B101,$B111,$B119,$B121,$B139,$B139,$B141,$B151,$B159,$B161
            DC.w   $B179,$B179,$B181,$B191,$B199,$B1A1,$B1B9,$B1B9,$0A01,$0A11
            DC.w   $0A19,$0A21,$0A39,$0A39,$0A41,$0A51,$0A59,$0A61,$0A79,$0A79
            DC.w   $0A81,$0A91,$0A99,$0AA1,$0AB9,$0AB9,$E121,$E161,$E341,$E1D1
            DC.w   $E1D9,$E1E1,$E1F9,$E1F9,$E1A1,$E021,$E061,$E241,$E0D1,$E0D9
            DC.w   $E0E1,$E0F9,$E0F9,$E0A1,$E139,$E179,$E359,$E7D1,$E7D9,$E7E1
            DC.w   $E7F9,$E7F9,$E1B9,$E039,$E079,$E259,$E6D1,$E6D9,$E6E1,$E6F9
            DC.w   $E6F9,$E0B9,$B200,$B210,$B218,$B220,$B239,$B239,$B23C,$B240
            DC.w   $B248,$B250,$B258,$B260,$B279,$B279,$B27C,$B280,$B288,$B290
            DC.w   $B298,$B2A0,$B2B9,$B2B9,$B2BC,$B2C0,$B2C8,$B2D0,$B2D8,$B2E0
            DC.w   $B2F9,$B2F9,$B2FC,$B3C0,$B3C8,$B3D0,$B3D8,$B3E0,$B3F9,$B3F9
            DC.w   $B3FC,$0C01,$0C11,$0C19,$0C21,$0C39,$0C39,$0C41,$0C51,$0C59
            DC.w   $0C61,$0C79,$0C79,$0C81,$0C91,$0C99,$0CA1,$0CB9,$0CB9,$6400
            DC.w   $6500,$6700,$6C00,$6E00,$6200,$6F00,$6300,$6D00,$6B00,$6600
            DC.w   $6A00,$6800,$6900
END_INPUT
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
            BEQ         ASd_ROd_MS
            BRA         ASd_ROd_RS

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
            BSR         ISO_D0_TO_D5_FOR_EA     ; send source <ea> bits to EAR
            BRA         END_OCR
ROd_RS
            MOVE.W      #_ROd,(A6)+         ; push address of ROd to buffer
            BSR         DIRECTION
            BSR         ASd_ROd_SIZE
            BSR         ISO_D0_TO_D5_FOR_EA     ; send source <ea> bits to EAR
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
