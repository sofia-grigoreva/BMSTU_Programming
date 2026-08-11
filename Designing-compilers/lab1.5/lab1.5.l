%option noyywrap bison-bridge bison-locations

%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

#define TAG_NUMBER  1
#define TAG_STRING  2

char *tag_names[] = {
    "END_OF_PROGRAM", "NUMBER", "STRING"
};

struct Position {
    int line, pos, index;
};

void print_pos(struct Position *p) {
    printf("(%d, %d)", p->line, p->pos);
}

struct Fragment {
    struct Position starting, following;
};

typedef struct Fragment YYLTYPE;

void print_frag(struct Fragment *f) {
    print_pos(&(f->starting));
    printf("-");
    print_pos(&(f->following));
}

struct Message {
    char *text;
    struct Position pos;
};

struct MessageList {
    int idx;
    int capacity;
    struct Message *messages;
};

union Token {
    long long num;
    char *str;
};

typedef union Token YYSTYPE;

int continued;
struct Position cur;
struct MessageList msg_list;

#define YY_USER_ACTION { \
    int i; \
    if (!continued) yylloc->starting = cur; \
    continued = 0; \
    for (i = 0; i < yyleng; i++) { \
        if (yytext[i] == '\n') { \
            cur.line++; \
            cur.pos = 1; \
        } else { \
            cur.pos++; \
        } \
        cur.index++; \
    } \
    yylloc->following = cur; \
}

static char *append_text(char *dst, const char *src) {
    size_t len1 = strlen(dst);
    size_t len2 = strlen(src);
    char *tmp = malloc(len1 + len2 + 1);
    if (!tmp) {
        perror("Memory allocation failed");
        exit(1);
    }
    memcpy(tmp, dst, len1);
    memcpy(tmp + len1, src, len2);
    tmp[len1 + len2] = '\0';
    free(dst);
    return tmp;
}

static char *append_char(char *dst, char c) {
    size_t len = strlen(dst);
    char *tmp = malloc(len + 2);
    if (!tmp) {
        perror("Memory allocation failed");
        exit(1);
    }
    memcpy(tmp, dst, len);
    tmp[len] = c;
    tmp[len + 1] = '\0';
    free(dst);
    return tmp;
}

void init_scanner(char *program) {
    continued = 0;

    cur.line = 1;
    cur.pos = 1;
    cur.index = 0;

    msg_list.idx = 0;
    msg_list.capacity = 8;
    msg_list.messages = malloc(msg_list.capacity * sizeof(struct Message));
    if (!msg_list.messages) {
        perror("Memory allocation failed");
        exit(1);
    }

    yy_scan_string(program);
}

void err(const char *msg) {
    if (msg_list.idx == msg_list.capacity) {
        msg_list.capacity *= 2;
        struct Message *tmp = realloc(
            msg_list.messages,
            msg_list.capacity * sizeof(struct Message)
        );
        if (!tmp) {
            perror("Memory allocation failed");
            exit(1);
        }
        msg_list.messages = tmp;
    }

    msg_list.messages[msg_list.idx].text = strdup(msg);
    if (!msg_list.messages[msg_list.idx].text) {
        perror("Memory allocation failed");
        exit(1);
    }
    msg_list.messages[msg_list.idx].pos = cur;
    msg_list.idx++;
}

void print_errors() {
    if (msg_list.idx == 0) {
        return;
    }

    printf("\nErrors:\n");
    for (int i = 0; i < msg_list.idx; i++) {
        print_pos(&msg_list.messages[i].pos);
        printf(": %s\n", msg_list.messages[i].text);
    }
}

char *read_file(const char *filename) {
    FILE *f = fopen(filename, "rb");
    if (!f) {
        perror("Cannot open file");
        exit(1);
    }

    fseek(f, 0, SEEK_END);
    long size = ftell(f);
    rewind(f);

    char *buffer = malloc(size + 1);
    if (!buffer) {
        perror("Memory allocation failed");
        fclose(f);
        exit(1);
    }

    if (fread(buffer, 1, size, f) != (size_t)size) {
        perror("Cannot read file");
        fclose(f);
        free(buffer);
        exit(1);
    }

    buffer[size] = '\0';
    fclose(f);
    return buffer;
}

void free_memory() {
    for (int i = 0; i < msg_list.idx; i++) {
        free(msg_list.messages[i].text);
    }
    free(msg_list.messages);
}

%}

NUMBER   0|1+
WS       [ \t\r\n]+

%x REG_STRING
%x VERB_STRING

%%

{WS}              ;

{NUMBER}          {
                    if (yytext[0] == '0') {
                        yylval->num = 0;
                    } else {
                        yylval->num = yyleng;
                    }
                    return TAG_NUMBER;
                  }

@\"               {
                    BEGIN(VERB_STRING);
                    yylval->str = strdup("");
                    if (!yylval->str) {
                        perror("Memory allocation failed");
                        exit(1);
                    }
                    continued = 1;
                  }

\"                {
                    BEGIN(REG_STRING);
                    yylval->str = strdup("");
                    if (!yylval->str) {
                        perror("Memory allocation failed");
                        exit(1);
                    }
                    continued = 1;
                  }

<REG_STRING>\\n   {
                    yylval->str = append_char(yylval->str, '\n');
                    continued = 1;
                  }

<REG_STRING>\\t   {
                    yylval->str = append_char(yylval->str, '\t');
                    continued = 1;
                  }

<REG_STRING>\\\"  {
                    yylval->str = append_char(yylval->str, '"');
                    continued = 1;
                  }

<REG_STRING>\\[0-9]{1,3}  {
                    yylval->str = append_char(yylval->str, atoi(yytext + 1));
                    continued = 1;
                  }


<REG_STRING>[^\\\"\n]+ {
                    yylval->str = append_text(yylval->str, yytext);
                    continued = 1;
                  }

<REG_STRING>\"    {
                    BEGIN(INITIAL);
                    return TAG_STRING;
                  }

<REG_STRING>\n    {
                    err("newline in regular string");
                    BEGIN(INITIAL);
                  }

<REG_STRING><<EOF>> {
                    err("end of program found, '\"' expected for regular string");
                    BEGIN(INITIAL);
                    return 0;
                  }

<VERB_STRING>\"\" {
                    yylval->str = append_char(yylval->str, '"');
                    continued = 1;
                  }

<VERB_STRING>\"   {
                    BEGIN(INITIAL);
                    return TAG_STRING;
                  }

<VERB_STRING>[^\"\n]+ {
                    yylval->str = append_text(yylval->str, yytext);
                    continued = 1;
                  }

<VERB_STRING>\n   {
                    yylval->str = append_char(yylval->str, '\n');
                    continued = 1;
                  }

<VERB_STRING><<EOF>> {
                    err("end of program found, '\"' expected for literal string");
                    BEGIN(INITIAL);
                    return 0;
                  }

.                 {
                    err("unexpected character");
                  }

<<EOF>>           {
                    return 0;
                  }

%%

// В регулярных строках можно использовать escape-последовательности вида \ц \цц \ццц
// где ц - десятичная цифра

int main(int argc, char **argv) {
    if (argc < 2) {
        printf("Usage: %s <input-file>\n", argv[0]);
        return 1;
    }

    char *program = read_file(argv[1]);

    int tag;
    YYSTYPE value;
    YYLTYPE coords;

    init_scanner(program);

    do {
        tag = yylex(&value, &coords);
        if (tag != 0) {
            printf("%s ", tag_names[tag]);
            print_frag(&coords);
            printf(":");

            if (tag == TAG_NUMBER) {
                printf(" %lld", value.num);
            } else if (tag == TAG_STRING) {
                printf(" %s", value.str);
                free(value.str);
            }

            printf("\n");
        }
    } while (tag != 0);

    print_errors();

    free(program);
    free_memory();
    return 0;
}