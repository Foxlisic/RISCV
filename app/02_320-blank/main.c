#include <io.h>

void main()
{
    heapb(vm, 0x100000);

    csr_write(0x7C0, VM_320);

    int k = 0;
    for (;;) {

        for (int y = 0; y < 200; y++)
        for (int x = 0; x < 256; x++) {
            vm[x + y*320] = x + y + k;
        }
        k++;
    }
}
