
; Moises Campos Zepeda
; 15-07-2020
; IE0623: Microprocesadores
; Ejercicio 9: comunicacion con puerto serial

; Include File
#include registers.inc


; *****************************************************************************
;                           Data Structures
; *****************************************************************************
CR:             equ $0D
LF:             equ $0A
EOM:            equ $FF

            org             $1000
Pointer0:        ds  2 
Pointer1:        ds  2 
Pointer2:        ds  2 

            org             $1010
Nivel_PROM:     ds  2
NIVEL:          ds  1
; Vaue to send to terminal
VOLUMEN:        ds  1
CONT_RTI:       ds  1
; 1: Vaciado activated, 0: Alarma activated 
BANDERAS:       ds  1

V_ASCII_C:      ds  1
V_ASCII_D:      ds  1
V_ASCII_U:      ds  1

MSG:        fcc "           UNIVERSIDAD DE COSTA RICA "
            fcb CR,LF
            fcc "          Escuela de Ingenieria Electrica "
            fcb CR,LF
            fcc "                Microprocesadores "
            fcb CR,LF
            fcc "                    IE0623 "
            fcb CR,LF
            fcc "       Medicion de Volumen "
            db LF
            db CR
            fcc "Volumen Actual: "

A_MSG:      fcc " Alarma: El Nivel esta Bajo "
            fcb CR,LF
            db  EOM

V_MSG:      fcc " Tanque vaciando, Bomba Apagada"
            fcb CR,LF
            db  EOM

; *****************************************************************************
;                       Interruption Vector Relocation
; *****************************************************************************
            org     $FFD2
            dw          ATD0_ISR
            
            org     $FFF0
            dw          RTI_ISR

            org     $FFD4
            dw          SCI_ISR
            
            
; *****************************************************************************
;                           Main Program
; *****************************************************************************
            org     $2000
            bset        DDRB,$FF
            bset        CRGINT,$80
            movb        #$54,RTICTL
            movb        #$C2,ATD0CTL2
            ldaa        #200
WAIT_ATD:
            beq         NEXT_ATD
            deca
            jmp         WAIT_ATD
NEXT_ATD:
            movb        #$30,ATD0CTL3
            movb        #$10,ATD0CTL4
            movb        #$87,ATD0CTL5

            movb        #$27,SC1BDH
            bclr        SC1CR1,$FF
            movb        #$10,SC1CR1

            lds         #$3BFF
            cli
            clr         BANDERAS
            clr         CONT_RTI
            clr         VOLUMEN
            clr         NIVEL
            clr         Nivel_PROM
CHK_CALC:
            jsr         CALCULO
            bra         CHK_CALC


; *****************************************************************************
;                           CALCULO Subroutine
; *****************************************************************************
CALCULO:    loc
        ; Calculate NIVEL
            ldd         Nivel_PROM
            ldy         #20
            emul
            ldx         #1023
            ediv
            tfr         Y,D
            stab        NIVEL
        ; Calculate Volumen with 7 = pi*(1.5)^2
            ldaa        #7
            mul
            stab        VOLUMEN
        ; Convert to ASCII, dividing units, tens, and hundreds
            ldx         #100
            idiv
            pshd
            tfr         X,D
            addb        #$30
            stab        V_ASCII_C
            ldx         #10
            puld
            idiv
            addb        #$30
            stab        V_ASCII_U
            tfr         X,D
            addb        #$30
            stab        V_ASCII_D
            rts


; ************************************ISR*************************************

; *****************************************************************************
;                           RTI_ISR
; *****************************************************************************
RTI_ISR:    loc
            bset       	CRGFLG,$80
            tst         CONT_RTI
            bne         return`
            movb        #$C8,SC1CR2
            movb        #100,CONT_RTI
            ldaa        SC1SR1
            movw        MSG,Pointer0            
            movw        A_MSG,Pointer1
            movw        V_MSG,Pointer2
return`
            dec         CONT_RTI
            rti        


; *****************************************************************************
;                           ATD0_ISR
; *****************************************************************************
ATD0_ISR:   loc
            ldd         ADR00H
            addd        ADR01H
            addd        ADR02H
            addd        ADR03H
            addd        ADR04H
            addd        ADR05H
            ldx         #6
            idiv
            tfr         X,D
            std         Nivel_PROM
            movb        #$80,ATD0CTL5


; *****************************************************************************
;                           SCI_ISR
; *****************************************************************************
SCI_ISR:    loc
            bset        SC1SR1,$80
            ldaa        SC1SR1
            ldx         Pointer0
            ldaa        0,X
            cmpa        #EOM
            beq         CHK_FLAG0`
            movb        1,X+,SC1DRL
            stx         Pointer0
            bra         return` 
CHK_FLAG0`
            ldaa        VOLUMEN
            brset       BANDERAS,$01,CHK_30pc`
            cmpa        #16
            bhi         CHK_90pc`
        ; Alarma activated
            bset        BANDERAS,$01
            movb        #1,PORTB
            bra         GO2PTR1`
CHK_30pc`
            cmpa        #32
            bls         GO2PTR1`
        ; Alarma deactivated
            bclr        BANDERAS,$01
            bra         CHK_90pc`
GO2PTR1`
            ldx         Pointer1
            ldaa        0,X
            cmpa        #EOM
            bne         INC_PTR1`
            bra         END_SC1`
GO2PTR2`
            ldx         Pointer2
            ldaa        0,X
            cmpa        #EOM
            beq         END_SC1`
            bset        BANDERAS,$02
            movb        #0,PORTB
            movb        1,X+,SC1DRL
            stx         Pointer2
            bra         return`
CHK_90pc`
            cmpa       #95
            beq        GO2PTR2`
            bclr       BANDERAS,$02
END_SC1`                
            movb        #$08,SC1CR2
return`
            rti

INC_PTR1`
            movb        1,X+,SC1DRL
            stx         Pointer1
            bra         return`