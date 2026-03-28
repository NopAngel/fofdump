section .data
    newline     db 0x0A
    space       db " "
    colon       db ": "
    hex_chars   db "0123456789ABCDEF"
    
    clr_reset   db 0x1B, "[0m"
    clr_cyan    db 0x1B, "[36m"
    clr_green   db 0x1B, "[32m"
    clr_gray    db 0x1B, "[90m"
    
    msg_ver     db "fofdump v1.0", 0x0A
    len_ver     equ $ - msg_ver
    arg_ver     db "--version", 0
    msg_usage   db "Use: ./fofdump <FILE>", 0x0A
    len_usage   equ $ - msg_usage

section .bss
    buffer      resb 16
    bytes_read  resq 1
    addr_out    resb 1
    hex_out     resb 2
    counter     resq 1

section .text
    global _start

_start:
    pop rax                 ; argc
    cmp rax, 2
    jl .err_usage

    pop rax                
    pop rdi                
    mov r12, rdi

    ; Check --version
    mov rsi, arg_ver
    call strcmp
    test rax, rax
    jz .show_version
    ; =====================
    mov rax, 2
    mov rdi, r12
    mov rsi, 0
    syscall
    test rax, rax
    js .exit
    mov r8, rax             ; FD
    mov qword [counter], 0

.main_loop:
    mov rax, 0             
    mov rdi, r8
    mov rsi, buffer
    mov rdx, 16
    syscall
    
    test rax, rax
    jle .done              
    mov [bytes_read], rax

    call print_cyan
    mov rdi, [counter]
    call print_hex_64
    call print_reset
    
    mov rdi, colon
    mov rdx, 2
    call print_string

    xor r13, r13           
.hex_loop:
    cmp r13, 16
    je .prep_ascii
    
    cmp r13, [bytes_read]
    jae .print_padding
    
    movzx rbx, byte [buffer + r13]
    test rbx, rbx
    jz .is_zero
    call print_green
    jmp .do_print
.is_zero:
    call print_gray
.do_print:
    call print_byte_hex
    call print_reset
    mov rdi, space
    mov rdx, 1
    call print_string
    inc r13
    jmp .hex_loop

.print_padding:
    mov rdi, space
    mov rdx, 1
    call print_string
    call print_string
    call print_string
    inc r13
    jmp .hex_loop

.prep_ascii:
    mov rdi, space
    mov rdx, 1
    call print_string
    
    xor r13, r13
.ascii_loop:
    cmp r13, [bytes_read]
    jae .end_line
    movzx rax, byte [buffer + r13]
    cmp al, 32
    jb .dot
    cmp al, 126
    ja .dot
    jmp .print_char
.dot:
    mov al, '.'
.print_char:
    mov [hex_out], al
    mov rdi, hex_out
    mov rdx, 1
    call print_string
    inc r13
    jmp .ascii_loop

.end_line:
    mov rdi, newline
    mov rdx, 1
    call print_string
    
    mov rax, [bytes_read]
    add [counter], rax
    
    cmp rax, 16            
    jne .done
    jmp .main_loop

.done:
    mov rax, 3
    mov rdi, r8
    syscall
.exit:
    mov rax, 60
    xor rdi, rdi
    syscall

.show_version:
    mov rdi, msg_ver
    mov rdx, len_ver
    call print_string
    jmp .exit

.err_usage:
    mov rdi, msg_usage
    mov rdx, len_usage
    call print_string
    jmp .exit

; print's
print_string:
    mov rax, 1
    mov rsi, rdi
    mov rdi, 1
    syscall
    ret

print_cyan:  
    mov rdi, clr_cyan
    mov rdx, 5
    call print_string
    ret

print_green: 
    mov rdi, clr_green
    mov rdx, 5
    call print_string
    ret

print_gray:  
    mov rdi, clr_gray
    mov rdx, 5
    call print_string
    ret

print_reset: 
    mov rdi, clr_reset
    mov rdx, 4
    call print_string
    ret

print_byte_hex:
    mov rdx, rbx
    shr rdx, 4
    mov al, [hex_chars + rdx]
    mov [hex_out], al
    mov rdx, rbx
    and rdx, 0x0F
    mov al, [hex_chars + rdx]
    mov [hex_out + 1], al
    mov rdi, hex_out
    mov rdx, 2
    call print_string
    ret

print_hex_64:
    mov r9, 15
.l64:
    mov rbx, rdi
    mov rcx, r9
    shl rcx, 2
    shr rbx, cl
    and rbx, 0x0F
    mov al, [hex_chars + rbx]
    mov [addr_out], al
    push rdi
    push r9
    mov rdi, addr_out
    mov rdx, 1
    call print_string
    pop r9
    pop rdi
    sub r9, 1
    jns .l64
    ret

strcmp:
.l:
    mov al, [rdi]
    mov bl, [rsi]
    cmp al, bl
    jne .d
    test al, al
    jz .e
    inc rdi
    inc rsi
    jmp .l
.d:
    mov rax, 1
    ret
.e:
    xor rax, rax
    ret
