// Объявление разных региона памяти
#define heap(A,B,C) volatile unsigned A* B = (unsigned A*) C
#define heapb(A,B)  heap(char,A,B)
#define heaph(A,B)  heap(short,A,B)
#define heapw(A,B)  heap(int,A,B)
#define brk         asm("ebreak")

// Работа с CSR, reg-номер регистра CSR, val-значение на запись
#define csr_read(reg)       ({ unsigned int __v; asm volatile ("csrr %0,  " #reg : "=r"(__v)); __v; })
#define csr_swap(reg,val)   ({ unsigned int __v; asm volatile ("csrrw %0, " #reg ", %1" : "=r"(__v) : "rK" (val)); __v; })
#define csr_write(reg, val) asm volatile ("csrw " #reg ", %0" : : "rK"(val))
#define csr_set(reg, mask)  asm volatile ("csrs " #reg ", %0" : : "rK" (mask))
#define csr_clr(reg, mask)  asm volatile ("csrrc " #reg ", %0" : : "rK" (mask))
