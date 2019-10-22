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
    mov cx, ax
    add ecx, array
    mov edi, array
    xor esi, esi
    .loop1:
        mov esi, edi
        sub si, 2
        .loop2:
            add esi, 2
            cmp esi, ecx
            jz .continue1
            mov ax, word[esi]
            mov bx, word[edi]
            cmp ax, bx
            jle .loop2
            mov [edi], ax
            mov [esi], bx
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

macro print_array array_ptr, array_len {
    pusha
    local .loop1
    local .continue1 
    xor ecx, ecx
    mov ebx, array_ptr
    mov cx, array_len
    shl cx, 1
    add ecx, array_ptr
    xor ax, ax
    .loop1:
        cmp ecx, ebx
        jz .continue1
        mov ax, word[ebx]
        mov [el], ax
        zero_str element_str, 10
        itoa [el], element_str_out
        str_len element_str_out, len
        put_str element_str_out, [len]
        add ebx, 2
        jmp .loop1
    .continue1:
    popa
}

macro print_2d_array array_ptr, row_len, col_len {
    pusha
    local .loop1
    local .continue1
    xor ecx, ecx
    xor eax, eax
    xor edx, edx
    xor ebx, ebx
    mov ax, col_len
    shl ax, 1
    mul row_len
    mov ecx, eax
    lea ecx, [ecx + array_ptr]
    lea ebx, [array_ptr]
    mov dx, col_len
    shl dx, 1
    xor ax, ax
    .loop1:
        shr dx, 1
        cmp ecx, ebx
        jz .continue1
        print_array ebx, dx
        put_str break_symbol, 1
        shl dx, 1
        lea ebx, [ebx + edx]
        jmp .loop1
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

macro read_array array_ptr, len_ptr {
    pusha
    local .continue1
    local .loop1
    xor edx, edx
    xor eax, eax
    mov [len_ptr], ax
    lea edx, [array_ptr]
    .loop1:
        zero_str element_str, 10
        read_str element_str, 10
        cmp byte [element_str], 0x0a
        jz .continue1
        atoi element_str, el
        mov ax, [el]
        mov [edx], ax
        xor ax, ax
        lea edx, [edx + 2]
        inc [len_ptr]
        jmp .loop1
    .continue1:
    popa
}

macro read_2d_array array_ptr, row_len_ptr, col_len_ptr {
    pusha
    local .continue1
    local .loop1
    xor ebx, ebx
    lea ebx, [array_ptr]

    xor eax, eax
    mov [col_len_ptr], ax
    mov [row_len_ptr], ax
    .loop1:
        mov [arr_len], ax
        read_array ebx, arr_len
        cmp [arr_len], 0
        jz .continue1
        mov ax, [arr_len]
        lea ebx, [ebx + eax]
        lea ebx, [ebx + eax]
        inc [row_len_ptr]
        mov [col_len_ptr], ax
        xor eax, eax
        jmp .loop1
    .continue1:
    popa
}

macro find array_ptr, search_el, array_len, index_ptr, found_ptr {
    pusha
    local .continue1
    local .loop1
    xor ecx, ecx
    mov ebx, array_ptr
    mov cx, array_len
    shl cx, 1
    lea ecx, [array_ptr + ecx]
    xor dx, dx
    mov dx, search_el
    xor ax, ax
    mov [found_ptr], ax
    .loop1:
        cmp ecx, ebx
        jz .continue1
        cmp word[ebx], dx
        jz .continue2
        lea ebx, [ebx + 2]
        jmp .loop1
    .continue2:
        mov ax, 1
        mov [found_ptr], ax
        sub ebx, array_ptr
        mov ax, bx
        mov bh, 2
        div bh
        mov [index_ptr], ax
    .continue1:
    popa
}

macro offset_to_indx ind, col, row_ind_ptr, col_ind_ptr {
    pusha
    xor dx, dx
    mov ax, ind
    ; mov [col_ind_ptr], ax
    mov bx, col
    div bx
    mov [row_ind_ptr], ax
    mov [col_ind_ptr], dx
    popa
}

start:
    pusha
    str_len instr_str, len
    put_str instr_str, [len]
    read_2d_array array, row_len, col_len

    zero_str element_str, 10
    read_str element_str, 10
    atoi element_str, el

    xor ax, ax
    xor bx, bx 
    mov ax, [row_len]
    mov bx, [col_len]
    mul bx
    mov bx, 2
    mul bx
    mov [len], ax

    find array, [el], [len], indx, fnd
    cmp [fnd], 0
    jz .end
    offset_to_indx [indx], [col_len], el_row, el_col

    zero_str element_str_out, 10
    itoa [el_row], element_str_out
    str_len element_str_out, len
    put_str element_str_out, [len]

    zero_str element_str_out, 10
    itoa [el_col], element_str_out
    str_len element_str_out, len
    put_str element_str_out, [len]

    .end:
    exit 0
    popa
    ret

segment readable writeable
instr_str db "Put arrays:", 0x0a, 0
instr_str_search db "Put element search:", 0x0a, 0
break_symbol db 0x0a
element_str rb 6
element_str_out rb 6
array rw 100
len dw 0
el dw 0
sum dw 0
arr_len dw 0
row_len dw 0
col_len dw 0
indx dw 0
fnd dw 0
el_row dw 0
el_col dw 0
; TODO:
; - check array length
; - check array row length 
; - check namesrow_len
; - fix read string