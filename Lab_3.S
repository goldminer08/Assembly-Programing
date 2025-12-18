.section .text
.align 2
.globl _start


_start:
    
    # GPIO Control Registers Memory Mapping
    .equ GPIO_BASE_CTRL_ADDR,   0x10012000      # Base address for GPIO control registers
    .equ GPIO_OUTPUT_EN,        0x08            # Offset to enable GPIO outputs
    .equ GPIO_OUTPUT_VAL,       0x0C            # Offset to write GPIO outputs
    .equ GPIO_INPUT_EN,         0x04            # Offset to enable GPIO inputs
    .equ GPIO_INPUT_VAL,        0x00            # Offset to write GPIO inputs


    # Define GPIO Pin Mapping for LEDs (8 LEDs in LED bar, LED6)

    .equ GPIO_7SEGLED_PINS, 0x0000023F          # Seven Segment LED Display Pins (7)
    .equ GPIO_LEDBAR_PINS,  0x00FC0C00          # LED Bar Pins (8)
    .equ GPIO_ALL_LED_PINS, 0x00FC0E3F          # All LED Pins (15)
    .equ GPIO_LEDBAR_LED_6, 0x00400000          # LEDBAR LED6 (Bit 22)



    # Configure the GPIO Outputs for all LEDs
    li t0, GPIO_BASE_CTRL_ADDR # loads value of GPIO_BASE_CTRL_ADDR into register t0.
    li t1, GPIO_ALL_LED_PINS # loads value of GPIO_ALL_LED_PINS into register t1.
    sw t1, GPIO_OUTPUT_EN(t0) # Stores value from t1 (0x00FC0E3F) into address in t0 (0x10012000), with an offset of GPIO_OUTPUT_EN (0x08) to store value of t1 into address 0x10012008.


    # Define GPIO Pin Mapping for Pushbuttons (S1, S2, and both)
    .equ GPIO_PUSH_S1, 0x00001000 # Sets position of push button S1 onto variable GPIO_PUSH_S1.
    .equ GPIO_PUSH_S2, 0x00002000 # Sets position of push button S2 onto variable GPIO_PUSH_S2.
    .equ GPIO_PUSH_BUTTONS, 0x00003000 # Stores position of push button S1 and S2 onto variable GPIO_PUSH_BUTTONS.
    


    # Configure the GPIO Inputs for the pushbuttons used (S1, S2, or both)
    li t2, GPIO_PUSH_BUTTONS # Loads value of GPIO_PUSH_BUTTONS onto t2 to enable the buttons as inputs.
    sw t2, GPIO_INPUT_EN(t0) # Stores the value in t2 into GPIO_BASE_CTRL_ADDR, with offset GPIO_INPUT_EN (0x10012004)


    # Turn off all LEDs
    li t1, 0x00000000 # loads value of 0x00000000 into register t1.
    sw t1, GPIO_OUTPUT_VAL(t0) # Stores value in t1 (0x00000000) into address stored in t0, with offset of GPIO_OUTPUT_VAL (0x1001200C)



InitRandomNum:
    # Sets a7 to a 16-bit non-zero value; only the PRNG subroutine should modify a7
    li a7, 0xABCD


# -------------------LED Binary Counter and GPIO Verification----------------------
Task_1:
    li s0, 0x00 # Loads immediate value onto s0, as starting value of counter
    li s1, 0xFF # Loads 0xFF onto s1 for branch condition for loop
    loop: # Loop used for displaying counter on LEDs
       lw s5, GPIO_INPUT_VAL(t0) # These next four lines are used for polling purposes, if S2 is pressed, then jump to the reflex_meter subroutine
       li t1, GPIO_PUSH_S2  
       and s5, s5, t1
       beq s5, x0, Task_2

        beq s0, s1, reset # If counter reached 0xFF, then branch to reset to begin counter again from 0x00
        mv a0, s0 # Stores value in s0 into register a0
        jal ra, LED_ON_COUNTER # Jumps to LED_ON_COUNTER, to display the current counter value on LED Bars
        jal ra, Delay100m # Jumps to Delay100m, to have 100ms delay between displaying counter values
        addi s0, s0, 1 # Increments counter value by 1
        j loop


        reset: # reset is used to turn off all LEDS, and resets counter to 0x00 to begin counter again.
        jal LED_OFF 
        li s0, 0
        j loop

LED_ON_COUNTER:
    addi sp, sp, -4 # Allocates 4 bytes on stack by moving stack pointer down by 4.
    sw ra, 0(sp) # Stores return address into stack, to load after subroutine complete.

    andi t2, a0, 0x3 # To extract lower two bits since led bits are split in GPIO bit pattern. 
    slli t2, t2, 10 # To move into proper bits of LED 0 and 1.
    srli a0, a0, 2 # Remove lower two bits from value.
    slli a0, a0, 18 # Moves it to correct bits to turn on corresponding bits.

    or a0, a0, t2 # Computes the or of a0 and t2, and stores it in a0, to have bits in correct position to display counter value.
    sw a0, GPIO_OUTPUT_VAL(t0) # Stores value of a0 into the address that t0 stores, with offset of GPIO_OUTPUT_VAL (0x1001200C).

    lw ra, 0(sp) # Loads original return address into the ra register.
    addi sp, sp, 4 # Deallocates the space on stack allocated for this subroutine.

    ret
LED_ON_LED6:
    addi sp, sp, -4 # Allocates 4 bytes on stack by moving stack pointer down by 4.
    sw ra, 0(sp) # Stores return address into stack, to load after subroutine complete.

    li t3, GPIO_LEDBAR_LED_6 # Loads immediate value onto t3, used to turn on only LED6.
    sw t3, GPIO_OUTPUT_VAL(t0) # Stores value of t3 into the address that t0 stores, with offset of GPIO_OUTPUT_VAL (0x1001200C).

    lw ra, 0(sp) # Loads original return address into the ra pointer.
    addi sp, sp, 4 # Deallocates the space on stack allocated for this subroutine.

    ret
LED_OFF:
    addi sp, sp, -8 # Allocates 8 bytes on stack by moving stack pointer down 8 bytes.
    sw ra, 0(sp) # Stores return address into stack, to load after subroutine complete.
    sw t1, 4(sp) # Stores t1 in the stack.

    li t1, 0x00000000 # Loads value of 0 onto register t1.
    sw t1, GPIO_OUTPUT_VAL(t0) # Stores 0 into address in t0 with offset GPIO_OUTPUT_VAL (0x1001200C) to turn off all leds.

    lw ra, 0(sp) # Loads original return address into ra pointer.
    lw t1, 4(sp) # Retrieving original t1 value from stack, and storing back in t1
    addi sp, sp, 8 # Deallocates space allocated in stack for this subroutine.

    ret # returns to where this subroutine was called.
Delay100m:
    addi sp, sp, -4 # Allocates 4 bytes on the stack to store one 32 bit register.
    sw ra, 0(sp) # Stores return address onto the stack.

    li t1, 0x000C3500 # Since clock cycle is 16Mhz, indicates 16M cycles in one second, so 1.6M cycles are completed in 0.1s,
                      # so we initialize counter to 800k in hex (0x000C3500) because two operations, each of one cycle, occur in one subtraction of counter, stored in t1.
    loop2:
        addi t1, t1, -1 # Decrements counter by 1 every time loop2 runs.
        bnez t1, loop2 # If the counter is not 0, then continue looping through loop2 to achieve 100ms delay.
    
    lw ra, 0(sp) # Stores original return address from stack back into ra.
    addi sp, sp, 4 # Deallocates space on stack that was allocated at beginning of subroutine.

    ret # Returns to where Delay100m subroutine was called.

# ----------------------------------Task 2: Reflex Meter-----------------------------------
Task_2:
    jal ra, LED_OFF # Jumps to LED_OFF subroutine to turn off all LEDs.
    jal ra, RandomNum # Jumps to RandomNum subroutine to generate a random number for delay.
    jal ra, Scale # Jumps to Scale subroutine to scale the value given by RandomNum to be in required range.
    jal ra, DelayRNG # Jumps to DelayRNG to delay by correct time given by RandomNum
    returnLedOn6:
    jal ra, LED_ON_LED6  # Jumps to turn on LED_ON_LED6 subroutine to turn on LED 6
    mv t5, x0 # Stores value 0 in t5 to be used for counter.
    loop7: # Loop used to count the time it takes for user to press push button S1.
        li t0, GPIO_BASE_CTRL_ADDR # Next four lines is implementing polling to check if user pressed push button S1.
        lw s5, GPIO_INPUT_VAL(t0)
        li t1, GPIO_PUSH_S1
        and s5, s5, t1 # And operation is used to extract value of push button S1.
        beq s5, x0, exittask_2 # If S1 pressed, then proceed to displaying counter of reflex time.
        jal ra, delay # Jumps to delay subroutine to implement delay between displaying subsequent bytes.
        addi t5, t5, 1 # Increments counter by 1.
        j loop7 # Jumps back to start of loop7.
   exittask_2:
   jal ra, LED_OFF # Jumps to LED_OFF subroutine to turn off all LEDS
   li s5, 4 # Counter used to display four bytes of counter.
   loop8: 
    beq s5, x0, exit8 # If already displayed all four bytes, do not display anything else.
    jal ra, display_counter # Jumps to display_counter to display one byte of counter.
    jal ra, delay2secs # Delays 2 seconds between two bytes being shown on LED bar.
    srli t5, t5, 8 # Clears lower 8 bits since those 8 bits have already been displayed.
    addi s5, s5, -1 # Decrements loop counter by 1.
    j loop8 # Jumps back to beginning of loop8.

    exit8:
        jal ra, delay5secs # Delays 5 seconds after the full 32-bit counter has been displayed.
        j returnLedOn6 # Jumps to line in task_2 where LED_6 is turned on and repeats all subsequent instructions. 

display_counter:
    addi sp, sp, -12 # Stores ra, t5, and t4 onto the stack since using these registers.
    sw ra, 0(sp)
    sw t5, 4(sp)
    sw t4, 8(sp)

    li t0, GPIO_BASE_CTRL_ADDR # Loads base address of GPIO onto t0

    andi t5, t5, 0x0FF # Used to extract the lower 8 bits of counter.
    andi t4, t5, 0x3 # To extract lower two bits since leds split in GPIO bit pattern.
    slli t4, t4, 10 # To move into proper bits of LED 0 and 1.
    srli t5, t5, 2 # Remove lower two bits from value since stored in t4.
    slli t5, t5, 18 # Moves values to correct bits to turn on corresponding leds.

    or t5, t4, t5 # Computes the OR of t4 and t5, in order to have the correct value for displaying the number on the LED bar.
    sw t5, GPIO_OUTPUT_VAL(t0) # Stores value of t5 into the address that t0 stores, with offset of GPIO_OUTPUT_VAL (0x1001200C).


    lw ra, 0(sp) # Loads original return address into the ra register.
    lw t5, 4(sp) # Loads original value of t5 into t5 register.
    lw t4, 8(sp) # Loads original value of t4 into t4 register.
    addi sp, sp, 12 # Deallocates stack frame used by this subroutine.

    ret
delay2secs: # Delay subroutine used to delay 2 seconds
    addi sp, sp, -8 # Allocates stack frame, and stores ra and s4 onto the stack.
    sw ra, 0(sp)
    sw s4, 4(sp)

    li s4, 0xF42400 # Since 16M cycles in one second, then 32M cycles are completed in two seconds. Since two instructions in loop, each of one cycle each, account for this by beginning
                    # the counter at 16M, in order to get the proper delay.
    loop10: 
        beq s4, x0, exit10 # If already delayed for two seconds, then exit loop.
        addi s4, s4, -1 # Decrements counter by 1.
        j loop10 # Jumps back to beginning of loop10.
    exit10:

    lw ra, 0(sp) # Stores original ra value onto ra register.
    lw s4, 4(sp) # Stores original s4 value onto s4 register.
    addi sp, sp, 8  # Deallocates stack frame of this subroutine.

    ret

delay5secs: # Delay subroutine used to delay 5 seconds.
    addi sp, sp, -8 # Allocates stack frame, and stores ra and s4 onto the stack.
    sw ra, 0(sp)
    sw s4, 4(sp)

    li s4, 0x2625A00 # Since 16M cycles in one second, then 80M cycles are completed in five seconds. Since two instructions in loop, each of one cycle each, account for this by beginning
                    # the counter at 40M, in order to get the proper delay.
    loop9: 
        beq s4, x0, exit9 # Once counter reaches zero, then already have 5 second delay, so exit loop.
        addi s4, s4, -1 # Decrements counter by 1.
        j loop9 # Jumps back to beginning of loop9.
    exit9:

    lw ra, 0(sp) # Stores original ra value onto ra register.
    lw s4, 4(sp) # Stores original s4 value onto s4 register.
    addi sp, sp, 8  # Deallocates stack frame of this subroutine.

    ret

delay: # Delay of 0.1ms
    addi sp, sp, -8 # Allocates 8 bytes on stack to store ra and s4 register.
    sw ra, 0(sp)
    sw s4, 4(sp)

    li s4, 800 #  Since 16M cycles in one second, then 1600 cycles are completed in 0.1m seconds. Since two instructions in loop, each of one cycle each, account for this by beginning
                    # the counter at 800, in order to get the proper delay.
    loop5: 
        beq s4, x0, exit5 # If already achieved 0.1 ms delay, then exit loop.
        addi s4, s4, -1 # Decrements counter by 1.
        j loop5 # Jumps back to beginning of loop5.
    exit5:

    lw ra, 0(sp) # Stores original ra value onto ra register.
    lw s4, 4(sp) # Stores original s4 value onto s4 register.
    addi sp, sp, 8 # Deallocates stack frame of this subroutine.

    ret
# ----------------------------------------Scaling-------------------------------------------
# Scaling the randum number generated (a7) between 2 and 10 sec
Scale:
    addi sp, sp, -8  # Allocates 8 bytes on stack to store ra and s0 register.
    sw ra, 0(sp)
    sw s0, 4(sp)

    li s0, 0x4E20 # Loads value of 20,000, as used for branch condition as any value greater then this value gives valid delay.
    loop3:
        bge a7, s0, exit3 # If randomNum gives valid value, then do not call RandomNum again.
        jal ra, RandomNum # If invalid delay, then call RandomNum again to get correct value.
        j loop3 # Jumps back to beginning of loop 3 to check if new value is valid.
    exit3:
    lw ra, 0(sp) # Stores original ra value onto ra register.
    lw s0, 4(sp) # Stores original s0 value onto s0 register.
    addi sp, sp, 8 # Deallocates stack frame of this subroutine.

    ret


# -------------------------Pseudo-Random Number Generator------------------------------
# Register a7 will hold the generated random number
# You may read this register anywhere in your program.
# Important: Only this subroutine should write to a7.
RandomNum:
    addi sp, sp, -16
    sw ra, 12(sp)                  # Save return address

    li s4, 0x8000                  # Select bit 15 of a7
    and t1, a7, s4                 # Extract bit 15

    li s4, 0x2000                  # Select bit 13 of a7
    and t3, a7, s4                 # Extract bit 13

    slli t3, t3, 2                 # Shift extracted bit 13 left by 2
    xor t3, t1, t3                 # Combine with extracted bit 15

    li s4, 0x1000                  # Select bit 12 of a7
    and t1, a7, s4                 # Extract bit 12

    slli t1, t1, 3                 # Shift extracted bit 12 left by 3
    xor t3, t3, t1                 # Combine with previous result

    andi t1, a7, 0x0400            # Select bit 10 of a7
    slli t1, t1, 5                 # Shift bit 10 left by 5
    xor t3, t3, t1                 # Combine with previous result

    srli t3, t3, 15                # Shift result right by 15
    slli a7, a7, 1                 # Shift a7 left by 1
    or a7, a7, t3                  # Update a7 with new pseudo-random value

    lw ra, 12(sp)                  # Restore return address
    addi sp, sp, 16                # Restore stack pointer
    ret                             # Return from subroutine

# ---------------------------- DELAY ROUTINES -----------------------
# Create as much as you need.
DelayRNG:
    addi sp, sp, -16 # Allocates 16 bytes on stack to store values in ra, s3, s4, and s5 registers.
    sw ra, 0(sp)
    sw s3, 8(sp)
    sw s4, 4(sp)
    sw s5, 12(sp)

    mv s5, a7 # Stores value of a7 into register s5.

   slli s5, s5, 2 # Multiplying value by 2 to scale value to get delay in 5% tolerance.

    loopouter: # Outer loop used for proper delay.
        beq s5, x0, exitouter # Once reaches zero, achieved required delay, so stop looping.
        addi s5, s5, -7 # Decrement counter, using -7 in order to achieve 5% tolerance.
        li s4, 800 # Value used to achieve 0.1 ms delay in inner loop, in order to increment counter every 0.1 msecs.
    loop4: 
        beq s4, x0, exit4 # Once 0.1 ms delay achieved, then stop looping loop4.
        addi s4, s4, -1 # Decrement loop4 counter by 1.
        j loop4 # Jump back to beginning of loop4.
    exit4:
    j loopouter # Jumps back to loopouter label.
    exitouter:

    lw ra, 0(sp) # Stores original ra value onto ra register.
    lw s3, 8(sp) # Stores original s3 value onto s3 register.
    lw s4, 4(sp) # Stores original s4 value onto s4 register.
    lw s5, 12(sp) # Stores original s5 value onto s5 register.
    addi sp, sp, 16 # Deallocates stack frame of this subroutine.
    ret

    


End:
    .end

