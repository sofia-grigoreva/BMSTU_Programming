#include <stdio.h>
#include <stdlib.h>
#include <string.h>

struct List {
    int key;
    int value;
    struct List * next;
};

struct DispArray {
    struct List** table;
};

int hash_function(int key, int m) {
    return key % m;
}

struct DispArray* InitHashTable(int m) {
    struct DispArray* new = malloc(sizeof(struct DispArray));
    new->table = (struct List**)calloc(m, sizeof(struct List*)); 
    for (int i = 0; i < m; i++) 
    {
        new->table[i] = NULL;
    }
    return new;
}

int ListSearch (struct List* l, int k){
    while (l != NULL) 
    {
        if (l->key == k) 
        {
            return l->value;  
        }
        l = l->next;
    }
    return 0; 
}

int MapSearch(struct DispArray* a, int h, int k) {
    struct List* l = a->table[h];
    return ListSearch (l, k) != 0;
}


int Lookup(int h, int k, struct DispArray* a) {
    struct List* l = a->table[h];
    return ListSearch (l, k);
}


void Insert (struct DispArray* a, int m, int k, int v){
    int i = hash_function(k, m);
    if (MapSearch(a, i, k))
    {
        struct List* l = a->table[i];
        while (l != NULL) 
        {
            if (l->key == k) 
            {
                l->value = v;
                return;
            }
            l = l->next;
        }
    } 
    else 
    {
        struct List* new_l = (struct List*)malloc(sizeof(struct List));
        new_l->key = k;
        new_l->value = v;
        new_l->next = a->table[i];
        a->table[i] = new_l;
    }
}


int At(int k, struct DispArray* a, int m) {
    int i = hash_function(k, m);
    if (MapSearch(a, i, k)) 
    {
        return Lookup(i, k, a);
    } 
    else 
    {
        return 0;  
    }
}

int main() {
    int m;
    scanf("%d", &m);
    struct DispArray* a = InitHashTable(m);
    int k, v;
    char str[6];
    scanf("%s", str);
    
    while (strcmp(str, "END") != 0) 
    {
        if (strcmp(str, "ASSIGN") == 0) 
        {
            scanf("%d", &k);
            scanf("%d", &v);
            Insert(a, m, k, v);
        } 
        else if (strcmp(str, "AT") == 0) 
        {
            scanf("%d", &k);
            printf("%d\n", At(k, a, m));
        }
        scanf("%s", str);
    }
    
    
    for (int i = 0; i < m; i++) 
    {
        struct List* l = a->table[i];
        while (l != NULL) 
        {
            struct List* t = l->next;
            free(l);
            l = t;
        }
    }
    free(a->table);
    free(a);
    return 0;
}
