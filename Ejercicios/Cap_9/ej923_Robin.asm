#include registers.inc

;*******************************************************************************
;       UNIVERSIDAD DE COSTA RICA       ESCUELA DE INGENIERIA ELECTRICA
;               MICROPROCESADORES IE 623  I SEMESTRE 2020
;*******************************************************************************
;                                 Despl_LED 923
;*******************************************************************************
;       V1
;       AUTOR: ROBIN GONZALEZ   B43011
;
;       DESCRIPCION:    KEY WAKEUPS
;
;*******************************************************************************
;                             Estructuras de datos
;*******************************************************************************

LEDS:   equ     1000

;*******************************************************************************
;                             Relocalizar vectores
;*******************************************************************************

        org     $3E4C ;de tabla de vectores de interrupt
        dw      PTH_ISR

;*******************************************************************************
;                             Config de hardware
;*******************************************************************************

        org     $2000

        BSET DDRb,$FF   ;ESTO ES UNA MASCARA
        BSET DDRj,$02   ;bit 1 es segundo de der a izq
        BCLR ptj,$02    ;habilita diodos leds
        
        MOVB #$0F, DDRP ;apaga display de 7 segmentos
        MOVB #$0F, PTP

        BSET PIEH,$01
        BSET PPSH,$01 ;Flanco creciente
;        MOVB #$17, RTICTL
;       MOVB #$C0, irqcr
        
;*******************************************************************************
;                             PROGRAMA PRINCIPAL
;*******************************************************************************

        LDS #$3BFF
        CLI
        LDAA 1
        STAA LEDS

        BRA *
        
;*******************************************************************************
;                             SUbrutina PTH_ISR
;*******************************************************************************

PTH_ISR         BSET PIFH,$01 ;borrar solicitud de interrupcion

                MOVB LEDS, PORTB

                LDAA $80
                CMPA LEDS
                BEQ reinicio
                LSL LEDS
retornar:
                RTI

reinicio:
               LDAA 1

                STAA LEDS

                Bra retornar