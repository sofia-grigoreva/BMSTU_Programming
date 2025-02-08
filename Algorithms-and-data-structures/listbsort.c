#include <stdio.h>
#include <stdlib.h>
#include <string.h>

struct Elem {
    struct Elem *next;
    char *word;
};

struct Elem* InitSingleLinkedList() {
    return NULL;
}

int ListEmpty(struct Elem* e) {
    return e == NULL;
}

struct Elem* Insert(struct Elem* e, const char* str) {
    struct Elem* newe = malloc(sizeof(struct Elem));
    newe->word = (char*)malloc(strlen(str) + 1);
    strcpy(newe->word, str);
    newe->next = e;
    return newe;
}


struct Elem *bsort(struct Elem *e){
    if (e == NULL) return e;
    struct Elem * copye = e;
	char* s;
	int j = 1;
	while(j != 0)
	{
		j = 0;
		for (struct Elem *i = copye; i->next != NULL; i = i->next) 
		{
			if (strlen(i->word) > strlen(i->next->word))
			{
				s = i->word;
				i->word = i->next->word;
				i->next->word = s;
				j++;
			}
		}
	}
	return e;
}


int main() {
    char str[1000];
    fgets(str, sizeof(str), stdin);
    char str_copy[1000];
    strcpy(str_copy, str);
    char* words[500];
    int n = 0;
    char* word = strtok(str_copy, " ");
    while (word != NULL) {
        words[n] = word;
        n++;
        word = strtok(NULL, " ");
    }
    if (words[n - 1][strlen(words[n - 1]) - 1] == '\n') {
        words[n - 1][strlen(words[n - 1]) - 1] = '\0';
    }
    if (n == 1) {
        printf("%s", words[0]);
        return 0;
    }

    struct Elem* e = InitSingleLinkedList();
    for (int i = n - 1; i >= 0; i--) 
    {
        e = Insert(e, words[i]);
    }

    e = bsort(e);

    while (!ListEmpty(e)) {
        printf("%s ", e->word);
        struct Elem* t = e->next;
        free(e->word);
        free(e);
        e = t;
    }

    return 0;
}
