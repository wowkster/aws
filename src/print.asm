%ifndef PRINT_ASM
%define PRINT_ASM

%include "macros.asm"
%include "string.asm"

bits 64
section .text

;
; Prints the string to STDOUT
;   rsi [in] - the null terminated string to print
;
print:    
    push rax
    push rdx

    call strlen
    mov rdx, rax

    mov rax, SYSCALL_WRITE
    mov rdi, STDOUT
    syscall

    pop rdx
    pop rax
    ret

;
; Prints the string to STDOUT followed by a new line
;   rsi [in] - the null terminated string to print
;
println:    
    push rax
    
    call print

    mov rax, 10
    call print_char

    pop rax
    ret

;
; Prints a number as an integer in base 10
;   rax [in] - The number to write to STDOUT
;
print_int:    
    push rax
    push rbx
    push rdx

    mov rbx, 10
    mov rdx, 0

    div rbx

    test rax, rax
    je .l1
    call print_int

    .l1:
        lea rdx, [rdx + '0']
        
        push rax
        mov rax, rdx
        call print_char
        pop rax

    .finish:
        pop rdx
        pop rbx
        pop rax
        ret

;
; Prints a single character number to STDOUT
;   al [in] - the char to print
;
print_char:
    push rax
    push rdi
    push rsi
    push rdx

    push rbp
    mov rbp, rsp
    sub rsp, 8

    mov [rbp - 8], al

    mov rax, SYSCALL_WRITE
    mov rdi, STDOUT
    lea rsi, [rbp - 8]
    mov rdx, 1
    syscall

    mov rsp, rbp
    pop rbp

    pop rdx
    pop rsi
    pop rdi
    pop rax
    ret

;
; Prints a string to STDOUT
;   rdi [in] - Pointer to the string
;
print_string:
    push rax
    push rdx
    push rdi
    push rsi

    mov rsi, [rdi + STRING_OFFSET_PTR]
    mov rdx, [rdi + STRING_OFFSET_LENGTH]
    mov rax, SYSCALL_WRITE
    mov rdi, STDOUT
    syscall

    pop rsi
    pop rdi
    pop rdx
    pop rax
    ret
;
; Prints the given IP address in the standard x.x.x.x fashion
;   eax [in] - IP address to print
;
print_ip_address:
    push rax
    push rbx

    mov ebx, eax
    mov rax, 0

    mov al, bl
    call print_int
    
    mov rax, '.'
    call print_char

    mov ax, bx
    shr ax, 8
    call print_int

    mov rax, '.'
    call print_char

    mov eax, ebx
    shr eax, 16
    and eax, 0x00FF
    call print_int

    mov rax, '.'
    call print_char

    mov eax, ebx
    shr eax, 24
    call print_int

    pop rbx
    pop rax
    ret

;
; Exit the process with an error message
;   rsi [in] - Null-terminated error messaage to print
;
print_error:
    mov rbx, rax
    
    call strlen
    mov rdx, rax

    mov rax, SYSCALL_WRITE
    mov rdi, STDERR
    syscall

    mov rax, ' '
    call print_char
    
    mov rax, '('
    call print_char

    mov rax, rbx
    call print_errno

    mov rax, ')'
    call print_char

    mov rax, 10
    call print_char

    mov     rax, SYSCALL_EXIT
    mov     rdi, 1
    syscall

print_errno:
    not rax
    inc rax

    mov rsi, [_errno_table + rax * 8]

    call strlen
    mov rdx, rax

    mov rax, SYSCALL_WRITE
    mov rdi, STDERR
    syscall

    ret

section .data
    _error_EPERM: db "EPERM", 0
    _error_ENOENT: db "ENOENT", 0
    _error_ESRCH: db "ESRCH", 0
    _error_EINTR: db "EINTR", 0
    _error_EIO: db "EIO", 0
    _error_ENXIO: db "ENXIO", 0
    _error_E2BIG: db "E2BIG", 0
    _error_ENOEXEC: db "ENOEXEC", 0
    _error_EBADF: db "EBADF", 0
    _error_ECHILD: db "ECHILD", 0
    _error_EAGAIN: db "EAGAIN", 0
    _error_ENOMEM: db "ENOMEM", 0
    _error_EACCES: db "EACCES", 0
    _error_EFAULT: db "EFAULT", 0
    _error_ENOTBLK: db "ENOTBLK", 0
    _error_EBUSY: db "EBUSY", 0
    _error_EEXIST: db "EEXIST", 0
    _error_EXDEV: db "EXDEV", 0
    _error_ENODEV: db "ENODEV", 0
    _error_ENOTDIR: db "ENOTDIR", 0
    _error_EISDIR: db "EISDIR", 0
    _error_EINVAL: db "EINVAL", 0
    _error_ENFILE: db "ENFILE", 0
    _error_EMFILE: db "EMFILE", 0
    _error_ENOTTY: db "ENOTTY", 0
    _error_ETXTBSY: db "ETXTBSY", 0
    _error_EFBIG: db "EFBIG", 0
    _error_ENOSPC: db "ENOSPC", 0
    _error_ESPIPE: db "ESPIPE", 0
    _error_EROFS: db "EROFS", 0
    _error_EMLINK: db "EMLINK", 0
    _error_EPIPE: db "EPIPE", 0
    _error_EDOM: db "EDOM", 0
    _error_ERANGE: db "ERANGE", 0
    _error_EDEADLOCK: db "EDEADLOCK", 0
    _error_ENAMETOOLONG: db "ENAMETOOLONG", 0
    _error_ENOLCK: db "ENOLCK", 0
    _error_ENOSYS: db "ENOSYS", 0
    _error_ENOTEMPTY: db "ENOTEMPTY", 0
    _error_ELOOP: db "ELOOP", 0
    _error_ENOMSG: db "ENOMSG", 0
    _error_EIDRM: db "EIDRM", 0
    _error_ECHRNG: db "ECHRNG", 0
    _error_EL2NSYNC: db "EL2NSYNC", 0
    _error_EL3HLT: db "EL3HLT", 0
    _error_EL3RST: db "EL3RST", 0
    _error_ELNRNG: db "ELNRNG", 0
    _error_EUNATCH: db "EUNATCH", 0
    _error_ENOCSI: db "ENOCSI", 0
    _error_EL2HLT: db "EL2HLT", 0
    _error_EBADE: db "EBADE", 0
    _error_EBADR: db "EBADR", 0
    _error_EXFULL: db "EXFULL", 0
    _error_ENOANO: db "ENOANO", 0
    _error_EBADRQC: db "EBADRQC", 0
    _error_EBADSLT: db "EBADSLT", 0
    _error_EBFONT: db "EBFONT", 0
    _error_ENOSTR: db "ENOSTR", 0
    _error_ENODATA: db "ENODATA", 0
    _error_ETIME: db "ETIME", 0
    _error_ENOSR: db "ENOSR", 0
    _error_ENONET: db "ENONET", 0
    _error_ENOPKG: db "ENOPKG", 0
    _error_EREMOTE: db "EREMOTE", 0
    _error_ENOLINK: db "ENOLINK", 0
    _error_EADV: db "EADV", 0
    _error_ESRMNT: db "ESRMNT", 0
    _error_ECOMM: db "ECOMM", 0
    _error_EPROTO: db "EPROTO", 0
    _error_EMULTIHOP: db "EMULTIHOP", 0
    _error_EDOTDOT: db "EDOTDOT", 0
    _error_EBADMSG: db "EBADMSG", 0
    _error_EOVERFLOW: db "EOVERFLOW", 0
    _error_ENOTUNIQ: db "ENOTUNIQ", 0
    _error_EBADFD: db "EBADFD", 0
    _error_EREMCHG: db "EREMCHG", 0
    _error_ELIBACC: db "ELIBACC", 0
    _error_ELIBBAD: db "ELIBBAD", 0
    _error_ELIBSCN: db "ELIBSCN", 0
    _error_ELIBMAX: db "ELIBMAX", 0
    _error_ELIBEXEC: db "ELIBEXEC", 0
    _error_EILSEQ: db "EILSEQ", 0
    _error_ERESTART: db "ERESTART", 0
    _error_ESTRPIPE: db "ESTRPIPE", 0
    _error_EUSERS: db "EUSERS", 0
    _error_ENOTSOCK: db "ENOTSOCK", 0
    _error_EDESTADDRREQ: db "EDESTADDRREQ", 0
    _error_EMSGSIZE: db "EMSGSIZE", 0
    _error_EPROTOTYPE: db "EPROTOTYPE", 0
    _error_ENOPROTOOPT: db "ENOPROTOOPT", 0
    _error_EPROTONOSUPPORT: db "EPROTONOSUPPORT", 0
    _error_ESOCKTNOSUPPORT: db "ESOCKTNOSUPPORT", 0
    _error_EOPNOTSUPP: db "EOPNOTSUPP", 0
    _error_EPFNOSUPPORT: db "EPFNOSUPPORT", 0
    _error_EAFNOSUPPORT: db "EAFNOSUPPORT", 0
    _error_EADDRINUSE: db "EADDRINUSE", 0
    _error_EADDRNOTAVAIL: db "EADDRNOTAVAIL", 0
    _error_ENETDOWN: db "ENETDOWN", 0
    _error_ENETUNREACH: db "ENETUNREACH", 0
    _error_ENETRESET: db "ENETRESET", 0
    _error_ECONNABORTED: db "ECONNABORTED", 0
    _error_ECONNRESET: db "ECONNRESET", 0
    _error_ENOBUFS: db "ENOBUFS", 0
    _error_EISCONN: db "EISCONN", 0
    _error_ENOTCONN: db "ENOTCONN", 0
    _error_ESHUTDOWN: db "ESHUTDOWN", 0
    _error_ETOOMANYREFS: db "ETOOMANYREFS", 0
    _error_ETIMEDOUT: db "ETIMEDOUT", 0
    _error_ECONNREFUSED: db "ECONNREFUSED", 0
    _error_EHOSTDOWN: db "EHOSTDOWN", 0
    _error_EHOSTUNREACH: db "EHOSTUNREACH", 0
    _error_EALREADY: db "EALREADY", 0
    _error_EINPROGRESS: db "EINPROGRESS", 0
    _error_ESTALE: db "ESTALE", 0
    _error_EUCLEAN: db "EUCLEAN", 0
    _error_ENOTNAM: db "ENOTNAM", 0
    _error_ENAVAIL: db "ENAVAIL", 0
    _error_EISNAM: db "EISNAM", 0
    _error_EREMOTEIO: db "EREMOTEIO", 0
    _error_EDQUOT: db "EDQUOT", 0
    _error_ENOMEDIUM: db "ENOMEDIUM", 0
    _error_EMEDIUMTYPE: db "EMEDIUMTYPE", 0
    _error_ECANCELED: db "ECANCELED", 0
    _error_ENOKEY: db "ENOKEY", 0
    _error_EKEYEXPIRED: db "EKEYEXPIRED", 0
    _error_EKEYREVOKED: db "EKEYREVOKED", 0
    _error_EKEYREJECTED: db "EKEYREJECTED", 0
    _error_EOWNERDEAD: db "EOWNERDEAD", 0
    _error_ENOTRECOVERABLE: db "ENOTRECOVERABLE", 0
    _error_ERFKILL: db "ERFKILL", 0
    _error_EHWPOISON: db "EHWPOISON", 0

    _errno_table:
        dq 0                      ; 0
        dq _error_EPERM           ; 1
        dq _error_ENOENT          ; 2
        dq _error_ESRCH           ; 3
        dq _error_EINTR           ; 4
        dq _error_EIO             ; 5
        dq _error_ENXIO           ; 6
        dq _error_E2BIG           ; 7
        dq _error_ENOEXEC         ; 8
        dq _error_EBADF           ; 9
        dq _error_ECHILD          ; 10
        dq _error_EAGAIN          ; 11
        dq _error_ENOMEM          ; 12
        dq _error_EACCES          ; 13
        dq _error_EFAULT          ; 14
        dq _error_ENOTBLK         ; 15
        dq _error_EBUSY           ; 16
        dq _error_EEXIST          ; 17
        dq _error_EXDEV           ; 18
        dq _error_ENODEV          ; 19
        dq _error_ENOTDIR         ; 20
        dq _error_EISDIR          ; 21
        dq _error_EINVAL          ; 22
        dq _error_ENFILE          ; 23
        dq _error_EMFILE          ; 24
        dq _error_ENOTTY          ; 25
        dq _error_ETXTBSY         ; 26
        dq _error_EFBIG           ; 27
        dq _error_ENOSPC          ; 28
        dq _error_ESPIPE          ; 29
        dq _error_EROFS           ; 30
        dq _error_EMLINK          ; 31
        dq _error_EPIPE           ; 32
        dq _error_EDOM            ; 33
        dq _error_ERANGE          ; 34
        dq _error_EDEADLOCK       ; 35
        dq _error_ENAMETOOLONG    ; 36
        dq _error_ENOLCK          ; 37
        dq _error_ENOSYS          ; 38              
        dq _error_ENOTEMPTY       ; 39
        dq _error_ELOOP           ; 40
        dq 0                      ; 41
        dq _error_ENOMSG          ; 42
        dq _error_EIDRM           ; 43
        dq _error_ECHRNG          ; 44
        dq _error_EL2NSYNC        ; 45
        dq _error_EL3HLT          ; 46
        dq _error_EL3RST          ; 47
        dq _error_ELNRNG          ; 48
        dq _error_EUNATCH         ; 49
        dq _error_ENOCSI          ; 50
        dq _error_EL2HLT          ; 51
        dq _error_EBADE           ; 52
        dq _error_EBADR           ; 53
        dq _error_EXFULL          ; 54
        dq _error_ENOANO          ; 55
        dq _error_EBADRQC         ; 56
        dq _error_EBADSLT         ; 57
        dq 0                      ; 58
        dq _error_EBFONT          ; 59
        dq _error_ENOSTR          ; 60
        dq _error_ENODATA         ; 61
        dq _error_ETIME           ; 62
        dq _error_ENOSR           ; 63
        dq _error_ENONET          ; 64
        dq _error_ENOPKG          ; 65
        dq _error_EREMOTE         ; 66
        dq _error_ENOLINK         ; 67
        dq _error_EADV            ; 68
        dq _error_ESRMNT          ; 69
        dq _error_ECOMM           ; 70
        dq _error_EPROTO          ; 71
        dq _error_EMULTIHOP       ; 72
        dq _error_EDOTDOT         ; 73
        dq _error_EBADMSG         ; 74
        dq _error_EOVERFLOW       ; 75
        dq _error_ENOTUNIQ        ; 76
        dq _error_EBADFD          ; 77
        dq _error_EREMCHG         ; 78
        dq _error_ELIBACC         ; 79
        dq _error_ELIBBAD         ; 80
        dq _error_ELIBSCN         ; 81
        dq _error_ELIBMAX         ; 82
        dq _error_ELIBEXEC        ; 83
        dq _error_EILSEQ          ; 84
        dq _error_ERESTART        ; 85
        dq _error_ESTRPIPE        ; 86
        dq _error_EUSERS          ; 87
        dq _error_ENOTSOCK        ; 88
        dq _error_EDESTADDRREQ    ; 89
        dq _error_EMSGSIZE        ; 90
        dq _error_EPROTOTYPE      ; 91
        dq _error_ENOPROTOOPT     ; 92
        dq _error_EPROTONOSUPPORT ; 93
        dq _error_ESOCKTNOSUPPORT ; 94
        dq _error_EOPNOTSUPP      ; 95
        dq _error_EPFNOSUPPORT    ; 96
        dq _error_EAFNOSUPPORT    ; 97
        dq _error_EADDRINUSE      ; 98
        dq _error_EADDRNOTAVAIL   ; 99
        dq _error_ENETDOWN        ; 100
        dq _error_ENETUNREACH     ; 101
        dq _error_ENETRESET       ; 102
        dq _error_ECONNABORTED    ; 103
        dq _error_ECONNRESET      ; 104
        dq _error_ENOBUFS         ; 105
        dq _error_EISCONN         ; 106
        dq _error_ENOTCONN        ; 107
        dq _error_ESHUTDOWN       ; 108
        dq _error_ETOOMANYREFS    ; 109
        dq _error_ETIMEDOUT       ; 110
        dq _error_ECONNREFUSED    ; 111
        dq _error_EHOSTDOWN       ; 112
        dq _error_EHOSTUNREACH    ; 113
        dq _error_EALREADY        ; 114
        dq _error_EINPROGRESS     ; 115
        dq _error_ESTALE          ; 116
        dq _error_EUCLEAN         ; 117
        dq _error_ENOTNAM         ; 118
        dq _error_ENAVAIL         ; 119
        dq _error_EISNAM          ; 120
        dq _error_EREMOTEIO       ; 121
        dq _error_EDQUOT          ; 122
        dq _error_ENOMEDIUM       ; 123
        dq _error_EMEDIUMTYPE     ; 124
        dq _error_ECANCELED       ; 125
        dq _error_ENOKEY          ; 126
        dq _error_EKEYEXPIRED     ; 127
        dq _error_EKEYREVOKED     ; 128
        dq _error_EKEYREJECTED    ; 129
        dq _error_EOWNERDEAD      ; 130
        dq _error_ENOTRECOVERABLE ; 131
        dq _error_ERFKILL         ; 132
        dq _error_EHWPOISON       ; 133

%endif