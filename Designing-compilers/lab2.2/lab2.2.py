from __future__ import annotations

import abc
import enum
import pprint
import re
import sys
from dataclasses import dataclass

import parser_edsl as pe


class TypeNode(abc.ABC):
    pass


class PrimitiveKind(enum.Enum):
    INT = 'int'
    CHAR = 'char'
    BOOL = 'bool'


@dataclass
class PrimitiveType(TypeNode):
    kind: PrimitiveKind


@dataclass
class ArrayType(TypeNode):
    element_type: TypeNode


@dataclass
class Program:
    functions: list['FunctionDef']


@dataclass
class FunctionDef:
    return_type: TypeNode | None
    name: str
    params: list['Param']
    body: list['Statement']


@dataclass
class Param:
    type: TypeNode
    name: str
    init: 'Expr | None' = None


class Statement(abc.ABC):
    pass


@dataclass
class VarInit:
    name: str
    init: 'Expr | None' = None


@dataclass
class DeclStatement(Statement):
    type: TypeNode
    declarators: list[VarInit]


@dataclass
class AssignStatement(Statement):
    target: 'Expr'
    value: 'Expr'


@dataclass
class CallStatement(Statement):
    call: 'CallExpr'

@dataclass
class IfBranch:
    condition: 'Expr'
    body: list['Statement']


@dataclass
class IfStatement(Statement):
    branches: list[IfBranch]
    else_body: list['Statement'] | None


@dataclass
class WhileStatement(Statement):
    condition: 'Expr'
    body: list['Statement']


class ForInit(abc.ABC):
    pass


@dataclass
class ForVar(ForInit):
    name: str


@dataclass
class ForDecl(ForInit):
    type: TypeNode
    name: str


@dataclass
class ForStatement(Statement):
    init: ForInit
    start: 'Expr'
    end: 'Expr'
    step: 'Expr | None'
    body: list['Statement']


@dataclass
class DoWhileStatement(Statement):
    body: list['Statement']
    condition: 'Expr'


@dataclass
class ReturnStatement(Statement):
    value: 'Expr | None'


@dataclass
class AssertStatement(Statement):
    condition: 'Expr'


class Expr(abc.ABC):
    pass


ABSENT = object()

@dataclass
class TernOperation(Expr):
    condition: 'Expr'
    value1: 'Expr'
    value2: 'Expr'

@dataclass
class VariableExpr(Expr):
    name: str


@dataclass
class IntConstExpr(Expr):
    value: int
    base: int
    image: str


@dataclass
class CharConstExpr(Expr):
    value: str
    image: str


@dataclass
class StringConstExpr(Expr):
    value: str
    sections: list[str]


@dataclass
class BoolConstExpr(Expr):
    value: bool


@dataclass
class NullConstExpr(Expr):
    pass


@dataclass
class CallExpr(Expr):
    function: str
    args: list['Expr']


@dataclass
class NewExpr(Expr):
    element_type: TypeNode
    size: 'Expr'


@dataclass
class IndexExpr(Expr):
    array: 'Expr'
    index: 'Expr'


@dataclass
class UnaryOpExpr(Expr):
    op: str
    expr: 'Expr'


@dataclass
class BinaryOpExpr(Expr):
    left: 'Expr'
    op: str
    right: 'Expr'


CONTROL_CODES = {
    'NUL': 0,
    'SOH': 1,
    'STX': 2,
    'ETX': 3,
    'EOT': 4,
    'ENQ': 5,
    'ACK': 6,
    'BEL': 7,
    'BS': 8,
    'TAB': 9,
    'LF': 10,
    'VT': 11,
    'FF': 12,
    'CR': 13,
    'SO': 14,
    'SI': 15,
    'DLE': 16,
    'DC1': 17,
    'DC2': 18,
    'DC3': 19,
    'DC4': 20,
    'NAK': 21,
    'SYN': 22,
    'ETB': 23,
    'CAN': 24,
    'EM': 25,
    'SUB': 26,
    'ESC': 27,
    'FS': 28,
    'GS': 29,
    'RS': 30,
    'US': 31,
}

CONTROL_ALT_NAMES = '|'.join(sorted(CONTROL_CODES, key=len, reverse=True))

def parse_int_literal(image: str) -> IntConstExpr:
    if image.startswith('{'):
        close = image.index('}')
        base_text = image[1:close]
        digits = image[close + 1:]
        base = int(base_text, 10)
    else:
        base = 10
        digits = image

    if not (2 <= base <= 36):
        raise pe.TokenAttributeError(f'Недопустимое основание системы счисления: {base}')

    try:
        value = int(digits, base)
    except ValueError:
        raise pe.TokenAttributeError(f'Недопустимая запись числа {image!r} для основания {base}')

    if not (0 <= value <= 2147483647):
        raise pe.TokenAttributeError(f'Целочисленная константа вне диапазона: {image}')

    return IntConstExpr(value=value, base=base, image=image)


HEX_RE = re.compile(r'^\{([0-9A-Fa-f]+)\}$')


def decode_control_name(name: str) -> str:
    if name.startswith('{'):
        m = HEX_RE.match(name)
        assert m is not None
        code = int(m.group(1), 16)
    else:
        code = CONTROL_CODES[name]
    return chr(code)



def parse_char_quoted(image: str) -> CharConstExpr:
    inner = image[1:-1]
    value = "'" if inner == "''" else inner
    return CharConstExpr(value=value, image=image)



def parse_char_control(image: str) -> CharConstExpr:
    value = decode_control_name(image[1:])
    return CharConstExpr(value=value, image=image)



def parse_string_text(image: str) -> str:
    return image[1:-1]



def parse_string_ctrl(image: str) -> str:
    return decode_control_name(image[1:])


IDENT = pe.Terminal(
    'IDENT',
    r'[A-Za-zА-Яа-яЁё][A-Za-zА-Яа-яЁё0-9_]*',
    str,
)

INT_CONST = pe.Terminal(
    'INT_CONST',
    r'(?:[0-9]+|\{[0-9]+\}[0-9A-Za-z]+)',
    parse_int_literal,
    priority=7,
)

CHAR_QUOTED = pe.Terminal(
    'CHAR_QUOTED',
    r"'(?:[^'\r\n]|'')'",
    parse_char_quoted,
    priority=7,
)

CHAR_CTRL = pe.Terminal(
    'CHAR_CTRL',
    rf'#(?:{CONTROL_ALT_NAMES}|\{{[0-9A-Fa-f]+\}})',
    parse_char_control,
    priority=7,
)

STRING_TEXT = pe.Terminal(
    'STRING_TEXT',
    r'"[^"\r\n]*"',
    parse_string_text,
    priority=7,
)

STRING_QUOT = pe.Terminal(
    '$QUOT',
    r'\$QUOT',
    lambda _: '"',
    priority=10,
)

STRING_CTRL = pe.Terminal(
    'STRING_CTRL',
    rf'\$(?:{CONTROL_ALT_NAMES}|\{{[0-9A-Fa-f]+\}})',
    parse_string_ctrl,
    priority=7,
)


def kw(image: str) -> pe.Terminal:
    return pe.Terminal(image, image, lambda _: None, priority=10)


(
    KW_DEFINE,
    KW_INT,
    KW_CHAR,
    KW_BOOL,
    KW_ARRAY,
    KW_IF,
    KW_ELSIF,
    KW_ELSE,
    KW_THEN,
    KW_WHILE,
    KW_DO,
    KW_TO,
    KW_STEP,
    KW_RETURN,
    KW_ASSERT,
    KW_NEW,
    KW_MOD,
    KW_AND,
    KW_OR,
    KW_XOR,
    KW_NOT,
    KW_NULL,
    KW_T,
    KW_F,
    KW_END,
) = map(
    kw,
    (
        'define int char bool array if elsif else then while do to step '
        'return assert new mod and or xor not NULL T F end'
    ).split(),
)


(
    NProgram,
    NFuncDefs,
    NFuncDef,
    NOptType,
    NType,
    NBaseType,
    NParamListOpt,
    NParamList,
    NParam,
    NOptInit,
    NStmtListOpt,
    NStmtList,
    NStmt,
    NDeclItems,
    NDeclItem,
    NElseIfList,
    NElseIf,
    NElseOpt,
    NForInit,
    NStepOpt,
    NExpr,
    NOrExpr,
    NAndExpr,
    NCmpExpr,
    NAddExpr,
    NMulExpr,
    NPowExpr,
    NUnaryExpr,
    NPostfixExpr,
    NPostfixTail,
    NPrimaryExpr,
    NArgListOpt,
    NArgList,
    NConst,
    NStringConst,
    NStringSections,
    NStringSection,
    NCmpOp,
    NAddOp,
    NMulOp,
    NTerExpr,
) = map(
    pe.NonTerminal,
    (
        'Program FuncDefs FuncDef OptType Type BaseType ParamListOpt ParamList Param OptInit '
        'StmtListOpt StmtList Stmt DeclItems DeclItem ElseIfList ElseIf ElseOpt ForInit StepOpt '
        'Expr OrExpr AndExpr CmpExpr AddExpr MulExpr PowExpr UnaryExpr PostfixExpr PostfixTail '
        'PrimaryExpr ArgListOpt ArgList Const StringConst StringSections StringSection CmpOp AddOp MulOp NTerExpr'
    ).split(),
)

NProgram |= NFuncDefs, Program

NFuncDefs |= NFuncDef, lambda fd: [fd]
NFuncDefs |= NFuncDefs, NFuncDef, lambda fds, fd: fds + [fd]

NOptType |= lambda: ABSENT
NOptType |= NType

NFuncDef |= (
    KW_DEFINE,
    NOptType,
    IDENT,
    '(',
    NParamListOpt,
    ')',
    NStmtListOpt,
    KW_END,
    lambda ret_type, name, params, body: FunctionDef(None if ret_type is ABSENT else ret_type, name, params, body),
)

NBaseType |= KW_INT, lambda: PrimitiveType(PrimitiveKind.INT)
NBaseType |= KW_CHAR, lambda: PrimitiveType(PrimitiveKind.CHAR)
NBaseType |= KW_BOOL, lambda: PrimitiveType(PrimitiveKind.BOOL)

NType |= NBaseType
NType |= NType, KW_ARRAY, ArrayType

NParamListOpt |= lambda: []
NParamListOpt |= NParamList

NParamList |= NParam, lambda p: [p]
NParamList |= NParamList, ',', NParam, lambda ps, p: ps + [p]

NOptInit |= lambda: ABSENT
NOptInit |= ':=', NExpr, lambda expr: expr

NParam |= NType, IDENT, NOptInit, lambda typ, name, init: Param(typ, name, None if init is ABSENT else init)

NStmtListOpt |= lambda: []
NStmtListOpt |= NStmtList

NStmtList |= NStmt, lambda s: [s]
NStmtList |= NStmtList, ';', NStmt, lambda ss, s: ss + [s]

NDeclItems |= NDeclItem, lambda d: [d]
NDeclItems |= NDeclItems, ',', NDeclItem, lambda ds, d: ds + [d]

NDeclItem |= IDENT, NOptInit, lambda name, init: VarInit(name, None if init is ABSENT else init)

NElseIfList |= lambda: []
NElseIfList |= NElseIfList, NElseIf, lambda xs, x: xs + [x]

NElseIf |= KW_ELSIF, NExpr, KW_THEN, NStmtListOpt, lambda cond, body: IfBranch(cond, body)

NElseOpt |= lambda: ABSENT
NElseOpt |= KW_ELSE, NStmtListOpt, lambda body: body

NForInit |= IDENT, ForVar
NForInit |= NType, IDENT, ForDecl

NStepOpt |= lambda: ABSENT
NStepOpt |= KW_STEP, NExpr, lambda expr: expr

NStmt |= NType, NDeclItems, DeclStatement
NStmt |= NExpr, ':=', NExpr, AssignStatement
NStmt |= IDENT, '(', NArgListOpt, ')', lambda name, args: CallStatement(CallExpr(name, args))
NStmt |= (
    KW_IF,
    NExpr,
    KW_THEN,
    NStmtListOpt,
    NElseIfList,
    NElseOpt,
    KW_END,
    lambda cond, then_body, elifs, else_body: IfStatement([IfBranch(cond, then_body)] + elifs, None if else_body is ABSENT else else_body),
)
NStmt |= KW_WHILE, NExpr, KW_DO, NStmtListOpt, KW_END, WhileStatement
NStmt |= (
    NForInit,
    ':=',
    NExpr,
    KW_TO,
    NExpr,
    NStepOpt,
    KW_DO,
    NStmtListOpt,
    KW_END,
    lambda init, start, end, step, body: ForStatement(init, start, end, None if step is ABSENT else step, body),
)
NStmt |= KW_DO, NStmtListOpt, KW_WHILE, NExpr, DoWhileStatement
NStmt |= KW_RETURN, lambda: ReturnStatement(None)
NStmt |= KW_RETURN, NExpr, ReturnStatement
NStmt |= KW_ASSERT, NExpr, AssertStatement

NExpr |= NOrExpr

NOrExpr |= NAndExpr
NOrExpr |= NOrExpr, KW_OR, NAndExpr, lambda x, y: BinaryOpExpr(x, 'or', y)
NOrExpr |= NOrExpr, KW_XOR, NAndExpr, lambda x, y: BinaryOpExpr(x, 'xor', y)

NAndExpr |= NCmpExpr
NAndExpr |= NAndExpr, KW_AND, NCmpExpr, lambda x, y: BinaryOpExpr(x, 'and', y)

NCmpExpr |= NTerExpr
NCmpExpr |= NCmpExpr, NCmpOp, NTerExpr, BinaryOpExpr

for op in ('=', '<>', '<', '>', '<=', '>='):
    NCmpOp |= op, (lambda op=op: op)

NTerExpr |= NAddExpr
NTerExpr |= NAddExpr, '?', NAddExpr, ':', NTerExpr, TernOperation

NAddExpr |= NMulExpr
NAddExpr |= NAddExpr, NAddOp, NMulExpr, BinaryOpExpr

NAddOp |= '+', lambda: '+'
NAddOp |= '-', lambda: '-'

NMulExpr |= NPowExpr
NMulExpr |= NMulExpr, NMulOp, NPowExpr, BinaryOpExpr

NMulOp |= '*', lambda: '*'
NMulOp |= '/', lambda: '/'
NMulOp |= KW_MOD, lambda: 'mod'

NPowExpr |= NUnaryExpr
NPowExpr |= NUnaryExpr, '**', NPowExpr, lambda x, y: BinaryOpExpr(x, '**', y)

NUnaryExpr |= NPostfixExpr
NUnaryExpr |= '-', NUnaryExpr, lambda x: UnaryOpExpr('-', x)
NUnaryExpr |= KW_NOT, NUnaryExpr, lambda x: UnaryOpExpr('not', x)

NPostfixExpr |= NPrimaryExpr
NPostfixExpr |= NPostfixExpr, '[', NExpr, ']', IndexExpr

NPrimaryExpr |= IDENT, lambda name: VariableExpr(name)
NPrimaryExpr |= IDENT, '(', NArgListOpt, ')', CallExpr
NPrimaryExpr |= KW_NEW, NType, '[', NExpr, ']', NewExpr
NPrimaryExpr |= NConst
NPrimaryExpr |= '(', NExpr, ')'

NArgListOpt |= lambda: []
NArgListOpt |= NArgList

NArgList |= NExpr, lambda e: [e]
NArgList |= NArgList, ',', NExpr, lambda es, e: es + [e]

NConst |= INT_CONST
NConst |= CHAR_QUOTED
NConst |= CHAR_CTRL
NConst |= NStringConst
NConst |= KW_T, lambda: BoolConstExpr(True)
NConst |= KW_F, lambda: BoolConstExpr(False)
NConst |= KW_NULL, lambda: NullConstExpr()

NStringConst |= NStringSections, lambda sections: StringConstExpr(''.join(sections), sections)

NStringSections |= NStringSection, lambda s: [s]
NStringSections |= NStringSections, NStringSection, lambda ss, s: ss + [s]

NStringSection |= STRING_TEXT
NStringSection |= STRING_QUOT
NStringSection |= STRING_CTRL

parser = pe.Parser(NProgram, method=pe.EARLEY)
parser.add_skipped_domain(r'[ \t\r\n]+')
parser.add_skipped_domain(r'(?m)^\*[^\n]*(?:\n|$)')
parser.add_skipped_domain(r'\*\*\*[^\n]*(?:\n|$)')

def parse_text(text: str) -> Program:
    return parser.parse(text)

if __name__ == '__main__':
    if len(sys.argv) == 1:
        print('Usage: python l1_parser.py <file1> [file2 ...]')
        raise SystemExit(0)

    for filename in sys.argv[1:]:
        try:
            with open(filename, 'r', encoding='utf-8') as f:
                tree = parse_text(f.read())
            print(f'=== {filename} ===')
            pprint.pp(tree, sort_dicts=False)
        except pe.Error as e:
            print(f'Ошибка {e.pos}: {e.message}')
        except Exception as e:
            print(f'Ошибка: {e}')