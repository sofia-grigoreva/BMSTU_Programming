#include <stdio.h>
#include <stdlib.h>

void MergeSort2 (long* a, long* result, int left, int right) 
{
  if (left < right) 
  {
    long middle = (left + right) / 2;
    MergeSort2 (a, result, left, middle);
    MergeSort2 (a, result, middle + 1, right);
    int result_index = left;
    long j = middle + 1;
    for (long i = left; i <= middle || j <= right;) 
    {
      if (i > middle || (j <= right && labs (a[j]) < labs  (a[i])))
      {
        result[result_index] = a[j];
        j++;
      } 
      else 
      {
        result[result_index] = a[i];
        i++;
      }
      result_index++;
    }
    for (long i = left; i <= right; ++i) 
    {
      a[i] = result[i];
    }
  }
}

void InsertionSort(long* a, long n) 
{
  for (long i = 1; i < n; i++) 
  {
    long x = a[i];
    long j = i;
    while (j > 0 && labs (a[j - 1]) > labs(x)) 
    {
      a[j] = a[j - 1];
      j--;
    }
    a[j] = x;
  }
}

void MergeSort(long* a, long n) 
{ 
  if (n <= 1) {return;}
  if (n<5)
  {
    InsertionSort(a,n);
  }
  else
  {
    long result [n];
    MergeSort2 (a, result, 0, n - 1);
  }
}

int main() {
    long n;
    scanf ("%ld", &n);
    long arr[n];
    for (long i = 0; i < n; i++) 
    {
        scanf("%ld", &arr[i]);
    }
    MergeSort(arr, n);
    for (long i = 0; i < n; i++) 
    {
        printf("%ld ", arr[i]);
    }
    return 0;
}
