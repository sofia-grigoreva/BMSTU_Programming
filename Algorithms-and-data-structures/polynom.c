#include <stdio.h>

int main()
{
    long long n; 
    long long x;
    scanf("%lld", &n);
    scanf("%lli", &x);
    long long k[(n+1)];
    long long q;
    for (int i = 0; i<=n; i++)
    { 
        scanf("%lli", &q);
        k[i] = q; 
    }
    long long p;
    long long d;
    d = k[0];
    for (int i = 1; i<=n; i++)
    { 
        d = d * x + k[i];
    }
    p = k[0] * n;
    for (int i = 1; i<n; i++)
    {
        p = p * x + k[i] * (n-i);
    }
    printf("%lld\n%lld\n", d, p);
    return 0;
}
