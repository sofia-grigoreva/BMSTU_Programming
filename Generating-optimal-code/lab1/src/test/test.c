#include <stdio.h>

int g0[10];

int f0(int a0, int b0)
{
    int t0;

    t0 = a0 - b0;
    t0 = t0 * 3;
    t0 = t0 + 4;

    g0[2] = t0;
    int t1 = g0[3];

    if (t0 < -2)
    {
        return t0;
    }
    else
    {
        return t1;
    }
}

struct S
{
    int x;
    int y;
};

int main()
{
    int v0, v1, v2;
    int a1[3] = {1, 2, 3};
    int *p0 = &a1[0];

    struct S s0;
    struct S *ps0 = &s0;

    s0.x = 10;
    s0.y = 20;

    int *px0 = &s0.x;

    for (int step = 0; step < 5; step++)
    {
        v0 = f0(step, step + 2);
        printf("Step %d: score = %d\n", step, v0);
    }

    a1[1] = a1[0] + v0;
    a1[2] = a1[1] - 2;

    v2 = *p0;
    *p0 = v2 + a1[2];

    s0.x = s0.x + v0;
    s0.y = s0.x + s0.y;
    *px0 = *px0 + 1;

    if (v0 < 0)
        v1 = 7;
    else
        v1 = 11;

    v2 = v1 + 1;
    v2 = v2 + *p0;
    v2 = v2 + s0.x;

    return 0;
}