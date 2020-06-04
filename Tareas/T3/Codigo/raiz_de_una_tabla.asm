; Moises Campos Zepeda
; 25-05-2020
; IE0623: Microprocesadores
; Tarea #3 
; Nota: el codigo se comento en ingles
; *****************************************************************************
;                       Data Structures Declaration
; *****************************************************************************
; $1000,  CANT en $1001, CONT en $1002, y ENTERO en $101

; Subroutine direction pointers
PrintF:     equ     $EE88
GETCHAR:    equ     $EE84
PUTCHAR:    equ     $EE86

; Message keywords
CR:         equ     $0D
LF:         equ     $0A
FIN:        equ     $0

            org         $1000
LONG:       db      #10         
CANT:       ds      1
CONT:       ds      1

            org         $1010
ENTERO:    ds       100

            org         $1020
DATOS:      db      4,9,18,4,27,63,12,32,36,15

; Perfect squares from 1 to 255
            org         $1030
CUAD:       db      1,4,9,16,25,36,49,64,81,100,121,144,169,196,225

; Additional variables
TEMP:       ds      2
TEMP_VAR1:  ds      2
TEMP_VAR2:  ds      2

            org         $1100
; Messages
MSG0:       fcc "IE0623: Microprocesadores. Tarea #3. Elaborada por Moises Campos"
            fcb CR,CR,LF,FIN 

MSG1:       fcc "Ingrese el valor de cant Entre 1 y 99"
            fcb CR,CR,LF,FIN

MSG2:       fcc "Valor ingresado %i"
            fcb CR,CR,LF,FIN

MSG3:       fcc "Cantidad de valores encontrados %i"
            fcb CR,CR,LF,FIN

MSG4:       fcc "Valores en ENTERO: "
            fcb FIN

MSG5:       fcc "%i, "
            fcb FIN

MSG5:       fcc "%i"
            fcb FIN

ERR1:       fcc "ERROR: La tecla ingresada no es valida!"
            fcb CR,CR,LF,FIN

ERR2:       fcc "ERROR: El valor $00 no es valido!"
            fcb CR,CR,LF,FIN


; *****************************************************************************
;                               Main Program
; *****************************************************************************
            org             $2000

        ; Stack place 
;            lds     #$3BFF
;            ldx     #0
;            ldd     #MSG0
;            jsr     [PrintF,X]

            clra
            clrb
            jsr     LEER_CANT

        ;    jsr     BUSCAR
        ;    jsr     Print_RESULT
        ; End of Program
            bra     *



; *****************************************************************************
;                           Subroutine  LEER_CANT
; *****************************************************************************
LEER_CANT:
            ldaa    #$FF
            staa    CANT
            ldx     #0
            ldd     #MSG1

LOOP_CANT_A:
            jsr     [PrintF,X]

LOOP_CANT_B:
            ldx     #0
            jsr     [GETCHAR,X]
        ;check valid char
            cpd     $30
            blo     CATCH_1
            cpd     $39
            bhi     CATCH_1`
        ;CANT = $FF ?
            ldaa    #$FF
            cmpa    CANT
            bne     CHECK_VALUE
        ;first digit of two
            subb    #$30
            orab    #$F0
            stab    CANT
            jmp     LOOP_CANT_B

CHECK_VALUE:
            subb    #$30
            ldaa    #$0A
            mul
            addd    #CANT
            cpd     #0
            beq     CATCH_2
        ; Store CANT
            clra
            stab    CANT
            ldx     #0
        ; Show CANT
            clra    
            ldab    #CANT
            pshd
            ldd     #MSG2
            jsr     [PrintF,X]
            leas    2,SP
            rts

CATCH_1:
        ; catch invalid char
            ldx     #0
            ldd     #ERR1
            jsr     [PrintF,X]
            jmp     LOOP_CANT_A

CATCH_2:
        ; Reset CANT
            ldaa    #$FF
            staa    CANT
        ; catch invalid char
            ldx     #0
            ldd     #ERR2
            jsr     [PrintF,X]
            jmp     LOOP_CANT_A


; *****************************************************************************
;                           Subroutine  BUSCAR
; *****************************************************************************
BUSCAR:
            ldx         #DATOS
            ldy         #CUAD
            clra
            clrb

LOOP_BUSCAR:
        ; A = (CANT) || A = (LONG)
            cmpa        CANT
            beq         RETURN_BUSCAR
            cmpa        LONG
            beq         RETURN_BUSCAR
        ; Stack A counter
            psha                    
            ldaa        0,X
            ldab        0,Y
            cba
            beq         MATCH
            cmpb        #$E1
        ; No Match        
            beq         INCREASE
            iny
            pula
            jmp         LOOP_BUSCAR

MATCH:      
            pshx      
            psha
            jsr         RAIZ
            pula
            pulx
            sty         TEMP
            ldy         #ENTERO
            ldab        CONT
            staa        B,Y        
            inc         CONT
            jmp         INCREASE    

INCREASE:
            inx
            ldy         #CUAD
            pula
            inca
            jmp         LOOP_BUSCAR

RETURN_BUSCAR:
            rts 


; *****************************************************************************
;                           Subroutine  RAIZ
; *****************************************************************************
RAIZ:
        ; SP stack pull
            puly
            pulb
            clra
        ; X = 1
            ldx        #1
            std        TEMP_VAR1

BABYLON:
        ; b value of algorithm
            leax        D,X
            xgdx
            lsrd
            xgdx
            stx         TEMP_VAR2
        ; h value of algorithm, X = TEMP_VAR1 / b value
            ldd         TEMP_VAR1        
            idiv
            ldd         TEMP_VAR2
        ; b = h ?
            cpx         TEMP_VAR2
            beq         RETURN_RAIZ
            jmp         BABYLON

RETURN_RAIZ:
        ; SP stack push
            pshb
            pshy
            rts


; *****************************************************************************
;                           Subroutine  Print_RESULT
; *****************************************************************************
        ;TODO: Routine
Print_RESULT:
            clra
            ldab        #CONT
            pshd
            ldx         #0
            ldd         #MSG3
            jsr         [PrintF,X]
            leas        2,SP
            ldy         #ENTERO
            ldx         #0
            ldd         #MSG4

LOOP_PRINT:
            jsr         [PrintF,X]
            leas        2,SP
            clra
            ldab        0,Y
            pshd
            ldx         #0
            cpx         #CONT
            beq         RETURN_PRINT
            ldd         #MSG5
            dec         CONT
            iny
            jmp         LOOP_PRINT
            
RETURN_PRINT:
            ldd         #MSG6
            jsr         [PrintF,X]
            rts        