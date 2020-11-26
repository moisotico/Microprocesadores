; Moises Campos Zepeda
; 28-11-2020
; IE0623: Microprocesadores
; Proyecto Final: RunMeter623
; *****************************************************************************
#include registers.inc
; *****************************************************************************
;  Descripcion General:
; El siguiente codigo para la tarjeta dragon 12 plus 2 de FreeScale corresponde
; a un programa para un selector electronico, denominado Selector 623, el cual
; permite demarcar los tubos que alcancen una longitud de cumplimiento
; programanda. Para esto cuenta con 4 modos:
;  - CONFIG para configuracion del parametro LengthOK, esto se hace por medio
; del uso del teclado matricial de la tarjeta y los  displays de 7 segmentos 
; para mostrar el valor LengthOK.
;  - LIBRE: Muestra un mensaje de bienvenida en la pantalla LCD, se utiliza si 
; no se desean relizar selecciones de tubos.
; * TODO * :
; - COMPETENCIA: Se realiza 
; - RESUMEN: .
; *****************************************************************************
; *                           Data Structures                                 *
; *****************************************************************************
CR:             equ $0D
LF:             equ $0A
FIN:            equ $0

            org         $1000
   ;-- BANDERAS:    7:MODO1, 6:MODO0, 5:Calc_TICKS, 4: Cambio_MODO
   ;                3:Pant_flag, 2:ARRAY_OK_FLG, 1:TCL_LEIDA, 0:TCL_LISTA
BANDERAS:        ds  1


    ;-- MODO_CONFIG       
NumVueltas:     ds  1
ValorVueltas:   ds  1
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
    ;-- CALCULAR           
Veloc:          ds  1
Vueltas:        ds  1
VelProm:        ds  1
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

; Mensaje Modo Libre
L_MSG1:         fcc " RunMeter  623 "
                fcb FIN
L_MSG2:         fcc "  MODO  LIBRE  "
                fcb FIN
; Mensaje Modo Configuracion
CONF_MSG1:      fcc "  MODO CONFIG  "
                fcb FIN
CONF_MSG2:      fcc "  NUM VUELTAS  "
                fcb FIN

; Mensaje Inicial
I_MSG1:         fcc " RunMeter  623 "
                fcb FIN
I_MSG2:         fcc " ESPERANDO...  "
                fcb FIN

; Mensaje de Competencia
COMP_MSG1:      fcc " M.COMPETENCIA "
                fcb FIN
COMP_MSG2:      fcc "VUELTA    VELOC"
                fcb FIN

; Mensaje Calculando
CALC_MSG1:      fcc "RunMeter 623"
                fcb FIN
CALC_MSG2:      fcc "*CALCULANDO..."
                fcb FIN

; Mensaje de Alerta
A_MSG1:         fcc "**  VELOCIDAD **"
                fcb FIN
A_MSG2:         fcc "*FUERA DE RANGO*"
                fcb FIN
; Mensaje de Alerta
R_MSG1:         fcc "  MODO RESUMEN  "
                fcb FIN
R_MSG2:         fcc "VUELTAS    VELOC"
                fcb FIN

; *****************************************************************************
;                       Interruption Vector Relocation
; *****************************************************************************
                ;org  $FFF0
                org $3E70
                dw RTI_ISR
                
                ;org  $FFCC
                org $3E4C
                dw PTH_ISR

                ;org $FFD2
                org $3E52
                dw ATD_ISR

                ;org  $FFE6
                org $3E66
                dw OC4_ISR

                ;org $FFDE
                ;org $3E5E
                ;dw TCNT_ISR

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
        ; Port E relay
            bset        DDRE,$04
        ; Key wakeup PTH
            bset        PIEH,$0C          
            bset        PIFH,$0F
        ; RTI @ 1,027 ms
            movb        #$17, RTICTL       
            bset        CRGINT,$80
        ; Ctrl registers y timer enable
            movb        #$90,TSCR1 
        ;PRS = 8    
            movb        #$03,TSCR2
            movb        #$10,TIOS
            movb        #$10,TIE
            movb        #$01,TCTL1
            bclr        TCTL2,$FF
            ldd         TCNT
            addd        #60
            std         TC4
        ; LCD screen
            movb        #$FF,DDRK
        ; PORTA + Pullup resistors     
            movb        #$F0,DDRA
            bset        PUCR,$01
        ; ATD0
            movb        #$C2, ATD0CTL2
            ldab        #200
        ; Esperar ATD por 10 us via loop
loopIATD:
            dbne        B,loopIATD         
        ;6 mediciones
            movb        #$30,ATD0CTL3     
        ;8 bits, 4 ciclos de atd, PRS 19
            movb        #$B2,ATD0CTL4
        ; no multiplex, sin signo, pad7
        ;    movb        #$87,ATD0CTL5

; *****************************************************************************
; *                               Main                                        *
; *****************************************************************************
;   Descrip: Inicio del programa principal
; *****************************************************************************
            loc
            lds         #$3BFF
        ; Permitir interrup enmascaradas
            cli
        ; Limpiar varaibles
            movb        #$FF, TECLA
            movb        #$FF, TECLA_IN
            ldaa        MAX_TCL
            ldx         #Num_Array-1
ARRAY_RST`
            movb        #$FF,A,X
            dbne        A,ARRAY_RST`
            
            clr         Cont_Reb
            clr         Cont_TCL
            clr         Patron
            movb        #$50,Banderas
            clr         BIN1
            clr         BIN2
            clr         BCD1
            clr         BCD2
            clr         CONT_DIG
            clr         BRILLO
            clr         NumVueltas
            clr         ValorVueltas
INIT_LOOP`
            jsr         MODO_CONFIGURACION
            tst         NumVueltas
            beq         INIT_LOOP`
MAIN_LOOP`
            ldaa        PTIH
            anda        #$C0
            ldab        BANDERAS
            andb        #$C0
            cba
            beq         NO_CHNG`
            bclr        BANDERAS,$C0
            oraa        BANDERAS
            staa        BANDERAS
            bset        BANDERAS,$10
            bra         CHK_COMP`
NO_CHNG`
            bclr        BANDERAS,$10
CHK_COMP`
            brset       BANDERAS,$C0,GO2_COMP`
            brset       BANDERAS,$80,GO2_RES`
            brclr       BANDERAS,$10,CHK_CONFIG`
            clr         Veloc
            clr         Vueltas
            movb        #$03,TSCR2
        ; Check for errors
            bclr        $0F,PIEH
            bclr        $0F,PIFH
            bclr        $08,BANDERAS
CHK_CONFIG`
            brset       BANDERAS,$40,GO2_CONFIG`
            jsr         MODO_LIBRE
            bra         RETURN`
GO2_CONFIG`
            jsr         MODO_CONFIGURACION
            bra         RETURN`
; TODO
GO2_COMP`
            brclr       BANDERAS,$10,*TODO*`
            jsr         MODO_COMPETENCIA
            bra         RETURN`
; TODO
GO2_RES`
            brclr       BANDERAS,$10,*TODO*`
            jsr         MODO_RESUMEN
RETURN`:     
            jmp         MAIN_LOOP`

; *****************************************************************************
;                        MODO_CONFIGURACION Subroutine
; *****************************************************************************
MODO_CONFIGURACION:
            loc
            brclr       BANDERAS,$10,jmodoconfig`
            bclr        BANDERAS,$10
            movb        #$02,LEDS
            movb        NumVueltas,BIN1
            movb        #100,BIN2
            movb        #0,ValorVueltas
            ldx         #CONF_MSG1
            ldy         #CONF_MSG2
            jsr         CARGAR_LCD
jmodoconfig`
            loc
            bclr        PIEH,$0F
            brclr       BANDERAS,$04,GO2TAREATECLADO
            jsr         BCD_BIN
            bclr        BANDERAS,$04
            ldaa        ValorVueltas
            cmpa        #25
            bgt         resetNumVuelt`
            cmpa        #5
            blt         resetNumVuelt`
            movb        ValorVueltas,NumVueltas
            movb        NumVueltas,BIN1
            ;movb        #0,BIN2
            bra         return`
GO2TAREATECLADO:
            jsr         TAREA_TECLADO
            bra         return`
resetNumVuelt`:
            clr         NumVueltas
return`:
            rts
            
            
; *****************************************************************************
;                        MODO_COMPETENCIA Subroutine
; *****************************************************************************
MODO_COMPETENCIA:
            loc
            rts

; *****************************************************************************
;                         MODO_RESUMEN Subroutine
; *****************************************************************************
MODO_RESUMEN:
            loc
            rts
; *****************************************************************************
;                           MODO_LIBRE Subroutine
; *****************************************************************************
MODO_LIBRE:
            loc
            brclr       BANDERAS,$10,return`
            ldx         #L_MSG1
            ldy         #L_MSG2
            bclr        BANDERAS,$10
            movb        #$04,LEDS
            jsr         CARGAR_LCD
            movb        #$BB,BIN1      
            movb        #$BB,BIN2
return`
            rts


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
            cmpa    #$BB
            beq     chk_special1`
            cmpa    #$AA
            beq     chk_special1`
            ldx     #BCD_L    
            bra     loop`
changeBCD`
            lsla
            rol     0,X
chk_BCD`
            ldaa    BIN2   ;continua con bcd2
            cmpa    #$BB
            beq     chk_special2`
            cmpa    #$AA
            beq     chk_special2`
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
return`                                         
            rts

chk_special1`
            staa    BCD1
            bra     chk_BCD`
chk_special2`
            staa    BCD2
            bra     return`



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
            stab        ValorVueltas
            bra         return`
wrong`
            movb        #$FF,NUM_ARRAY
            movb        #$0,ValorVueltas
return`
            rts


; ************************************ISR*************************************

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
;                           PTH_ISR Subroutine
; *****************************************************************************
PTH_ISR:
;            brset       Banderas,$08,CONF_ONLY
            brset       PIFH,$01,PH0
            brset       PIFH,$08,PH3
;CONF_ONLY:        
;            brset       PIFH,$04,PH2
;            brset       PIFH,$08,PH3
            bra         RETURN_PTH
PH0:
            bset        PIFH,$01
            tst         Cont_Reb
            bne         RETURN_PTH
            movb        #100,Cont_Reb
            bra         RETURN_PTH
;PH2:
PH3:
RETURN_PTH:
            rti

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
            tst        CONT_200
            beq        RETURN`
            dec        CONT_200 
;INCR200`
            movb        #$87,ATD0CTL5
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
            bclr        PTJ,$02 ; enciendo
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

; *****************************************************************************
;                           TCNT_ISR Subroutine
; *****************************************************************************
;TCNT_ISR:
;           loc
;           ldd         TCNT
;          movb        #$FF,TFLG2
;          ldaa        TICK_MED
;          cmpa        #255
;          beq         chk_en`
;          brclr       BANDERAS,$10,chk_en`
;          inc         TICK_MED
;chk_en`
;           tst         VELOC
;           beq         return`
;           ldx         TICK_EN
;       ; When TICK_EN = $0000, on next run dex makes it $FFFF
;           dex
;           bne         No_Set`
;           bset        BANDERAS,$08
;No_Set`
;           stx         TICK_EN
;           ldx         TICK_DIS
;       ; When TICK_DIS = $0000, on next run dex makes it $FFFF
;           dex
;           bne         No_Clr`
;           bclr        BANDERAS,$08
;No_Clr`
;           stx         TICK_DIS
;return`
;            rti        