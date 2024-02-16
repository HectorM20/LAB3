//******************************************************************************************************************
;Universidad del Valle de Guatemala 
;IE2023: Programación de Microcontroladores 
; Autor: Héctor Martínez 
; Hardware: ATMEGA328p
;POSTLAB3
//******************************************************************************************************************
//ENCABEZADO
//******************************************************************************************************************
.INCLUDE "M328PDEF.INC"
.CSEG
.ORG 0x0000
	JMP SETUP				;Vector Reset
.ORG 0x0006					
	JMP ISR_PCINT0			;Vector ISR PCINT0
.ORG 0x0020
	JMP ISR_TIMER0_OVF		;Vector ISR de timer0


SETUP:
//******************************************************************************************************************
//STACK POINTER
//******************************************************************************************************************	
LDI R16, LOW(RAMEND)
OUT SPL, R16
LDI R17, HIGH(RAMEND)
OUT SPH, R17	

//******************************************************************************************************************
//CONFIGURACION
//******************************************************************************************************************
Setup:
	DISPLAY7_SEG: .DB 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x10, 0x11, 0x12, 0x13, 0x14, 0x15
	 
	LDI R16,(1<<PCIE0)			;PCINT0
	STS PCICR, R16

	LDI R16, 0b01111111		;Establecer PD0 a PD6 como salidas de display 
	OUT DDRD, R16

	LDI R16, 0b00000011		;Establcer PB0 y PB1 como salidas (transistores)
	OUT DDRB, R16
	
	LDI R16, 0b00010100		;Establecer PC2 y PC4 como entradas (pulsadores)
	OUT PORTC, R16

	SEI						;Habilitar interrupciones globales

	LDI R17, 0				;Unidades
	LDI R18, 0				;Decenas

	LDI R25, 0				;Registros de display
	LDI R26, 0
	LDI R27, 0
	LDI R28, 0

	CALL TIMER0				;Inicializar timer0
LOOP:
	CPI R21, 100
	BRNE LOOP 
	CLR 21

	LDI R20, 0
	LDI ZL, LOW(DISPLAY7_SEG<<1)
	LDI ZH, HIHG(DISPLAY7_SEG<<1)

	SBIC PIND, 0

	LDI R20, 1
	RJMP LOOP

	INC R20, R16		; Incrementar display
	BRNE MOSTRAR

	DEC R20				;Decrementar display
	CPI R25, 1
	BRNE MOSTRAR

MOSTRAR
    LDI ZL, LOW(DISPLAY7_SEG<<1)
    LDI ZH, HIGH(DISPLAY7_SEG<<1); 
    ADD ZL, R25  

TIMER0:
	LDI R20, (1<<CS02)|(1<<CS02)		;Configurar el prescaler a 1024 para un reloj de 16 Mhz
	OUT TCCR0B, R20		

	LDI R20, 100			;Cargar valor de desbordamiento 
	OUT TCNT0, R20			;Cargar valor inicial del contador

	LDI R20, 0
	OUT TCCR0A, R20
			
	LDI R20, (1<<TOIE0)		;Habilitar interrupción de timer0
	OUT TIMSK0, R16
	RET

ISR_TIMER0_0VF:
	PUSH R20
	IN R20, SREG
	PUSH R20

	LDI R20, 100
	OUT TCNT0, R20			;Cargar valor inicial del contador
	SBI TIFR0, TOV0			;Borrar bandera TOV0
	INC R21					;Incrementar contador

	POP  R20
	OUT SREG, R20
	POP R20
	RETI					;Retornar a ISR 

ISR_PCINT0:					;Pulsadores
		
	PUSH R16				;Guardar pila en resgitro R16
	IN R16, SREG
	PUSH R16
	
	IN R18, PINC			;Leer puerto C
	SBRC R18, PC2 					