assume cs: code, ds: data

data segment
    num1 db 25, ?, 25 dup (0) 
    num2 db 25, ?, 25 dup (0)
    sign1 dw 0
    sign2 dw 0
    len1 dw 0
    len2 dw 0
    hnum1 db 25, ?, 25 dup (0) 
    hnum2 db 25, ?, 25 dup (0)
    base dw 10
    great dw 0
    add_res db 50, 50 dup (0) 
    mul_res db 50, 50 dup (0) 
    hadd_res db 50, 50 dup (0) 
    hmul_res db 50, 50 dup (0)
    res_sign dw 0        
    output db 0ah, 0dh, '$'
    msg1 db "Add: $"
    msg2 db "Mul: $" 
data ends

sseg segment stack
db 255 dup (?)
sseg ends

code segment

;--ввод---------------------------------------------------

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
  
str_to_num proc
    pop bp 
    pop di 
    mov cx, 0
    mov cl, [di]
    add di, 1
    mov ax, 0
    mov al, cl
    mov bx, 0
    cmp byte ptr [di], '-'
    jne str_loop
    dec ax
    mov bx, 1
    inc di
    dec cx

    str_loop:
        cmp byte ptr [di], 48
        jb exit				
        cmp byte ptr [di], 57
        ja hex			
        sub byte ptr [di], 30h		
        jmp str_next

    hex: 	
        cmp base, 10
        je exit
        cmp byte ptr [di], 65
        jb exit				
        cmp byte ptr [di], 70			
        ja little			
        sub byte ptr [di], 55	
        jmp str_next

    little: 	
        cmp byte ptr [di], 97
        jb exit				
        cmp byte ptr [di], 102
        ja exit				
        sub byte ptr [di], 87
            	
    str_next: 
        inc di			
        dec cx
        or cx, cx
        jne str_loop
        jmp end_loop

    exit: 
        mov ah, 4ch
        int 21h
        
    end_loop: 
        mov byte ptr [di], '$'	
        push bp
        ret	
str_to_num endp

;--вывод---------------------------------------------------

print proc  
	pop bp
	pop di
	mov cx, 0
	mov cl, [di]
	add di, 1
	mov dx, di
	cmp res_sign, 1
	jne num_to_str
	mov byte ptr [di], 45
	inc di
	dec cx

	num_to_str:
		cmp byte ptr [di], 9		
		ja num_loop
		add byte ptr [di], 48 		
		jmp num_next

	num_loop:
		add byte ptr [di], 55 	

	num_next:
		inc di				
		dec cx				
		or cx, cx
		jne num_to_str

	mov byte ptr [di], '$'			
	mov ah, 09h
	int 21h	
	mov dx, offset output
	int 21h
	push bp
	ret
print endp

;--нахождение большего---------------------------------------------------

find_greater proc
	push bp			
	mov bp, sp		
	mov di, [bp+4]		
	mov si, [bp+6]
	mov cx, len1
	cmp len2, cx
    jb num1_greater
	ja num2_greater

	compare:	
		cmp byte ptr [di], '$'
		je end_compare
		mov cx, 0
		mov cl, byte ptr [di]
		cmp byte ptr [si], cl
	    jb num1_greater
	    ja num2_greater
		inc di
		inc si
		jmp compare

	num1_greater:
		mov great, 1
		jmp end_compare

	num2_greater:
		mov great, 2
		jmp end_compare

	end_compare:
		ret
	
find_greater endp

;--сложение---------------------------------------------------

addition proc
	push bp			
	mov bp, sp		
	cmp great, 2
    je add_swap
	mov di, [bp+4]		;num1
	mov si, [bp+6]		;num2
	mov bx, [bp+8]	    ;res
    mov cx, len2
	mov dx, len1	
    jmp add_next

    add_swap:
        mov si, [bp+4]		
        mov di, [bp+6]		
        mov bx, [bp+8]	    
        mov cx, len1
        mov dx, len2	
        
    add_next:	
        add di, dx 		
        add si, cx
        sub dx, cx	
        add bx, [bx]	
        push dx
        mov dl, [bp + 10]
        xor ax, ax

	add_loop:
		or cx, cx
		je add_then
		add al, byte ptr [di]
		add al, byte ptr [si]
		div dl				
		mov byte ptr [bx], ah 
		xor ah, ah		
		dec di	
		dec si
		dec cx
		dec bx
		jmp add_loop

    add_then:
        pop cx

	add_first_part:
        or cx, cx
		je add_exit
		add al, byte ptr [di]
		div dl				
		mov byte ptr [bx], ah 
		xor ah, ah		
		dec di	
		dec cx
		dec bx
		jmp add_first_part

	add_exit: 
        mov byte ptr [bx], al
        mov sp, bp 
        pop bp     
        ret	   
addition endp

;--вычитание---------------------------------------------------

subtraction proc
	push bp
	mov bp, sp
	mov di, [bp+4]
	mov si, [bp+6]
	mov bx, [bp+8]
	mov cx, 0
	mov dx, 0
	mov cx, len1
	mov dx, len2
	add di, cx
	add si, dx
	cmp great, 2
	jne sub_next

    sub_swap:
	    xchg cx, dx
	    xchg di, si

	sub_next:
		sub cx, dx
		add bx, [bx]
		push cx
		xor ax, ax
		xor cx, cx

	sub_loop:
		or dx, dx
		je sub_then
		mov al, byte ptr [di]
		cmp al, cl
		jnb less
		add al, [bp+10]
		dec al
		jmp sub1

	less:
		sub al, cl
		xor cx, cx

	sub1:
		cmp al, byte ptr [si]
		jnb sub2
		add al, [bp+10]
		mov cx, 1

	sub2:
		sub al, byte ptr [si]
		mov byte ptr [bx], al
		dec di
		dec si
		dec dx
		dec bx
		jmp sub_loop

	sub_then:
		pop dx

	sub3:
		xor ah, ah
		or dx, dx
		je sub_exit
		mov al, byte ptr [di]
		cmp al, cl
		jnb sub4
		add al, [bp+10]
		dec al
		jmp sub5

	sub4:
		sub al, cl
		xor cx, cx

	sub5:
		mov byte ptr [bx], al
		xor ah, ah
		dec di
		dec dx
		dec bx
		jmp sub3

	sub_exit:
		mov sp, bp
		pop bp
		ret 6
subtraction endp

;--умножение---------------------------------------------------

multiplication proc
	push bp			
	mov bp, sp		
	mov di, [bp+4]		
	mov si, [bp+6]		
	mov bx, [bp+8]		
	mov cx, 0
	mov dx, 0
	mov cx, len1	
	mov dx, len2	
	add di, cx 		
	add si, dx		
	cmp great, 2			
	jne mul_next

    mul_swap:
	    xchg cx, dx
	    xchg di, si		

	mul_next: 
	    add bx, [bx]	
	    xor ax, ax		
	
	mul_loop1:
		or dx, dx	
		je mul_exit
		push bx	
		push di	
		push si			
		push cx			
		push dx				
		xor dx, dx 
		xor ax, ax

	mul_loop2:
		or cx, cx 
		je mul_finish
		mov al, byte ptr [di]	
        mul byte ptr [si]	
		add al, dh		
		div byte ptr [bp+10]	
		mov dh, al				
		mov al, byte ptr [bx]	 
		add al, ah		
		add al, dl		
		xor ah, ah
		div byte ptr [bp+10]	
		mov [bx], ah
		mov dl, al	
		dec di
		dec cx
		dec bx
		jmp mul_loop2

	mul_finish:
		xor ax, ax
		mov al, byte ptr [bx]
		add al, dh		
		add al, dl		
		div byte ptr [bp+10]	
		mov byte ptr [bx], ah
		mov byte ptr [bx-1], al
		pop dx			
		pop cx			
		pop si			
		pop di			
		pop bx	
		dec bx			
		dec si			
		dec dx
		jmp mul_loop1	
			
	mul_exit:
		mov sp, bp 
		pop bp     
		ret 6	   
multiplication endp

;--10---------------------------------------------------

start:	
    mov ax, data
    mov ds, ax
    
    push offset num1
    call input
    call endl
    
    push offset num2
    call input
    call endl

    mov bx, 0
    mov dx, offset num1 + 1
    push dx		
    call str_to_num
    mov sign1, bx
    mov len1, ax
    
    mov bx, 0
    mov dx, offset num2 + 1
    push dx		
    call str_to_num
    mov sign2, bx
    mov len2, ax

    cmp sign1, 0
    je spn
    cmp sign2, 0
    je snp
    jmp snn
    spn:
        cmp sign2, 0
        je spp
        push offset num2 + 3
        push offset num1 + 2
        call find_greater
        jmp sfinish

    snp:
        push offset num2 + 2
        push offset num1 + 3
        call find_greater
        jmp sfinish

    spp:
        push offset num2 + 2
        push offset num1 + 2 
        call find_greater
        jmp sfinish

    snn:
        push offset num2 + 3
        push offset num1 + 3
        call find_greater
        jmp sfinish

    sfinish:

;--сложение в 10---------------------------------------------------

    cmp sign1, 0
    je pn
    cmp sign2, 0
    je np
    jmp nn
    pn:
        cmp sign2, 0
        je np
        cmp great, 1
        je poll
        mov res_sign, 1
        push 10
        push offset add_res
        push offset num2 + 2
        push offset num1 + 1
        call subtraction
        jmp finish
        poll:
            push 10
            push offset add_res
            push offset num2 + 2
            push offset num1 + 1
            call subtraction
        jmp finish

    np:
        cmp sign1, 0
        je pp
        cmp great, 2
        je pol
        mov res_sign, 1
        push 10
        push offset add_res
        push offset num2 + 1
        push offset num1 + 2
        call subtraction
        jmp finish
        pol:
            push 10
            push offset add_res
            push offset num2 + 1
            push offset num1 + 2
            call subtraction
        jmp finish

    pp:
        push 10
        push offset add_res
        push offset num2 + 1 
        push offset num1 + 1
        call addition
        jmp finish

    nn:
        push 10
        push offset add_res
        push offset num2 + 2 
        push offset num1 + 2
        call addition
        mov res_sign, 1
        jmp finish

    finish:
    lea dx, msg1
    mov ah, 09h
    int 21h
    push offset add_res
    call print
    mov dx, offset output
    int 21h
    mov res_sign, 0

;--умножение в 10---------------------------------------------------

    cmp sign1, 0
    je mpn
    cmp sign2, 0
    je mnp
    jmp mnn
    mpn:
        cmp sign2, 0
        je mnp
        mov res_sign, 1
        push 10
        push offset mul_res
        push offset num1 + 1
        push offset num2 + 2
        call multiplication
        jmp mfinish

    mnp:
        cmp sign1, 0
        je mpp
        mov res_sign, 1
        push 10
        push offset mul_res
        push offset num1 + 2
        push offset num2 + 1
        call multiplication
        jmp mfinish

    mpp:
        push 10
        push offset mul_res
        push offset num2 + 1 
        push offset num1 + 1
        call multiplication
        jmp mfinish

    mnn:
        push 10
        push offset mul_res
        push offset num2 + 2 
        push offset num1 + 2
        call multiplication
        mov res_sign, 1
        jmp mfinish

    mfinish:

    
    lea dx, msg2
    mov ah, 09h
    int 21h
    push offset mul_res
    call print
    mov dx, offset output
    int 21h

;--16-------------------------------------------------------------
    
    mov base, 16
    
    push offset hnum1
    call input
    call endl
    
    push offset hnum2
    call input
    call endl

    mov bx, 0
    mov dx, offset hnum1 + 1
    push dx		
    call str_to_num
    mov sign1, bx
    mov len1, ax
    
    mov bx, 0
    mov dx, offset hnum2 + 1
    push dx		
    call str_to_num
    mov sign2, bx
    mov len2, ax

    cmp sign1, 0
    je hspn
    cmp sign2, 0
    je hsnp
    jmp hsnn
    hspn:
        cmp sign2, 0
        je hspp
        push offset hnum2 + 3
        push offset hnum1 + 2
        call find_greater
        jmp hsfinish

    hsnp:
        push offset hnum2 + 2
        push offset hnum1 + 3
        call find_greater
        jmp hsfinish

    hspp:
        push offset hnum2 + 2
        push offset hnum1 + 2 
        call find_greater
        jmp hsfinish

    hsnn:
        push offset hnum2 + 3
        push offset hnum1 + 3
        call find_greater
        jmp hsfinish

    hsfinish:

;--сложение в 16---------------------------------------------------

    cmp sign1, 0
    je hpn
    cmp sign2, 0
    je hnp
    jmp hnn
    hpn:
        cmp sign2, 0
        je hnp
        cmp great, 1
        je hpoll
        mov res_sign, 1
        push 16
        push offset hadd_res
        push offset hnum2 + 2
        push offset hnum1 + 1
        call subtraction
        jmp hfinish
        hpoll:
            push 16
            push offset hadd_res
            push offset hnum2 + 2
            push offset hnum1 + 1
            call subtraction
        jmp hfinish

   hnp:
        cmp sign1, 0
        je hpp
        cmp great, 2
        je hpol
        mov res_sign, 1
        push 16
        push offset hadd_res
        push offset hnum2 + 1
        push offset hnum1 + 2
        call subtraction
        jmp hfinish
        hpol:
            push 16
            push offset add_res
            push offset hnum2 + 1
            push offset hnum1 + 2
            call subtraction
        jmp hfinish

    hpp:
        push 16
        push offset hadd_res
        push offset hnum2 + 1 
        push offset hnum1 + 1
        call addition
        jmp hfinish

    hnn:
        push 16
        push offset hadd_res
        push offset hnum2 + 2 
        push offset hnum1 + 2
        call addition
        mov res_sign, 1
        jmp hfinish

    hfinish:
    lea dx, msg1
    mov ah, 09h
    int 21h
    push offset hadd_res
    call print
    mov dx, offset output
    int 21h
    mov res_sign, 0

;--умножение в 16---------------------------------------------------
   
    cmp sign1, 0
    je hmpn
    cmp sign2, 0
    je hmnp
    jmp hmnn
    hmpn:
        cmp sign2, 0
        je hmnp
        mov res_sign, 1
        push 16
        push offset hmul_res
        push offset hnum1 + 1
        push offset hnum2 + 2
        call multiplication
        jmp hmfinish

    hmnp:
        cmp sign1, 0
        je hmpp
        mov res_sign, 1
        push 16
        push offset hmul_res
        push offset hnum1 + 2
        push offset hnum2 + 1
        call multiplication
        jmp hmfinish

    hmpp:
        push 16
        push offset hmul_res
        push offset hnum2 + 1 
        push offset hnum1 + 1
        call multiplication
        jmp hmfinish

    hmnn:
        push 16
        push offset hmul_res
        push offset hnum2 + 2 
        push offset hnum1 + 2
        call multiplication
        mov res_sign, 1
        jmp hmfinish

    hmfinish:


    lea dx, msg2
    mov ah, 09h
    int 21h
    push offset hmul_res
    call print
    mov dx, offset output
    int 21h
    
    mov ah, 4ch
    int 21h
code ends
end start
