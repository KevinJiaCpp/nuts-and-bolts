; struct Array
;   int capacity    (4 byte)
;   int length      (4 byte)
;   ptr data_ptr    (8 byte)

; arg 1 (rdi): array addr
global arr_Init

; arg 1 (rdi): array addr
global arr_Free

; arg 1 (rdi): array addr
global arr_Len

; arg 1 (rdi): array addr
global arr_Data

; arg 1 (rdi): array addr
; arg 2 (rsi): data addr
; arg 3 (rdx): data size
global arr_Append

extern malloc, free

section .data
    INITIAL     equ         16
section .bss
section .text
; ----------------------------------------------------------------
arr_Init:
    push    rbp
    mov     rbp, rsp
    push    rbx
    sub     rsp, 8

    mov     rbx, rdi

    mov     rdi, INITIAL
    call    malloc

    ; exception
    cmp     rax, 0
    je      .bad

    ; setup instance
    mov     dword [rbx], 16
    mov     dword [rbx + 4], 0
    mov     [rbx + 8], rax
    jmp     .return

.bad:
    mov     dword [rbx], 0
    mov     dword [rbx + 4], 0
    mov     [rbx + 8], 0
.return:
    add     rsp, 8
    pop     rbx
    mov     rsp, rbp
    pop     rbp
    ret

; ----------------------------------------------------------------
arr_Free:
    push    rbx

    mov     rbx, rdi
    mov     rdi, [rbx + 8]
    call    free
    mov     [rbx + 8], 0

    pop     rbx
    ret

; ----------------------------------------------------------------
arr_Len:
    mov     eax, [rdi + 4]
    ret

; ----------------------------------------------------------------
arr_Data:
    mov     rax, [rdi + 8]
    ret

; ----------------------------------------------------------------
arr_Append:
    push    rbx
    push    r12         ; new capacity
    push    r13         ; new length
    push    r14         ; new data addr
    push    r15

    mov     rbx, rdi
    mov     r15, rsi
    mov     r12d, [rdi]
    mov     r13d, [rdi + 4]
    add     r13d, edx

    cmp     r12d, r13d
    jae     .append

.expand:
    shl     r12d, 1
    cmp     r12d, r13d
    jb      .expand

    mov     edi, r12d
    call    malloc

    ; allocation failed
    cmp     rax, 0
    je      .return
    mov     r14, rax

    mov     ecx, [rbx + 4]
    mov     rsi, [rbx + 8]
    mov     rdi, r14
    rep     movsb

    mov     rdi, [rbx + 8]
    call    free

    mov     [rbx], r12d
    mov     [rbx + 8], r14

.append:
    mov     rsi, r15
    mov     edx, [rbx + 4]
    mov     rdi, [rbx + 8]
    add     rdi, rdx

    ; calculate increment
    mov     ecx, r13d
    sub     ecx, [rbx + 4]
    rep     movsb

    ; write new length
    mov     [rbx + 4], r13d

.return:
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret