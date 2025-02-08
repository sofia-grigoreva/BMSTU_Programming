#include <stdio.h>
#include <stdlib.h>
#include <string.h>

struct Queue
{
    int *data;
    int cap;
    int count;
    int head;
    int tail;
};

struct Queue * InitQueue ()
{
    struct Queue *newq = malloc (sizeof (struct Queue));
    newq->data = malloc (4 * sizeof (int));
    newq->cap = 4;
    newq->count = 0;
    newq->head = 0;
    newq->tail = 0;
    return newq;
}

int QueueEmpty (struct Queue *q)
{
    return q->count == 0;
}

void
Enqueue (struct Queue *q, int x)
{
    if (q->count == q->cap)
        {
            int *newData = malloc (sizeof (int) * q->cap * 2);
            for (int i = 0; i < q->count; i++)
                {
                    newData[i] = q->data[(q->head + i) % q->cap];
                }
            free (q->data);
            q->data = newData;
            q->cap = q->cap * 2;
            q->head = 0;
            q->tail = q->count;
        }
    q->data[q->tail] = x;
    q->tail = q->tail + 1;
    if (q->tail == q->cap)
        {
            q->tail = 0;
        }
    q->count = q->count + 1;
}

int Dequeue (struct Queue *q)
{
    int x = q->data[q->head];
    q->head = q->head + 1;
    if (q->head == q->cap)
        {
            q->head = 0;
        }
    q->count = q->count - 1;
    return x;
}

int main ()
{
    struct Queue *q = InitQueue ();
    int x;
    char str[6];
    scanf ("%s", str);

    while (strcmp (str, "END") != 0)
        {
            if (strcmp (str, "ENQ") == 0)
                {
                    scanf ("%d", &x);
                    Enqueue (q, x);
                }
            else if (strcmp (str, "DEQ") == 0)
                {
                    printf ("%d\n", Dequeue (q));
                }
            else if (strcmp (str, "EMPTY") == 0)
                {
                    if (QueueEmpty (q) == 0)
                        printf ("false\n");
                    else
                        printf ("true\n");
                }
            scanf ("%s", str);
        }

    free (q->data);
    free (q);
    return 0;
}
