#include <stdio.h>
#include <stdlib.h>

struct Elem {
    struct Elem *prev, *next;
    int v;
};

struct Elem* InitDoubleLinkedList (){
    struct Elem* newe = (struct Elem*)calloc(1, sizeof(struct Elem));
	newe->prev = newe;
	newe->next = newe;
	return newe;
}

void InsertAfter(struct Elem* x, struct Elem* y)
{
	struct Elem* z = x->next;
	x->next = y;
	y->prev = x;
	y->next = z;
	z->prev = y;
}

void Delete(struct Elem* x)
{
	struct Elem* y = x->prev;
	struct Elem* z = x->next;
	y->next = z;
	z->prev = y;
	x->prev = NULL;
	x->next = NULL;
}

void InsertSort(struct Elem* e)
{
	struct Elem* i = e->next;
    while(i != e) 
    {
        struct Elem* j = i->prev;
		while(j != e && j->v > i->v)
		{
			j = j->prev;
		}
		Delete(i);
		InsertAfter(j, i);
		i = i->next;
	}
}

int main() {
    int n;
	scanf("%d", &n);
	
	struct Elem* e = InitDoubleLinkedList();
	struct Elem* a = malloc(sizeof(struct Elem) * n);
	
	for(int i = 0; i < n; i++) 
	{
		scanf("%d", &a[i].v);
		InsertAfter(e->prev, &a[i]);
	}
	
	InsertSort(e);
	
	struct Elem* t = e->next;
	while(1) 
	{
		printf("%d ", t->v);
		t = t->next;
		if (t == e)
		{
		    break;
		}
	}

	free(a);
	free(e);
	return 0;
}
