#include <stdio.h>
#include <string.h>
#include <stdlib.h>

int main(int argc, char** argv) 
    {
    char* str = argv[1];
    size_t lenstr = strlen(str);
    size_t* p = calloc(lenstr, sizeof(size_t));
    p[0] = 0;
    size_t j = 0;
    size_t i = 1;
    while (i < lenstr)
    {
        if (str[i] == str[j]) 
        {
            p[i] = j+1; i++; j++;
        }
        else if (j == 0) 
        {
            p[i]=0; i++;
        }
        else 
        {
            j = p[j - 1];
        }
    }
    
    for (size_t i = 0; i < lenstr; i++) 
    {
        size_t n = i + 1;
        size_t k = n / (n - p[i]);
        if ((n % (n - p[i]) == 0) && k > 1)
        {
            printf("%ld" , n); 
            printf(" ");
            printf("%ld\n", k);
        }
    }
    free(p);
    return 0;
}
