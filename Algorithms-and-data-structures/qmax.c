#include <stdio.h>  
#include <stdlib.h>  
#include <string.h>  
  
int max(int a, int b)  
{  
    if (a > b) return a;  
    return b;  
}  
  
struct Key {  
    int value;  
    int max;  
} ;  
  
struct DoubleStackQueue {  
    struct Key* data;  
    int top1;  
    int top2;  
    int cap;  
};  
  
struct DoubleStackQueue* InitDoubleStackQueue(int n) {  
    struct DoubleStackQueue* news = (struct DoubleStackQueue*)malloc(sizeof (struct DoubleStackQueue));  
    news->data = (struct Key*)malloc(sizeof(struct Key) * n);  
    news->top1 = 0;  
    news->top2 = n - 1;  
    news->cap = n;  
    return news;  
}  
  
int StackEmpty1(struct DoubleStackQueue* q) {  
    return q->top1 == 0;  
}  
  
int StackEmpty2(struct DoubleStackQueue* q) {  
    return q->top2 == q->cap - 1;  
}  
  
void Push1(struct DoubleStackQueue* q, int x) {  
    struct Key k = q->data[q->top1];  
    if(StackEmpty1(q))  
    {k.max = x;}  
    else 
    {  
        if (x > q->data[q->top1 - 1].max)  
        {
            k.max = x;
        }  
        else   
        {
            k.max = q->data[q->top1 - 1].max;
        }  
    }  
          
    k.value = x;  
    q->data[q->top1] = k;  
    q->top1 = q->top1 + 1;  
}  
  
void Push2(struct DoubleStackQueue* q, int x) {  
    struct Key k = q->data[q->top2];  
    if (StackEmpty2(q))  
    {k.max = x;}  
    else   
    {  
        if (x > q->data[q->top2 + 1].max)  
        {
            k.max = x;
        }  
        else   
        {
            k.max = q->data[q->top2 + 1].max;
        }  
    }  
    k.value = x;  
    q->data[q->top2] = k;  
    q->top2 = q->top2 - 1;  
}  
  
  
struct Key Pop1(struct DoubleStackQueue* q){  
    q->top1 = q->top1 - 1;  
    return q->data[q->top1];  
}  
  
struct Key Pop2(struct DoubleStackQueue* q){  
    q->top2 = q->top2 + 1;  
    return q->data[q->top2];  
}  
  
struct Key Dequeue(struct DoubleStackQueue* q) {  
    if(StackEmpty2(q)) 
    { 
        while(!StackEmpty1(q))  
        {
            Push2(q, Pop1(q).value);
        }
    } 
    return Pop2(q);  
}  
  
int Maximum(struct DoubleStackQueue* q) {  
    if (StackEmpty2(q))   
    {
        return q->data[q->top1 - 1].max;
    }  
    if (!StackEmpty1(q) && !StackEmpty2(q))  
    {
        return  max(q->data[q->top1 - 1].max, q->data[q->top2 + 1].max);
    } 
    return q->data[q->top2 + 1].max;  
}  
  
int main() {  
    struct DoubleStackQueue* q = InitDoubleStackQueue(200000);  
    char str[6];  
    int x;  
    scanf("%s", str);  
   
    while (strcmp(str, "END") != 0)   
    { 
        if (strcmp(str, "ENQ") == 0)   
        {  
            scanf("%d", &x);  
            Push1(q,x);  
        }   
        else if (strcmp(str, "DEQ") == 0)   
        {  
            printf("%d\n", Dequeue(q).value);  
        }   
        else if (strcmp(str, "MAX") == 0)   
        {  
            printf("%d\n", Maximum(q));  
        }   
        else if (strcmp(str, "EMPTY") == 0)   
        {  
            if (StackEmpty1(q) && StackEmpty2(q)) printf("true\n");  
            else printf("false\n");  
        }  
        scanf("%s", str);  
    }  
  
    free(q->data);  
    free(q);  
    return 0;  
}
