#include <io.h>
#include <common.h>

int main()
{
    str(ib,8);

    screen(3);
    cls();

    print(" Привет, мир! ",33,12,0x30);
    input(ib,3,0,24,0x07);
    print(ib, 1,1);

    return 0;
}
