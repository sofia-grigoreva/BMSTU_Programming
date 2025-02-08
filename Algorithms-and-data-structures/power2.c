#include <stdio.h>

void comb (long* a, long index, long sum, int n, long* result) 
{   
    if (index >= n) 
    {
        return;
    }
    long f = sum;
    long d = 0;
    while (f > 0) 
    {
        if (f == 1) 
        {
            *result += 1;
        }
        if (f % 2 == 0) 
        {
        f/=2;
        }
        else 
        {
            f = 0;
        }
    }
    for (long i = index + 1; i < n; ++i) 
    {
        comb (a, i, sum + a[i], n, result);
    }
}

int main(){
    int n;
    scanf("%d", &n);
    long a[n];
    for (int i = 0; i < n; ++i) 
    {
        scanf("%ld", &a[i]);
    }
    long result = 0;
    for (int i = 0; i < n; ++i) 
    {
        comb(a, i, a[i], n, &result);
    }
    printf ("%ld", result);
    return 0;
}
