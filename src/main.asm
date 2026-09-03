global main

extern Run
extern LoadLevel
extern printf

section .data
	msg_no_file     db 		"file name missing", 10, 0
	msg_bad_file    db      "failed to open the file", 10, 0
section .bss
section .text
main:
	push 	rbp

    ; verify argument count
	cmp 	rdi, 1
	jle 	.no_file

    ; attempt to load level
	mov 	rdi, [rsi + 8]
	call 	LoadLevel
    cmp     rax, 0
    je      .bad_file

    mov     rdi, rax
	call 	Run
	jmp 	.exit

	.no_file:
	xor 	rax, rax
	mov 	rdi, msg_no_file
	call 	printf
    jmp     .exit

    .bad_file:
    xor     rax, rax
    mov     rdi, msg_bad_file
    call    printf

	.exit:
	mov 	rax, 0
	pop 	rbp
	ret
