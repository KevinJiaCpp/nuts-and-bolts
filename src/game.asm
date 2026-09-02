global Run

; arg 1 (rdi): file name
; returns the level addr
; NULL is returned upon error
global LoadLevel

extern PrintBolt

extern GetBoltAddr

%include "src/array.inc"
%include "src/term.inc"

extern malloc, free
extern fopen, fclose
extern getchar, putchar, fgetc
extern printf
extern tolower

section .data
    NULL        equ     0
    EOF         equ     -1
    NL          equ     10
    STDIN       equ     0

    level_path  db      "level.txt", 0

    ; ui specs
    BOLT_SPACE  equ     48
    LEVEL_POSR  equ     7

    ; ui text resources
    ui_title 	db 		" _   _       _            _              _   ____        _ _       ", 10
			    db	 	"| \ | |_   _| |_ ___     / \   _ __   __| | | __ )  ___ | | |_ ___ ", 10
			    db		"|  \| | | | | __/ __|   / _ \ | '_ \ / _` | |  _ \ / _ \| | __/ __|", 10
			    db		"| |\  | |_| | |_\__ \  / ___ \| | | | (_| | | |_) | (_) | | |_\__ \", 10
			    db		"|_| \_|\__,_|\__|___/ /_/   \_\_| |_|\__,_| |____/ \___/|_|\__|___/", 10, 0
    ui_sep      db      "═══════════════════════════════════════════════════════════════", 10, 0

section .bss
section .text
; ----------------------------------------------------------------
Run:
    push    rbx

    ; load level
    ; rbx       holds level addr
    mov     rdi, level_path
    call    LoadLevel
    mov     rbx, rax

    call    tc_ClearTerm
    mov     rdi, 1
    mov     rsi, 1
    call    tc_MoveCursorAbs
    call    tc_HideCursor
    call    tc_RawMode

    ; display decoration characters
    xor     rax, rax
    mov     rdi, ui_title
    call    printf

    xor     rax, rax
    mov     rdi, ui_sep
    call    printf

    mov     rdi, [rbx]
    add     rdi, LEVEL_POSR
    mov     rsi, 1
    call    tc_MoveCursorAbs
    xor     rax, rax
    mov     rdi, ui_sep
    call    printf

.mainloop:
    ; render
    mov     rdi, LEVEL_POSR
    mov     rsi, 1
    call    tc_MoveCursorAbs
    mov     rdi, rbx
    mov     rsi, -1
    mov     rdx, -1
    call    RenderLevel

    ; handle input
    call    getchar
    cmp     al, 'q'
    je      .break

    jmp     .mainloop

.break:
    call    tc_ResetMode
    call    tc_ShowCursor

    ; render test
    ; mov       rdi, LEVEL_POSR
    ; mov       rsi, 1
    ; call      tc_MoveCursorAbs
    ; mov       rdi, rbx
    ; mov       rsi, 0
    ; mov       rdx, -1
    ; call      RenderLevel

    ; free level
    mov     rdi, rbx
    call    free

    pop     rbx
    ret

; ----------------------------------------------------------------
; arg 1 (rdi): level addr
; arg 2 (rsi): left index
; arg 3 (rdx): right index
RenderLevel:
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15

    ; rbx   level addr
    ; r12d   left index
    ; r13d   right index
    ; r14d  bolt num
    ; r15d  index
    mov     rbx, rdi
    mov     r12d, esi
    mov     r13d, edx
    mov     r14d, [rbx]
    xor     r15d, r15d

.printloop:
    cmp     r14d, 0
    jle     .break

    cmp     r15d, r12d
    je     .left
    ; no left indicator
    mov     dil, ' '
    call    putchar
    jmp     .bolt
    .left:
    ; print left indicator
    mov     dil, '>'
    call    putchar

    .bolt:
    mov     dil, ' '
    call    putchar
    ; print bolt
    mov     rdi, rbx
    mov     esi, r15d
    call    GetBoltAddr

    mov     rdi, rax
    call    PrintBolt

    mov     rdi, BOLT_SPACE + 3
    call    tc_MoveCursorCol

    cmp     r15d, r13d
    jne      .continue
    ; print right indicator
    mov     dil, ' '
    call    putchar
    mov     dil, '<'
    call    putchar

    .continue:
    mov     dil, NL
    call    putchar
    dec     r14d
    inc     r15d
    jmp     .printloop
    
.break:
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

; ----------------------------------------------------------------
; support the follows color:
; R     red
; G     green
; B     blue
; O     orange
; P     purple
; C     cyan
; W     white
; transfers ownership
LoadLevel:
section .data
    .mode       db          "r", 0

    .C_EMPTY     db          0, 0, 0, 0
    .C_RED       db          255, 0, 0, 0
    .C_GREEN     db          0, 255, 0, 0
    .C_BLUE      db          0, 0, 255, 0
    .C_ORANGE    db          255, 255, 0 ,0.
    .C_PURPLE    db          255, 0, 255, 0
    .C_CYAN      db          0, 255, 255, 0
    .C_WHITE     db          255, 255, 255, 0

section .text
    push    rbp
    push    rbx
    push    r12
    push    r13
    sub     rsp, 24
    ; stack layout
    ; rsp       dynamic buffer (16 byte)
    ; rsp + 16  item buffer (8 byte)

    ; var rbx: holds the file descriptor
    mov     rsi, .mode
    call    fopen
    cmp     rax, NULL
    je      .return
    mov     rbx, rax

    mov     rdi, rsp
    call    arr_Init

    ; set initial bolt count
    mov     dword [rsp + 16], 0
    mov     rdi, rsp
    lea     rsi, [rsp + 16]
    mov     rdx, 4
    call    arr_Append

    ; var r12: holds the offset into the buffer
    ; of the current bolt. -1 if no bolt exist.
    ; var r13: holds the address to the selected color
    mov     r12, -1
.read:
    mov     rdi, rbx
    call    fgetc

    cmp     al, EOF
    je      .break
    cmp     al, NL
    jne      .color
    ; release the current bolt
    mov     r12, -1
    jmp     .read

.color:
    xor     rdi, rdi
    mov     dil, al
    call    tolower

    cmp     al, '-'
    je      .empty
    cmp     al, 'r'
    je      .red
    cmp     al, 'g'
    je      .green
    cmp     al, 'b'
    je      .blue
    cmp     al, 'o'
    je      .orange
    cmp     al, 'p'
    je      .purple
    cmp     al, 'c'
    je      .cyan
    cmp     al, 'w'
    je      .white
    jmp     .read
    .red:
        mov     r13, .C_RED
        jmp     .addnut
    .green:
        mov     r13, .C_GREEN
        jmp     .addnut
    .blue:
        mov     r13, .C_BLUE
        jmp     .addnut
    .orange:
        mov     r13, .C_ORANGE
        jmp     .addnut
    .purple:
        mov     r13, .C_PURPLE
        jmp     .addnut
    .cyan:
        mov     r13, .C_CYAN
        jmp     .addnut
    .white:
        mov     r13, .C_WHITE
        jmp     .addnut
    .empty:
        mov     r13, .C_EMPTY
        jmp     .addnut

.addnut:
    cmp     r12, 0
    jge     .hasbolt
    ; --- create a new bolt ---
    ; register bolt to r12
    mov     rdi, rsp
    call    arr_Len
    mov     r12, rax

    mov     qword [rsp + 16], 0
    mov     rdi, rsp
    lea     rsi, [rsp + 16]
    mov     rdx, 8
    call    arr_Append

    ; increase bolt count
    mov     rdi, rsp
    call    arr_Data
    inc     dword [rax]

.hasbolt:
    ; append the nut
    mov     rdi, rsp
    mov     rsi, r13
    mov     rdx, 4
    call    arr_Append
    ; adjust bolt count
    mov     rdi, rsp
    call    arr_Data
    inc     dword [rax + r12]           ; increase bolt length

    ; if color is C_EMPTY
    cmp     r13, .C_EMPTY
    je      .skip_nut
    inc     dword [rax + r12 + 4]       ; increase nut count
    .skip_nut:

    jmp     .read

.break:
    mov     rdi, rbx
    call    fclose
    ; write the return value
    mov     rdi, rsp
    call    arr_Data

.return:
    add     rsp, 24
    pop     r13
    pop     r12
    pop     rbx
    pop     rbp
    ret