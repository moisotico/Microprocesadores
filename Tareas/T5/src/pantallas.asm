; Moises Campos Zepeda
; 15-06-2020
; IE0623: Microprocesadores
; Tarea 5: Pantallas

#include registers.inc

; *****************************************************************************
;                           Data Structures
; *****************************************************************************
CR:             equ $0D
LF:             equ $0A
FIN:            equ $0

            org         $1000
; Size of Num_Array        
Banderas:       ds  1
MAX_TCL:        db  2
Tecla:          ds  1
Tecla_IN:       ds  1
Cont_Reb:       ds  1
Cont_TCL:       ds  1
Patron:         ds  1

; Array of pressed buttons, by default $FF
Num_Array:      ds  2

CUENTA:         ds  1
AcmPQ:          ds  1
CantPQ:         ds  1
TIMER_CUENTA:   ds  1
LEDS:           ds  1
BRILLO:         ds  1
CONT_DIG:       ds  1
CONT_TICKS:     ds  1
DT:             ds  1
BIN1:           ds  1
BIN2:           ds  1
BCD_L:          ds  1
LOW:            ds  1
TEMP:           ds  1
BCD1            ds  1
BCD2            ds  1
DISP1           ds  1
DISP2           ds  1
DISP3           ds  1
DISP4           ds  1
CONT_7SEG       ds  1
Cont_Delay      ds  1
; TODO
;D2mS            db  1
;D260uS          db  1
;D40uS           db  1
;Clear_LCD       db  1
;ADD_L1          db  1
;ADD_L2          db  1


; Key values  
            org     $1030
Teclas:         db  $01,$02,$03,$04,$05,$06,$07,$08,$09,$0B,$00,$0E

            org     $1040
        ; 0, 1, ..., 9     
 SEGMENT:       db  $3F,$06,$5B,$4F,$66,$6D,$7D,$07,$7F,$6F

; TODO: org     $1050
; iniDisp Array


            org         $1060

            ; DELETE OR COMMENT

MSG0:          fcc "Numero a en array: %X"
               fcb CR,LF,CR,LF,FIN

MSG1:          fcc "MODO CONFIG"
               fcb CR,LF,CR,LF,FIN 

MSG2:          fcc "INGRSE CantPQ"
                db CR,LF,CR,LF,FIN
 
MSG3:          fcc "MODO RUN"
                db CR,LF,CR,LF,FIN               

MSG4:          fcc "AcmPQ CUENTA"
                db CR,LF,CR,LF,FIN               


; *****************************************************************************
;                       Interruption Vector Relocation
; *****************************************************************************

            org             $3E70
            dw      RTI_ISR
            org             $3E4C
            dw      PTH_ISR



; *****************************************************************************
;                               HW Config
; *****************************************************************************
            org             $2000

        ; LEDS
            bset        PTJ,$02
            movb        #$0F,DDRP
            bset        PTP,$0F
            movb        #$FF,DDRB

        ; Ctrl registers and timer enable
            bset        TSCR1,$90 
            bset        TSCR2,$04
            bset        TIOS,$20
            bset        TIE,$20
            bset        TCTL1,$0

        ; Key wakeup PTH
            bset        PIEH,$01          
            bset        PIFH,$0F
        ; RTI @ 1,027 ms
            movb        #$17, RTICTL       
            bset        CRGINT,$80
        ; PORTA + Pullup resistors     
            movb        #$F0,DDRA
            bset        PUCR,$01
        ;Port E relay
            bset        DDRE,$04
        ; Enable masked interruptions
            cli

; *****************************************************************************
;                               Main Program
; *****************************************************************************
            lds         #$3BFF
            movb        #$FF, Tecla
            movb        #$FF, Tecla_IN
            ldaa        MAX_TCL
            ldx         #Num_Array-1
ARRAY_RST:
            movb        #$FF,A,X
            dbne        A,ARRAY_RST
            
            clr         Cont_Reb
            clr         Cont_TCL
            clr         Patron
            clr         Banderas

MAIN_LOOP:
            brset       Banderas,$04,MAIN_LOOP
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
            jsr         TAREA_TECLADO
            bra         MAIN_LOOP
    
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
            clra
            pshd
            ldx         #0
            ldd         #MSG1
            jsr         [PrintF,X]
            leas        2,SP
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
            dec         Cont_TCL
            jmp         RETURN_FA

CHECK_E:
            cmpa        #$0E
            bne         RETURN_FA

COMPARE_E:
        ; ARRAY_OK = 1
            bset        Banderas,$04
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
;                           Subrutine  BCD_BIN
; *****************************************************************************
BCD_BIN:
    ; Decimal 4 bits
            ldab        Num_Array
            ldaa        #10
            mul
            addd        Num_Array+1
            std         CantPQ
    ; End of subroutine
            rts


; ************************************ISR*************************************

; *****************************************************************************
;                           PHO_ISR Subroutine
; *****************************************************************************
PTH_ISR:
            brset       PIFH,$01,PH0
            brset       PIFH,$02,PH1
            brset       PIFH,$04,PH2
            brset       PIFH,$08,PH3
            bra         RETURN_PTH
PH0:
            bset        PIFH,$01
            brclr       Cont_Reb,$FF,RETURN_PTH
            clr         CUENTA
            movb        #25,Cont_Reb
            ;stop relay
            bclr        PORTE,$04
            bra         RETURN_PTH
PH1:
            bset        PIFH,$02
            brclr       Cont_Reb,$FF,RETURN_PTH
            clr         AcmPQ
            movb        #25,Cont_Reb
            ;stop relay
            bclr        PORTE,$04
            bra         RETURN_PTH
PH2:
            bset        PIFH,$04
            ldaa        BRILLO
            bls         RETURN_PTH
            suba        #5
            staa        BRILLO
            bra         RETURN_PTH
PH3:
            bset        PIFH,$08
            ldaa        BRILLO
            cmpa        #100
            bhs         RETURN_PTH
            adda        #5
            staa        BRILLO
            bra         RETURN_PTH
RETURN_PTH:
            rti


; *****************************************************************************
;                           RTI_ISR Subroutine
; *****************************************************************************
RTI_ISR:
            loc
            bset        CRGFLG,$80
            tst         Cont_Reb
            beq         RETURN`
            dec         Cont_Reb
RETURN`:
            rti