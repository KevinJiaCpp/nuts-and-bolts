global tc_ClearTerm
global tc_ResetFont
global tc_MoveCursorAbs
global tc_MoveCursorCol
global tc_HideCursor
global tc_ShowCursor
global tc_SetFontFGC
global tc_SetFontBGC

global tc_RawMode
global tc_ResetMode

extern printf
extern tcgetattr, tcsetattr

section .data
	STDIN 		equ 		0

	C_LFLAG 	equ 		12
	F_ECHO		equ 		0x8
	F_ICANON 	equ 		0x2
	TCSAFLUSH 	equ 		2
section .bss
	termios_orig 	resb 		60
	termios_raw 	resb 		60
section .text
; ----------------------------------------------------------------
tc_RawMode:
	push 	rbp

	mov 	rdi, STDIN
	mov 	rsi, termios_orig
	call 	tcgetattr

	mov 	rsi, termios_orig
	mov 	rdi, termios_raw
	mov 	rcx, 60
	rep movsb

	mov 	eax,  [termios_raw + C_LFLAG]
	and 	eax, ~(F_ECHO | F_ICANON)
	mov 	[termios_raw + C_LFLAG], eax

	mov 	rdi, STDIN
	mov 	rsi, TCSAFLUSH
	mov 	rdx, termios_raw
	call 	tcsetattr
	
	pop 	rbp
	ret

tc_ResetMode:
	push 	rbp

	mov 	rdi, STDIN
	mov 	rsi, TCSAFLUSH
	mov 	rdx, termios_orig
	call 	tcsetattr

	pop 	rbp
	ret

; ----------------------------------------------------------------
tc_ClearTerm:
section .data
	.msg	db 		27, "[2J", 0
section .text
	push 	rbp

	xor 	rax, rax
	mov 	rdi, .msg
	call 	printf

	pop 	rbp
	ret

; ----------------------------------------------------------------
tc_ResetFont:
section .data
	.msg 	db 		27, "[0m", 0
section .text
	push  	rbp

	xor 	rax, rax
	mov 	rdi, .msg
	call 	printf

	pop 	rbp
	ret

; ----------------------------------------------------------------
tc_MoveCursorAbs:
section .data
	.fmt 	db 		27, "[%d;%dH", 0
section .text
	push 	rbp

	xor 	rax, rax
	mov 	rdx, rsi
	mov 	rsi, rdi
	mov 	rdi, .fmt
	call 	printf
	
	pop 	rbp
	ret

; ----------------------------------------------------------------
tc_MoveCursorCol:
section .data
	.fmt 	db 		27, "[%dG", 0
section .text
	push 	rbp

	xor 	rax, rax
	mov 	rsi, rdi
	mov 	rdi, .fmt
	call 	printf
	
	pop 	rbp
	ret

; ----------------------------------------------------------------
tc_HideCursor:
section .data
	.fmt 	db 		27, "[?25l", 0
section .text
	push 	rbp

	xor 	rax, rax
	mov 	rdi, .fmt
	call 	printf

	pop 	rbp
	ret

; ----------------------------------------------------------------
tc_ShowCursor:
section .data
	.fmt 	db 		27, "[?25h", 0
section .text
	push 	rbp

	xor 	rax, rax
	mov 	rdi, .fmt
	call 	printf

	pop 	rbp
	ret

; ----------------------------------------------------------------
tc_SetFontFGC:
section .data
	.fmt 	db 		27, "[38;2;%d;%d;%dm", 0
section .text
	push 	rbp

	xor 	rax, rax
	mov 	rcx, rdx
	mov 	rdx, rsi
	mov 	rsi, rdi
	mov 	rdi, .fmt
	call 	printf

	pop 	rbp
	ret

; ----------------------------------------------------------------
tc_SetFontBGC:
section .data
	.fmt 	db 		27, "[48;2;%d;%d;%dm", 0
section .text
	push 	rbp

	xor 	rax, rax
	mov 	rcx, rdx
	mov 	rdx, rsi
	mov 	rsi, rdi
	mov 	rdi, .fmt
	call 	printf

	pop 	rbp
	ret
