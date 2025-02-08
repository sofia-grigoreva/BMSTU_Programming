#include <stdio.h>
#include <string.h>
#include <stdlib.h>

void csort(char *src, char *dest)
{   
    char src_copy[2000];
    strcpy(src_copy, src);
    char *words[1000];
    int n = 0;
    char *word = strtok(src_copy, " ");
    while (word != NULL)
    {  
        words[n] = word;
        n++;
        word = strtok(NULL, " ");
    }

    if (words[n - 1][strlen(words[n - 1]) - 1] == '\n')
        words[n - 1][strlen(words[n - 1]) - 1] = 0;

    int count[n];
    
    for (int i = 0; i < n; i++)
    {
        count[i] = 0;
    }
    int j = 0;
    int i = 0;
    
    while (j < n - 1)
    {
        i = j + 1;
        while (i < n)
        {
            if (strlen(words[i]) >= strlen(words[j]))
            {
                count[i]++;
            }
            else
            {
                count[j]++;
            }
            i++;
        }
        j++;
    }
    
    strcpy(dest, "");
    for (int i = 0; i < n; i++) 
    {
        int j = 0;
        while (count[j] != i) 
        {
            j++;
        }
        strcat(dest, words[j]);
        if (i + 1 != n) 
        {
            strcat(dest, " ");
        }
    }
}

int main()
{
    char src[2000];
    fgets(src, sizeof(src), stdin);
    char* dest = calloc(2000, sizeof(char));
    csort(src, dest);
    printf("%s", dest);
    free(dest);
    return 0;
}
