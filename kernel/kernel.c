/* kernel.c - A minimal kernel */

/* Define our own fixed-width integer types since we can't use stdint.h with -nostdinc */
typedef unsigned char  uint8_t;
typedef unsigned short uint16_t;
typedef unsigned int   uint32_t;
typedef unsigned long  uint64_t;

typedef signed char  int8_t;
typedef signed short int16_t;
typedef signed int   int32_t;
typedef signed long  int64_t;

// Video memory pointer
volatile uint16_t* video_memory = (uint16_t*)0xB8000;
// VGA color constants
#define VGA_BLACK         0
#define VGA_BLUE          1
#define VGA_GREEN         2
#define VGA_CYAN          3
#define VGA_RED           4
#define VGA_MAGENTA       5
#define VGA_BROWN         6
#define VGA_LIGHT_GREY    7
#define VGA_DARK_GREY     8
#define VGA_LIGHT_BLUE    9
#define VGA_LIGHT_GREEN   10
#define VGA_LIGHT_CYAN    11
#define VGA_LIGHT_RED     12
#define VGA_LIGHT_MAGENTA 13
#define VGA_LIGHT_BROWN   14
#define VGA_WHITE         15

// Screen dimensions
#define VGA_WIDTH  80
#define VGA_HEIGHT 25

// Create a VGA color byte from foreground and background colors
uint8_t vga_entry_color(uint8_t fg, uint8_t bg) {
    return fg | (bg << 4);
}

// Create a VGA character entry from character and color
uint16_t vga_entry(unsigned char c, uint8_t color) {
    return (uint16_t)c | ((uint16_t)color << 8);
}

// Clear the screen
void clear_screen() {
    uint8_t color = vga_entry_color(VGA_WHITE, VGA_BLACK);
    uint16_t blank = vga_entry(' ', color);
    
    for (int i = 0; i < VGA_WIDTH * VGA_HEIGHT; i++) {
        video_memory[i] = blank;
    }
}

// Print a string at specific position with color
void print_at(const char* str, int x, int y, uint8_t color) {
    int offset = y * VGA_WIDTH + x;
    
    for (int i = 0; str[i] != '\0'; i++) {
        video_memory[offset++] = vga_entry(str[i], color);
    }
}

// Simple port I/O functions
void outb(uint16_t port, uint8_t value) {
    asm volatile ("outb %0, %1" : : "a"(value), "Nd"(port));
}

uint8_t inb(uint16_t port) {
    uint8_t ret;
    asm volatile ("inb %1, %0" : "=a"(ret) : "Nd"(port));
    return ret;
}

// Main kernel function
void main() {
    // Clear the screen
    clear_screen();
    
    // Print welcome message
    uint8_t color = vga_entry_color(VGA_LIGHT_GREEN, VGA_BLACK);
    print_at("Welcome to MyOS!", 30, 10, color);
    print_at("Custom x86 Kernel successfully loaded!", 20, 12, color);
    
    // Initialize features
    // TODO: Add kernel features like IDT, GDT, etc.
    
    // Halt the CPU
    while(1) {
        asm volatile("hlt");
    }
}