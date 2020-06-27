; Moises Campos Zepeda
; 25-05-2020
; IE0623: Microprocesadores
; Ejercicio 3: gpio
#include registers.inc


DATA:        equ     $2000



; *****************************************************************************
;                               HW Config
; *****************************************************************************
; HW config

                org     DATA

            bclr        DDRH, $01
            bset        DDRB, $FF
            bset        DDRJ, $02

LOOP:
            ldaa        PTH
            staa        PORTB
            jmp         LOOP