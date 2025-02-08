#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int max(int a, int b)
{
    if (a > b) return a;
    return b;
}

int min(int a, int b)
{
    if (a < b) return a;
    return b;
}

struct Stack{
    int data[200000];
    int top;
} ;


struct Stack* InitStack() {
    struct Stack* newStack = malloc(sizeof(struct Stack));
    newStack->top = 0;
    return newStack;
}

int Peek(struct Stack* stack) {
    return stack->data[stack->top - 1];
}

void Push(struct Stack* stack, int x) 
{
    stack->data[stack->top] = x;
    stack->top = stack->top + 1;
}

int Pop(struct Stack* stack) 
{
    stack->top = stack->top - 1;
    return stack->data[stack->top];
}


int main() {
    
    struct Stack* stack = InitStack();
    int x,a,b;
    char str[6];
    scanf("%s", str);
 
    while (strcmp(str, "END") != 0)
    { 
        if (strcmp(str, "CONST") == 0) 
        {
            scanf("%d", &x);
            Push(stack, x);
        }
        else if (strcmp(str, "ADD") == 0) 
        {
            scanf("%d", &x);
            a = Pop(stack);
            b = Pop(stack);
            Push(stack, a+b);
        }
        else if (strcmp(str, "SUB") == 0) 
        {
            a = Pop(stack);
            b = Pop(stack);
            Push(stack, a-b);
        }
        else if (strcmp(str, "MUL") == 0) 
        {
            a = Pop(stack);
            b = Pop(stack);
            Push(stack, a*b);
        }
        else if (strcmp(str, "DIV") == 0) 
        {
            a = Pop(stack);
            b = Pop(stack);
            Push(stack, (a - (a%b)) / b);
        }
        else if (strcmp(str, "MAX") == 0) 
        {
            a = Pop(stack);
            b = Pop(stack);
            Push(stack, max(a,b));
        }
        else if (strcmp(str, "MIN") == 0) 
        {
            a = Pop(stack);
            b = Pop(stack);
            Push(stack, min(a,b));
        }
        else if (strcmp(str, "NEG") == 0) 
        {
            a = Pop(stack);
            Push(stack, a * -1);
        }
        else if (strcmp(str, "DUP") == 0) 
        {
            Push(stack, Peek(stack));
        }
        else if (strcmp(str, "SWAP") == 0) 
        {
            a = Pop(stack);
            b = Pop(stack);
            Push(stack, a);
            Push(stack, b);
        }
        scanf("%s", str);
    }
    printf("%d", Peek(stack));
    free(stack);
	return 0;
}
