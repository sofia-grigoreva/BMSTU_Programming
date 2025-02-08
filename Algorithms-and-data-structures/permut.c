#include <stdio.h>
int main()
{
    int x;
    int y;
    long long a[8];
    long long b[8];
    for (int i = 0; i < 8; i++)
    {
        a[i]=0;
        b[i]=0;
    }
    long long p;
    long long min = 10000000;
    for (int i = 0; i <= 7; i++)
    {
        scanf("%lld", &p);
        a[i]=p;
    }
    
    for (int i = 0; i <= 7; i++)
    {
        scanf("%lld", &p);
        if (p < min) {min = p;}
        b[i]=p;
    }
      
    min = min - 1;
    long long c = 0;
    for (int i = 0; i<8; i++)
    { 
        for (int j = 0; j<8; j++)
        {
            if (a[i] == b[j]) 
            {
                c+=1; b[j] = min; 
                break;
            }
        }
    }
     
    if (c == 8) 
    {
        printf("yes");
    }
    else 
    {
        printf("no");
    }
    return 0;
}
