
; Moises Campos Zepeda
; 13-11-2020
; IE0623: Microprocesadores
; Tarea 6: Control ON/OFF de Tanque de almacenamiento de Agua

; Include File
#include registers.inc

; *****************************************************************************
;                           Data Structures
; *****************************************************************************
CR:             equ $0D
LF:             equ $0A
EOM:            equ $FF
SUB:            equ $1A
BS:             equ $08

            org             $1000
Pointer0:       ds  2 
            org             $1010
Nivel_PROM:     ds  2
NIVEL:          ds  1
; Vaue to send to terminal
VOLUMEN:        ds  1
CONT_RTI:       ds  1
;2: Msg completado, 1: Vaciado activated, 0: Alarma activated 
BANDERAS:       ds  1



MSG:        fcb SUB
            fcc "                           UNIVERSIDAD DE COSTA RICA"
            fcb CR,LF
            fcc "                        Escuela de Ingenieria Electrica"
            fcb CR,LF
            fcc "                              Microprocesadores"
            fcb CR,LF
            fcc "                                   IE0623"
            fcb CR,LF
            fcc "              Volumen Calculado: "
V_ASCII:
            fcb 45,45,45,CR
            fcb EOM

A_MSG:      fcb CR,LF
            fcc "              Alarma: El Nivel esta Bajo! "
            fcb CR,LF
            db  EOM

V_MSG:      fcb CR,LF
            fcc "              Tanque vaciando, Bomba Apagada!"
            fcb CR,LF
            db  EOM

ERASE:      db BS,BS,BS,EOM            

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
        ; Clean
            clr         BANDERAS
            clr         CONT_RTI
            clr         VOLUMEN
            clr         NIVEL
            clr         Nivel_PROM
            clr         Pointer0
        ;ATD
            movb        #$C2,ATD0CTL2
        ; Wait around 10 ms
            ldaa        #200
WAIT_ATD:
            dbne        A,WAIT_ATD
NEXT_ATD:
            movb        #$30,ATD0CTL3
            movb        #$10,ATD0CTL4
            movb        #$80,ATD0CTL5
        ;SCI 1
            movb        #$27,SC1BDH
            movb        #0,SC1CR1
            movb        #$88,SC1CR2
        ;RTI
            bset        CRGINT,$80
            movb        #$54,RTICTL
        ;LEDs
            bset        DDRB,$01
            bset        DDRJ,$02
            bclr        PTJ,$01
            lds         #$4000
            cli
            movw        #MSG,Pointer0
            ldaa        SC1SR1
            wai
CHK_CALC:
            jsr         CALCULO
            nop
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
            stab        V_ASCII
            ldx         #10
            puld
            idiv
            addb        #$30
            stab        V_ASCII+2
            tfr         X,D
            addb        #$30
            stab        V_ASCII+1
            rts

; ************************************ISR*************************************

; *****************************************************************************
;                           RTI_ISR
; *****************************************************************************
RTI_ISR:    loc
            bset        CRGFLG,$80
            tst         CONT_RTI
            bne         return`
            brclr       BANDERAS,$08,NEXT`
            bclr        BANDERAS,$08
            movb        #$88,SC1CR2
NEXT`
            movb        #100,CONT_RTI
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
            stx         Nivel_PROM
            movb        #$80,ATD0CTL5
            rti

; *****************************************************************************
;                           SCI_ISR
; *****************************************************************************
SCI_ISR:    loc
            ldaa        SC1SR1
            ldx         Pointer0
            ldaa        1,X+
            cmpa        #EOM
            beq         ALRM_CHK`
            staa        SC1DRL
            stx         Pointer0
            bra         return`   
ALRM_CHK`
            ldaa        VOLUMEN
            brset       BANDERAS,$04,clear`
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
            movw        #A_MSG,Pointer0
            bset        Banderas,$04
            bra         return`
GO2PTR2`
            movw        #V_MSG,Pointer0
            bset        BANDERAS,$02
            bset        Banderas,$04
            bclr        PORTB,$01
            bra         return`
CHK_90pc`
            cmpa       #95
            bhi        GO2PTR2`
            bclr       BANDERAS,$02
            bset       Banderas,$04
return`
            rti
clear`
            movw       #MSG,Pointer0
            bclr       Banderas,$04
            bset       Banderas,$08
            movb       #$08,SC1CR2
            bra        return`