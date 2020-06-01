; Moises Campos
; 11-05-2020


; Posicion de inicio de los datos de origen.
DATOS_NODOS:	equ             $1000

; Posicion de inicio de los datos de destino.
ORDEN:		equ             $1800

; Cantidad de nodos. N<250.
N:		equ             $10

; Cantidad de bits de offset para una direccion base de origen
; en los diferentes campos de cada nodo.

; Offset para numero de serie.
OFFSET_SERIE:	equ             2*N+DATOS_NODOS

; Offset para baud rate.
OFFSET_BR:	equ             4*N+DATOS_NODOS

; Offset para troughput.
OFFSET_THP:     equ             6*N+DATOS_NODOS


                org             $1000
                                
                                ; Se almacenan los valores de origen para los nodos.
                ; nuemeros de modelos
                dw              $0000,$1115,$2220,$3335,$4440,$5555,$6660,$7775
                dw              $8880,$9995,$aaa0,$bbb5,$ccc0,$ddd5,$eee0,$fff5
                ; numeros de serie
                dw              $0001,$1111,$2221,$3331,$4441,$5551,$6661,$7771
                dw              $8881,$9991,$aaa1,$bbb1,$ccc1,$ddd1,$eee1,$fff1
                ; baud rate
                dw              $0002,$1112,$2222,$3332,$4442,$5552,$6662,$7772
                dw              $8882,$9992,$aaa2,$bbb2,$ccc2,$ddd2,$eee2,$fff2
                ; troughput
                dw              $0004,$1114,$2224,$3334,$4444,$5554,$6664,$7774
                dw              $8884,$9994,$aaa4,$bbb4,$ccc4,$ddd4,$eee4,$fff4
                ; exceso que no debe copiarse
                dw              $ffff,$ffff,$ffff,$ffff,$ffff,$ffff,$ffff,$ffff
                dw              $ffff,$ffff,$ffff,$ffff,$ffff,$ffff,$ffff,$ffff

                org		$2000

                ldy             #ORDEN
                clra
                clrb
INICIO:                
                ldx      	#DATOS_NODOS+1
                ldaa            b,x
                anda            #$01
                                
                ; Verifica si el numero de serie es par, para diferenciar rutinas
                beq             PAR
		jmp             IMPAR
PAR:
                ; Se mueve el numero de modelo del elemento en B a ORDEN
                ldx             #DATOS_NODOS
                movw		b,x,2,y+
                ; Se mueve el numero de serie del elemento en B a ORDEN        
                ldx		#OFFSET_SERIE
                movw		b,x,2,y+
                ; Se mueve el baudrate del elemento en B a ORDEN        
                ldx             #OFFSET_BR
                movw            b,x,2,y+
                ; Se mueve el Throughput del elemento en B a ORDEN        
                ldx             #OFFSET_THP
                movw            b,x,2,y+
                ; Se avanza al siguiente elemento
                jmp             AVANZA
                                
IMPAR:
                ; Se mueve el numero de serie del elemento en B a ORDEN        
                ldx             #OFFSET_SERIE
                movw            b,x,2,y+
                ; Se mueve el baudrate del elemento en B a ORDEN        
                ldx             #OFFSET_BR
                movw            b,x,2,y+
                ; Se mueve el Throughput del elemento en B a ORDEN        
                ldx             #OFFSET_THP
                movw            b,x,2,y+
                ; Se mueve el numero de modelo del elemento en B a ORDEN
                ldx             #DATOS_NODOS
                movw            b,x,2,y+

AVANZA:                
                ; Se verifica si b < N
                addb		#2
                cmpb            #N
                bcs             INICIO
FIN:                
                ; Fin del programa
                jmp             FIN
                end
                                
                                
                                