void bubblesort(unsigned long nel, 
            int (*compare)(unsigned long i, unsigned long j), 
            void (*swap)(unsigned long i, unsigned long j)){
    unsigned long left = 0;
    unsigned long right = nel - 1;
    if (nel <= 1) 
    {
        return;
    }
    while (left <= right) 
    {
        for (unsigned long i = left; i < right; ++i) 
        {
            if ((compare (i , i + 1)) == 1) 
            {
                swap(i, i + 1);
            }
        }
        right--;
        for (unsigned long i = right; i > left; --i) 
        {
            if ((compare (i - 1, i)) == 1)
            {
                swap(i - 1, i);
            }
        }
        left++;
    }
}
