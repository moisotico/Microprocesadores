#include registers.inc

;*******************************************************************************
;       UNIVERSIDAD DE COSTA RICA       ESCUELA DE INGENIERIA ELECTRICA
;               MICROPROCESADORES IE 623  I SEMESTRE 2020
;*******************************************************************************
;                                 Despl_LED
;*******************************************************************************
;       V1
;       AUTOR: ROBIN GONZALEZ   B43011
;
;       DESCRIPCION:    video 10.1 Timer Output Compare
;
;*******************************************************************************
;                             Estructuras de datos
;*******************************************************************************

LEDS:                EQU        $1000
Cont_OC:        equ     $1001
                ORG LEDS
                db 0,50




;*******************************************************************************
;                             Relocalizar vectores
;*******************************************************************************

 org            $3E64  ;DEBUG12 Ver tabla de vectores!!

                 dw TOI_ISR

;*******************************************************************************
;                             Config de hardware
;*******************************************************************************

                ORG     $2000

        BSET DDRb,$FF   ;ESTO ES UNA MASCARA
        BSET DDRj,$02   ;bit 1 es segundo de der a izq
        BCLR ptj,$02
        
        MOVB #$0F, DDRP         ;inhibir displays
;        MOVB #$0F, PTP          ;apaga display

        ;Control Register interrupt
        ;reg de ctrl
        BSET TSCR1,$90        ;Poner 1 en TEN Timer enable bit y de Timer Status Control Reg 1 Habilitio CRFFCA
        BSET TSCR2,$04        ;Prescalador de 16
        BSET TIOS,$20        ;Vamos a usar canal 5
        BSET TIE,$20        ;Canal 5
        
	BSET TCTL1,$04		;habilita toggle en pad 5 de Port T
        ;NUEVO OUTPUT COMPARE
        ;calculo cuentas sobre valor actual del contador porque nunca para
        LDD #1500      ;15000 en D
        ADDD TCNT       ;15000 + contador en D
        STD TC5         ;15000 + contador en TC5
        
        
;*******************************************************************************
;                             PROGRAMA PRINCIPAL
;*******************************************************************************

        LDS #$3BFF ;DEBUG12
        CLI
;       LDAA #1
;        MOVB #1, LEDS
;        STAA LEDS
;       MOVB #250,Cont_RTI
        LDAA #25
        STAA Cont_OC
;        LDAA 250
        BSET PORTB,$01
        BRA *
        
;*******************************************************************************
;                             SUbrutina RTI_ISR
;*******************************************************************************
                ;Control Register General Flag
                ;reg de estatus
TOI_ISR:         BSET TFLG2,$80 ;borrar solicitud de interrupcion  se borra con un 1
               ; BSET PORTB,$55
;                EORA #$01
;                STAA CRGFLG
;                DBNE Cont_RTI, retornar
                DEC Cont_OC
                BNE retornar
;                LDAA Cont_RTI
                MOVB #25, Cont_OC
;                LDAA 250
;                STAA Cont_RTI
;                MOVB LEDS, PORTB
;                LSL LEDS
                LSL PORTB
;                LDAA LEDS
;                STAA PORTB
                LDAA $80
;                CMPA LEDS
                CMPA PORTB
                BEQ reinicio
retornar:
        	;NUEVO OUTPUT COMPARE
	        ;calculo cuentas sobre valor actual del contador porque nunca para
	        LDD #1500      ;15000 en D
	        ADDD TCNT       ;15000 + contador en D
        	STD TC5         ;15000 + contador en TC5

                RTI

reinicio:
;                MOVB #1, LEDS
                BSET PORTB,$01
;                LDAA 1
;                STAA LEDS
                Bra retornar