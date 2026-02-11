#include "qblib.h"

// 4Mb Memory Maximus
#define MAX_MEM 0x3FFFFF

Uint8* mem;
Uint32 pc;
Uint32 regs[32], pregs[32];
Uint32 csr[4096];

#include "routines.cc"

// --------------------------------

int main(int argc, char** argv)
{
    init(argc, argv);
    screen(3);

    // По умолчанию, выдавать дамп
    updateDump();

    while (loop()) {

        int k = inkey();

        // В активном запуске
        if (run) {

            // Добавление кода нажатия клавиши ASCII
            if      (k > 0) { kb_key_ascii = kb_ascii(k, 1); kb_hit_ascii = kb_key_ascii ? 1 : 0; }
            else if (k < 0) { kb_ascii(-k, 0); }

            // Шагомер по N-кадров x 50 = 25M инструкции
            int i = 0; while (i < 500000) { i += step(); if (ebreak) break; }

            // Остановка в развитии событии
            if (k == SDL_SCANCODE_F12) {
                ebreak = 1;
            } else {
                updateScreen(); // Обновить экран каждые 1/50 сек
            }

            // Выход и просмотр что там наработало
            if (ebreak) {

                run = 0;
                updateDump();
            }

        } else {

            // Чисто по-приколу (ня, десу, кавай, штааа!, шлёп губошлёп)
            switch (k) {

                // Посмотреть что на экране сейчас в данный момент
                case SDL_SCANCODE_F4:

                    wherei = 1 - wherei;
                    if (wherei) updateScreen(); else updateDump();
                    break;

                // Запуск программы
                case SDL_SCANCODE_F9:

                    run = 1;
                    break;

                // Один шаг дампа
                case SDL_SCANCODE_F7: step(); updateDump(); break;
            }
        }
    }

    free(mem);
    return quit();
}
