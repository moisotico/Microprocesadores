; Moises Campos Zepeda
; 19-09-2020
; IE0623: Microprocesadores
; Tarea #2
; Problema # 1
; Nota: el codigo se comento en ingles
; *****************************************************************************
;                           Data Structures
; *****************************************************************************
                org     $1000
; Data to use
BIN:            dw      #$A11
BCD:            dw      #$9999

; Dirs of data to save
                org     $1010
NUM_BCD:        ds      2

                org     $1020
NUM_BIN:        ds      2

; Temp variables
                org     $1100
TEMP:           ds      2
LOW:            ds      1

; *****************************************************************************
;                               Main Program
; *****************************************************************************
                org     $2000
                Ldd                 BIN
                jmp                 BIN_BCD
RETURN_BCD:
                ldd                 BCD
                jmp                 BCD_BIN
END:
                bra                 *

; *****************************************************************************
;                           Routine  BIN_BCD
; *****************************************************************************
BIN_BCD:
                ldx                     #15
        ; NUM_BCD:NUM_BCD+1 = 0
                clr                 NUM_BCD
                clr                 NUM_BCD+1

LOOP_1:        
                asld
                ;rol                 NUM_BCD+2
                rol                 NUM_BCD+1
                rol                 NUM_BCD
        ; Store A:B in TEMP:TEMP+1
                std                 TEMP
        ; Compare first 4 bytes
                ldab                NUM_BCD+1
                andb                #$0F
                cmpb                #5
                bcs                 NEXT_1
                addb                #3
NEXT_1:
        ; Store B
                stab                LOW
        ; Compare the second nibble
                ldab                NUM_BCD+1
                clra
                andb                #$F0
                cmpb                #$50
                bcs                 NEXT_2
        ; When B => $50                   
                addd                #$30
NEXT_2:
        ; Exchange to use daa
                ;exg                 A,B
                addb                LOW
                ;daa
                adca                #0
                stab                NUM_BCD+1
                adda                NUM_BCD
                staa                NUM_BCD
                clra
        ; Load 3rd nibble
                ldab                NUM_BCD
                andb                #$0F
                cmpb                #5
                bcs                 NEXT_3
                addb                #3
    ; Load 4th nibble
NEXT_3:
                stab                LOW
                ldab                NUM_BCD
                andb                #$F0
        ; Add LOW to B and store in NUM_BCD
                addb                LOW
                ;daa
                stab                NUM_BCD
        ; Load previous value in D
                ldd                 TEMP
                dex
        ; Is x == 0 ?
                beq                 EXIT_L1
                jmp                 LOOP_1
    ; Return to the main program
EXIT_L1:
                asld
                rol                 NUM_BCD+1
                rol                 NUM_BCD
                jmp                 RETURN_BCD


; *****************************************************************************
;                           Routine  BCD_BIN
; *****************************************************************************
BCD_BIN:
                clr                 NUM_BIN
                clr                 NUM_BIN+1
        ; First 4 bits
                andb                #$0F
                sty                 NUM_BIN+1
        ; Second group of 4 bits
                ldab                BCD+1
                andb                #$F0
        ; Transform B = $x0 to B = $0x
                lsrb
                lsrb
                lsrb
                lsrb
        ; D = B * 10
                ldaa                #10
                mul
                addb                NUM_BIN+1
                stab                NUM_BIN+1
        ; Third gorup of 4 bits                        
                ldaa                BCD
                anda                #$0F
                ldab                #100
                mul
                addd                NUM_BIN
                std                 NUM_BIN
        ; Final group of 4 bits                        
                ldab                BCD
                andb                #$F0
            ; Transform A = $X0 to A = $0X
                lsrb
                lsrb
                lsrb
                lsrb
        ; D = 0:B
                clra
        ; D = D *1000
                ldy                 #1000
                emul
                addd                NUM_BIN
                std                 NUM_BIN
        ; End of routine
                jmp                 END