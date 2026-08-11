% Лабораторная работа 3.2 «Форматтер исходных текстов»
% 3 июня 2026 г.
% Софья Григорьева, ИУ9-61Б

# Цель работы
Целью данной работы является приобретение навыков использования генератора синтаксических
анализаторов bison.

# Индивидуальный вариант
Язык L4.

# Реализация

## `lexer.h`

```c
#ifndef LEXER_H
#define LEXER_H

#include <stdbool.h>
#include <stddef.h>
#include <stdio.h>

#ifndef YY_TYPEDEF_YY_SCANNER_T
#define YY_TYPEDEF_YY_SCANNER_T
typedef void *yyscan_t;
#endif

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
} Output;

void init_scanner(FILE *input, yyscan_t *scanner, struct Extra *extra);
void destroy_scanner(yyscan_t scanner);

char *lex_dup(yyscan_t scanner, const char *text);

#endif
```

## `lexer.l`

```lex
%option reentrant noyywrap bison-bridge bison-locations
%option extra-type="struct Extra *"
%option noinput nounput

%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "lexer.h"
#include "parser.tab.h"

void yyerror(YYLTYPE *loc, yyscan_t scanner, Output *out, const char *message);

#define YY_USER_ACTION \
  { \
    int i; \
    struct Extra *extra = yyextra; \
    if (!extra->continued) { \
      yylloc->first_line = extra->cur_line; \
      yylloc->first_column = extra->cur_column; \
    } \
    extra->continued = false; \
    for (i = 0; i < yyleng; ++i) { \
      if (yytext[i] == '\n') { \
        extra->cur_line += 1; \
        extra->cur_column = 1; \
      } else { \
        extra->cur_column += 1; \
      } \
    } \
    yylloc->last_line = extra->cur_line; \
    yylloc->last_column = extra->cur_column; \
  }

char *lex_dup(yyscan_t scanner, const char *text) {
    (void)scanner;
    char *copy = malloc(strlen(text) + 1);
    if (!copy) {
        abort();
    }
    strcpy(copy, text);
    return copy;
}

%}

LETTER      [A-Za-zА-Яа-яЁё]
DIGIT       [0-9]
NAME_CHAR   [A-Za-zА-Яа-яЁё0-9_]
CTRL_NAME   [A-Za-z0-9]+

%%

[ \t\r\n]+

\{[^}]*\}

"%%"        { return END_FUNC; }
"+++"       { return ELSE; }
":="        { return ASSIGN; }

"_and_"             { yylval->lex = lex_dup(yyscanner, yytext); return AND_OP; }
"_or_"              { yylval->lex = lex_dup(yyscanner, yytext); return OR_OP; }
"_xor_"             { yylval->lex = lex_dup(yyscanner, yytext); return XOR_OP; }
"_eq_"              { yylval->lex = lex_dup(yyscanner, yytext); return EQ_OP; }
"_ne_"              { yylval->lex = lex_dup(yyscanner, yytext); return NE_OP; }
"_lt_"              { yylval->lex = lex_dup(yyscanner, yytext); return LT_OP; }
"_gt_"              { yylval->lex = lex_dup(yyscanner, yytext); return GT_OP; }
"_le_"              { yylval->lex = lex_dup(yyscanner, yytext); return LE_OP; }
"_ge_"              { yylval->lex = lex_dup(yyscanner, yytext); return GE_OP; }
"_mod_"             { yylval->lex = lex_dup(yyscanner, yytext); return MOD_OP; }
"_pow_"             { yylval->lex = lex_dup(yyscanner, yytext); return POW_OP; }
"not_"              { yylval->lex = lex_dup(yyscanner, yytext); return NOT_OP; }
"new_"              { yylval->lex = lex_dup(yyscanner, yytext); return NEW_KW; }
"int"|"char"|"bool" { yylval->lex = lex_dup(yyscanner, yytext); return TYPE_KW; }
"true"|"false"|"nothing" {
    yylval->lex = lex_dup(yyscanner, yytext);
    return CONST_KW;
}

{DIGIT}+            { yylval->lex = lex_dup(yyscanner, yytext); return INT_CONST; }
{DIGIT}+{NAME_CHAR}*\{{DIGIT}+\} {
    yylval->lex = lex_dup(yyscanner, yytext);
    return INT_CONST;
}
{LETTER}{NAME_CHAR}*\{{DIGIT}+\} {
    yylval->lex = lex_dup(yyscanner, yytext);
    return INT_CONST;
}

\"([^\"\n\r]|\"\")\" {
    yylval->lex = lex_dup(yyscanner, yytext);
    return CHAR_CONST;
}
\${CTRL_NAME}\$ {
    yylval->lex = lex_dup(yyscanner, yytext);
    return CHAR_CONST;
}

\'[^'\n\r]*\' {
    yylval->lex = lex_dup(yyscanner, yytext);
    return STR_PART;
}
"%"{CTRL_NAME}"%" {
    yylval->lex = lex_dup(yyscanner, yytext);
    return STR_PART;
}

[_!@.#]{NAME_CHAR}+ {
    yylval->lex = lex_dup(yyscanner, yytext);
    return VAR_ID;
}
{LETTER}{NAME_CHAR}* {
    yylval->lex = lex_dup(yyscanner, yytext);
    return FUN_ID;
}

"("     { return '('; }
")"     { return ')'; }
"["     { return '['; }
"]"     { return ']'; }
"|"     { return '|'; }
"<"     { return '<'; }
">"     { return '>'; }
","     { return ','; }
":"     { return ':'; }
"?"     { return '?'; }
"&"     { return '&'; }
"\\"    { return '\\'; }
"^"     { return '^'; }
"+"     { return '+'; }
"-"     { return '-'; }
"*"     { return '*'; }
"/"     { return '/'; }
"%"     { return '%'; }

. yyerror(yylloc, yyscanner, NULL, "Lexer error");

%%

void yyerror(YYLTYPE *loc, yyscan_t scanner, Output *out, const char *message) {
    (void)scanner;
    (void)out;
    printf("Error (%d,%d): %s\n", loc->first_line, loc->first_column, message);
}

void init_scanner(FILE *input, yyscan_t *scanner, struct Extra *extra) {
    extra->continued = false;
    extra->cur_line = 1;
    extra->cur_column = 1;

    yylex_init_extra(extra, scanner);
    yyset_in(input, *scanner);
}

void destroy_scanner(yyscan_t scanner) {
    yylex_destroy(scanner);
}
```

## `parser.y`

```yacc
%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "lexer.h"

static void out_grow(Output *o, size_t need) {
    if (o->len + need + 1 <= o->cap) {
        return;
    }
    size_t cap = o->cap ? o->cap : 256;
    while (o->len + need + 1 > cap) {
        cap *= 2;
    }
    char *next = realloc(o->buf, cap);
    if (!next) {
        abort();
    }
    o->buf = next;
    o->cap = cap;
}

static void out_init(Output *o) {
    o->buf = NULL;
    o->len = 0;
    o->cap = 0;
    o->indent = 0;
    o->need_space = false;
}

static void out_free(Output *o) {
    free(o->buf);
    o->buf = NULL;
    o->len = o->cap = 0;
}

static void out_finish(Output *o) {
    out_grow(o, 1);
    o->buf[o->len] = '\0';
    fputs(o->buf, stdout);
}

static void out_raw(Output *o, const char *s) {
    if (o->need_space && o->len > 0 && o->buf[o->len - 1] != '\n') {
        out_grow(o, 1);
        o->buf[o->len++] = ' ';
    }
    o->need_space = false;
    size_t n = strlen(s);
    out_grow(o, n);
    memcpy(o->buf + o->len, s, n);
    o->len += n;
}

static void out_lex(Output *o, const char *lex) {
    out_raw(o, lex);
}

static void out_space(Output *o) {
    o->need_space = true;
}

static void out_newline(Output *o) {
    if (o->len == 0 || o->buf[o->len - 1] == '\n') {
        o->need_space = false;
        return;
    }
    out_grow(o, 1);
    o->buf[o->len++] = '\n';
    o->need_space = false;
}

static void out_indent(Output *o) {
    for (int i = 0; i < o->indent; ++i) {
        out_raw(o, "  ");
    }
}

static void out_binary(Output *out, const char *op) {
    out_space(out);
    out_lex(out, op);
    out_space(out);
}
%}

%pure-parser
%locations

%lex-param {yyscan_t scanner}
%parse-param {yyscan_t scanner}
%parse-param {Output *out}

%union {
    char *lex;
}

%token <lex> TYPE_KW CONST_KW NEW_KW NOT_OP
%token <lex> AND_OP OR_OP XOR_OP EQ_OP NE_OP LT_OP GT_OP LE_OP GE_OP MOD_OP POW_OP
%token <lex> VAR_ID FUN_ID INT_CONST CHAR_CONST STR_PART
%token ASSIGN END_FUNC ELSE

%{
int yylex(YYSTYPE *yylval_param, YYLTYPE *yylloc_param, yyscan_t scanner);
void yyerror(YYLTYPE *loc, yyscan_t scanner, Output *out, const char *message);
%}

%%

program:
      functions
    ;

functions:
      /* empty */
    | functions function
    ;

function:
      value_function
    | void_function
    ;

value_function:
      '('
      {
          out_raw(out, "(");
      } type function_name_part ')'
      {
          out_raw(out, ")");
          out_newline(out);
          out->indent += 1;
      } stmt_seq_opt END_FUNC
      {
          out->indent -= 1;
          out_newline(out);
          out_indent(out);
          out_raw(out, "%%");
          out_newline(out);
          out_newline(out);
      }
    ;

void_function:
      '['
      {
          out_raw(out, "[");
      } fun_name params ']'
      {
          out_raw(out, "]");
          out_newline(out);
          out->indent += 1;
      } stmt_seq_opt END_FUNC
      {
          out->indent -= 1;
          out_newline(out);
          out_indent(out);
          out_raw(out, "%%");
          out_newline(out);
          out_newline(out);
      }
    ;

function_name_part:
      '['
      {
          out_space(out);
          out_raw(out, "[");
      } fun_name params ']'
      {
          out_raw(out, "]");
      }
    ;

params:
      /* empty */
    | params
      {
          out_space(out);
      } param
    ;

param:
      '('
      {
          out_raw(out, "(");
      } type
      {
          out_space(out);
      } var_name ')'
      {
          out_raw(out, ")");
      }
    ;

type:
      TYPE_KW
      {
          out_lex(out, $1);
          free($1);
      }
    | '<'
      {
          out_raw(out, "<");
      } type '>'
      {
          out_raw(out, ">");
      }
    ;

fun_name:
      FUN_ID
      {
          out_lex(out, $1);
          free($1);
      }
    ;

var_name:
      VAR_ID
      {
          out_lex(out, $1);
          free($1);
      }
    ;

stmt_seq_opt:
      /* empty */
    | {
          out_indent(out);
      } stmt_seq
    ;

stmt_seq:
      stmt
    | stmt_seq ','
      {
          out_raw(out, ",");
          out_newline(out);
          out_indent(out);
      } stmt
    ;

stmt:
      paren_stmt
    | lvalue ASSIGN
      {
          out_space(out);
          out_raw(out, ":=");
          out_space(out);
      } expr
    | call_expr
    | return_stmt
    | assert_stmt
    ;

paren_stmt:
      '('
      {
          out_raw(out, "(");
      } paren_stmt_body
    ;

init_opt:
      /* empty */
    | ASSIGN
      {
          out_space(out);
          out_raw(out, ":=");
          out_space(out);
      } expr
    ;

paren_stmt_body:
      '?'
      {
          out_raw(out, "?");
          out_space(out);
      } expr ')'
      {
          out_raw(out, ")");
          out_newline(out);
          out->indent += 1;
      } stmt_seq_opt
      {
          out->indent -= 1;
      } else_parts '%'
      {
          out_newline(out);
          out_indent(out);
          out_raw(out, "%");
      }
    | '&'
      {
          out_raw(out, "&");
          out_space(out);
      } expr ')'
      {
          out_raw(out, ")");
          out_newline(out);
          out->indent += 1;
      } stmt_seq_opt
      {
          out->indent -= 1;
      } '%'
      {
          out_newline(out);
          out_indent(out);
          out_raw(out, "%");
      }
    | type
      {
          out_space(out);
      } var_name typed_paren_tail
    | var_name for_bounds ')'
      {
          out_raw(out, ")");
          out_newline(out);
          out->indent += 1;
      } stmt_seq_opt
      {
          out->indent -= 1;
      } '%'
      {
          out_newline(out);
          out_indent(out);
          out_raw(out, "%");
      }
    ;

typed_paren_tail:
      ')'
      {
          out_raw(out, ")");
      } init_opt
    | for_bounds ')'
      {
          out_raw(out, ")");
          out_newline(out);
          out->indent += 1;
      } stmt_seq_opt
      {
          out->indent -= 1;
      } '%'
      {
          out_newline(out);
          out_indent(out);
          out_raw(out, "%");
      }
    ;

else_parts:
      /* empty */
    | ELSE
      {
          out_newline(out);
          out_indent(out);
          out_raw(out, "+++");
          out_newline(out);
      } else_branch
    ;

else_branch:
      {
          out->indent += 1;
      } stmt_seq_opt
      {
          out->indent -= 1;
      }
    ;

for_bounds:
      ':'
      {
          out_space(out);
          out_raw(out, ":");
          out_space(out);
      } expr ','
      {
          out_raw(out, ",");
          out_space(out);
      } expr step_opt
    ;

step_opt:
      /* empty */
    | ','
      {
          out_raw(out, ",");
          out_space(out);
      } expr
    ;

return_stmt:
      '^'
      {
          out_raw(out, "^");
      } return_expr_opt
    ;

return_expr_opt:
      /* empty */
    | {
          out_space(out);
      } expr
    ;

assert_stmt:
      '\\'
      {
          out_raw(out, "\\");
          out_space(out);
      } expr
    ;

expr:
      or_expr
    ;

or_expr:
      and_expr
    | or_expr or_op and_expr
    | or_expr xor_op and_expr
    ;

and_expr:
      cmp_expr
    | and_expr and_op cmp_expr
    ;

cmp_expr:
      add_expr
    | cmp_expr eq_op add_expr
    | cmp_expr ne_op add_expr
    | cmp_expr lt_op add_expr
    | cmp_expr gt_op add_expr
    | cmp_expr le_op add_expr
    | cmp_expr ge_op add_expr
    ;

or_op:
      OR_OP
      {
          out_binary(out, $1);
          free($1);
      }
    ;

xor_op:
      XOR_OP
      {
          out_binary(out, $1);
          free($1);
      }
    ;

and_op:
      AND_OP
      {
          out_binary(out, $1);
          free($1);
      }
    ;

eq_op:
      EQ_OP
      {
          out_binary(out, $1);
          free($1);
      }
    ;

ne_op:
      NE_OP
      {
          out_binary(out, $1);
          free($1);
      }
    ;

lt_op:
      LT_OP
      {
          out_binary(out, $1);
          free($1);
      }
    ;

gt_op:
      GT_OP
      {
          out_binary(out, $1);
          free($1);
      }
    ;

le_op:
      LE_OP
      {
          out_binary(out, $1);
          free($1);
      }
    ;

ge_op:
      GE_OP
      {
          out_binary(out, $1);
          free($1);
      }
    ;

add_expr:
      mul_expr
    | add_expr '+'
      {
          out_binary(out, "+");
      } mul_expr
    | add_expr '-'
      {
          out_binary(out, "-");
      } mul_expr
    ;

mul_expr:
      pow_expr
    | mul_expr '*'
      {
          out_binary(out, "*");
      } pow_expr
    | mul_expr '/'
      {
          out_binary(out, "/");
      } pow_expr
    | mul_expr mod_op pow_expr
    ;

mod_op:
      MOD_OP
      {
          out_binary(out, $1);
          free($1);
      }
    ;

pow_expr:
      unary_expr
    | unary_expr pow_op pow_expr
    ;

pow_op:
      POW_OP
      {
          out_binary(out, $1);
          free($1);
      }
    ;

not_op:
      NOT_OP
      {
          out_lex(out, $1);
          out_space(out);
          free($1);
      }
    ;

unary_expr:
      primary
    | '-'
      {
          out_raw(out, "-");
      } unary_expr
    | not_op unary_expr
    ;

primary:
      var_name
    | fun_name
    | INT_CONST
      {
          out_lex(out, $1);
          free($1);
      }
    | CHAR_CONST
      {
          out_lex(out, $1);
          free($1);
      }
    | CONST_KW
      {
          out_lex(out, $1);
          free($1);
      }
    | STR_PART
      {
          out_lex(out, $1);
          free($1);
      }
    | '('
      {
          out_raw(out, "(");
      } expr ')'
      {
          out_raw(out, ")");
      }
    | call_expr
    | index_expr
    | new_expr
    ;

lvalue:
      var_name
    | index_expr
    ;

call_expr:
      '['
      {
          out_raw(out, "[");
      } fun_name call_args ']'
      {
          out_raw(out, "]");
      }
    ;

call_args:
      /* empty */
    | call_args
      {
          out_space(out);
      } unary_expr
    ;

index_expr:
      '<'
      {
          out_raw(out, "<");
      } unary_expr
      {
          out_space(out);
      } expr '>'
      {
          out_raw(out, ">");
      }
    ;

new_expr:
      NEW_KW
      {
          out_lex(out, $1);
          out_space(out);
          free($1);
      } type
      {
          out_space(out);
      } unary_expr
    ;

%%

int main(int argc, char *argv[]) {
    FILE *input = 0;
    yyscan_t scanner;
    struct Extra extra;
    Output out;

    if (argc > 1) {
        fprintf(stderr, "Read file %s\n", argv[1]);
        input = fopen(argv[1], "r");
    } else {
        fprintf(stderr, "No file in command line, use stdin\n");
        input = stdin;
    }

    if (!input) {
        perror("Cannot open input");
        return 1;
    }

    out_init(&out);
    init_scanner(input, &scanner, &extra);
    yyparse(scanner, &out);
    destroy_scanner(scanner);
    out_finish(&out);
    out_free(&out);

    if (input != stdin) {
        fclose(input);
    }

    return 0;
}
```

## `run.sh`

```bash
#!/bin/bash

cd "$(dirname "$0")"

flex lexer.l
bison -d parser.y
gcc -w -I. -o formatter lex.yy.c parser.tab.c
rm -f lex.yy.c parser.tab.?
./formatter input.txt
```

# Тестирование

Входные данные

```
(<int> [SumVectors (<int> !A) (<int> !B)] )(int #size) := [length !A] ,
\ #size _eq_ [length !B] , (<int> #C) := new_ <int> #size ,
(<int> #i : 0, #size - 1) <#C #i> := <!A #i> + <!B #i> % , ^ #C %%
```

Вывод на `stdout`

```
Read file input.txt
(<int> [SumVectors (<int> !A) (<int> !B)])
  (int #size) := [length !A],
  \ #size _eq_ [length !B],
  (<int> #C) := new_ <int> #size,
  (<int> #i : 0, #size - 1)
    <#C #i> := <!A #i> + <!B #i>
  %,
  ^ #C
%%
```

# Вывод
В ходе выполнения лабораторной работы были освоены принципы построения синтаксического
анализатора с помощью генератора bison.