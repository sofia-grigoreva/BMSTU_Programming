% Лабораторная работа № 3.1 «Самоприменимый генератор компиляторов
  на основе предсказывающего анализа»
% 26 мая 2026 г.
% Софья Григорьева, ИУ9-61Б

# Цель работы
Целью данной работы является изучение алгоритма построения таблиц предсказывающего анализатора.

# Индивидуальный вариант
```
(terms n \( \) * +)

; правила грамматики

(F)  = n | \( (E) \).
(T)  = (F) (T1).
(T1) = * (F) (T1) | .
(axiom E) = (T) (E1).
(E1) = + (T) (E1) | .
```

# Грамматика на входном языке

```
; Аксиома заключена в фигурные скобки.
{ S }, D, L, I, R, P, A, B, C, M, N, Y
< S : D R >
< D : I L >
< I : "NONTERM" : "LBRACE" "NONTERM" "RBRACE" >
< L : "COMMA" I L : @ >
< R : P R : @ >
< P : "LANGLE" "NONTERM" "COLON" A "RANGLE" >
< A : C B >
< B : "COLON" C B : @ >
< C : "EPS" : M >
< M : Y N >
< N : Y N : @ >
< Y : "NONTERM" : "TERM" >
```

# Реализация
## Генератор компиляторов

```python
from __future__ import annotations

from dataclasses import dataclass, field
from pprint import pformat
from typing import Dict, List, Optional, Sequence, Set, Tuple
import sys
import gen_table

EOF_TAG = 0
EPSILON_NAME = "@"
EPS = "<EPS>"
EOF_NAME = "EOF"


class DomainTag:
    END_OF_PROGRAM = EOF_TAG
    NONTERM = 1
    LBRACE = 2
    RBRACE = 3
    COMMA = 4
    LANGLE = 5
    COLON = 6
    RANGLE = 7
    EPS = 8
    TERM = 9


class Position:
    def __init__(self, text: str):
        self.text = text
        self.line = 1
        self.pos = 1
        self.index = 0

    @property
    def cp(self) -> Optional[str]:
        if self.index >= len(self.text):
            return None
        return self.text[self.index]

    def is_whitespace(self) -> bool:
        return self.cp is not None and self.cp.isspace()

    def next(self) -> None:
        if self.index < len(self.text):
            if self.cp == "\n":
                self.line += 1
                self.pos = 1
            else:
                self.pos += 1
            self.index += 1

    def copy(self) -> "Position":
        p = Position(self.text)
        p.line = self.line
        p.pos = self.pos
        p.index = self.index
        return p

    def __str__(self) -> str:
        return f"({self.line}, {self.pos})"


class Fragment:
    def __init__(self, start: Position, end: Position):
        self.starting = start.copy()
        self.following = end.copy()

    def __str__(self) -> str:
        return f"{self.starting}-{self.following}"


class Token:
    def __init__(self, tag: int, start: Position, end: Position):
        self.tag = tag
        self.coords = Fragment(start, end)

    @property
    def coord(self) -> str:
        return str(self.coords.starting)


class NonTermToken(Token):
    def __init__(self, value: str, start: Position, end: Position):
        super().__init__(DomainTag.NONTERM, start, end)
        self.value = value


class TermToken(Token):
    def __init__(self, value: str, start: Position, end: Position):
        super().__init__(DomainTag.TERM, start, end)
        self.value = value


class SimpleToken(Token):
    def __init__(self, tag: int, start: Position, end: Position):
        super().__init__(tag, start, end)


class EOFToken(Token):
    def __init__(self, pos: Position):
        super().__init__(DomainTag.END_OF_PROGRAM, pos, pos)


@dataclass
class Message:
    coord: str
    text: str


class GenerationError(Exception):
    pass


class Compiler:
    def __init__(self):
        self.messages: List[Message] = []
        self.comments: List[Tuple[str, str, str]] = []

    def add_error(self, pos: Position, text: str) -> None:
        self.messages.append(Message(str(pos), text))

    def add_comment(self, text: str, start: Position, end: Position) -> None:
        self.comments.append((text, str(start), str(end)))


@dataclass
class Node:
    symbol: int
    name: str
    token: Optional[Token] = None
    children: List["Node"] = field(default_factory=list)

    def add_child(self, child: "Node") -> None:
        self.children.append(child)

    def print_tree(self, indent: str = "") -> None:
        if self.token is None:
            print(f"{indent}{self.name}")
        elif hasattr(self.token, "value"):
            print(f"{indent}{self.name}: {self.token.value}")
        else:
            print(f"{indent}{self.name}")
        for child in self.children:
            child.print_tree(indent + "  ")


class TableParser:
    def __init__(
        self,
        parse_table: Dict[int, Dict[int, List[int]]],
        start_symbol: int,
        symbol_names: Dict[int, str],
    ):
        self.parse_table = parse_table
        self.start_symbol = start_symbol
        self.symbol_names = symbol_names
        self.errors: List[str] = []

    @staticmethod
    def is_terminal(symbol: int) -> bool:
        return symbol >= 0

    def symbol_name(self, symbol: int) -> str:
        return self.symbol_names.get(symbol, str(symbol))

    def parse(self, tokens: Sequence[Token]) -> Optional[Node]:
        self.errors.clear()
        if not tokens:
            self.errors.append("internal error: empty token stream")
            return None
        if tokens[-1].tag != EOF_TAG:
            self.errors.append("internal error: token stream must end with EOF")
            return None

        root = Node(self.start_symbol, self.symbol_name(self.start_symbol))
        stack: List[Tuple[int, Optional[Node]]] = [(EOF_TAG, None), (self.start_symbol, root)]
        index = 0
        current = tokens[index]

        while stack:
            top, node = stack.pop()

            if self.is_terminal(top):
                if top == current.tag:
                    if node is not None:
                        node.token = current
                    index += 1
                    if index < len(tokens):
                        current = tokens[index]
                    continue
                self.errors.append(
                    f"{current.coord}: expected {self.symbol_name(top)}, "
                    f"got {self.symbol_name(current.tag)}"
                )
                return None

            row = self.parse_table.get(top)
            if row is None:
                self.errors.append(f"{current.coord}: no table row for {self.symbol_name(top)}")
                return None

            production = row.get(current.tag)
            if production is None:
                expected = ", ".join(self.symbol_name(t) for t in sorted(row))
                self.errors.append(
                    f"{current.coord}: no rule for {self.symbol_name(top)} "
                    f"with lookahead {self.symbol_name(current.tag)}; expected one of: {expected}"
                )
                return None

            if not production:
                continue

            children: List[Node] = []
            for symbol in production:
                child = Node(symbol, self.symbol_name(symbol))
                if node is not None:
                    node.add_child(child)
                children.append(child)

            for symbol, child in reversed(list(zip(production, children))):
                stack.append((symbol, child))

        if current.tag != EOF_TAG:
            self.errors.append(f"{current.coord}: extra input after parse")
            return None
        return root


class BuiltinInputLanguageTable:
    EOF = 0
    TERMINALS = {
        "NONTERM": 1,
        "LBRACE": 2,
        "RBRACE": 3,
        "COMMA": 4,
        "LANGLE": 5,
        "COLON": 6,
        "RANGLE": 7,
        "EPS": 8,
        "TERM": 9,
    }
    NONTERMINALS = {
        "S": -1,
        "D": -2,
        "L": -3,
        "I": -4,
        "R": -5,
        "P": -6,
        "A": -7,
        "B": -8,
        "C": -9,
        "M": -10,
        "N": -11,
        "Y": -12,
    }
    START = -1
    SYMBOL_NAMES = {
        -12: "Y",
        -11: "N",
        -10: "M",
        -9: "C",
        -8: "B",
        -7: "A",
        -6: "P",
        -5: "R",
        -4: "I",
        -3: "L",
        -2: "D",
        -1: "S",
        0: "EOF",
        1: "NONTERM",
        2: "LBRACE",
        3: "RBRACE",
        4: "COMMA",
        5: "LANGLE",
        6: "COLON",
        7: "RANGLE",
        8: "EPS",
        9: "TERM",
    }
    PARSE_TABLE = {
        -1: {1: [-2, -5], 2: [-2, -5]},
        -2: {1: [-4, -3], 2: [-4, -3]},
        -3: {0: [], 4: [4, -4, -3], 5: []},
        -4: {1: [1], 2: [2, 1, 3]},
        -5: {0: [], 5: [-6, -5]},
        -6: {5: [5, 1, 6, -7, 7]},
        -7: {1: [-9, -8], 8: [-9, -8], 9: [-9, -8]},
        -8: {6: [6, -9, -8], 7: []},
        -9: {1: [-10], 8: [8], 9: [-10]},
        -10: {1: [-12, -11], 9: [-12, -11]},
        -11: {1: [-12, -11], 6: [], 7: [], 9: [-12, -11]},
        -12: {1: [1], 9: [9]},
    }

class GrammarScanner:
    def __init__(self, program: str, compiler: Optional[Compiler] = None):
        self.program = program
        self.compiler = compiler if compiler is not None else Compiler()
        self.cur = Position(program)

    @property
    def errors(self) -> List[Message]:
        return self.compiler.messages

    @property
    def comments(self) -> List[Tuple[str, str, str]]:
        return self.compiler.comments

    def skip_ws(self) -> None:
        while self.cur.cp is not None and self.cur.is_whitespace():
            self.cur.next()

    def read_comment(self, start: Position) -> str:
        self.cur.next()
        comment_text = ""
        while self.cur.cp is not None and self.cur.cp != "\n":
            comment_text += self.cur.cp
            self.cur.next()
        return comment_text

    def read_quoted_term(self, start: Position) -> Optional[TermToken]:
        self.cur.next()
        value = ""
        while self.cur.cp is not None and self.cur.cp != '"':
            if self.cur.cp == "\\":
                self.cur.next()
                if self.cur.cp is None:
                    self.compiler.add_error(start, "unterminated quoted string")
                    return None
                escapes = {"n": "\n", "t": "\t", "r": "\r", '"': '"', "\\": "\\"}
                value += escapes.get(self.cur.cp, self.cur.cp)
                self.cur.next()
            else:
                value += self.cur.cp
                self.cur.next()

        if self.cur.cp != '"':
            self.compiler.add_error(start, "unterminated quoted string")
            return None

        self.cur.next()
        return TermToken(value, start, self.cur)

    def read_nonterm(self, start: Position) -> Optional[NonTermToken]:
        value = ""

        if self.cur.cp is not None and "A" <= self.cur.cp <= "Z":
            value += self.cur.cp
            self.cur.next()
        else:
            self.compiler.add_error(start, "nonterm must start with an uppercase Latin letter (A-Z)")
            if self.cur.cp is not None:
                self.cur.next()
            return None

        while self.cur.cp is not None and self.cur.cp.isdigit():
            value += self.cur.cp
            self.cur.next()

        return NonTermToken(value, start, self.cur)

    def next_token(self) -> Token:
        while True:
            self.skip_ws()

            if self.cur.cp is None:
                return EOFToken(self.cur)

            start = self.cur.copy()
            ch = self.cur.cp

            if ch == ";":
                comment_start = start.copy()
                comment_text = self.read_comment(start)
                comment_end = self.cur.copy()
                self.compiler.add_comment(comment_text, comment_start, comment_end)
                continue

            if ch == ",":
                self.cur.next()
                return SimpleToken(DomainTag.COMMA, start, self.cur)
            if ch == "{":
                self.cur.next()
                return SimpleToken(DomainTag.LBRACE, start, self.cur)
            if ch == "}":
                self.cur.next()
                return SimpleToken(DomainTag.RBRACE, start, self.cur)
            if ch == "<":
                self.cur.next()
                return SimpleToken(DomainTag.LANGLE, start, self.cur)
            if ch == ">":
                self.cur.next()
                return SimpleToken(DomainTag.RANGLE, start, self.cur)
            if ch == ":":
                self.cur.next()
                return SimpleToken(DomainTag.COLON, start, self.cur)
            if ch == "@":
                self.cur.next()
                return SimpleToken(DomainTag.EPS, start, self.cur)
            if ch == '"':
                token = self.read_quoted_term(start)
                if token is not None:
                    return token
                continue
            if ch.isalpha():
                token = self.read_nonterm(start)
                if token is not None:
                    return token
                continue

            bad = ""
            while (
                self.cur.cp is not None
                and not self.cur.is_whitespace()
                and self.cur.cp not in ',{}<>:@";'
            ):
                bad += self.cur.cp
                self.cur.next()
            if not bad:
                bad = self.cur.cp or ""
                if self.cur.cp is not None:
                    self.cur.next()
            self.compiler.add_error(start, f"unexpected character: {bad!r}")

    def scan(self) -> List[Token]:
        tokens: List[Token] = []
        while True:
            token = self.next_token()
            tokens.append(token)
            if token.tag == EOF_TAG:
                return tokens


@dataclass
class SymbolRef:
    kind: str
    name: str
    coord: str


@dataclass
class Alternative:
    symbols: List[SymbolRef]
    coord: str


@dataclass
class Rule:
    lhs: str
    alternatives: List[Alternative]
    coord: str


@dataclass
class DeclaredNonterminal:
    name: str
    is_start: bool
    coord: str


@dataclass
class GrammarSpec:
    declarations: List[DeclaredNonterminal]
    rules: List[Rule]


class TreeExtractor:
    def extract(self, root: Node) -> GrammarSpec:
        if root.name != "S":
            raise GenerationError("internal error: root of input grammar parse tree must be S")
        declarations = self.extract_D(root.children[0])
        rules = self.extract_R(root.children[1])
        return GrammarSpec(declarations, rules)

    @staticmethod
    def token_value(node: Node) -> str:
        if node.token is None:
            raise GenerationError(f"internal error: leaf {node.name} has no token")
        return str(node.token.value)

    @staticmethod
    def token_coord(node: Node) -> str:
        if node.token is None:
            raise GenerationError(f"internal error: leaf {node.name} has no token")
        return str(node.token.coord)

    def extract_D(self, node: Node) -> List[DeclaredNonterminal]:
        # D -> I L
        return [self.extract_I(node.children[0])] + self.extract_L(node.children[1])

    def extract_L(self, node: Node) -> List[DeclaredNonterminal]:
        # L -> COMMA I L | eps
        if not node.children:
            return []
        return [self.extract_I(node.children[1])] + self.extract_L(node.children[2])

    def extract_I(self, node: Node) -> DeclaredNonterminal:
        # I -> NONTERM | LBRACE NONTERM RBRACE
        if node.children[0].name == "NONTERM":
            leaf = node.children[0]
            return DeclaredNonterminal(self.token_value(leaf), False, self.token_coord(leaf))
        leaf = node.children[1]
        return DeclaredNonterminal(self.token_value(leaf), True, self.token_coord(leaf))

    def extract_R(self, node: Node) -> List[Rule]:
        # R -> P R | eps
        if not node.children:
            return []
        return [self.extract_P(node.children[0])] + self.extract_R(node.children[1])

    def extract_P(self, node: Node) -> Rule:
        # P -> LANGLE NONTERM COLON A RANGLE
        lhs_leaf = node.children[1]
        lhs = self.token_value(lhs_leaf)
        coord = self.token_coord(lhs_leaf)
        return Rule(lhs, self.extract_A(node.children[3]), coord)

    def extract_A(self, node: Node) -> List[Alternative]:
        # A -> C B
        return [self.extract_C(node.children[0])] + self.extract_B(node.children[1])

    def extract_B(self, node: Node) -> List[Alternative]:
        # B -> COLON C B | eps
        if not node.children:
            return []
        return [self.extract_C(node.children[1])] + self.extract_B(node.children[2])

    def extract_C(self, node: Node) -> Alternative:
        # C -> EPS | M
        first = node.children[0]
        if first.name == "EPS":
            return Alternative([], self.token_coord(first))
        symbols = self.extract_M(first)
        coord = symbols[0].coord if symbols else "(?)"
        return Alternative(symbols, coord)

    def extract_M(self, node: Node) -> List[SymbolRef]:
        # M -> Y N
        return [self.extract_Y(node.children[0])] + self.extract_N(node.children[1])

    def extract_N(self, node: Node) -> List[SymbolRef]:
        # N -> Y N | eps
        if not node.children:
            return []
        return [self.extract_Y(node.children[0])] + self.extract_N(node.children[1])

    def extract_Y(self, node: Node) -> SymbolRef:
        # Y -> NONTERM | TERM
        leaf = node.children[0]
        if leaf.name == "NONTERM":
            return SymbolRef("N", self.token_value(leaf), self.token_coord(leaf))
        return SymbolRef("T", self.token_value(leaf), self.token_coord(leaf))


@dataclass
class BuiltGrammar:
    terminals: Dict[str, int]
    nonterminals: Dict[str, int]
    symbol_names: Dict[int, str]
    start: int
    table: Dict[int, Dict[int, List[int]]]
    first: Dict[str, Set[str]]
    follow: Dict[str, Set[str]]


class GrammarBuilder:
    def __init__(self, spec: GrammarSpec):
        self.spec = spec
        self.errors: List[Message] = []
        self.declared_order: List[str] = []
        self.rules_by_lhs: Dict[str, Rule] = {}
        self.term_order: List[str] = []

    def add_error(self, coord: str, text: str) -> None:
        self.errors.append(Message(coord, text))

    def validate_declarations(self) -> Optional[str]:
        seen: Dict[str, str] = {}
        starts: List[DeclaredNonterminal] = []

        for decl in self.spec.declarations:
            if decl.name in seen:
                self.add_error(
                    decl.coord,
                    f"nonterminal {decl.name!r} is declared twice; "
                    f"first declaration at {seen[decl.name]}",
                )
            else:
                seen[decl.name] = decl.coord
                self.declared_order.append(decl.name)

            if decl.is_start:
                starts.append(decl)

        if not starts:
            self.add_error("(1, 1)", "axiom is not specified")
            return None

        if len(starts) > 1:
            for decl in starts[1:]:
                self.add_error(
                    decl.coord,
                    f"more than one axiom is specified; extra axiom {decl.name!r}",
                )
            return starts[0].name

        return starts[0].name

    def validate_rules_and_symbols(self) -> None:
        declared = set(self.declared_order)

        for rule in self.spec.rules:
            if rule.lhs not in declared:
                self.add_error(rule.coord, f"rule for undeclared nonterminal {rule.lhs!r}")
                continue

            if rule.lhs in self.rules_by_lhs:
                self.add_error(rule.coord, f"duplicate rule for nonterminal {rule.lhs!r}")
            else:
                self.rules_by_lhs[rule.lhs] = rule

            seen_alts: Set[Tuple[Tuple[str, str], ...]] = set()
            for alt in rule.alternatives:
                key = tuple((s.kind, s.name) for s in alt.symbols)
                if key in seen_alts:
                    self.add_error(alt.coord, f"duplicate alternative in rule {rule.lhs!r}")
                seen_alts.add(key)

                for sym in alt.symbols:
                    if sym.kind == "N":
                        if sym.name not in declared:
                            self.add_error(sym.coord, f"undeclared nonterminal {sym.name!r}")
                    else:
                        if sym.name not in self.term_order:
                            self.term_order.append(sym.name)

        for nonterm in self.declared_order:
            if nonterm not in self.rules_by_lhs:
                coord = next(d.coord for d in self.spec.declarations if d.name == nonterm)
                self.add_error(coord, f"nonterminal {nonterm!r} has no rule with it on the left side")

    def first_of_sequence(self, seq: Sequence[SymbolRef], first: Dict[str, Set[str]]) -> Set[str]:
        if not seq:
            return {EPS}

        result: Set[str] = set()
        all_nullable = True

        for sym in seq:
            if sym.kind == "T":
                result.add(sym.name)
                all_nullable = False
                break

            sym_first = first[sym.name]
            result.update(x for x in sym_first if x != EPS)

            if EPS not in sym_first:
                all_nullable = False
                break

        if all_nullable:
            result.add(EPS)

        return result

    def compute_first(self) -> Dict[str, Set[str]]:
        first: Dict[str, Set[str]] = {n: set() for n in self.declared_order}

        changed = True
        while changed:
            changed = False
            for lhs, rule in self.rules_by_lhs.items():
                for alt in rule.alternatives:
                    before = len(first[lhs])
                    first[lhs].update(self.first_of_sequence(alt.symbols, first))
                    if len(first[lhs]) != before:
                        changed = True

        return first

    def compute_follow(self, start_name: str, first: Dict[str, Set[str]]) -> Dict[str, Set[str]]:
        follow: Dict[str, Set[str]] = {n: set() for n in self.declared_order}
        follow[start_name].add(EOF_NAME)

        changed = True
        while changed:
            changed = False
            for lhs, rule in self.rules_by_lhs.items():
                for alt in rule.alternatives:
                    symbols = alt.symbols
                    for i, sym in enumerate(symbols):
                        if sym.kind != "N":
                            continue

                        beta = symbols[i + 1:]
                        first_beta = self.first_of_sequence(beta, first)
                        before = len(follow[sym.name])

                        follow[sym.name].update(x for x in first_beta if x != EPS)
                        if EPS in first_beta:
                            follow[sym.name].update(follow[lhs])

                        if len(follow[sym.name]) != before:
                            changed = True

        return follow

    def make_codes(self, start_name: str) -> Tuple[Dict[str, int], Dict[str, int], Dict[int, str]]:
        nonterminals = {name: -(i + 1) for i, name in enumerate(self.declared_order)}
        terminals = {name: i + 1 for i, name in enumerate(self.term_order)}

        symbol_names: Dict[int, str] = {EOF_TAG: EOF_NAME}
        for name, code in terminals.items():
            symbol_names[code] = name
        for name, code in nonterminals.items():
            symbol_names[code] = name

        return terminals, nonterminals, symbol_names

    @staticmethod
    def format_production(symbols: Sequence[SymbolRef]) -> str:
        if not symbols:
            return EPSILON_NAME
        return " ".join(sym.name for sym in symbols)

    def build(self) -> BuiltGrammar:
        start_name = self.validate_declarations()
        self.validate_rules_and_symbols()

        if self.errors:
            raise GenerationError(self.format_errors())
        if start_name is None:
            raise GenerationError(self.format_errors())

        first = self.compute_first()
        follow = self.compute_follow(start_name, first)
        terminals, nonterminals, symbol_names = self.make_codes(start_name)

        table: Dict[int, Dict[int, List[int]]] = {nonterminals[n]: {} for n in self.declared_order}

        def sym_code(sym: SymbolRef) -> int:
            return terminals[sym.name] if sym.kind == "T" else nonterminals[sym.name]

        for lhs, rule in self.rules_by_lhs.items():
            lhs_code = nonterminals[lhs]

            for alt in rule.alternatives:
                rhs_codes = [sym_code(s) for s in alt.symbols]
                lookaheads = self.first_of_sequence(alt.symbols, first)
                target_terms = [x for x in lookaheads if x != EPS]

                if EPS in lookaheads:
                    target_terms.extend(follow[lhs])

                for terminal_name in target_terms:
                    terminal_code = EOF_TAG if terminal_name == EOF_NAME else terminals[terminal_name]
                    old = table[lhs_code].get(terminal_code)

                    if old is not None:
                        existing = " ".join(symbol_names[x] for x in old) if old else EPSILON_NAME
                        current = self.format_production(alt.symbols)
                        self.add_error(
                            alt.coord,
                            f"grammar is not LL(1): conflict in cell "
                            f"[{lhs!r}, {terminal_name!r}], alternatives {existing!r} and {current!r}",
                        )
                    else:
                        table[lhs_code][terminal_code] = rhs_codes

        if self.errors:
            raise GenerationError(self.format_errors())

        return BuiltGrammar(
            terminals=terminals,
            nonterminals=nonterminals,
            symbol_names=symbol_names,
            start=nonterminals[start_name],
            table=table,
            first=first,
            follow=follow,
        )

    def format_errors(self) -> str:
        return "\n".join(f"Error {m.coord}: {m.text}" for m in self.errors)


def load_input_language_table():
    return gen_table
    # return BuiltinInputLanguageTable


def parse_specification(text: str) -> GrammarSpec:
    table_module = load_input_language_table()
    scanner = GrammarScanner(text)
    tokens = scanner.scan()

    if scanner.errors:
        raise GenerationError("\n".join(f"Error {m.coord}: {m.text}" for m in scanner.errors))

    parser = TableParser(table_module.PARSE_TABLE, table_module.START, table_module.SYMBOL_NAMES)
    tree = parser.parse(tokens)

    if tree is None:
        raise GenerationError("\n".join("Error " + e for e in parser.errors))

    return TreeExtractor().extract(tree)


def build_from_text(text: str) -> BuiltGrammar:
    spec = parse_specification(text)
    return GrammarBuilder(spec).build()


def emit_python_table(built: BuiltGrammar) -> str:
    return (
        "EOF = 0\n"
        f"TERMINALS = {pformat(built.terminals, width=100)}\n"
        f"NONTERMINALS = {pformat(built.nonterminals, width=100)}\n"
        f"START = {built.start!r}\n"
        f"SYMBOL_NAMES = {pformat(built.symbol_names, width=100)}\n"
        f"PARSE_TABLE = {pformat(built.table, width=100)}\n"
    )


def write_calculator_table(filename: str = "calculator_table.py") -> None:
    built = build_from_text(CALCULATOR_GRAMMAR)
    with open(filename, "w", encoding="utf-8") as f:
        f.write("from typing import Dict, List\n\n")
        f.write(emit_python_table(built))


def print_sets(title: str, sets: Dict[str, Set[str]]) -> None:
    print(title)
    for name in sorted(sets):
        values = ", ".join(sorted(sets[name]))
        print(f"  {name}: {{{values}}}")


def table_data(
    built: BuiltGrammar,
) -> Tuple[Dict[str, int], Dict[str, int], int, Dict[int, str], Dict[int, Dict[int, List[int]]]]:
    return built.terminals, built.nonterminals, built.start, built.symbol_names, built.table


def self_check(built) -> None:
    expected = BuiltinInputLanguageTable
    actual = table_data(built)
    reference = (
        expected.TERMINALS,
        expected.NONTERMINALS,
        expected.START,
        expected.SYMBOL_NAMES,
        expected.PARSE_TABLE,
    )
    if actual != reference:
        raise GenerationError("generated input language table differs from embedded table")
    else: 
        print('ok')


def print_generated_table(title: str, grammar_text: str) -> None:
    built = build_from_text(grammar_text)
    print(title)
    print(emit_python_table(built), end="")


def main() -> int:
    input_filename = sys.argv[1]
    output_filename = sys.argv[2]

    try:
        with open(input_filename, "r", encoding="utf-8") as f:
            grammar_text = f.read()

        built = build_from_text(grammar_text)

        # self_check(built)

        with open(output_filename, "w", encoding="utf-8") as f:
            f.write("from typing import Dict, List\n\n")
            f.write(emit_python_table(built))

        return 0

    except (GenerationError, OSError) as exc:
        print(str(exc), file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
```

## Калькулятор

```python
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
                    self.errors.append(
                        f"({line}, {col}): terminal {ch!r} "
                        f"is absent in calculator_table.py"
                    )
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
```

# Тестирование
## Генератор компиляторов

Таблица для калькулятора

```
from typing import Dict, List

EOF = 0
TERMINALS = {'(': 2, ')': 3, '*': 4, '+': 5, 'n': 1}
NONTERMINALS = {'E': -4, 'E1': -5, 'F': -1, 'T': -2, 'T1': -3}
START = -4
SYMBOL_NAMES = {
    -5: 'E1', -4: 'E', -3: 'T1', -2: 'T', -1: 'F', 0: 'EOF',
    1: 'n', 2: '(', 3: ')', 4: '*', 5: '+',
}
PARSE_TABLE = {-5: {0: [], 3: [], 5: [5, -2, -5]},
 -4: {1: [-2, -5], 2: [-2, -5]},
 -3: {0: [], 3: [], 4: [4, -1, -3], 5: []},
 -2: {1: [-1, -3], 2: [-1, -3]},
 -1: {1: [1], 2: [2, -4, 3]}}
```

Таблица для собственной грамматики

```
from typing import Dict, List

EOF = 0
TERMINALS = {'COLON': 6,
 'COMMA': 4,
 'EPS': 8,
 'LANGLE': 5,
 'LBRACE': 2,
 'NONTERM': 1,
 'RANGLE': 7,
 'RBRACE': 3,
 'TERM': 9}
NONTERMINALS = {'A': -7,
 'B': -8,
 'C': -9,
 'D': -2,
 'I': -4,
 'L': -3,
 'M': -10,
 'N': -11,
 'P': -6,
 'R': -5,
 'S': -1,
 'Y': -12}
START = -1
SYMBOL_NAMES = {-12: 'Y',
 -11: 'N',
 -10: 'M',
 -9: 'C',
 -8: 'B',
 -7: 'A',
 -6: 'P',
 -5: 'R',
 -4: 'I',
 -3: 'L',
 -2: 'D',
 -1: 'S',
 0: 'EOF',
 1: 'NONTERM',
 2: 'LBRACE',
 3: 'RBRACE',
 4: 'COMMA',
 5: 'LANGLE',
 6: 'COLON',
 7: 'RANGLE',
 8: 'EPS',
 9: 'TERM'}
PARSE_TABLE = {-12: {1: [1], 9: [9]},
 -11: {1: [-12, -11], 6: [], 7: [], 9: [-12, -11]},
 -10: {1: [-12, -11], 9: [-12, -11]},
 -9: {1: [-10], 8: [8], 9: [-10]},
 -8: {6: [6, -9, -8], 7: []},
 -7: {1: [-9, -8], 8: [-9, -8], 9: [-9, -8]},
 -6: {5: [5, 1, 6, -7, 7]},
 -5: {0: [], 5: [-6, -5]},
 -4: {1: [1], 2: [2, 1, 3]},
 -3: {0: [], 4: [4, -4, -3], 5: []},
 -2: {1: [-4, -3], 2: [-4, -3]},
 -1: {1: [-2, -5], 2: [-2, -5]}}
```

## Калькулятор


Входные данные

```
12*(3+4*5)+6*(7+8*(9+1))+2
```

Вывод на `stdout`

```
800
```

# Вывод
В процессе работы сформировалось понимание устройства самоприменимого генератора
компиляторов, а также закрепились навыки 
вычисления множеств FIRST и FOLLOW и построения грамматик.