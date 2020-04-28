.include "../tn13def.inc"
.org 	0x0000
	rjmp	main
.org 	PCI0addr
	rjmp	pin_int
.org 	OC0Aaddr
	rjmp	on_timer
.org 	OC0Baddr
	rjmp	on_timer
.org	OVF0addr
	rjmp	on_timer

.def	r_tmp=r16
.def	r_state=r17
.def	r_ports=r0
.def	r_timer=r3

.def	r_t1=r18
.def	r_t2=r19
.def	r_t3=r20


.define _TRIAC_FREE

.org	INT_VECTORS_SIZE

.equ	RELAY=4
.equ	TRIAC=3

.equ	PWR_BUTTON=0
.equ	CNC_CTRL=2

.macro	relay_on
	sbi		PORTB, RELAY
.endm

.macro	relay_off
	cbi		PORTB, RELAY
.endm

.macro	triac_on
	sbi		PORTB, TRIAC
.endm

.macro	triac_off
	cbi		PORTB, TRIAC
.endm

.macro	relay_delay
	rcall	delay_100ms
.endm

.equ	TIMER_OCR=150

.equ	POWER_IS_ON_BIT=0

.equ	IN_MASK=((1 << PWR_BUTTON) | (1 << CNC_CTRL))


.macro	read_port
	in		@0, PINB
	andi	@0, IN_MASK
.endm


;r17 - состояние системы
;r3 - счетчик циклов таймера
;r0 - состояние контролируемых портов

.include "utils.inc"

main:	
	;Подготовка стека
	outp	SPL, low(RAMEND)

	sbi		DDRB, TRIAC
	sbi		DDRB, RELAY
	
	;Подтягивающие резисторы
	sbi		PORTB, PWR_BUTTON 
	sbi		PORTB, CNC_CTRL
	
	read_port	r_tmp
	mov		r_ports, r_tmp
	 
	;Прерывания от gpio
	outp	PCMSK, (1 << PWR_BUTTON) | (1 << CNC_CTRL)
	outp	GIMSK, 1<<PCIE

	;Все выключить
	triac_off
	relay_off
	
	;Начальное состояние системы
	clr		r_state
	
	sei

	rjmp	infinity 


do_power_off:
	.ifdef TRIAC_FREE
		triac_on
		relay_delay
	.endif
	
	relay_off
	relay_delay
	triac_off
	andi	r_state, ~(1<<POWER_IS_ON_BIT)
	ret
	
do_power_on:
	triac_on
	relay_delay
	relay_on
	
	.ifdef TRIAC_FREE
		relay_delay
		triac_off
	.endif
	
	ori		r_state, 1<<POWER_IS_ON_BIT
	ret

pin_int:
	rcall	timer_start
	reti
		

timer_start:
	clr		r_timer
	clr		r_tmp
	out		TCCR0B, r_tmp			;Остановка таймера
	out		TCNT0, r_tmp			;Сброс счетчика

	outp	TCCR0A, 1 << WGM01			;CNC
	outp	TCCR0B, (1<<CS01) | (1<<CS00)	;Режим таймера CTC, делитель 1024
	
	outp	OCR0A, TIMER_OCR										;Прервывания будут идти каждые 20мс
	outp	TIMSK0, 1<<OCIE0A										;Разрешение прерывания
	ret


.macro	_on_timer
	inc		r_timer
	brne	_lend
		clrp	TCCR0B			;Остановка таймера
		read_port	r_tmp
		cp		r_ports, r_tmp
		breq	_lend
			mov		r_t1, r_tmp
			eor		r_tmp, r_ports
			mov		r_ports, r_t1
			push r_tmp
			sbrc	r_tmp, POWER_IS_ON_BIT
				rcall	power_button
			pop		r_tmp
			sbrc	r_tmp, CNC_CTRL
				rcall	cnc_check
_lend:	
	reti

.endm

on_timer: _on_timer
	

.macro _power_button
	sbrc	r_ports, PWR_BUTTON
		ret	
    sbrc	r_state, POWER_IS_ON_BIT
		rjmp	_do_on
	rcall	do_power_on
	rjmp	_l_end
_do_on:
	rcall	do_power_off
_l_end:
	ret
.endm

power_button: _power_button
	

.macro _cnc_check
	sbrs	r_state, POWER_IS_ON_BIT	;Питание отключено, ничего делать не надо
		rjmp	_lend
	sbrc	r_ports, CNC_CTRL
		rcall	do_power_off
_lend:
	ret
.endm

cnc_check: _cnc_check
