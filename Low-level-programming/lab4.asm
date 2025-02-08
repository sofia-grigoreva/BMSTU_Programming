; Вариант 1
;1. Описать с помощью подходящих блоков повторений решение следующих задач:
;а) записать в регистр AH (изначально равный нулю) сумму чисел из регистров AL, BL, CL и DH;
;б) обнулить переменные A, B и C размером в 64 бита (массивы из 8 байт или 4 слов);
;в) зарезервировать директивой DB место в памяти для 40 байтов,
; задав им в качестве начальных значений первые 40 нечётных чисел.

assume cs: code, ds: data

data segment
	output db ? , ? , ? , ? , '$'
	A dw 1, 2, 3, 4
	B dw 5, 6, 7, 8
	C dw 9, 8, 7, 6
	nechet = 1
	rept 40
		db nechet
		nechet = nechet + 2
	endm
data ends

code segment

main:

part_a:
	mov ax, data
	mov ds, ax

	xor ah, ah
	mov al, 10
	;mov bl, 20
	mov cl, 30
	mov dh, 10

	irp s, < al, bl, cl, dh >
		add ah, s
	endm

	mov al, ah
	mov ah, 0
	mov di, offset output + 3

print: 
    xor dx, dx 
    mov cx, 10 
    div cx 
    add dl, '0' 
    dec di 
    mov [di], dl 
    test ax, ax
    jnz print 
    mov ah, 09h 
    mov dx, di 
    int 21h 
     
    mov ah, 2 
    mov dl, 10     
    int 21h 

part_b:
	xor di, di
	irp arr, < A, B, C >
		mov di, offset arr
		rept 8
			mov byte ptr[di], 0
			inc di
		endm
	endm


	mov ah, 4Ch 
    int 21h 

code ends
end main
