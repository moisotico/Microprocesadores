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

; Message keywords
CR:         equ     $0D
LF:         equ     $0A
FIN:        equ     $0

            org         $1000
LONG:       db      #12
CANT:       ds      1
CONT:       ds      1
CONT_B:     ds      1

            org         $1010
ENTERO:     ds      12

            org         $1020
DATOS:      db      4,9,18,4,27,63,12,32,36,15,49,64

; Perfect squares from 1 to 255
            org         $1030
CUAD:       db      1,4,9,16,25,36,49,64,81,100,121,144,169,196,225

; Additional variables
TEMP:       ds      2
TEMP_1:     ds      2
TEMP_2:     ds      2

            org         $1100
; Messages
MSG_I:      fcc "IE0623: MICROPROCESADORES. TAREA #3. ELABORADA POR MOISES CAMPOS ZEPEDA"
            fcb CR,CR,LF,LF,FIN
            
MSG_N_1:     fcc "%i"
            fcb LF,FIN
            
MSG_N_2:     fcc "%i"
            fcb CR,CR,LF,FIN

MSG0:       fcc "INGRESE EL VALOR DE CANT (ENTRE 1 Y 99): "
            fcb CR,CR,LF,LF,FIN

MSG1:       fcc "EL VALOR SELECCIONADO EN CANT ES: %i"
            fcb CR,CR,LF,FIN

MSG2:       fcc "CANTIDAD DE VALORES ENCONTRADOS: %i"
            fcb CR,CR,LF,FIN

MSG3:       fcc "VALORES EN ENTERO: "
            fcb FIN

MSG4:       fcc "%i, "
            fcb LF, FIN

MSG5:       fcc "%i"
            fcb CR,CR,LF,FIN

ERR0:       fcc "ERROR: LA TECLA INGRESADA NO ES VALIDA!"
            fcb CR,CR,LF,FIN

ERR1:       fcc "ERROR: EL VALOR $00 NO ES VALIDO!"
            fcb CR,CR,LF,FIN


; *****************************************************************************
;                               Main Program
; *****************************************************************************
                org             $2000
            ; Stack place 
                lds         #$3BFF
                ldx         #0
                ldd         #MSG_I
                jsr         [PrintF,X]
                clra
                clrb
                clr         CONT
            ; Subroutines
                jsr         LEER_CANT
                jsr         BUSCAR
                jsr         Print_RESULT
            ; End of Program
                bra         *


; *****************************************************************************
;                           Subroutine  LEER_CANT
; *****************************************************************************
LEER_CANT:
                movb        #$FF,CANT
                ldx         #0
                ldd         #MSG0
LOOP_CANT_A:
                jsr         [PrintF,X]
                ldx         #0
LOOP_CANT_B:
                jsr         [GETCHAR,X]
            ;check valid char
                cmpb        #$30
                blo         CATCH_1
                cmpb        #$39
                bhi         CATCH_1
            ;CANT = $FF ?
                ldaa        CANT
                cmpa        #$FF
                bne         CHK_VAL
           ; first digit
                subb        #$30
                andb        #$0F
                stab        CANT
          ; Show CANT
                clra
                pshd
                ldx         #0
                ldd         #MSG_N_1
                jsr         [PrintF,X]
                puld
                ldaa        #10
                mul
                stab        CANT
                ldx         #0
                bra         LOOP_CANT_B
CHK_VAL:
            ; second digit of two
                subb        #$30
                clra
                pshd
                ldx         #0
                ldd         #MSG_N_2
                jsr         [PrintF,X]
                puld
                ldaa        CANT
                aba
                tab
                stab        CANT
                cmpb        #0
                beq         CATCH_2
            ; Store CANT
                clra
                pshd
                ldx         #0
            ; Show CANT
                ldd         #MSG1
                jsr         [PrintF,X]
                leas        2,SP
                rts
CATCH_1:
            ; catch invalid char
                ldx         #0
                ldd         #ERR0
                bra         LOOP_CANT_A
CATCH_2:
            ; Reset CANT
                movb        #$FF,CANT
            ; catch invalid char
                ldd         #ERR1
                jmp         LOOP_CANT_A

; *****************************************************************************
;                           Subroutine  BUSCAR
; *****************************************************************************
BUSCAR:
                ldx         #DATOS
                ldy         #CUAD
                ldd         #0
                clr         CONT_B                
LOOP_BUSCAR:
            ; A = (CANT) || A = (LONG)
                ldaa        CONT_B
                cmpa        CANT
                beq         RETURN_BUSCAR
                cmpa        LONG
                beq         RETURN_BUSCAR
            ; Stack A counter
                ldaa        0,X
                ldab        0,Y
                cba
                beq         MATCH
                cmpb        #225
            ; No Match        
                beq         INCREASE
                iny
                bra         LOOP_BUSCAR
MATCH:
                pshx      
                psha
                jsr         RAIZ
                pula
                pulx
                ldy         #ENTERO
                ldab        CONT
                staa        B,Y        
                iny
                inc         CONT
INCREASE:
                inx
                ldy         #CUAD
                inc         CONT_B
                bra         LOOP_BUSCAR
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
                clr         TEMP_1
            ; X = 1
                ldx         #1
                std         TEMP_2
BABYLON:
                cpx         TEMP_1
                beq         RETURN_RAIZ
            ; b value of algorithm
                ldd         TEMP_1
                abx
                xgdx
                lsrd
                xgdx
                stx         TEMP_1
            ; h value of algorithm, X = TEMP_2 / b value
                ldd         TEMP_2        
                idiv
                bra         BABYLON
RETURN_RAIZ:
            ; SP stack push
                xgdx
                pshb
                pshy
                rts

; *****************************************************************************
;                           Subroutine  Print_RESULT
; *****************************************************************************
                loc
Print_RESULT:
                ldab        CONT
                ldaa        #0
                pshd
                ldd         #MSG2
                ldx         #0
            ; Print CONT value
                jsr         [PrintF,X]
                leas        2,SP
                ldy         #ENTERO
LOOP`:      
                ldx         #0
                ldab        1,Y+
            ; Avoid PrintF to modify Y
                pshy
                pshb
            ; Make b the right size
                ldab        #0
                pshb
                ldaa        CONT
                cmpa        #$1
                bne         NEXT
            ; Prints Final number
                ldd         #MSG5
                jmp         PRINT_E
NEXT:
        ;Prints Number and a comma
                ldd         #MSG4
PRINT_E:
                jsr         [PrintF,X]
                leas        2,SP
                puly
                dec         CONT
                ldaa        CONT
                bne         LOOP`
                rts