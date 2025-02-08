       .386p                                           ; разрешить привилегированные инструкции i386

assume     CS:RM_CODE,SS:RM_STACK  

get_addr macro segm, name
    xor eax, eax
    mov ax, &segm
    shl eax, 4
    add eax, offset &name
endm

; СЕГМЕНТ КОДА (для Real Mode)
; -----------------------------------------------------------------------------
RM_CODE     segment     para public 'CODE' use16
    
@start:
        mov        AX,03h
        int        10h            
        in         AL,92h
        test         AL,2
        jnz skip1
        or al, 2
        out        92h,AL
 
skip1:
        get_addr PM_CODE, @pm_start     
        mov        dword ptr entry_point,EAX      
        get_addr RM_CODE, GDT
        mov        dword ptr GDTR+2,EAX
        lgdt       fword ptr GDTR
        cli
        in         AL,70h
        or         AL,80h
        out        70h,AL
        mov        EAX,CR0
        or         AL,1
        mov        CR0,EAX

    db 66h, 0EAh
    entry_point dd ?
    dw 1 * 8 

GDT:  
NULL_descr  db     8 dup(0)
CODE_descr  db     0FFh,0FFh,00h,00h,00h,10011010b,11001111b,00h
DATA_descr  db     0FFh,0FFh,00h,00h,00h,10010010b,11001111b,00h
MY1_descr   db     000h,009h,00h,00h,00h,10010010b,11011111b,00h     ; лимит с номером варианта
MYERROR_descr  db  099h,000h,40h,99h,99h,01111101b,11111001b,99h     ; база и лимит с номером варианта
 
GDTR dw $-GDT-1, 0, 0
RM_CODE            ends
; -----------------------------------------------------------------------------
 

; СЕГМЕНТ СТЕКА (для Real Mode)
; -----------------------------------------------------------------------------
RM_STACK           segment             para stack 'STACK' use16
            db     100h dup(?)                  ; 256 байт под стек - это даже много
RM_STACK           ends
; -----------------------------------------------------------------------------


assume CS:PM_CODE, DS:PM_DATA


; СЕГМЕНТ КОДА (для Protected Mode)
; -----------------------------------------------------------------------------
PM_CODE            segment             para public 'CODE' use32

@pm_start:

; загрузим сегментные регистры селекторами на соответствующие дескрипторы:
        mov        AX, 2 * 8                ; селектор на второй дескриптор (DATA_descr)
        mov        DS,AX                        ; в DS его        
        mov        ES,AX                        ; его же - в ES
 
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; создать каталог страниц
        mov        EDI,100000h                ; его физический адрес - 1 Мб
        mov        EAX, 101007h               ; адрес таблицы 0 = 1 Мб + 4 Кб
        stosd             
                              ; записать первый элемент каталога
        mov        ECX, 3FFh                   ; остальные элементы каталога -
        xor        EAX,EAX                      ; нули
        rep        stosd

; заполнить таблицу страниц 0
        
        mov eax, 07h
        mov ecx, 1024  
                   ; число страниц в таблице
fill_page_table:
        stosd                                   ; записать элемент таблицы
        add        EAX,1000h                ; добавить к адресу 4096 байтов
        loop       fill_page_table              ; и повторить для всех элементов
; поместить адрес каталога страниц в CR3
        mov        EAX,100000h                
        mov        CR3,EAX
; включить страничную адресацию,
        mov        EAX,CR0
        or         EAX,80000000h
        mov        CR0,EAX

        mov eax, 0B8007h
        mov ES:00101000h+031h*4,eax


@main:
    sgdt fword ptr ind

    mov word ptr ds:[cursor_pos], 0

    mov dl, 0
    mov ds:[color], dl

;извлечение размера

    mov ax, word ptr [ind] 

    inc ax
    mov cl, 3
    shr ax, cl
    mov cx, ax

    mov eax, dword ptr [ind+2]
    mov ebx, eax
    xor edi, edi
    mov dl, 3

;цикл по дескрипторам

gdt_loop:
    cmp di, cx
    jge end_loop

    add dl, 2
    mov ds:[color], dl

    irpc ch, <Descriptor >
        mov al, '&ch&'
        call print_char
    endm

    mov ax, di
    add al, '0'
    call print_char

    push ecx
    push edx

    mov ecx, dword ptr [ebx+4]

    test ecx, 200000h
    jz skip

    irpc ch, < invalid>
        mov al, '&ch&'
        call print_char
    endm


skip:
    mov edx, dword ptr [ebx]

    call newline

    irpc ch, <Base: >
        mov al, '&ch&'
        call print_char
    endm

    rol ecx, 8
    mov ax, cx
    xchg al, ah
    ror ecx, 8
    call print_str

    rol edx, 16
    mov ax, dx
    ror edx, 16
    call print_str

    call newline

    irpc ch, <Limit: >
        mov al, '&ch&'
        call print_char
    endm

    mov eax, ecx
    and eax, 0F0000h
    mov ax, dx

    test ecx, 800000h
    jz skip2

    shl eax, 12
    or eax, 0FFFh

skip2:

    call print_word
    call newline

    mov eax, ecx
    and eax, 0E00h
    shr eax, 9

    test al, 0100b 
    jnz code_type1

    push ax

    irpc ch, <Type: data, >
        mov al, '&ch&'
        call print_char
    endm

    pop ax

    test al, 1 
    jz read_type

    push ax
    irpc ch, <read/write>
        mov al, '&ch&'
        call print_char
    endm
    pop ax

    jmp d_type

read_type:

    push ax

    irpc ch, <read-only>
        mov al, '&ch&'
        call print_char
    endm

    pop ax

    jmp d_type

d_type:

    test al, 10b
    jz end_type

    irpc ch, <, >
        mov al, '&ch&'
        call print_char
    endm

    irpc ch, <down expansion>
        mov al, '&ch&'
        call print_char
    endm

    jmp end_type

code_type1:

    push ax

    irpc ch, <Type: code, execute>
        mov al, '&ch&'
        call print_char
    endm

    pop ax
    xor al, 11b 
    test al, 11b 

    jnz code_type2

    push ax

    irpc ch, <& read>
        mov al, '&ch&'
        call print_char
    endm

    pop ax

code_type2:

    test al, 10b
    jnz end_type

    irpc ch, <, >
        mov al, '&ch&'
        call print_char
    endm

    irpc ch, <conforming>
        mov al, '&ch&'
        call print_char
    endm
    
end_type:

    irpc ch, <, >
        mov al, '&ch&'
        call print_char
    endm

    test ecx, 0100h
    jnz acs

    irpc ch, <not accessed>
        mov al, '&ch&'
        call print_char
    endm

    jmp end_acs

acs:

    irpc ch, <accessed>
        mov al, '&ch&'
        call print_char
    endm

end_acs:

    irpc ch, <. >
        mov al, '&ch&'
        call print_char
    endm

    irpc ch, <Priv level: >
        mov al, '&ch&'
        call print_char
    endm

    mov eax, ecx
    and eax, 6000h
    ror eax, 13

    call print_byte

    irpc ch, <. >
        mov al, '&ch&'
        call print_char
    endm

    call newline 

    test ecx, 8000h
    jz not_in_mem

    irpc ch, <in RAM >
        mov al, '&ch&'
        call print_char
    endm

    jmp end_mem

not_in_mem:

    irpc ch, <Not in RAM >
        mov al, '&ch&'
        call print_char
    endm

end_mem:

    irpc ch, <User bit: >
        mov al, '&ch&'
        call print_char
    endm

    mov eax, ecx
    and eax, 100000h
    ror eax, 20
    add al, '0'

    call print_char

    irpc ch, <, Bit depth: >
        mov al, '&ch&'
        call print_char
    endm

    test ecx, 100000h

    jnz size_32

    irpc ch, <16>
        mov al, '&ch&'
        call print_char
    endm

    jmp end_size


size_32:

    irpc ch, <32>
        mov al, '&ch&'
        call print_char
    endm

end_size:

    irpc ch, < bits.>
        mov al, '&ch&'
        call print_char
    endm

    call newline

    pop edx
    pop ecx

    inc di
    add ebx, 8
    jmp gdt_loop
    
end_loop:

    jmp $



; функции

cursor_update:

    mov word ptr ds:[cursor_pos], dx
    pop edx
    ret


newline:

    push edx
    mov dx, word ptr ds:[cursor_pos]

    mov dh, 0
    inc dl
    cmp dl, 25
    jl cursor_update

    mov dl, 0
    jmp cursor_update


screen_put_at:

    push eax
    push edx
    push edi
    xor edi, edi
    and edx, 0FFFFh
    mov edi, 031000h
    push ax
    xor ax, ax
    mov al, 80
    mul dl 
    xor dl, dl
    xchg dh, dl 
    add ax, dx
    xchg dx, ax
    shl dx, 1
    pop ax
    add edi, edx
    mov ah, byte ptr ds:[color]
    stosw
    pop edi
    pop edx
    pop eax
    ret


print_char:

    push edx

    mov dx, word ptr ds:[cursor_pos]
    call screen_put_at

    inc dh
    cmp dh, 80
    jl cursor_update

    mov dh, 0
    inc dl
    cmp dl, 25
    jl cursor_update

    mov dl, 0


print:

    push ecx
    push esi
    push edx
    push ax


print_loop:

    mov al, byte ptr ds:[esi]
    call print_char

    inc esi
    loop print_loop

    pop ax
    pop edx
    pop esi
    pop ecx
    ret


strlen:

    push esi
    push ax

    xor cx, cx

strlen_loop:

    mov al, byte ptr ds:[esi]
    cmp al, 0
    je end_strlen

    inc esi
    inc cx
    jmp strlen_loop


end_strlen:

    pop ax
    pop esi

    ret


print_string:

    call strlen
    call print
    ret


print_byte:

    push ax
    push cx

    mov ah, al
    mov cl, 4
    shr al, cl
    call hex_digit
    call print_char

    mov al, ah
    and al, 0Fh
    call hex_digit
    call print_char

    pop cx
    pop ax
    ret

hex_digit:
    add al, '0'
    cmp al, '9'
    jle end_print
    sub al, '0'
    sub al, 10
    add al, 'A'

end_print:
    ret


print_str:

    xchg al, ah
    call print_byte
    xchg al, ah
    call print_byte
    ret


print_word:

    rol eax, 16
    call print_str
    rol eax, 16
    call print_str
    ret


PM_CODE ends
 
PM_DATA segment para public 'DATA' use32
    assume CS:PM_DATA

    color db 0
    cursor_pos dw 0

    ind dd 0, 0, 0
PM_DATA ends

end @start
