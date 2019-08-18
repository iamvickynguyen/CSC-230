; reverse.asm
; CSC 230: Summer 2019
;
; Code provided for Assignment #1
;
; Mike Zastre (2019-May-22)

; This skeleton of an assembly-language program is provided to help you
; begin with the programming task for A#1, part (b). In this and other
; files provided through the semester, you will see lines of code
; indicating "DO NOT TOUCH" sections. You are *not* to modify the
; lines within these sections. The only exceptions are for specific
; changes announced on conneX or in written permission from the course
; instructor. *** Unapproved changes could result in incorrect code
; execution during assignment evaluation, along with an assignment grade
; of zero. ****
;
; In a more positive vein, you are expected to place your code with the
; area marked "STUDENT CODE" sections.

; ==== BEGINNING OF "DO NOT TOUCH" SECTION ====
; Your task: To reverse the bits in the word IN1:IN2 and to store the
; result in OUT1:OUT2. For example, if the word stored in IN1:IN2 is
; 0xA174, then reversing the bits will yield the value 0x2E85 to be
; stored in OUT1:OUT2.

    .cseg
    .org 0

; ==== END OF "DO NOT TOUCH" SECTION ==========

; **** BEGINNING OF "STUDENT CODE" SECTION **** 
    ; These first lines store a word into IN1:IN2. You may
    ; change the value of the word as part of your coding and
    ; testing.
    ;
    ldi R16, 0xA1
    sts IN1, R16
    ldi R16, 0x74
    sts IN2, R16
    
; VICKY NGUYEN - V00906571

	ldi r17, 0
	ldi r18, 0 ; r18 holds counter value
	ldi r20, 0

loop:
	cpi r18, 8
	breq loadIN1
	inc r18
	lsl r17
	mov r19, r16 ; r19=temp
	andi r19, 1
	cpi r19, 0
	breq noinc
	inc r17

noinc:	
	lsr r16
	rjmp loop

loadIN1:
	inc r20
	cpi r20, 2
	breq done
	sts OUT1, r17
	lds r16, IN1
	ldi r17, 0
	ldi r18,0

	rjmp loop

done: 
	sts OUT2, r17
    ; This code only swaps the order of the bytes from the
    ; input word to the output word. This clearly isn't enough
    ; so you may modify or delete these lines as you wish.
    ;

/*
    lds R16, IN1
	sts OUT2, R16

    lds R16, IN2
	sts OUT1, R16
*/

; **** END OF "STUDENT CODE" SECTION ********** 



; ==== BEGINNING OF "DO NOT TOUCH" SECTION ====
stop:
    rjmp stop

    .dseg
    .org 0x200
IN1:	.byte 1
IN2:	.byte 1
OUT1:	.byte 1
OUT2:	.byte 1
; ==== END OF "DO NOT TOUCH" SECTION ==========
