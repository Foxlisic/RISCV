RC=riscv64-unknown-elf
all: comp dump
comp:
	$(RC)-gcc -march=rv32i -mabi=ilp32 -nostdlib -T linker.ld -Os main.c -o main.elf
	$(RC)-objcopy -O binary main.elf main.bin
dump:
	$(RC)-objdump -S main.elf > dump.lst
