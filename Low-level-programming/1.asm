section .data
    video_mem db 0B8000h  ; адрес видеопамяти
    colors db 0x0F, 0x1F, 0x2F, 0x3F, 0x4F, 0x5F, 0x6F, 0x7F  ; цвета для вывода
    msg_format db "Base: %04X%04X, Limit: %04X, Type: %02X, Access: %02X", 0

section .bss
    buffer resb 80  ; буфер для форматированной строки

section .text
global _start

_start:
    ; Инициализация GDT
    lgdt [GDTR]  ; загрузка адреса GDT

    ; Установка сегментов
    mov ax, 0x10  ; сегмент кода
    mov ds, ax
    mov es, ax

    ; Указатель на GDT
    mov si, GDT
    mov cx, GDT_size / 8  ; количество дескрипторов
    xor di, di  ; индекс цвета

next_descriptor:
    cmp cx, 0
    je done

    ; Получаем информацию о дескрипторе
    mov ax, [si]         ; лимит (младший байт)
    mov bx, [si + 2]     ; базовый адрес (младший байт)
    mov dx, [si + 4]     ; атрибуты
    mov di, [si + 6]     ; базовый адрес (старший байт)

    ; Вычисляем полный лимит
    ; (здесь нужно учитывать бит гранулярности, который находится в атрибутах)
    ; Пример: если бит гранулярности установлен, лимит умножается на 4096

    ; Форматируем строку для вывода
    call format_descriptor

    ; Вывод информации в видеопамять
    call print_to_video

    add si, 8  ; переходим к следующему дескриптору
    dec cx
    inc di
    jmp next_descriptor

done:
    ; Завершение программы
    jmp $

format_descriptor:
    ; Здесь реализуем форматирование строки
    ; Пример: формируем строку с адресом базы и лимитом
    ; Используем sprintf или аналог для форматирования
    ; Для простоты, просто заполним буфер статически
    mov eax, [si + 2]  ; базовый адрес (младший байт)
    mov ebx, [si + 6]  ; базовый адрес (старший байт)
    mov ecx, [si]      ; лимит
    mov edx, [si + 4]  ; атрибуты

    ; Пример заполнения буфера (это нужно будет адаптировать)
    ; sprintf(buffer, msg_format, ebx, eax, ecx, атрибуты)

    ret

print_to_video:
    ; Выводим строку из буфера в видеопамять
    mov edi, video_mem
    mov esi, buffer
    mov ecx, 80  ; длина строки
    rep movsb  ; копируем строку в видеопамять
    ret

GDT:
    NULL_descr db 8 dup(0)
    CODE_descr db 0FFh, 0FFh, 00h, 00h, 00h, 10011010b, 11001111b, 00h
    DATA_descr db 0FFh, 0FFh, 00h, 00h, 00h, 10010010b, 11001111b, 00h
    MY1_descr db 09h, 00h, 00h, 00h, 00h, 10011010b, 11001111b, 00h
    MY2_descr db 0FFh, 0FFh, 09h, 00h, 00h, 10011010b, 11001111b, 00h
GDT_size equ $ - GDT

GDTR:
    dw GDT_size - 1  ; 16-битный лимит GDT
    dd GDT           ; 32-битный линейный адрес GDT