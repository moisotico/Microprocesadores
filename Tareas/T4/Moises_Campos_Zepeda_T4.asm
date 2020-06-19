; Moises Campos Zepeda
; 15-06-2020
; IE0623: Microprocesadores
; Tarea 4: teclado matricial


#include registers.inc

; *****************************************************************************
;                           Data Structures
; *****************************************************************************
CR:             equ         $0D
LF:             equ         $0A
FIN:            equ         $0

            org         $1000
; Size of Num_Array        
MAX_TCL:        db  #2
Tecla:          ds  1
Tecla_IN:       ds  1
Cont_Reb:       ds  1
Cont_TCL:       ds  1
Patron:         ds  1
Banderas:       ds  1

; Array of pressed buttons, by default $FF
Num_Array:      ds  6

; Key values  
Teclas:         db  $01,$02,$03,$04,$05,$06,$07,$08,$09,$0B,$0,$0E

            org         $1200

            ; DELETE OR COMMENT
MSG:           fcc "Numero: %X"
               fcb CR,LF,CR,LF,FIN

MSG2:       fcc "Cantidad de valores ingresados %i"
            fcb CR,CR,LF,FIN

MSG3:       fcc "%i, "
            fcb LF, FIN

MSG4:       fcc "%i"
            fcb CR,CR,LF,FIN



; *****************************************************************************
;                       Interruption Vector Relocation
; *****************************************************************************

            org        $3E70
            ;org        $FFF0
            dw      RTI_ISR

            org        $3E4C
            ;org        $FFCC
            dw      PHO_ISR



; *****************************************************************************
;                               HW Config
; *****************************************************************************
            org         $2000
        ; PHO
            bset        PIEH,$01
            bset        PIFH,$01
        ; Enable pullup resistors on Port A
            bset        PUCR,$01    
        ; RTI
            bset        CRGINT,$80
        ; Set imputs and outputs
            movb        #$F0, DDRA
        ; T = 11 ms 
            movb        $4A,RTICTL


; *****************************************************************************
;                               Main Program
; *****************************************************************************
            lds         #$3BFF

            movb        #$FF, TECLA
            movb        #$FF, TECLA_IN

            ldaa        MAX_TCL
            ldx         #Num_Array-1
LOOP_RST:
            movb        #$FF,A,X
            dbne        A,LOOP_RST
            
            clr         Cont_Reb
            clr         Cont_TCL
            clr         Patron
            clr         Banderas

MAIN_LOOP:
            brset       Banderas,$04,MAIN_LOOP
            jsr         TAREA_TECLADO
            bra         MAIN_LOOP
    
; *****************************************************************************
;                        TAREA_TECLADO Subroutine
; *****************************************************************************
TAREA_TECLADO:
            tst         Cont_Reb
            bne         RETURN_TT
            jsr         MUX_TECLADO

            ldaa        TECLA
            cmpa        #$FF
            beq         CHECK_LISTA

            brclr       Banderas,$02,REBOTES
            ldaa        TECLA
            ldab        TECLA_IN
            cba
            beq         TCL_LISTA
            movb        #$FF, TECLA
            movb        #$FF, TECLA_IN
            bclr        Banderas, $03
            jmp         RETURN_TT

TCL_LISTA:
        ; TCL_LISTA = 1
            bset        Banderas,$01
            jmp         RETURN_TT

REBOTES:
            movb        TECLA, TECLA_IN
        ; TCL_LEIDA = 1
            bset        Banderas,$02
            movb        #$0A, Cont_Reb
            jmp         RETURN_TT

CHECK_LISTA:
            brclr       Banderas,$01,RETURN_TT
            bclr        Banderas, $03
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
            ldaa        #$F0
            cmpa        Patron
            bne         READ_LOOP
        ; If no key was pressed
            movb        #$FF,Tecla
            rts

        ; If a key was pressed
WR_TECLA:
            movb        B,X,Tecla
        ; Print Tecla value
            ldab        Tecla
            clra
            ldx         #0
            pshd
            ldd         #MSG
            jsr         [PrintF,X]
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
            dec         Cont_TCL
            jmp         RETURN_FA

CHECK_E:
            cmpa        #$0E
            bne         RETURN_FA

COMPARE_E:
        ; ARRAY_OK = 1
            bset        Banderas,$04
           ; jsr         Print_Result
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
            movb        #$FF,TECLA_IN
            rts

; *****************************************************************************
;                           RTI_ISR Subroutine
; *****************************************************************************
RTI_ISR:    
            bset        CRGFLG, $80
            ldy         Cont_Reb
            cpy         #0
            beq         RETURN_RTI
            dec         Cont_Reb

RETURN_RTI:
            rti


; *****************************************************************************
;                           PHO_ISR Subroutine
; *****************************************************************************
PHO_ISR:
            ldx         #Num_Array
            bclr        Banderas, $04
            ldaa        MAX_TCL 
LOOP_P:       
            tsta
            beq         RETURN_PHO
            deca
            movb        #$FF,A,X
            jmp         LOOP_P

RETURN_PHO:
            rti