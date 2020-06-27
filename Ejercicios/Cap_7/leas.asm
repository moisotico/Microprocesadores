; Moises Campos Zepeda
; 25-05-2020
; IE0623: Microprocesadores
; Ejercicio 1: Lea-K
; *****************************************************************************
;                               Data Structures
; *****************************************************************************

DATA:        equ     $1100
PROG:        equ     $1500
STACK:       equ     $4000
NUM:         equ     10

        org     DATA

BUFF:        dB      3,6,55,65,49,78,95,21,14,122

; *****************************************************************************
;                                   Main Program
; *****************************************************************************

        org     PROG

    lds         #STACK
    ldab        #NUM
    ldx         #BUFF

Load:
    ldaa        1,X+
    psha        
    dbne        B,Load
    jsr         CALCSUM
    leas        NUM,SP
    bra         *


CALCSUM:
    leas        2,SP        
    pula
    ldab        #NUM-1

Sume:
    adda        1,SP+
    dbne        b,Sume
    leas        0-NUM-2,SP
    rts





