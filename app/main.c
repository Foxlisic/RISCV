__attribute__((section(".text.entry")))
void _start()
{
    asm("li sp, 0x10000");

    char *str = "Hello World!";
    volatile unsigned short * uart = (unsigned short *) 0xB8000;

    while (*str) { *uart = (*str | 0x1700); str++; uart++; }
}
