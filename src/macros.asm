%ifndef MACROS_ASM
%define MACROS_ASM

%define SYSCALL_READ 0
%define SYSCALL_WRITE 1
%define SYSCALL_CLOSE 3
%define SYSCALL_MMAP 9
%define SYSCALL_MUNMAP 10
%define SYSCALL_MREMAP 25
%define SYSCALL_SOCKET 41
%define SYSCALL_ACCEPT 43
%define SYSCALL_BIND 49
%define SYSCALL_LISTEN 50
%define SYSCALL_SETSOCKOPT 54
%define SYSCALL_EXIT 60

%define STDIN 0
%define STDOUT 1
%define STDERR 2

%define PROT_READ 0x1
%define PROT_WRITE 0x2

%define MAP_PRIVATE 0x2
%define MAP_ANONYMOUS 0x20

%define AF_INET 2
%define SOCK_STREAM	1
%define IPPROTO_TCP 0
%define INADDR_ANY	0

%define SOL_SOCKET 1
%define SO_REUSEADDR 2


%endif