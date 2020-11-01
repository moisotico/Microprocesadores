; Moises Campos Zepeda
; 02-10-2020
; IE0623: Microprocesadores
; Tarea 5: Pantallas
#include registers.inc

; *****************************************************************************
;                           Data Structures
; *****************************************************************************
CR:             equ $0D
LF:             equ $0A
FIN:            equ $0
VMAX:           equ $FA ;#250 for 3HZ

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
BCD1:           ds  1
BCD2:           ds  1
DISP1:          ds  1
DISP2:          ds  1
DISP3:          ds  1
DISP4:          ds  1
CONT_7SEG:      ds  2
Cont_Delay:     ds  1
D2mS:           db  100
D260uS:         db  13
D40uS:          db  2
Clear_LCD:      db  $01
ADD_L1:         db  $80
ADD_L2:         db  $C0
SendData:       ds  1
BIN_NUM:        ds  1


; Key values  
            org     $1030
Teclas:         db  $01,$02,$03,$04,$05,$06,$07,$08,$09,$0B,$00,$0E

            org     $1040
SEGMENT:        db  $3F,$06,$5B,$4F,$66,$6D,$7D,$07,$7F,$6F

            org     $1050
;   Number of bytes, 2*function set, Entry mode set, display on            
iniDisp:        db  $28,$28,$06,$0C 


            org     $1060

            ; DELETE OR COMMENT

MSGA:       fcc "Key Received!"
            fcb CR,LF,CR,LF,FIN

MSG0:       fcc "Tecla: %X"
            fcb CR,LF,CR,LF,FIN

MSG1:       fcc "MODO CONFIG"
            fcb CR,LF,CR,LF,FIN 

MSG2:       fcc "INGRSE CantPQ"
            db CR,LF,CR,LF,FIN
 
MSG3:       fcc "MODO RUN"
            db CR,LF,CR,LF,FIN               

MSG4:       fcc "AcmPQ CUENTA"
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
            org            $2000
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
            movb        #$17,RTICTL       
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
mainL:
            loc
            tst         CantPQ
            beq         chknodoM1
            ldaa        PTIH
            anda        #$80
            ldab        BANDERAS
            andb        #$08
            lslb 
            lslb 
            lslb 
            lslb 
            cba
            beq         nochange`
            bset        BANDERAS,$10
            cmpa        #$80
            beq         ph1`
            bclr        BANDERAS,$08
            bra         nochange`
ph1`        
            bset        BANDERAS,$08

nochange`
            brclr       BANDERAS,$08,chknodoM0
chknodoM1:
            brclr       BANDERAS,$10,jmodoconfig`
            bclr        BANDERAS,$10
            movb        #$02,LEDS
            movb        CantPQ,BIN1
            movb        #0,BIN2
            movb        #0,AcmPQ
            movb        #0,CUENTA
            bclr        PORTE,$04
            ldx         #MSG1
            ldy         #MSG2
            jsr         CARGAR_LCD
            

jmodoconfig`
            jsr         MODO_CONFIG
            bra         returnmain
chknodoM0:
            brclr       BANDERAS,$10,jmodorun`
            bclr        BANDERAS,$10
            movb        #$01,LEDS
            ldx         #MSG3
            ldy         #MSG4
            jsr         CARGAR_LCD
jmodorun`
            jsr         MODO_RUN
              
returnmain:     
            jmp         mainL

;       Subrutinas Generales
; *****************************************************************************

; *****************************************************************************
;                        TAREA_TECLADO Subroutine
; *****************************************************************************
TAREA_TECLADO:
            tst         Cont_Reb
            bne         RETURN_TT
        ;Go to MUX_TECLADO    
            jsr         MUX_TECLADO
            ldaa        TECLA
            cmpa        #$FF
            beq         CHECK_ARRAY
            brclr       Banderas,$02,REBOTES
            cmpa        TECLA_IN
            bne         TCL_NOT_READY
        ; TCL_LISTA = 1
            bset        Banderas,$01
            jmp         RETURN_TT
TCL_NOT_READY:
            movb        #$FF, TECLA
            movb        #$FF, TECLA_IN
            bclr        Banderas, $03
            jmp         RETURN_TT
REBOTES:
            movb        TECLA, TECLA_IN
        ; TCL_LEIDA = 1
            bset        Banderas,$02
            movb        #$0A, Cont_Reb
            jmp         RETURN_TT
CHECK_ARRAY:
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
            ldaa        #$F0
            cmpa        Patron
            bne         READ_LOOP
        ; If no key was pressed
            movb        #$FF,Tecla
            rts
        ; If a key was pressed
WR_TECLA:
            movb        B,X,Tecla
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
            clr         SendData
            ldaa        Clear_LCD
            jsr         SEND
            movb        D2mS,Cont_Delay
            jsr         Delay
        ; LINE1    
            pulx
            ldaa        ADD_L1
            clr         SendData
            jsr         SEND
            movb        D40uS,Cont_Delay
            jsr         Delay
loop2`:
            ldaa        1,X+
            cmpa        #FIN
            beq         LINE2`
            movb        #1,SendData
            jsr         SEND
            movb        D40uS,Cont_Delay
            jsr         Delay
            bra         loop2`
LINE2`:
            ldaa        ADD_L2
            clr         SendData
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
    

; *****************************************************************************
;                            Delay Subrutine
; *****************************************************************************
Delay:
            tst         Cont_Delay
            bne         Delay
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
;                        CONV_BIN_BCD Subrutine
; *****************************************************************************
            loc
CONV_BIN_BCD:
            ldab    #14
            movb    #0,BCD_L
            ldaa    BIN1   ;inicio con bcd1
            ldx     #BCD_L    
            bra     loop`
changeBCD`
            lsla
            rol     0,X
            ldaa    BIN2   ;continua con bcd2
            movb    BCD_L,BCD1
            movb    #0,BCD_L    
loop`
            lsla
            rol     0,X
            staa    TEMP
            ldaa    0,X
            anda    #$0F
            cmpa    #5
            blt     continue1`
            adda    #3
continue1`
            staa    LOW 
            ldaa    0,X
            anda    #$F0
            cmpa    #$50
            blt     continue2`
            adda    #$30
continue2`
            adda    LOW
            staa    0,X
            ldaa    TEMP
            decb
            cmpb    #7
            beq     changeBCD`
            cmpb    #$0 
            bne     loop`
            lsla
            rol     0,X
            movb    BCD_L,BCD2                             
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

; ************************************ISR*************************************

; *****************************************************************************
;                           PHO_ISR Subroutine
; *****************************************************************************
PTH_ISR:
; si no sirve usar brclr lol
            brset       PIFH,$01,PH0
            brset       PIFH,$02,PH1
            brset       PIFH,$04,PH2
            brset       PIFH,$08,PH3
PH0:
            bset        PIFH,$01
            tst         Cont_Reb
            bne         RETURN_PTH
            clr         CUENTA
            movb        #50,Cont_Reb
            ;stop relay
            bclr        PORTE,$04
            bra         RETURN_PTH
PH1:
            bset        PIFH,$02
            tst         Cont_Reb
            bne         RETURN_PTH
            clr         AcmPQ
            movb        #50,Cont_Reb
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
            jsr         CONV_BIN_BCD
            bra         returnOC4