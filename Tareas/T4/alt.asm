;       Subrutina MUX_TECLADO
MUX_TECLADO:    loc
                ldab #0
                movb #0,PATRON
                ldx #TECLAS
mainloop`       tst PATRON
                bne p1
                movb #$EF,PORTA
                bra READ
p1:             ldaa #1
                cmpa PATRON
                bne p2
                movb #$DF,PORTA
                bra READ
p2:             inca                    ;A=2
                cmpa PATRON
                bne p3
                movb #$BF,PORTA
                bra READ
p3:             inca                    ;A=3
                cmpa PATRON             ;Se detecta cual patron se debe usar en la salida
                bne nk
                movb #$7F,PORTA
read:           brclr PORTA,$01, treturn`       ;se leen las entradas para encontrar la tecla presionada
                incb
                brclr PORTA,$02, treturn`
                incb
                brclr PORTA,$04, treturn`
                incb
                inc PATRON
                bra mainloop`
nk              movb #$FF,TECLA                 ;Se guarda la tecla o se retorna FF
                bra return`
treturn`        movb B,X,TECLA
return`         rts


; *****************************************************************************
;                           Subroutine  Print_RESULT
; *****************************************************************************

            ; DELETE OR COMMENT
Print_Result:
            ldab        Cont_TCL
            ldaa        #0
            pshd
            ldd         #MSG2
            ldx         #0
        ; Print CONT value
            jsr         [PrintF,X]
            leas        2,SP
            ldy         #Num_Array

LOOP_P`:      
            ldx         #0
            ldab        1,Y+
        ; Avoid PrintF to modify Y
            pshy
            pshb
        ; Make b the right size
            ldab        #0
            pshb
            ldaa        Cont_TCL
            cmpa        #$1
            bne         NEXT
        ; Prints Final number
            ldd         #MSG4
            jmp         PRINT_E

NEXT:
        ;Prints Number and a comma
            ldd         #MSG3
PRINT_E:
            jsr         [PrintF,X]
            leas        2,SP
            puly
            dec         Cont_TCL
            ldaa        Cont_TCL
            bne         LOOP_P`
            rts



