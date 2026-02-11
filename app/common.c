
// Включить режим экрана
void screen(int i)
{
    if (i ==  3) {
        csr_write(0x7C0, VM_TEXT);
    } else if (i == 13) {
        csr_write(0x7C0, VM_320);
    } else if (i == 12) {
        csr_write(0x7C0, VM_640);
    }
}

// Очистка экрана
void cls(int c)
{
    heaph(vm, D_VIDEOADDR);

    switch (csr_read(0x7C0)) {

        case VM_TEXT:

            for (int i = 0; i < 2000; i++) vm[i] = (c << 8);
            cursor_a = c;
            break;
    }
}

// Установить точку на экране монитора
void pset(int x, int y, uint8 c) {

    heapb(vm, D_VIDEOADDR);
    if (x >= 0 && x < 320 && y >= 0 && y < 200) {
        vm[x + y*320] = c;
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

// Установка курсора, в том числе аппаратного, если есть
void locate(int x, int y)
{
    cursor_x = x;
    cursor_y = y;
}

// Установка текущего цвета
void color(int c)
{
    cursor_a = c;
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
void print(const char* s)
{
    int i = 0;
    while (s[i]) { pchar(s[i++]); }
}
