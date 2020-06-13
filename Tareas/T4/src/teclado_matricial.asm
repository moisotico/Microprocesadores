; Moises Campos Zepeda
; 15-06-2020
; IE0623: Microprocesadores
; Tarea 4: teclado matricial


#include registers.inc

; *****************************************************************************
;                           Data Structures
; *****************************************************************************
            org         $1000
; Size of Num_Array	
    MAX_TCL:        db  #5
    Tecla:          ds  1
    Tecla_IN:       ds  1
    Cont_Reb:       ds  1
    Cont_TCL:       ds  1
    Patron:         ds  1
    Banderas:       ds  3

; Array of pressed buttons, by default $FF
    Num_Array:      ds  #MAX_TCL         

; Key values  
    Teclas:         db  $01,$02,$03,$04,$05,$06,$07,$08,$09,$0B,$0,$0E
    

; *****************************************************************************
;                               HW Config
; *****************************************************************************
            org         $2000
        ; PHO
            bset        PIEH,$01
        ; Enable pullup resistors on Port A
            bset        PUCR,$01    
        ; RTI
            bset        CRGINT,$80
        ; T = 11 ms 
        ;   movb        $4A,RTICTL               


; *****************************************************************************
;                               Main Program
; *****************************************************************************
            lds     #$3BFF

            bra     *
    
; *****************************************************************************
;                               X Subroutine
; *****************************************************************************