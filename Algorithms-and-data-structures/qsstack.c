#include <stdio.h>

struct Task 
{
    int low, high;
};

int transfer (long* a, int l, int r) 
{
  long x = a[r];
  int less = l;
  for (long i = l; i < r; i++) 
  {
    if (a[i] <= x) 
    {
        long k = a[less];
        a[less] = a[i];
        a[i] = k;
        less++;
    }
  }
  long k = a[less];
  a[less] = a[r];
  a[r] = k;
  return less;
}

void QuickSort(long* a, long n) 
{
    struct Task stack[n];
    int pos = 0;
    stack[pos].low = 0;
    stack[pos].high = n - 1;
    while (pos >= 0) 
    {
        int l = stack[pos].low;
        int r = stack[pos].high;
        pos--;
        int q = transfer(a, l, r);
        
        if (q - 1 > l) 
        {
            pos++;
            stack[pos].low = l;
            stack[pos].high = q - 1;
        }

        if (q + 1 < r) 
        {
            pos++;
            stack[pos].low = q + 1;
            stack[pos].high = r;
        }
    }
}


int main() {
    long n;
    scanf("%ld", &n);
    long a[n];
    for (long  i = 0; i < n; i++) 
    {
        scanf("%ld", &a[i]);
    }
    QuickSort(a, n);
    for (long i = 0; i < n; i++) 
    {
        printf("%ld ", a[i]);
    }

    return 0;
}
