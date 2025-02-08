assume cs: code, ds: data

data segment
 first db 255, 254 dup (0)
 second db 255, 254 dup (0)                                            
     print_len db ?, ?, ?, ?, '$'
data ends

code segment

input proc
  push bp
  mov bp, sp
  
  mov dx, [bp+4]
  xor ax, ax
  mov ah, 0Ah
  int 21h
  
  mov dx, [bp+4]
  inc dx
  mov si, dx
  mov cx, [si]
  xor ch, ch
  add si, cx
  mov byte ptr [si+1], '$'
  inc dx
  
  pop bp
  ret
input endp

endl proc
  mov ah, 02h
  mov dl, 0Ah
  int 21h
  ret
endl endp

strspn proc
  push bp
  mov bp, sp
  xor cx, cx               
  mov si, [bp+4]           
  mov di, [bp+6]          

loop_first_str:
  mov al, [si]             
  cmp al, 0                
  je return       
  mov bx, di               

loop_second_str:
  mov dl, [bx]            
  cmp dl, '$'
  je return                         

  cmp al, dl               
  je in_str           
  inc bx                   
  jmp loop_second_str          

in_str:                   
  inc si   
  inc cx                
  jmp loop_first_str          

return:
  mov ax, cx 
  cmp ax, 0 
  je endd
  dec ax

endd:            
  pop bp                   
  ret                      

strspn endp


main:
  mov ax, data
  mov ds, ax

  push offset second
  call input
  call endl
  
  push offset first
  call input
  call endl
  
  push offset first + 2
  push offset second + 2
  call strspn
  mov ah, 0
  
print1:
    mov ax, cx         
    xor dx, dx             
    mov cx, 10             
    mov di, offset print_len + 4  
    
digit:
    div cx                 
    add dl, '0'            
    dec di                 
    mov [di], dl           
    test ax, ax            
    jnz digit      

    mov ah, 09h            
    mov dx, di             
    int 21h                
    mov ah, 4ch
    int 21h
      

code ends
end main