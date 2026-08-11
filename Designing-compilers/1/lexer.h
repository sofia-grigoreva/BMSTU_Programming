#ifndef LEXER_H
#define LEXER_H

#include <stdbool.h>
#include <stddef.h>
#include <stdio.h>

#ifndef YY_TYPEDEF_YY_SCANNER_T
#define YY_TYPEDEF_YY_SCANNER_T
typedef void *yyscan_t;
#endif /* YY_TYPEDEF_YY_SCANNER_T */

struct Extra {
    bool continued;
    int cur_line;
    int cur_column;
};

typedef struct Output {
    char *buf;
    size_t len;
    size_t cap;
    int indent;
    bool need_space;
    bool after_bar;
} Output;

void init_scanner(FILE *input, yyscan_t *scanner, struct Extra *extra);
void destroy_scanner(yyscan_t scanner);

char *lex_dup(yyscan_t scanner, const char *text);

#endif /* LEXER_H */
