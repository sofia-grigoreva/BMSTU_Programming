#include <stdio.h>
#include <stdint.h>


int maxarray(void *base, size_t nel, size_t width,
        int (*compare)(void *a, void *b))
{ 
    unsigned char *n = base;
    void* max = base;
    int index = 0;
    for (int i = 1; i < nel; i++)
    { 
        n+=width;
        if (compare(n , max) > 0 )
        { 
            max = n;
            index = i;
        }
    }
    return index;
}
