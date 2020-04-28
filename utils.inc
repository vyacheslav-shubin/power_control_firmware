.cseg

.macro	outp
	ldi		r_tmp, @1
	out		@0, r_tmp
.endm

.macro	clrp
	clr		r_tmp
	out		@0, r_tmp
.endm

infinity:
	rjmp	infinity 


.macro _delay_50ms
    ldi		r_t1, 2
    ldi		r_t2, 56
    ldi		r_t3, 174
_l0: 
	dec		r_t3
    brne	_l0
    dec		r_t2
    brne	_l0
    dec		r_t1
    brne	_l0
    ret
.endm
delay_50ms: _delay_50ms

delay_100ms:
	rcall	delay_50ms
	rcall	delay_50ms
	ret

delay_500ms:
	rcall	delay_100ms
	rcall	delay_100ms
	rcall	delay_100ms
	rcall	delay_100ms
	rcall	delay_100ms
	ret

delay_1s:
	rcall	delay_500ms
	rcall	delay_500ms
	ret
	
