; Moises Campos Zepeda
; 15-06-2020
; IE0623: Microprocesadores
; Proyecto Final: Selector 623
#include registers.inc

; *****************************************************************************
; *                           Data Structures                                 *
; *****************************************************************************
CR:             equ $0D
LF:             equ $0A
FIN:            equ $0

            org         $1000
    ;-- BANDERAS
BANDERA:        ds  2
    ;-- MODO_CONFIG       
LenghtOK:       ds  1
ValorLenght:    ds  1
    ;-- TAREA_TECLADO
MAX_TCL:        db  2
Tecla:          ds  1
Tecla_IN:       ds  1
Cont_Reb:       ds  1
Cont_TCL:       ds  1
Patron:         ds  1
Num_Array:      ds  2
    ;-- ATD_ISR
BRILLO:         ds  1
POT:            ds  1
    ;-- PANT_CTRL
TICK_EN:        ds  2           
TICK_DIS:       ds  2
CONT_ROC        ds  1
    ;-- CALCULAR           
VELOC:          ds  1
LONG:           ds  1
    ;-- TCNT_ISR
TICK_MED:       ds  2
    ;-- CONV_BIN_BCD
BIN1:           ds  1
BIN2:           ds  1
BCD1:           ds  1
BCD2:           ds  1
    ;-- BIN_BCD
BCD_L:          ds  1
BCD_H:          ds  1
TEMP:           ds  1
LOW:            ds  1
    ;-- BCD_7SEG
DISP1:          ds  1
DISP2:          ds  1
DISP3:          ds  1
DISP4:          ds  1
    ;-- OC4_ISR
LEDS:           ds  1
CONT_DIG:       ds  1
CONT_TICKS:     ds  1
DT:             ds  1
CONT_7SEG:      ds  2
CONT_200:       ds  1
    ;--SUBRUTINAS_LCD
Cont_Delay:     ds  1
D2mS:           db  100
D240uS:         db  12
D60uS:          db  3
Clear_LCD       db  $01
ADD_L1          db  $80
ADD_L2          db  $C0


            org         $1040
Teclas:         db  $01,$02,$03,$04,$05,$06,$07,$08,$09,$0B,$00,$0E
            org         $1050
SEGMENT:        db  $3F,$06,$5B,$4F,$66,$6D,$7D,$07,$7F,$6F
            org         $1060
iniDisp:        db  $28,$28,$06,$0C

            org     $1070

MSG1:          fcc "Key Received!"
               fcb CR,LF,CR,LF,FI

; *****************************************************************************
;                       Interruption Vector Relocation
; *****************************************************************************


; *****************************************************************************
; *                          Main Program                                     *
; *****************************************************************************

; *****************************************************************************
;                        TAREA_TECLADO Subroutine
; *****************************************************************************
TAREA_TECLADO:
            tst         Cont_Reb
            bne         RETURN_TT
        ;Go to MUX_TECLADO    
            jsr         MUX_TECLADO
            ldaa        Tecla
            cmpa        #$FF
            beq         CHECK_ARRAY
            brclr       Banderas,$02,REBOTES
            cmpa        Tecla_IN
            bne         TCL_NOT_READY
        ; TCL_LISTA = 1
            bset        Banderas,$01
            bra         RETURN_TT

TCL_NOT_READY:
            movb        #$FF,Tecla
            movb        #$FF,Tecla_IN
            bclr        Banderas,$03
            bra         RETURN_TT

REBOTES:
            movb        Tecla,Tecla_IN
        ; TCL_LEIDA = 1
            bset        Banderas,$02
            movb        #10,Cont_Reb
            bra         RETURN_TT

CHECK_ARRAY:
            brclr       Banderas,$01,RETURN_TT
            bclr        Banderas,$03
            ; Print Tecla value
            ldab        Tecla_IN
            cmpb        #$FF
            beq         RETURN_TT
            ldx         #0
            ldd         #MSGA
            jsr         [PrintF,X]
            jsr         FORMAR_ARRAY

RETURN_TT:      
            rts            
         
; *****************************************************************************
;                        MUX_TECLADO Subroutine
; *****************************************************************************
MUX_TECLADO:
            clrb
            ldx         #Teclas
            movb        #$EF,Patron

READ_LOOP:
            movb        Patron, PORTA
            nop
            nop
            nop
            nop
            nop
            nop
            nop
            nop
            nop
            nop
        ; check col 0 of port A
            brclr       PORTA,$01,WR_TECLA
            incb
        ; check col 0 of port A
            brclr       PORTA,$02,WR_TECLA
            incb
        ; check col 0 of port A
            brclr       PORTA,$04,WR_TECLA
            incb
            lsl         Patron
            ldaa        Patron
            cmpa        #$F0
            bne         READ_LOOP
        ; If no key was pressed
            movb        #$FF,TECLA
            bra         RETURN_MUX

        ; If a key was pressed
WR_TECLA:
            movb        B,X,Tecla
RETURN_MUX:
            rts


; *****************************************************************************
;                        FORMAR_ARRAY Subroutine
; *****************************************************************************
FORMAR_ARRAY:
            ldx         #Num_Array
            ldaa        TECLA_IN
            ldab        Cont_TCL
        
        ; check for full array   
            cmpb        MAX_TCL
            beq         CHECK_B
            cmpb        #0
            beq         CATCH_EORB
            cmpa        #$0B
            beq         COMPARE_B
            cmpa        #$0E
            beq         COMPARE_E
            jmp         ADD_ARRAY

CHECK_B:
            cmpa        #$0B
            bne         CHECK_E

COMPARE_B:
            decb
            stab        Cont_TCL
            movb        #$FF,B,X
            jmp         RETURN_FA

CHECK_E:
            cmpa        #$0E
            bne         RETURN_FA

COMPARE_E:
        ; ARRAY_OK = 1
            bset        Banderas,$04
        ; Print Array ok
            ldx         #0
            ldd         #MSG1
            jsr         [PrintF,X]
            clr         Cont_TCL
            jmp         RETURN_FA

CATCH_EORB:
        ; catch B
            cmpa        #$0B
            beq         RETURN_FA
        ; catch E
            cmpa        #$0E
            beq         RETURN_FA

ADD_ARRAY:
            staa        B,X
            inc         Cont_TCL

RETURN_FA
            rts


; *****************************************************************************
;                            BCD_BIN Subrutine
; *****************************************************************************
;       BCD_BIN
BCD_BIN:        
            loc
            ldx         #NUM_ARRAY
            ldaa        1,X
            cmpa        #$FF
        ;Check for $FF
            beq         wrong`
            ldaa        #0
loop`
            cmpa        #0
            beq         mul10`
            addb        A,X    
            bra         sumA`
mul10`
            ldab        A,X
            lslb
            lslb
        ;mult by 8
            lslb        
            addb        A,X
        ;mult by 10
            addb        A,X    
sumA`
            movb        #$FF,A,X
            inca
            cmpa        MAX_TCL
            bne         loop`
            stab        CPROG 
            bra         return`
wrong`
            movb        #$FF,NUM_ARRAY
            movb        #$0,CPROG
return`
            rts

; *****************************************************************************
;                           OC4_ISR Subroutine
; *****************************************************************************            
OC4_ISR:
            loc
            ldaa        CONT_TICKS
            ldab        #100
            subb        BRILLO
            cba
            beq         apagar`
            tst         CONT_TICKS
            beq         check_digit`
checkN`         
            cmpa        #100
            beq         changeDigit`
incticks`
            inc         CONT_TICKS
            jmp         part2`
;Apagar
apagar`
            movb        #$FF,PTP
            movb        #$0, PORTB
            bra         checkN`
changeDigit`
            movb        #$0,CONT_TICKS
            ldaa        #5
            cmpa        CONT_DIG
            bne         jpart2` 
            clr         CONT_DIG
jpart2`
            inc         CONT_DIG
            bra         part2`
check_digit`
            ldaa        CONT_DIG
            cmpa        #1
            bne         dig2`
            bclr        PTP, $08
            movb        DISP1, PORTB
            bset        PTJ, $02
            bra         incticks`
dig2`
            cmpa        #2
            bne         dig3`
            bclr        PTP, $04
            ldaa        DISP2
            cmpa        #$3F
            beq         ndig2`
            movb        DISP2, PORTB
            bset        PTJ, $02
ndig2`
            bra         incticks`
dig3`
            cmpa        #3
            bne         dig4`
            bclr        PTP, $02                
            brset       BANDERAS,$08,ndig3`
            movb        DISP3, PORTB
            bset        PTJ, $02
ndig3`
            bra         incticks`
dig4`
            cmpa        #4
            bne         digleds`
            bclr        PTP, $01
            brset       BANDERAS,$08,ndig4`
            ldaa        DISP4
            cmpa        #$3F
            beq         ndig4`
            movb        DISP4, PORTB
            bset        PTJ, $02
ndig4`
            jmp         incticks`
digleds`
            movb        LEDS, PORTB
            bclr        PTJ, $02
            inc         CONT_TICKS

part2`
            tst         CONT_DELAY
            beq         tst7seg`
            dec         CONT_DELAY
tst7seg`
            ldx         CONT_7SEG
            beq         JBCD_7SEG`
            dex
            stx         CONT_7SEG
returnOC4
            ldd         TCNT
            addd        #60
            std         TC4
            rti
JBCD_7SEG`
            movw        #5000,CONT_7SEG
            jsr         BCD_7SEG
            bra         returnOC4