from enum import Enum
from typing import List, Optional, Dict, Tuple
import sys

class DomainTag(Enum):
    TERMS_KW = "TERMS_KW"
    AXIOM_KW = "AXIOM_KW"

    LPAREN = "LPAREN"          # (
    RPAREN = "RPAREN"          # )
    EQUAL = "EQUAL"            # =
    BAR = "BAR"                # |
    DOT = "DOT"                # .

    ESC_LPAREN = "ESC_LPAREN"  # \(
    ESC_RPAREN = "ESC_RPAREN"  # \)

    PLUS = "PLUS"              # +
    STAR = "STAR"              # *
    N = "N"                    # n

    NONTERM = "NONTERM"        # E, E1, T, T1, F
    END_OF_PROGRAM = "EOF"


class Position:
    def __init__(self, text: str):
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
    def __init__(self, start: Position, end: Position):
        self.starting = start.copy()
        self.following = end.copy()

    def __str__(self):
        return f"{self.starting}-{self.following}"


class Token:
    def __init__(self, tag: DomainTag, start: Position, end: Position):
        self.tag = tag
        self.coords = Fragment(start, end)


class TermsKwToken(Token):
    def __init__(self, start: Position, end: Position):
        super().__init__(DomainTag.TERMS_KW, start, end)


class AxiomKwToken(Token):
    def __init__(self, start: Position, end: Position):
        super().__init__(DomainTag.AXIOM_KW, start, end)


class LParenToken(Token):
    def __init__(self, start: Position, end: Position):
        super().__init__(DomainTag.LPAREN, start, end)


class RParenToken(Token):
    def __init__(self, start: Position, end: Position):
        super().__init__(DomainTag.RPAREN, start, end)


class EqualToken(Token):
    def __init__(self, start: Position, end: Position):
        super().__init__(DomainTag.EQUAL, start, end)


class BarToken(Token):
    def __init__(self, start: Position, end: Position):
        super().__init__(DomainTag.BAR, start, end)


class DotToken(Token):
    def __init__(self, start: Position, end: Position):
        super().__init__(DomainTag.DOT, start, end)


class EscLParenToken(Token):
    def __init__(self, start: Position, end: Position):
        super().__init__(DomainTag.ESC_LPAREN, start, end)


class EscRParenToken(Token):
    def __init__(self, start: Position, end: Position):
        super().__init__(DomainTag.ESC_RPAREN, start, end)


class PlusToken(Token):
    def __init__(self, start: Position, end: Position):
        super().__init__(DomainTag.PLUS, start, end)


class StarToken(Token):
    def __init__(self, start: Position, end: Position):
        super().__init__(DomainTag.STAR, start, end)


class NToken(Token):
    def __init__(self, start: Position, end: Position):
        super().__init__(DomainTag.N, start, end)


class NonTermToken(Token):
    def __init__(self, value: str, start: Position, end: Position):
        super().__init__(DomainTag.NONTERM, start, end)
        self.value = value


class EOFToken(Token):
    def __init__(self, pos: Position):
        super().__init__(DomainTag.END_OF_PROGRAM, pos, pos)


class Message:
    def __init__(self, is_error: bool, text: str, coord: Position):
        self.is_error = is_error
        self.text = text
        self.coord = coord.copy()


class Compiler:
    def __init__(self):
        self.messages: List[Message] = []
        self.comments: List[Tuple[str, Position, Position]] = []

    def add_error(self, pos: Position, text: str):
        self.messages.append(Message(True, text, pos.copy()))

    def add_comment(self, text: str, start: Position, end: Position):
        self.comments.append((text, start.copy(), end.copy()))

    def get_scanner(self, program: str):
        return Scanner(program, self)

class Scanner:
    ALLOWED_NONTERMS = {"E", "E1", "T", "T1", "F"}

    def __init__(self, program: str, compiler: Compiler):
        self.program = program
        self.compiler = compiler
        self.cur = Position(program)

    def skip_ws(self):
        while self.cur.cp is not None and self.cur.is_whitespace():
            self.cur.next()

    def read_comment(self, start: Position) -> str:
        self.cur.next()
        text = ""
        while self.cur.cp is not None and self.cur.cp != "\n":
            text += self.cur.cp
            self.cur.next()
        return text

    def read_word(self, start: Position) -> Optional[Token]:
        value = ""
        while self.cur.cp is not None and self.cur.cp.isalpha():
            value += self.cur.cp
            self.cur.next()

        if value == "terms":
            return TermsKwToken(start, self.cur)
        if value == "axiom":
            return AxiomKwToken(start, self.cur)
        if value == "n":
            return NToken(start, self.cur)

        self.compiler.add_error(start, f"unknown word '{value}'")
        return None

    def read_nonterm(self, start: Position) -> Optional[NonTermToken]:
        value = ""

        if self.cur.cp is None or not self.cur.cp.isalpha():
            self.compiler.add_error(start, "nonterminal must start with a letter")
            return None

        value += self.cur.cp
        self.cur.next()

        if self.cur.cp is not None and self.cur.cp.isdigit():
            value += self.cur.cp
            self.cur.next()

        if value not in self.ALLOWED_NONTERMS:
            self.compiler.add_error(start, f"unknown nonterminal '{value}'")
            return None

        return NonTermToken(value, start, self.cur)

    def next_token(self) -> Token:
        while True:
            self.skip_ws()

            if self.cur.cp is None:
                return EOFToken(self.cur)

            start = self.cur.copy()
            ch = self.cur.cp

            if ch == ";":
                text = self.read_comment(start)
                self.compiler.add_comment(text, start, self.cur)
                continue

            if ch == "(":
                self.cur.next()
                return LParenToken(start, self.cur)

            if ch == ")":
                self.cur.next()
                return RParenToken(start, self.cur)

            if ch == "=":
                self.cur.next()
                return EqualToken(start, self.cur)

            if ch == "|":
                self.cur.next()
                return BarToken(start, self.cur)

            if ch == ".":
                self.cur.next()
                return DotToken(start, self.cur)

            if ch == "+":
                self.cur.next()
                return PlusToken(start, self.cur)

            if ch == "*":
                self.cur.next()
                return StarToken(start, self.cur)

            if ch == "\\":
                self.cur.next()
                if self.cur.cp == "(":
                    self.cur.next()
                    return EscLParenToken(start, self.cur)
                if self.cur.cp == ")":
                    self.cur.next()
                    return EscRParenToken(start, self.cur)

                self.compiler.add_error(start, "expected '(' or ')' after '\\'")
                continue

            if ch.isalpha():
                look = self.cur.copy()
                temp = ""
                while look.cp is not None and look.cp.isalpha():
                    temp += look.cp
                    look.next()

                if temp in {"terms", "axiom", "n"}:
                    token = self.read_word(start)
                    if token is not None:
                        return token
                    continue

                token = self.read_nonterm(start)
                if token is not None:
                    return token
                continue

            self.compiler.add_error(start, f"unexpected character '{ch}'")
            self.cur.next()

class Node:
    def __init__(self, name: str):
        self.name = name
        self.children: List["Node"] = []

    def add_child(self, child: "Node"):
        self.children.append(child)

    def print_tree(self, indent: str = ""):
        print(f"{indent}{self.name}")
        for child in self.children:
            child.print_tree(indent + "  ")

    def to_dot(self, node_id: int = 0, parent_id: Optional[int] = None) -> Tuple[str, int]:
        dot = ""
        current_id = node_id

        if parent_id is not None:
            dot += f"  n{parent_id} -> n{current_id};\n"

        label = self.name.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n")
        dot += f'  n{current_id} [label="{label}"];\n'

        next_id = current_id + 1
        child_ids = []

        for child in self.children:
            child_root_id = next_id
            child_ids.append(child_root_id)
            child_dot, next_id = child.to_dot(next_id, current_id)
            dot += child_dot

        if len(child_ids) > 1:
            chain = " -> ".join(f"n{i}" for i in child_ids)
            dot += f"  {{ rank=same; {chain} [style=invis]; }}\n"

        return dot, next_id


class Leaf(Node):
    def __init__(self, token: Token):
        if token.tag == DomainTag.NONTERM:
            label = getattr(token, "value")
        elif token.tag == DomainTag.TERMS_KW:
            label = "terms"
        elif token.tag == DomainTag.AXIOM_KW:
            label = "axiom"
        elif token.tag == DomainTag.LPAREN:
            label = "("
        elif token.tag == DomainTag.RPAREN:
            label = ")"
        elif token.tag == DomainTag.EQUAL:
            label = "="
        elif token.tag == DomainTag.BAR:
            label = "|"
        elif token.tag == DomainTag.DOT:
            label = "."
        elif token.tag == DomainTag.ESC_LPAREN:
            label = "\\("
        elif token.tag == DomainTag.ESC_RPAREN:
            label = "\\)"
        elif token.tag == DomainTag.PLUS:
            label = "+"
        elif token.tag == DomainTag.STAR:
            label = "*"
        elif token.tag == DomainTag.N:
            label = "n"
        else:
            label = token.tag.value

        super().__init__(label)
        self.token = token


class Inner(Node):
    def __init__(self, nterm: str):
        super().__init__(nterm)
        self.nterm = nterm


class Parser:
    def __init__(self):
        self.table: Dict[str, Dict[str, List[str]]] = {}
        self.errors: List[str] = []
        self.init_table()

    def init_table(self):
        self.table["Spec"] = {
            "LPAREN": ["Terms", "Rules"]
        }

        self.table["Terms"] = {
            "LPAREN": ["LPAREN", "TERMS_KW", "TermList", "RPAREN"]
        }

        self.table["TermList"] = {
            "N": ["Term", "TermList"],
            "ESC_LPAREN": ["Term", "TermList"],
            "ESC_RPAREN": ["Term", "TermList"],
            "PLUS": ["Term", "TermList"],
            "STAR": ["Term", "TermList"],
            "RPAREN": []
        }

        self.table["Term"] = {
            "N": ["N"],
            "ESC_LPAREN": ["ESC_LPAREN"],
            "ESC_RPAREN": ["ESC_RPAREN"],
            "PLUS": ["PLUS"],
            "STAR": ["STAR"]
        }

        self.table["Rules"] = {
            "LPAREN": ["Rule", "Rules"],
            "EOF": []
        }

        self.table["Rule"] = {
            "LPAREN": ["LPAREN", "RuleHead"]
        }

        self.table["RuleHead"] = {
            "NONTERM": ["NONTERM", "RPAREN", "EQUAL", "Expr", "DOT"],
            "AXIOM_KW": ["AXIOM_KW", "NONTERM", "RPAREN", "EQUAL", "Expr", "DOT"]
        }

        self.table["Expr"] = {
            "N": ["Alt", "ExprTail"],
            "ESC_LPAREN": ["Alt", "ExprTail"],
            "ESC_RPAREN": ["Alt", "ExprTail"],
            "PLUS": ["Alt", "ExprTail"],
            "STAR": ["Alt", "ExprTail"],
            "LPAREN": ["Alt", "ExprTail"],
            "BAR": ["Alt", "ExprTail"],
            "DOT": ["Alt", "ExprTail"]
        }

        self.table["ExprTail"] = {
            "BAR": ["BAR", "Alt", "ExprTail"],
            "DOT": []
        }

        self.table["Alt"] = {
            "N": ["SymbolList"],
            "ESC_LPAREN": ["SymbolList"],
            "ESC_RPAREN": ["SymbolList"],
            "PLUS": ["SymbolList"],
            "STAR": ["SymbolList"],
            "LPAREN": ["SymbolList"],
            "BAR": [],
            "DOT": []
        }

        self.table["SymbolList"] = {
            "N": ["Symbol", "SymbolList"],
            "ESC_LPAREN": ["Symbol", "SymbolList"],
            "ESC_RPAREN": ["Symbol", "SymbolList"],
            "PLUS": ["Symbol", "SymbolList"],
            "STAR": ["Symbol", "SymbolList"],
            "LPAREN": ["Symbol", "SymbolList"],
            "BAR": [],
            "DOT": []
        }

        self.table["Symbol"] = {
            "N": ["N"],
            "ESC_LPAREN": ["ESC_LPAREN"],
            "ESC_RPAREN": ["ESC_RPAREN"],
            "PLUS": ["PLUS"],
            "STAR": ["STAR"],
            "LPAREN": ["LPAREN", "NONTERM", "RPAREN"]
        }

    def is_terminal(self, sym: str) -> bool:
        return sym in {
            "TERMS_KW", "AXIOM_KW",
            "LPAREN", "RPAREN", "EQUAL", "BAR", "DOT",
            "ESC_LPAREN", "ESC_RPAREN", "PLUS", "STAR", "N",
            "NONTERM", "EOF"
        }

    def error(self, msg: str, token: Token):
        row = token.coords.starting.line
        col = token.coords.starting.pos
        self.errors.append(f"({row}, {col}) {msg}")

    def parse(self, tokens: List[Token]) -> Optional[Node]:
        if not tokens or tokens[-1].tag != DomainTag.END_OF_PROGRAM:
            eof_pos = tokens[-1].coords.following if tokens else Position("")
            tokens.append(EOFToken(eof_pos))

        stack: List[Tuple[str, Optional[Node]]] = [("EOF", None), ("Spec", None)]
        token_idx = 0
        current_token = tokens[token_idx]

        root = Inner("Spec")

        while stack:
            top, parent = stack.pop()

            if self.is_terminal(top):
                if top == current_token.tag.value:
                    leaf = Leaf(current_token)
                    if parent is not None:
                        parent.add_child(leaf)

                    token_idx += 1
                    if token_idx < len(tokens):
                        current_token = tokens[token_idx]
                else:
                    self.error(f"expected {top}, got {current_token.tag.value}", current_token)
                    return None
            else:
                rule = self.table.get(top, {}).get(current_token.tag.value)

                if rule is None:
                    self.error(f"no rule for {top} with lookahead {current_token.tag.value}", current_token)
                    return None

                if top == "Spec" and parent is None:
                    current_node = root
                else:
                    current_node = Inner(top)
                    if parent is not None:
                        parent.add_child(current_node)

                for sym in reversed(rule):
                    stack.append((sym, current_node))

        if current_token.tag != DomainTag.END_OF_PROGRAM:
            self.error("extra input after end of parse", current_token)
            return None

        return root


def print_token(token: Token):
    if token.tag == DomainTag.NONTERM:
        print(f"NONTERM {token.coords}: {token.value}")
    else:
        print(f"{token.tag.value} {token.coords}")


def main():
    if len(sys.argv) < 2:
        print("Usage: python main.py <input-file>")
        return

    with open(sys.argv[1], "r", encoding="utf-8") as f:
        program = f.read()

    compiler = Compiler()
    scanner = compiler.get_scanner(program)

    tokens: List[Token] = []
    while True:
        token = scanner.next_token()
        tokens.append(token)
        if token.tag == DomainTag.END_OF_PROGRAM:
            break

    for tok in tokens:
        print_token(tok)

    if compiler.comments:
        for text, start, end in compiler.comments:
            print(f"COMMENT {start}-{end}: {text}")

    if compiler.messages:
        for msg in compiler.messages:
            print(f"Error {msg.coord}: {msg.text}")
        return

    parser = Parser()
    tree = parser.parse(tokens)

    if parser.errors:
        for err in parser.errors:
            print(err)
        return
    
    tree.print_tree()

    dot, _ = tree.to_dot(0)
    with open("parse_tree.dot", "w", encoding="utf-8") as f:
        f.write("digraph {\n")
        f.write("  rankdir=TB;\n")
        f.write("  node [shape=box];\n")
        f.write(dot)
        f.write("}\n")


if __name__ == "__main__":
    main()