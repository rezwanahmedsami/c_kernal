; kernel_entry.asm
[bits 32]
[extern main]           ; Declare that we will be referencing the external symbol 'main'
global _start

section .text
_start:
    call main           ; Call our main() kernel function
    jmp $               ; Infinite loop if kernel returns