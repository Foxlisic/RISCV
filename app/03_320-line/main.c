#include <io.h>
#include <common.c>

void main()
{
    screen(13);

    for (int i = 1; i < 200; i++) line(0,0,319,i,i);
    for (int i = 1; i < 320; i++) line(0,0,i,199,520-i);
}
