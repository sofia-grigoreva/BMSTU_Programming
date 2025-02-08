#include <stdio.h>
#include <math.h>

int main()
{
    int x;
    int y;
    long long a = 0;
    long long b = 0;
    int p;
    scanf("%d", &x);
    for (int i = 0; i < x; i++)
    {
            scanf("%d", &p);
            a+= pow(2, p);
    }
    scanf("%d", &y);
    for (int i = 0; i < y; i++)
    {
            scanf("%d", &p);
            b+= pow(2, p);
    }
    long long z[32];
    for(int i = 0; i<32; i++)
    {
        z[i] = 0;
    }
    for (int k = 31; k>=0; k--)
    {
        if (a>= pow(2,k) && b>= pow(2,k)) 
        {
            z[k] = 1; a=a- pow(2,k); b= b- pow(2,k);
        } 
        else 
        {
            if (a>= pow(2,k)) 
            {
                a= a - pow(2,k);
            }
            if (b>= pow(2,k)) 
            {
            b= b - pow(2,k);
            }
        }
    }
    for (int t = 0; t<=31; t++)
    {
        if (z[t]==1) 
        {
            printf("%d", t); 
            printf(" ");
        }
    }
    return 0;
}
