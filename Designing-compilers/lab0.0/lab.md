% Лабораторная работа № 0.0. Знакомство с компиляцией программ
% 10 февраля 2026 г.
% Софья Григорьева, ИУ9-61Б

# Цель работы

Заполнить первую лабораторную, которая проводится до лекции😉.

# Индивидуальный вариант

```
<Program> ::= <Articles> <Body> .
<Articles> ::= <Article> <Articles> | .
<Article>  ::= define word <Body> end .
<Body>     ::= if <Body> <ElsePart> endif <Body> | integer <Body> | word <Body> | .
<ElsePart> ::= else <Body> | .
```

# Реализация

```python
def parse(program):
    tokens = program.split()
    pos = 0


    def lookahead():
        return tokens[pos] if pos < len(tokens) else None


    def getNext():
        nonlocal pos
        if pos < len(tokens):
            token = tokens[pos]
            pos += 1
            return token
        return None


    def parseArticles():
        articles = {}
        while lookahead() == 'define':
            article = parseArticle()
            if article is None:
                return None
            name, body = article
            articles[name] = body
        return articles


    def parseArticle():
        getNext()
        word = getNext()

        if word is None or word in ['define', 'end', 'if', 'endif', 'else']:
            return None

        body = parseBody()
        if body is None:
            return None

        if lookahead() != 'end':
            return None
        getNext()

        return (word, body)


    def parseBody():
        elements = []
        while True:
            token = lookahead()

            if token == 'define':
                return None

            if token is None or token in ['end', 'else', 'endif']:
                break

            if token == 'if':
                ifPart = parseIf()
                if ifPart is None:
                    return None
                elements.append(ifPart)
            else:
                token = getNext()
                try:
                    if token.lstrip('-').isdigit() and (token[0] != '-' or len(token) > 1):
                        elements.append(int(token))
                    else:
                        elements.append(token)
                except (ValueError, IndexError):
                    elements.append(token)

        return elements


    def parseIf():

        getNext()

        ifBody = parseBody()
        if ifBody is None:
            return None

        elsePart = parseElsePart()

        if lookahead() != 'endif':
            return None
        getNext()

        if elsePart is None:
            return ['if', ifBody]
        else:
            return ['if', ifBody, elsePart]


    def parseElsePart():
        if lookahead() != 'else':
            return None
        getNext()

        elseBody = parseBody()
        if elseBody is None:
            return None

        return elseBody


    articles = parseArticles()
    if articles is None:
        return None

    mainBody = parseBody()
    if mainBody is None:
        return None

    if lookahead() is not None:
        return None

    return [articles, mainBody]
```

# Тестирование

```python
>>> parse("1 2 +")
[{}, [1, 2, '+']]

>>> parse("x dup 0 swap if drop -1 endif")
[{}, ['x', 'dup', 0, 'swap', ['if', ['drop', -1]]]]

>>> parse("x dup 0 swap if drop -1 else swap 1 + endif")
[{}, ['x', 'dup', 0, 'swap', ['if', ['drop', -1], ['swap', 1, '+']]]]

>>> parse(""" define -- 1 - end
        define =0? dup 0 = end
        define =1? dup 1 = end
        define factorial
            =0? if drop 1 exit endif
            =1? if drop 1 exit endif
            dup --
            factorial
            *
        end
        0 factorial
        1 factorial
        2 factorial
        3 factorial
        4 factorial""")
[{'--': [1, '-'], '=0?': ['dup', 0, '='], '=1?': ['dup', 1, '='], 'factorial': ['=0?', ['if', ['drop', 1, 'exit']], '=1?', ['if', ['drop', 1, 'exit']], 'dup', '--', 'factorial', '*']}, [0, 'factorial', 1, 'factorial', 2, 'factorial', 3, 'factorial', 4, 'factorial']]

>>> parse(""" define -- 1 - end
        define =0? dup 0 = end
        define =1? dup 1 = end
        define factorial
            =0? if
                drop 1
            else =1? if
                drop 1
            else
                dup --
                factorial
                *
            endif
            endif
        end
        0 factorial
        1 factorial
        2 factorial
        3 factorial
        4 factorial """)
[{'--': [1, '-'], '=0?': ['dup', 0, '='], '=1?': ['dup', 1, '='], 'factorial': ['=0?', ['if', ['drop', 1], ['=1?', ['if', ['drop', 1], ['dup', '--', 'factorial', '*']]]]]}, [0, 'factorial', 1, 'factorial', 2, 'factorial', 3, 'factorial', 4, 'factorial']]

>>> parse("define word w1 w2 w3")
None

>>> parse("if 1")
None

>>> parse("endif")
None

>>> parse("else")
None
```

# Вывод

Освежили знания с первого курса
