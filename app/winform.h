#include "tahoma.h"

// Очистка экрана
void clear(u8 c)
{
    heapw(vm, 0x20000);

    c &= 15;

    int c8 = c | (c<<4);

    c8 |= (c8 << 8);
    c8 |= (c8 << 16);

    for (int i = 0; i < (640*400/8); i++) vm[i] = c8;
}

// Установить точку на экране
void pset(int x, int y, u8 c)
{
    heapb(vm, 0x20000);
    int t = y*320 + (x >> 1);
    vm[t] = x & 1 ? (vm[t] & 0xF0) | c : (vm[t] & 0x0F) | (c << 4);
}

// Нарисовать блок
void block(int x1, int y1, int x2, int y2, u8 c)
{
    heapb(vm, 0x20000);

    // Запрет рисования за пределами
    if (x1 >= 640 || y1 >= 400) return;

    // Ограничение по сторонам
    if (x1 < 0)    x1 = 0;
    if (x2 >= 640) x2 = 6309;

    if (y1 < 0)    y1 = 0;
    if (y2 >= 400) y2 = 399;

    int xa = x1 >> 1;
    int xb = x2 >> 1;
    u8  c4 = c  << 4;

    if (x1 & 1) xa++;
    if (x2 & 1) xb++;

    for (int i = y1; i <= y2; i++) {

        int t = 320*i;

        // Нарисовать точку слева
        if (x1 & 1) { vm[t + xa - 1] = (vm[t + xa - 1] & 0xF0) | c; }

        // Прорисовать блок посередине
        for (int j = xa; j < xb; j++) { vm[j + t] = (c | c4); }

        // Нарисовать точку справа
        if ((x2 & 1) == 0) { vm[t + xb] = (vm[t + xb] & 0x0F) | c4; }
    }
}

// Обведенный блок
void lineb(int x1, int y1, int x2, int y2, u8 c)
{
    block(x1, y1, x2, y1, c);
    block(x1, y1, x1, y2, c);
    block(x2, y1, x2, y2, c);
    block(x1, y2, x2, y2, c);
}

// Общий вид окна
void draw_win(int x1, int y1, int w, int h)
{
    int x2 = x1 + w,
        y2 = y1 + h;

    // Серый фон
    block(x1,y1,x2,y2,7);

    // Выпуклый свет
    block(x1,y1,x1,y2,15);
    block(x1,y1,x2,y1,15);
    block(x2,y1,x2,y2,8);
    block(x1,y2,x2,y2,8);

    // Обводка
    lineb(x1-1, y1-1, x2+1, y2+1, 0);

    // Заголовок
    block(x1+2, y1+2, x2-2, y1+16, 1);
}

void draw_textarea(int x, int y, int w, int h)
{
    int x2 = x + w, y2 = y + h;

    block(x, y, x2, y2, 15);
    block(x, y, x, y2, 8);
    block(x, y, x2-1, y, 8);

    block(x2-1, y+1,  x2-1, y2-1, 7);
    block(x+2,  y2-1, x2-1, y2-1, 7);
    block(x+1,  y+1,  x2-2, y+1,  0);
    block(x+1,  y+1,  x+1,  y2-1, 0);
}

// Отрисовать как надо, и всё...
int draw_tahoma(int x, int y, u8 ch, u8 fr = 15)
{
    ch -= 0x20;

    int a;
    int o = tahoma_offset[ch];
    int s = tahoma_size[ch];
    int b = o >> 3;
    int c = o & 7;
    int m = 0xFFFF8000 >> s;

    for (int i = 0; i < 11; i++) {

        a   = tahoma_bitmap[b]*256 + tahoma_bitmap[b+1];
        b  += 112;
        a <<= c;

        for (int j = 0; j < s; j++) {

            if (a & 0x8000) {
                pset(x + j, y + i, fr);
            }

            a <<= 1;
        }
    }

    return s;
}

int draw_string(int x, int y, const char* s, u8 fr = 15)
{
    int i = 0;
    int size = 0;
    while (s[i]) {

        u8 ch = s[i++];

        if (ch == 0xD0) { ch = s[i++]; ch -= 0x10; if (ch == 0x71) ch = 0xC0; }
        if (ch == 0xD1) { ch = s[i++]; ch += 0x30; }

        size += draw_tahoma(x + size, y, ch, fr);
    }

    return size;
}
