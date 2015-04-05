/*
* 2015/04/01 created from various net examples
*   http://www.jamesmolloy.co.uk
*   http://www.osdever.net/bkerndev/Docs/isrs.htm
*
*/

#include "common.h"
#include "vgaconsole.h"
#include "isr.h"

extern void idt_load(int);
extern void halt(void);


// These extern directives let us access the addresses of our ASM ISR handlers.
extern void isr0 ();
extern void isr1 ();
extern void isr2 ();
extern void isr3 ();
extern void isr4 ();
extern void isr5 ();
extern void isr6 ();
extern void isr7 ();
extern void isr8 ();
extern void isr9 ();
extern void isr10 ();
extern void isr11 ();
extern void isr12 ();
extern void isr13 ();
extern void isr14 ();
extern void isr15 ();
extern void isr16 ();
extern void isr17 ();
extern void isr18 ();

extern void irq32(); 
extern void irq33(); 
extern void irq34(); 
extern void irq35(); 
extern void irq36(); 
extern void irq37(); 
extern void irq38(); 
extern void irq39(); 
extern void irq40(); 
extern void irq41(); 
extern void irq42(); 
extern void irq43(); 
extern void irq44(); 
extern void irq45(); 
extern void irq46(); 
extern void irq47(); 


// *******************************************
// GLOBAL DECLARATIONS
// *******************************************

// A struct describing an interrupt gate.
struct idt_entry
{
   u16int base_lo;             // The lower 16 bits of the address to jump to when this interrupt fires.
   u16int sel;                 // Kernel segment selector.
   u8int  always0;             // This must always be zero.
   u8int  flags;               // More flags. See documentation.
   u16int base_hi;             // The upper 16 bits of the address to jump to.
}  __attribute__((packed));

struct idt_entry idt_entries[256];

// typedef struct idt_entry_struct idt_entry_t;


// A struct describing a pointer to an array of interrupt handlers.
// This is in a format suitable for giving to 'lidt'.
struct idtptr
{
   u16int limit;
   u32int base;                // The address of the first element in our idt_entry_t array
}  __attribute__((packed));
// typedef struct idt_ptr_struct idt_ptr_t;

struct idtptr idt_ptr;
int idt_list[2048];
int idt_count=0;
int exception_interrupt=0;
int exception_no=999;


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
// long  i, d;
// char blankline[]="                                    ";

// if (regs.int_no == 0) {
//     d = 100;
//    } else{
//         d = 5000;
//     }
// 
// for(i=0;i<=d; i++){
//   vga_goto(10,0);
//    vga_writestring("INTERRUPT: ");
//    vga_writenumber(regs.int_no);
//   vga_writestring("   ");
// }
// vga_goto(10,0);
// vga_writestring(blankline);
// vga_goto(3,0);

    exception_interrupt=1;
    exception_no = regs.int_no;

    if(idt_count <= 2040) {
       idt_list[idt_count++] = regs.int_no;
    }
    if(regs.int_no == 8) {
        vga_writestring("Double!!!!!!");
        halt();
    }  
}


// Routine for all Hardware Interrupts (IRQs)
// This gets called from our ASM interrupt handler stub.
void irq_handler(registers_t *r)
{
// This is a blank function pointer
void (*handler)(registers_t *r);

   vga_goto(12,0);
   vga_writestring("HARDWARE INTERRUPT: ");
   vga_writenumber(r->int_no);
   vga_writestring("   ");

    // if we have a custom handler this IRQ, run it
    handler = irq_routines[r->int_no - 32];
    if (handler)
    {
        handler(r);
    }

    // If the IDT entry that was invoked was greater than 40
    //  (meaning IRQ8 - 15), then we need to send an EOI to
    //  the slave controller
    if (r->int_no >= 40)
    {
        outportb(0xA0, 0x20);
    }

    // In either case, we need to send an EOI to the master
    //  interrupt controller too
    outportb(0x20, 0x20);
}

// Most of the compiler support routines used by GCC are present in libgcc, but
// there are a few exceptions. GCC requires the freestanding environment
// provide memcpy, memmove, memset and memcmp. 
void memset(void *s, int c, int n)
{
int i;

    for(i=0; i<=n;i++) {
       *((unsigned char*)s)=(unsigned char)c;
    }
}  //end

// static void idt_set_gate(u8int num, u32int base, u16int sel, u8int flags)
void idt_set_gate(u8int num, u32int base, u16int sel, u8int flags)
{
   idt_entries[num].base_lo = base & 0xFFFF;
   idt_entries[num].base_hi = (base >> 16) & 0xFFFF;

   idt_entries[num].sel     = sel;
   idt_entries[num].always0 = 0;
   // We must uncomment the OR below when we get to using user-mode.
   // It sets the interrupt gate's privilege level to 3.
   idt_entries[num].flags   = flags /* | 0x60 */;
} 


// static void idt_init(void)
void idt_init(void)
{
   idt_ptr.limit = 48*8-1;
   idt_ptr.base  = (u32int)&idt_entries;

   memset(&idt_entries, 0, sizeof(struct idt_entry)*256);

   idt_set_gate( 0, (u32int)isr0 , 0x08, 0x8E);
   idt_set_gate( 1, (u32int)isr1 , 0x08, 0x8E);
   idt_set_gate( 2, (u32int)isr2 , 0x08, 0x8E);
   idt_set_gate( 3, (u32int)isr3 , 0x08, 0x8E);
   idt_set_gate( 4, (u32int)isr4 , 0x08, 0x8E);
   idt_set_gate( 5, (u32int)isr5 , 0x08, 0x8E);
   idt_set_gate( 6, (u32int)isr6 , 0x08, 0x8E);
   idt_set_gate( 7, (u32int)isr7 , 0x08, 0x8E);
   idt_set_gate( 8, (u32int)isr8 , 0x08, 0x8E);
   idt_set_gate( 9, (u32int)isr9 , 0x08, 0x8E);
   idt_set_gate( 10, (u32int)isr10 , 0x08, 0x8E);
   idt_set_gate( 11, (u32int)isr11 , 0x08, 0x8E);
   idt_set_gate( 12, (u32int)isr12 , 0x08, 0x8E);
   idt_set_gate( 13, (u32int)isr13 , 0x08, 0x8E);
   idt_set_gate( 14, (u32int)isr14 , 0x08, 0x8E);
   idt_set_gate( 15, (u32int)isr15 , 0x08, 0x8E);
   idt_set_gate( 16, (u32int)isr16 , 0x08, 0x8E);
   idt_set_gate( 17, (u32int)isr17 , 0x08, 0x8E);
   idt_set_gate( 18, (u32int)isr18 , 0x08, 0x8E);
  
   idt_set_gate(32, (u32int)irq32, 0x08, 0x8E);
   idt_set_gate(33, (u32int)irq33, 0x08, 0x8E);
   idt_set_gate(34, (u32int)irq34, 0x08, 0x8E);
   idt_set_gate(35, (u32int)irq35, 0x08, 0x8E);
   idt_set_gate(36, (u32int)irq36, 0x08, 0x8E);
   idt_set_gate(37, (u32int)irq37, 0x08, 0x8E);
   idt_set_gate(38, (u32int)irq38, 0x08, 0x8E);
   idt_set_gate(39, (u32int)irq39, 0x08, 0x8E);
   idt_set_gate(40, (u32int)irq40, 0x08, 0x8E);
   idt_set_gate(41, (u32int)irq41, 0x08, 0x8E);
   idt_set_gate(42, (u32int)irq42, 0x08, 0x8E);
   idt_set_gate(43, (u32int)irq43, 0x08, 0x8E);
   idt_set_gate(44, (u32int)irq44, 0x08, 0x8E);
   idt_set_gate(45, (u32int)irq45, 0x08, 0x8E);
   idt_set_gate(46, (u32int)irq46, 0x08, 0x8E);
   idt_set_gate(47, (u32int)irq47, 0x08, 0x8E);

   idt_load((u32int)&idt_ptr);

}


