#
# 2015/04/01 created from various examples on the net
#

# C-level ISR & IRQ interrupt handlers
.extern isr_handler
.extern irq_handler

# ISR entry point (added to the IDT table)

.global _isr0
.global _isr1
.global _isr2
.global _isr3
.global _isr4
.global _isr5
.global _isr6
.global _isr7
.global _isr8
.global _isr9
.global _isr10
.global _isr11
.global _isr12
.global _isr13
.global _isr14
.global _isr15
.global _isr16
.global _isr17
.global _isr18
.global _isr999

# to keep the stack consistant we add a null error code for
# IRQ's that do not push their own
.macro isr_noerror irqnum
    cli
    push 0
    push \irqnum 
    jmp isr_common
.endm

.macro isr_witherror irqnum
    cli
    push \irqnum 
    jmp isr_common
.endm

#   	DESCRIPTION 	                ERROR CODE
# 0 	Division By Zero Exception 	        No
# 1 	Debug Exception 	                No
# 2 	Non Maskable Interrupt Exception 	No
# 3 	Breakpoint Exception 	            No
# 4 	Into Detected Overflow Exception 	No
# 5 	Out of Bounds Exception 	        No
# 6 	Invalid Opcode Exception 	        No
# 7 	No Coprocessor Exception 	        No
# 8 	Double Fault Exception 	            Yes
# 9 	Coprocessor Seg Overrun Exception 	No
# 10 	Bad TSS Exception 	                Yes
# 11 	Segment Not Present Exception 	    Yes
# 12 	Stack Fault Exception 	            Yes
# 13 	General Protection Fault Exception 	Yes
# 14 	Page Fault Exception 	            Yes
# 15 	Unknown Interrupt Exception 	    No
# 16 	Coprocessor Fault Exception 	    No
# 17 	Alignment Check Exception (486+) 	No
# 18 	Machine Check Exception (Pent/586+)	No
# 19 to 31 	Reserved Exceptions 	        No
_isr0: isr_noerror 0
_isr1: isr_noerror 1
_isr2: isr_noerror 2
_isr3: isr_noerror 3
_isr4: isr_noerror 4
_isr5: isr_noerror 5
_isr6: isr_noerror 6
_isr7: isr_noerror 7
_isr8: isr_noerror 8
_isr9: isr_noerror 9
_isr10: isr_witherror 10 
_isr11: isr_witherror 11 
_isr12: isr_witherror 12 
_isr13: isr_witherror 13 
_isr14: isr_witherror 14 
_isr15: isr_noerror 15 
_isr16: isr_noerror 16 
_isr17: isr_noerror 17 
_isr18: isr_noerror 18 

# used for reserverd exceptions 19-31
_isr999: isr_noerror 999 

_isr32: isr_noerror 0x20 
_isr33: isr_noerror 0x21 
_isr34: isr_noerror 0x22 
_isr35: isr_noerror 0x23 
_isr36: isr_noerror 0x24 
_isr37: isr_noerror 0x25 
_isr38: isr_noerror 0x26 
_isr39: isr_noerror 0x27 
_isr40: isr_noerror 0x28 
_isr41: isr_noerror 0x29 
_isr42: isr_noerror 0x2a 
_isr43: isr_noerror 0x2b 
_isr44: isr_noerror 0x2c 
_isr45: isr_noerror 0x2d 
_isr46: isr_noerror 0x2e 
_isr47: isr_noerror 0x2f 

# Common ISR stub. 
#   saves the processor state
#   sets up for kernel mode segments
#   call the C-level fault handler
#   and finally restores the stack frame.
isr_common:
    pusha       # push eax, ecx, edx, ebx, esp, ebp, esi  

    push %ds
    push %es
    push %fs
    push %gs

    mov $0x10, %ax   # Load the Kernel Data Segment descriptor
    mov %ax, %ds
    mov %ax, %es
    mov %ax, %fs
    mov %ax, %gs

    call isr_handler

    pop %gs
    pop %fs
    pop %es
    pop %ds
    popa
    add $8,%esp     # Cleans up the pushed error code and pushed ISR number
    iret            # pops 5 things 


# In protected mode, the IRQs 0 to 7 conflict with the CPU exception which are
# reserved by Intel up until 0x1F. (It was an IBM design mistake.) Consequently
# it is difficult to tell the difference between an IRQ or an software error.
# It is thus recommended to change the PIC's offsets (also known as remapping
# the PIC) so that IRQs use non-reserved vectors. A common choice is to move
# them to the beginning of the available range (IRQs 0..0xF -> INT 0x20..0x2F).
# For that, we need to set the master PIC's offset to 0x20 and the slave's to
# 0x28. 
#        Line     interrupt  function
#        IRQ0      08        system timer
#        IRQ1      09        keyboard
#        IRQ2      0A        PC/XT: EGA vertical retrace or maybe available
#                            PC/AT: see explanation below
#        IRQ3      0B        COM2 or maybe available
#        IRQ4      0C        COM1
#        IRQ5      0D        PC/XT: hard disk drive
#                            PC/AT: LPT2 or maybe available
#        IRQ6      0E        floppy disk drive
#        IRQ7      0F        LPT1
#        IRQ8      70        PC/AT: CMOS Real Time Clock
#        IRQ9      71        PC/AT: see explanation below
#        IRQ10     72        PC/AT: probably available
#        IRQ11     73        PC/AT: probably available
#        IRQ12     74        PC/AT: probably available
#                            PS/2: mouse
#        IRQ13     75        PC/AT: numeric coprocessor
#        IRQ14     76        PC/AT: hard disk drive
#        IRQ15     77        PC/AT: probably available

.equ pic1,       0x20
.equ pic1_data,  0x21
.equ pic2,       0xa0
.equ pic2_data,  0xa1

irq_remap:
    in $pic1_data,%al       # Save master
    push %ax                # IMR
    in $pic2_data,%al      # Save slave
    push %ax                # IMR

    movb $0x11,%al          # ICW1 to
    outb %al,$pic1          # master
    outb %al,$pic2          # slave

    movb $20,%al            # ICW2 to
    outb %al,$pic1_data     # master
    movb $28,%al            # ICW2 to
    outb %al,$pic2_data     # slave

    movb $0x4,%al           # ICW3 to
    outb %al,$pic1_data     # master
    movb $0x2,%al           # ICW3 to
    outb %al,$pic2_data     # slave

    movb $0x1,%al           # ICW4 to
    outb %al,$pic1_data     # master
    outb %al,$pic2_data     # slave

    pop %ax                 # Restore slave
    outb %al,$0xa1          # IMR
    pop %ax                 # Restore master
    outb %al,$0x21          # IMR

# wtf why the w on call and ret
#     retw # To caller
    ret 



#**************************************************************
#**************************************************************
# Interrupt Gate Descriptor

# 63                      48|47           40|39              32
# +------------------------------------------------------------
# |                         | |D|D| | | | | | | | |
# | HANDLER OFFSET (16-31)  |P|P|P|0|1|1|1|0|0|0|0| RESERVED
# |                         | |L|L| | | | | | | | |
# =============================================================
#                           |                                 |
#   SEGMENT SELECTOR        |   HANDLER OFFSET (0-15)         |
#                           |                                 |
# ------------------------------------------------------------+
# 31                      16|15                               0
# 
#         - bits  0 to 15 : handler offset low
#         - bits 16 to 31 : segment selector
#         - bits 32 to 37 : reserved
#         - bits 37 to 39 : 0
#         - bits 40 to 47 : flags/type
#         - bits 48 to 63 : handler offset high

.section .data
#*********************************
#* Interrupt Descriptor Table (IDT) *
#*********************************
.p2align 4

idt_ptr:
    .word 0x800
    .word IDT_ADDR
    .word 0x0

idt_default:
    .word 0x1234 
    .word 0x8e
    .byte 0
    .byte 0x8
    .word 0x5678 

.long   _isr0
.long   _isr1
# type and attribute field 10001110 = 0x8e
# bit 7     P = 1 
# bit 5-6   DPL = 00
# bit 4     S = 0 for interrupt gates
# bit 0-3   Type = 0xe for 386 interrupt gate 
                                             

