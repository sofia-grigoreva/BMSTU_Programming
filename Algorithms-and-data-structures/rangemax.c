#include <stdio.h>
#include <stdlib.h>

int max(int a, int b)
{
    if (a > b) return a;
    return b;
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
    t[i] = max(t[i * 2 + 1], t[i * 2 + 2]);
}

void update (int j, int x, int i, int a, int b, int* t) 
{
    if (a == b) 
    {
        t[i] = x;
        return;
    }
    int m = (a + b) / 2;
    if (j <= m) 
    {
        update(j, x, 2 * i + 1, a, m, t);
    } 
    else 
    {
        update(j, x, 2 * i + 2, m + 1, b, t);
    }
    t[i] = max(t[2 * i + 1], t[2 * i + 2]);
}

int query(int *t, int l, int r, int i, int a, int b)
{
    if ((l == a) && (r == b))
    {
    return t[i];
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
        return max (query(t, l, m, 2 * i + 1, a, m), query(t, m + 1, r, 2 * i + 2, m + 1, b));
    }
}


int main()
{
    int n;
    scanf("%d", &n);
    int* a = (int*)malloc(sizeof(int) * n);
    int* t = (int*)malloc(sizeof(int) * n * 4);
    for (int i = 0; i < n; i++)
        {scanf("%d",&a[i]);}
    build (a, 0, 0, n - 1, t);
    char str[4];
    scanf("%s", str);
    int l, r, i, v;
    while (str[0] != 'E') 
    {
        if (str[0] == 'M') 
        {
            scanf("%d",&l);
            scanf("%d",&r);
            printf("%d\n", query(t, l, r, 0, 0, n - 1));
        } 
        else if (str[0] == 'U') 
        {
            scanf("%d",&i);
            scanf("%d",&v);
            update (i, v, 0, 0, n - 1, t); 
        }
        scanf("%s", str);
    }
    
    free(a);
    free(t);
    return 0;
}
