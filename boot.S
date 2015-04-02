;
;
; 2009/05/14 created
;		-first test of a boot loader: startup, print a message, and quit
; 2015/05/17 added memory dump and jump to "hello world" kernel

%define	BOOTSEG     0x07C0		; memory segment load address for the boot code
%define BOOT_ADDR   0x7c00
%define	LOADSEG     0x0800		; memory segment load address for the kernel code
%define LOAD_ADDR   0x8000
%define BOOTPARMS   0x0500
%define drive       BOOTPARMS+0  ; boot parm addr to save drive 

[bits 16]
[org 0x7c00]
	jmp start

;*********************************
; startup message
msg:	db 0x0D, 0x0A, "Loading......", 0x0D, 0x0A, 0x00


start:
	cli                 ; clear interrupts while setting up stack

	mov ax, 0x9000		; init the stack to $9ffff (9000:ffff)
	mov ss, ax
	mov sp, 0x0100   

    mov ax,0             ; set data segment 
    mov ds,ax

    mov [drive],dl      ; save doot drive(0x00=floppy 0x80=HD)

	mov si, msg
	call print_str

; display memory at start of the boot code location
    mov si,BOOT_ADDR      
    call memdump

; display memory at start of the load buffer location
    mov si,LOAD_ADDR   
    call memdump

	call loadk	    	    ; load my kernel

    mov si,LOAD_ADDR
    call memdump            ; dump memory to ensure things loaded correctly

    jmp LOADSEG:0x0000


; *********************************************************************
;  load kernel from disk 
;
loadk:
	mov ax,0		    ; reset drive ah=0
	mov dl,[drive]		; drive 
	int 0x13
	jc  .readerr


	mov ax, LOADSEG		; load location (es:bx)
	mov es, ax
	mov bx,0

.read:
	mov dl,[drive]		; drive=floppy
	mov dh,0		    ; head=0
;	mov cl,2		    ; sector=2
;	mov ch,0		    ; cylinder=0
    mov cx,0x0002
	mov al,4		    ; kernal code sectors
	mov ah,2		    ; read sector 
	int 0x13
	jc  .readerr
	ret	

    mov al,0x21         ; error print 
    call outch
    mov al,0x21         ; error print !! and stop
    call outch
.readerr:
    jmp .readerr
 


; *********************************************************************
;  dump 16 bytes of memory at load location 
;
memdump:
    mov ecx, 0          ; loop counter

mdumploop:
    mov eax, 0 
    lodsb
    push ecx
    call print_byte
    mov al,0x20         ; space
    call outch
    pop ecx
    inc ecx
    cmp ecx, 16
    jne mdumploop
    mov al,0x0d         ; cr/lf 
    call outch
    mov al,0x0a
    call outch
    ret

; *********************************************************************
;  print NULL terminated string
;
print_str:
msgloop:
	lodsb			; load one byte of the message
	cmp al,0		; if byte==null we are all done
	je .done
	call outch
    jmp msgloop
.done:
	ret

; *********************************************************************
;  print byte in hex
;   -print byte in ax register
;
print_byte:
    push ax
    shr ax,4
    call print_nibble
    pop ax
    call print_nibble
    ret

; *********************************************************************
;  print nibble in hex 
;       -print lower nibble in ax register
;
print_nibble:
        and al,0x0F
        cmp al,9            ; if (al <=9) 
        jle  add30          ;   then al=al+30
        add al,7            ;   else al=al+7+30
add30:
        add al,0x30
        call outch
        ret


; *********************************************************************
;  output character 
;
outch:
	mov ah,0x0E		; write tty mode
	mov bh,0x00		; not sure if we need this but set output page
	mov bl,0x07		; not sure if we need this but set char attribute=white
	int 0x10
	ret

; *********************************************************************
; not used any more 
pause:
; pause for key
    mov ah,0
    int 0x16
    ret
    


; this fancy magic puts the boot record signature in the last two bytes
boot_flag:
	times 510-($-$$) db 0	; $=position at start of the line
                            ; $$=beginning of the current section
	dw 0xAA55
