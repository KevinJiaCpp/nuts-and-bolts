global main

extern Run
extern tc_MoveCursorAbs

section .data
section .bss
section .text
main:
	push 	rbp

	call 	Run
	mov 	rax, 0

	pop 	rbp
	ret
