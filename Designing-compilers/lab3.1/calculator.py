from __future__ import annotations

from typing import List, Optional
import sys

from generator import EOF_TAG, Node, TableParser, Token
from calculator_table import TERMINALS, START, SYMBOL_NAMES, PARSE_TABLE


class Position:
    def __init__(self, line: int, pos: int):
        self.line = line
        self.pos = pos

    def copy(self) -> "Position":
        return Position(self.line, self.pos)

    def __str__(self) -> str:
        return f"({self.line}, {self.pos})"


class Token(Token):
    def __init__(self, tag: int, line: int, col: int):
        pos = Position(line, col)
        super().__init__(tag, pos, pos)


class NumberToken(Token):
    def __init__(self, tag: int, value: int, line: int, col: int):
        super().__init__(tag, line, col)
        self.value = value


class Scanner:
    def __init__(self, text: str):
        self.text = text
        self.index = 0
        self.line = 1
        self.col = 1
        self.errors: List[str] = []

    @property
    def cp(self) -> Optional[str]:
        if self.index >= len(self.text):
            return None
        return self.text[self.index]

    def advance(self) -> None:
        if self.cp == "\n":
            self.line += 1
            self.col = 1
        else:
            self.col += 1
        self.index += 1

    def scan(self) -> List[Token]:
        tokens: List[Token] = []
        terminals = TERMINALS

        while self.cp is not None:
            if self.cp.isspace():
                self.advance()
                continue

            line, col = self.line, self.col
            ch = self.cp

            if ch.isdigit():
                lexeme = ""
                while self.cp is not None and self.cp.isdigit():
                    lexeme += self.cp
                    self.advance()

                if "n" not in terminals:
                    self.errors.append("internal error: terminal 'n' is absent in calculator_table.py")
                    continue

                tokens.append(NumberToken(terminals["n"], int(lexeme), line, col))
                continue

            if ch in "+*()":
                if ch not in terminals:
                    self.errors.append(f"({line}, {col}): terminal {ch!r} is absent in calculator_table.py")
                    self.advance()
                    continue

                self.advance()
                tokens.append(Token(terminals[ch], line, col))
                continue

            self.errors.append(f"({line}, {col}): unexpected character {ch!r}")
            self.advance()

        tokens.append(Token(EOF_TAG, self.line, self.col))
        return tokens


class Evaluator:

    def eval(self, root: Node) -> int:
        if root.name != "E":
            raise RuntimeError(f"internal error: expected root E, got {root.name}")
        return self.eval_E(root)

    def eval_E(self, node: Node) -> int:
        # E -> T E1
        t_value = self.eval_T(node.children[0])
        return self.eval_E1(node.children[1], t_value)

    def eval_E1(self, node: Node, acc: int) -> int:
        # E1 -> eps
        if not node.children:
            return acc

        # E1 -> + T E1
        t_value = self.eval_T(node.children[1])
        return self.eval_E1(node.children[2], acc + t_value)

    def eval_T(self, node: Node) -> int:
        # T -> F T1
        f_value = self.eval_F(node.children[0])
        return self.eval_T1(node.children[1], f_value)

    def eval_T1(self, node: Node, acc: int) -> int:
        # T1 -> eps
        if not node.children:
            return acc

        # T1 -> * F T1
        f_value = self.eval_F(node.children[1])
        return self.eval_T1(node.children[2], acc * f_value)

    def eval_F(self, node: Node) -> int:
        # F -> n
        if len(node.children) == 1:
            token = node.children[0].token
            if token is None or not hasattr(token, "value"):
                raise RuntimeError("internal error: number token has no value")
            return int(token.value)

        # F -> ( E )
        return self.eval_E(node.children[1])


def parse_expression(text: str) -> Node:
    scanner = Scanner(text)
    tokens = scanner.scan()

    if scanner.errors:
        raise ValueError("\n".join(scanner.errors))

    parser = TableParser(PARSE_TABLE, START, SYMBOL_NAMES)
    tree = parser.parse(tokens)

    if tree is None:
        raise ValueError("\n".join(parser.errors))

    return tree


def calculate(text: str) -> int:
    tree = parse_expression(text)
    return Evaluator().eval(tree)


def main() -> int:
    filename = "input.txt"

    try:
        with open(filename, "r", encoding="utf-8") as f:
            text = f.read().strip()
    except FileNotFoundError:
        print(f"Error: file {filename!r} not found", file=sys.stderr)
        return 1
    except OSError as exc:
        print(f"Error reading file: {exc}", file=sys.stderr)
        return 1

    try:
        print(calculate(text))
        return 0
    except ValueError as exc:
        print(exc, file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())