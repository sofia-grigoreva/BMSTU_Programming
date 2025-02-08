assume cs:code, ds: data   
 
; вар9 Определить, какие два последовательных элемента массива наименее 
; отличаются друг от друга. Найти индекс первого элемента пары. 
 
data segment   
    arr dw 2, 4, 10, 7, 8
    len dw ($- arr) / 2
    minraz dw 100
    ind dw 0
    curind dw 0
    curelem dw 0
    output db  ?, ?, ?, ?, '$' 
data ends   
         
code segment   
start:       
    mov ax, data   
    mov ds, ax   

    mov es, ax
    mov ah, 0
    
    mov si, offset arr
    mov cx, len
    dec cx
    lodsw
    mov curelem, ax 
    
cikl:   
    mov bx, curelem
    lodsw
    mov curelem, ax 
    sub ax, bx
    jns positive
    neg ax     
 
positive: 
    cmp ax, minraz
    ja next
    mov minraz, ax 
    mov dx, curind
    mov ind, dx
    
next: 
    inc curind 
    loop cikl 
 
    mov ax, ind
    mov ah, 0 
    mov di, offset output + 4 
 
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
 
    mov ah, 4Ch 
    int 21h 
 
code ends   
end start