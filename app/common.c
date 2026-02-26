// Включить режим экрана
void screen(int i)
{
    if (i ==  3) {

        csr_write(0x7C0, VM_TEXT);
        screen_w = 80;
        screen_w = 25;

    } else if (i == 13) {

        csr_write(0x7C0, VM_320);
        screen_w = 320;
        screen_h = 200;

    } else if (i == 12) {

        csr_write(0x7C0, VM_640);
        screen_w = 640;
        screen_h = 400;
    }
}

// Установка курсора, в том числе аппаратного, если есть
void locate(int x, int y)
{
    heapw(kk, 0xC0002000);

    cursor_x = x;
    cursor_y = y;

    // Установить аппаратное положение курсора
    kk[0] = x + y*80;
}

// Установка текущего цвета
void color(int c)
{
    cursor_a = c;
}

// Очистка экрана
void cls(int c = 0x07)
{
    heaph(vm, D_VIDEOADDR);

    switch (csr_read(0x7C0)) {

        case VM_TEXT:

            for (int i = 0; i < 2000; i++) vm[i] = (c << 8);

            locate(0, 0);
            color(c);
            break;

        case VM_320:
        case VM_640:

            for (int i = 0; i < 64000; i++) vm[i] = c + (c << 8);
            break;
    }
}

// Установить точку на экране монитора
void pset(int x, int y, uint8 c) {

    heapb(vm, D_VIDEOADDR);

    if (x >= 0 && x < screen_w && y >= 0 && y < screen_h) {
        vm[x + y*screen_w] = c;
    }
}

// Рисование линии на экране (256,192)
void line(int x1, int y1, int x2, int y2, u8 c)
{
    int signx  = x1 < x2 ? 1 : -1;
    int signy  = y1 < y2 ? 1 : -1;
    int deltax = x2 > x1 ? x2 - x1 : x1 - x2;
    int deltay = y2 > y1 ? y2 - y1 : y1 - y2;
    int error  = deltax - deltay;
    int error2;

    // Первичное позиционирование
    int ad = (x1 >> 3) + (32*y1);

    // Перебирать до конца
    for (;;) {

        pset(x1, y1, c);
        error2 = 2 * error;

        // Выйти из цикла при достижении конца линии
        if (x1 == x2 && y1 == y2) break;

        // Перемещение точки по X++, X--
        if (error2 + deltay > 0) {

            x1    += signx;
            error -= deltay;
        }

        // Перемещение точки по Y++, Y--
        if (error2 < deltax) {

            y1    += signy;
            error += deltax;
        }
    }
}

// Печать зависит от выбранного режима экрана
void pchar(unsigned char c)
{
    heaph(vm, D_VIDEOADDR);

    switch (csr_read(0x7C0)) {

        case VM_TEXT:

            vm[cursor_x + 80*cursor_y] = (cursor_a << 8) | c;
            cursor_x++;
            break;
    }
}

// Печать строки
void print(const char* s, int x = -1, int y = -1, int c = -1)
{
    int i = 0;

    if (x >= 0) cursor_x = x;
    if (y >= 0) cursor_y = y;
    if (c >= 0) cursor_a = c;

    while (s[i]) {

        // UTF-8 => CP866
        if      (s[i] == 0xD0) { i++; pchar(s[i++] - 0x10); }
        else if (s[i] == 0xD1) { i++; pchar(s[i++] + 0x60); }
        else { pchar(s[i++]); }
    }

    locate(cursor_x, cursor_y);
}

// Проверка принятой клавиши от клавиатуры
inline int kbhit()
{
    heapb(kk, 0xC0000000);
    return kk[0];
}

// Какой код от клавиатуры
inline unsigned char kbcode()
{
    heapb(kk, 0xC0001000);
    return kk[0];
}

// Простой ввод строки с ограничителем
int input(char* s, int max = 3, int x = -1, int y = -1, int c = -1)
{
    int length = 0;

    if (x >= 0) cursor_x = x;
    if (y >= 0) cursor_y = y;
    if (c >= 0) cursor_a = c;

    locate(cursor_x, cursor_y);

    for (;;) {

        if (kbhit()) {

            int ch = kbcode();

            switch (ch) {

                // ENTER
                case 10: {
                    return length;
                }

                // BACKSPACE
                case 8: {

                    if (length > 0) {

                        cursor_x--;
                        pchar(' ');
                        locate(--cursor_x, cursor_y);
                        s[length--] = 0;
                    }

                    break;
                }

                // ДОБАВИМ СИМВОЛ
                default: {

                    if (length < max) {

                        s[length++] = ch;
                        s[length] = 0;

                        pchar(ch);
                        locate(cursor_x, cursor_y);
                    }

                    break;
                }
            }
        }
    }
}
