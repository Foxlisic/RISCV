#include <io.h>
#include <common.h>

void main()
{
    screen(3);
    cls(0x17);

    locate(33,12);
    color(0x30);
    print(" Hello World! ");
}
