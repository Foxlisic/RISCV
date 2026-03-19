#include <io.h>
#include <common.h>

// Регистровые операции АЛУ
#define REG_OP(inst, dst, src1, src2) asm volatile (\
    #inst " %[rd], %[s1], %[s2]" \
    : [rd] "=r" (dst) \
    : [s1] "r" (src1), [s2] "r" (src2) \
    );

const static unsigned int data_add[] =
{
    // RD       RS1         RS2
    0x00000000, 0x00000000, 0x00000000,
    0x00000002, 0x00000001, 0x00000001,
    0x0000000a, 0x00000003, 0x00000007,
    0xffff8000, 0x00000000, 0xffff8000,
    0x80000000, 0x80000000, 0x00000000,
    0x7fff8000, 0x80000000, 0xffff8000,
    0x00007fff, 0x00000000, 0x00007fff,
    0x7fffffff, 0x7fffffff, 0x00000000,
    0x80007ffe, 0x7fffffff, 0x00007fff,
    0x80007fff, 0x80000000, 0x00007fff,
    0x7fff7fff, 0x7fffffff, 0xffff8000,
    0xffffffff, 0x00000000, 0xffffffff,
    0x00000000, 0xffffffff, 0x00000001,
    0xfffffffe, 0xffffffff, 0xffffffff,
    0x80000000, 0x00000001, 0x7fffffff
};

// Тестирование инструкции ADD
volatile int test_add()
{

    for (int i = 0; i < sizeof(data_add) / sizeof(unsigned int); i += 3) {

        unsigned int a = data_add[i+1], b = data_add[i+2], c;
        unsigned int r = data_add[i+0];

        REG_OP(add, c, a, b);

        if (c != r) return 1;
    }

    return 0;
}

// Вывести ошибку на тестах
void error(const char* s)
{
    print(s);
    for (;;);
}

int main()
{
    screen(3);

    if (test_add()) error("ADD");

    print("SUCCESS");
    return 0;
}
