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

%%

[ \t\r\n]+

"<<"([^>]|>[^>])*">>"   /* << ... >> — сильный форматтер удаляет */

"type"   { yylval->lex = lex_dup(yyscanner, yytext); return TYPE_KW; }
"fun"    { yylval->lex = lex_dup(yyscanner, yytext); return FUN_KW; }
"where"  { yylval->lex = lex_dup(yyscanner, yytext); return WHERE_KW; }
"wend"   { yylval->lex = lex_dup(yyscanner, yytext); return WEND_KW; }

"->"   { return ARROW; }
"|"    { return '|'; }
":"    { return COLON; }
"."    { return DOT; }
"("    { return '('; }
")"    { return ')'; }
"["    { return '['; }
"]"    { return ']'; }

[0-9]+ {
    yylval->lex = lex_dup(yyscanner, yytext);
    return INT_LIT;
}

[A-Z][A-Za-z0-9_]* {
    yylval->lex = lex_dup(yyscanner, yytext);
    return UIDENT;
}

[a-z][A-Za-z0-9_]* {
    yylval->lex = lex_dup(yyscanner, yytext);
    return LIDENT;
}

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
