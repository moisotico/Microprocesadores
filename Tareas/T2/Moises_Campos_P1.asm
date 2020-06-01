; Moises Campos Zepeda
; 25-05-2020
; IE0623: Microprocesadores
;Tarea #2
; Problema # 1
; Nota: el codigo se comento en ingles
; *****************************************************************************
;                           Declaracion de Estructuras de datos
; *****************************************************************************


; Dirs of data to test
BIN:            equ                        $1000

BCD:            equ                        $1002

; Dirs of data to save
NUM_BCD:        equ                        $1010

NUM_BIN:        equ                        $1020


; Data to use
                        org                     $1000
                        
                        ; Valor de prueba #525 
                dw                              #125
                                
                        org                     $1002

                        ; Valor de prueba #1250 
                dw                              $1250

; Variables Temporales
                        org                     $1100
TEMP:           ds                      2
LOW:            ds                      1
MID:            ds                      1

; *****************************************************************************
;                               Main Program
; *****************************************************************************

                        org         $2000
                        Ldy                     #0
                        Ldd                     BIN
                        jmp                     BIN_BCD

RETURN_BCD:
                        Ldy                     #0
                        ldx                     #0
                        ldd                     BCD
                        jmp                     BCD_BIN

END:
                        jmp                     END



; *****************************************************************************
;                           Subrutine  BIN_BCD
; *****************************************************************************
BIN_BCD:
                        ldx                     #15
                
                        ; NUM_BCD:NUM_BCD+1 = 0

                        clr                     NUM_BCD
                        clr                     NUM_BCD+1
                        clr                     NUM_BCD+2
                        ldy                     NUM_BCD

                        ;asld
                        ;asld
                        ;asld
                        ;asld
                        ;std                     BIN

LOOP_1:        
                        asld
                        rol                     NUM_BCD+2
                        rol                     NUM_BCD+1
                        ;rol                     NUM_BCD



                ; Store A:B in TEMP
                        std                     TEMP

                ; Compare first 4 bytes
                        ldd                     NUM_BCD+1
                        andb                    #$0F
                        cmpb                    #5
                        bcs                     NEXT_1
                        addb                    #3
NEXT_1:
                ; Store B
                        stab                    LOW

                ; Compare next 4 bytes
                        ldd                     NUM_BCD+1
                        andb                    #$F0
                        cmpb                    #$50
                        bcs                     NEXT_2
                        tba
                        clrb
                        adda                    #$30
                        daa
                        tab
                        clra

NEXT_2:

                ; Store in NUM_BCD+1
                        addd                   LOW
                        daa
                ; Store A in MID and in NUM_BIN+1
                        std                    NUM_BCD+1

                ; Compare last 4 bytes
                        ldd                     NUM_BCD
                        andb                    #$F0
                        
                        anda                    #$0F
                        cmpa                    #$5
                        bcs                     NEXT_3
                        adda                    #$03
                        daa
                        
NEXT_3:
                ; Add MID to D and store in NUM_BCD

	                staa                   	NUM_BCD
                        
                ; Load previous value in D
                        ldd                     TEMP
                        dex

                ; Is x == 0
                        beq                     EXIT_L1
                        jmp                     LOOP_1

EXIT_L1:
                ; Return to the main program
                        lsld
                        rol                     NUM_BCD+1
                        ;rol                     NUM_BCD
                        jmp                     RETURN_BCD


; *****************************************************************************
;                           Subrutine  BCD_BIN
; *****************************************************************************
BCD_BIN:
                        sty                     NUM_BIN
                        Ldy                     NUM_BIN

                ; First 4 bits
                        andb                    #$0F
                        aby
                        sty                     NUM_BIN

                ; Second group of 4 bits
                        ldd                     BCD
                        andb                    #$F0
                ; Transform B = $x0 to B = $0x
                        lsrb
                        lsrb
                        lsrb
                        lsrb
                ; D = B * 10
                           ldaa                    #10
                        mul
                        addd                    NUM_BIN
                        std                     NUM_BIN

                ; Third gorup of 4 bits                        
                        ldd                     BCD
                        anda                    #$0F
                        ldab                    #100
                        mul
                        addd                    NUM_BIN
                        std                     NUM_BIN


                ; Final group of 4 bits                        
                        ldd                     BCD
                        anda                    #$F0
                    ; Transform A = $X0 to A = $0X
                        lsra
                        lsra
                        lsra
                        lsra
                ; D = A * B
                        ldab                    #100
                        mul
                ; D = D *10
                        ldy                     #10
                        emul
                        addd                    NUM_BIN
                        std                     NUM_BIN

                ; End of subroutine
                        jmp                     END