format ELF executable 3
entry start
segment readable writable executable

macro read_str str_ptr, len
{
    pusha
    xor edx, edx
    mov eax, 3 ; #define __NR_read 3
    mov ebx, 0 ; fd
    mov ecx, str_ptr ; buffer_ptr
    mov dx, len ; length
    int 0x80 ; sys_cal
    popa
}

macro put_str str_ptr, len
{
    pusha
    xor edx, edx
    mov eax, 4 ; #define __NR_write 4
    mov ebx, 1 ; fd
    mov ecx, str_ptr ; buffer_ptr
    mov dx, len ; length
    int 0x80 ; sys_call
    popa
}

macro str_len str_ptr, len_ptr {
    pusha
    local .continue1
    local .loop1
    xor eax, eax ; length = 0
    lea edx, [str_ptr] ; point to first element
    jmp .continue1 ; skip iterator
    .loop1:
        inc edx ; next element
        inc eax ; increment length
    .continue1:
        cmp byte[edx], 0 ; check if pointed element is \0
        jnz .loop1 ; if not eq go to next
    mov [len_ptr], ax ; store len
    popa
}

macro exit code
{
    pusha
    mov eax, 1 ; #define __NR_exit 1
    mov ebx, code ; code
    int 0x80 ; sys_call
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
    xor   ecx, ecx
    mov ax, num ; copy value
    mov bx, 10 ; store snum base
    lea edi, [str_ptr] ; point to first element 

    test ax, ax ; check sign
    jns .push_chars ; if positive go to chars representation; test SF
    neg ax ; else switcch sign

    .push_chars:
        xor edx, edx ; clear dividend; note: num = [s1][s2][s3][s4] thus num / base = [s1][s2][s3] (r. [s4])
        div bx ; DX = 0, AX = num, BX = 10 => DX:AX / BX => AX = [s1][s2][s3], DX = [s4], BX = 10
        add dx, "0" ; convert number to symbol 

    .continue:
        push dx ; store in stack
        inc cx ; increment counter 
        test ax, ax ; logical and
        jnz .push_chars ; if all bits of number are not zeros, read next symbol; test ZF 

        mov ax, num ; copy value
        test ax, ax ; logical and 
        jns .pop_chars ; if number is  not negative, extract it's string value; test SF
    
    mov dx, '-' ; else store sign
    push dx ; push sign to stack
    inc cx ; increment counter

    cld ; reset DF

    .pop_chars:
        pop ax ; get symbol
        stosb ; load AL to ES:EDI; increment EDI
        dec cx ; increment counter
        test cx, cx ; logical and
        jnz .pop_chars ; if all bits of number are not zeros, read next symbol; test ZF
    
    mov ax, 0x0a ; add \n 
    stosb ; load AL to ES:EDI; increment EDI
    popa
}

macro atoi str_ptr, num_ptr
{
    pusha
    local .get_decimal
    local .continue1
    local .store_num
    local .ret_error
    local .continue2
    xor eax, eax
    xor ebx, ebx
    xor ecx, ecx
    cld ; set DF = 0
    mov esi, str_ptr ; point to first symbol
    cmp byte [esi], '-' ; check if negative
    jne .get_decimal ; if ZF = 0 start read string
    inc esi ; else skip one symbol
    .get_decimal:
        lodsb ; load DS:ESI to AL; increment ESI
        cmp al, 48 ; check if symbol is number
        jl .continue1 ; else stop reading num
        cmp al, 57 ; check if symbol is number
        jg .continue1 ; else stop reading num
        sub al, 48 ; convert to number
        imul bx, 10 ; shift <-
        jo .ret_error ; if OF = 1 throw error
        add bx, ax ; add extracted symbol
        jo .ret_error ; if OF = 1 throw error
        xor eax, eax
        jmp .get_decimal ; go to next symbol
    .continue1:
        xchg bx, ax ; exchnge registre's interiors
        mov esi, str_ptr ; point to first symbol
        cmp byte [esi] , '-' ; check if num is negative
        jnz .store_num ; continue if ZF=0
        neg ax ; else switch sign
    .store_num:
        mov [num_ptr], ax ; store num
        jmp .continue2 ; go to end
    .ret_error: 
        exit 1 ; reserved for error
    .continue2:
        popa
}

macro print_num element {
    pusha
    zero_str element_str, 6 ; clear string
    zero_str element_str_out, 6 ; clear string
    itoa element, element_str_out ; convert number to string
    str_len element_str_out, len ; calculate string length 
    put_str element_str_out, [len] ; write string to fd=1
    zero_str element_str, 6 ; clear string
    zero_str element_str_out, 6 ; clear string
    popa
}

macro print_array array_ptr, array_len {
    pusha
    local .loop1
    local .continue1 
    xor ecx, ecx
    lea ebx, [array_ptr] ; poin to first array's element
    mov cx, array_len ; store array length
    shl cx, 1 ; double length as array element equel 2 bytes
    add ecx, array_ptr ; point to the next word after the last array element 
    xor ax, ax ; clean array 
    .loop1:
        cmp ecx, ebx ; check if the end of the array is reached 
        jz .continue1 ; end if FZ=1
        mov ax, word[ebx] ; load array element to AX
        mov [el], ax ; store to persistant data
        print_num [el] ; print num
        lea ebx, [ebx + 2] ; point to next array's element
        jmp .loop1 ; go to next element
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
    mov ax, col_len ; load number of colomns (number of elements in the row)
    shl ax, 1 ; double as element length = 2 bytes
    mul row_len ; calculate total array size = col_len * 2 * row_len
    mov ecx, eax ; store length in ECX
    lea ecx, [ecx + array_ptr] ; point to the word next to the last element
    lea ebx, [array_ptr] ; point to first element
    mov dx, col_len ; load number of colomns (number of elements in the row)
    shl dx, 1 ; store one row lendth (in bytes)
    xor ax, ax 
    .loop1:
        shr dx, 1 ; store number of elements in one row 
        cmp ecx, ebx ; check if the end of the array is reached 
        jz .continue1 ; end if FZ=1
        print_array ebx, dx ; print 1D array
        put_str break_symbol, 1 ; put delimetr
        shl dx, 1 ; store one row lendth (in bytes)
        lea ebx, [ebx + edx] ; point to the next element
        jmp .loop1 ; go to next element
    .continue1:
    popa
}

macro zero_str str_ptr, len {
    pusha
    local .continue1
    local .loop1
    xor ecx, ecx
    lea edi, [str_ptr] ; point to first element
    jmp .continue1 ; skip iterator
    .loop1:
        inc edi ; next symbol
        inc ecx ; increment counter
    .continue1:
        mov byte[edi], 0 ; put zero
        cmp cx, len ; compsre counters 
        jnz .loop1 ; next symbol, until counter != length
    popa
}

macro read_array array_ptr, len_ptr {
    pusha
    local .continue1
    local .loop1
    xor edx, edx
    xor eax, eax
    mov [len_ptr], ax ; reset length 
    lea edx, [array_ptr] ; point to the first element
    .loop1:
        zero_str element_str, 6 ; clean string
        read_str element_str, 6 ; read element
        cmp byte [element_str], 0x0a ; check if the end of array is reached
        jz .continue1 ; end if ZF=1
        atoi element_str, el ; convert to number
        mov ax, [el] ; store new element to AX 
        mov [edx], ax ; move to array
        xor ax, ax 
        lea edx, [edx + 2] ; point to next element
        inc [len_ptr] ; increment length
        jmp .loop1 ; go to next element
    .continue1:
    popa
}

macro read_2d_array array_ptr, row_len_ptr, col_len_ptr {
    pusha
    local .continue1
    local .continue2
    local .loop1
    xor ebx, ebx
    lea ebx, [array_ptr] ; point to first element

    xor eax, eax
    mov [col_len_ptr], ax ; reset length
    mov [row_len_ptr], ax ; reset length
    .loop1:
        mov [arr_len], ax ; reset length 
        read_array ebx, arr_len ; read 1d array
        cmp [arr_len], 0 ; check if the end 
        jz .continue1 ; end if ZF=1
        mov ax, [arr_len] ; store length of row
        cmp [row_len_ptr], 0 ; check if the first row
        jz .continue2 ; continue if ZF=1
        cmp ax, [col_len_ptr] ; else check if row lengthes are equel 
        jz .continue2 ; continue if ZF=1
        exit 1 ; else exit with error
        .continue2:
            lea ebx, [ebx + eax] ; go to the next free space (1 element = 2 byte)
            lea ebx, [ebx + eax] ; so it is two times bigger than length
            inc [row_len_ptr] ; increment row counter
            mov [col_len_ptr], ax ; update column counter
            xor eax, eax ; clean array
            jmp .loop1 ; go to next element
    .continue1:
    popa
}

macro find array_ptr, search_el, array_len, index_ptr, found_ptr {
    ; note: araay with any dimension is considered 
    ; to be 1d array with fixed length of elements
    ; thus it is posible to iterate throw them and
    ; find it's position and then convert it with 
    ; respect to dimensions
    pusha
    local .continue1
    local .loop1
    xor ecx, ecx
    xor dx, dx
    xor ax, ax
    lea ebx, [array_ptr] ; point to first element 
    mov cx, array_len ; load array lngth (element counter)
    shl cx, 1 ; double to get length in bytes 
    lea ecx, [array_ptr + ecx] ; point to the element next to the last one
    mov dx, search_el ; load element to look up
    mov [found_ptr], ax ; found flag set to zero: basicaly, can be removed and index_ptr set to -1
    .loop1:
        cmp ecx, ebx ; check if the end of the array is reached 
        jz .continue1 ; end if ZF=1
        cmp word[ebx], dx ; check if element found 
        jz .continue2 ; continue if ZF=1
        lea ebx, [ebx + 2] ; else point to the next element 
        jmp .loop1 ; go to next element
    .continue2:
        mov ax, 1 
        mov [found_ptr], ax ; set found flag
        sub ebx, array_ptr ; calculate index of found element
        mov ax, bx ; move to ax
        mov bh, 2 ; prepare divider to get index but not offset in bytes
        div bh ; divide
        mov [index_ptr], ax ; store index
    .continue1:
    popa
}

macro offset_to_indx ind, col, row_ind_ptr, col_ind_ptr {
    pusha
    xor dx, dx
    mov ax, ind ; load index
    mov bx, col ; load row length
    div bx ; calculate position if  index = column_counter * row_ind + col_ind
    mov [row_ind_ptr], ax ; load row_ind (quot) 
    mov [col_ind_ptr], dx ; load col_ind (reminder)
    popa
}

start:
    pusha
    str_len instr_str, len ; get string length
    put_str instr_str, [len] ; print string
    read_2d_array array, row_len, col_len ; erad 2d array

    zero_str element_str, 6 ; clean input string
    read_str element_str, 7 ; read string
    atoi element_str, el ; convert string to number

    xor ax, ax
    xor bx, bx 
    mov ax, [row_len] ; load row counter
    mov bx, [col_len] ; load column counter 
    mul bx ; calculate total number of elements (store to DX:AX)
    mov [len], ax ; store array length

    find array, [el], [len], indx, fnd ; look up the element
    cmp [fnd], 0 ; check if found
    jz .end ; end if not found (ZF=1)
    offset_to_indx [indx], [col_len], el_row, el_col ; else convert offset to indexes

    print_num [el_row] ; print row index
    print_num [el_col] ; print col index
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
; - check names row_len