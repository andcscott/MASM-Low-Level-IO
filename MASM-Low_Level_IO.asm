TITLE Project 6 - String Primitives and Macros     (MASM_Low-Level-IO.asm)

; Author: Andrew Scott
; Last Modified: 2022-03-13
; Course number/section: CS271 Section 400
; Project Number: 6          Due Date: 2022-03-13
; Description: Program asks for 10 signed integers from the user as strings. 
;              The strings are converted from ASCII to SDWORDs and stored 
;              in an array. Then, their sum, and the truncated average are 
;              calculated. After the calculations all numbers entered by 
;              the user as well as the results are converted back to their 
;              ASCII representations and printed as strings.

INCLUDE Irvine32.inc

; name: mGetString
; Gets a value from the user
; preconditions: global variables are passed by reference
; receives: global variables userPrompt, userInput, userInputLen
; returns: stores user input in userInput
mGetString MACRO prompt:REQ, inString:REQ, stringLen:REQ
  push	EAX
  push	ECX
  push	EDX
  push	EDI
  mov	EDX, prompt
  call	WriteString
  mov	EDX, inString
  mov	ECX, MAXSIZE
  call	ReadString
  mov	EDI, stringLen
  mov	[EDI], EAX
  pop	EDI
  pop	EDX
  pop	ECX
  pop	EAX
ENDM

; name: mDisplayString
; Prints a string to the output
; preconditions: strings must be passed by reference
; receives: outString - offset of string to be written to output
; returns: prints outString
mDisplayString MACRO outString:REQ
  push	EDX
  mov	EDX, outString
  call	WriteString
  pop	EDX
ENDM

MAXSIZE = 500

.data

projectTitle	BYTE "Project 6 - String Primitives and Macros, by Andrew Scott",13,10,0
description1	BYTE "You will be prompted to enter 10 signed decimal integers. Each integer must fit into a 32-bit register.",13,10,0
description2	BYTE "After you've entered 10 valid integers this program will display the integers, their sum, and their truncated average",13,10,13,10,0
userPrompt		BYTE ". Please enter a signed number: ",0
invalidInput	BYTE "ERROR: You did not enter a signed number or your number was too big. Please Try again.",13,10,0
listLabel		BYTE 13,10,"You entered the following numbers:",13,10,0
sumLabel		BYTE 13,10,"The sum of these numbers is: ",0
avgLabel		BYTE 13,10,"The truncated average of these numbers is: ",0
retryPrompt		BYTE "ERROR: Input was not a signed number or was too big. Please try again.",13,10,13,10,0
space			BYTE " ",0
ecOption		BYTE "**EC1: Number each line of user input and display a running subtotal of the valid numbers.",13,10,13,10,0

userInput		BYTE MAXSIZE DUP(?)
userOutput		BYTE MAXSIZE DUP(?)
userInputLen	DWORD 0
userInputNum	SDWORD 0
inputIsValid	DWORD 0
userArray		SDWORD 10 DUP(0)
userArrayLen	DWORD LENGTHOF userArray
userArraySum	SDWORD 0
userArrayAvg	SDWORD 0
inputCount		DWORD 1

.code
main PROC
  ; introduce the program
  push	OFFSET projectTitle
  push	OFFSET ecOption
  push	OFFSET description1
  push	OFFSET description2
  call	introduction	

  ; prepare to get values from user
  mov	ECX, userArrayLen
  mov	EDI, OFFSET userArray
  ; get signed integers from user and store them
_fillArray:
  push	OFFSET space					
  push	OFFSET userOutput
  push	OFFSET inputCount
  push	OFFSET retryPrompt
  push	OFFSET userPrompt					
  push	OFFSET userInput
  push	OFFSET userInputLen
  push	OFFSET userInputNum
  call	ReadVal							; get user input
  inc	inputCount
  mov	EAX, userInputNum
  mov	[EDI], EAX						; store user input
  mov	EAX, 0
  add	EDI, 4
  loop	_fillArray

  ; calculate the sum
  mov	ECX, userArrayLen					; prepare registers
  mov	ESI, OFFSET userArray
  mov	userArraySum, 0
_calcSum:								
  mov	EAX, userArraySum					; begin addition
  mov	EBX, [ESI]
  add	EAX, EBX
  mov	userArraySum, EAX
  add	ESI, 4
  mov	EAX, 0
  loop	_calcSum
  ; find average
  mov	EAX, userArraySum
  cdq
  idiv	userArrayLen						
  mov	userArrayAvg, EAX

  ; display all nums entered by user
  mov	ECX, userArrayLen						; prepare registers and display label
  mov	EDI, OFFSET userArray
  mov	EDX, OFFSET listLabel
  mDisplayString EDX
_displayNums:									; begin loop to print nums in userArray
  push	OFFSET space
  push	OFFSET userOutput
  push	EDI
  call	WriteVal
  add	EDI, 4
  loop	_displayNums
  call	CrLf
  
  ; display sum
  push	OFFSET sumLabel
  push	OFFSET userOutput
  push	OFFSET userArraySum
  call	WriteVal
  call	CrLf

  ; display truncated average
  push	OFFSET avgLabel
  push	OFFSET userOutput
  push	OFFSET userArrayAvg
  call	WriteVal
  call	CrLf

	Invoke ExitProcess,0	; exit to operating system
main ENDP

; name: introduction
; Introduces the program
; preconditions: global variables projectTitle, description1, and description2 are strings
; postconditions: none
; receives: global variables projectTitle, description1, and description2 from the stack
; returns: prints the program intro
introduction PROC
  push	EBP
  mov	EBP, ESP
  mDisplayString [EBP+20]
  mDisplayString [EBP+16]
  mDisplayString [EBP+12]
  mDisplayString [EBP+8]
  pop	EBP
  ret	16
introduction ENDP

; name: ReadVal
; Prompts the user to input a string of digits, validates the input, converts it
; to a signed int, then stores it. Uses local variable isNegative as custom
; sign flag and convertedInt as temporary storage for the integer after conversion.
; preconditions: retryPrompt, userPrompt, userInput are strings and global variables
;                userInputNum is a DWORD global variable
; postconditions: none
; receives: global variables retryPrompt, userPrompt, userInput, userInputNum passed on stack by reference
; returns: signed integer stored in userInputNum
ReadVal PROC
  ;push	EBP
  ;mov	EBP, ESP
  local	isNegative:DWORD, convertedInt:SDWORD
  push	EAX						; preserve registers
  push	EBX
  push	ECX
  push	EDX
  push	ESI
_tryAgain:
  ; prepend line number to prompt
  mov	EDX, [EBP+36]
  mov	EBX, [EBP+32]
  mov	EAX, [EBP+28]
  push	EDX
  push	EBX
  push	EAX
  call	WriteVal
  ; get input from user
  mGetString [EBP+20], [EBP+16], [EBP+12]		
  mov	ESI, [EBP+16]							; prepare isNegative, ESI and ECX for _isNumeric loop
  mov	ECX, [EBP+12]
  mov	ECX, [ECX]
  mov	isNegative, 0
  cld
_isNumeric:						
  ; begin loop to check sign and validate input
  lodsb
  cmp	AL, 43
  je	_positive				; check sign
  cmp	AL, 45
  je	_negative
  cmp	AL, 48					; check input is numeric
  jl	_invalidNum
  cmp	AL, 57
  jg	_invalidNum
  jmp	_validNum
_positive:
  mov	isNegative, 0			; make sure isNegative is clear
  jmp	_validNum
_negative:
  mov	isNegative, 1			; set isNegative
_validNum:
  loop	_isNumeric
  jmp	_continue				; continue to conversion after confirming input is numeric
_invalidNum:
  mDisplayString [EBP+24]		; display error if input is invalid and jump to re-prompt
  jmp	_tryAgain

_continue:						
  ; prepare registers, local, and counter (ECX) for conversion loop
  mov	convertedInt, 0
  mov	ESI, [EBP+16]
  mov	EAX, 0
  mov	EBX, 10
  mov	EDX, 0
  mov	ECX, [EBP+12]
  mov	ECX, [ECX]
  cld
_convert:						
  ; begin convert loop
  lodsb
  cmp	AL, 43					; compare first character to +/- and skip if present
  je	_skipSign				
  cmp	AL, 45
  je	_skipSign
  sub	AL, 48					; begin conversion to SDWORD
  push	EAX
  mov	EAX, convertedInt
  imul	EBX
  mov	convertedInt, EAX
  pop	EAX
  jo	_invalidNum				; check for overflow before proceeding, jump to error and re-prompt if OV flag = 1
  cmp	isNegative, 1			; negate if isNegative is set
  je	_convertToNeg
_add:
  add	convertedInt, EAX		; add current value to convertedInt
  jo	_invalidNum
  mov	EAX, 0					; reset EAX to 0
_skipSign:
  loop	_convert
  jmp	_storeValue				; jump to saving value to global variable after convert loop complete
_convertToNeg:
  neg	EAX
  jmp	_add

_storeValue:					; store value in variable userInputNum by reference
  mov	EDX, [EBP+8]
  mov	EAX, convertedInt
  mov	[EDX], EAX
  pop	ESI						; restore registers and return
  pop	EDX
  pop	ECX
  pop	EBX
  pop	EAX
  ret	32
ReadVal ENDP

; name: WriteVal
; Converts SDWORD input to ASCII and prints the data with it's corresponding label
; preconditions: global variables have been declared for the data label and SDWORD.
; Uses local variables remainder and quotient to hold results of division.
; postconditions: none
; receives: label and data global variables passed on stack
; returns: prints the data and label to the output
WriteVal PROC
  local	remainder:DWORD, quotient:DWORD
  push	EAX						; preserve registers
  push	EBX
  push	ECX
  push	EDX
  push	ESI
  push	EDI
  ; prepare local vars and registers for conversion and array filling
  mov	remainder, 0
  mov	quotient, 0
  mov	EBX, 10
  mov	ECX, 0
  mov	ESI, [EBP+8]
  mov	EAX, [ESI]
  mov	EDI, [EBP+12]
  cld
  cmp	EAX, 0
  jl	_negative				; check for negative input
_convert:
; begin conversion from SDWORD to string
  cdq
  idiv	EBX
  mov	quotient, EAX
  mov	remainder, EDX
  add	remainder, 48
  mov	EAX, remainder
  push	EAX						; save value to add later
  inc	ECX						; increment counter for adding to byte array later
  mov	EAX, quotient
  cmp	EAX, 0
  jne	_convert				; keep looping until quotient = 0
  jmp	_fillByteArray
_negative:
  mov	AL, 45					; add '-' (ASCII 45) as first byte if negative
  stosb
  mov	EAX, [ESI]
  neg	EAX						; reverse sign before continuing to _convert
  jmp _convert

_fillByteArray:
; begin filling array
  pop	EAX						; pop values pushed during conversion
  stosb							; store popped values in array
  loop	_fillByteArray
  mov	EAX, 0						; terminate string
  mov	[EDI], EAX
  ; invoke mDisplayString to print byte array
  mDisplayString [EBP+16]
  mDisplayString [EBP+12]
  ; restore registers and return
  pop	EDI
  pop	ESI						
  pop	EDX
  pop	ECX
  pop	EBX
  pop	EAX
  ret	12
WriteVal ENDP

END main
