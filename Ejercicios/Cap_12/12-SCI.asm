; Moises Campos Zepeda
; 15-07-2020
; IE0623: Microprocesadores
; Tarea 6: comunicacion con puerto serial

; Include File
#include registers.inc


; *****************************************************************************
;                           Data Structures
; *****************************************************************************
CR:             equ $0D
LF:             equ $0A
EOM:            equ $FF

            org             $1000
Puntero:    ds  2 

MSG:        fcc "	   UNIVERSIDAD DE COSTA RICA"
            fcb CR,LF
            fcc "	Escuela de Ingenieria Electrica"
            fcb CR,LF
            fcc "		Microprocesadores"
            fcb CR,LF
            fcc "		    IE0623"
            db  EOM


; *****************************************************************************
;                       Interruption Vector Relocation
; *****************************************************************************
            org     $FFD4
            dw          SCI_ISR
            
; *****************************************************************************
;                           HW Config
; *****************************************************************************
            org     $2000
            movb        #39,SC1BDH
            bclr        SC1CR1,$FF
            movb        #$88,SC1CR2

; *****************************************************************************
;                           Main Program
; *****************************************************************************
            lds         #$4000
            cli
            ldx         #MSG
            stx         Puntero

            ldaa        SC1SR1
            movb        #$0C,SC1DRL
            bra         *

; *****************************************************************************
;                           SCI_ISR
; *****************************************************************************
SCI_ISR:    loc
            ldaa        SC1SR1
            ldx         Puntero
            ldaa        1,X+
            cmpa        #EOM
            beq         TURNOFF
            staa        SC1DRL
            stx         Puntero
            bra         return` 
TURNOFF:
            movb        #$08,SC1CR2
return`
            rti
