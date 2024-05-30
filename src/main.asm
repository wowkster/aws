bits 64
global _start

%include "macros.asm"

section .text
_start:
    push rbp
    mov rbp, rsp
    sub rsp, 44 ; [rbp - 4] = int socket_fd
                ; [rbp - 8] = int connection_fd
                ; [rbp - 24] = sockaddr_in server_addr 
                ;   [rbp - 24] = server_addr.sin_family
                ;   [rbp - 22] = server_addr.sin_port
                ;   [rbp - 20] = server_addr.sin_addr
                ; [rbp - 40] = sockaddr_in client_addr 
                ;   [rbp - 40] = client_addr.sin_family
                ;   [rbp - 38] = client_addr.sin_port
                ;   [rbp - 36] = client_addr.sin_addr
                ; [rbp - 44] = int client_addr_len
    
    mov rsi, start_msg
    call println

    .socket:
    ; socket_fd = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP)
    mov rax, SYSCALL_SOCKET
    mov rdi, AF_INET
    mov rsi, SOCK_STREAM
    mov rdx, IPPROTO_TCP
    syscall

    mov [rbp - 4], eax

    cmp eax, 0
    jnl .setsockopt

    mov rsi, error_msg_socket
    call print_error

    .setsockopt:
    ; setsockopt(socket_fd, SOL_SOCKET, SO_REUSEADDR, &1, sizeof(int))
    mov rax, SYSCALL_SETSOCKOPT
    mov edi, [rbp - 4]
    mov rsi, SOL_SOCKET
    mov rdx, SO_REUSEADDR
    mov r10, one_constant
    mov r8, 8
    syscall

    cmp eax, 0
    jnl .bind

    mov rsi, error_msg_setsockopt
    call print_error

    .bind:
    ; bzero(&server_addr, sizeof(server_addr)); 
    lea rdi, [rbp - 24]
    mov rsi, 16
    call bzero

    ; server_addr.sin_family = AF_INET
    mov word [rbp - 24], AF_INET 
    
    ; server_addr.sin_port = htons(6969)
    mov ax, 6969
    call reverse_byte_order_16
    mov word [rbp - 22], ax

    ; server_addr.sin_port = htonl(INADDR_ANY)
    mov eax, INADDR_ANY
    call reverse_byte_order_32
    mov dword [rbp - 20], eax

    ; bind(socket_fd, &server_addr, sizeof(server_addr))
    mov rax, SYSCALL_BIND
    mov rdi, [rbp - 4]
    lea rsi, [rbp - 24]
    mov rdx, 16
    syscall

    cmp rax, 0
    je .listen

    mov rsi, error_msg_bind
    call print_error

    .listen:
    ; listen(socket_fd, 16)
    mov rax, SYSCALL_LISTEN
    mov rdi, [rbp - 4]
    mov rsi, 16
    syscall

    cmp rax, 0
    je .accept

    mov rsi, error_msg_listen
    call print_error

    .accept:
    mov rsi, listening_msg
    call println

    mov dword [rbp - 44], 16

    ; connection_fd = accept(socket_fd, &client_addr, &client_addr_len)
    mov rax, SYSCALL_ACCEPT
    mov rdi, [rbp - 4]
    lea rsi, [rbp - 40]
    lea rdx, [rbp - 44]
    syscall

    mov [rbp - 8], rax

    cmp rax, 0
    jnl .handle

    mov rsi, error_msg_accept
    call print_error

    .handle:
    ; Print IP and Port
    mov rsi, got_connection_msg
    call print

    mov eax, [rbp - 36]
    call print_ip_address

    mov rax, ':'
    call print_char

    mov rax, 0
    mov ax, [rbp - 38]
    call reverse_byte_order_16
    call print_int

    mov rax, 10
    call print_char

    ; Call connection handler
    mov rax, [rbp - 8]
    call handle_connection

    ; close(socket_fd)
    mov rax, SYSCALL_CLOSE
    mov rdi, [rbp - 4]
    syscall

    ; exit(0)
    mov rax, SYSCALL_EXIT
    mov rdi, 0
    syscall

RECV_BUFFER_LEN equ 1024 * 8

;
; Handles a connection from a client
;   rax [in] - connection file descriptor
;
handle_connection:
    push rbx

    ; struct BufferedReader {
    ;   int fd
    ;   int length
    ;   char recv_buff[1024]
    ; }

    ; struct HTTP_Version {
    ;   int major
    ;   int minor
    ; } (8)

    ; struct HTTP_Header {
    ;   char* key
    ;   char* value
    ; } (16)

    ; struct HTTP_Request {
    ;   int method
    ;   char* uri
    ;   struct HTTP_Version version
    ;   struct HTTP_Header** headers
    ;   char* body
    ;   int64_t content_length 
    ; } (48)

    push rbp
    mov rbp, rsp
    sub rsp, 96 ; [rbp - 24] = BufferedReader buff_read
                ; [rbp - 72] = HTTP_Request req
                ;   [rbp - 72] = req.method
                ;   [rbp - 64] = req.uri
                ;   [rbp - 56] = req.version
                ;   [rbp - 48] = req.headers
                ;   [rbp - 40] = req.body
                ;   [rbp - 32] = req.content_length
                ; [rbp - 96] = String line

    lea rdi, [rbp - 24]
    mov rsi, rax
    call buffered_reader_new

    .loop:
        lea rdi, [rbp - 96]
        call string_new

        lea rdi, [rbp - 24]
        lea rsi, [rbp - 96]
        call buffered_reader_read_line

        lea rdi, [rbp - 96]
        call print_string
        call string_free

        jmp .loop

    ; mov rsi, http_204_response
    ; call strlen
    ; mov rdx, rax

    ; mov rax, SYSCALL_WRITE
    ; mov rdi, rbx
    ; syscall

    ; call print_int

    .finish:
        lea rdi, [rbp - 24]
        mov rsi, rax
        call buffered_reader_new

        mov rsp, rbp
        pop rbp

        pop rbx

        ret

%include "string.asm"
%include "print.asm"
%include "inet.asm"
%include "util.asm"
%include "buff_read.asm"

section .data
    start_msg: db "Starting server...", 0
    listening_msg: db "Listening on http://127.0.0.1:6969", 0
    got_connection_msg: db "Received connection from ", 0
    http_204_response: db "HTTP/1.1 200 OK", 13, 10
                       db "Content-Length: 13", 13, 10
                       db "Content-Type: text/plain", 13, 10, 13, 10
                       db "Hello, world!", 13, 10, 13, 10, 0

    error_msg_socket: db "ERROR: Failed to open socket", 0
    error_msg_setsockopt: db "ERROR: Failed to set socket options", 0
    error_msg_bind: db "ERROR: Failed to bind socket to port", 0
    error_msg_listen: db "ERROR: Failed to listen on socket", 0
    error_msg_accept: db "ERROR: Failed to accept client connection", 0

    one_constant: dq 1

    