
; Moises Campos Zepeda
; 06-06-2020
; IE0623: Microprocesadores
; Ejercicio 6: Desplazamiento de LEDS con timer de comparacion

; Include File
#include registers.inc


; *****************************************************************************
;                           Data Structures
; ****************************************************************************
            org             $1000
LEDS:       ds              1
CONT_OC:    ds              1

; *****************************************************************************
;                       Interruption Vector Relocation
; *****************************************************************************
            org             $3E64
            dw          OC5_ISR

; *****************************************************************************
;                               HW Config
; *****************************************************************************            
            org             $2000
            bset        DDRB,$FF
            bset        DDRJ,$02
            bclr        PTJ,$02

            ;movb        #$0F,DDRP
            bset        DDRP,$0F
            bset        PTP,$0F

        ; Ctrl registers and timer enable
            bset        TSCR1,$90 
            bset        TSCR2,$04
            bset        TIOS,$20
            bset        TIE,$20

            ldd         TCNT
            addd        #15000
            std         TC5

; *****************************************************************************
;                               Main Program
; *****************************************************************************
            lds         #$3BFF
            cli
            movb        #$01,LEDS
            movb        #25,CONT_OC
            bra         *
    
; *****************************************************************************
;                               TOI_ISR Subroutine
; *****************************************************************************
OC5_ISR:
            dec         CONT_OC
            bne         RETURN_ISR
            movb        #25,CONT_OC
            movb        LEDS,PORTB
            ldaa        LEDS
            cmpa        #$80
            bne         LSL_LEDS
            movb        #$01,LEDS
            
RETURN_ISR:
            ldd         TCNT
            addd        #15000
            std         TC5
            rti            

LSL_LEDS:
            lsl         LEDS
            bra         RETURN_ISR