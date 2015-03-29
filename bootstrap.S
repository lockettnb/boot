#
# 2015/03/23 bare bones from OSDev
#

.code16

.extern  kernel_main

# The linker script specifies _start as the entry point to the kernel and the
# bootloader will jump to this position once the kernel has been loaded. 
#    .section .text
    .global _start

_start:


# show that we have arrived with a double **
    mov $0x2a,%al
    call outch
    mov $0x2a,%al
    call outch

# open the A20 gate 
    # switch A20 gate via fast A20 port 92
#    in $0x93,%al
#    or $2,%al               # set A20 Gate bit 1
#    and $1,%al              # clear INIT_NOW bit
#    out %al, $0x92


# enable protected mode    
#    cli
    mov $0,%ax
    mov %ax,%ds
#    nop
#    sgdt gdtsave
#    nop
    lgdt gdtptr 
#    nop
#    sgdt gdtsave
    nop

    mov  %cr0,%eax
    or   $1,%ax
    mov  %eax,%cr0
	ljmp $8,$init32		# To 32-bit code
    nop

# *********************************************************************
#  output character 
#
outch:
    mov $0x0e,%ah     # write tty mode
    mov $0,%bh     # not sure if we need this but set output page
    mov $7,%bl     # not sure if we need this but set char attribute=white
    int $0x10
    ret


.code32

init32:
    nop
    mov $0x10,%ax             # data segment is offset 0x10 in the GDT table
    mov %ax,%es
    mov %ax,%fs
    mov %ax,%gs
    mov %ax,%ss
    mov %ax,%ds
    nop
                            # kernel code was loaded at address 0x008000

    mov $0x9F000,%esp       # Stack begins filling at this address

# call kernel_main in C code 
    call kernel_main



#************************************
# print byte on screen
#
# choutvid:
#     push eax
#     push ebx
#     and ax, 0x0fff     ; background=black(bits 12-15=0) foreground=white(bit8-11=15)
#     mov ebx, [video_pointer]
#     mov [ebx], ax
#     inc ebx
#     mov [video_pointer], ebx
#     pop ebx
#     pop eax
#     ret

# .section .data

.p2align 4, 0xaa
gdtsave:
    .long 0x12345678               # current location in video screen

video_pointer:
    .long 0xb8000               # current location in video screen

#*********************************
#* Global Descriptor Table (GDT) *
#*********************************
.p2align 4

gdt_start:
 NULL_DESC:
    .word 0
    .word 0
    .word 0
    .word 0

 CODE_DESC:
    .word 0xFFFF       # limit low
    .word 0            # base low
   .byte 0            # base middle
#   10011010b    # access
    .byte 0x9a
#    11001111b    # granularity
    .byte 0xcf
    .byte 0            # base high

 DATA_DESC:
    .word 0xFFFF       # data descriptor
    .word 0            # limit low
    .byte 0            # base low
#    .byte 10010010b    # access
    .byte 0x92
#    .byte 11001111b    # granularity
    .byte 0xcf
    .byte 0            # base high
gdt_end:

gdtptr:
    .word gdt_end-gdt_start         # length of GDT
    .word gdt_start
    .word 0x0




