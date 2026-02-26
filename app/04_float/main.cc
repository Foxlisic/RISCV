#include <io.h>
#include <common.h>

int main()
{
    screen(13);
    cls(7);

    float a = 0.5;

    // Тест флоата
    for (int x = 0; x < 320; x++) {

        pset(x, 100 - (int) a, 0);

        brk;
        a += 0.4;
    }

    return 0;
}
