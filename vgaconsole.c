//
// 2014/04/01 created from net
//


#include <stdbool.h> /* C doesn't have booleans by default. */
#include <stddef.h>
#include <stdint.h>
 
/* Check if the compiler thinks if we are targeting the wrong operating system. */
#if defined(__linux__)
#error "You are not using a cross-compiler, you will most certainly run into trouble"
#endif
 
/* This tutorial will only work for the 32-bit ix86 targets. */
#if !defined(__i386__)
#error "This tutorial needs to be compiled with a ix86-elf compiler"
#endif

#include "vgaconsole.h"
 
static const size_t VGA_WIDTH = 80;
static const size_t VGA_HEIGHT = 25;
 
uint8_t make_color(enum vga_color fg, enum vga_color bg)
{
	return fg | bg << 4;
}
 
uint16_t make_vgaentry(char c, uint8_t color)
{
	uint16_t c16 = c;
	uint16_t color16 = color;
	return c16 | color16 << 8;
}
 
size_t strlen(const char* str)
{
	size_t ret = 0;
	while ( str[ret] != 0 )
		ret++;
	return ret;
}
 
 
size_t vga_row;
size_t vga_column;
uint8_t vga_color;
uint16_t* vga_buffer;
 
void vga_init(void)
{
	vga_row = 0;
	vga_column = 0;
	vga_color = make_color(COLOR_LIGHT_GREY, COLOR_BLACK);
	vga_buffer = (uint16_t*) 0xB8000;
	for ( size_t y = 0; y < VGA_HEIGHT; y++ )
	{
		for ( size_t x = 0; x < VGA_WIDTH; x++ )
		{
			const size_t index = y * VGA_WIDTH + x;
			vga_buffer[index] = make_vgaentry(' ', vga_color);
		}
	}
}
 
void vga_setcolor(uint8_t color)
{
	vga_color = color;
}
 
void vga_putentryat(char c, uint8_t color, size_t x, size_t y)
{
	const size_t index = y * VGA_WIDTH + x;
	vga_buffer[index] = make_vgaentry(c, color);
}
 
void vga_putchar(char c)
{
    if(c == '\n') {
        vga_column=0;
        if ( ++vga_row == VGA_HEIGHT ) {
            vga_init();
        } 
    }
    else {
        vga_putentryat(c, vga_color, vga_column, vga_row);
        if ( ++vga_column == VGA_WIDTH ) {
            vga_column = 0;
            if ( ++vga_row == VGA_HEIGHT ) {
                vga_row = 0;
            }
        }
    }
}
 
void vga_writestring(const char* data)
{
	size_t datalen = strlen(data);
	for ( size_t i = 0; i < datalen; i++ )
		vga_putchar(data[i]);
}
 
void vga_writenumber(int n)
{
unsigned char nl;
unsigned char nh;
    nl = n & 0x000f;
    nh = (n & 0x00f0)>>4;
    if (nl <= 9)
        nl=nl+48;
    else
        nl=nl+55;

    if (nh <= 9)
        nh=nh+48;
    else
        nh=nh+55;
   
    vga_putchar(48);    // 0 zero
    vga_putchar(120);    // x
    vga_putchar(nh);    // high byte
    vga_putchar(nl);    // low byte

} 

void vga_goto(int x, int y)
{
    vga_row = x;
    vga_column = y;
}
