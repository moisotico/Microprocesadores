; Moises Campos
; 11-05-2020

DATOS:		equ             $1000
MAYORES:        equ             $1100

                org             $1000
                
                                ; Valores de prueba
                db              3,66,74,52,70,43,70,97
                db              -51,28,-7,73,25,76,32,-30
                db              -36,90,1,66,58,-17,7,-109
                db              63,-74,23,-69,28,63,114,88
                db              54,-106,-39,-65,-100,100
                db              -27,10,46,-6,85,7,51,-75,-70,-72
                db              -84,118,-85,27,-14,-97


                org             $2000
; Inicialmente se cargan las direcciones de inicio
; de DATOS y MAYORES respectivamente en indices X y Y.
INICIO:
                ldx             #DATOS
                ldy             #MAYORES
				clrb
                stab		$1300
                stab            $1301
x`
; Se chequea que el numero sea mayor a -50($CE)
; Si es menor o igual no se copia el dato.
LOOP:

                incb
                stab            $1300
				ldaa            b,X
                cmpa            #$CE
                ble             SIGUIENTE_DATO


; Si el dato es mayor que -50, se copia el dato en MAYORES.
; Ademas se cambia el valor de b para contar MAYORES y se guarda este valor.
COPIAR_DATO:
                ldab		$1301
                incb
		staa            xb,Y
                stab            $1301

; Se comprueba la condicion de salida del loop.
SIGUIENTE_DATO:
                ldab            $1300
		cmpb		#$C8
                bcs             LOOP

; Fin del programa
FIN:
                jmp             FIN
                end