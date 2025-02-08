#include <stdio.h>

unsigned long binsearch (unsigned long nel, int (*compare)(unsigned long i))
{
    unsigned long long index = 0;
    unsigned long long first = 0;
    unsigned long long last = nel - 1;
    unsigned long middle;
    while (first <= last)
    {
        middle = first + ((last - first) - ((last - first) % 2)) / 2;
        if (compare (middle) == 0)
        {
            return middle; 
            break;
        }
        else if (compare (middle) < 0)
        {
            first = middle + 1;
        }
        else
        {
            last = middle - 1;
        }
    } 
    return nel;
}
