/*
* 2015/04/01 created from various net examples
*   http://www.jamesmolloy.co.uk
*   http://www.osdever.net/bkerndev/Docs/isrs.htm
*
*/

#include "common.h"
#include "vgaconsole.h"

typedef struct registers
{
   u32int gs, fs, es, ds;                  // Data segment selector
   u32int edi, esi, ebp, esp, ebx, edx, ecx, eax; // Pushed by pusha.
   u32int int_no, err_code;    // Interrupt number and error code 
   u32int eip, cs, eflags, useresp, ss; // Pushed by the processor automatically.
} registers_t;


// array of function pointers to IRQ handlers
void *irq_routines[16] =
{
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0
};


// Inline assembly for I/O to ports
unsigned char inportb (unsigned short _port)
{
    unsigned char rv;
    __asm__ __volatile__ ("inb %1, %0" : "=a" (rv) : "dN" (_port));
    return rv;
}

void outportb (unsigned short _port, unsigned char _data)
{
    __asm__ __volatile__ ("outb %1, %0" : : "dN" (_port), "a" (_data));
}


/* This installs a custom IRQ handler for the given IRQ */
void irq_install_handler(int irq, void (*handler)(registers_t *r))
{
    irq_routines[irq] = handler;
}

/* This clears the handler for a given IRQ */
void irq_uninstall_handler(int irq)
{
    irq_routines[irq] = 0;
}


//************************************************************
// INTERRUPT SERVICE REQUEST Processing 
//************************************************************

// Routine for all the "Exception" interrupts.
// This gets called from our ASM interrupt handler stub.
void isr_handler(registers_t regs)
{
   vga_writestring("INTERRUPT: ");
   vga_writenumber(regs.int_no);
   vga_writestring("   ");
}


// Routine for all Hardware Interrupts (IRQs)
// This gets called from our ASM interrupt handler stub.
void irq_handler(registers_t *r)
{
// This is a blank function pointer
void (*handler)(registers_t*r);

    // if we have a custom handler this IRQ, run it
    handler = irq_routines[r->int_no - 32];
    if (handler)
    {
        handler(r);
    }

    /* If the IDT entry that was invoked was greater than 40
    *  (meaning IRQ8 - 15), then we need to send an EOI to
    *  the slave controller */
    if (r->int_no >= 40)
    {
        outportb(0xA0, 0x20);
    }

    /* In either case, we need to send an EOI to the master
    *  interrupt controller too */
    outportb(0x20, 0x20);
}

