; Moises Campos Zepeda
; 25-05-2020
; IE0623: Microprocesadores
; Tarea #2
; Problema # 2
; Nota: el codigo se comento en ingles
; *****************************************************************************
;                           Declaracion de Estructuras de datos
; *****************************************************************************
                    org     $1050
DATOS:              db $63,$75,$63,$8,$64,$7,$56,$29,$71,$28,$80,$7,$41,$59
                    db $8,$5,$59,$93,$71,$7,$82,$68,$58,$34,$98,$2,$35,$87
                    db $51,$54,$23,$93,$47,$88,$0,$60,$22,$64,$6,$79,$68,$15
                    db $20,$17,$83,$38,$93,$80,$27,$36,$4,$41,$31,$25,$91,$80

                    org     $1150
MASCARAS:           db $8,$5,$59,$93,$71,$7,$82,$68,$58,$34,$98,$2,$35,$87
                    db $63,$75,$63,$8,$64,$7,$56,$29,$71,$28,$80,$7,$41,$59
                    db $20,$17,$80,$38,$93,$80,$27,$36,$4,$41,$31,$25,$91,$30
                    db $51,$54,$23,$93,$47,$88,$0,$60,$22,$64,$6,$79,$68,$FE

                    org     $1300
NEGAT:               ds 1000


                    org     $1400
TEMP:               ds $2
RESULT:             ds $2

; *****************************************************************************
;                               Main Program
; *****************************************************************************



                    org     $2000

                    Ldx         #DATOS
                    
                    Ldy         #MASCARAS

DATA_END:           
                    
                    cpx         #$80 
                    beq         LOOP
                    inx
                    jmp         DATA_END

LOOP:
                ; Review for negative results  
                    ldaa        0, y
                    eora        0, x
                    cmpa         #$0

                ;Adding to NEGAT    
                    bgt         CHECK_MASKS
                    sty         TEMP
                    Ldy         #NEGAT
                    staa        1, y+
                    sty         [NEGAT, y]
                    Ldy         TEMP
CHECK_MASKS:
                    cpy         #$FE
                    beq         FIN
                    iny
                    jmp         LOOP

FIN:                
                    bra         FIN


