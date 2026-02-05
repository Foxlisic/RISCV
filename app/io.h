// Объявление разных региона памяти
#define heap(A,B,C) volatile unsigned A* B = (unsigned A*) C
#define heapb(A,B)  heap(char,A,B)
#define heaph(A,B)  heap(short,A,B)
#define heapw(A,B)  heap(int,A,B)
