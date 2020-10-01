; Moises Campos Zepeda
; 20-09-2020
; IE0623: Microprocesadores
; Tarea #2
; Problema # 3
; Nota: el codigo se comento en ingles
; *****************************************************************************
;                           Data Structures
; *****************************************************************************
                org     $1000
L:              db      12
CANT4:          ds      1

                org     $1100
DATOS:          db      $51,$A4,$23,$92,$47,$18,$A1,$60,$27,$78,$69,$FC

                org     $1200
DIV4:           ds      255

; *****************************************************************************
;                               Main Program
; *****************************************************************************
                org     $2000
                clr	    CANT4
                ldx         #DATOS
                ldy         #Div4
                ldab        #0
LOOP:           
                ldaa        0,X
                cmpa        #0
                bge         CHK_CARRY
                nega
CHK_CARRY:
                lsra
                bcs         NEXT
                lsra
                bcs         NEXT
        ; if %4 = 0  
                inc         CANT4
                movb         0,X,1,Y+
NEXT:           
                incb            
                cmpb        L
                bcc         FIN
                inx
                bra         LOOP
FIN:            
                bra         *