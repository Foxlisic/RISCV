
all: asm ica cem
ica:
	iverilog -g2005-sv -DICARUS=1 -o main.qqq tb.v core.v
	vvp main.qqq > /dev/null
asm:
	riscv64-unknown-elf-as -march=rv32im -mabi=ilp32 -o test.o test.s
	riscv64-unknown-elf-ld -m elf32lriscv -Ttext 0x0 -o test.elf test.o
	riscv64-unknown-elf-objcopy -O binary test.elf test.bin
	riscv64-unknown-elf-objdump -S test.elf > test.lst
	hexdump -v -e '1/4 "%08x\n"' test.bin > tb.hex
	php c5/romer.php p test.bin c5/m256.mif
	rm test.o test.elf
cem:
	./cemu/main test.bin
vcd:
	gtkwave tb.vcd
wav:
	gtkwave tb.gtkw
clean:
	rm -r tb
