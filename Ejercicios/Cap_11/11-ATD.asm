; Moises Campos Zepeda
; 06-06-2020
; IE0623: Microprocesadores
; Ejercicio 8: Desplazamiento de LEDS con timer de comparacion

; Include File
#include registers.inc



; *****************************************************************************
;                           Data Structures
; *****************************************************************************
            org             $1000
RESULT:     ds  1



; *****************************************************************************
;                       Interruption Vector Relocation
; *****************************************************************************
            org             $FFD2
            dw          ATD0_ISR
            
; *****************************************************************************
;                           Main Program
; *****************************************************************************
            org             $2000
            movb        #$C2,ATD0CTL2
        ; a 10 ms Delay
            ldaa        #160
MAIN_LOOP:
            dbne        A,MAIN_LOOP
            movb        #$20,ATD0CTL3
            movb        #$97,ATD0CTL4
            movb        #$93,ATD0CTL5
            lds         #$3BFF
            cli
            bra         *


; *****************************************************************************
;                           ATD0_ISR Subroutine
; *****************************************************************************
ATD0_ISR:
            ldd         ADR00H
            addd        ADR01H
            addd        ADR02H
            addd        ADR03H
        ; avg value 
            lsrd
            lsrd
            stab        RESULT
            movb        #$93,ATD0CTL5
            rti
