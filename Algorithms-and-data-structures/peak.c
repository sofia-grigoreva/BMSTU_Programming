#include <stdio.h>

unsigned long peak(unsigned long nel, int (*less)(unsigned long i, unsigned long j))
{
    unsigned long p;
    unsigned long long n;
    if (nel == 1 || less (0 , 1) == 0)
    {
        return 0;
    }
    for (unsigned long i = 1; i < nel - 1; i++)
        { 
            if ((less (i, i - 1 )) == 0 && (less (i, i + 1)) == 0)
            {
                return i;
            }
        }
    return (nel - 1);
}
