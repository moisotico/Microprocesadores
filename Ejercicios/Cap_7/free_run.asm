; Moises Campos Zepeda
; 25-05-2020
; IE0623: Microprocesadores
; Ejercicio 2: Free_run
; *****************************************************************************
;                               Data Structures
; *****************************************************************************

DATA:        equ     $1100
PROG:        equ     $1500
STACK:       equ     $4000
NUM:         equ     10

        org     DATA


BUFF:           dB      3,6,55,65,49,78,95,21,14,122
;CUENTA         dB              
INCRE           ds      1

CONT_BIN        ds      1
VALOR_INT       ds      1
VALOR_MED       ds      1
VALOR_EXT       ds      1


; *****************************************************************************
;                               Main Program
; *****************************************************************************
        ; CONT_BIN = 0 and INCRE = 1                        
                clra
                staa            LOW
                ldab            #1
                stab            INCRE           

MAIN_LOOP:
                 ldab            INCRE
                 cmpb            #1
                 
         ; incre == 1 ?
                 ldaa            CONT_BIN                        
                 beq             INCREASE
REDUCE:
         ; CONT_BIN --        
                 deca
                 bne             TO_BIN_BCD
         ; INCRE = 1
                 ldab            #1
                 jmp             TO_BIN_BCD      
INCREASE:
        ; CONT_BIN ++        
                inca
                cmpa            CUENTA
                bne             TO_BIN_BCD
        ; INCRE = 0
                ldab            #0


TO_BIN_BCD:
        ; Store A in SP
                psha

        ; Go to BIN_BCD subroutine
                jsr             BIN_BCD
                pula

        ; VALOR_INT, VALOR_EXT, VALOR_MED
        ;        movb           VALOR_INT
        ;        movb           VALOR_MED
        ;        movb           VALOR_EXT

        ; DELAY Subroutine
        ;       jsr             DELAY


; *****************************************************************************
;                           BIN_BCD Subroutine
; *****************************************************************************
;TODO: DIVIDE HIGH and LOW PART

BIN_BCD:
                ldx                     #15
                
        ; NUM_BCD:NUM_BCD+1 = 0
                clr             NUM_BCD
                clr             NUM_BCD+1
                clr             NUM_BCD+2
                ldy             NUM_BCD

LOOP_1:        
                asld
                rol             NUM_BCD+2
                rol             NUM_BCD+1
                ;rol            NUM_BCD

        ; Store A:B in TEMP
                std             TEMP

        ; Compare first 4 bytes
                ldd             NUM_BCD+1
                andb            #$0F
                cmpb            #5
                bcs             NEXT_1
                addb            #3
NEXT_1:
        ; Store B
                stab            LOW

        ; Compare next 4 bytes
                ldd             NUM_BCD+1
                andb            #$F0
                cmpb            #$50
                bcs             NEXT_2
                tba
                clrb
                adda            #$30
                daa
                tab
                clra

NEXT_2:

        ; Store in NUM_BCD+1
                addd            LOW
                daa
        ; Store A in MID and in NUM_BIN+1
                std             NUM_BCD+1

        ; Load previous value in D
                ldd             TEMP
                dex

        ; Is x == 0
                beq              EXIT_L1
                jmp              LOOP_1

EXIT_L1:
        ; Return to the main program
                lsld
                rol              NUM_BCD+1
                rst


; *****************************************************************************
;                           DELAY Subroutine
; *****************************************************************************
;TODO: ALL