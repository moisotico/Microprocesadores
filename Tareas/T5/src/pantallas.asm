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
CONT_7SEG       ds  2
Cont_Delay      ds  1
D2mS            db  100
D240uS          db  12
D60uS           db  3
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


            org     $1060

            ; DELETE OR COMMENT

MSGA:          fcc "Key Received!"
               fcb CR,LF,CR,LF,FIN

MSG0:          fcc "There's a mistake on PTH!"
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
             org            $3E66
            dw      OC4_ISR


; *****************************************************************************
;                               HW Config
; *****************************************************************************
            org             $2000
        ; PORTS
            bset        DDRJ,$02
            bset        PTJ,$02
            movb        #$0F,DDRP
            movb        #$0F,PTP
            movb        #$FF,DDRB
            movb        #$F0,DDRA
        ;Port E relay
            bset        DDRE,$04
        ; Key wakeup PTH
            bset        PIEH,$0C          
            bset        PIFH,$0F
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
            movb        #$FF,DDRK

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
            bset        PTIH,$80
            clr         CONT_TICKS
            clr         CONT_DIG
            movb        #50,BRILLO
            movb        #$FF,Tecla
            movb        #$FF,Tecla_IN
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
            ldaa        PTIH
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
            ldaa        PTIH
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
            movb        #1,LEDS
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
;                        MODO_CONFIG Subroutine
; *****************************************************************************
MODO_CONFIG:
            loc
            bclr        PIEH,$03
            brclr       BANDERAS,$04,GO2TAREATECLADO
            jsr         BCD_BIN
            bclr        BANDERAS,$04
            ldaa        CantPQ
            cmpa        #90
            bgt         resetCantPQ`
            cmpa        #20
            blt         resetCantPQ`
            movb        CantPQ,BIN1
            movb        #0,BIN2
            bra         return`
GO2TAREATECLADO:
            jsr         TAREA_TECLADO
            bra         return`
resetCantPQ`:
            clr         CantPQ
return`:
            rts


; *****************************************************************************
;                        MODO_RUN Subroutine
; *****************************************************************************
MODO_RUN:   
            loc    
            bset        PIEH,$03
            ldaa        CantPQ
            cmpa        CUENTA
            beq         return`
            tst         TIMER_CUENTA
            bne         return`
            movb        CantPQ,TIMER_CUENTA
            inc         CUENTA
            cmpa        CUENTA
            bne         return`
            inc         AcmPQ
            bset        PORTE,$04
            ldaa        AcmPQ
            cmpa        #100
            bne         return`
            movb        #0,AcmPQ
return`:
            movb         CUENTA,BIN1
            movb         AcmPQ,BIN2
            rts

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
            stab        CantPQ
            bra         return`
wrong`
            movb        #$FF,NUM_ARRAY
            movb        #$0,CantPQ
return`
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
            movb        #0,DT
            jmp         BIN_BCD
RETURN1:
            movb        BCD_L,BCD1
            ldaa        BIN2
            movb        #1,DT
            jmp         BIN_BCD
RETURN2:
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
            ldaa        TEMP
            tsta
            beq         RETURN1
            bra         RETURN2                  


; *****************************************************************************
;                           Cargar_LCD Subrutine
; *****************************************************************************
CARGAR_LCD: 
            loc
            pshx        
        ;  TODO: PRINT     
            ldx         #iniDisp
            ldab        #4
loop1`:
            ldaa        1,X+
            clr         SendData
            jsr         SEND
            movb        D40uS,Cont_Delay
            jsr         Delay
            dbne        B,loop1`
            ldaa        Clear_LCD
            jsr         SEND
            movb        D2mS,Cont_Delay
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
            jsr         SEND
            movb        D40us,Cont_Delay
            jsr         Delay
loop3`:
            ldaa        1,Y+
            cmpa        #FIN
            beq         return`
            movb        #1,SendData
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
merge2`:
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
            ldx         #0
            ldd         #MSG0
            jsr         [PrintF,X]
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
RETURN_PTH:
            rti


; *****************************************************************************
;                           RTI_ISR Subroutine
; *****************************************************************************
RTI_ISR:
            loc
            bset        CRGFLG,$80
            tst         Cont_Reb
            beq         CHK_TCOUNT
            dec         Cont_Reb
CHK_TCOUNT:
            tst         TIMER_CUENTA
            beq         RETURN`
            dec         TIMER_CUENTA
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
            beq         OFF`
            tst         CONT_TICKS
            beq         check_digit`
CHECK_N`         
            cmpa        #100
            beq         CHANGE_DIG`
INC_TICKS`
            inc         CONT_TICKS
            jmp         CHK_DELAY
;OFF
OFF`
            movb        #$FF,PTP
            movb        #$0, PORTB
            bra         CHECK_N`
CHANGE_DIG`
            movb        #$0,CONT_TICKS
            ldaa        #5
            cmpa        CONT_DIG
            bne         GO2_CHK_DELAY 
            clr         CONT_DIG
GO2_CHK_DELAY
            inc         CONT_DIG
            bra         CHK_DELAY
check_digit`
            ldaa        CONT_DIG
            cmpa        #1
            bne         dig2`
            bclr        PTP, $08
            movb        DISP1, PORTB
            bset        PTJ, $02
            bra         INC_TICKS`
dig2`
            cmpa        #2
            bne         dig3`
            bclr        PTP, $04
            ldaa        DISP2
            cmpa        #$3F
            beq         INC_TICKS`
            movb        DISP2, PORTB
            bset        PTJ, $02
            bra         INC_TICKS`
dig3`
            cmpa        #3
            bne         dig4`
            bclr        PTP, $02                
            brset       BANDERAS,$08,INC_TICKS`
            movb        DISP3, PORTB
            bset        PTJ, $02
            bra         INC_TICKS`
dig4`
            cmpa        #4
            bne         digleds`
            bclr        PTP, $01
            brset       BANDERAS,$08,negdig4`
            ldaa        DISP4
            cmpa        #$3F
            beq         negdig4`
            movb        DISP4, PORTB
            bset        PTJ, $02
negdig4`
            jmp         INC_TICKS`
digleds`
            movb        LEDS, PORTB
            bclr        PTJ, $02
            inc         CONT_TICKS

CHK_DELAY
            tst         CONT_DELAY
            beq         chk7seg`
            dec         CONT_DELAY
chk7seg`
            ldx         CONT_7SEG
            beq         JBCD_7SEG`
            dex
            stx         CONT_7SEG
RETURN`
            ldd         TCNT
            addd        #60
            std         TC4
            rti
JBCD_7SEG`
            movw        #5000,CONT_7SEG
            jsr         BCD_7SEG
            bra         RETURN`