#include <stdio.h>
int main()
{
    long long n;
    scanf("%lld", &n);
    long long a[n];
    long long k;
    long long p;
    for (long long i = 0; i < n; i++)
    {
        scanf("%lld", &p);
        a[i]=p;
    }
    scanf("%lld", &k);
    long long sum = 0;
    for (long long  i = 0; i<k; i++)
    {
        sum += a[i];
    }
    long long max = sum;
    for (long long i = k; i<n; i++)
    {
        sum = sum + a[i] - a[i-k];
        if (max < sum) 
        {
            max = sum;
        }
    }
    printf("%lli" , max);
    return 0;
}
