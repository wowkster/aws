%ifndef STRING_ASM
%define STRING_ASM

%include "macros.asm"
%include "print.asm"
%include "mem.asm"

bits 64
segment .text

; struct String {
;   char *ptr
;   size_t length
;   size_t capacity
; } (24)

STRING_OFFSET_PTR equ 0
STRING_OFFSET_LENGTH equ 8
STRING_OFFSET_CAPACITY equ 16

STRING_DEFAULT_CAPACITY equ 1024

;
; Allocates a new string
;   rdi [in] - Pointer to an (uninitialized) String struct as described above
;
string_new:
    push rax
    push rbx
    push rdi

    mov rbx, rdi

    mov qword [rdi + STRING_OFFSET_PTR], 0
    mov qword [rdi + STRING_OFFSET_LENGTH], 0
    mov qword [rdi + STRING_OFFSET_CAPACITY], STRING_DEFAULT_CAPACITY
    
    mov rdi, [rdi + STRING_OFFSET_CAPACITY]
    call mmap

    mov [rbx + STRING_OFFSET_PTR], rax  

    .finish:

    pop rdi
    pop rbx
    pop rax
    ret

;
; Deallocates a previously allocated string
;   rdi [in] - Pointer to an initialized String struct as described above
;
string_free:
    push rdi
    push rsi

    ; munmap(string.ptr, string.capacity)
    mov rsi, [rdi + STRING_OFFSET_CAPACITY]
    mov rdi, [rdi + STRING_OFFSET_PTR]
    call munmap

    pop rsi
    pop rdi
    ret

;
; Gets the length of a string
;   rdi [in] - Pointer to the string
;   rax [out] - Length of the string
;
string_len:
    mov rax, [rdi + STRING_OFFSET_LENGTH]
    ret

;
; Gets a value from the string
;   rdi [in] - Pointer to the string
;   rsi [in] - The offset into the string
;   al [out] - The char at the given index or -1 if the string is not that long
;
string_get:
    push rbx

    mov rbx, [rdi + STRING_OFFSET_LENGTH]
    cmp rbx, rsi
    jg .read_char

    mov al, -1
    jmp .finish

    .read_char:
        mov rbx, [rdi + STRING_OFFSET_PTR]
        mov al, [rbx + rsi]
    
    .finish:
        push rbx
        ret

;
; Gets the value at the end of the string
;   rdi [in] - Pointer to the string
;   al [out] - The byte at the end of the string or -1 if the string is empty
;
string_peek:
    push rbx
    push rcx

    mov rbx, [rdi + STRING_OFFSET_LENGTH]
    cmp rbx, 0
    jne .read_char

    mov al, -1
    jmp .finish

    .read_char:
        dec rbx

        mov rcx, [rdi + STRING_OFFSET_PTR]
        mov al, [rcx + rbx]
    
    .finish:
        pop rcx
        pop rbx
        ret

;
; Appends a value to the end of the string
;   rdi [in] - Pointer to the string
;   rsi [in] - The byte to push into the string
;
string_push:
    push rax
    push rbx
    push rcx
    push r8
    push r9

    mov r8, rdi
    mov r9, rsi

    ; If the string length is equal to its capacity we need to resize
    mov rax, [rdi + STRING_OFFSET_LENGTH]
    mov rbx, [rdi + STRING_OFFSET_CAPACITY]
    cmp rax, rbx
    jne .set_value

    .resize:
        ; string.ptr = mremap(string.ptr, string.capacity, (string.capacity >>= 1))
        mov rdi, [r8 + STRING_OFFSET_PTR]
        mov rsi, rbx
        shl rbx, 1
        mov [r8 + STRING_OFFSET_CAPACITY], rbx
        mov rdx, rbx
        call mremap
        mov [r8 + STRING_OFFSET_PTR], rax

    .set_value:
        ; string.ptr[string.length] = rsi
        mov rcx, r9
        mov [rdi + rax], cl
        ; string.length++
        inc rax
        mov [rdi + STRING_OFFSET_LENGTH], rax

    .finish:
        pop r9
        pop r8
        pop rcx
        pop rbx
        pop rax
        ret

;
; Removes an element from the end of a string
;   rdi [in] - Pointer to the string
;   al [out] - The element at the end of the string (or -1 if the string is empty)
;
string_pop:
    push rbx
    push rcx

    xor rax, rax

    ; Make sure the string length is > 0
    mov rbx, [rdi + STRING_OFFSET_LENGTH]
    cmp rbx, 0
    jne .pop_char

    mov al, -1
    jmp .finish

    .pop_char:
        ; string.length--
        dec rbx
        mov [rdi + STRING_OFFSET_LENGTH], rbx

        ; rax = string.ptr[string.length]
        mov rcx, [rdi + STRING_OFFSET_PTR]
        mov al, [rcx + rbx]

        ; string.ptr[string.length + 1] = 0
        mov byte [rcx + rbx + 1], 0

    .finish:
        pop rcx
        pop rbx
        ret

;
; Pushes a certain amount of bytes from a buffer into the string
;   rdi [in] - Pointer to the string
;   rsi [in] - Pointer to the buffer
;   rdx [in] - The number of bytes to copy
;
string_push_all:
    push rax
    push rbx
    push rcx
    push r8

    mov r8, rdi

    ; Check if we have enough room for the new bytes
    mov rax, [rdi + STRING_OFFSET_LENGTH]
    mov rbx, [rdi + STRING_OFFSET_CAPACITY]

    mov rcx, rax
    add rcx, rdx

    cmp rcx, rbx
    jng .copy_elements

    .resize:
        ; rbx = round_to_next_power_of_2(needed_capacity)
        bsr rcx, rcx
        inc rcx
        mov rbx, 1
        shl rbx, cl

        ; string.ptr = mremap(string.ptr, string.capacity, rbx)
        mov rdi, [r8 + STRING_OFFSET_PTR]
        mov rsi, [rdi + STRING_OFFSET_CAPACITY]
        mov rdx, rbx
        call mremap
        mov [r8 + STRING_OFFSET_PTR], rax

        mov [r8 + STRING_OFFSET_CAPACITY], rbx

    .copy_elements:
        mov rdi, [rdi + rax + STRING_OFFSET_PTR]
        call memcpy

        add rax, rdx
        mov [r8 + STRING_OFFSET_LENGTH], rax

    .finish:
        pop r8
        pop rcx
        pop rbx
        pop rax

        ret

;
; Calculate the length of a null terminated string
;   rsi [in] - String pointer
;   rax [out] - String length
;
strlen:    
    mov rax, 0

    .loop:
        cmp byte [rsi + rax], 0
        je .finish
        inc rax
        jmp .loop

    .finish:
        ret

%endif