RC=riscv64-unknown-elf
LB=-nostartfiles -nostdlib -nodefaultlibs

all: comp dump run
comp:
	$(RC)-gcc -march=rv32im_zicsr -mabi=ilp32 -Os $(LB) -I.. -T ../linker.ld ../crt.s main.c -o main.elf -lgcc
	$(RC)-objcopy -O binary main.elf main.bin
dump:
	$(RC)-objdump -S main.elf > dump.lst
run:
	../../cemu/main main.bin
