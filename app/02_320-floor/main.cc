#include <io.h>
#include <common.h>

int main()
{
    heapb(vm, 0x100000);
    screen(13);

    for (int i = 0; i < 320*203; i++) vm[i] = 1;

    uint k = 0;
    for (;;) {

        for (int y = 3; y < 100; y++)
        for (int x = 0; x < 320; x++) {

            int a = 0 + 2048 / y;
            int b = k + ((16 * (x - 160)) / y);

            pset(x, y+100, a|b);
        }

        k++;
    }

    return 0;
}
