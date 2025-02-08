void shellsort(unsigned long nel, 
        int (*compare)(unsigned long i, unsigned long j), 
        void (*swap)(unsigned long i, unsigned long j)) {
    if (nel <= 1) 
    {
        return;
    }
    unsigned long f[10000];
    f[0]=1;
    f[1]=2;
    unsigned long i = 2;
    unsigned long i1 = 1;
    unsigned long i2 = 2;
    unsigned long i3 = 0;
    while (i1 + i2 <= nel)
    { 
        i3 = i1 + i2;
        i1 = i2;
        i2 = i3;
        f[i] = i3;
        i++;
    }
    for (long j = i - 1; j >= 0; j--) 
    {
        long d = f[j];
        for (long k = d; k < nel; k++) 
        {
            long loc = k - d;
            while (loc >= 0 && compare(loc, loc + d) == 1) 
            {
                swap(loc, loc + d);
                loc -= d;
            }
        }
    }
}
