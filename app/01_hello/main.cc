#include <io.h>
#include <common.h>

int main()
{
    str(ib,8);

    screen(3);
    cls(0x17);
    locate(33,12); color(0x30); print(" Hello World! ");
    input(ib,3);
    locate(1,1); print(ib);

    return 0;
}
