#include "tahoma.h"

#define CURSOR_W 12
#define CURSOR_H 21

int cursorx, cursory, cursorc;

// 1-черный,2-белый,0-прозрачный
static const u8 cursor[CURSOR_W*CURSOR_H] = {
    1,0,0,0,0,0,0,0,0,0,0,0,
    1,1,0,0,0,0,0,0,0,0,0,0,
    1,2,1,0,0,0,0,0,0,0,0,0,
    1,2,2,1,0,0,0,0,0,0,0,0,
    1,2,2,2,1,0,0,0,0,0,0,0,
    1,2,2,2,2,1,0,0,0,0,0,0,
    1,2,2,2,2,2,1,0,0,0,0,0,
    1,2,2,2,2,2,2,1,0,0,0,0,
    1,2,2,2,2,2,2,2,1,0,0,0,
    1,2,2,2,2,2,2,2,2,1,0,0,
    1,2,2,2,2,2,2,2,2,2,1,0,
    1,2,2,2,2,2,2,1,1,1,1,1,
    1,2,2,2,1,2,2,1,0,0,0,0,
    1,2,2,1,1,2,2,1,0,0,0,0,
    1,2,1,0,0,1,2,2,1,0,0,0,
    1,1,0,0,0,1,2,2,1,0,0,0,
    1,0,0,0,0,0,1,2,2,1,0,0,
    0,0,0,0,0,0,1,2,2,1,0,0,
    0,0,0,0,0,0,0,1,2,2,1,0,
    0,0,0,0,0,0,0,1,2,2,1,0,
    0,0,0,0,0,0,0,0,1,1,0,0,
};

// Запись того что было за курсором во время прорисовки pset()
u8 cursorback[21][12];
u8 cursor_new[21][12];

// Прочесть точку с экрана
int point(int x, int y)
{
    heapb(vm, 0x20000);

    if (x < 0 || x >= 640 || y < 0 || y >= 400) {
        return 0;
    }

    int t = y*320 + (x >> 1);
    return (x & 1 ? (vm[t] & 15) : (vm[t] >> 4));
}

// Установить точку на экране
void pset(int x, int y, u8 c)
{
    heapb(vm, 0x20000);
    if (x < 0 || x >= 640 || y < 0 || y >= 400) {
        return;
    }

    int j = x - cursorx;
    int i = y - cursory;

    // Сейчас мы рисуем там, где показывается курсор
    if (j >= 0 && j < CURSOR_W && i >= 0 && i < CURSOR_H) {

        // Сохранить в буфер курсора для восстановления
        cursorback[i][j] = c;

        // Получение цвета точки для курсора
        int ck = cursor[j + CURSOR_W*i];

        if (ck == 1) c = 0; else if (ck == 2) c = 15;
    }

    int t = y*320 + (x >> 1);
    vm[t] = x & 1 ? (vm[t] & 0xF0) | c : (vm[t] & 0x0F) | (c << 4);
}

// Очистка экрана
void clear(u8 c)
{
    heapw(vm, 0x20000);

    c &= 15;

    int c8 = c | (c<<4);

    c8 |= (c8 << 8);
    c8 |= (c8 << 16);

    for (int i = 0; i < (640*400/8); i++) vm[i] = c8;

    cursorx = mousex();
    cursory = mousey();
    cursorc = 0;

    // Нарисовать курсор
    for (int i = 0; i < CURSOR_H; i++) for (int j = 0; j < CURSOR_W; j++) pset(j + cursorx, i + cursory, c);
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

        // В области рисования курсора придется протормозить
        if (i >= cursory && i < cursory + CURSOR_H) {

            for (int j = x1; j <= x2; j++) {
                pset(j, i, c);
            }

        } else {

            int t = 320*i;

            // Нарисовать точку слева
            if (x1 & 1) { vm[t + xa - 1] = (vm[t + xa - 1] & 0xF0) | c; }

            // Прорисовать блок посередине
            for (int j = xa; j < xb; j++) { vm[j + t] = (c | c4); }

            // Нарисовать точку справа
            if ((x2 & 1) == 0) { vm[t + xb] = (vm[t + xb] & 0x0F) | c4; }
        }
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

void draw_button(int x, int y, int w, int h, int press = 0)
{
    int x2 = x + w, y2 = y + h;
    int c1 = 15, c2 = 0, c3 = 8;

    if (press) { c1 = 0; c2 = 15; c3 = 8; }

    block(x, y, x2, y2, 7);

    block(x, y, x2, y, c1);
    block(x, y, x, y2, c1);

    block(x2, y, x2, y2, c2);
    block(x, y2, x2, y2, c2);

    block(x2-1, y+1, x2-1, y2-1, c3);
    block(x+1, y2-1, x2-1, y2-1, c3);
}

// Область для текста
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

// Нарисовать строку
int draw_string(int x, int y, const char* s, u8 fr = 15, int bold = 0)
{
    int i = 0;
    int size = 0;
    while (s[i]) {

        u8 ch = s[i++];

        if (ch == 0xD0) { ch = s[i++]; ch -= 0x10; if (ch == 0x71) ch = 0xC0; }
        if (ch == 0xD1) { ch = s[i++]; ch += 0x30; }

        if (bold) { draw_tahoma(x + size, y, ch, fr); size++; }

        size += draw_tahoma(x + size, y, ch, fr);
    }

    return size;
}

// Нижняя панель
void draw_panel_down()
{
    int h = 372;

    block(0,h,639,399,7);
    block(0,h+1,639,h+1,15);

    draw_button(2,h+4,40,20);
    draw_string(8,h+9,"Пуск",0,1);
}

// Смещение положения мыши
int mouse_moveclick()
{
    int rt = 0;
    int px = cursorx,  py = cursory,  pb = cursorc;    // Было ранее
    int mx = mousex(), my = mousey(), mb = mouseb();   // Стало сейчас

    // Обнаружен клик мышкой (>0) или откликивание (<0)
    if (pb != mb && pb == 0) { rt =  mb; }
    if (pb != mb && mb == 0) { rt = -pb; }

    cursorc = mb;

    // Если мышь не меняла позицию, то ничего не делать далее
    if (mx == px && my == py) {
        return rt;
    }

    cursorx = mx;
    cursory = my;

    // Скопировать старую область памяти
    for (int i = 0; i < CURSOR_H; i++) for (int j = 0; j < CURSOR_W; j++) cursor_new[i][j] = cursorback[i][j];

    // Восстановить старую область, частично может быть перерисована иконка курсора
    for (int i = 0; i < CURSOR_H; i++) for (int j = 0; j < CURSOR_W; j++) pset(px+j, py+i, cursor_new[i][j]);

    // Перерисовка нового указателя
    for (int i = 0; i < CURSOR_H; i++) for (int j = 0; j < CURSOR_W; j++) {

        int x  = mx+j, y  = my+i; // Текущая точка
        int dx = x-px, dy = y-py; // Старая область

        // Если точка попадает в старую область, то взять цвет оттуда, иначе просто с экрана
        int cl = (dx >= 0 && dx < CURSOR_W && dy >= 0 && dy < CURSOR_H) ? cursor_new[dy][dx] : point(x, y);

        pset(mx+j, my+i, cl);
    }

    return rt;
}
