
assume cs:code, ds:data

; вар9 a * b + c / d + 5

data segment
    a db 50
    b db 3
    c db 4
    d db 2
    prom1 dw ?
    prom2 dw ?
    res db ?
    decoutput db  ?, ?, ?, ?, '$'
    hexoutput db  ?, ?, ?, ?, '$'
data ends

code segment
start:
    mov AX, data
    mov DS, AX

    mov AL, a       
    mov BL, b        
    mul BL           
    mov prom1, AX  

    mov AL, c        
    mov BL, d       
    xor AH, AH      
    div BL           
    mov prom2, AX    
  
    mov AX, prom1    
    add AX, prom2   

    add AX, 5
    
    mov res, AL
    
    mov AL, res
    mov AH, 0
    mov DI, offset decoutput + 4

printdec:
    xor DX, DX
    mov CX, 10
    div CX
    add DL, '0'
    dec DI
    mov [DI], DL
    test AL, AL
    jnz printdec
    mov AH, 09h
    mov DX, DI
    int 21h
    
    mov ah, 2
    mov dl, 10    
    int 21h
    
    mov AL, res
    mov AH, 0
    mov DI, offset hexoutput + 4 
 
hexprint:    
    xor DX, DX
    mov CX, 16    
    div CX
    cmp DL, 10    
    jl notletter
    add DL, 'A' - 10    
    jmp writedigit
    
notletter:
    add DL, '0'
    
writedigit:    
    dec DI
    mov [DI], DL
    test AL, AL    
    jnz hexprint

    mov AH, 09h
    mov DX, DI    
    int 21h
    
    mov AH, 4Ch
    int 21h

code ends
end start


 ;   aam 
 ;   add ax,3030h 
 ;   mov dl,ah 
 ;   mov dh,al 
 ;   mov ah,02 
 ;   int 21h 
 ;   mov dl,dh 
 ;   int 21h

 