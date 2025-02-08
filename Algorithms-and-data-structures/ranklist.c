#include <stdio.h>
#include <stdlib.h>
#include <string.h>

struct SkipList {
    int k;
    char* v;
    struct SkipList ** next;
    int* span;
};


struct SkipList* InitSkipList(int m) {
    struct SkipList* newl = malloc(sizeof(struct SkipList));
    newl->next = calloc(m, sizeof(struct SkipList*));
    newl->span = calloc(m, sizeof(int));
    newl->k = 1000000000;
    newl->v = 0;
    return newl;
}

struct SkipList* Succ(struct SkipList* l) {
    return l->next[0];
}

int Rank(struct SkipList* l, int m, int k) {
    if (k == 1000000000) return -1;
    int res = 0;
    for (int i = m - 1; i >= 0; i--) 
    {
        while (l->next[i] != NULL && l->next[i]->k < k) 
        {
            res += l->span[i];
            l = l->next[i];
        }
    }
    return res;
}

struct SkipList** Skip(struct SkipList* l, int m, int k, struct SkipList** p) {
    struct SkipList* x = l;
    int i = m - 1;
    while (i >= 0) 
    {
        while (x->next[i] != NULL && x->next[i]->k < k) 
        {
            x = x->next[i];
        }
        p[i] = x;
        i--;
    }
    return p;
}

char* Lookup(struct SkipList* l, int m, int k) {
    struct SkipList **p = malloc(m * sizeof(struct SkipList*));
    Skip(l, m, k, p);
    struct SkipList* x = Succ(p[0]);
    free(p);
    return x->v;
}

void Insert(struct SkipList* l, int m, int k, char* v) {
    struct SkipList **p = malloc(m * sizeof(struct SkipList*));
    Skip(l, m, k, p);
    struct SkipList* x = InitSkipList(m);
    x->v = v;
    x->k = k;
    long long r = rand() << 1;
    int rx = Rank(l, m, p[0]->k);
    int i;
    for (i = 0; i < m && r % 2 == 0; ++i) 
    {
        x->next[i] = p[i]->next[i];
        p[i]->next[i] = x;
        int t = rx - Rank(l, m, p[i]->k);
        x->span[i] = p[i]->span[i] - t;
        p[i]->span[i] = t + 1;
        r >>= 1;
    }
    while (i < m)
    {
        p[i]->span[i]++;
        i++;
    }
    free(p);
}

void Delete(struct SkipList *l, int m, int k) {
    struct SkipList **p = malloc(m * sizeof(struct SkipList*));
    Skip(l, m, k, p);
    struct SkipList *x = Succ(p[0]);
    int i = 0;
    while (i < m && p[i]->next[i] == x) 
    {
        p[i]->span[i] += x->span[i] - 1;
        p[i]->next[i] = x->next[i];
        i++;
    }
    while(i < m)
    {
        p[i]->span[i]--;
        i++;
    }
    free(x->v);
    free(x->next);
    free(x->span);
    free(x);
    free(p);
}


int main() {
   int m = 17;
    int k;
    struct SkipList* l = InitSkipList(m);
    char str[6];
    scanf("%s", str);
    
    while (strcmp(str, "END") != 0) 
    {
        if (strcmp(str, "INSERT") == 0) 
        {
            char* v = malloc(11);
            scanf("%d", &k);
            scanf("%s", v);
            Insert(l, m, k, v);
        } 
        else if (strcmp(str, "LOOKUP") == 0) 
        {
            scanf("%d", &k);
            printf("%s\n", Lookup(l, m, k));
        } 
        else if (strcmp(str, "DELETE") == 0) 
        {
            scanf("%d", &k);
            Delete(l, m, k);
        } 
        else if (strcmp(str, "RANK") == 0) 
        {
            scanf("%d", &k);
            printf("%d\n", Rank(l, m, k));
        }
        scanf("%s", str);
    }
    
    while (l) 
    {
        struct SkipList* t = l->next[0];
        if (l->v != NULL)
        { 
            free(l->v);
        }
        free(l->next);
        free(l->span);
        free(l);
        l = t;
    }
    return 0;
}
