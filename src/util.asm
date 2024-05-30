%ifndef UTIL_ASM
%define UTIL_ASM

bits 64
section .text

;
; Zeros out a region of memory
;   rdi [in] - Pointer to the region of memory
;   rsi [in] - The number of zero bytes to write
;
bzero:    
    push rdx

    mov rdx, 0

    .loop:
        cmp rdx, rsi
        je .finish

        mov byte [rdi + rdx], 0
        
        inc rdx
        jmp .loop

    .finish:
        pop rdx
        ret

%endif