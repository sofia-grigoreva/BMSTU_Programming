#include <stdio.h>

int main(){
    long long b;
    unsigned long long a, m;
    scanf("%lld %lld %lld", &a, &b, &m);
    int b2[400];
    unsigned long long s = b;
    int j = 0 ;
    while (s>0) {
        b2[j] = s%2;
        j++;
        s /= 2; 
    }
    unsigned long long g = b2[j-1] * a;
    for (int i = j-2; i>=0; i--){ 
        g = ((g % m * 2) % m) + ((b2[i] * a%m) % m);
    }   
    g = g % m;
    printf("%lli", g);
    return 0;
}
