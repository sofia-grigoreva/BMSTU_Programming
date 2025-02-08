#include <stdio.h>
#include <string.h>
#include <stdlib.h>

int main(int argc, char** argv) {
    char* S = argv[1];
    char* T = argv[2];
    size_t lenS= strlen(S);
    size_t lenT= strlen(T);
    size_t* p = calloc(lenS, sizeof(size_t));
    p[0] = 0;
    size_t j = 0;
    for (size_t i = 1; i < lenS; i++)
    {
        while (S[i] != S[j] && j!=0) 
        {
            j = p[j - 1];
        }
        if (S[i] == S[j]) 
        {
            p[i] = j + 1; j++;
        }
        if (j == 0)
        {
            p[i] = 0;
        }
    }
    size_t l = 0;
    for (size_t k = 0; k < lenT; k++)
    {
        while (T[k] != S[l] && l!=0) 
        {
            l= p[l - 1];
        }
        if (T[k] == S[l])
        {
            l++; 
        }
        if (l == lenS)
        {
            printf ("%ld", k - lenS + 1); 
            printf(" ");
        }
    }
    
    free(p);
    return 0;
}
