%ifndef MEM_ASM
%define MEM_ASM

%include "macros.asm"
%include "print.asm"

bits 64

segment .data

error_msg_mmap: db "ERROR: Failed to allocate memory", 0
error_msg_mremap: db "ERROR: Failed to reallocate memory", 0
error_msg_munmap: db "ERROR: Failed to free memory", 0

segment .text

;
; Requests the operating system to allocate some memory
;   rdi [in] - The number of bytes to allocate
;   rax [out] - A pointer to the allocated memory block (checked to be valid and zeroed)
;
mmap:
    push rdx
    push rdi
    push rsi
    push r8
    push r9
    push r10
    
    mov rsi, rdi
    mov rax, SYSCALL_MMAP
    mov rdi, 0
    mov rdx, PROT_READ | PROT_WRITE
    mov r10, MAP_PRIVATE | MAP_ANONYMOUS
    mov r8, -1
    mov r9, 0
    syscall

    cmp rax, 0
    jg .finish

    mov rsi, error_msg_mmap
    call print_error

    .finish:

    pop r10
    pop r9
    pop r8
    pop rsi
    pop rdi
    pop rdx
    ret

;
; Requests the operating system to reallocate a region of memory
;   rdi [in] - A pointer to the previously allocated memory
;   rsi [in] - The old size of the memory region
;   rdx [in] - The new size to allocate
;   rax [out] - A pointer to the allocated memory block (checked to be valid and zeroed)
;
mremap:
    push r10
    
    mov rax, SYSCALL_MREMAP
    mov r10, 0
    syscall

    cmp rax, 0
    jg .finish

    mov rsi, error_msg_mremap
    call print_error

    .finish:

    pop r10
    ret

;
; Requests the operating system to free a region of memory
;   rdi [in] - A pointer to the previously allocated memory
;   rsi [in] - The old size of the memory region
;
munmap:
    push rax
    
    mov rax, SYSCALL_MUNMAP
    syscall

    cmp rax, 0
    jg .finish

    mov rsi, error_msg_munmap
    call print_error

    .finish:

    pop rax
    ret

;
; Copies n bytes from memory area src to dest
;   rdi [in] - dest
;   rsi [in] - src
;   rdx [in] - n
;
memcpy:
    push rax
    push rbx
    push rcx

    .copy_qwords:
        ; rbx = number of qwords to copy
        mov rbx, rdx
        shr rbx, 3

        mov rcx, 0

    .copy_qwords_loop:
        cmp rbx, 0
        je .copy_bytes

        mov rax, [rsi + rcx * 8]
        mov [rdi + rcx * 8], rax

        inc rcx
        dec rbx

    .copy_bytes:
        ; rbx = number of bytes to copy
        mov rbx, rdx
        and rbx, 0b0000_0111

        mov rcx, 0
    
    .copy_bytes_loop:
        cmp rbx, 0
        je .finish

        mov al, [rsi + rcx]
        mov [rdi + rcx], al

        inc rcx
        dec rbx
    
    .finish:
        pop rcx
        pop rbx
        pop rax
        ret

%endif