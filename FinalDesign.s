.equ CONTROLLER,   0xFF200060
.equ DIRECTION,    0x07F557FF

.equ MOTORFORWARD, 0xFFFFFFF0
.equ TURNRIGHT, 0xFFFFFFF8
.equ TURNLEFT, 0xFFFFFFF2
.equ REVERSE, 0xFFFFFFFA

.equ PS2ADDRESS, 0xFF200100
.equ A, 0x1C
.equ S, 0x1B
.equ D, 0x23
.equ W, 0x1D
.equ BREAK, 0xF0

.equ TIMER, 0xFF202000
.equ HEXDISPLAY, 0xFF200020

.equ ADDR_PUSHBUTTONS, 0xFF200050
.equ IRQ_PUSHBUTTONS, 0x02

.section .text
.global _start

_start:

	#*******************INITIALIZATIONS****************************
	
	#***** PUSH_BUTTON INTERRUPT INTIALIZATION *****
	
	movia r2,ADDR_PUSHBUTTONS #|
	movia r20, 0xFFFFFFFF	  #| Clear IRQ mask register for push buttons
	stwio r20, 12(r2)		  #|
	
	movia r2,ADDR_PUSHBUTTONS
	movia r3,0xe
	stwio r3,8(r2)  # Enable interrupts on push buttons 1,2, and 3 

	movia r2,IRQ_PUSHBUTTONS
	wrctl ctl3,r2   # Enable bit 5 - button interrupt on Processor 

	movia r2,1
	wrctl ctl0,r2   # Enable global Interrupts on Processor
	
	movia r2, ADDR_PUSHBUTTONS
	
	movi r23, 0
	
	#***** KEYBOARD INITIALIZATIONS *****
	movia r15, PS2ADDRESS #load ps/2 address into r8
	movia r10, A
	movia r11, S
	movia r12, D
	movia r13, W
	movia r14, BREAK
	movi r4, 1
	
	
	
	#***** HEX, AUTO LEGO, TIMER INTIALIZATIONS ******
	movia r12, HEXDISPLAY	#enable the hex to display nothing
	movia r14, 0x0000003F
	stwio r14, 0(r12)

	movia r14, 0x00000000	#counter register set as 0
	stwio r14, 0(r14)

	movia r8, CONTROLLER
	movia r9, DIRECTION
	stwio r9, 4(r8)
	movia r9, 0xFFFFFFFF	#turn everything off
	stwio r9, 0(r8)
	
LOOP:
	bne r23, r0, LOAD
	br INITIALIZE_KEYBOARD

LOOP2:
	beq r23, r0, READ_KEYBOARD_VALID
	br LOOP

LOAD:

	ldwio r11, 0(r8)	#retrieve register with 0xFFFFFFFF
	movia r10, 0xFFFFFBFF	#only sensor0 on
	ldwio r20, 0(r8)	#retrieve register with 0xFFFFFFFF
	and   r20, r10, r20	
	stwio r20, 0(r8)	#r8 is now 0xFFFFFBFF with sensor 0 on only

CHECK_SENSOR_0:

	ldwio r16, 0(r8)		#retrieve register with 0xFFFFFBFF
	srli  r16, r16, 11	
	andi  r16, r16, 1		#check for sensor 0 validity
	bne   r16, r0, CHECK_SENSOR_0	#if invalid check again

	ldwio r10, 0(r8)		#retrieve register with 0xFFFFFBFF
	srli  r10, r10, 27		#get sensor0 value and store in r10
	movia r11, 0xFFFFEFFF		#turn on sensor1 only		
	stwio r11, 0(r8)		#r8 is now 0xFFFFEFFF with sensor 1 on

	CHECK_SENSOR_1:

	ldwio r16, 0(r8)		#retrieve register with 0xFFFFEFFF
	srli  r16, r16, 13		
	andi  r16, r16, 1		#check validity for sensor 1
	bne   r16, r0, CHECK_SENSOR_1	#if invalid check again
	ldwio r11, 0(r8)		#retrieve register with 0xFFFFEFFF

	srli  r11, r11, 27		#get sensor1 value and store in r11

	subi  r10, r10, 0x3		#sensor value subtract 4
	subi  r11, r11, 0x2

	subi  r15, r10, 0x8
	bgt r10, r0, CHECK_2

EXIT:

	bgt   r10, r0, TURN_LEFT	#if sensor one 
	bgt   r11, r0, TURN_RIGHT
	br    STRAIGHT

CHECK_2:
	subi r15, r11, 0x8
	bgt r11, r0, EXECUTE
	br EXIT
	
EXECUTE:
	
	addi r14, r14, 0x1
	stwio r14, 0(r14)
	
	#check for 1
	ldwio r15, 0(r14) #r14 contains current value
	subi r15, r15, 0x1
	beq r15, r0, ONE
	
	#check for 2
	ldwio r15, 0(r14)
	subi r15, r15, 0x2
	beq r15, r0, TWO
	
	#check for 3
	ldwio r15, 0(r14)
	subi r15, r15, 0x3
	beq r15, r0, THREE
	
	#check for 4
	ldwio r15, 0(r14)
	subi r15, r15, 0x4
	beq r15, r0, FOUR
	
	#check for 5
	ldwio r15, 0(r14)
	subi r15, r15, 0x5
	beq r15, r0, FIVE
	
	br EXIT
	
ONE:
	movia r15, 0x00000006
	stwio r15, 0(r12)
	
	movia r9, 0xFFFFFFFF	#turn everything off
	stwio r9, 0(r8)

	movia r4, 25000000 #1/4 of a second 
  	movia	 r9, MOTORFORWARD      
  	stwio	 r9, 0(r8)
	call DELAY
	movia r4, 3000000 #1/8 of a second 
  	movia	 r9, 0xFFFFFFFA #reverse a little      
  	stwio	 r9, 0(r8)
	call DELAY
	movia r4, 7500000
	movia	 r9, 0xFFFFFFFF #reverse a little      
  	stwio	 r9, 0(r8)
	call DELAY
	
	br LOOP
TWO:
	movia r15, 0x0000005B
	stwio r15, 0(r12)
	
	movia r9, 0xFFFFFFFF	#turn everything off
	stwio r9, 0(r8)

	movia r4, 25000000 #1/4 of a second 
  	movia	 r9, MOTORFORWARD      
  	stwio	 r9, 0(r8)
	call DELAY
	movia r4, 3000000 #1/8 of a second 
  	movia	 r9, 0xFFFFFFFA #reverse a little      
  	stwio	 r9, 0(r8)
	call DELAY
	movia r4, 7500000
	movia	 r9, 0xFFFFFFFF #reverse a little      
  	stwio	 r9, 0(r8)
	call DELAY
	
	br LOOP
	
THREE:
	movia r15, 0x0000004F
	stwio r15, 0(r12)
	
	movia r9, 0xFFFFFFFF	#turn everything off
	stwio r9, 0(r8)

	movia r4, 25000000 #1/4 of a second 
  	movia	 r9, MOTORFORWARD      
  	stwio	 r9, 0(r8)
	call DELAY
	movia r4, 3000000 #1/8 of a second 
  	movia	 r9, 0xFFFFFFFA #reverse a little      
  	stwio	 r9, 0(r8)
	call DELAY
	movia r4, 7500000
	movia	 r9, 0xFFFFFFFF #reverse a little      
  	stwio	 r9, 0(r8)
	call DELAY
	
	br LOOP
	
FOUR:
	movia r15, 0x00000066
	stwio r15, 0(r12)
	
	movia r9, 0xFFFFFFFF	#turn everything off
	stwio r9, 0(r8)

	movia r4, 25000000 #1/4 of a second  
  	movia	 r9, MOTORFORWARD      
  	stwio	 r9, 0(r8)
	call DELAY
	movia r4, 3000000 #1/8 of a second 
  	movia	 r9, 0xFFFFFFFA #reverse a little      
  	stwio	 r9, 0(r8)
	call DELAY
	movia r4, 7500000
	movia	 r9, 0xFFFFFFFF #reverse a little      
  	stwio	 r9, 0(r8)
	call DELAY
	
	br LOOP
	
FIVE:
	movia r15, 0x0000006D
	stwio r15, 0(r12)
	
	movia r9, 0xFFFFFFFF	#turn everything off
	stwio r9, 0(r8)

	movia r4, 25000000 #1/4 of a second   
  	movia	 r9, MOTORFORWARD      
  	stwio	 r9, 0(r8)
	call DELAY
	movia r4, 3000000 #1/8 of a second 
  	movia	 r9, 0xFFFFFFFA #reverse a little      
  	stwio	 r9, 0(r8)
	call DELAY
	movia r4, 7500000
	movia	 r9, 0xFFFFFFFF #reverse a little      
  	stwio	 r9, 0(r8)
	call DELAY
	
	br LOOP

STRAIGHT:
	movia r4, 7500000 #1/4 of a second 
  	movia	 r9, MOTORFORWARD      
  	stwio	 r9, 0(r8)
	call DELAY
	movia r4, 3000000 #1/8 of a second 
  	movia	 r9, 0xFFFFFFFA #reverse a little      
  	stwio	 r9, 0(r8)
	call DELAY
	movia r4, 7500000
	movia	 r9, 0xFFFFFFFF #reverse a little      
  	stwio	 r9, 0(r8)
	call DELAY
  	br LOOP

TURN_LEFT:
	movia r4, 25000000	#1/16 of a second
  	movia r9, 0xFFFFFFF8 		#1000
    stwio r9, 0(r8)                 #store value into DIRECTION
	call DELAY
	movia r4, 7500000
	movia	 r9, 0xFFFFFFFF #reverse a little      
  	stwio	 r9, 0(r8)
	call DELAY
    br LOOP				#left motor is motor0
	
TURN_RIGHT:
  	movia r4, 25000000	#1/16 of a second 		
	movia r9, 0xFFFFFFF2 		#0010, both motor turn on one forward and one reverse
    stwio r9, 0(r8)          	#store value into DIRECTION
	call DELAY
	movia r4, 7500000
	movia	 r9, 0xFFFFFFFF #reverse a little      
  	stwio	 r9, 0(r8)
	call DELAY
    br LOOP			#right motor is motor1
	
CONVERSION:
	

DELAY:
    andi  r17, r4, 0xffff 	#set lower bits to all 1s for arbitrary register
    andhi r19, r4, 0xffff 	#set higher bits to all 1s for arbitrary register
    srli  r19, r19,16		#use the stored bits from r19 

    movia r18, TIMER		#initialize timer 

    stwio r17, 8(r18)		#lower bits timeout period
    stwio r19, 12(r18)		#higher bits timeout period

    movia r20, 0x0		
    stwio r20, 0(r18)		#reset the timer to 0

    movia r20, 4		#stop the time by writing to 3rd bit	
    stwio r20, 4(r18)		#instruction to do the above

POLL:
    ldwio r13, 0(r18)	#load timer into r12
    andi  r13, r13,1	#timer will restart and continue when it times out
    beq   r13, r0, POLL	#repeats
	ret
	
	#AUTOMATIC STATE ABOVE
	#------------------------------------------------------------------------------------------------
	#KEYBOARD STATE BELOW
	
INITIALIZE_KEYBOARD:
	movia r22, PS2ADDRESS #load ps/2 address into r8
	movia r10, A
	movia r11, S
	movia r12, D
	movia r13, W
	movia r14, BREAK
	movi r4, 1	
	
READ_KEYBOARD_VALID:
	
	ldwio r15, 0(r22)
	srli  r16, r15, 15		#shift by 15 bits, because on 15th
	andi r16, r16, 1
	beq r16, r4, READ_KEYBOARD
	br LOOP2
	
READ_KEYBOARD:
	andi r15, r15, 0xFF
	beq r15, r10, DO_A
	beq r15, r11, DO_S
	beq r15, r12, DO_D
	beq r15, r13, DO_W
	br LOOP2
	
DO_A:
	movia r20, TURNLEFT
	stwio r20, 0(r8)
	
	ldwio r15, 0(r22)
	ldwio r17, 0(r22)

	andi r15, r15, 0xFF
	andi r17, r17, 0xFF
	bne r15, r14, DO_A		#check if F0 inputted
	beq r17, r10, TURN_OFF

DO_D:
	movia r20, TURNRIGHT
	stwio r20, 0(r8)
	
	ldwio r15, 0(r22)
	ldwio r17, 0(r22)

	andi r15, r15, 0xFF
	andi r17, r17, 0xFF
	bne r15, r14, DO_D		#check if F0 inputted
	beq r17, r12, TURN_OFF
	
DO_W:
	movia r20, MOTORFORWARD
	stwio r20, 0(r8)
	
	ldwio r15, 0(r22)
	ldwio r17, 0(r22)

	andi r15, r15, 0xFF
	andi r17, r17, 0xFF
	bne r15, r14, DO_W		#check if F0 inputted
	beq r17, r13, TURN_OFF
	
DO_S:
	movia r20, REVERSE
	stwio r20, 0(r8)
	
	ldwio r15, 0(r22)
	ldwio r17, 0(r22)

	andi r15, r15, 0xFF
	andi r17, r17, 0xFF
	bne r15, r14, DO_S		#check if F0 inputted
	beq r17, r11, TURN_OFF
	
TURN_OFF:
	movia r20, 0xFFFFFFFF
	stwio r20, 0(r8)
	br LOOP2
	

#---------------------------------
#Interrupt handling
#---------------------------------

.section .exceptions, "ax"

myISR:
	bne r23, r0, ZEROISR
	
ONEISR:
	movia r14, 0x00000000	#counter register set as 0
	stwio r14, 0(r14)
	movia r12, HEXDISPLAY
	movi r23, 1
	br EXITISR
	
ZEROISR:
	movi r23, 0
		
EXITISR:
	movia r22, 0xFFFFFFFF
	stwio r22, 12(r2)
	subi ea, ea, 4
	eret
