# Assembly-Programing
## About
This repository contains **all RISC-V assembly code** for my ECE labs on the SiFive FE310-G002, covering GPIO, polling/interrupts, timing loops, and LED-based output.

## Lab 3: Input / Output Interfacing
Lab 3 focuses on GPIO input/output on a RISC-V microprocessor, starting with an 8-bit LED binary counter to verify correct LED/GPIO mapping.  
It then implements a polling-based reflex meter that measures reaction time with 0.1 ms resolution using a pseudorandom 2–10s start delay and displays the 32-bit result on the LED bar one byte at a time.

## Lab 4: Interrupt Handling
Lab 4 focuses on interrupt-driven LED countdown on the SiFive FE310-G002 (RISC-V) using a GPIO falling-edge interrupt from the S1 pushbutton routed through the PLIC.
The main loop flashes the 8-LED bar while updating a pseudo-random number generator, and the interrupt service routine scales the latest random value into a 5–25s countdown displayed on the LEDs.
