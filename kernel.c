//
//  2014/04/01 created from the net 
//
//
// #include <stdbool.h> /* C doesn't have booleans by default. */
// #include <stddef.h>
// #include <stdint.h>

#include "common.h" 
#include "vgaconsole.h"
#include "isr.h"

extern int exception_interrupt;
extern int exception_no;

/* Check if the compiler thinks if we are targeting the wrong operating system. */
#if defined(__linux__)
#error "You are not using a cross-compiler, you will most certainly run into trouble"
#endif
 
/* This tutorial will only work for the 32-bit ix86 targets. */
#if !defined(__i386__)
#error "This tutorial needs to be compiled with a ix86-elf compiler"
#endif
 

 
void kernel_main()
{
long i ;

    idt_init();

	vga_init();
	/* Since there is no support for newlines in vga_putchar yet, \n will
	   produce some VGA specific character instead. This is normal. */
	vga_writestring("Hello, kernel World!\n");
	vga_writestring("hhhhhhHello, kernel World!\n");
 
    while (1) {
        for(i=0; i<=500000000; i++) {
        }
        vga_writestring("...Idle \n"); 
    if(exception_interrupt) {
        vga_writestring(" Exception: ");
        vga_writenumber(exception_no);
        vga_writestring("\n"); 
        exception_interrupt=0;
    }
    
    }

}

