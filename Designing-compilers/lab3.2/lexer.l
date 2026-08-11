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
