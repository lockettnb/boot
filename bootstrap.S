#
# 2015/03/23 bare bones from OSDev
# 2015/03/31 converted to gas format and added GDT/IDT stuff
#

.equ BOOTPARMS, 0x0500
.equ BP_DRIVE,  BOOTPARMS+0
.equ BP_GDTPTR, BOOTPARMS+4
.equ BP_IDTPTR, BOOTPARMS+8

.equ GDT_ADDR,  0x0600
.equ IDT_ADDR,  0x0700

.code16
.extern  kernel_main
# .extern  isr_default_handler

# The linker script specifies _start as the entry point to the kernel and the
# bootloader will jump to this position once the kernel has been loaded. 
#    .section .text
    .global _start

_start:
# set the data/extra segments to known value 0x0000
    mov $0,%ax
    mov %ax,%ds
    mov %ax,%es

# show that we have arrived by printing a double star **
    mov $0x2a,%al
    call outch
    mov $0x2a,%al
    call outch

# move the GDT to lower memory location
    call gdtmove

# open the A20 gateA
#   code from freeBSD boot1.S
seta20:
    cli
    xor %cx,%cx

seta20.1:
    dec %cx                 # Timeout?
    jz seta20.3             # Yes
    inb $0x64,%al           # Get status
    testb $0x2,%al          # Busy?
    jnz seta20.1            # Yes
    movb $0xd1,%al          # Command: Write
    outb %al,$0x64          #  output port
seta20.2:
   inb $0x64,%al           # Get status
    testb $0x2,%al          # Busy?
    jnz seta20.2            # Yes
    movb $0xdf,%al          # Enable
    outb %al,$0x60          #  A20
seta20.3:
    sti             # Enable interrupts


# enable protected mode
    lgdt (BP_GDTPTR) 
    nop
    sgdt gdtsave
    nop

    mov  %cr0,%eax
    or   $1,%ax
    mov  %eax,%cr0
    ljmp $8,$init32     # To 32-bit code
    nop

# *****************************************
# relocate GDT table and pointer

# copy GDT pointer to Boot Parm section
gdtmove:
    mov $gdtptr,%si
    mov $BP_GDTPTR,%di
    xor %ecx,%ecx
    mov $6,%cx
.gdtmove1:
    lodsb
    stosb
    loop   .gdtmove1
    nop

# copy GDT table to GDT section
    mov $gdt_start,%si
    mov $GDT_ADDR,%di
    xor %ecx,%ecx
    mov (gdtptr),%cx
.gdtmove2:
    lodsb
    stosb
    loop   .gdtmove2
    nop
    ret


# ***********************************************
#  output character

outch:
    mov $0x0e,%ah  # write tty mode
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

    mov $0x9ffff,%esp       # Top of Stack 

# remap the IRQ's via the PIC and set up interrupt IDT table 
#    call idtmove
    call irq_remap
    
# call kernel_main in C code 
    call kernel_main

#
# ************************************
# interrupt service request functions
.include "isr.S"

#*********************************
#*********************************
#*********************************
.section .data

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
#   10011010b          # access
    .byte 0x9a
#    11001111b         # granularity
    .byte 0xcf
    .byte 0            # base high

 DATA_DESC:
    .word 0xFFFF       # data descriptor
    .word 0            # limit low
    .byte 0            # base low
#    .byte 10010010b   # access
    .byte 0x92
#    .byte 11001111b   # granularity
    .byte 0xcf
    .byte 0            # base high
gdt_end:

gdtptr:
    .word gdt_end-gdt_start         # length of GDT
    .word gdt_start
    .word 0x0

