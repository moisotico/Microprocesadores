; Moises Campos Zepeda
; 25-05-2020
; IE0623: Microprocesadores
; Tarea #2
; Problema # 3
; Nota: el codigo se comento en ingles
; *****************************************************************************
;                           Declaracion de Estructuras de datos
; *****************************************************************************
                org     $1000
L:              ds      $1
COUNT4          ds      $1

                org     $1100
DATOS:          ds      255

                org     $1200
DIV4:           ds      255


; *****************************************************************************
;                               Main Program
; *****************************************************************************




                    org $2000
div4Prog:       
                ;
                movb    #0,COUNT4   
		        ldx     #DATOS
                dex
                ldy     #Div4
                ldaa    L
                ldab    #0
LOOP:           
                ror     A,X
                ; Check % 2
                blo     NOTMOD2
                ror     A,X
                bhs     MOD4
NOTMOD4:
                rol     A,X
NOTMOD2:        
                ; Decrement counter   
                rol     A,X              
                dbne    A, LOOP
                bra     Fin
MOD4:           
                ; if %4=0 return to original, use C for branch 
                rol     A,X            
                rol     A,X                 
                movb    A,X,B,Y
                incb
                inc     COUNT4
                dbne    A,LOOP
FIN:            
                bra     FIN