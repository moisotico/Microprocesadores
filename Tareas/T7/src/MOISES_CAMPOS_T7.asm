; Moises Campos Zepeda
; 4-12-2020
; IE0623: Microprocesadores
; Tarea 7: Control itinerario de Luz

; Include File
#include registers.inc

; *****************************************************************************
;                           Data Structures
; *****************************************************************************
CR:             equ $0D
LF:             equ $0A
FIN:            equ $00

            org     $1000
CONT_RTI:       ds  1 
   ;-- BANDERAS:    7:X, 6:X, 5:X, 4: X,
   ;                3:X, 2:SendData, 1:Read/Write, 0:TCL_LISTA
BANDERAS:       ds  1
; Valor de 0 a 100, controla brillo de 7 seg
BRILLO:         ds  1
; Dígito actual de disp 7 seg
CONT_DIG:       ds  1
; Permite definir la cantidad de ticks que se rende el disp 7 seg
CONT_TICKS:     ds  1
; 100 - Brillo 
DT:             ds  1   
; Bin 1 y 2 en BCD
BCD1:           ds  1
BCD2:           ds  1
    ; Valores a mandar a DISP_7SEG
DIG1:           ds  1
DIG2:           ds  1
DIG3:           ds  1
DIG4:           ds  1
    ; Valor para usar LEDS
LEDS:           ds  1
    ; Codificacion para numeros en disp de 7 segmentos
SEGMENT:        db  $3F,$06,$5B,$4F,$66,$6D,$7D,$07,$7F,$6F
CONT_7SEG:      ds  2
Cont_Delay:     ds  1
; Constantes para pantalla LCD
D2mS:           db  100
D260uS:         db  13
D60uS:          db  3
; Comando para limpiar pantalla LCD
Clear_LCD:      db  $01
; Agregan primera y segunda linea en pantalla LCD
ADD_L1:         db  $80
ADD_L2:         db  $C0
;  COMANDOS: Number of bytes, 2*function set, Entry mode set, display on
initDisp:        db  $28,$28,$06,$0C
; Punteroa posicion a la que se envia/recibe
Index_RTC:      ds  1
; Direccioens de escritura y lectura de DS1307
Dir_WR:         db  $D0
Dir_RD:         db  $D1
; Primera escritura y lectrua de DS1307
Dir_Seg:        db  $00

            org     $1030
; Hexadecimal  al ser BCD.
;                   seg, min,hora,dia,#dia,mes,a�o
T_WRITE_RTC:    db $00,$00,$10,$05,$04,$12,$20
            org     $1040
T_READ_RTC:     ds  6

            org     $1050
T_Acc_Iti:      db $01              ; min, encendido
                db $10              ; hora, encendido
                db $02              ; min, apagado
                db $10              ; hora, apagado
                db %11111111        ; .7 => MODO, .6:0 => Días

            
            org     $1060
MSG0:       fcc " CONTROL DE LUZ "
            fcb FIN
MSG1:       fcc " POR ITINERARIO "
            fcb FIN
; *****************************************************************************
;                       Interruption Vector Relocation
; *****************************************************************************
            org     $3E70
            dw          RTI_ISR
            org     $3E4C
            dw          PTH_ISR
            org     $3E66
            dw          OC4_ISR
            org     $3E40
            dw          IIC_ISR
            
; *****************************************************************************
;                               HW Config
; *****************************************************************************
            org     $2000
        ; Port E relay
            bset        DDRE,$04
            bclr        PORTE,$04
        ; PORTA + Pullup resistors     
            movb        #$F0,DDRA
            bset        PUCR,$01
        ; Key wakeup PTH
            bset        PIEH,$0D          
            bset        PPSH,$00
        ; LCD screen
            movb        #$FF,DDRK
        ; 7seg screen
            movb        #$0F,DDRP
            movb        #$0F,PTP
            movb        #$FF,DDRB
        ; Conf puerto J
            bset        DDRJ,$02 
            bset        PTJ,$02
            
        ; RTI @ 1,027 ms
            movb        #$64,RTICTL       
            bset        CRGINT,$80
        ; Ctrl registers and timer enable
            bset        TSCR1,$90 
        ;PRS = 8
            bset        TSCR2,$03
            bset        TIOS,$10
            bset        TIE,$10
            bset        TCTL1,$01
            bset        TCTL2,$00
            ldd         TCNT
            addd        #60
            std         TC4

        ;IIC 100 kps, SCL div = 240
            movb        #$1F,IBFD 
            movb        #$D0,IBCR

        ; Enable masked interruptions
            cli
            lds         #$3BFF

; *****************************************************************************
;                           Main Program
; *****************************************************************************
            loc
        ; Clean
            clr         CONT_RTI
            clr         BANDERAS
            movb        #50,BRILLO
            clr         BCD1
            clr         BCD2
            clr         DIG1
            clr         DIG2
            clr         DIG3
            clr         DIG4
            clr         LEDS
            movw        #0,CONT_7SEG
            clr         Cont_Delay
            clr         Index_RTC
            ldx         #T_READ_RTC
            ldaa        #5
clr_l1`
            movb        #0,A,X
            dbne        A,clr_l1`
        ; Init msg
            ldx         #MSG0
            ldy         #MSG1
            jsr         CARGAR_LCD
            ldx         #T_Acc_Iti
            ldy         #T_READ_RTC+3
mainL`
            ldaa        0,X
            anda        #$80
            beq         variable_mode`
ctrl_l`
            jsr         Control_Luz
            bra         mainL`
variable_mode`
            ldab        0,Y
            cmpb        #7
l1`
            beq         m_next`
            incb
            rora      
            bra         l1`  
m_next`
            anda        #$01
            beq         mainL`
            bra         ctrl_l`   


; *****************************************************************************
;                           Control_Luz Subroutine
; *****************************************************************************
Control_Luz:
            loc
        ; apagado a encendido
            ldd         T_Acc_Iti
            cpd         T_Read_RTC+1       ;Se compara los minutos de encendido con los de memoria
            bne         next`
            bclr        BANDERAS,$04
set_relay`
            ;brset       BANDERAS,$10,return`
            ;bset        BANDERAS,$10
        ; Prende la luz
            brset       BANDERAS,$04,tlight_off`
            bset        PORTE,$04
            bra         return`
        ; encendido a apagado
next`
            ldd         T_Acc_Iti+2
            cpd         T_Read_RTC+1       ;Se compara las horas con las de memoria
            bne         return`
            bset        BANDERAS,$04
            beq         set_relay`
return`
            rts
tlight_off`
        ; Apaga la luz    
            bclr        PORTE,$04
            bra         return`

; *****************************************************************************
;                           Cargar_LCD Subrutine
; *****************************************************************************
;Descripcion:
;   Subrutina encargada de enviar la información a desplegar en la pantalla LCD
;Entrada:
;   * ADD_L1,ADD_L2: Constantes que representan comandos para añadir lineas.
;   * D60us,D2ms: Constantes para el tiempo de espera para comunicarse
;    con la pantalla LED.
;   * initDisp: Tabla de comandos para iniciar la comunicación con la pantalla
;   * J: Contiene el puntero de la linea 1
;   * K: Contiene el puntero de la linea 2           
; *****************************************************************************
CARGAR_LCD: 
            loc
            pshx        
            ldx         #initDisp
            ldab        #4
loop1`:
            ldaa        1,X+
            bclr        BANDERAS,$08
            jsr         SEND
            movb        D60uS,Cont_Delay
            jsr         Delay
            dbne        B,loop1`
            bclr        BANDERAS,$08
            ldaa        Clear_LCD
            jsr         SEND
            movb        D2mS,Cont_Delay
            jsr         Delay
        ; LINE1    
            pulx
            ldaa        ADD_L1
            bclr        BANDERAS,$08
            jsr         SEND
            movb        D60uS,Cont_Delay
            jsr         Delay
loop2`:
            ldaa        1,X+
            cmpa        #FIN
            beq         LINE2`
            bset        BANDERAS,$08
            jsr         SEND
            movb        D60uS,Cont_Delay
            jsr         Delay
            bra         loop2`
LINE2`:
            ldaa        ADD_L2
            bclr        BANDERAS,$08
            jsr         SEND
            movb        D60uS,Cont_Delay
            jsr         Delay
loop3`:
            ldaa        1,Y+
            cmpa        #FIN
            beq         return`
            bset        BANDERAS,$08
            jsr         SEND
            movb        D60uS,Cont_Delay
            jsr         Delay
            bra         loop3`
return`:
            rts

; *****************************************************************************
;                            SEND Subrutine
; *****************************************************************************
; Descripcion:
;     Se encarga de enviar a la pantalla LCD el dato o comando que 
;   recibe conforme al estado de la bandera en BANDERAS_2.0: SEND_DATA.
;Entrada:
;   * BANDERAs_2.0: Indica si se envia un comando o datos.
;   * D260uS: Constante con el delay necesario para la pantalla. 
; ****************************************************************************
SEND:       loc
            psha
            anda        #$F0
            lsra
            lsra
            staa        PORTK
            brclr       BANDERAS,$08,clearK1`
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
            brclr       BANDERAS,$08,clearK2`
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
;Descripcion:
;   Subrutina de atraso, consume el tiempo necesario para la comunicacion con 
;  la pantalla.               
;Entrada:
;       CONT_DELAY: Contador que indica cuanto esperar (1 = 230 us).
; *****************************************************************************
Delay:
            tst         Cont_Delay
            bne         Delay
            rts

; *****************************************************************************
;                            BCD_7SEG Subrutine
; *****************************************************************************
;Descripcion:
;   Subrutina encargada convertir valores de BCD a los valores necesarios para
; poder visualizarlos en la pantalla de 7 segmentos.
;Entrada:
;   * BC1,BCD2: Valores en bcd a convertir
;   * SEGMENT: Tabla que contiene los valores para cada uno de los digitos,
;           guiones y valores en blanco.
;Salida:
;   *  DIG1,DIG2,DIG3,DIG4: Valores en 7 segmentos para cada uno de los
;           displays
; *****************************************************************************
BCD_7SEG:       
            loc
            movb        T_Read_RTC+1,BCD1
            movb        T_Read_RTC+2,BCD2
            ldx         #SEGMENT
            ldy         #DIG1
            clra
            ldab        BCD1
            bra         set_disps`
loadBCD2`
            ldab        BCD2
set_disps`
            pshb 
            andb        #$0F
        ; move lower bcd to DIG1 or disp 3
            movb        B,X,1,Y+      
            pulb 
            lsrb
            lsrb
            lsrb
            lsrb
        ; move lower bcd to DIG2 or DIG4
            movb        B,X,1,Y+     
        ;check DIG3    
            cpy         #DIG3
            beq         loadBCD2`
            brclr       T_Read_RTC,$01,cln_dots`
            bset        DIG2,$80
            bset        DIG3,$80
            bra         return`
cln_dots`
            bclr        DIG2,$80
            bclr        DIG3,$80
return`
            rts


; *****************************************************************************
;                            Write_RTC Subrutine
; *****************************************************************************
Write_RTC:  loc
        ;No se recibio el ack
            brset       IBSR,$02,error`       
            ldaa        Index_RTC
            bne         next`
        ; Direccion de segundos
            movb        Dir_Seg,IBDR                
            bra         return`
next`       
            cmpa        #7
            beq         finish_wr`
            deca
            ldx         #T_WRITE_RTC
            movb        A,X,IBDR
        ; ultimo dato?
            cmpa        #6
            bne         return`
        ;enviar señal de stop (Modo S)
            bclr        IBCR,$20                        
            bra         return`
finish_wr`
            bset        BANDERAS,$01
return`
            inc         Index_RTC
            rts 
error`     
            bra         return`


; *****************************************************************************
;                            Read_RTC Subrutine
; *****************************************************************************
Read_RTC:       
            loc
            ldaa        Index_RTC
        ;Primer uso
            bne         next0`          
        ; Se envia la direccion a leer (Segundos)    
            movb        Dir_Seg,IBDR       
            bra         return`
next0`
            cmpa        #1
            bne         next1`
        ; Repeat start
            bset        IBCR,$04       
            movb        Dir_RD,IBDR
            bra         return`
next1`
            cmpa        #2             ;Tercera?
            bne         next2`
        ; Borra repeated start, pasa a rx y pone en 0 el ack
            bclr        IBCR,$1C       
        ; Lectura dummy 
            ldab        IBDR           
            bra         return`
next2`
        ; Ultimo
            cmpa        #9             
            bne         next3`
        ; borra el no ack (8), stop (2)
            bclr        IBCR,$28       
        ; Tx
            bset        IBCR,$10             
            bra         return`
next3`
            cmpa        #8
            bne         next4`
        ; Pone un no ack
            bset        IBCR,$08              
next4`          
        ; A-3 = > las primeras 3 interrupciones
            suba        #3                
            ldx         #T_Read_RTC
        ;Se mueve el dato a la posicion de T_read_RTC
            movb        IBDR,A,X       
return`     
            inc         Index_RTC           
            rts

; ************************************ISR*************************************
; *****************************************************************************
;                           IIC_ISR Subroutine
; *****************************************************************************
IIC_ISR:
            loc
            bset        IBSR,$20
        ;check CONT_RTI
            brset       BANDERAS,$02,read`
            jsr         WRITE_RTC
            bra         return`
read`
            jsr         READ_RTC
return`:
            rti

; *****************************************************************************
;                           RTI_ISR Subroutine
; *****************************************************************************
RTI_ISR:
            loc
            bset        CRGFLG,$80
        ;check CONT_RTI
            tst         CONT_RTI
            beq         chk_read`
            dec         CONT_RTI
            bra         return`
chk_read`
            movb        #50,CONT_RTI
        ; check read_enable flag
            brclr       BANDERAS,$01,return`
        ;Read mode
            bset        BANDERAS,$02
            movb        Dir_WR,IBDR 
        ; Setea Master & Tx
            bset        IBCR,$30
            clr         Index_RTC
return`:
            rti

; *****************************************************************************
;                           PHO_ISR Subroutine
; *****************************************************************************
PTH_ISR:
        ; Skip on MODO_CONFIG
            brset       PIFH,$01,PH0
            brset       PIFH,$04,PH2
            brset       PIFH,$08,PH3
            bra         RETURN_PTH
PH0:
            bset        PIFH,$01
            ;Inicio de comunicaciones, write=0 , rele_flg
            bclr        BANDERAS,$12
            ;IBEN=1, IBIE=1 MS=1(START), TX=1, txak=0(9no ciclo)
            movb        #$F0,IBCR                                 
        ;Se envia direccion de escritura    
            movb        Dir_WR,IBDR                                        
            clr         Index_RTC
            bra         RETURN_PTH
PH2:
            bset        PIFH,$04
            ldaa        BRILLO
            beq         RETURN_PTH
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
;                           OC4_ISR Subroutine
; *****************************************************************************
;Descripcion:
;   Subrutina encargada del manejo de la pantalla de 7 segmentos, el contenido
; de los displays, el brillo y la subrutina bcd 7 segmentos. Ademas decrementa
; CONT_DELAY, asistiendo al control de la pantalla LED.
;Entrada:
;   * DT: determina si se apaga la pantalla, controlando asi el brillo con
;       el valor obtenido en ATD_ISR.
;   * DIG1,DIG2,DIG3,DIG4: Contenido que se debe mostrar en el display de
;       7 segmentos
;   * LEDS: Variable que determina el patron de los leds
;Salida:
;   * CONT_DELAY: contador de retraso para contador de pantalla de LEDS
;   * CONT_7SEG: contador de retraso para contador de pantalla de 7 segmentos
; *****************************************************************************
OC4_ISR:
            loc
            ldaa        CONT_TICKS
            ldab        #100
            subb        BRILLO
            stab        DT
            cba
            bge         apagar`
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
            movb        DIG1, PORTB
            bset        PTJ, $02
            bra         incticks`
dig2`
            cmpa        #2
            bne         dig3`
            bclr        PTP, $04
            ldaa        DIG2
            cmpa        #$3F
            beq         ndig2`
            movb        DIG2, PORTB
            bset        PTJ, $02
ndig2`
            bra         incticks`
dig3`
            cmpa        #3
            bne         dig4`
            bclr        PTP, $02
            movb        DIG3, PORTB
            bset        PTJ, $02
ndig3`
            bra         incticks`
dig4`
            cmpa        #4
            bne         digleds`
            bclr        PTP, $01
            ldaa        DIG4
            cmpa        #$3F
            beq         ndig4`
            movb        DIG4, PORTB
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