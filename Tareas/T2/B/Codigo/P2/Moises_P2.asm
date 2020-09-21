; Moises Campos Zepeda
; 25-09-2020
; IE0623: Microprocesadores
; Tarea #2
; Problema # 2
; Nota: el codigo se comento en ingles
; *****************************************************************************
;                           Data Structures
; *****************************************************************************
                org     $1050
DATOS:          db 	    $63,$75,$63,$8,$64,$7,$56,$29,$71,$28,$81,$7,$41,$59
                db 	    $8,$5,$59,$93,$71,$7,$82,$68,$58,$34,$98,$2,$35,$87
                db 	    $20,$17,$83,$38,$93,$87,$27,$36,$4,$41,$31,$25,$91,$80

                org     $1150
MASCARAS:       db      $8,$5,$D9,$93,$71,$7,$82,$68,$58,$34,$98,$2,$35,$87
                db      $20,$17,$80,$38,$93,$F0,$27,$36,$4,$41,$31,$25,$C1,$30
                db      $51,$A4,$23,$93,$47,$88,$A0,$60,$22,$64,$6,$79,$68,$FE

                org     $1300
NEGAT:          ds      1000

; Temp variables
                org     $1400
TEMP1:          ds      2
TEMP2:          ds      2

; *****************************************************************************
;                               Main Program
; *****************************************************************************
                org     $2000
                ldx         #DATOS
                ldy         #MASCARAS
                movw        #NEGAT,TEMP1
CHK_DATA_END:           
                ldaa        0,X 
                cmpa        #$80 
                beq         LOOP
                inx
                bra         CHK_DATA_END
LOOP:
            ; Review for negative results  
                ldaa        0,Y
                eora        0,X
                cmpa        #0
            ;Adding to NEGAT, can also use stack as an improvement    
                bge         CHECK_MASKS
                sty         TEMP2
                ldy         TEMP1
                staa        1,Y+
                sty         TEMP1
                ldy         TEMP2
CHECK_MASKS:
                ldab        0,Y 
                cmpb        #$FE
                beq         FIN
                iny
                dex
                jmp         LOOP
FIN:                
                bra         *


