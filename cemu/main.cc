#include "qblib.h"
#define MAX_MEM 0xFFFFF

Uint8* mem;
Uint32 pc;
Uint32 regs[32];

#include "routines.cc"

int main(int argc, char** argv)
{
    screen(3);
    init(argc, argv);

    for (int i = 0; i <= 0x30; i += 4) { disasm(i); printf("%04x :: %s\n", i, ds); }

    while (loop()) { }

    free(mem);
    return quit();
}
