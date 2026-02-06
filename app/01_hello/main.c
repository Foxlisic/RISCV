#include <io.h>

void main()
{
    heaph(vm,0xB8000);

    int i;
    char *str = " Hello World! ";

    // Очистить экран
    for (i = 0; i < 2000; i++) vm[i] = 0x1700;

    i = 80*12+32;
    while (*str) {

        vm[i++] = (*str | 0x3000);
        str++;
    }
}
