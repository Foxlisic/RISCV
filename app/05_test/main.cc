#include <io.h>
#include <winform.h>

int main()
{
    clear(3);

    draw_win(16, 16, 420, 200);
    draw_string(21, 20, "Съешь [же] ещё этих мягких французских булок да выпей чаю");

    draw_textarea(19, 35, 300, 100);
    draw_string(24, 40, "Часто говорят о чае, но не знают, что это такое",0);

    draw_panel_down();

    int x = 0;
    for (;;) {

        if (kbhit()) {
            x += draw_tahoma(x, 0, kbread());
        }

        // pset(mousex(), mousey(), mouseb());
    }

    return 0;
}
