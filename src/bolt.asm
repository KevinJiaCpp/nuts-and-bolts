; arg 1 (rdi) : bolt addr
; no return value
global PrintBolt

; arg 1 (rdi) : bolt addr
; returns whether the bolt is solved
; expects non-zero capactiy
global BoltSolved

; arg 1 (rdi) : bolt addr
; returns whether the bolt is empty
global BoltEmpty

; arg 1 (rdi) : bolt addr
; returns the top nut of the bolt
global BoltTop

; arg 1 (rdi) : from bolt addr
; arg 2 (rsi) : to bolt addr
; returns the number of movable nuts
global Movable

; arg 1 (rdi) : from bolt addr
; arg 2 (rsi) : to bolt addr
; arg 3 (rdx) : number of nuts to move
; no return value
; no self moving
global MoveNuts

; arg 1 (rdi) : bolt addr
; returns size in byte
global BoltSize

extern tc_ResetFont
extern tc_SetFontFGC
extern tc_SetFontBGC

extern putchar

; struct Bolt
; 	int capacity		(4 byte)
; 	int nut_count		(4 byte)
; 	int[] nut_list

section .text
; ----------------------------------------------------------------
PrintBolt:
	push 	rbp
	mov 	rbp, rsp

	push  	r12
	push 	r13
	push 	r14
	push 	rbx

	mov 	r12d, [rdi]
	mov 	r13d, [rdi + 4]
	lea 	rbx, [rdi + 8]

	mov 	dil, '-'
	call 	putchar
	mov 	dil, '|'
	call 	putchar

	mov 	r14, r13
.PrintNuts:
	cmp  	r14, 0
	jle 	.EndNuts
	xor 	rdi, rdi
	xor 	rsi, rsi
	xor 	rdx, rdx
	mov 	dil, [rbx]
	mov 	sil, [rbx + 1]
	mov 	dl, [rbx + 2]
	call 	tc_SetFontFGC

	mov 	dil, '('
	call 	putchar

	add 	rbx, 4

	dec 	r14
	jmp		.PrintNuts
	
.EndNuts:
	mov 	rdi, 255
	mov 	rsi, 255
	mov 	rdx, 255
	call 	tc_SetFontFGC

	mov  	r14, r12
	sub 	r14, r13
.PrintDash:
	cmp 	r14, 0
	jle 	.EndDash
	mov 	dil, '-'
	call 	putchar
	dec 	r14
	jmp 	.PrintDash
.EndDash:
	pop 	rbx
	pop 	r14
	pop 	r13
	pop 	r12

	mov 	rsp, rbp
	pop 	rbp

	ret

; ----------------------------------------------------------------
BoltSolved:
	mov 	ecx, [rdi]
	cmp 	ecx, [rdi + 4]
	jne 	.unsolved

	add 	rdi, 8
	mov 	rax, [rdi + 8]

	cld
	repe scasd
	jne 	.unsolved
	mov 	rax, 1
	ret

.unsolved:
	xor 	rax, rax
	ret

; ----------------------------------------------------------------
BoltEmpty:
	xor 	rax, rax
	mov 	ecx, [rdi + 4]
	cmp 	ecx, 0
	jne 	.return
	mov 	rax, 1

.return:
	ret

; ----------------------------------------------------------------
BoltTop:
	mov 	ecx, [rdi + 4]
	dec 	ecx

	mov 	eax, [rdi + 8 + 4 * rcx]
	ret

; ----------------------------------------------------------------
Movable:
	push 	rbp
	mov 	rbp, rsp
	push 	r12
	push 	r13

	mov 	r12, rdi 		; src bolt addr
	mov 	r13, rsi		; dest bolt addr

	; test whether the destination bolt is empty
	mov 	rdi, r13
	call 	BoltEmpty
	test 	rax, rax
	jz 		.dest_color		; use destination top as moving color if not empty

	mov 	rdi, r12
	call 	BoltEmpty
	test 	rax, rax
	jne 	.return

	; use source top as moving color
	mov 	rdi, r12
	call 	BoltTop
	jmp 	.count_nuts

.dest_color:
	mov 	rdi, r13
	call 	BoltTop

.count_nuts:
	mov 	esi, eax		; save the moving color in esi
	xor 	rax, rax
	mov 	ecx, [r12 + 4]	; source bolt count
	mov 	edx, [r13 + 4]	; destination bolt count
	mov 	edi, [r13]		; destination capacity

.countloop:
	; out of nuts check
	cmp 	ecx, 0
	jle 	.endloop
	; out of space check
	cmp 	edx, edi
	jge 	.endloop

	; color matching
	cmp 	esi, [r12 + 8 + 4 * rcx - 4]
	jne 	.endloop

	dec 	ecx
	inc 	edx
	jmp 	.countloop

.endloop:
	mov 	eax, [r12 + 4]
	sub 	eax, ecx

.return:
	pop 	r13
	pop 	r12
	mov 	rsp, rbp
	pop 	rbp

	ret

; ----------------------------------------------------------------
MoveNuts:
	mov 	rax, rdx		; load number of nuts to move
	mov 	ecx, [rdi + 4]	; load source nut count
	mov 	edx, [rsi + 4]	; load destination nut count
	
	test	rax, rax
.moveloop:
	jz 		.endloop

	mov 	r8d, [rdi + 8 + 4 * rcx - 4]	; load nut from src bolt
	mov 	[rsi + 8 + 4 * rdx], r8d		; store nut in dest bolt

	dec 	rcx				; decrement src nut count
	inc 	rdx				; increment dest nut count
	dec 	rax				; sets ZF when rax equals zero
	jmp 	.moveloop

.endloop:
	; update nut counts
	mov 	[rdi + 4], ecx
	mov 	[rsi + 4], edx

	ret

; ----------------------------------------------------------------
BoltSize:
	mov 	eax, [rdi]
	shl 	rax, 2
	add 	rax, 8
	ret