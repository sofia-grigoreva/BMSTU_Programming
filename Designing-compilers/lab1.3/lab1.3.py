from enum import Enum
import unicodedata

class DomainTag(Enum):
    IDENT = "IDENT"
    NUMBER = "NUMBER"
    KEYWORD = "KEYWORD"
    END_OF_PROGRAM = "EOF"
    STRING = "STRING"

# Строки начинаются и заканчиваются на обратную кавычку, могут пересекать границы
# строк текста

class Position:
    def __init__(self, text):
        self.text = text
        self.line = 1
        self.pos = 1
        self.index = 0
    
    @property
    def cp(self):
        if self.index >= len(self.text):
            return None
        return self.text[self.index]
    
    def is_whitespace(self):
        return self.cp is not None and self.cp.isspace()
    
    def next(self):
        if self.index < len(self.text):
            if self.cp == "\n":
                self.line += 1
                self.pos = 1
            else:
                self.pos += 1
            self.index += 1
    
    def copy(self):
        p = Position(self.text)
        p.line = self.line
        p.pos = self.pos
        p.index = self.index
        return p
    
    def __str__(self):
        return f"({self.line}, {self.pos})"


class Fragment:
    def __init__(self, start, end):
        self.starting = start.copy()
        self.following = end.copy()
    
    def __str__(self):
        return f"{self.starting}-{self.following}"

class Token:
    def __init__(self, tag, start, end):
        self.tag = tag
        self.coords = Fragment(start, end)

class IdentToken(Token):
    def __init__(self, value, start, end):
        super().__init__(DomainTag.IDENT, start, end)
        self.value = value

class NumberToken(Token):
    def __init__(self, value, start, end):
        super().__init__(DomainTag.NUMBER, start, end)
        self.value = value

class KeywordToken(Token):
    def __init__(self, value, start, end):
        super().__init__(DomainTag.KEYWORD, start, end)
        self.value = value

class StringToken(Token):
    def __init__(self, value, start, end):
        super().__init__(DomainTag.STRING, start, end)
        self.value = value

class EOFToken(Token):
    def __init__(self, pos):
        super().__init__(DomainTag.END_OF_PROGRAM, pos, pos)

class Message:
    def __init__(self, is_error, text, coord):
        self.is_error = is_error
        self.text = text
        self.coord = coord

class NameDictionary:
    def __init__(self):
        self.name_to_code = {}
        self.names = []
    
    def add(self, name):
        if name in self.name_to_code:
            return self.name_to_code[name]
        code = len(self.names)
        self.names.append(name)
        self.name_to_code[name] = code
        return code
    
    def get(self, code):
        return self.names[code]

class Compiler:
    def __init__(self):
        self.messages = []
        self.names = NameDictionary()
    
    def add_error(self, pos, text):
        self.messages.append(Message(True, text, pos.copy()))
    
    def get_scanner(self, program):
        return Scanner(program, self)

class Scanner:
    KEYWORDS = {"qeq", "xx", "xxx"}
    
    def __init__(self, program, compiler):
        self.program = program
        self.compiler = compiler
        self.cur = Position(program)
    
    def skip_ws(self):
        while self.cur.cp and self.cur.is_whitespace():
            self.cur.next()
    
    def is_letter(self, ch):
        if ch is None:
            return False
        return unicodedata.category(ch)[0] == 'L'
    
    def is_hex_digit(self, ch):
        if ch is None:
            return False
        return ch.isdigit() or ch.upper() in 'ABCDEF'
    
    def next_token(self):
        while True:
            self.skip_ws()
            if self.cur.cp is None:
                return EOFToken(self.cur)
            
            start = self.cur.copy()
            ch = self.cur.cp
            
            if self.is_letter(ch):
                text = ""
                
                while self.cur.cp and (self.is_letter(self.cur.cp) or self.cur.cp.isdigit()):
                    text += self.cur.cp
                    self.cur.next()
                
                if text and self.is_letter(text[-1]):
                    if text in self.KEYWORDS:
                        return KeywordToken(text, start, self.cur)
                    else:
                        code = self.compiler.names.add(text)
                        return IdentToken(code, start, self.cur)
                else:
                    self.compiler.add_error(start, f"Identifier must end with a letter: {text}")
                    continue

            elif ch == '`':
                self.cur.next()
                text = ""
                
                while self.cur.cp is not None and self.cur.cp != '`':
                    text += self.cur.cp
                    self.cur.next()

                if self.cur.cp == '`':
                    self.cur.next()
                    return StringToken(text, start, self.cur)
                else:
                    self.compiler.add_error(start, f"String must end with `")
                    return StringToken(text, start, self.cur)

            elif self.is_hex_digit(ch):
                text = ""
                while self.cur.cp and self.is_hex_digit(self.cur.cp):
                    text += self.cur.cp
                    self.cur.next()
                
                if self.cur.cp is not None and self.is_letter(self.cur.cp):
                    self.cur = start
                    self.cur.next()
                    self.compiler.add_error(start, f"Number cannot be followed directly by a letter")
                    continue
                
                value = int(text, 16)
                return NumberToken(value, start, self.cur)

            else:
                bad = ""
                while self.cur.cp and not self.cur.is_whitespace() and not self.is_letter(self.cur.cp) and not self.is_hex_digit(self.cur.cp):
                    bad += self.cur.cp
                    self.cur.next()
                
                if bad:
                    self.compiler.add_error(start, f"Unexpected character(s): {bad}")
                else:
                    self.cur.next()
                    self.compiler.add_error(start, f"Unexpected character: {ch}")
        
        return EOFToken(self.cur)

def print_token(token, compiler):
    if token.tag == DomainTag.IDENT:
        name = compiler.names.get(token.value) if hasattr(token, 'value') else str(token.value)
        print(f"{token.tag.name} {token.coords}: {name}")
    elif token.tag == DomainTag.NUMBER:
        print(f"{token.tag.name} {token.coords}: {hex(token.value)}")
    elif token.tag == DomainTag.KEYWORD:
        print(f"{token.tag.name} {token.coords}: {token.value}")
    elif token.tag == DomainTag.END_OF_PROGRAM:
        print(f"{token.tag.name} {token.coords}")
    elif token.tag == DomainTag.STRING:
        print(f"{token.tag.name} {token.coords}: {token.value}")

if __name__ == "__main__":
    import sys
    
    if len(sys.argv) > 1:
        filename = sys.argv[1]
    else:
        filename = "input.txt"

    with open(filename, encoding="utf-8") as f:
        program = f.read()
    
    compiler = Compiler()
    scanner = compiler.get_scanner(program)
    
    while True:
        token = scanner.next_token()
        print_token(token, compiler)
        if token.tag == DomainTag.END_OF_PROGRAM:
            break
    
    for m in compiler.messages:
        print(f"Error {m.coord}: {m.text}")
            