#include <stdio.h>

struct Date {
    int Day, Month, Year;
};

int main() {
    int n;
    scanf("%d", &n);
    struct Date a[n];
    for (size_t i = 0; i < n; i++) 
    {
        scanf("%d%d%d", &a[i].Year, &a[i].Month, &a[i].Day);
    }
    //Дни
    int days [31];
    for (int i = 0; i < 31; i++) 
    {
        days [i] = 0;
    }
    for (int i = 0; i < n; i++)
    {days[a[i].Day - 1]++;}
    
    for (int i = 1; i < 31; i++)
    {
        days[i] += days[i - 1];
    }
    
    struct Date sd[n];
    
    for (int i = n - 1 ; i >= 0; i--)
    {
        sd[days[a[i].Day - 1] - 1] = a[i];
        days[a[i].Day - 1]--;
    }
    
    for (int i = 0; i < n; i++)
    {
        a[i]=sd[i];
    }
        
    //Месяцы
    int monthes [12];
    for (int i = 0; i < 12; i++) 
    {
        monthes [i] = 0;
    }
    for (int i = 0; i < n; i++)
    {
        monthes[a[i].Month - 1]++;
    }
    
    for (int i = 1; i < 12; i++)
    {
        monthes[i] += monthes[i - 1];
    }
    
    struct Date sm[n];

    for (int i = n - 1 ; i >= 0; i--)
    {
        sm[monthes[a[i].Month - 1] - 1] = a[i];
        monthes[a[i].Month - 1]--;
    }
    
    for (int i = 0; i < n; i++)
    {
        a[i]=sm[i];
    }
       
    //Годы
    int years [61];
    for (int i = 0; i < 61; i++) 
    {
        years [i] = 0;
    }
    for (int i = 0; i < n; i++)
    {
        years[a[i].Year - 1970]++;
    }
    
    for (int i = 1; i < 61; i++)
    {
        years[i] += years[i - 1];
    }
    
    struct Date sy[n];
    
    for (int i = n - 1 ; i >= 0; i--)
    {   
        sy[years[a[i].Year - 1970] - 1] = a[i];
        years[a[i].Year - 1970]--;
    }
    
    for (int i = 0; i < n; i++)
    {
        a[i]=sy[i];
    }
    
    for (int i = 0; i < n; i++)
    {
        printf( "%04d %02d %02d\n", a[i].Year, a[i].Month, a[i].Day);
    }
     
    return 0;
}
