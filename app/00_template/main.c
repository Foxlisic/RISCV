#include <io.h>

static const char *str = "Hello World!";

void main()
{
    heaph(vm,0xB8000);

    while (*str) {

        *vm = (*str | 0x1700);
        str++;
        vm++;
    }
}
