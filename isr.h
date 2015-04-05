//
// 2015/04/02 created
//
//  Interrupt Service Routine stuff
//


// struct describing the registers on the stack during an ISR 
// these registers are pushed by the assembler routines in bootstrap.S
typedef struct registers
{
   u32int gs, fs, es, ds;                  // Data segment selector
   u32int edi, esi, ebp, esp, ebx, edx, ecx, eax; // Pushed by pusha.
   u32int int_no, err_code;    // Interrupt number and error code 
   u32int eip, cs, eflags, useresp, ss; // Pushed by the processor automatically.
} registers_t;



// prototypes
void idt_init(void);



// These extern directives let us access the addresses of our ASM ISR handlers.
// extern void isr0 ();
// extern void isr31(); 
