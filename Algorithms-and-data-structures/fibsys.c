#include <stdio.h>
int main(){
    long long x;
    scanf("%lli", &x);
    long long f[1000];
    unsigned long long i1 = 1;
    unsigned long long i2 = 1;
    unsigned long long i3;
    f[0]=1;
    f[1]=1;
    long long i = 2;
    while (i1 + i2 <= x)
    { 
        i3 = i1 + i2;
        i1 = i2;
        i2 = i3;
        f[i] = i3;
        i++;
    }
    unsigned  long long z[i];
    for (unsigned long long t = 0; t<(i - 1); t++)
    {
        z[t] = 0;
    }
    unsigned long long k = 0;
    for (unsigned long long j = (i - 1); j>0; j--)
    {
        if (x >= f[j]) 
        { 
            x = x-f[j]; z[k] = 1;
        }
        k++;
    }
    for (unsigned long long t = 0; t<(i - 1); t++)
    {
        printf("%lli", z[t]);
    }
}
