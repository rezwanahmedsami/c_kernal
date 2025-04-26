# Makefile for building a custom x86 OS
# Designed for macOS with x86_64-elf toolchain

# Check if we're on macOS
UNAME_S := $(shell uname -s)
ifneq ($(UNAME_S),Darwin)
    $(error This Makefile is intended for macOS)
endif

# Directories
BUILD_DIR := build
BOOT_DIR := boot
KERNEL_DIR := kernel

# Tools - Using x86_64-elf toolchain
NASM := nasm
CC := x86_64-elf-gcc
LD := x86_64-elf-ld
QEMU := qemu-system-i386

# Flags - Targeting 32-bit output with minimal dependencies
NASM_FLAGS := -f elf32
CFLAGS := -m32 -fno-pie -ffreestanding -fno-builtin -nostdlib -Wall -Wextra
LDFLAGS := -m elf_i386 --oformat binary -Ttext 0x1000

# Files
KERNEL_C_SOURCES := $(wildcard $(KERNEL_DIR)/*.c)
KERNEL_C_OBJECTS := $(patsubst $(KERNEL_DIR)/%.c,$(BUILD_DIR)/%.o,$(KERNEL_C_SOURCES))
KERNEL_ASM_SOURCES := $(wildcard $(KERNEL_DIR)/*.asm)
KERNEL_ASM_OBJECTS := $(patsubst $(KERNEL_DIR)/%.asm,$(BUILD_DIR)/%.o,$(KERNEL_ASM_SOURCES))

# Default target
all: check_tools $(BUILD_DIR) $(BUILD_DIR)/os.img

# Check if required tools are installed
check_tools:
	@which $(NASM) >/dev/null 2>&1 || (echo "Error: nasm not found. Install with 'brew install nasm'"; exit 1)
	@which $(CC) >/dev/null 2>&1 || (echo "Error: x86_64-elf-gcc not found. Install cross-compiler toolchain"; exit 1)
	@which $(LD) >/dev/null 2>&1 || (echo "Error: x86_64-elf-ld not found. Install cross-compiler toolchain"; exit 1)
	@which $(QEMU) >/dev/null 2>&1 || (echo "Error: qemu not found. Install with 'brew install qemu'"; exit 1)

# Create build directory if it doesn't exist
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

# Compile C kernel files
$(BUILD_DIR)/%.o: $(KERNEL_DIR)/%.c
	$(CC) $(CFLAGS) -c $< -o $@

# Compile ASM kernel files
$(BUILD_DIR)/%.o: $(KERNEL_DIR)/%.asm
	$(NASM) $(NASM_FLAGS) $< -o $@

# Link kernel objects into kernel binary
$(BUILD_DIR)/kernel.bin: $(KERNEL_ASM_OBJECTS) $(KERNEL_C_OBJECTS)
	$(LD) $(LDFLAGS) -o $@ $^

# Compile bootloader
$(BUILD_DIR)/boot.bin: $(BOOT_DIR)/boot.asm
	$(NASM) -f bin $< -o $@

# Combine bootloader and kernel into disk image
$(BUILD_DIR)/os.img: $(BUILD_DIR)/boot.bin $(BUILD_DIR)/kernel.bin
	cat $^ > $@
	# Pad to floppy disk size (1.44MB)
	dd if=/dev/zero bs=1024 count=1440 >> $@ 2>/dev/null
	truncate -s 1474560 $@

# Run OS in QEMU
run: $(BUILD_DIR)/os.img
	$(QEMU) -fda $<

# Debug with QEMU and GDB
debug: $(BUILD_DIR)/os.img
	$(QEMU) -fda $< -s -S &
	x86_64-elf-gdb -ex "target remote localhost:1234" -ex "symbol-file $(BUILD_DIR)/kernel.bin"

# Clean build files
clean:
	rm -rf $(BUILD_DIR)

.PHONY: all check_tools run debug clean