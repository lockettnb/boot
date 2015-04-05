#
# 2015/04/01 created from various examples on the net
#

.equ BOOTPARMS, 0x0500
.equ BP_DRIVE,  BOOTPARMS+0
.equ BP_GDTPTR, BOOTPARMS+4
.equ BP_IDTPTR, BOOTPARMS+8
.equ BP_ISR,    BOOTPARMS+12 
.equ BP_IRQ,    BOOTPARMS+16 

# C-level ISR & IRQ interrupt handlers
.extern isr_handler
.extern irq_handler

#  Allows the C code to call idt_load().
.global idt_load
.global halt 

# C-level routine will add all these addresses to the IDT
.global isr0
.global isr1
.global isr2
.global isr3
.global isr4
.global isr5
.global isr6
.global isr7
.global isr8
.global isr9
.global isr10
.global isr11
.global isr12
.global isr13
.global isr14
.global isr15
.global isr16
.global isr17
.global isr18
.global isr999

.global irq32
.global irq33
.global irq34
.global irq35
.global irq36
.global irq37
.global irq38
.global irq39
.global irq40
.global irq41
.global irq42
.global irq43
.global irq44
.global irq45
.global irq46
.global irq47

# to keep the stack consistant we add a null error code for
# IRQ's that do not push their own
.macro isr_noerror isrnum
    cli
    push $0x12345678
    push $\isrnum 

    push %eax
    mov $\isrnum, %eax
    mov %eax, (BP_ISR)
    pop %eax

    jmp isr_common
.endm

.macro isr_witherror isrnum
    cli
    push $\isrnum 

    push %eax
    mov $\isrnum, %eax
    mov %eax, (BP_ISR)
    pop %eax

    jmp isr_common
.endm

.macro irq_noerror irqnum
    cli
    push $0xc1c2c3c4
    push $\irqnum 

    push %eax
    mov $\irqnum, %eax
    mov %eax, (BP_IRQ)
    pop %eax

    jmp irq_common
.endm
# Software Exceptions 
#
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
isr0: isr_noerror 0
isr1: isr_noerror 1
isr2: isr_noerror 2
isr3: isr_noerror 3
isr4: isr_noerror 4
isr5: isr_noerror 5
isr6: isr_noerror 6
isr7: isr_noerror 7
isr8: isr_noerror 8
isr9: isr_noerror 9
isr10: isr_witherror 10 
isr11: isr_witherror 11 
isr12: isr_witherror 12 
isr13: isr_witherror 13 
isr14: isr_witherror 14 
isr15: isr_noerror 15 
isr16: isr_noerror 16 
isr17: isr_noerror 17 
isr18: isr_noerror 18 

# used for reserverd exceptions 19-31 (0x13-0x1f)
isr999: isr_noerror 999 

# Hardware Interrupts (IRQ's)
#
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
irq32: irq_noerror 0x20 
irq33: irq_noerror 0x21 
irq34: irq_noerror 0x22 
irq35: irq_noerror 0x23 
irq36: irq_noerror 0x24 
irq37: irq_noerror 0x25 
irq38: irq_noerror 0x26 
irq39: irq_noerror 0x27 
irq40: irq_noerror 0x28 
irq41: irq_noerror 0x29 
irq42: irq_noerror 0x2a 
irq43: irq_noerror 0x2b 
irq44: irq_noerror 0x2c 
irq45: irq_noerror 0x2d 
irq46: irq_noerror 0x2e 
irq47: irq_noerror 0x2f 

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


# Common IRQ stub. 
#   saves the processor state
#   sets up for kernel mode segments
#   call the C-level fault handler
#   and finally restores the stack frame.
irq_common:
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

    call irq_handler

    pop %gs
    pop %fs
    pop %es
    pop %ds
    popa
    add $8,%esp     # Cleans up the pushed error code and pushed ISR number
    iret            # pops 5 things 



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

    ret 

#***********************************************
idt_load:
   mov 4(%esp), %eax      #  Get the pointer to the IDT, passed as a param
   lidt (%eax)              # Load the IDT pointer.
   sti
   ret

# *********************************************
halt:
    cli
    nop
    hlt
    nop
    jmp halt
