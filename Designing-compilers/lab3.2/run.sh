#!/bin/bash

cd "$(dirname "$0")"

flex lexer.l
bison -d parser.y
gcc -w -I. -o formatter lex.yy.c parser.tab.c
rm -f lex.yy.c parser.tab.?
./formatter input.txt
