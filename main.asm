format ELF64 executable

; task
; - file: to store and read todos
; - user able to show, write, read and delete

sys_read            equ 0
sys_write           equ 1
sys_open            equ 2
sys_exit            equ 60

NULL                equ 0

STDIN               equ 0
STDOUT              equ 1
STDERR              equ 2

O_RDONLY            equ 0
O_RDWR              equ 2

MAX_READ            equ 1024 * 64 ; bytes

macro write fd, buffer, count
{
    mov rax, sys_write
    mov rdi, fd
    mov rsi, buffer
    mov rdx, count
    syscall
}

macro exit code
{
    mov rax, sys_exit
    mov rdi, code
    syscall
}


; int open(const char *pathname, int flags);
macro open pathname, flags
{
    mov rax, sys_open
    mov rdi, pathname
    mov rsi, flags
    syscall
}

macro read fd, buffer, length
{
    mov rax, sys_read
    mov rdi, fd
    mov rsi, buffer
    mov rdx, length
    syscall
}

macro print_file char, buffer, length
{
    ; NOTE
    ; loop until rdx != length of buffer
    ; extract each byte from buffer

    mov rdx, 0
.loop:
    push rdx ; store rdx

    mov rax, buffer ; rax = &buffer
    mov eax, [rax+rdx] ; calculate next byte
    mov byte [char], al ; lower eax [ al ], stores byte

    write STDOUT, char, 1 ; output byte, NOTE: changing 1 => to any other number will result in buffer overflow

    mov byte [char], 10 ; 10 represents a newline
    write STDOUT, char, 1 ; again output byte

    ; some random shit, future me will understand
    pop rdx
    inc rdx
    mov rcx, [len]
    dec rcx
    cmp rdx, rcx
    jle .loop
}

segment readable executable
entry main

main:
    open pathname, O_RDWR ; open returns rax: file descriptor (fd)
    cmp rax, 0
    jl .err
    mov qword [file_fd], rax

.main_loop:
    read qword [file_fd], buffer, MAX_READ
    mov qword [len], rax

    cmp [len], 0
    jne .continue
    write STDOUT, empty_msg, empty_msg_len

.continue:
    write STDOUT, buffer, [len] ; print buffer
    write STDOUT, menu, menu_len

    read STDIN, char, 2 ; 1 - data, 2 - EOF byte

    cmp [char], 49 ; 1
    jne .next_char_0

    read STDIN, buffer, MAX_READ
    mov qword [len], rax
    write STDOUT, buffer, [len] ; print buffer
    write qword [file_fd], buffer, [len]

    jmp .end

.next_char_0:

    cmp [char], 50 ; 2
    jne .next_char_1

    ; ...

    jmp .end

.next_char_1:

    cmp [char], 51 ; 3
    jne .end

    exit 0

.end:
    jmp .main_loop

    write STDOUT, ok_msg, ok_msg_len ; OK, if everything went well.
    exit 0
.err:
    write STDERR, err_msg, err_msg_len
    exit 1

segment readable writable

pathname db "todo"
file_fd dq 0
len dq 0

; msg
err_msg db "[ERR]: ERROR!", 10
err_msg_len = $ - err_msg

ok_msg db "[INFO]: OK!", 10
ok_msg_len = $ - ok_msg

empty_msg db "[INFO]: todo list is empty.", 10
empty_msg_len = $ - empty_msg

menu db "----------------MENU----------------", 10, "1) WRITE", 10, "2) DELETE", 10, "3) QUIT", 10, "ENTER: "
menu_len = $ - menu

; storage classes
char rb 1
buffer rb MAX_READ
