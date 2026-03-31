#include <io.h>
#include <winform.h>

int main()
{
    clear(1);

    while (sdstatus() & 1);

    sdlba(1);
    sdcmd();

    while (sdstatus() & 1);

    draw_tahoma(16,8,'0' + sdstatus());

    return 0;
}
