format ELF executable 3
entry start
segment readable writable executable

macro read_str str_ptr, len
{
    pusha
    xor edx, edx
    mov eax, 3
    mov ebx, 0
    mov ecx, str_ptr
    mov edx, len
    int 0x80
    popa
}

macro put_str str_ptr, len
{
    pusha
    xor edx, edx
    mov eax, 4
    mov ebx, 1
    mov ecx, str_ptr
    mov dx, len
    int 0x80
    popa
}

macro str_len str_ptr, len_ptr {
    pusha
    local .overit
    local .loop
        mov edx, str_ptr
        xor eax, eax
        jmp .overit
    .loop:
        inc edx
        inc eax
    .overit:
        cmp byte[edx], 0
        jnz .loop
    mov [len_ptr], ax
    popa
}

macro exit code
{
    pusha
    mov eax, 1
    mov ebx, code
    int 0x80
    popa
}


macro itoa num, str_ptr
{
    pusha
    local .push_chars
    local .pop_chars
    local .less
    local .continue
    xor   eax, eax
    xor   ebx, ebx
    mov ax, num
    mov bx, 10
    mov edi, str_ptr

    test ax, ax
    jns .push_chars
    neg ax
.push_chars:
    xor edx, edx
    div bx
    add dl, '0'
.continue:
    push dx
    inc esi
    test ax, ax
    jnz .push_chars

    mov ax, num
    test ax, ax
    jns .pop_chars
    mov dx, '-'
    push dx
    inc esi

    cld

.pop_chars:
    pop ax
    stosb
    dec esi
    test esi, esi
    jnz .pop_chars
    mov ax, 0x0a
    stosb
    popa
}

macro atoi str_ptr, num_ptr
{
    pusha
    local .get_decimal
    local .atoi_continue1
    local .switch_sign
    local .ret_error
    local .atoi_continue2
    xor eax, eax
    xor ebx, ebx
    xor ecx, ecx
    mov esi, str_ptr
    push esi
    cmp byte [esi], '-'
    jne .get_decimal
    inc esi
.get_decimal:
    lodsb
    cmp al, 48
    jl .atoi_continue1
    sub al, 48
    imul bx, 10
    jo .ret_error
    add bx, ax
    jo .ret_error
    xor eax, eax
    jmp .get_decimal
.atoi_continue1:
    xchg bx,ax
    pop esi
    cmp byte [esi] , '-'
    jnz .switch_sign
    neg ax
.switch_sign:
    mov [num_ptr], ax
    jmp .atoi_continue2
.ret_error:
    exit 1
.atoi_continue2:
    popa
}


macro array_len array_ptr, len_ptr {
    pusha
    local .loop
    local .continue1
    local .ret_error
    mov ebx, array
    xor ax, ax
    .loop:
        cmp word[ebx], 0
        jz .continue1

        inc [len_ptr]
        jo .ret_error

        add ebx, 2
        jmp .loop
    .ret_error:
        exit 1
    .continue1:
    popa
}

macro zero_str str_ptr, len {
    pusha
    local .overit
    local .loop
    mov edi, str_ptr
    xor eax, eax
    jmp .overit
    .loop:
        inc edi
        inc eax
    .overit:
        mov byte[edi], 0
        cmp ax, len
        jnz .loop
    popa
}

macro sort_array array_ptr, len {
    pusha
    local .loop1
    local .loop2
    local .continue1
    local .continue2
    local .ret_error
    xor ecx, ecx
    mov ax, len
    mov bx, 2
    mul bx
    ; sub ax, 2
    mov cx, ax
    add ecx, array
    mov edi, array
    xor esi, esi
    .loop1:
        mov esi, ecx
        .loop2:
            sub esi, 2
            cmp esi, edi
            jz .continue1
            mov ax, word[esi]
            mov bx, word[esi - 2]
            cmp ax, bx
            jle .loop2
            mov word[esi], bx
            mov word[esi - 2], ax
            jmp .loop2
        .continue1:

        add edi, 2
        cmp edi, ecx
        jnz .loop1
    .continue2:
    xor si, si
    xor di, di
    popa
}

macro print_array array_ptr {
    pusha
    local .loop
    local .continue1
    local .ret_error
    mov ebx, array
    xor ax, ax
    .loop:
        cmp word[ebx], 0
        jz .continue1
        mov ax, word[ebx]
        mov [el], ax
        zero_str element_str_out, 6
        itoa [el], element_str_out
        str_len element_str_out, len
        put_str element_str_out, [len]

        add ebx, 2
        jmp .loop
    .ret_error:
        exit 1
    .continue1:
    popa
}


start:
    pusha
    str_len instr_str, len
    put_str instr_str, [len]
    mov ebx, array
    read_array:
        read_str element_str, 10
        str_len element_str, len
        atoi element_str, el

        mov ax, [el]
        mov [ebx] , ax

        xor ax, ax
        add ebx, 2
        cmp byte [element_str], 0x0a
        jnz read_array
    continue1:

    mov [len], ax
    array_len array, len
    sort_array array, [len]
    print_array array
    exit 0
    popa
    ret


segment readable writeable
instr_str db "Put arrays:", 0x0a, 0x00
element_str rb 6
element_str_out rb 6
array rw 100
len dw 0
el dw 0
sum dw 0