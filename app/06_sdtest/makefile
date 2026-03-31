RC=riscv64-unknown-elf
LB=-nostartfiles -nostdlib -nodefaultlibs -ffunction-sections  -ffreestanding

all: comp dump run
comp:
	$(RC)-gcc -march=rv32im -mabi=ilp32 -Os -flto $(LB) -I.. -T ../linker.ld ../crt.s main.cc -o main.elf -lgcc -Wl,-Map=main.map
	$(RC)-objcopy -O binary main.elf main.bin
	php ../../c5/romer.php p main.bin ../../c5/m256.mif
dump:
	$(RC)-objdump -S main.elf > dump.lst
run:
	../../cemu/main main.bin
clean:
	rm -f main.elf main.map main.bin dump.lst
