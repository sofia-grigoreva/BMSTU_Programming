#include <stdio.h>
#include <stdlib.h>

struct Key{
    int* v;
    int index;
    int k;
};

struct PriorityQueue{
    struct Key* heap;
    int cap;
    int count;
};

struct PriorityQueue* InitPriorityQueue(int n) {
    struct PriorityQueue* newq = (struct PriorityQueue*)malloc(sizeof(struct PriorityQueue));
    newq->heap = (struct Key*)malloc(sizeof(struct Key) * n);
    newq->cap = n;
    newq->count = 0;
    return newq;
}

int comparer(struct Key a, struct Key b) {
    return a.v[a.index] > b.v[b.index];
}

int QueueEmpty(struct PriorityQueue* q) {
    return q->count == 0;
}

void Insert(struct PriorityQueue* q, struct Key x) {
    int i = q->count;
    q->count = i + 1;
    q->heap[i] = x;
    while (i > 0 && comparer(q->heap[(i - 1) / 2], q->heap[i])) {
        struct Key t = q->heap[i];
        q->heap[i] = q->heap[(i - 1) / 2];
        q->heap[(i - 1) / 2] = t;
        i = (i - 1) / 2;
    }
}

void Heapify(int i, int n, struct Key* P) {
    while (1) {
        int l = 2 * i + 1;
        int r = l + 1;
        int j = i;
        if (l < n && comparer(P[i], P[l])) {
            i = l;
        }
        if (r < n && comparer(P[i], P[r])) {
            i = r;
        }
        if (i == j) {
            break;
        }
        struct Key t = P[i];
        P[i] = P[j];
        P[j] = t;
    }
}

struct Key ExtractMax(struct PriorityQueue* q) {
    struct Key ptr = q->heap[0];
    q->count = q->count - 1;
    if (q->count > 0) {
        q->heap[0] = q->heap[q->count];
        Heapify(0, q->count, q->heap);
    }
    return ptr;
}

int main() {
    int n, c = 0;
    scanf("%d", &n);
    int* lens = (int*)malloc(sizeof(int) * n);
    int** a = (int**)malloc(sizeof(int*) * n);

    for (int i = 0; i < n; i++) {
        scanf("%d", &lens[i]);
        c += lens[i];
    }

    struct PriorityQueue* q = InitPriorityQueue(c);

    for (int i = 0; i < n; i++) {
        a[i] = (int*)malloc(sizeof(int) * lens[i]);
        for (int j = 0; j < lens[i]; j++) {
            scanf("%d", &(a[i][j]));
        }
        struct Key arr;
        arr.k = lens[i];
        arr.v = a[i];
        arr.index = 0;
        Insert(q, arr);
    }

    while (1) {
        if (QueueEmpty(q)) {
            break;
        }
        struct Key t = ExtractMax(q);
        printf("%d ", t.v[t.index]);
        t.index = t.index + 1;
        int i = t.index;
        if (i < t.k) {
            t.v[t.index] = t.v[i];
            Insert(q, t);
        }
    }

    for (int i = 0; i < n; i++) {
        free(a[i]);
    }
    free(a);
    free(lens);
    free(q->heap);
    free(q);
    return 0;
}
