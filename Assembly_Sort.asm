

define(i_reg, w19)				// register for values of i
define(j_reg, w20)				// register for values of j
define(base, x21)				// base of array
define(temp_reg, w22)				// register for values of temp
define(array_element, w23)			// register for values of array elements 

	size = 4 + 4 + 4 + 4*10			// Total size of stack variables
	i_s = 16				// i offset (16)
	j_s = i_s + 4				// j offset (20)
	temp_s = j_s + 4			// temp offset (24)
	arr_s = temp_s + 4			// array offset (28)	
	alloc = -(16+size) & -16		// memory to be allocated at start of program
	dealloc = -alloc			// memory to be de allocated at end of program

	greet1: .string "\nUnsorted Array:\n"	// string formatting for first greeting
	greet2: .string "\nSorted Array:\n"	// string formatting for second greetig
	printInfo: .string " arr[%d] : %d \n"	// string formatting for displaying array indexes and values to the user

fp .req x29					// Register Equate assembler directive. Alias for x29
lr .req x30					// Register Equate assembler directive. Alias for x30

	.balign 4				// Instructions must be word aligned
	.global main				// Make "main" visible to the OS and start the execution

main:
	stp fp, lr, [sp, alloc]!		// Save FP and LR to stack
	mov fp, sp				// Update FP to the current SP

//----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// Initializing the local variables i, j and temp.

	mov 	i_reg, 		0			// initialize the value of i to 0
	mov 	j_reg, 		0 			// initialize the value of j to 0
	mov	temp_reg, 	0			// initialize the value of temp to 0
	
	str 	i_reg,		[fp, i_s]		// store i at i offset (16)
	str 	j_reg, 		[fp, j_s]		// store j at j offset (20)
	str 	temp_reg,	[fp, temp_s]		// store temp at temp offset (24)
		
	add 	base, 		fp, arr_s		// set the array base to fp + the array offset
	b 	loop_test1				// proceed to loop test 1

//----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// Initializing the array

loop1:

	bl 	rand					// the values in x0 reg is replaced with a populated random value
	and 	array_element,	w0,	1023		// set the array element register to store a random value
	
	ldr 	i_reg,		[fp, i_s]		// load i from the stack	
	str 	array_element,	[base, i_reg, SXTW 2] 	// store the random value at arr[i], using the "scaled register offset" technique 
		
	add 	i_reg, 		i_reg, 1		// increment the index register by one	
	str 	i_reg, 		[fp, i_s]		// store the new index value at i 
	
loop_test1:

	ldr 	i_reg, 		[fp, i_s]		// load i from the stack
	cmp 	i_reg, 		30			// compare it to 30
	b.lt 	loop1					// if less then repeat loop1

//----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// printing the array values to the user

	ldr 	x0, 		=greet1			// load greeting 1 to x0
	bl	printf					// print to the user

	mov 	i_reg,		0			// set the index register to 0
	str 	i_reg, 		[fp, i_s]		// store the index value at i
	b 	loop_test2				// proceed to loop_test 2

loop2:
	ldr 	x0, 		=printInfo		// load fmt1 to x0
	ldr 	w1, 		[fp, i_s]		// load i to w1
	ldr 	w2, 		[base, i_reg, SXTW 2]	// load arr[i] to w2

	bl 	printf					// print i and arr[i] to user

	ldr 	i_reg, 		[fp, i_s]		// load i from the stack
	add 	i_reg, 		i_reg, 1		// increment i by 1
	str 	i_reg, 		[fp, i_s]		// store new i on the stack
	
loop_test2:
	ldr 	i_reg, 		[fp, i_s]		// load i from the stack
	cmp 	i_reg, 		30			// compare to 30
	b.lt 	loop2					// if less than, repeat the loop

//----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// insertion sort algorithm

//----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// Outer Loop

out_loop_setup:
	
	// i = 1
	ldr 	i_reg, 		[fp, i_s]		// load i from the stack
	mov 	i_reg, 		1			// set i to 1
	str 	i_reg, 		[fp, i_s]		// store new i on the stack

	b	out_loop_test				// proceed to outer loop test

out_loop:

	// temp = arr[i]
	ldr 	i_reg, 		[fp, i_s]		// load i from the stack
	ldr	array_element,	[base, i_reg, SXTW 2]	// load arr[i] from the stack
	str 	array_element, 	[fp, temp_s]		// set temp = arr[i], and store on the stack	

	b	in_loop_setup				// proceed to inner loop setup

out_loop_cleanup:

	// arr[j] = temp
	ldr 	temp_reg, 	[fp, temp_s]		// load temp from the stack	
	ldr 	j_reg, 		[fp, j_s]		// load j from the stack			 
	str 	temp_reg, 	[base, j_reg, SXTW 2] 	// set arr[j] = temp

	// i = i + 1
	ldr 	i_reg, 		[fp, i_s]		// load i from the stack
	add 	i_reg, 		i_reg, 1		// increment i by 1
	str 	i_reg, 		[fp, i_s]		// store new i on the stack
		
	b	out_loop_test				// proceed to out loop test

out_loop_test:

	// if i < 30, repeat outer loop
	ldr 	i_reg, 		[fp, i_s]		// load i from the stack
	cmp 	i_reg, 		30			// compare to 30
	b.lt 	out_loop				// if less than, repeat the loop
	b	final_print				// else proceed to final print

//----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// Inner Loop
	
in_loop_setup:

	// j = i
	ldr 	j_reg, 		[fp, j_s]		// load j from the stack
	ldr 	i_reg, 		[fp, i_s]		// load i from the stack
	mov 	j_reg, 		i_reg			// set j = i
	str 	j_reg, 		[fp, j_s]		// store new j to the stack

	b	in_loop_test1				// proceed to in_loop_test1

in_loop:

	// arr[j] = arr[j-1]
	ldr 	j_reg, 		[fp, j_s]		// load j from the stack
	sub	j_reg,		j_reg,		1	// get value of j-1
	ldr 	array_element,	[base, j_reg, SXTW 2]	// load arr[j-1] from stack, store in array element
	ldr 	j_reg, 		[fp, j_s]		// load j from the stack
	str 	array_element, 	[base, j_reg, SXTW 2] 	// set arr[j] = arr[j-1]

	b	in_loop_cleanup				// proceed to in_loop_cleanup

in_loop_cleanup:

	// j = j - 1 
	ldr 	j_reg, 		[fp, j_s]		// load j from the stack
	sub 	j_reg, 		j_reg, 1		// de-increment j by 1
	str 	j_reg,		[fp, j_s]		// store new j on the stack
			
	b	in_loop_test1				// proceed to in loop test1

in_loop_test1:

	// if j > 0, proceed to inner loop test 2
	ldr 	j_reg, 		[fp, j_s]		// load j from the stack
	cmp 	j_reg, 		0			// compare j to 0
	b.gt 	in_loop_test2				// if greater than, proceed to in loop test 2
	b	out_loop_cleanup			// else proceed to out loop cleanup

in_loop_test2:

	// if temp > arr[j-1], repeat the inner loop										// now largest to smallest
	ldr 	temp_reg, 	[fp, temp_s]		// load temp from the stack
	ldr 	j_reg, 		[fp, j_s]		// load j from the stack
	sub	j_reg,		j_reg,		1	// get value of j-1
	ldr 	array_element,	[base, j_reg, SXTW 2]	// load arr[j-1] from stack
	cmp	temp_reg,	array_element		// compare temp to arr[j-1]
	b.gt	in_loop					// if less than, proceed to inner loop
	b	out_loop_cleanup			// else proceed to outer loop cleanup					

//----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// printing of final sorted array to the user

final_print:

	ldr	x0, 		=greet2			// load greeting 2 to x0
	bl	printf					// print greeting 2 to user

	mov 	i_reg, 		0			// set the index register to 0
	str 	i_reg, 		[fp, i_s]		// store the index value at i
	b loop_test3					// proceed to loop_test 2

loop3:
	ldr 	x0, 		=printInfo		// load fmt1 to x0
	ldr 	w1, 		[fp, i_s]		// load i to w1
	ldr 	w2, 		[base, i_reg, SXTW 2]	// load arr[i] to w2

	bl 	printf					// print i and arr[i] to user

	ldr 	i_reg, 		[fp, i_s]		// load i from the stack
	add 	i_reg, 		i_reg, 1		// increment i by 1
	str 	i_reg, 		[fp, i_s]		// store new i on the stack
	
loop_test3:
	ldr 	i_reg, 		[fp, i_s]		// load i from the stack
	cmp 	i_reg, 		30			// compare to 30
	b.lt 	loop3					// if less than, repeat the loop


end:
	ldp fp, lr, [sp], dealloc			// Restore FP and LR
	ret						// Return to caller (OS)

