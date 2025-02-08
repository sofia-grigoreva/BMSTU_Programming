#include <stdio.h>
#include <stdlib.h>

int max(int a, int b)
{
    if (a > b) return a;
    return b;
}

struct Task{
    int start;
    int duration;
};

struct PriorityQueue{
    int* heap;
    int cap;
    int count;
};

struct PriorityQueue* InitPriorityQueue(int n) {
    struct PriorityQueue* newq = (struct PriorityQueue*)malloc(sizeof(struct PriorityQueue));
    newq->heap = (int*)malloc(sizeof(int) * n);
    newq->cap = n;
    newq->count = 0;
    return newq;
}


int QueueEmpty(struct PriorityQueue* q) {
    return q->count == 0;
}

void Insert(struct PriorityQueue* q, int x) {
    int i = q->count;
    q->count = i + 1;
    q->heap[i] = x;
    while (i > 0 && (q->heap[(i - 1) / 2] > q->heap[i])) {
        int t = q->heap[i];
        q->heap[i] = q->heap[(i - 1) / 2];
        q->heap[(i - 1) / 2] = t;
        i = (i - 1) / 2;
    }
}

void Heapify(int i, int n, int* P) {
    while (1) {
        int l = 2 * i + 1;
        int r = l + 1;
        int j = i;
        if (l < n && (P[i] > P[l])) {
            i = l;
        }
        if (r < n && (P[i] > P[r])) {
            i = r;
        }
        if (i == j) {
            break;
        }
        int t = P[i];
        P[i] = P[j];
        P[j] = t;
    }
}

int ExtractMax(struct PriorityQueue* q) {
    int ptr = q->heap[0];
    q->count = q->count - 1;
    if (q->count > 0) 
    {
        q->heap[0] = q->heap[q->count];
        Heapify(0, q->count, q->heap);
    }
    return ptr;
}

int main() {
    int n, m;
    scanf("%d", &n); 
    scanf("%d", &m); 
    
    struct Task* tasks = (struct Task*)malloc(sizeof(struct Task) * m);

    for (int i = 0; i < m; i++)
    {
        scanf("%d %d", &tasks[i].start, &tasks[i].duration);
    }

    struct PriorityQueue* q = InitPriorityQueue(m);
    int ans = 0;
    
    for (int i = 0; i < m; i++) 
    {
        if (q->count < n) 
        {
            Insert(q, tasks[i].start + tasks[i].duration);
        } 
        else 
        {
            ans = ExtractMax(q);
            Insert(q, max(ans, tasks[i].start) + tasks[i].duration);
        }
    }

    while (q->count > 0) 
    {
        ans = ExtractMax(q);
    }

    printf("%d", ans);
    
    free(tasks);
    free(q->heap);
    free(q);

    return 0;
}
