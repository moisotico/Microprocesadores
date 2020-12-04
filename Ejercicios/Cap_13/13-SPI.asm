; Moises Campos Zepeda
; 30-11-2020
; IE0623: Microprocesadores
; Ejemplo: generador diente de sierra

; Include File
#include registers.inc


; *****************************************************************************
;                           Data Structures
; *****************************************************************************
CR:             equ $0D
LF:             equ $0A
EOM:            equ $FF

            org             $1000
CONT_DA:    ds  2 

MSG:        fcc "                           UNIVERSIDAD DE COSTA RICA"
            fcb CR,LF
            fcc "                        Escuela de Ingenieria Electrica"
            fcb CR,LF
            fcc "                              Microprocesadores"
            fcb CR,LF
            fcc "                                   IE0623"
V_ASCII:
            fcb 82,71,82,CR,LF
            fcc " "
            fcb CR,LF
            fcc " "
            fcb CR,LF
            db  EOM


; *****************************************************************************
;                       Interruption Vector Relocation
; *****************************************************************************
                org $3E70
                dw RTI_ISR
            
; *****************************************************************************
;                           HW Config
; *****************************************************************************
            org     $2000
        ;RTI                       
            movb        #$49,RTICTL
            bset        CRGINT,$80
        ;SPI por pooling
            movb        #$50,SPI0CR1    ;master
            bclr        SPI0CR2,$FF     ; dispositivo como salida
            movb        #$45,SPI0BR     ; Bit_rate = 75kbps
            bset        DDRM,$40
            bset        PTM,$40
            bset        DDRB,$01
            bset        PORTB,$01

; *****************************************************************************
;                           Main Program
; *****************************************************************************
            loc
            lds         #$3BFF
            cli
            movw        #0,CONT_DA
loop`
            wai
            bra         loop`
; *****************************************************************************
;                           RTI_ISR
; *****************************************************************************
RTI_ISR:    loc
            ldd         CONT_DA
            addd        #1
            cpd         #1024
            bne         skip`
            movw        #0,CONT_DA
            ldab        PORTB
            eorb        #$01
skip`
            bclr        PTM,$40 ; CS =0
chk_sptef`
            brclr       SPI0SR,$20,chk_sptef`
            ldd         CONT_DA
            asld
            asld
            brclr       SPI0SR,$20,chk_sptef`
            stab        SPI0DR
            brclr       SPI0SR,$20,chk_sptef`
            bset        PTM,$40
            bset        CRGFLG,$80
            rti
