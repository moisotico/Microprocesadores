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
D2mS            db  1
D260uS          db  13
D40uS           db  3
Clear_LCD       db  $01
ADD_L1          db  $80
ADD_L2          db  $C0
SendData:       ds  1


; Key values  
            org     $1030
Teclas:         db  $01,$02,$03,$04,$05,$06,$07,$08,$09,$0B,$00,$0E

            org     $1040
SEGMENT:       db  $3F,$06,$5B,$4F,$66,$6D,$7D,$07,$7F,$6F

            org     $1050
;   Number of bytes, 2*function set, Entry mode set, display on            
iniDisp:        db  $28,$28,$06,$0C 


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

        ; PORTS
            bset        PTJ,$02
            movb        #$0F,DDRP
            bset        PTP,$0F
            movb        #$FF,DDRB
            movb        #$F0,DDRA
        ;Port E relay
            bset        DDRE,$04
        ; Key wakeup PTH
            bset        PIEH,$0F          
            bset        PIFH,$0C
        ; RTI @ 1,027 ms
            movb        #$17, RTICTL       
            bset        CRGINT,$80
        ; Enable masked interruptions
            cli

        ; Ctrl registers and timer enable
            bset        TSCR1,$90 
            bset        TSCR2,$03
            bset        TIOS,$10
            bset        TIE,$10
            bset        TCTL1,$01
            bset        TCTL2,$00
            ldd         TCNT
            addd        #60
            std         TC4
            movb        #$FF,DDR4

        ; PORTA + Pullup resistors     
            movb        #$F0,DDRA
            bset        PUCR,$01

; *****************************************************************************
;                               Main Program
; *****************************************************************************
            lds         #$3BFF
            clr         BCD1
            clr         BCD2
            clr         BIN1
            clr         BIN2
            clr         LEDS
            clr         DISP1
            clr         DISP2
            clr         DISP3
            clr         DISP4
            bset        PITH,$80
            clr         CONT_TICKS
            clr         CONT_DIG
            movb        #50,BRILLO
            movb        #$FF, Tecla
            movb        #$FF, Tecla_IN
            clr         Cont_Reb
            clr         Cont_TCL
            clr         Patron
            clr         BANDERAS
            bset        BANDERAS,$10
            ldaa        MAX_TCL
            ldx         #Num_Array-1
ARRAY_RST:
            movb        #$FF,A,X
            dbne        A,ARRAY_RST   
MAIN_LOOP:
            tst         CantPQ
            beq         SET_MOD
            ldaa        PITH
            anda        #$80
            lsra
            lsra
            lsra
            lsra
            ldab        BANDERAS
            andb        #$08
            cba
            beq         CHK_MODSEL
            bset        BANDERAS,$10
            tstb
            bne         SET_FLG3
            bclr        BANDERAS,$08
            bra         CHK_MODSEL
SET_FLG3:   
            bset        BANDERAS,$08
CHK_MODSEL:
            ldaa        PITH
            cmpa        #$80
            beq         CHK_CAMBMOD
        ; check CambMod flag             
            ldab        BANDERAS
            cmpb        #$10
            bne         GO2RUN
            bclr        BANDERAS,$10
            bset        PIEH,$03
            ldx         MSG3
            ldy         MSG4
            jsr         CARGAR_LCD
GO2RUN:
            jsr         MODO_RUN
            bra         MAIN_LOOP              
            
SET_MOD:
            bset        BANDERAS,$08
CHK_CAMBMOD:
            ldab        BANDERAS
            cmpb        #$10
            bne         GO2CONFIG
            bclr        BANDERAS,$10
            clr         CUENTA
            clr         AcmPQ
            bclr        PIEH,$03
            ldx         MSG1
            ldy         MSG2
            movb        #2,LEDS
            jsr         CARGAR_LCD

GO2CONFIG:
            jsr         MODO_CONFIG
            bra         MAIN_LOOP


; *****************************************************************************
;                        MODO_RUN Subroutine
; *****************************************************************************

; *****************************************************************************
;                        MODO_CONFIG Subroutine
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
;                            BCD_BIN Subrutine
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


; *****************************************************************************
;                            BCD_7SEG Subrutine
; *****************************************************************************
BCD_7SEG:       
            loc
            ldx         #SEGMENT
            ldy         #DISP1
            clra
            ldab        BCD1
            bra set_disps`
loadBCD2`:
            ldab        BCD2
set_disps`:
            pshb 
            andb        #$0F
        ; move lower bcd to disp1 or disp 3
            movb        B,X,1,Y+      
            pulb 
            lsrb
            lsrb
            lsrb
            lsrb
        ; move lower bcd to disp2 or disp4
            movb        B,X,1,Y+     
        ;check DISP3    
            cpy         #DISP3
            beq         loadBCD2`
return`:
            rts


; *****************************************************************************
;                            CONV_BIN_BCD Subrutine
; *****************************************************************************
CONV_BIN_BCD:
            loc
            ldaa        BIN1
            jsr         BIN_BCD
            movb        BCD_L,BCD1
            ldaa        BIN2
            bra         BIN_BCD
            movb        BCD_L,BCD2
            rts


; *****************************************************************************
;                            BIN_BCD Subrutine
; *****************************************************************************
BIN_BCD:    
            loc
            ldab        #3
            clr         BCD_L
loop1`:            
            lsla
            rol         BCD_L
            staa        TEMP
            ldaa        BCD_L
            anda        #$0F
            cmpa        #5
            bcs         to_low`
            adda        #3
to_low`:    
            staa        LOW
            ldaa        BCD_L
            anda        #$F0
            cmpa        #$50
            bcs         next`
            adda        #$30
next`:
            adda        LOW
            staa        BCD_L
            ldaa        TEMP
            dbne        B,loop1`
        ; exit
            lsla
            rol         BCD_L
            rts


; *****************************************************************************
;                           Cargar_LCD Subrutine
; *****************************************************************************
CARGAR_LCD: 
            loc
            pshx
            ldx         iniDisp
loop1`:
            ldaa        0,X
            clr         SendData
            jsr         SEND
            movb        D40uS,Cont_Delay
            jsr         Delay
            cmpa        #$0C
            bne         loop1`
            ldaa        Clear_LCD
            jsr         SEND
            movb        D2uS,Cont_Delay
            jsr         Delay
        ; LINE1    
            pulx
            ldaa        ADD_L1
            movb        #1,SendData
            jsr         SEND
            movb        D40uS,Cont_Delay
            jsr         Delay
loop2`:
            ldaa        1,X+
            cmpa        #FIN
            beq         LINE2`
            jsr         SEND
            movb        D40uS,Cont_Delay
            jsr         Delay
            bra         loop2`
LINE2`:
            ldaa        ADD_L2
            movb        #1,SendData
            jsr         send
            movb        d40us,cont_delay
            jsr         delay
loop3`:
            ldaa        1,Y+
            cmpa        #FIN
            beq         return`
            jsr         SEND
            movb        D40uS,Cont_Delay
            jsr         Delay
            bra         loop3`
return`:
            rts
            


; *****************************************************************************
;                            Delay Subrutine
; *****************************************************************************
Delay:
            tst         Cont_Delay
            bne         Delay
            rts


; *****************************************************************************
;                            SEND Subrutine
; *****************************************************************************
SEND:       loc
            psha
            anda        #$F0
            lsra
            lsra
            staa        PORTK
            tst         SendData
            beq         clearK1`
            bset        PORTK,$01
merge1`:
            bset        PORTK,$02
            movb        D260uS,Cont_Delay
            jsr         Delay
            bclr        PORTK,$02
        ; lower nibble    
            pula
            anda        #$0F
            lsla
            lsla
            staa        PORTK
            tst         SendData
            beq         clearK2`
            bset        PORTK,$01
loop2`:
            bset        PORTK,$02
            movb        D260uS,Cont_Delay
            jsr         Delay
            bclr        PORTK,$02
            rts

clearK1`:
            bclr        PORTK,$01
            bra         merge1`
clearK2`:
            bclr        PORTK,$01
            bra         merge2`


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

; *****************************************************************************
;                           OC4_ISR Subroutine
; *****************************************************************************
OC4_ISR:
            loc
            ldaa        CONT_TICKS
            ldab        #100
            subb        BRILLO
            cba
            bne         NO_TICKS
            bset        PTP,$FF
            bclr        PORTB,$FF
            bra         TOP_TICKS
NO_TICKS:
            tst         CONT_TICKS
            beq         CHK_DIGTS
TOP_TICKS:  
            ldaa        CONT_TICKS
            ldab        #100
            cba
            beq         INC_CD
            inc         CONT_TICKS
CHK_7SEG:
            tst         CONT_7SEG
            bne         CHK_DELAY
            jsr         CONV_BIN_BCD
            jsr         BCD_7SEG
CHK_DELAY:
            tst         Cont_Delay
            beq         RETURN`
            dec         Cont_Delay
RETURN`:
            rti

INC_CD:
            inc         CONT_DIG
            clr         CONT_TICKS
            bra         CHK_7SEG
CHK_DIGTS:
            ldaa        CONT_DIG
            cmpa        #1
            bne         DIG2
            bclr        PTP,$08
            bset        PTJ,$02
            movb        DISP1,PORTB
            bra         RESUME_TCKS       
DIG2:
            cmpa        #2
            bne         DIG3
            ldab        DISP2
            cmpb        #$3F
            beq         RESUME_TCKS
            bclr        PTP,$04
            bset        PTJ,$02
            movb        DISP2,PORTB
            bra         RESUME_TCKS
DIG3:
            cmpa        #3
            bne         DIG4
        ; (MODOACTUAL = 1 , Modo Config)
            brset       BANDERAS,$08,RESUME_TCKS
            bclr        PTP,$02
            bset        PTJ,$02
            movb        DISP3,PORTB
            bra         RESUME_TCKS
DIG4:
            cmpa        #4
            bne         ENB_LEDS
            ldab        DISP4
            cmpb        #$3F
            beq         RESUME_TCKS
            bclr        PTP,$01
            bset        PTJ,$02
            movb        DISP4,PORTB
            bra         RESUME_TCKS
ENB_LEDS:
            bclr        PTJ,$01
            movb        LEDS,PORTB
RESUME_TCKS:
            inc         CONT_TICKS
            bra         CHK_7SEG
            