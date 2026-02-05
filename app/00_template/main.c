#include <io.h>

void main()
{
    heaph(vm,0xB8000);

    char *str = "Hello World!";

    while (*str) {

        *vm = (*str | 0x1700);
        str++;
        vm++;
    }
}
