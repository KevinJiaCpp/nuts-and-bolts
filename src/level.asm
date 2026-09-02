; arg 1 (rdi): level addr
; arg 2 (rsi): bolt index
; returns the addr of the level at
; the specified index
global GetBoltAddr

; arg 1 (rdi): level addr
; returns whether the level
; is considered cleared
global LevelCleared

; arg 1 (rdi): level addr
; returns the size of the level in byte
global LevelSize

extern PrintBolt
extern BoltEmpty
extern BoltSolved
extern BoltSize

extern printf

; struct Level
; 	int bolt_count 		(4 byte)
; 	Bolt[] bolt_list

section .text
; ----------------------------------------------------------------
LevelSize:
	push 	rbp
	mov 	rbp, rsp

	push 	rbx
	sub 	rsp, 8

	mov 	rbx, rdi
	mov 	esi, [rdi]
	call 	GetBoltAddr
	sub 	rax, rbx
	
	add 	rsp, 8
	pop 	rbx

	mov 	rsp, rbp
	pop 	rbp
	ret

; ----------------------------------------------------------------
LevelCleared:
	push 	rbp
	mov 	rbp, rsp
	push 	rbx			; current bolt addr
	push 	r12			; return val
	push 	r13			; bolt count
	sub 	rsp, 8

	mov 	rbx, rdi
	add 	rbx, 4		; bolt list
	mov 	r13d, [rdi]	; bolt count
	mov 	r12, 0		; return val

.checkloop:
	test 	r13, r13
	jz 		.cleared

	mov 	rdi, rbx
	call 	BoltEmpty
	test 	rax, rax
	jnz 	.empty

	mov 	rdi, rbx
	call 	BoltSolved
	test 	rax, rax
	jz 		.return		; r12 default to 0

.empty:
	mov 	rdi, rbx
	call 	BoltSize
	add 	rbx, rax

	dec 	r13
	jmp 	.checkloop

.cleared:
	mov 	r12, 1

.return:
	mov 	rax, r12

	add 	rsp, 8
	pop 	r13
	pop 	r12
	pop 	rbx
	mov 	rsp, rbp
	pop 	rbp

	ret

; ----------------------------------------------------------------
GetBoltAddr:
	push 	rbp
	mov 	rbp, rsp
	push	rbx
	push 	r12

	add 	rdi, 4 		; calculate bolt list addr
	mov 	rbx, rdi	; store bolt list addr in rbx
	mov 	r12, rsi

.loop:
	cmp 	r12, 0
	jle 	.end

	mov 	rdi, rbx
	call 	BoltSize
	add 	rbx, rax

	dec 	r12
	jmp 	.loop

.end:
	mov 	rax, rbx

	pop 	r12
	pop 	rbx
	mov 	rsp, rbp
	pop 	rbp

	ret