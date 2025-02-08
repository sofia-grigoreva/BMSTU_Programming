#include <stdio.h>
#include <stdint.h>

void revarray (void *base, size_t nel, size_t width)
{
    unsigned char *n = base;
    unsigned char *k =  (unsigned char*)base + (nel - 1) * width;
    while (n < k)
    {
        for (size_t i = 0; i < width; ++i)
        {
            unsigned char p = *n;
            *n = *k;
            *k  = p;
            n++;
            k++;
        }
        k-= 2* width;
    }
}
