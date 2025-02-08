#include <stdio.h>
#include <string.h>
#include <stdlib.h>

int main() {
    char * str = (char*) calloc(1000001 ,sizeof(char));
    // scanf("%ms", &str);
    fgets(str, 1000001, stdin);
    long long count[26];
    if (strlen(str) == 1) {printf("%s", str);}
    else
    {
            for (long i = 0; i < 26; i++)
        {
            count[i] = 0;
        }
        int len = strlen(str);
        for (long i = 0; i < len; i++)
        {
            char a = str[i];
            if(a != '\n'){
                count [a -'a']++; 
            }
        }
        
        for (long i = 0; i < 26; i++)
        {
            while (count[i] != 0)
        { 
            printf("%c", ((char)i + 'a'));
                count[i]--;
        }
        }
    }
    free(str);
    return 0;
}
