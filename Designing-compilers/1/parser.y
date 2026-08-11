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
    o->after_bar = false;
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
        o->need_space = false;
    }
    size_t n = strlen(s);
    out_grow(o, n);
    memcpy(o->buf + o->len, s, n);
    o->len += n;
}

static void out_lex(Output *o, const char *lex) {
    if (o->need_space && o->len > 0 && o->buf[o->len - 1] != '\n') {
        out_grow(o, 1);
        o->buf[o->len++] = ' ';
        o->need_space = false;
    }
    size_t n = strlen(lex);
    out_grow(o, n);
    memcpy(o->buf + o->len, lex, n);
    o->len += n;
}

static void out_newline(Output *o) {
    out_grow(o, 1);
    o->buf[o->len++] = '\n';
    o->need_space = false;
}

static void out_indent(Output *o) {
    for (int i = 0; i < o->indent; ++i) {
        out_raw(o, "  ");
    }
}

static void out_space(Output *o) {
    o->need_space = true;
}
%}

%define api.pure
%locations

%lex-param {yyscan_t scanner}

%parse-param {yyscan_t scanner}
%parse-param {Output *out}

%union {
    char *lex;
}

%destructor { free($$); } <lex>

%token <lex> TYPE_KW FUN_KW WHERE_KW WEND_KW
%token <lex> UIDENT LIDENT INT_LIT
%token ARROW
%token '|' COLON DOT
%token '(' ')' '[' ']'

%{
int yylex(YYSTYPE *yylval_param, YYLTYPE *yylloc_param, yyscan_t scanner);
void yyerror(YYLTYPE *loc, yyscan_t scanner, Output *out, const char *message);
%}

%%

program:
      items
    ;

items:
      /* empty */
    | items item
    ;

item:
      type_decl
    | fun_decl
    ;

type_decl:
      TYPE_KW UIDENT COLON
      {
          out_lex(out, $TYPE_KW);
          out_space(out);
          out_lex(out, $UIDENT);
          out_raw(out, ":");
          out_newline(out);
          out->indent += 1;
          free($TYPE_KW);
          free($UIDENT);
      } type_alt_list DOT
      {
          out->indent -= 1;
          out_raw(out, ".");
          out_newline(out);
      }
    ;

type_alt_list:
      { out_indent(out); } type_variant
    | type_alt_list '|'
      {
          out_newline(out);
          out_indent(out);
          out_raw(out, "| ");
      } type_variant
    ;

type_variant:
      UIDENT
      {
          out_lex(out, $UIDENT);
          free($UIDENT);
      } type_names
    ;

type_names:
      /* empty */
    | type_names UIDENT
      {
          out_space(out);
          out_lex(out, $UIDENT);
          free($UIDENT);
      }
    ;

fun_decl:
      FUN_KW '(' LIDENT
      {
          out_newline(out);
          out_lex(out, $FUN_KW);
          out_space(out);
          out_raw(out, "(");
          out_lex(out, $LIDENT);
          free($FUN_KW);
          free($LIDENT);
      } type_names ')' ARROW UIDENT COLON
      {
          out_raw(out, ")");
          out_space(out);
          out_raw(out, "->");
          out_space(out);
          out_lex(out, $UIDENT);
          out_raw(out, ":");
          out_newline(out);
          out->indent += 1;
          free($UIDENT);
      } rules
      {
          out->indent -= 1;
      }
    ;

rules:
      rule
    | rules rule
    ;

rule:
      '('
      {
          if (out->after_bar) {
              out->after_bar = false;
          } else {
              out_indent(out);
          }
          out_raw(out, "(");
      } patterns ')' ARROW
      {
          out_raw(out, ")");
          out_space(out);
          out_raw(out, "->");
          out_space(out);
      } expr where_part rule_end
    ;

patterns:
      pattern
    | patterns
      {
          out_space(out);
      } pattern
    ;

pattern:
      '[' UIDENT
      {
          out_raw(out, "[");
          out_lex(out, $UIDENT);
          free($UIDENT);
      } pat_list ']'
      {
          out_raw(out, "]");
      }
    | LIDENT
      {
          out_lex(out, $LIDENT);
          free($LIDENT);
      }
    | UIDENT
      {
          out_lex(out, $UIDENT);
          free($UIDENT);
      }
    | INT_LIT
      {
          out_lex(out, $INT_LIT);
          free($INT_LIT);
      }
    ;

pat_list:
      /* empty */
    | pat_list
      {
          out_space(out);
      } pattern
    ;

where_part:
      /* empty */
    | WHERE_KW
      {
          out_newline(out);
          out_indent(out);
          out_lex(out, $WHERE_KW);
          out_newline(out);
          free($WHERE_KW);
      } where_fun_decl WEND_KW
      {
          out_newline(out);
          out_indent(out);
          out_lex(out, $WEND_KW);
          free($WEND_KW);
      }
    ;

where_fun_decl:
      FUN_KW '(' LIDENT
      {
          out->indent += 1;
          out_indent(out);
          out_lex(out, $FUN_KW);
          out_space(out);
          out_raw(out, "(");
          out_lex(out, $LIDENT);
          free($FUN_KW);
          free($LIDENT);
      } type_names ')' ARROW UIDENT COLON
      {
          out_raw(out, ")");
          out_space(out);
          out_raw(out, "->");
          out_space(out);
          out_lex(out, $UIDENT);
          out_raw(out, ":");
          out_newline(out);
          out->indent += 1;
          free($UIDENT);
      } where_rules
      {
          out->indent -= 2;
      }
    ;

where_rules:
      where_rule
    | where_rules where_rule
    ;

where_rule:
      '('
      {
          if (out->after_bar) {
              out->after_bar = false;
          } else {
              out_indent(out);
          }
          out_raw(out, "(");
      } patterns ')' ARROW
      {
          out_raw(out, ")");
          out_space(out);
          out_raw(out, "->");
          out_space(out);
      } expr rule_end
    ;

rule_end:
      '|'
      {
          out_newline(out);
          out_indent(out);
          out_raw(out, "| ");
          out->after_bar = true;
      }
    | DOT
      {
          out_raw(out, ".");
          out_newline(out);
      }
    ;

expr:
      expr
      {
          out_space(out);
      } atom
    | atom
    ;

atom:
      LIDENT
      {
          out_lex(out, $LIDENT);
          free($LIDENT);
      }
    | UIDENT
      {
          out_lex(out, $UIDENT);
          free($UIDENT);
      }
    | INT_LIT
      {
          out_lex(out, $INT_LIT);
          free($INT_LIT);
      }
    | '('
      {
          out_raw(out, "(");
      } expr ')'
      {
          out_raw(out, ")");
      }
    | list_expr
    ;

list_expr:
      '['
      {
          out_raw(out, "[");
      } expr ']'
      {
          out_raw(out, "]");
      }
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
