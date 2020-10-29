




; *****************************************************************************
;                           OC4_ISR Subroutine
;   Subrutina OC4
OC4_ISR:
            loc
            ldaa        CONT_TICKS
            ldab        #100
            subb        BRILLO
            cba
            beq         apagar`
            tst         CONT_TICKS
            beq         check_digit`
checkN`         
            cmpa        #100
            beq         changeDigit`
incticks`
            inc         CONT_TICKS
            jmp         part2`
;Apagar
apagar`
            movb        #$FF,PTP
            movb        #$0, PORTB
            bra         checkN`
changeDigit`
            movb        #$0,CONT_TICKS
            ldaa        #5
            cmpa        CONT_DIG
            bne         jpart2` 
            clr         CONT_DIG
jpart2`
            inc         CONT_DIG
            bra         part2`
check_digit`
            ldaa        CONT_DIG
            cmpa        #1
            bne         dig2`
            bclr        PTP, $08
            movb        DISP1, PORTB
            bset        PTJ, $02
            bra         incticks`
dig2`
            cmpa        #2
            bne         dig3`
            bclr        PTP, $04
            ldaa        DISP2
            cmpa        #$3F
            beq         ndig2`
            movb        DISP2, PORTB
            bset        PTJ, $02
ndig2`
            bra         incticks`
dig3`
            cmpa        #3
            bne         dig4`
            bclr        PTP, $02                
            brset       BANDERAS,$08,ndig3`
            movb        DISP3, PORTB
            bset        PTJ, $02
ndig3`
            bra         incticks`
dig4`
            cmpa        #4
            bne         digleds`
            bclr        PTP, $01
            brset       BANDERAS,$08,ndig4`
            ldaa        DISP4
            cmpa        #$3F
            beq         ndig4`
            movb        DISP4, PORTB
            bset        PTJ, $02
ndig4`
            jmp         incticks`
digleds`
            movb        LEDS, PORTB
            bclr        PTJ, $02
            inc         CONT_TICKS

part2`
            tst         CONT_DELAY
            beq         tst7seg`
            dec         CONT_DELAY
tst7seg`
            ldx         CONT_7SEG
            beq         JBCD_7SEG`
            dex
            stx         CONT_7SEG
returnOC4
            ldd         TCNT
            addd        #60
            std         TC4
            rti
JBCD_7SEG`
            movw        #5000,CONT_7SEG
            jsr         BCD_7SEG
            bra         returnOC4

; *****************************************************************************
;                           OC4_ISR Subroutine
; *****************************************************************************
OC4_ISR:    loc
            ldaa        CONT_TICKS
            ldab        #100
            subb        BRILLO
            cba
            bne         NO_TICKS`
            movb        PTP,$FF
            clr         PORTB
            bra         TOP_TICKS
NO_TICKS`
            tst         CONT_TICKS
            beq         CHK_DIGTS
TOP_TICKS  
            ldaa        CONT_TICKS
            cmpa        #100
            beq         CHK_CD
            inc         CONT_TICKS
CHK_SEG
            ldx         CONT_7SEG
            cpx         #0
            bne         DEC_7SEG
            movw        #5000,CONT_7SEG
            jsr         CONV_BIN_BCD
            jsr         BCD_7SEG
            bra         CHK_DELAY
DEC_7SEG
            dex
            stx         CONT_7SEG
CHK_DELAY
            tst         Cont_Delay
            beq         RETURN`
            dec         Cont_Delay
RETURN`
            ldd         TCNT
            addd        #60
            std         TC4
            rti

CHK_CD:     ldaa        #5
            cmpa        CONT_DIG
            bcs         INC_CD
            clr         CONT_DIG
INC_CD:
            inc         CONT_DIG
            clr         CONT_TICKS
            bra         CHK_SEG
CHK_DIGTS:
            ldaa        CONT_DIG
            cmpa        #1
            bne         DIG2
            bclr        PTP,$08
            movb        DISP1,PORTB
            bset        PTJ,$02
            bra         RESUME_TCKS       
DIG2:
            cmpa        #2
            bne         DIG3
            bclr        PTP,$04
            ldab        DISP2
            cmpb        #$3F
            beq         RESUME_TCKS
            movb        DISP2,PORTB
            bset        PTJ,$02
            bra         RESUME_TCKS
DIG3:
            cmpa        #3
            bne         DIG4
        ; (MODOACTUAL = 1 , Modo Config)
            bclr        PTP,$02
            brset       BANDERAS,$08,RESUME_TCKS
            movb        DISP3,PORTB
            bset        PTJ,$02
            bra         RESUME_TCKS
DIG4:
            cmpa        #4
            bne         ENB_LEDS
            bclr        PTP,$01
            brset       BANDERAS,$08,RESUME_TCKS
            ldab        DISP4
            cmpb        #$3F
            beq         RESUME_TCKS
            movb        DISP4,PORTB
            bset        PTJ,$02
            bra         RESUME_TCKS
ENB_LEDS:
            movb        LEDS,PORTB
            bclr        PTJ,$02
RESUME_TCKS:
            inc         CONT_TICKS
            jmp         CHK_SEG