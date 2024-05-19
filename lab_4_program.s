;*-------------------------------------------------------------------
;* Name:    		lab_4_program.s 
;* Term:		Fall 2023, ECE-222
;*-------------------------------------------------------------------
				THUMB 								; Declare THUMB instruction set 
				AREA 			My_code, CODE, READONLY 	 
				EXPORT 			__MAIN 					; Label __MAIN is used externally 
                		EXPORT      		EINT3_IRQHandler
				ENTRY 

__MAIN
				MOV			R6, #0					; Initialize R6 to 0, indicates that INT0 haven't been pushed
				LDR			R2, =ISER0				; Load addr for Interrupt Set-Enable Register 0 register to R2
				MOV			R3,	#0x00200000			; (0010 0000 0000 0000 0000 0000) in hex = 0x200000, where the 21th bit is 1
				STR			R3, [R2]				; Enable EINT3 (External Interrupt 3 Interrupt Enable) - Table 52
				MOV			R2, #0
				MOV 			R3,	#0
				
				LDR			R2, =IO2IntEnf			 	; Load GPIO Interrupt Enable for port 2 Falling Edge to R2
				MOV			R3, #0x00000400			 	; (0100 0000 0000) in hex = 0x400 , where the 10th bit is 1
				STR			R3, [R2]				; Enable falling edge interrupt port2 pin10 - Table 117
				MOV			R2, #0
				MOV 			R3,	#0

				LDR			R10, =LED_BASE_ADR		 	; R10 is a  pointer to the base address for the LEDs
				MOV 			R3, #0xB0000000			 	; Turn off three LEDs on port 1  
				STR 			R3, [r10, #0x20]
				MOV 			R3, #0x0000007C
				STR 			R3, [R10, #0x40] 		 	; Turn off five LEDs on port 2 

; This line is very important in your main program
; Initializes R11 to a 16-bit non-zero value and NOTHING else can write to R11 !!
				MOV			R11, #0xABCD				; Init the random number generator with a non-zero number
				
				
LOOP 			
				BL 			RNG  

				
FLASH_LEDS		
				
				BL			RNG
				MOV			R1, #0
				MOV			R6, #0
				MOV32			R1, #0xFF				; Set bit to flash 255 (0xff)
				BL 			DISPLAY_NUM				; Turn ON all LEDs

				
				MOV32			R0, #0x1				; Set delay for 1 x 0.1s = 0.1s
				BL			DELAY					; Delay for 1s for 10HZ flash 
				
				MOV32			R1, #0x00				; Set bit to flash 0(0x00)
				BL			DISPLAY_NUM				; Turn OFF all LEDs
				MOV			R1, #0
			
				MOV32			R0, #0x1				; Set delay for 1 x 0.1s = 0.1s
				BL			DELAY					; Delay for 1s for 10HZ flash 			
				
;				TEQ 			R6, #0
				B			FLASH_LEDS				; Keep Flashing if the button is not pressed

;*------------------------------------------------------------------- 
; Subroutine DISPLAY_NUM ... Display number stored in R1 with LEDs
;*------------------------------------------------------------------- 		
; Display the number in R3 onto the 8 LEDs
; MSB to LSB:		p1.28	 p1.29	  p1.31	  p2.2	  p2.3	  p2.4	  p2.5	  p2.6
DISPLAY_NUM		
				STMFD		R13!,{R1, R2, R14}				; push R1, R2 and LR onto the stack before manipulation
	
	;----------------------------- PORT 2 LEDS --------------------------------;
				MOV			R2, #0x0000				; Initialize R2 to 0
				BFI			R2, R1, #0, #5				; Get 0, 1, 2, 3, 4th bit of R1 and insert them into R2 for Port 2 (5 LEDs in port 2)
				
				RBIT			R2, R2					; Reverse the bit as the higher number LED pins is at LSB 	
				LSR			R2, #25					; right shift the effective bits from upper 31-27 to lower 6-2 (which is the port 2 LEDs) 
				
				EOR			R2, #0x7C				; For onboard LEDs, 0 is ON and 1 is OFF, 0x7C = bin(0111 1100), flip the 6th, 5th, 4th, 3th, 2th bit
				STR			R2, [R10, #0x40]			; Store the value of R2 into the memory location at 0x2009C040 (port 2)
				
	;----------------------------- PORT 1 LEDS --------------------------------;
				MOV			R2, #0x0000				; Initialize R2 to 0
				LSR			R1, #5					; for the top 3 port 1 LED pins, we right shift 8 - 3 = 5 bits to shift out the bits for port 2
				BFI			R2, R1, #0, #1				; Get 0, 1th bit of R1 and insert them into R2 for Port 1 (p1.30 and p1.31)
				
				ORR			R2, R2, R1, LSL #1			; left shift out p1.30 as we don't care the value of 30. Then we OR it to add the bit 28 and 29 to R2
				RBIT			R2, R2					; Reverse the bit as the higher number LED pins is at LSB 	
 	
				EOR			R2, #0xB0000000				; For onboard LEDs, 0 is ON and 1 is OFF, 0xB0000000 = bin(1011 0000 0000 0000   This will flip the 31th, 29th, 28th bit
																										; 	   0000 0000 0000 0000 )
				STR			R2, [R10, #0x20]			; Store the value of R2 into the memory location at 0x2009C020 (port 1)
				
				LDMFD			R13!,{R1, R2, R15}				
		
		
;*------------------------------------------------------------------- 
; Subroutine RNG ... Generates a pseudo-Random Number in R11 
;*------------------------------------------------------------------- 
; R11 holds a random number as per the Linear feedback shift register (Fibonacci) on WikiPedia
; R11 MUST be initialized to a non-zero 16-bit value at the start of the program
; R11 can be read anywhere in the code but must only be written to by this subroutine
RNG 			
				STMFD			R13!,{R1-R3, R14} 			; Random Number Generator 
				AND			R1, R11, #0x8000
				AND			R2, R11, #0x2000
				LSL			R2, #2
				EOR			R3, R1, R2
				AND			R1, R11, #0x1000
				LSL			R1, #3
				EOR			R3, R3, R1
				AND			R1, R11, #0x0400
				LSL			R1, #5
				EOR			R3, R3, R1				; The new bit to go into the LSB is present
				LSR			R3, #15
				LSL			R11, #1
				ORR			R11, R11, R3
				LDMFD			R13!,{R1-R3, R15}


;*------------------------------------------------------------------- 
; Subroutine DELAY ... Causes a delay of 100ms * R0 times
;*------------------------------------------------------------------- 
; 		aim for better than 10% accuracy
DELAY			STMFD		R13!,{R2, R14}

;Processor runs at: 4000000 clock cycles/second, which is: 400000 clock cycles/0.1s
;SUBS takes 1 clock cycle to run, BNE takes 2 clock cycles to run, hence it takes 3 clock cycles to have R2 = R2 - 1
;400000 / 3 = 133333, in hex: 0x000208D5
    
Multi_Delay		
				TEQ			R0, #0
				BEQ			exitDelay
				MOV32			R2, #0x000208D5
				;MOV32			R2, #130
				
Small_Delay	
		;----------------------------- before R2 == 0 --------------------------------;
				SUBS			R2, #1					; To delay for R2 times (0.1ms)
				BNE			Small_Delay
		;----------------------------- after R2 == 0 --------------------------------;
				SUBS 			R0, #1					; To delay for R2*R0 times (0.1ms * R0)
				B 			Multi_Delay

exitDelay			LDMFD			R13!,{R2, R15}



; The Interrupt Service Routine MUST be in the startup file for simulation 
;   to work correctly.  Add it where there is the label "EINT3_IRQHandler
;
;*------------------------------------------------------------------- 
; Interrupt Service Routine (ISR) for EINT3_IRQHandler 
;*------------------------------------------------------------------- 
; This ISR handles the interrupt triggered when the INT0 push-button is pressed 
; with the assumption that the interrupt activation is done in the main program
EINT3_IRQHandler 	
				STMFD 			R13!, {R2, R3, R4, R5, R14}			
				
	;------------------- Code generates new radom number in R6 -------------------------------------;				
				BL			RNG
				MOV			R5, #0
				BFI			R5, R11, #0, #7				; fetch the lowest 8 bit of R11, we don't need other bit
				ADD			R5, R5, #0x32				; Add the lowest 8 bit of R11 with 32, now the number is in range [0x32, 0xFA], or [50, 250]
				MOV			R6, R5					; Move the random number from R5 to R6 to display
		
COUNT_DOWN
				MOV 			R1, R6					; Move R6 into R1 to display number in R6
				BL			DISPLAY_NUM				; Display the number in R6
				
				MOV			R0, #0xA				; Set delay for 1s, 10 x 0.1 = 1s
				BL			DELAY
				
				SUB			R6, R6, #10				; Decrease R6 by 10 every second
				
				CMP			R6, #0					; Compare R6 and 0
				BGT 			COUNT_DOWN				; If R6 is greater than 0, keep coutting down until R6 is equal or less than 0
				
	;--------------------------- Code handles the interrupt ----------------------------------------;	
				LDR			R2, =IO2IntClr				; Load addr for GPIO Interrupt Clear register for port 2 to R2
				MOV32			R3, #0x400				; (0100 0000 0000) in hex = 0x400 , where the 10th bit is 1
				STR			R3, [R2]				; Clear GPIO port Interrupts for P2.10. - Table 124	
				
				LDMFD 			R13!, {R2, R3, R4, R5, R15}			


;*-------------------------------------------------------------------
; Below is a list of useful registers with their respective memory addresses.
;*------------------------------------------------------------------- 
LED_BASE_ADR			EQU 			0x2009c000 			; Base address of the memory that controls the LEDs 
PINSEL3				EQU 			0x4002C00C 			; Pin Select Register 3 for P1[31:16]
PINSEL4				EQU 			0x4002C010 			; Pin Select Register 4 for P2[15:0]
FIO1DIR				EQU			0x2009C020 			; Fast Input Output Direction Register for Port 1 
FIO2DIR				EQU			0x2009C040 			; Fast Input Output Direction Register for Port 2 
FIO1SET				EQU			0x2009C038 			; Fast Input Output Set Register for Port 1 
FIO2SET				EQU			0x2009C058 			; Fast Input Output Set Register for Port 2 
FIO1CLR				EQU			0x2009C03C 			; Fast Input Output Clear Register for Port 1 
FIO2CLR				EQU			0x2009C05C 			; Fast Input Output Clear Register for Port 2 
IO2IntEnf			EQU			0x400280B4			; GPIO Interrupt Enable for port 2 Falling Edge 
IO2IntClr			EQU			0x400280AC			; GPIO Interrupt Clear register for port 2 - Table 124
ISER0				EQU			0xE000E100			; Interrupt Set-Enable Register 0 

				ALIGN 

				END 
