; a2_morse.asm
; CSC 230: Summer 2019
;
; Student name: VICKY NGUYEN
; Student ID: V00906571
; Date of completed work: 25/6/2019
;
; *******************************
; Code provided for Assignment #2
;
; Author: Mike Zastre (2019-Jun-12)
; 
; This skeleton of an assembly-language program is provided to help you
; begin with the programming tasks for A#2. As with A#1, there are 
; "DO NOT TOUCH" sections. You are *not* to modify the lines
; within these sections. The only exceptions are for specific
; changes announced on conneX or in written permission from the course
; instructor. *** Unapproved changes could result in incorrect code
; execution during assignment evaluation, along with an assignment grade
; of zero. ****
;
; I have added for this assignment an additional kind of section
; called "TOUCH CAREFULLY". The intention here is that one or two
; constants can be changed in such a section -- this will be needed
; as you try to test your code on different messages.
;


; =============================================
; ==== BEGINNING OF "DO NOT TOUCH" SECTION ====
; =============================================

.include "m2560def.inc"

.cseg
.equ S_DDRB=0x24
.equ S_PORTB=0x25
.equ S_DDRL=0x10A
.equ S_PORTL=0x10B

	
.org 0
	; Copy test encoding (of 'sos') into SRAM
	;
	ldi ZH, high(TESTBUFFER)
	ldi ZL, low(TESTBUFFER)
	ldi r16, 0x30
	st Z+, r16
	ldi r16, 0x37
	st Z+, r16
	ldi r16, 0x30
	st Z+, r16
	clr r16
	st Z, r16

	; initialize run-time stack
	ldi r17, high(0x21ff)
	ldi r16, low(0x21ff)
	out SPH, r17
	out SPL, r16

	; initialize LED ports to output
	ldi r17, 0xff
	sts S_DDRB, r17
	sts S_DDRL, r17

; =======================================
; ==== END OF "DO NOT TOUCH" SECTION ====
; =======================================

; ***************************************************
; **** BEGINNING OF FIRST "STUDENT CODE" SECTION **** 
; ***************************************************

	; If you're not yet ready to execute the
	; encoding and flashing, then leave the
	; rjmp in below. Otherwise delete it or
	; comment it out.

	;rjmp stop

    ; The following seven lines are only for testing of your
    ; code in part B. When you are confident that your part B
    ; is working, you can then delete these seven lines. 

	/*
	ldi r17, high(TESTBUFFER)
	ldi r16, low(TESTBUFFER)
	push r17
	push r16
	rcall flash_message
    pop r16
    pop r17
	rjmp stop
	*/
   
; ***************************************************
; **** END OF FIRST "STUDENT CODE" SECTION ********** 
; ***************************************************


; ################################################
; #### BEGINNING OF "TOUCH CAREFULLY" SECTION ####
; ################################################

; The only things you can change in this section is
; the message (i.e., MESSAGE01 or MESSAGE02 or MESSAGE03,
; etc., up to MESSAGE09).
;

	; encode a message
	;
	ldi r17, high(MESSAGE03 << 1)
	ldi r16, low(MESSAGE03 << 1)
	push r17
	push r16
	ldi r17, high(BUFFER01)
	ldi r16, low(BUFFER01)
	push r17
	push r16
	rcall encode_message
	pop r16
	pop r16
	pop r16
	pop r16

; ##########################################
; #### END OF "TOUCH CAREFULLY" SECTION ####
; ##########################################


; =============================================
; ==== BEGINNING OF "DO NOT TOUCH" SECTION ====
; =============================================
	; display the message three times
	;


	ldi r18, 3
main_loop:
	ldi r17, high(BUFFER01)
	ldi r16, low(BUFFER01)
	push r17
	push r16
	rcall flash_message
	dec r18
	tst r18
	brne main_loop


stop:
	rjmp stop
; =======================================
; ==== END OF "DO NOT TOUCH" SECTION ====
; =======================================


; ****************************************************
; **** BEGINNING OF SECOND "STUDENT CODE" SECTION **** 
; ****************************************************


flash_message:
.set OFFSET = 10 
	push r17
	push r16
	push ZH
	push ZL
	push YH
	push YL

	in YH, SPH
	in YL, SPL

	ldd ZL, Y + OFFSET
	ldd ZH, Y + OFFSET + 1

	while_not_0:
		ld r16, Z+
		tst r16
		breq flash_return
		push r16
		call morse_flash
		pop r16
		rjmp while_not_0

	flash_return: 
		pop YL
		pop YH
		pop ZL
		pop ZH
		pop r16
		pop r17
		ret



morse_flash: 
	push r16
	push r17
	push r18
	push r19

	cpi r16, 0xff
	breq space

	swap r16
	mov r17, r16 ; copy, HIGH = r17
	mov r18, r16 ; copy, LOW = r18
	andi r17, 0x0f
	andi r18, 0xf0

	cpi r17, 4
	breq no_shift
	cpi r17, 3
	breq shift_1
	cpi r17, 2
	breq shift_2
	lsl r18
	shift_2: lsl r18
	shift_1: lsl r18

	no_shift:	
		cpi r17, 0
		breq return_morse_flash
		dec r17 ; counter = r17

		mov r19, r18
		andi r19, 0x80 ; take the MSB of r18
		cpi r19, 0x80
		breq dash

		;else dot
		call leds_on	
		call delay_short
		call leds_off
		call delay_long
		
		lsl r18
		rjmp no_shift

	dash: 	
		call leds_on
		call delay_long
		call leds_off
		call delay_long
		
		lsl r18
		rjmp no_shift

	space:
		call leds_off	
		call delay_long
		call delay_long
		call delay_long
		
	return_morse_flash: 
		pop r19
		pop r18
		pop r17
		pop r16
		ret



leds_on:
	push r16
	push r17
	push r19 ; control port B
	push r20 ; control port L

	ldi r19, 0 ; PORTB position
	ldi r20, 0 ; PORTL position

	;only take low nybble
	mov r17, r16
	andi r17, 0x0f

	cpi r17, 0
	breq leds_off
	cpi r17, 1
	breq turn_1
	cpi r17, 2
	breq turn_2
	cpi r17, 3
	breq turn_3
	cpi r17, 4
	breq turn_4
	cpi r17, 5
	breq turn_5

	turn_all:
		ori r19, 2
	turn_5:
		ori r19, 8
	turn_4:
		ori r20, 2
	turn_3:
		ori r20, 8
	turn_2:
		ori r20, 0x20
	turn_1:
		ori r20, 0x80
		
	sts S_PORTL, r20
	sts S_PORTB, r19

	pop r20
	pop r19
	pop r17
	pop r16
	ret



leds_off:
	push r16
	ldi r16, 0
	sts S_PORTB, r16 
	sts S_PORTL, r16
	pop r16		
	ret



encode_message:
.set OFFSET = 12

	push r17
	push r16
	push XH
	push XL
	push ZH
	push ZL
	push YH
	push YL

	in YH, SPH
	in YL, SPL

	ldd ZL, Y + OFFSET + 2 ; Z: THE MESSAGE
	ldd ZH, Y + OFFSET + 3
	ldd XL, Y + OFFSET  ; X: THE ADDRESS
	ldd XH, Y + OFFSET + 1

	read_char:
		lpm r16, Z+
		tst r16
		breq return_msg
		push r16
		call alphabet_encode
		pop r16
		st X+, r0
		rjmp read_char

	return_msg: 

		pop YL
		pop YH
		pop ZL
		pop ZH
		pop XL
		pop XH
		pop r16
		pop r17
		ret	



alphabet_encode: 
.set OFFSET = 9 

	push r16
	push r17
	push r18
	push r19
	push r20
	push r22
	push r23
	push ZH
	push ZL
	push YH
	push YL

	in YH, SPH
	in YL, SPL

	ldi ZH, high(ITU_MORSE << 1)
	ldi ZL, low(ITU_MORSE << 1)
	lpm r17, Z+ ; load character to r17
	ldi r18, 0 ; count dots & dashes
	ldi r19, 0 ; keep track dots & dashes
	ldi r20, '-'
	ldi r22, 7
	clr r23
	clr r0

	while_not_null:
		cpi r17, 0
		breq alphabet_return
		cp r16, r17 
		breq if_equals ; if equals letter

		; Z += 8
		add ZL, r22
		adc ZH, r23
		lpm r17, Z+
		rjmp while_not_null

	if_equals:
		lpm r17, Z+1
		cpi r17, 0
		breq alphabet_return ; not a dot or dash
		;else convert dot & dash to byte

			lsl r19
			inc r18
			
			cp r17, r20 ; if it's a dash
			breq a_dash
			rjmp if_equals

		a_dash:
			ori r19, 1

		rjmp if_equals

	alphabet_return: 
		clr r0
		swap r18
		or r0, r18
		or r0, r19

		; new space
		tst r0
		brne not_space
		ldi r18, 0xff
		or r0, r18

	not_space:
		pop YL
		pop YH
		pop ZL
		pop ZH
		pop r23
		pop r22
		pop r20
		pop r19
		pop r18
		pop r17
		pop r16
	ret	 


; **********************************************
; **** END OF SECOND "STUDENT CODE" SECTION **** 
; **********************************************


; =============================================
; ==== BEGINNING OF "DO NOT TOUCH" SECTION ====
; =============================================

delay_long:
	rcall delay
	rcall delay
	rcall delay
	ret

delay_short:
	rcall delay
	ret

; When wanting about a 1/5th of second delay, all other
; code must call this function
;
delay:
	rcall delay_busywait
	ret


; This function is ONLY called from "delay", and
; never directly from other code.
;
delay_busywait:
	push r16
	push r17
	push r18

	ldi r16, 0x08
delay_busywait_loop1:
	dec r16
	breq delay_busywait_exit
	
	ldi r17, 0xff
delay_busywait_loop2:
	dec	r17
	breq delay_busywait_loop1

	ldi r18, 0xff
delay_busywait_loop3:
	dec r18
	breq delay_busywait_loop2
	rjmp delay_busywait_loop3

delay_busywait_exit:
	pop r18
	pop r17
	pop r16
	ret



.org 0x1000

ITU_MORSE: .db "a", ".-", 0, 0, 0, 0, 0
	.db "b", "-...", 0, 0, 0
	.db "c", "-.-.", 0, 0, 0
	.db "d", "-..", 0, 0, 0, 0
	.db "e", ".", 0, 0, 0, 0, 0, 0
	.db "f", "..-.", 0, 0, 0
	.db "g", "--.", 0, 0, 0, 0
	.db "h", "....", 0, 0, 0
	.db "i", "..", 0, 0, 0, 0, 0
	.db "j", ".---", 0, 0, 0
	.db "k", "-.-", 0, 0, 0, 0
	.db "l", ".-..", 0, 0, 0
	.db "j", "--", 0, 0, 0, 0, 0
	.db "n", "-.", 0, 0, 0, 0, 0
	.db "o", "---", 0, 0, 0, 0
	.db "p", ".--.", 0, 0, 0
	.db "q", "--.-", 0, 0, 0
	.db "r", ".-.", 0, 0, 0, 0
	.db "s", "...", 0, 0, 0, 0
	.db "t", "-", 0, 0, 0, 0, 0, 0
	.db "u", "..-", 0, 0, 0, 0
	.db "v", "...-", 0, 0, 0
	.db "w", ".--", 0, 0, 0, 0
	.db "x", "-..-", 0, 0, 0
	.db "y", "-.--", 0, 0, 0
	.db "z", "--..", 0, 0, 0
	.db 0, 0, 0, 0, 0, 0, 0, 0

MESSAGE01: .db "a a a", 0
MESSAGE02: .db "sos", 0
MESSAGE03: .db "a box", 0
MESSAGE04: .db "dairy queen", 0
MESSAGE05: .db "the shape of water", 0, 0
MESSAGE06: .db "john wick parabellum", 0, 0
MESSAGE07: .db "how to train your dragon", 0, 0
MESSAGE08: .db "oh canada our own and native land", 0
MESSAGE09: .db "is that your final answer", 0

; First message ever sent by Morse code (in 1844)
MESSAGE10: .db "what god hath wrought", 0




.dseg
.org 0x200
BUFFER01: .byte 128
BUFFER02: .byte 128
TESTBUFFER: .byte 4

; =======================================
; ==== END OF "DO NOT TOUCH" SECTION ====
; =======================================
