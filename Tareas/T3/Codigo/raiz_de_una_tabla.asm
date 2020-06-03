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
PRINTF:     equ     $EE88
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
ENTERO:     ds      100

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
MESS0:     fcc "IE0623: Microprocesadores. Tarea #3. Elaborada por Moises Campos"
            db CR,LF,FIN 

MESS1:      fcc "Ingrese el valor de cant Entre 1 y 99"
            db CR,LF,FIN

MESS2:      fcc "Cantidad de valores encontrados %i"
            db CR,LF, FIN

MESS3:      fcc "Entero: "
            db FIN

; *****************************************************************************
;                               Main Program
; *****************************************************************************
            org             $2000
            
            clra
            clrb
            ;jsr     LEER_CANT

            
            jsr     LEER_CANT


; *****************************************************************************
;                           Subroutine  LEER_CANT
; *****************************************************************************
LEER_CANT:
        ; SP stack pull
            puly
        ; CANT = $2 meanwhile

        ;TODO: Routine

        ; SP stack push
            pshy
            rts 


; *****************************************************************************
;                           Subroutine  BUSCAR
; *****************************************************************************
        ; SP stack pull
            puly

        ;TODO: Routine

        ; Test 1
            ldab        #4
            pshb
            jsr         RAIZ
            pulb

        ; Test 2
            ldab        #9
            pshb
            jsr         RAIZ
            pulb

        ; SP stack push
            pshy
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
            abx
            xgdx
            lsrd
            std         TEMP_VAR2

        ; h value of algorithm
            ldx         TEMP_VAR1        
            idiv
            ldd         TEMP_VAR2
        ; b = h ?
            cmpd        0,J
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