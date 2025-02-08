#include <stdio.h>
#include <stdlib.h>
#include <stdlib.h>

int gcd (int a, int b)
{   if (b == 0) return a;
    return gcd (b, a % b);
}

void build(int * arr, int i, int a, int b, int * t)
{
    if (a == b) 
    {
        t[i] = arr[a];
        return;
    }
    int m = (a + b) / 2;
    build(arr, i * 2 + 1, a, m, t);
    build(arr, i * 2 + 2, m + 1, b, t);
    t[i] = gcd(t[i * 2 + 1], t[i * 2 + 2]);
}

int query(int *t, int l, int r, int i, int a, int b)
{
    if ((l == a) && (r == b))
    {
    return abs (t[i]);
    }
    else
    {
        int m = (a + b) / 2;
        if (r <= m)
        {
            return query(t, l, r, 2 * i + 1, a, m);
        }
        else if (l > m)
        {
            return query(t, l, r, 2 * i + 2, m + 1, b);
        }
        return gcd (query(t, l, m, 2 * i + 1, a, m), query(t, m + 1, r, 2 * i + 2, m + 1, b));
    }
}


int main()
{
    int n,m;
    scanf("%d", &n);
    int* a = (int*)malloc(sizeof(int) * n);
    int* t = (int*)malloc(sizeof(int) * n * 4);
    for (int i = 0; i < n; i++)
        {scanf("%d",&a[i]);}
    build (a, 0, 0, n - 1, t);
    scanf("%d", &m);
    int l, r;
    for (int i = 0; i < m; i++)
    {
        scanf("%d",&l);
        scanf("%d",&r);
        printf("%d\n", query(t, l, r, 0, 0, n - 1));
    } 
    free(a);
    free(t);
    return 0;
}
