;#################################################################
#include registers.inc



;#################################################################
;               Definicion de estructuras de datos


CR:             equ $0D
LF:             equ $0A
FIN:            equ $0

                org $1000
MAX_TCL:        db 5
TECLA:          ds 1
TECLA_IN:       ds 1

CONT_REB:       ds 1
CONT_TCL:       ds 1
PATRON:         ds 1
BANDERAS:       ds 1



NUM_ARRAY:      ds 6
TECLAS:         db $01,$02,$03,$04,$05,$06,$07,$08,$09,$0B,$00,$0E


                org $1200
MSG0:                  fcc "Tecla: %X"
                db CR,LF,CR,LF,FIN
                
MSG1:          fcc "Array OK"
                db CR,LF,CR,LF,FIN
                
                
                org $3E70
                dw INIT_ISR
                org $3E4C
                dw PTH0_ISR

;################################################
;       Programa principal
                org $2000

;################################################
;       Definicion de hardware

                bset PIEH, $01          ;habilitar interrupciones PH0
                bset PIFH, $01
                movb #$17, RTICTL       ;FIXME, esto lo pone en 9.26 ms
                bset CRGINT,$80        ;habilitar interrupciones rti
                movb #$F0,DDRA
                bset PUCR,$01          ;Habilita resistencia de pullup
                cli



;################################################
;       Programa

                lds #$3BFF
                movb #$FF, TECLA
                movb #$FF, TECLA_IN
                movb #$00, CONT_TCL
                movb #$00, CONT_REB
                bclr BANDERAS,$07      ;Poner las banderas en 0
                ldaa MAX_TCL
                ldx #NUM_ARRAY-1
LoopCLR:        movb #$FF,A,X          ;iniciar el arreglo en FF
                dbne A,LoopCLR
mainL:          brset BANDERAS,$04,mainL
                jsr TAREA_TECLADO
                bra mainL
;################################################
;       Subrutinas
;################################################
;       Subrutinas Generales


;       Subrutina Tarea Teclado
TAREA_TECLADO:  loc
                tst CONT_REB
                bne return`
                jsr MUX_TECLADO
                ldaa TECLA
                cmpa #$FF
                beq checkLista`
                brset BANDERAS,$02,checkLeida`        ;revision de bandera Tecla leida
                movb TECLA,TECLA_IN
                bset BANDERAS,$02
                movb #200,CONT_REB                       ;iniciar contador de rebotes
                bra return`
checkLeida`     cmpa TECLA_IN                           ;Comparar Tecla con tecla_in
                bne Diferente`
                bset BANDERAS,$01
                bra return`
Diferente`      movb #$FF,TECLA                         ;Las teclas son invalidas
                movb #$FF,TECLA_IN
                bclr BANDERAS,$03
                bra return`
checkLista`     brclr BANDERAS,$01,return`              ;el numero esta listo
        ; Print Tecla value
                ldab        Tecla_IN
                clra
                pshd
                ldx         #0
                ldd         #MSG0
                jsr         [PrintF,X]
                leas        2,SP
                bclr BANDERAS,$03
                jsr FORMAR_ARRAY
return`         rts

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

;       Subrutina formar array

FORMAR_ARRAY:   loc
                ldx #NUM_ARRAY
                ldaa TECLA_IN
                ldab CONT_TCL
                beq check_MAX`
                cmpa #$0E
                beq t_enter`
                cmpa #$0B
                beq t_borrar`
                cmpb MAX_TCL
                beq return`
                bra guardar`
check_MAX`      cmpa #$0E
                beq return`
                cmpa #$0B
                beq return`
guardar`        staa B,X
                incb
                stab CONT_TCL
                bra return`
t_enter`        bset BANDERAS,$04
            ; Print Array ok
                ldx         #0
                ldd         #MSG1
                jsr         [PrintF,X]
                movb #$0,CONT_TCL
                bra return`
t_borrar`       decb
                movb #$FF,B,X
                stab CONT_TCL
return`         rts

;################################################
;       Subrutinas de proposito especifico


;        subrutina de PHO

                loc
PTH0_ISR:       bset PIFH, $01          
                brclr BANDERAS,$04,returnPH0
            ;clean flg    
                bclr BANDERAS, $04                  ;limpiar la bandera
                ldy #NUM_ARRAY
                ldaa MAX_TCL
loop`           ldab 1,Y+
                cmpb #$FF                           ;primera condicion de parada
                beq returnPH0
                movb #$FF,-1,Y
                dbne A,loop`

returnPH0:      rti

;       subrutina de rti
                loc
INIT_ISR:       bset CRGFLG, $80
                tst CONT_REB
                beq return`
                dec CONT_REB
return`         rti