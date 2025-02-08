#include <stdio.h>
#include <math.h>
int main()
{
    long n;
    scanf("%ld", &n);
    if (n<0) 
    { 
        n = n * -1;
    }
    int p = sqrt (n) + 1;
    long long a[p + 2];
    for (long long i = 0; i <= p; i++)
    {
        a[i]=i;
    }
    long long i = 2;
    long long j;
    while (i<=p)
    {
        if (a[i] != 0) 
        { 
            j = i + i;
            while (j <= p)
            {
                a[j] = 0;
                j += i;
            }
               
        }
        i++;
    }
    long c;
    i = 2;
    while (i<=p)
    { 
        if (a[i] != 0 && n % a[i] == 0) 
        {
            c = a[i]; n = n / a[i];
        }
        else 
        {
            i++;
        }
    }
    if (n == 1) 
    {
        printf("%ld", c);
    }
    else 
    {
        printf("%ld", n);
    }
    return 0;
}
