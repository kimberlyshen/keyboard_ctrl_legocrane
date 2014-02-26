.equ TERMINAL, 		0x10001020 		# ask
.equ LEGO,  		0x10000070		# irq 11
.equ KEYBOARD, 		0x10000100 		# irq 7
.equ PERIOD, 		0x02FAF080		# 1second = 0x02FAF080
.equ TIMER, 		0x10002000

/********************************* Data ***************************************/

.data
/***
 * ARRAYS
 * =======
 ***/
 .align 2
 PULSE_ON: .space 4


/***************************** Program Code ***********************************/
.section .text
.global main

main:
/***************************** Device Configuration *****************************/
	#set up the logo controller
	movia r8, LEGO
	movia r9, 0x07f557ff
	stwio r9, 4(r8)

	# Configure timer
	movia r8, TIMER
	movui r9,%lo(PERIOD)
	stwio r9, 8(r8)
	movui r9, %hi(PERIOD)
	stwio r9, 12(r8)

	stwio r0, 0(r8)	#enable interrupts
	movi r9, 0b111
	stwio r9, 4(r8)

	movi r9, 0b1	#enable IRQ0
	wrctl ctl3, r9
	
	movi r9, 0b1	#enable PIE/external interrupts
	wrctl ctl0, r9
/*******************************************************************************/

MOTOR_LOOP:
	# turn motor on
	movia r8, PULSE_ON
	ldw r8, 0(r8)
	beq r8, r0, ON
	
	OFF:
		movia r9, 0xFFFFFFFF
		movia r8, LEGO
		stwio r9, 0(r8)
		br MOTOR_LOOP
		
	
	ON:
		movia r9, 0xFFFFFFFB
		movia r8, LEGO
		stwio r9, 0(r8)
		br MOTOR_LOOP
	
.section .exceptions, "ax"
IHANDLER:
	rdctl et, ctl4
	andi et, et, 0x1
	
	subi sp, sp, 12
	stw ra, 0(sp)
	stw r8, 4(sp)
	stw r9, 8(sp)
	
	bne et, r0, TIMER_INTERRUPT
	br EXIT_HANDLER
	


EXIT_HANDLER:
	ldw ra, 0(sp)
	ldw r8, 4(sp)
	ldw r9, 8(sp)
	addi sp, sp, 8
	subi ea, ea, 4
	eret
	
TIMER_INTERRUPT:
	movia et, PULSE_ON
	ldw r8, 0(et)
	beq r8, r0, TIMER_ON
	
	TIMER_OFF:
		movia r8, PERIOD
		ldw r8, 0(r8)
		movi r9, 0x3
		div r9, r8, r9
		
		# Configure timer
		movia et, TIMER
		andi r8, r9, 0x0000FFFF
		stwio r8, 8(et)
		srli r8, r9, 16
		stwio r8, 12(et)
		
		movia et, PULSE_ON
		stw r0, 0(et)
		
		# acknowledge interrupt
		movia et, TIMER
		stwio r0, 0(et)
		
		br EXIT_HANDLER	
		
	TIMER_ON:
		movia r8, PERIOD
		ldw r8, 0(r8)
		movi r9, 0x3
		div r9, r8, r9
		
		movi r9, 0x2
		mul r9, r8, r9
		
		# Configure timer
		movia et, TIMER
		andi r8, r9, 0x0000FFFF
		stwio r8, 8(et)
		srli r8, r9, 16
		stwio r8, 12(et)
	
		movia et, PULSE_ON
		movia r8, 1
		stw r8, 0(et)
		
		
		# acknowledge interrupt
		movia et, TIMER
		stwio r0, 0(et)
		
		br EXIT_HANDLER
		

		

		


