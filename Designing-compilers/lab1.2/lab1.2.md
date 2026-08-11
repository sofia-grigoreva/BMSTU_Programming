% Лабораторная работа № 1.2. «Лексический анализатор
  на основе регулярных выражений»
% 3 марта 2026 г.
% Софья Григорьева, ИУ9-61Б

# Цель работы
Целью данной работы является приобретение навыка 
разработки простейших лексических анализаторов, 
работающих на основе поиска в тексте по образцу, заданному регулярным выражением.

# Индивидуальный вариант
Числа: последовательности десятичных цифр, могут начинаться с нулём.  
Знаки операций: `+`, `-`, `*`, `/`, `(`, `)`.  
Комментарии начинаются на `(*`, заканчиваются на `*)`, не могут быть вложенными.  
Строки: ограничены фигурными скобками `{ … }`, 
escape-последовательности `#{`, `#}`, `##`, `#hh` означают соответственно `{`, `}`, `#` 
и символ с кодом `hh`, где `h` — шестнадцатеричное число, 
не могут пересекать границы строк текста.

## Лексический домен для защиты
Добавить рациональные дроби вида dddd/dddd

# Реализация

```javascript
class Lexer {

    constructor(text) {
        this.text = text;
        this.pos = 0;
        this.line = 1;
        this.column = 1;
        this.domains = [
            {name: 'NUMBER', reg : /^\d+/},
            {name: 'FLOAT', reg : /^\d+\/\d+/},
            {name: 'OPERATOR', reg : /^[+\-*/\(\)]/},  
            {name: 'COMMENT', reg : /^\(\*(?:(?!\(\*|\*\))[\s\S])*\*\)/},
            {name: 'STRING', reg: /^\{(?:\#\{|\#\}|\#\#|[^#{}\n]|\#[0-9a-fA-F]{2})*\}/},
        ] 
    }

    peekText() {
        return this.text.slice(this.pos);
    }

    skipWhitespace() {
        const match = this.peekText().match(/^[\s]+/);
        if (match) {
            this.clip(match[0]);
        }
    }

    clip (lexeme) {
        for (let s of lexeme) {
            if (s === '\n') {
                this.line++;
                this.column = 1;
            } else {
                this.column++;
            }
        }
        this.pos += lexeme.length;
    }

    nextToken = () => {

        this.skipWhitespace();

        if (this.pos >= this.text.length) {
            return null;
        }

        const startLine = this.line;
        const startColumn = this.column;
        const text = this.peekText();

        let bestMatch = null;
        let bestDomain = null;

        for (let domain of this.domains) {
            const match = text.match(domain.reg)
            if (match) {
                const lexeme = match[0];
                if (!bestMatch || lexeme.length > bestMatch.length) {
                    bestMatch = lexeme;
                    bestDomain = domain;
                }
            }
        }

        if (!bestMatch) {
            console.log(`syntax error (${startLine}, ${startColumn})`);
            this.clip(text[0]);
            return this.nextToken();
        }

        this.clip(bestMatch);

        return {
            type: bestDomain.name,
            line: startLine,
            column: startColumn,
            value: bestMatch,
        }
    }
}

const fs = require('fs');

const filename = process.argv[2];
const content = fs.readFileSync(filename, 'utf8');

const lexer = new Lexer(content);

let token;

while ((token = lexer.nextToken()) !== null) {
    console.log(`${token.type} (${token.line}, ${token.column}): ${token.value}`);
}
```

# Тестирование

Входные данные

```
222222 (*   njjn  
 *)
{aaa aa#{#}##3f}+/58
100/5
```

Вывод на `stdout` 

```
NUMBER (1, 1): 222222
COMMENT (1, 8): (*   njjn  
 *)
STRING (3, 1): {aaa aa#{#}##3f}
OPERATOR (3, 17): +
OPERATOR (3, 18): /
NUMBER (3, 19): 58
FLOAT (4, 1): 100/5
```

# Вывод
В лабораторной работе освоены принципы работы 
простейшего лексического анализатора на основе регулярных 
выражений: выделение лексем, поиск соответствий доменам, 
отслеживание координат, обработка пробелов, восстановление после ошибок.