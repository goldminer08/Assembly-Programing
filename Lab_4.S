# ------------------------------------------------------------------
# Student Information
# ------------------------------------------------------------------
# Lab number            : 4
# Group number          : 43
# Section number        : 203
# Student-1 name        : Gabriel Graterol
# Student-2 name        : Pasindu Danthanarayana
# ------------------------------------------------------------------
# -------------- YOUR CODE MUST BE WELL COMMENTED ------------------
# -------------- YOU MAY REMOVE UNNECESSARY COMMENTS ---------------
# ------------------------------------------------------------------

.section .text
.align 2
.globl _start

# --------------------------------------------------------------------------------------------------------------
# Constants and Register Definitions
# --------------------------------------------------------------------------------------------------------------

# GPIO control register base address and offsets
GPIO_BASE                   = 0x10012000        # GPIO base address
GPIO_OUTPUT_ENABLE          = 0x08              # GPIO output enable register (set pins as output)
GPIO_OUTPUT_VAL             = 0x0C              # GPIO output data register (write pin states)
GPIO_INPUT_ENABLE           = 0x04              # GPIO input enable register (set pins as input)
GPIO_INPUT_VAL              = 0x00              # GPIO input data register (read pin states)
GPIO_FALL_INTERRUPT_ENABLE  = 0x20              # Falling edge interrupt enable register offset
GPIO_FALL_INTERRUPT_PENDING = 0x24              # Falling edge interrupt pending register offset

# PLIC control register base address and offsets
PLIC_BASE                   = 0x0C000000        # PLIC base address
PLIC_ENABLE                 = 0x2000            # PLIC interrupt enable register offset
PLIC_PRIORITY               = 0x0004            # PLIC priority register offset
PLIC_THRESHOLD              = 0x200000          # PLIC threshold register offset 
                                                # (absolute addr = 0x0C200000, base + offset)
PLIC_CLAIM                  = 0x200004          # PLIC claim/complete register offset
PLIC_INT_PEND               = 0x1000            # PLIC interrupt pending register offset

# Define the GPIO Input and Output Pins
GPIO_LEDBAR_PINS            = 0x00FC0C00        # LED bar pins (8)
GPIO_SW_1                   = 0x00001000        # S1 / PB1
GPIO_SW_2                   = 0x00002000        # S2 / PB2
GPIO_ALL_PBS                = 0x00003000        # All pushbuttons

# Variables for Pushbutton S1
S1_GPIO_PIN                 = 12                # S1 pushbutton pin number (active low)
S1_IRQ                      = 12                # IRQ (Interrupt Request) number for GPIO pin 12
S1_PLIC_ID                  = 20                # PLIC interrupt source ID for GPIO pin 12 (12 + 8 = 20)
S1_PRIORITY                 = 7                 # Interrupt priority for S1 (0 = lowest, 7 = highest)


_start:

# Set up mtvec with the address of the interrupt vector (S1_interrupt)
      la t0, S1_interrupt                 # Load the address of the interrupt handler 'S1_interrupt' into t0
                                          # S1_interrupt represents the Interrupt Service Routine (ISR) found at the bottom of the code
      csrw mtvec, t0                      # csrw: CSR write,  writes the value in register t0 (which is the 
                                          # address of the interrupt handler) to the mtvec register.                        
                                          # Set the mtvec register to the address in t0 (S1_interrupt)
# Enable "External" machine interrupts in the mie register
      li t0, (1 << 11)                    # Set bit 11 to "1" and write it to t0
                                          # This bit (bit 11) corresponds to the external interrupt enable
      csrs mie, t0                        # csrs: CSR Set, it performs a bitwise OR between the current 
                                          # value of mie and the value in t0
                                          # Set bit 11 in the mie register (enable external interrupts)
# mtvec: Machine Trap Vector register, it stores the address of the interrupt handler
# directing the processor to jump to this address, S1_interrupt, when an interrupt occurs.

# Enable global machine interrupts (MIE, bit 3 of mstatus)
      csrr t0, mstatus                    # read the value of the mstatus into t0
      li t1, (1 << 3)                     # Set MIE (Machine Interrupt Enable)
                                          # (1<<3): this instruction puts "1" at the 3rd bit 
      or t0, t0, t1                       # add t0 "mstatus" to t1, where we actually are setting bit 3 to "1"
                                          # This sets the 3rd bit (MIE) in t0 without modifying other bits
      csrw mstatus, t0                    # Write the modified value in t0 back to the mstatus register

# ------------------------------Configure SW1 as an input------------------------------
li t1, GPIO_BASE # loads value of GPIO_BASE into register t1.
li t2, GPIO_SW_1 # Loads value of GPIO_SW_1 onto t2 to enable the S1 as inputs.
sw t2, GPIO_INPUT_ENABLE(t1) # Stores the value in t2 into GPIO_BASE, with offset GPIO_INPUT_ENABLE (0x10012004).



# -----------------------Configure GPIO LEDs pins as an output-------------------------
li t2, GPIO_LEDBAR_PINS # Loads value of GPIO_LEDBAR_PINS into register t2.
sw t2, GPIO_OUTPUT_ENABLE(t1) # Stores value from t2 (0x00FC0C00) into address in t1 (0x10012000), with an offset of GPIO_OUTPUT_ENABLE (0x08) to store in address 0x10012008.


# ----------------------------Turn Off all LEDs in LED Bar-----------------------------
 sw x0, GPIO_OUTPUT_VAL(t1) # Stores value in x0 (0x00000000) into address stored in t1, with offset of GPIO_OUTPUT_VAL (0x1001200C)



# ------------Enable Falling edge for S1: Remember S1 is a GPIO and not PLIC-----------
lw t2, GPIO_FALL_INTERRUPT_ENABLE(t1) # Loads the value currently stored at address in t1 (0x10012000), with offset GPIO_FALL_INTERRUPT_ENABLE (0x10012020).
li t3, GPIO_SW_1 # Loads the value of GPIO_SW_1 (0x00001000) into register t3.
or t2, t2, t3 # Ors result of t3 and t2 to set the interrupt to look for falling edge of PB1.
sw t2, GPIO_FALL_INTERRUPT_ENABLE(t1) # Stores value in t2, into address in t1 (0x10012000), with offsset GPIO_FALL_INTERRUPT_ENABLE (0x10012020).


# ----------------------------Enable PLIC for S1 interrupt-----------------------------
li t4, (1 << S1_PLIC_ID) # Loads value into t4 of one shifted by S1_PLIC_ID, to shift 1 by 20, to enable the PLIC for interrupt for S1 button.
li t5, PLIC_BASE + PLIC_ENABLE # Loads value in t5 of sum of PLIC_BASE and PLIC_ENABLE (0xC002000).
sw t4, 0(t5) # Stores value in t4, into the address in t5, to enable PLIC for S1 interrupt.
                   

# ----------------Set PLIC priority for S1 interrupt to 7 "Highest Priority"-----------
# -----------The address is calculated according to: PLIC_BASE + 4 × S1_PLIC_ID--------
li t4, S1_PRIORITY # Loads value of S1_PRIORITY (7) into t4.
li t5, S1_PLIC_ID # Loads value of S1_PLIC_ID (20) into register t5.
slli t5, t5, 2 # Shifts left logical t5 by 2, to multiply S1_PLIC_ID by 4.
li t3, PLIC_BASE # loads value of PLIC_BASE (0x0C000000).
add t5, t5, t3 # Adds the value in t5 (4*S1_PLIC_ID) and t3 (PLIC_BASE).
sw t4, 0(t5) # Stores value in t4 (S1_PRIORITY) into address stored in t5 (0xC000050)


# -------------------------------Set PLIC threshold to 6-------------------------------
li t5, PLIC_BASE + PLIC_THRESHOLD # Loads value of PLIC_BASE + PLIC_THRESHOLD (0x0E000000).
li t4, 6 # Loads immediate value of 6 onto register t4.
sw t4, 0(t5) # Stores 6 onto address into t5 (0x0E000000) to set PLIC threshold to 6.



# Initialize pseudo-random generator and countdown timer
      li a7, 0xABCD                       # Seed value for PRNG
      li a4, 0                            # Countdown timer value


main_program:                             
# -------------------Flashing the LEDS at a rate of 5 Hz (0.2 seconds delay)----------------
      li s0, GPIO_LEDBAR_PINS # Loads value of GPIO_LEDBAR_PINS (0x00FC0C00) onto register s0.
      sw s0, GPIO_OUTPUT_VAL(t1) # Stores this value into address in t1 with offset GPIO_OUTPUT_VAL (0x1001200C).

      loop:                               # Start of delay loop used as a simple timer (~0.2 sec (to achieve flashing leds at 5 Hz)).
       li t4, 0x186A00   # Load the correct value that corresponds to 0.2 secs to t4.
       loop1:  # Loop used to create a 0.2 secs delay.
            beq t4, x0, exit  # Checks if already had 0.2 secs delay, to break the loop.                                                        
            addi t4, t4, -1  # Decrements counter by one.
            j loop1 # Jumps back to loop to continue delay.
      exit: 
      lw t3, GPIO_OUTPUT_VAL(t1) # loads value of all led pins onto register t3.
      xor t5, t3, s0 # xor's the value of t3, with value in s0, to flip the bits of the leds, and stores this in t5. 
      sw t5, GPIO_OUTPUT_VAL(t1) # Stores t5 into address in t1 with offset GPIO_OUTPUT_VAL (0x1001200C) to flash the leds.
      jal RandomNum # Jump and links to RandomNum subroutine to generate a random number as the leds are flashing.
      j loop # Jumps back to loop label to continously execute main program until S1 button is pressed.



# Interrupt Service Routine (ISR) for S1 interrupt
.align 2
S1_interrupt:
# ----------------------------- Save Registers to Stack -----------------------------
addi sp,sp, -16 # Allocates space on the stack for 4 registers, 4 bytes each.
sw s0, 0(sp) # saves s0 on stack.
sw ra, 4(sp) # saves ra on stack.
sw s1, 8(sp) # saves s1 register onto stack.
sw s4, 12(sp) # saves s4 register onto stack.


# -------------------------- Acknowledge Interrupt in PLIC --------------------------
    li s3, PLIC_BASE + PLIC_CLAIM         # Address of PLIC claim/complete register
    lw t5, 0(s3)                          # Read Interrupt ID from claim register


# ----------------------------- Scale a7 and save it in a4 ---------------------------
      Scale: # Subroutine to scale number between 50 and 250 for countdown timer.
      li s4, 0x0000FFFF # Value used to extract lower 16 bits.
      and a7, a7,s4 # Ands s4 with a7 to extract lower 16 bits, to ensure between 1-65,535
      li s0, 250 # Loads value of 250 onto s0.
      rem a4, a7, s0 # Calculates the modulo result of random num and 250, which is a result between 0 and 249.
      li a5, 201 # Loads immediate of 201 onto a5, used to compare if mod result is greater than or equal to 201, to not add 50 to remain in range.
      bge a4,a5, noadd # If the modded result is greater than or equal to 201, then dont add 50.
      addi a4, a4, 50 # Adds 50 to the result of mod to ensure within range for small mod results. 
      noadd:

      jal ra, LED_ON_COUNTER # jump and links to LED_ON_COUNTER to turn on the leds.

      loop3:
      bge x0,a4, exit3 # Once timer reaches 0 or below, then stop timer as all values have been displayed.
            delay_sec: # Subroutine used to delay by one second.
            li s1, 0x7A1200 # Loads value of 16M / 2, because there are 16M cycles on one second, but there are two insructions of one cycle each
                            # so use 8M (0x7A1200), to accurately execute a delay of 1 second.
            loop2: # Loop used to execute delay of one second.
            beq s1, x0, exit2 # Once executed a one second delay, then exit the loop.
            addi s1, s1,-1 # Decrements counter by one every time loop runs.
            j loop2 # Jumps back to loop2 to continue delay. 
            exit2:
            addi a4,a4,-10 # Decrements counter value by 10, because 5.6 seconds corresponds to 56, so one second is indicated by subtracting 10.
            jal ra, LED_ON_COUNTER # Jumps to LED_ON_COUNTER to display the current value of the timer on the led bar.
            j loop3 # Jumps back to loop 3 to continue displaying timer.
      exit3:

      add a4,x0,x0 # Once countdown has reached 0, reset the timer to 0
      jal ra, LED_OFF # Jumps and links to LED_OFF to turn off all the LEDs

     li s1, GPIO_BASE # Loads immediate GPIO_BASE (0x10012000) address onto s1 
     li s2, GPIO_SW_1 # Loads immediate GPIO_SW_1 (0x00001000) onto s2 
     sw s2, GPIO_FALL_INTERRUPT_PENDING(s1) # Clears the GPIO interrupt by storing s2 into address s1 with offset GPIO_FALL_INTERRUPT_PENDING (0x10012024)

    sw t5, 0(s3)                          # Write it back to complete the interrupt

      lw s0, 0(sp) # Restores value of s0 from stack.
      lw ra,4(sp) # Restores value of ra from stack.
      lw s1, 8(sp) # Restores value of s1 from stack.
      lw s4, 12(sp) # Restores value of s4 from stack.
      addi sp,sp, 16 # Properly deallocates stack frame for this subroutine. 

# ----------------------------- Restore Registers & Return --------------------------
    mret                                  # Return from interrupt

LED_OFF:
    addi sp, sp, -8 # Allocates 8 bytes on stack by moving stack pointer down 8 bytes.
    sw ra, 0(sp) # Stores return address into stack, to load after subroutine complete.
    sw t2, 4(sp) # Stores t2 in the stack.

    sw x0, GPIO_OUTPUT_VAL(t1) # Stores 0 into address in t1 with offset GPIO_OUTPUT_VAL (0x1001200C) to turn off all leds.

    lw ra, 0(sp) # Loads original return address into ra pointer.
    lw t2, 4(sp) # Retrieving original t2 value from stack, and storing back in t2.
    addi sp, sp, 8 # Deallocates space allocated in stack for this subroutine.

    ret # Returns to where this subroutine was called.

LED_ON_COUNTER:
    addi sp, sp, -12 # Allocates 12 bytes on stack by moving stack pointer down by 12.
    sw ra, 0(sp) # Stores return address into stack, to load after subroutine complete.
    sw s1, 4(sp) # Stores s1 into stack, to load after subroutine complete.
    sw a4, 8(sp) # Stores a4 into stack, to load after subroutine complete.


    andi s1, a4, 0x3 # To extract lower two bits since led bits are split in GPIO bit pattern. 
    slli s1, s1, 10 # To move into proper bits of LED 0 and 1.
    srli a4, a4, 2 # Remove lower two bits from value.
    slli a4, a4, 18 # Moves it to correct bits to turn on corresponding bits.

    or a4, a4, s1 # Computes the or of a4 and s1, and stores it in a4, to have bits in correct position to display counter value.
    sw a4, GPIO_OUTPUT_VAL(t1) # Stores value of a4 into the address that t1 stores, with offset of GPIO_OUTPUT_VAL (0x1001200C).

    lw ra, 0(sp) # Loads original return address into the ra register.
    lw s1, 4(sp) # Loads original s1 value into the s1 register.
    lw a4, 8(sp) # Loads original a4 value into the a4 register.
    addi sp, sp, 12 # Deallocates the space on stack allocated for this subroutine.

    ret # Returns to where this subroutine was called.

RandomNum:
      # to optimize the code, we use the same registers used before (t1 and t3)
      addi sp, sp, -16                      # Decrement stack pointer to make space for saved registers.
      sw t1, 0(sp)                          # Store register t1 in the stack at offset 0.
      sw t3, 4(sp)                          # Store register t3 in the stack at offset 4.
      sw ra, 8(sp)                          # Store return address (ra) in the stack at offset 8.
      
      # Start random number generation by manipulating the bits of a7.
      li s4, 0x8000                         # Load the value 0x8000 (32,768) into register s4.
      and t1, a7, s4                        # Mask the lower 16 bits of a7 by performing an AND with 0x8000. Store the result in t1.
      li s4, 0x2000                         # Load the value 0x2000 (8,192) into register s4.
      and t3, a7, s4                        # Mask the lower 16 bits of a7 by performing an AND with 0x2000. Store the result in t3
      slli t3, t3, 2                        # Shift the bits of t3 left by 2, effectively multiplying t3 by 4.
      xor t3, t1, t3                        # Perform an XOR operation between t1 and t3, and store the result in t3.
      li s4, 0x1000                         # Load the value 0x1000 (4,096) into register s4.
      and t1, a7, s4                        # Mask a7 using t0 and store the result in t1.
      slli t1, t1, 3                        # Shift t1 left by 3 (multiply by 8).
      xor t3, t3, t1                        # XOR t1 with t3 and store the result back in t3.
      andi t1, a7, 0x0400                   # Perform an AND operation with 0x0400 to extract a specific bit pattern from a7.
      slli t1, t1, 5                        # Shift the bits of t1 left by 5.
      xor t3, t3, t1                        # XOR t3 with t1 and store the result back in t3.
      srli t3, t3, 15                       # Shift the bits of t3 right by 15 (to normalize the value).
      slli a7, a7, 1                        # Shift the bits of a7 left by 1, effectively multiplying by 2.
      or a7, a7, t3                         # Perform a logical OR between a7 and t3, and store the result in a7.

      # Restore the saved registers from the stack to their original values.
      lw t1, 0(sp)                              # Load the value of t1 back from the stack.
      lw t3, 4(sp)                              # Load the value of t3 back from the stack.
      lw ra, 8(sp)                              # Load the return address (ra) back from the stack.
      addi sp, sp, 16                           # Restore the stack pointer by adding 16.
      ret                                       # Return from the subroutine, passing the generated random number in a7.