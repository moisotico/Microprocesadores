; Moises Campos Zepeda
; 15-06-2020
; IE0623: Microprocesadores
; Proyecto Final: Selector 623
; *****************************************************************************
#include registers.inc
; *****************************************************************************
;*  Descripcion General:
;* El siguiente codigo para la tarjeta dragon 12 plus 2 de FreeScale corresponde
;* a un programa para un selector electronico, denominado Selector 623, el cual
;* permite demarcar los tubos que alcancen una longitud de cumplimiento
;* programanda. Para esto cuenta con 3 modos:
;*  - CONFIG para configuracion del parametro LengthOK, esto se hace por medio
;* del uso del teclado matricial de la tarjeta y los  displays de 7 segmentos 
;* para mostrar el valor LengthOK.
;*  - STOP: Muestra un mensaje de bienvenida en la pantalla LCD, se utiliza si 
;* no se desean relizar selecciones de tubos.
;*  - SELECT: Se realiza la seleccion de los tubos conforme a la Descripcion
;* realizada.



; *****************************************************************************
; *                           Data Structures                                 *
; *****************************************************************************
CR:             equ $0D
LF:             equ $0A
FIN:            equ $0

            org         $1000
   ;-- BANDERA:     7:MODO1 , 6:MODO0, 5:Calc_TICKS, 4:ENB_TICK_MED, 3:Pant_flag
   ;                2:ARRAY_OK_FLG , 1:TCL_LEIDA, 0:TCL_LISTA
BANDERA:        ds  1

   ;-- BANDERA_2:     1:CAMBIO_MOD, 0:ALERTA
BANDERA_2:       ds  1


    ;-- MODO_CONFIG       
LengthOK:       ds  1
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
CONT_200:       db  200
    ;--SUBRUTINAS_LCD
Cont_Delay:     ds  1
D2mS:           db  100
D240uS:         db  13
D60uS:          db  3
Clear_LCD:      db  $01
ADD_L1:         db  $80
ADD_L2:         db  $C0
SendData:       ds  1


            org         $1040
Teclas:         db  $01,$02,$03,$04,$05,$06,$07,$08,$09,$0B,$00,$0E
            org         $1050
SEGMENT:        db  $3F,$06,$5B,$4F,$66,$6D,$7D,$07,$7F,$6F,$40,$00
            org         $1060
initDisp:       db  $28,$28,$06,$0C

            org     $1070
; Mensaje de Config
C_MSG1:         fcc "CONFIGURACION"
                fcb CR,LF,CR,LF,FIN
C_MSG2:         fcc "LengthOK"
                fcb CR,LF,CR,LF,FIN

; Mensaje de Bienvenida
B_MSG1:         fcc "SELECTOR"
                fcb CR,LF,CR,LF,FIN
B_MSG2:         fcc "623"
                fcb CR,LF,CR,LF,FIN

; Mensaje Inicial
I_MSG1:         fcc "MODO SELECT"
                fcb CR,LF,CR,LF,FIN
I_MSG2:         fcc "Esperando..."
                fcb CR,LF,CR,LF,FIN

; Mensaje de Estado
E_MSG1:         fcc "*LONGITUD*"
                fcb CR,LF,CR,LF,FIN
E_MSG2:         fcc "*CORRECTA*"
                fcb CR,LF,CR,LF,FIN
E_MSG3:         fcc "-LONGITUD-"
                fcb CR,LF,CR,LF,FIN
E_MSG4:         fcc "-DEFICIENTE-"
                fcb CR,LF,CR,LF,FIN

; Mensaje de Alerta
A_MSG1:         fcc "VELOCIDAD"
                fcb CR,LF,CR,LF,FIN
A_MSG2:         fcc "FUERA DE RANGO"
                fcb CR,LF,CR,LF,FIN
; *****************************************************************************
;                       Interruption Vector Relocation
; *****************************************************************************
                ;org  $FFF0
                org $3E70
                dw RTI_ISR
                
                ;org  $FFCC
                org $3E4C
                dw CALCULAR_ISR

                ;org $FFD2
                org $3E52
                dw ATD_ISR

                ;org  $FFE6
                org $3E66
                dw OC4_ISR

                ;org $FFDE
                org $3E5E
                dw TCNT_ISR

; *****************************************************************************
; *                               Main                                        *
; *****************************************************************************
;   Descrip: Inicio del programa principal
; *****************************************************************************

; *****************************************************************************
;                               HW Config
; *****************************************************************************
;   Descrip: configuración de diferentes puertos, interrupciones y registros
;   de control, ademas se resetean mutiples varaibles.
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
            movb        #$80,TSCR1 
            movb        #$03,TSCR2
            movb        #$10,TIOS
            movb        #$10,TIE
            movb        #$01,TCTL1
            bclr        TCTL2,$FF
            ldd         TCNT
            addd        #60
            std         TC4
        ; for LCD screen
            movb        #$FF,DDRK

        ; PORTA + Pullup resistors     
            movb        #$F0,DDRA
            bset        PUCR,$01

        ; Beginning of the main program
            lds         #$3BFF
            clr         BCD1
            clr         BCD2
            clr         BIN1
            clr         BIN2
            movb        #1,LEDS
            clr         DISP1
            clr         DISP2
            clr         DISP3
            clr         DISP4
            clr         CONT_TICKS
            clr         CONT_DIG
            movb        #50,BRILLO
            movb        #$FF,Tecla
            movb        #$FF,Tecla_IN
            clr         Cont_Reb
            clr         Cont_TCL
            clr         LONG
            clr         Patron
            clr         BANDERA
            bset        BANDERA,$10
            ldaa        MAX_TCL
            ldx         #Num_Array-1
ARRAY_RST:
            movb        #$FF,A,X
            dbne        A,ARRAY_RST
            
; ATD0
            movb        #$C2, ATD0CTL2
            ldab        #200
        ;wait for ATD for 10 us via loop
loopIATD:
            dbne        B,loopIATD         
        ;5 mediciones
            movb        #$28,ATD0CTL3     
        ;8 bits, 2 ciclos de atd, PRS 23
            movb        #$97,ATD0CTL4
        ; no multiplex, pad7
            movb        #$87,ATD0CTL5
            bset        BANDERA_2,$02
INIT_LOOP:
            jsr         MODO_CONFIG
            tst         LengthOK
            beq         INIT_LOOP

MAIN_LOOP:
            ldaa        PTIH
            anda        #$C0
            ldab        BANDERA
            andb        #$C0
            cba
            beq         NO_CHANGE
        ; Check for 4th state
            cmpa        #$40
            beq         NO_CHANGE
            bset        BANDERA_2,$02

NO_CHANGE:
            cmpb        #$C0
            bne         DISABLE_H
            bset        BANDERA,$C0
            jsr         MODO_SELECT
            bra         MAIN_LOOP

DISABLE_H:
            clr         VELOC
            clr         LONG
            movb        #$03,TSCR2
            movb        #$00,PIEH
            movb        #$00,PIFH
            bclr        BANDERA,$04    
            bclr        BANDERA_2,$01
            cmpb        #$80
            bne         GO2STOP
            bset        BANDERA,$80
            bclr        BANDERA,$40
            jsr         MODO_CONFIG
            jmp         MAIN_LOOP

GO2STOP:
            bclr        BANDERA,$C0
            jsr         MODO_STOP
            jmp         MAIN_LOOP


; *****************************************************************************
;                        MODO_CONFIG Subroutine
; *****************************************************************************
MODO_CONFIG:
            loc
            brclr       BANDERA_2,$02,no_lcd`
        ;Deactivate H port interruption 
            bclr        PIEH,$09
            bset        PIFH,$09
            clr         TICK_EN
            clr         TICK_DIS
            bclr        BANDERA_2,$02
            ldx         C_MSG1
            ldy         C_MSG2
            movb        #1,LEDS
            jsr         CARGAR_LCD
no_lcd`
            movb        LengthOK,BIN1
            movb        #$BB,BIN2 
            jsr         TAREA_TECLADO
            brclr       BANDERA,$04,return`
            bclr        BANDERA,$04
            jsr         BCD_BIN
            ldaa        ValorLenght
            cmpa        #100
            bhi         reset`
            cmpa        #70
            blo         reset`
            movb        ValorLenght,LengthOK
            movb        LengthOK,BIN1
            jmp         return`
reset`
            clr         ValorLenght
reset2`

return`
            rts


; *****************************************************************************
;                        MODO_STOP Subroutine
; *****************************************************************************
MODO_STOP:
            loc
            ldaa        BANDERA_2
            anda        #$02
            beq         return`
            ldx         B_MSG1
            ldy         B_MSG2
            bclr        BANDERA_2,$02
            movb        #$04,LEDS
            jsr         CARGAR_LCD
            movb        #$BB,BIN1      
            movb        #$BB,BIN2
return`
            rts


; *****************************************************************************
;                        MODO_SELECT Subroutine
;           TODO: Check differences
; *****************************************************************************
MODO_SELECT:
            loc
            ldaa        BANDERA_2
            anda        #$02
            beq         chk_veloc`
            ldx         I_MSG1
            ldy         I_MSG2
            bclr        BANDERA_2,$02
            movb        #$02,LEDS
            movb        #$BB,BIN1      
            movb        #$BB,BIN2
            movb        #$09,PIEH
        ;activate TOI
            movb        #$83,TSCR2  
            jsr         CARGAR_LCD
chk_veloc`
            tst         VELOC
            beq         return`
            jsr         PANT_CTRL
return`
            rts


; *****************************************************************************
;                        PANT_CTRL Subroutine
; *****************************************************************************
PANT_CTRL:
            loc
            bclr        PIEH,$09
            bclr        PIFH,$09
        ; Check VELOC range
            ldaa        VELOC
            cmpa        #50
            bgt         rng_error`
            cmpa        #10
            blt         rng_error`
            brset       BANDERA,$20,next2`
            bset        BANDERA,$20
            ldx         VELOC
            ldd         LONG
            ldy         #1000
            emul
            ediv
            tfr         Y,D
            ldx         #23
            idiv
            tfr         X,D
            lsrd
            std         TICK_EN
            addd        #87
            std         TICK_DIS
            jmp         return`
rng_error`
        ;Levantar Alerta si es mayor a la velocidad limite
            cmpa        #$AA
            beq         next`
            bset        BANDERA_2,$01      
            clr         TICK_EN
            movb        #87,TICK_DIS
            movb        #$AA,BIN1
            movb        #$AA,BIN2
            ldx         A_MSG1 
            ldy         A_MSG2
            jsr         CARGAR_LCD
            rts
next`
            brset       BANDERA,$08,return`  
            jmp         info`       
next2`
            brset       BANDERA,$08,chk_BIN1_a`  
            jmp         chk_BIN1_b`       
chk_BIN1_a`
            ldaa        BIN1
            cmpa        #$BB
            bne         return`
            ldaa        LONG
            cmpa        LengthOK
            bge         all_good`
            ldx         E_MSG3
            ldy         E_MSG4
            jmp         load_LCD`
all_good`
            bset        PORTE,$04
            ldx         E_MSG1
            ldy         E_MSG2
load_LCD`   
            jsr         CARGAR_LCD
            movb        LONG,BIN1
            movb        VELOC,BIN2
            jmp         return`
chk_BIN1_b`
            ldaa        BIN1
            cmpa        #$BB
            beq         return`
info`
            ldx         I_MSG1
            ldy         I_MSG2
            jsr         CARGAR_LCD
            movw        #$BB,BIN1
            movw        #$BB,BIN2
            bset        PIEH,$09
            bset        PIFH,$09
return`
            rts


;*****************************************************************************
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
            brclr       BANDERA,$02,REBOTES
            cmpa        Tecla_IN
            bne         TCL_NOT_READY
        ; TCL_LISTA = 1
            bset        BANDERA,$01
            bra         RETURN_TT

TCL_NOT_READY:
            movb        #$FF,Tecla
            movb        #$FF,Tecla_IN
            bclr        BANDERA,$03
            bra         RETURN_TT

REBOTES:
            movb        Tecla,Tecla_IN
        ; TCL_LEIDA = 1
            bset        BANDERA,$02
            movb        #10,Cont_Reb
            bra         RETURN_TT

CHECK_ARRAY:
            brclr       BANDERA,$01,RETURN_TT
            bclr        BANDERA,$03
            ldab        Tecla_IN
            cmpb        #$FF
            beq         RETURN_TT
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
            bset        BANDERA,$04
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
            beq         mul_10`
            addb        A,X    
            bra         sumA`
mul_10`
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
            stab        ValorLenght
            bra         return`
wrong`
            movb        #$FF,NUM_ARRAY
            movb        #$0,ValorLenght
return`
            rts


; *****************************************************************************
;                           CONV_BIN_BCD Subrutine
; *****************************************************************************
CONV_BIN_BCD:
            loc
            ldaa        BIN1
            cmpa        #$BB
            bne         chk_AA`
            movb        $BB,BCD1
            bra         next`
chk_AA`
            cmpa        #$AA
            bne         GO2_BB`
            movb        $AA,BCD1
            bra         next`
GO2_BB`
            jsr         BIN_BCD
            movb        BCD_L,BCD1
            
next`
            ldaa        BIN2
            cmpa        #$BB
            bne         chk_AA2`
            movb        $BB,BCD2
            bra         return`
chk_AA2`
            cmpa        #$AA
            bne         GO2_BB2`
            movb        $AA,BCD2
            bra         return`
GO2_BB2`
            jsr         BIN_BCD
            movb        BCD_L,BCD2
return`
            rts


; *****************************************************************************
;                           BIN_BCD Subrutine
; *****************************************************************************
BIN_BCD:
            loc
            ldab #7

            clr         BCD_L
            ldx         #BCD_L    
            bra         loop`
loop`
            lsla
            rol         0,X
            staa        TEMP
            ldaa        0,X
            anda        #$0F
            cmpa        #5
            blt         continue1`
            adda        #3
continue1`
            staa        LOW 
            ldaa        0,X
            anda        #$F0
            cmpa        #$50
            blt         continue2`
            adda        #$30
continue2`
            adda        LOW
            staa        0,X
            ldaa        TEMP
            decb
            cmpb        #0
            bne         loop`
            lsla
            rol         0,X
            movb        BCD_L,BCD2                             
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
;                           Cargar_LCD Subrutine
; *****************************************************************************
CARGAR_LCD: 
            loc
            pshx        
        ;  TODO: PRINT     
            ldx         #initDisp
            ldab        #4
loop1`:
            ldaa        1,X+
            clr         SendData
            jsr         SEND
            movb        D60uS,Cont_Delay
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
            movb        D60uS,Cont_Delay
            jsr         Delay
loop2`:
            ldaa        1,X+
            cmpa        #FIN
            beq         LINE2`
            movb        #1,SendData
            jsr         SEND
            movb        D60uS,Cont_Delay
            jsr         Delay
            bra         loop2`
LINE2`:
            ldaa        ADD_L2
            clr         SendData
            jsr         SEND
            movb        D60uS,Cont_Delay
            jsr         Delay
loop3`:
            ldaa        1,Y+
            cmpa        #FIN
            beq         return`
            movb        #1,SendData
            jsr         SEND
            movb        D60uS,Cont_Delay
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
            movb        D240uS,Cont_Delay
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
            movb        D240uS,Cont_Delay
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


; ************************************ISR*************************************

; *****************************************************************************
;                           RTI_ISR Subroutine
; *****************************************************************************
RTI_ISR:
            loc
            bset        CRGFLG,$80
            tst         Cont_Reb
            beq         CHK_TCOUNT`
            dec         Cont_Reb
CHK_TCOUNT`
            ldaa        CONT_200
            cmpa        #200
            bne         INCR200`
            movb        #$93,ATD0CTL5
            bra         CHK_ROC`
INCR200`
            inc         CONT_200
CHK_ROC`    
            tst         CONT_ROC
            beq         RETURN`
            dec         CONT_ROC
RETURN`:
            rti


; *****************************************************************************
;                           ATD_ISR Subroutine
; *****************************************************************************
;           Calcula BRILLO from POT
; *****************************************************************************
ATD_ISR:
            ldx         #5
            ldd         ADR00H
            addd        ADR01H
            addd        ADR02H
            addd        ADR03H
            addd        ADR04H
            idiv
            tfr         X,D
            stab        POT
            ldaa        #20
            ldx         #255
            mul
            idiv
            tfr         X,D
            stab        BRILLO
            ldaa        #5
            mul
            stab        DT          
            rti


; *****************************************************************************
;                           CALCULAR_ISR Subroutine
; *****************************************************************************
;   Descrip: maneja las subrutinas PH
; *****************************************************************************
CALCULAR_ISR:
            brset       PIFH,$01,PH0
            brset       PIFH,$02,PH1
            brset       PIFH,$04,PH2
            brset       PIFH,$08,PH3

; *****************************************************************************
;                           PH0
; *****************************************************************************
;   Descrip: Calcula la velocidad de los tubos, así como los ticks necesarios
;   para mostrar y borrar la pantalla.
;   
;   *Entrada:
;   *Salida:
; *****************************************************************************
PH0:
            bset        PIFH,$01
            tst         Cont_Reb
            bne         RETURN_PTH
        ; Best value for buttons and keyboard
            movb        #100,Cont_Reb
            ldx         TICK_MED
            beq         RETURN_PTH
            cpx         #9
        ; Avoid overflow
            bhs         valid_Speed`
            movb        #$00,VELOC
            movb        #$00,LONG
            bra         RETURN_PTH

valid_Speed`
        ; Calculate Veloc         
            ldd         #50000              
            idiv
            tfr         X,D
            ldx         #22
            idiv
            tfr         X,D
            stab        VELOC  
        ; Calculate LONG
            ldaa        #22
            mul              
            ldx         #1000
            ldy         TICK_MED
            emul
            ediv
            tfr         X,D
            stab        LONG  
            bra         RETURN_PTH

; *****************************************************************************
;                           PH1
; *****************************************************************************
;   Descrip: Activa PIFH.1.
;   
;   *Entrada:
;   *Salida:
; *****************************************************************************
PH1:
            bset        PIFH,$02
            bra         RETURN_PTH

; *****************************************************************************
;                           PH2
; *****************************************************************************
;   Descrip: Activa PIFH.2.
;   
;   *Entrada:
;   *Salida:
; *****************************************************************************
PH2:
            bset        PIFH,$04
            bra         RETURN_PTH

; *****************************************************************************
;                           PH3
; *****************************************************************************
;   Descrip: Activa PIFH.3. Limpia TICK_MED y maneja Cont_Reb con un valor de
;   100.
;   
;   *Entrada: Cont_Reb 
;   *Salida:  BANDERA.3, BANDERA.2, Cont_Reb
; *****************************************************************************
PH3:
            bset        PIFH,$08
            ldaa        Cont_Reb
            bne         RETURN_PTH
            movb        #100,Cont_Reb
            clr         TICK_MED
            bset        BANDERA,$0C            
RETURN_PTH:
            rti

; *****************************************************************************
;                           TCNT_ISR Subroutine
; *****************************************************************************
TCNT_ISR:
            loc
            ldd         TCNT
            movb        #$FF,TFLG2
            ldaa        TICK_MED
            cmpa        #255
            beq         chk_en`
            brclr       BANDERA,$10,chk_en`
            inc         TICK_MED
chk_en`
            tst         VELOC
            beq         return`
            ldx         TICK_EN
        ; When TICK_EN = $0000, on next run dex makes it $FFFF
            dex
            bne         No_Set`
            bset        BANDERA,$08
No_Set`
            stx         TICK_EN
            ldx         TICK_DIS
        ; When TICK_DIS = $0000, on next run dex makes it $FFFF
            dex
            bne         No_Clr`
            bclr        BANDERA,$08
No_Clr`
            stx         TICK_DIS
return`
            rti        


; *****************************************************************************
;                           OC4_ISR Subroutine
; *****************************************************************************
OC4_ISR:
            loc
            ldaa        CONT_TICKS
            ldab        DT
            cba
            bge         off`
            tst         CONT_TICKS
            beq         check_digit`
chk_N`
            cmpa        #100
            beq         chnge_dgt`
incticks`
            inc         CONT_TICKS
            jmp         part2`
off`
            movb        #$FF,PTP
            bclr        PTJ,$02
            movb        LEDS,PORTB
            bra         chk_N`
chnge_dgt`
            clr         CONT_TICKS
            ldaa        #5
            cmpa        CONT_DIG
            bne         jpart2`
            clr         CONT_DIG
jpart2`
            inc         CONT_DIG
            bra         part2`
check_digit`
            ldaa        CONT_DIG
            ldx         #DISP1
            ;movb        A,X,PORTB
            bset        PTJ, $02
            tsta
            bne         dig2`
            movb        #$07,PTP
            bra         incticks`
dig2`
            cmpa        #1
            bne         dig3`
            movb        #$0B,PTP
            bra         incticks`
dig3`
            cmpa        #2
            bne         dig4`
            movb        #$0D,PTP
            bra         incticks`
dig4`
            cmpa        #4
            bne         digleds`
            movb        #$0E,PTP
            jmp         incticks`
digleds`
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
            movb        #$FF,TFLG1
            rti
JBCD_7SEG`
            movw        #5000,CONT_7SEG
            jsr         BCD_7SEG
            jsr         CONV_BIN_BCD
            bra         returnOC4
