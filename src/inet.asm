%ifndef INET_ASM
%define INET_ASM

bits 64
section .text

;
; Swaps the endianness of a 16-bit value
;   ax [in] - the 16-bit value to convert
;   ax [out] - the 16-bit result
;
reverse_byte_order_16:
    push bx

    mov bl, al
    mov al, ah
    mov ah, bl

    pop bx
    ret

;
; Swaps the endianness of a 32-bit value
;   eax [in] - the 32-bit value to convert
;   eax [out] - the 32-bit result
;
reverse_byte_order_32:
    push rbx

    ; Swap bytes 3 and 4
    ;   aabbccdd -> aabbddcc
    mov bl, al
    mov al, ah
    mov ah, bl

    ; Swap bytes 1 and 2 with bytes 3 and 4
    ; aabbddcc -> ddccaabb
    mov ebx, eax
    shl eax, 16
    shr ebx, 16
    mov ax, bx

    ; Swap bytes 3 and 4
    ;   ddccaabb -> ddccbbaa
    mov bl, al
    mov al, ah
    mov ah, bl

    pop rbx
    ret

%endif