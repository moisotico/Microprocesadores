; Moises Campos Zepeda
; 06-06-2020
; IE0623: Microprocesadores
; Ejercicio 5: Desplazamiento de LEDS

; Include File
#include registers.inc


; *****************************************************************************
;                           Data Structures
; ****************************************************************************
            org             $1000
LEDS:       ds              1
CONT_TOI:   ds              1

; *****************************************************************************
;                       Interruption Vector Relocation
; *****************************************************************************
            org             $3E5E
            dw          TOI_ISR

; *****************************************************************************
;                               HW Config
; *****************************************************************************            
            org             $2000
            bset        DDRB,$FF
            bset        DDRJ,$02
            bclr        PTJ,$02

            movb        #$0F,DDRP
            movb        #$0F,PTP

        ; Ctrl registers and timer enable
            bset        TSCR1,$80 
            bset        TSCR2,$82

; *****************************************************************************
;                               Main Program
; *****************************************************************************
            lds         #$3BFF
            cli
            movb        #25,CONT_TOI
            movb        #$01,LEDS
            bra         *
    
; *****************************************************************************
;                               TOI_ISR Subroutine
; *****************************************************************************
TOI_ISR:
            bset        TFLG2,$80
            dec         CONT_TOI
            bne         RETURN_ISR
            movb        #25,CONT_TOI
            movb        LEDS,PORTB
            ldaa        LEDS
            cmpa        #$80
            bne         LSL_LEDS
            movb        #$01,LEDS
RETURN_ISR:
            rti            

LSL_LEDS:
            lsl         LEDS
            bra         RETURN_ISR