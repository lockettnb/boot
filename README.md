# boot

This is a homebrew x86 bootloader.

boot.S
* Inital stage 1 boot loader installed as the disk's MBR
* responsible to load the kernal into memory
* There is no file system so it just loads disk sectors

bootstrap.S 
* stage 2 of the boot sequence
* initialization code to config and startup the C-level kernal code
* turns on A20 address via the Keyboard PIC
* switchs to Protected Mode
    -has the GDT table included as data table
* remaps the PIC IRQ's so the do not conflict with CPU exceptions
* calls C-level kernel "main"
* contains the ISR handlers for software execptions and hardware interrupts
    -these service routines set up the stack and call C-level handlers

kernel.c
* do nothing kernal, prints message to screen and loops forever
* uses VGA console routines from vgaconsole.c
* contains the ISR handlers for both software exceptions and hardware interrupts
