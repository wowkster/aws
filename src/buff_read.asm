%ifndef BUFF_READ_ASM
%define BUFF_READ_ASM

%include "mem.asm"
%include "string.asm"

bits 64

; struct BufferedReader {
;   int fd
;   int length  
;   int next_index
;   char* recv_buff
; } (24)

BUFFERED_READER_OFFSET_FD equ 0
BUFFERED_READER_OFFSET_LENGTH equ 4
BUFFERED_READER_OFFSET_NEXT_INDEX equ 8
BUFFERED_READER_OFFSET_RECV_BUFF equ 16

BUFFERED_READER_CAPACITY equ 1024 * 8

;
; Allocates a new buffered reader
;   rdi [in] - Pointer to an (uninitialized) BufferedReader struct
;   rsi [in] - The file descriptor to read from
;
buffered_reader_new:
    push rax
    push rbx
    push rdi

    mov rbx, rdi

    mov dword [rbx + BUFFERED_READER_OFFSET_FD], esi
    mov dword [rbx + BUFFERED_READER_OFFSET_LENGTH], 0
    mov dword [rbx + BUFFERED_READER_OFFSET_NEXT_INDEX], 0
    
    mov rdi, BUFFERED_READER_CAPACITY
    call mmap

    mov [rbx + BUFFERED_READER_OFFSET_RECV_BUFF], rax

    pop rdi
    pop rbx
    pop rax
    ret

;
; Closes the underlying file and frees the memory associated with the Buffered Reader
;   rdi [in] - Pointer to the initialized BufferedReader struct
;
buffered_reader_close:
    push rax
    push rbx
    push rdi
    push rsi

    mov rbx, rdi

    ; close(buff_read.fd)
    mov rax, SYSCALL_CLOSE
    xor rdi, rdi
    mov edi, [rbx + BUFFERED_READER_OFFSET_FD]
    syscall

    ; munmap(buff_read.recv_buff, BUFFERED_READER_CAPACITY)
    mov rdi, [rbx + BUFFERED_READER_OFFSET_RECV_BUFF]
    mov rsi, BUFFERED_READER_CAPACITY
    call munmap

    pop rsi
    pop rdi
    pop rbx
    pop rax
    ret

;
; Fills the backing buffer with new data from the stream
;   rdi [in] - Pointer to the BufferedReader
;
buffered_reader_fill:
    push rax
    push rbx
    push rdx
    push rdi
    push rsi

    mov rbx, rdi

    .read_loop:

        ; read(buff_read.fd, buff_read.recv_buff, BUFFERED_READER_CAPACITY)
        mov rax, SYSCALL_READ
        mov rdi, [rbx + BUFFERED_READER_OFFSET_FD]
        mov rsi, [rbx + BUFFERED_READER_OFFSET_RECV_BUFF]
        mov rdx, BUFFERED_READER_CAPACITY
        syscall

        cmp rax, 0
        je .read_loop
    
    .check_len:
        cmp rax, 0
        jl .finish

        mov dword [rbx + BUFFERED_READER_OFFSET_LENGTH], eax
        mov dword [rbx + BUFFERED_READER_OFFSET_NEXT_INDEX], 0

    .finish:
        pop rsi
        pop rdi
        pop rdx
        pop rbx
        pop rax
        ret

;
; Reads a single character from the stream (blocks if there are no unread characters)
;   rdi [in] - Pointer to the BufferedReader
;   al [out] - The character read or -1 if we reached the end of the stream
;
buffered_reader_read:
    push rbx
    push rcx

    xor rax, rax
    xor rbx, rbx

    ; Check if we have unread characters in the buffer
    mov eax, [rdi + BUFFERED_READER_OFFSET_LENGTH]
    mov ebx, [rdi + BUFFERED_READER_OFFSET_NEXT_INDEX]
    
    cmp ebx, eax
    jl .consume_byte

    ; We have reached the end of the buffer, so try and fill it
    call buffered_reader_fill

    mov eax, [rdi + BUFFERED_READER_OFFSET_LENGTH]
    mov ebx, [rdi + BUFFERED_READER_OFFSET_NEXT_INDEX]

    cmp ebx, eax
    jl .consume_byte

    ; We tried reading but got nothing, so return an error
    mov al, -1
    jmp .finish

    .consume_byte:
        xor rax, rax
        mov rcx, [rdi + BUFFERED_READER_OFFSET_RECV_BUFF]
        mov al, [rcx + rbx]
        
        inc ebx
        mov [rdi + BUFFERED_READER_OFFSET_NEXT_INDEX], ebx

    .finish:
        pop rcx
        pop rbx
        ret

;
; Reads bytes into the supplied string until a '\r\n' is found (blocks until a CRLF is found)
;   rdi [in] - Pointer to the BufferedReader
;   rsi [in] - Pointer to the String
;
buffered_reader_read_line:
    push rax
    push rbx
    push rcx
    push rdx
    push rdi
    push rsi

    mov rbx, rdi
    mov rcx, rsi
    
    .loop:
        xor rax, rax

        mov rdi, rbx
        call buffered_reader_read
        mov dl, al

        ; Check if the byte is a LF
        cmp dl, 0x0a 
        jne .push_char

        ; Check if last char is a CR
        mov rdi, rcx
        call string_peek

        cmp al, 0x0d
        jne .push_char

        ; Push the char and exit the loop

        mov rdi, rcx
        mov rsi, rax
        call string_push
        jmp .finished

    .push_char:

        mov rdi, rcx
        mov rsi, rax
        call string_push
        jmp .loop

    .finished:
        pop rsi
        pop rdi
        pop rdx
        pop rcx
        pop rbx
        pop rax
        ret
%endif