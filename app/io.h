// Объявление разных региона памяти
#define heap(A,B,C) volatile unsigned A*     B = (unsigned A*) C
#define heapb(A,B)  volatile unsigned char*  A = (unsigned char*) B
#define heaph(A,B)  volatile unsigned short* A = (unsigned short*) B
#define heapw(A,B)  volatile unsigned int*   A = (unsigned int*) B
