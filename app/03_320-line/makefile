RC=riscv64-unknown-elf
LB=-nostartfiles -nostdlib -nodefaultlibs -ffunction-sections

all: comp dump run
comp:
	$(RC)-gcc -march=rv32im_zicsr -mabi=ilp32 -Os -flto $(LB) -I.. -T ../linker.ld ../crt.s main.c -o main.elf -lgcc -Wl,-Map=main.map
	$(RC)-objcopy -O binary main.elf main.bin
dump:
	$(RC)-objdump -S main.elf > dump.lst
run:
	../../cemu/main main.bin
