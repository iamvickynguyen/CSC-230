; a3part2.asm
; CSC 230: Summer 2019
;
; Student name: VICKY NGUYEN
; Student ID: V00906571
; Date of completed work: 7/15/2019
;
; *******************************
; Code provided for Assignment #3
;
; Author: Mike Zastre (2019-Jul-04)
; 
; This skeleton of an assembly-language program is provided to help you
; begin with the programming tasks for A#3. As with A#2, there are 
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
;
; In this "DO NOT TOUCH" section are:
;
; (1) assembler directives setting up the interrupt-vector table
;
; (2) "includes" for the LCD display
;
; (3) some definitions of constants we can use later in the
;     program
;
; (4) code for initial setup of the Analog Digital Converter (in the
;     same manner in which it was set up for Lab #4)
;     
; (5) code for setting up our three timers (timer1, timer3, timer4)
;
; After all this initial code, your own solution's code may start.
;

.cseg
.org 0
	jmp reset

; location in vector table for TIMER1 COMPA
;
.org 0x22
	jmp timer1

; location in vector table for TIMER4 COMPA
;
.org 0x54
	jmp timer4

.include "m2560def.inc"
.include "lcd_function_defs.inc"
.include "lcd_function_code.asm"

.cseg

; These two constants can help given what is required by the
; assignment.
;
#define MAX_PATTERN_LENGTH 10
#define BAR_LENGTH 6

; All of these delays are in seconds
;
#define DELAY1 0.5
#define DELAY3 0.1
#define DELAY4 0.01


; The following lines are executed at assembly time -- their
; whole purpose is to compute the counter values that will later
; be stored into the appropriate Output Compare registers during
; timer setup.
;

#define CLOCK 16.0e6 
.equ PRESCALE_DIV=1024  ; implies CS[2:0] is 0b101
.equ TOP1=int(0.5+(CLOCK/PRESCALE_DIV*DELAY1))

.if TOP1>65535
.error "TOP1 is out of range"
.endif

.equ TOP3=int(0.5+(CLOCK/PRESCALE_DIV*DELAY3))
.if TOP3>65535
.error "TOP3 is out of range"
.endif

.equ TOP4=int(0.5+(CLOCK/PRESCALE_DIV*DELAY4))
.if TOP4>65535
.error "TOP4 is out of range"
.endif


reset:
	; initialize the ADC converter (which is neeeded
	; to read buttons on shield). Note that we'll
	; use the interrupt handler for timer4 to
	; read the buttons (i.e., every 10 ms)
	;
	ldi temp, (1 << ADEN) | (1 << ADPS2) | (1 << ADPS1) | (1 << ADPS0)
	sts ADCSRA, temp
	ldi temp, (1 << REFS0)
	sts ADMUX, r16


	; timer1 is for the heartbeat -- i.e., part (1)
	;
    ldi r16, high(TOP1)
    sts OCR1AH, r16
    ldi r16, low(TOP1)
    sts OCR1AL, r16
    ldi r16, 0
    sts TCCR1A, r16
    ldi r16, (1 << WGM12) | (1 << CS12) | (1 << CS10)
    sts TCCR1B, temp
	ldi r16, (1 << OCIE1A)
	sts TIMSK1, r16

	; timer3 is for the LCD display updates -- needed for all parts
	;
    ldi r16, high(TOP3)
    sts OCR3AH, r16
    ldi r16, low(TOP3)
    sts OCR3AL, r16
    ldi r16, 0
    sts TCCR3A, r16
    ldi r16, (1 << WGM32) | (1 << CS32) | (1 << CS30)
    sts TCCR3B, temp

	; timer4 is for reading buttons at 10ms intervals -- i.e., part (2)
    ; and part (3)
	;
    ldi r16, high(TOP4)
    sts OCR4AH, r16
    ldi r16, low(TOP4)
    sts OCR4AL, r16
    ldi r16, 0
    sts TCCR4A, r16
    ldi r16, (1 << WGM42) | (1 << CS42) | (1 << CS40)
    sts TCCR4B, temp
	ldi r16, (1 << OCIE4A)
	sts TIMSK4, r16

    ; flip the switch -- i.e., enable the interrupts
    sei

; =======================================
; ==== END OF "DO NOT TOUCH" SECTION ====
; =======================================


; *********************************************
; **** BEGINNING OF "STUDENT CODE" SECTION **** 
; *********************************************

	rcall lcd_init

	ldi r16, '<'
	sts CHAR_ONE, r16

	ldi r17, '>'
	sts CHAR_TWO, r17

	ldi r16, 1
	sts PULSE, r16

	clr r16
	sts BUTTON_COUNT, r16
	sts BUTTON_COUNT + 1, r16
	sts BUTTON_CURRENT, r16
	sts BUTTON_PREVIOUS, r16

	.def DATAH=r25  ;DATAH:DATAL  store 10 bits data from ADC
	.def DATAL=r24
	.equ ADCL_BTN=0x78
	.equ ADCH_BTN=0x79
	.equ BOUNDARY = 0x3E8



start:
	in r16, TIFR3
	sbrs r16, OCF3A
	rjmp heartbeat

	ldi r16, (1 << OCF3A)
	out TIFR3, r16
	rjmp start

	heartbeat:
		ldi r16, 0 ;row
		ldi r17, 14 ;column
		push r16
		push r17
		rcall lcd_gotoxy
		pop r17
		pop r16

		lds r16, CHAR_ONE
		push r16
		rcall lcd_putchar
		pop r16

		lds r17, CHAR_TWO
		push r17
		rcall lcd_putchar
		pop r17

		;======DISPLAY_TEXT=========
		ldi r16, 1 ;row
		ldi r17, 11 ;column
		push r16
		push r17
		rcall lcd_gotoxy
		pop r17
		pop r16
		
		; convert to text
		.equ MAX_POS = 5 
	
		lds r17, BUTTON_COUNT 
		lds r16, BUTTON_COUNT + 1
		push r17
		push r16
		ldi r17, high(DISPLAY_TEXT)
		ldi r16, low(DISPLAY_TEXT)
		push r17
		push r16
		rcall to_decimal_text
		pop r16
		pop r17
		pop r16
		pop r17
		

		;load 5 times
		ldi ZL, low(DISPLAY_TEXT)
		ldi ZH, high(DISPLAY_TEXT)
		ldi r17, 5
		load:
			ld r16, Z+
			push r16
			rcall lcd_putchar
			pop r16
			dec r17
			tst r17
			brne load

		rjmp start

stop:
    rjmp stop


timer1:
	push r16
	push r17
	in r16, SREG
	push r16

	lds r16, PULSE
	cpi r16, 1
	breq off
	cpi r16, 0
	breq on
	rjmp return

	on:
		ldi r16, '<'
		sts CHAR_ONE, r16
		ldi r17, '>'
		sts CHAR_TWO, r17
		ldi r16, 1
		sts PULSE, r16
		rjmp return

	off: 
		ldi r16, ' '
		sts CHAR_TWO, r16
		sts CHAR_ONE, r16
		ldi r16, 0
		sts PULSE, r16

	return:
		pop r16
		out SREG, r16
		pop r17
		pop r16
		reti


; Note there is no "timer3" interrupt handler as we must use this
; timer3 in a polling style within our main program.


timer4:
	push r16
	push r17
	in r16, SREG
	push r16
	push r23
	push ZH
	push ZL

	; check if button is pushed
	rcall check_button

	; VERSION 3
	/*
	if (current==1)
		if (previous != 1)
			count +=1 
	previous = current
	*/
	lds r16, BUTTON_CURRENT
	lds r17, BUTTON_PREVIOUS
	lds ZH, BUTTON_COUNT
	lds ZL, BUTTON_COUNT + 1 ; content


	cpi r16, 1
	brne return_timer4
	cpi r17, 1
	breq return_timer4
	adiw ZH:ZL, 1
	sts BUTTON_COUNT, ZH
	sts BUTTON_COUNT + 1, ZL


	return_timer4:	
		sts BUTTON_PREVIOUS, r16
		pop ZL
		pop ZH
		pop r23
		pop r16
		out SREG, r16
		pop r17
		pop r16
		reti

; ============ LAB 4 ======================
check_button:
	; start a2d
	lds	r16, ADCSRA	

	; bit 6 =1 ADSC (ADC Start Conversion bit), remain 1 if conversion not done
	; ADSC changed to 0 if conversion is done
	ori r16, 0x40 ; 0x40 = 0b01000000
	sts	ADCSRA, r16

	; wait for it to complete, check for bit 6, the ADSC bit
wait:	lds r16, ADCSRA
		andi r16, 0x40
		brne wait

		; read the value, use XH:XL to store the 10-bit result
		lds DATAL, ADCL_BTN
		lds DATAH, ADCH_BTN

		clr r23
		; if DATAH:DATAL < BOUNDARY_H:BOUNDARY_L
		;     r23=1  "right" button is pressed
		; else
		;     r23=0
		ldi r16, low(BOUNDARY)
		ldi r17, high(BOUNDARY)
		cp DATAL, r16
		cpc DATAH, r17
		brsh skip		
		ldi r23,1

skip:	
	sts BUTTON_CURRENT, r23
	ret



  ;===================	TO DECIMAL TEXT - MIKE ========================
to_decimal_text:
	.def countL=r18
	.def countH=r19
	.def factorL=r20
	.def factorH=r21
	.def multiple=r22
	.def pos=r23
	.def zero=r0
	.def ascii_zero=r16

	push countH
	push countL
	push factorH

	push factorL
	push multiple
	push pos
	push zero
	push ascii_zero
	push YH
	push YL
	push ZH
	push ZL
	in YH, SPH
	in YL, SPL

	.set PARAM_OFFSET = 16
	ldd countH, Y+PARAM_OFFSET+3
	ldd countL, Y+PARAM_OFFSET+2
	
	andi countH, 0b01111111
	clr zero
	clr pos
	ldi ascii_zero, '0'

to_decimal_next: clr multiple

to_decimal_10000:
	cpi pos, 0
	brne to_decimal_1000
	ldi factorL, low(10000)
	ldi factorH, high(10000)
	rjmp to_decimal_loop

to_decimal_1000:
	cpi pos, 1
	brne to_decimal_100
	ldi factorL, low(1000)
	ldi factorH, high(1000)
	rjmp to_decimal_loop

to_decimal_100:
	cpi pos, 2
	brne to_decimal_10
	ldi factorL, low(100)
	ldi factorH, high(100)
	rjmp to_decimal_loop

to_decimal_10:
	cpi pos, 3
	brne to_decimal_1
	ldi factorL, low(10)
	ldi factorH, high(10)
	rjmp to_decimal_loop

to_decimal_1:
	mov multiple, countL
	rjmp to_decimal_write

to_decimal_loop:
	inc multiple
	sub countL, factorL
	sbc countH, factorH
	brpl to_decimal_loop
	dec multiple
	add countL, factorL
	adc countH, factorH

to_decimal_write:
	ldd ZH, Y+PARAM_OFFSET+1
	ldd ZL, Y+PARAM_OFFSET+0
	add ZL, pos
	adc ZH, zero
	add multiple, ascii_zero
	st Z, multiple
	inc pos
	cpi pos, MAX_POS
	breq to_decimal_exit
	rjmp to_decimal_next

to_decimal_exit:
	pop ZL
	pop ZH
	pop YL
	pop YH
	pop ascii_zero
	pop zero
	pop pos
	pop multiple
	pop factorL
	pop factorH
	pop countL
	pop countH
	.undef countL
	.undef countH
	.undef factorL
	.undef factorH
	.undef multiple
	.undef pos
	.undef zero
	.undef ascii_zero
	ret

;==================== TO DECIMAL TEXT - MIKE =======================

; ***************************************************
; **** END OF FIRST "STUDENT CODE" SECTION ********** 
; ***************************************************


; ################################################
; #### BEGINNING OF "TOUCH CAREFULLY" SECTION ####
; ################################################

; The purpose of these locations in data memory are
; explained in the assignment description.
;

.dseg

CHAR_ONE: .byte 1
CHAR_TWO: .byte 1

PULSE: .byte 1
COUNTER: .byte 2
DISPLAY_TEXT: .byte 16
BUTTON_CURRENT: .byte 1
BUTTON_PREVIOUS: .byte 1
BUTTON_COUNT: .byte 2
BUTTON_LENGTH: .byte 1
DOTDASH_PATTERN: .byte MAX_PATTERN_LENGTH

; ##########################################
; #### END OF "TOUCH CAREFULLY" SECTION ####
; ##########################################
