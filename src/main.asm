bits 64
global _main

section .text
_main:
    mov     rax, 4 ; write
    mov     rdi, 1 ; stdout
    mov     rsi, msg
    mov     rdx, msg.len
    syscall

    mov     rax, 1 ; exit
    mov     rdi, 0
    syscall


section .data
    msg:    db      "Hello, world!", 10
    .len:   equ     $ - msg