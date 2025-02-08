#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int max_intercec = 0;

int intersection (char *str1, char *str2)
{
    int len1 = strlen (str1);
    int len2 = strlen (str2);
    int i;
    if (len1 < len2) i = len1;
    else i = len2;
    while (i >=1)
    {
        if (strncmp (str1 + len1 - i, str2, i) == 0)
        {
            return i;
        }
        i--;
    }
    return 0;
}

void generate_permutations (int c, int n, int now, int* available, int ** p, int all_intercec)
{
    if (c == n)
    {
        if (all_intercec > max_intercec)
        {
            max_intercec = all_intercec;
        }
    }
    else
    {
        for (int i = 0; i < n; i++)
        {
            if (available[i] == 1)
            {
                available[i] = 0;
                generate_permutations (c + 1, n, i, available, p, all_intercec + p[now][i]);
                available[i] = 1;
            }
        }
    }
}

int main ()
{
    int n;
    scanf ("%d", &n);
    int len = 0;
    int available[n];
    int array[n][n];

    char **strings = (char **)malloc (n * sizeof (char *));
    for (int i = 0; i < n; i++)
    {
        strings[i] = (char *)malloc (100 * sizeof (char));
        scanf ("%s", strings[i]);
        len += strlen (strings[i]);
        available[i] = 1;
    } 
    
    for (int i = 0; i < n; i++)
    {
        for (int j = 0; j < n; j++)
        {
            array[i][j] = intersection(strings[i],strings[j]);
        }
    }
    
    int *p[n];
    for (int i = 0; i < n; i++) 
    {
        p[i] = array[i];
    }
    int all_intercec = 0;
    for (int i = 0; i < n; i++)
    {
        available[i] = 0;
        generate_permutations (1, n, i, available, p, all_intercec);
        available[i] = 1;
    }
    
    printf ("%d", len - max_intercec);
    for (int i = 0; i < n; i++)
    {
        free (strings[i]);
    }
    free (strings);
    return 0;
}
