/*
 * assembly.s
 *
 */
 
 @ DO NOT EDIT
	.syntax unified
    .text
    .global ASM_Main
    .thumb_func

@ DO NOT EDIT
vectors:
	.word 0x20002000
	.word ASM_Main + 1

@ DO NOT EDIT label ASM_Main
ASM_Main:

	@ Some code is given below for you to start with
	LDR R0, RCC_BASE  		@ Enable clock for GPIOA and B by setting bit 17 and 18 in RCC_AHBENR
	LDR R1, [R0, #0x14]
	LDR R2, AHBENR_GPIOAB	@ AHBENR_GPIOAB is defined under LITERALS at the end of the code
	ORRS R1, R1, R2
	STR R1, [R0, #0x14]

	LDR R0, GPIOA_BASE		@ Enable pull-up resistors for pushbuttons
	MOVS R1, #0b01010101
	STR R1, [R0, #0x0C]
	LDR R1, GPIOB_BASE  	@ Set pins connected to LEDs to outputs
	LDR R2, MODER_OUTPUT
	STR R2, [R1, #0]
	MOVS R2, #0         	@ NOTE: R2 will be dedicated to holding the value on the LEDs

@ TODO: Add code, labels and logic for button checks and LED patterns

main_loop:
	@ Initialize counter
    MOVS R2, #0


increment_loop:
    @ Check SW3 state (PA3) for freeze
    LDR R3, GPIOA_BASE
    LDR R3, [R3, #0x10]  @ Read GPIOA IDR
    MOVS R4, #8          @ Bit mask for PA3
    ANDS R4, R3          @ Check if PA3 is set
    BEQ freeze_pattern   @ Branch if PA3 is low (button pressed)

    @ Check SW2 state (PA2)
    MOVS R4, #4          @ Bit mask for PA2
    ANDS R4, R3          @ Check if PA2 is set
    BEQ set_pattern_aa   @ Branch if PA2 is low (button pressed)

    @ Write current LED value
    STR R2, [R1, #0x14]

    @ Check SW1 state (PA1) to determine delay duration
    MOVS R4, #2          @ Bit mask for PA1
    ANDS R4, R3          @ Check if PA1 is set
    BNE use_long_delay   @ Branch if PA1 is high (button not pressed)

    @ SW1 is pressed, use short delay (0.3 seconds)
    LDR R3, SHORT_DELAY_CNT
    B start_delay

use_long_delay:
    @ SW1 is not pressed, use long delay (0.7 seconds)
    LDR R3, LONG_DELAY_CNT

start_delay:
delay_loop:
    SUBS R3, #1
    BNE delay_loop

    @ Check SW0 state (PA0)
    LDR R3, GPIOA_BASE
    LDR R3, [R3, #0x10]  @ Read GPIOA IDR
    MOVS R4, #1          @ Bit mask for PA0
    ANDS R4, R3          @ Check if PA0 is set
    BNE increment_by_one @ Branch if PA0 is high (button not pressed)

    @ SW0 is pressed, increment by 2
    ADDS R2, #2
    B continue_loop

increment_by_one:
    @ SW0 is not pressed, increment by 1
    ADDS R2, #1

continue_loop:
    @ If counter overflows, it will automatically wrap to 0
    B increment_loop

set_pattern_aa:
    @ SW2 is pressed, set LED pattern to 0xAA
    MOVS R2, #0xAA
    STR R2, [R1, #0x14]  @ Write to LEDs
    B wait_for_sw2_release

wait_for_sw2_release:
    @ Check if SW2 is still pressed
    LDR R3, GPIOA_BASE
    LDR R3, [R3, #0x10]  @ Read GPIOA IDR
    MOVS R4, #4          @ Bit mask for PA2
    ANDS R4, R3          @ Check if PA2 is set
    BEQ wait_for_sw2_release @ If SW2 still pressed, keep waiting

    @ SW2 released, continue normal counting from 0xAA
    B increment_loop

freeze_pattern:
    @ SW3 is pressed, freeze the pattern
    STR R2, [R1, #0x14]  @ Write current LED value

wait_for_sw3_release:
    @ Check if SW3 is still pressed
    LDR R3, GPIOA_BASE
    LDR R3, [R3, #0x10]  @ Read GPIOA IDR
    MOVS R4, #8          @ Bit mask for PA3
    ANDS R4, R3          @ Check if PA3 is set
    BEQ wait_for_sw3_release @ If SW3 still pressed, keep waiting

    @ SW3 released, continue normal counting from current value
    B increment_loop

write_leds:
    STR R2, [R1, #0x14]
    B main_loop

@ LITERALS; DO NOT EDIT
	.align
RCC_BASE: 			.word 0x40021000
AHBENR_GPIOAB: 		.word 0b1100000000000000000
GPIOA_BASE:  		.word 0x48000000
GPIOB_BASE:  		.word 0x48000400
MODER_OUTPUT: 		.word 0x5555

@ TODO: Add your own values for these delays
LONG_DELAY_CNT: 	.word 1866667  @ 0.7 seconds delay at 8 MHz
SHORT_DELAY_CNT: 	.word 800000   @ 0.13 seconds delay at 8 MHz (not used, but defined)
