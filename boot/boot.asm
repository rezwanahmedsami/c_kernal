; boot.asm - A simple bootloader
[bits 16]               ; We're in 16-bit Real Mode
[org 0x7c00]            ; BIOS loads us at 0x7C00

KERNEL_OFFSET equ 0x1000  ; Memory offset where we'll load our kernel

; BIOS Parameter Block
jmp short start
nop
times 33 db 0           ; BPB padding

start:
    mov [BOOT_DRIVE], dl ; BIOS stores boot drive in DL
    
    ; Set up stack
    mov bp, 0x9000
    mov sp, bp
    
    ; Clear screen
    mov ah, 0x00         ; Set video mode
    mov al, 0x03         ; 80x25 text mode
    int 0x10
    
    ; Print loading message
    mov si, MSG_REAL_MODE
    call print_string
    
    ; Load kernel from disk
    call load_kernel
    
    ; Switch to protected mode
    call switch_to_pm
    
    jmp $                ; Never executed - for safety

; Disk loading routine
load_kernel:
    mov si, MSG_LOAD_KERNEL
    call print_string
    
    mov ah, 0x02        ; BIOS read sector function
    mov al, 15          ; Read 15 sectors (adjust as needed)
    mov ch, 0           ; Cylinder 0
    mov cl, 2           ; Start from sector 2 (sector 1 is our bootloader)
    mov dh, 0           ; Head 0
    mov dl, [BOOT_DRIVE]
    mov bx, KERNEL_OFFSET
    int 0x13
    
    jc disk_error       ; Jump if error (carry flag set)
    
    cmp al, 15          ; BIOS sets al to the # of sectors read
    jne disk_error
    
    ret

disk_error:
    mov si, DISK_ERROR_MSG
    call print_string
    jmp $

; Print string routine
print_string:
    pusha
    mov ah, 0x0e        ; BIOS teletype function
.loop:
    lodsb               ; Load byte from SI into AL and increment SI
    test al, al         ; Check if character is 0 (end of string)
    jz .done
    int 0x10            ; Print character in AL
    jmp .loop
.done:
    popa
    ret

; GDT
gdt_start:
    ; Null descriptor
    dd 0x0
    dd 0x0
    
    ; Code segment descriptor
    dw 0xffff           ; Limit (0-15)
    dw 0x0              ; Base (0-15)
    db 0x0              ; Base (16-23)
    db 10011010b        ; Flags and access byte
    db 11001111b        ; Flags and limit (16-19)
    db 0x0              ; Base (24-31)
    
    ; Data segment descriptor
    dw 0xffff           ; Limit (0-15)
    dw 0x0              ; Base (0-15)
    db 0x0              ; Base (16-23)
    db 10010010b        ; Flags and access byte
    db 11001111b        ; Flags and limit (16-19)
    db 0x0              ; Base (24-31)
gdt_end:

; GDT descriptor
gdt_descriptor:
    dw gdt_end - gdt_start - 1  ; Size of GDT
    dd gdt_start                ; Address of GDT

; Define segment selectors
CODE_SEG equ 0x08      ; 8 bytes offset from start of GDT to code segment
DATA_SEG equ 0x10      ; 16 bytes offset from start of GDT to data segment

; Switch to protected mode
switch_to_pm:
    cli                 ; Turn off interrupts
    lgdt [gdt_descriptor] ; Load GDT
    
    ; Enable protected mode
    mov eax, cr0
    or eax, 0x1
    mov cr0, eax
    
    ; Far jump to 32-bit code
    jmp CODE_SEG:init_pm

[bits 32]
; Initialize registers and stack once in protected mode
init_pm:
    mov ax, DATA_SEG    ; Update segment registers
    mov ds, ax
    mov ss, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    
    mov ebp, 0x90000    ; Update stack position
    mov esp, ebp
    
    call KERNEL_OFFSET  ; Jump to the kernel!
    
; Data
BOOT_DRIVE db 0
MSG_REAL_MODE db "Started in 16-bit Real Mode", 0
MSG_LOAD_KERNEL db "Loading kernel into memory", 0
DISK_ERROR_MSG db "Disk read error!", 0

; Bootsector padding and signature
times 510-($-$$) db 0   ; Pad to 510 bytes
dw 0xaa55               ; Boot signature