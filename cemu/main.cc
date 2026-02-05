#include "qblib.h"
#define MAX_MEM 0xFFFFF

Uint8* mem;
Uint32 pc;
Uint32 regs[32], pregs[32];
Uint32 csr[4096];

#include "routines.cc"

int main(int argc, char** argv)
{
    int wherei = 0;

    screen(3);
    init(argc, argv);

    // По умолчанию, выдавать дамп
    updateDump();

    while (loop()) {

        int k = inkey();

        switch (k) {

            // Посмотреть что на экране сейчас в данный момент
            case SDL_SCANCODE_F4:

                wherei = 1 - wherei;
                if (wherei) updateScreen(); else updateDump();
                break;

            // Один шаг дампа
            case SDL_SCANCODE_F7: step(); updateDump(); break;
        }
    }

    free(mem);
    return quit();
}
