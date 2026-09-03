; arg 1 (rdi): level addr
global Run

; arg 1 (rdi): file name
; returns the level addr
; NULL is returned upon error
global LoadLevel

extern PrintBolt
extern GetBoltAddr
extern Movable, MoveNuts

extern LevelCleared

%include "src/array.inc"
%include "src/term.inc"

extern malloc, free
extern fopen, fclose
extern getchar, putchar, fgetc
extern printf
extern tolower

section .data
    ; settings
    KEY_UP      equ     'd'
    KEY_DOWN    equ     'f'
    KEY_LEFT    equ     'j'
    KEY_RIGHT   equ     'k'

    NULL        equ     0
    EOF         equ     -1
    NL          equ     10

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
    ui_clear    db      27, "[92m", "LEVEL CLEARED!", 27, "[0m", 10, 0

section .bss
section .text
; ----------------------------------------------------------------
Run:
    push    rbx
    push    r12
    push    r13
    push    r14
    sub     rsp, 8

    mov     rbx, rdi

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

    ; rsp + 0   from indicator
    ; rsp + 4   to indicator
    ; r12       active indicator addr
    mov     r12, rsp
    mov     dword [rsp + 0], 0
    mov     dword [rsp + 4], -1
.mainloop:
    ; render level
    mov     rdi, LEVEL_POSR
    mov     rsi, 1
    call    tc_MoveCursorAbs
    mov     rdi, rbx
    mov     esi, [rsp + 0]
    mov     edx, [rsp + 4]
    call    RenderLevel

    mov     rdi, rbx
    call    LevelCleared
    test    rax, rax
    jz      .not_cleared
    ; render clear msg and quit
    mov     rdi, [rbx]
    add     rdi, LEVEL_POSR + 1
    mov     rsi, 1
    call    tc_MoveCursorAbs
    xor     rax, rax
    mov     rdi, ui_clear
    call    printf
    jmp     .break
    .not_cleared:

    ; handle input
    call    getchar
    cmp     al, 'q'
    jne     .handle_input
    ; exit main loop
    mov     rdi, [rbx]
    add     rdi, LEVEL_POSR + 1
    mov     rsi, 1
    call    tc_MoveCursorAbs
    jmp     .break

    .handle_input:
    cmp     al, KEY_UP
    je     .up
    cmp     al, KEY_DOWN
    je      .down
    cmp     al, KEY_LEFT
    je      .left
    cmp     al, KEY_RIGHT
    je      .right
    jmp     .no_event

    .up:
    dec     dword [r12]
    mov     eax, [r12]
    cmp     eax, 0
    jge     .no_event
    ; loop over to the lower bound
    add     eax, [rbx]
    mov     [r12], eax
    jmp     .no_event

    .down:
    inc     dword [r12]
    mov     eax, [r12]
    cmp     eax, [rbx]
    jl      .no_event
    ; loop over to the upper bound
    sub     eax, [rbx]
    mov     [r12], eax
    jmp     .no_event

    .left:
    cmp     r12, rsp
    je      .select

    .move:
    ; r13       from bolt addr
    ; r14       to bolt addr
    mov     rdi, rbx
    mov     esi, [rsp]
    call    GetBoltAddr
    mov     r13, rax

    mov     rdi, rbx
    mov     esi, [rsp + 4]
    call    GetBoltAddr
    mov     r14, rax

    ; ignore self moving
    cmp     r13, r14
    je      .right

    mov     rdi, r13
    mov     rsi, r14
    call    Movable

    mov     rdi, r13
    mov     rsi, r14
    mov     edx, eax
    call    MoveNuts

    jmp     .right

    .select:
    lea     r12, [rsp + 4]
    mov     eax, [rsp]
    mov     [rsp + 4], eax
    jmp     .no_event

    .right:
    mov     eax, [r12]
    mov     [rsp + 0], eax
    mov     [rsp + 4], -1
    mov     r12, rsp

    .no_event:
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

    add     rsp, 8
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

; ----------------------------------------------------------------
; arg 1 (rdi): level addr
; arg 2 (rsi): from index
; arg 3 (rdx): to index
RenderLevel:
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15

    ; rbx   level addr
    ; r12d   from index
    ; r13d   to index
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
    je      .right
    mov     dil, ' '
    call    putchar
    mov     dil, ' '
    call    putchar
    jmp     .continue

    .right:
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

    .C_EMPTY    db          0, 0, 0, 0
    .C_RED      db          255, 0, 0, 0
    .C_GREEN    db          0, 255, 0, 0
    .C_BLUE     db          0, 0, 255, 0
    .C_YELLOW   db          255, 255, 0 ,0.
    .C_MAGENTA  db          255, 0, 255, 0
    .C_CYAN     db          0, 255, 255, 0
    .C_WHITE    db          255, 255, 255, 0

    .C_ORANGE   db          255, 85, 0, 0
    .C_LIME     db          178, 255, 102, 0

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
    cmp     al, 'y'
    je      .yellow
    cmp     al, 'm'
    je      .magenta
    cmp     al, 'c'
    je      .cyan
    cmp     al, 'w'
    je      .white
    cmp     al, 'o'
    je      .orange
    cmp     al, 'l'
    je      .lime
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
    .yellow:
        mov     r13, .C_YELLOW
        jmp     .addnut
    .magenta:
        mov     r13, .C_MAGENTA
        jmp     .addnut
    .cyan:
        mov     r13, .C_CYAN
        jmp     .addnut
    .white:
        mov     r13, .C_WHITE
        jmp     .addnut
    .orange:
        mov     r13, .C_ORANGE
        jmp     .addnut
    .lime:
        mov     r13, .C_LIME
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