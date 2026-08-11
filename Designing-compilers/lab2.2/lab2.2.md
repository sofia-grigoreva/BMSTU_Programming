% Лабораторная работа № 2.2 «Абстрактные синтаксические деревья»
% 14 апреля 2026 г.
% Софья Григорьева, ИУ9-61Б

# Цель работы
Целью данной работы является получение навыков составления грамматик и проектирования
синтаксических деревьев.

# Индивидуальный вариант
Язык L1.

## Синтаксическое расширение для защиты
Тернарная операция c правой ассоциативностью и приоритетом выше, чем у сравнений, но ниже, чем у + и -.

# Реализация

## Абстрактный синтаксис

Программа состоит из одного или нескольких определений функций:

```
Program → FunctionDef+
```

Определение функции содержит необязательный тип результата, имя, список параметров и
последовательность операторов:

```
FunctionDef → DEFINE Type? IDENT ( Params ) Statements END
Params → Param*
Param → Type IDENT Init?
Init → := Expr
```

Типом может быть примитивный тип или массив:

```
Type → INT | CHAR | BOOL | Type ARRAY
```

Последовательность операторов содержит ноль или более операторов:

```
Statements → Statement*
```

Оператором может быть объявление, присваивание, вызов процедуры, ветвление, цикл,
возврат из функции или проверка условия:

```
Statement → Type VarInit*
          | Expr := Expr
          | IDENT ( Args )
          | IF Expr THEN Statements Elsif* Else? END
          | WHILE Expr DO Statements END
          | ForInit := Expr TO Expr Step? DO Statements END
          | DO Statements WHILE Expr
          | RETURN Expr?
          | ASSERT Expr
VarInit → IDENT Init?
ForInit → IDENT | Type IDENT
Step → STEP Expr
Elsif → ELSIF Expr THEN Statements
Else → ELSE Statements
Args → Expr*
```

Выражение — переменная, константа, вызов функции, создание массива, индексирование,
одноместная или двуместная операция:

```
Expr → IDENT
     | Const
     | IDENT ( Args )
     | NEW Type [ Expr ]
     | Expr [ Expr ]
     | UnOp Expr
     | Expr BinOp Expr
     | ( Expr )
Const → INT_CONST | CHAR_CONST | STRING_CONST | T | F | NULL
UnOp → - | NOT
BinOp → OR | XOR | AND | = | <> | < | > | <= | >=
      | + | - | * | / | MOD | **
```

## Лексическая структура и конкретный синтаксис

Идентификаторы начинаются с буквы русского или латинского алфавита и далее могут
содержать буквы, цифры и символ `_`.

Целые константы записываются в десятичной форме или в форме `{основание}цифры`.
Основание системы счисления должно лежать в диапазоне от 2 до 36.

Символьные константы записываются в одинарных кавычках. Одинарная кавычка внутри
символьной константы записывается удвоением. Также доступны управляющие символы вида
`#LF`, `#TAB`, `#CR` и шестнадцатеричные коды вида `#{0A}`.

Строковая константа состоит из одной или нескольких секций: текста в двойных кавычках,
секции `$QUOT`, задающей двойную кавычку, и управляющих символов вида `$LF` или
`${0A}`.

Пробельные символы незначимы. Полнострочный комментарий начинается с `*`, хвостовой
комментарий начинается с `***`.

Перейдём к конкретной грамматике:

```
Program → FuncDefs
FuncDefs → FuncDef | FuncDefs FuncDef

FuncDef → DEFINE OptType IDENT ( ParamListOpt ) StmtListOpt END
OptType → ε | Type
Type → BaseType | Type ARRAY
BaseType → INT | CHAR | BOOL

ParamListOpt → ε | ParamList
ParamList → Param | ParamList , Param
Param → Type IDENT OptInit
OptInit → ε | := Expr

StmtListOpt → ε | StmtList
StmtList → Stmt | StmtList ; Stmt

Stmt → Type DeclItems
     | Expr := Expr
     | IDENT ( ArgListOpt )
     | IF Expr THEN StmtListOpt ElseIfList ElseOpt END
     | WHILE Expr DO StmtListOpt END
     | ForInit := Expr TO Expr StepOpt DO StmtListOpt END
     | DO StmtListOpt WHILE Expr
     | RETURN
     | RETURN Expr
     | ASSERT Expr

DeclItems → DeclItem | DeclItems , DeclItem
DeclItem → IDENT OptInit
ElseIfList → ε | ElseIfList ElseIf
ElseIf → ELSIF Expr THEN StmtListOpt
ElseOpt → ε | ELSE StmtListOpt
ForInit → IDENT | Type IDENT
StepOpt → ε | STEP Expr
```

Для учёта приоритета операций выражение разбивается на несколько нетерминалов:

```
Expr → OrExpr

OrExpr → AndExpr
       | OrExpr OR AndExpr
       | OrExpr XOR AndExpr

AndExpr → CmpExpr
        | AndExpr AND CmpExpr

CmpExpr → AddExpr
        | CmpExpr CmpOp AddExpr
CmpOp → = | <> | < | > | <= | >=

AddExpr → MulExpr
        | AddExpr AddOp MulExpr
AddOp → + | -

MulExpr → PowExpr
        | MulExpr MulOp PowExpr
MulOp → * | / | MOD

PowExpr → UnaryExpr
        | UnaryExpr ** PowExpr

UnaryExpr → PostfixExpr
          | - UnaryExpr
          | NOT UnaryExpr

PostfixExpr → PrimaryExpr
            | PostfixExpr [ Expr ]

PrimaryExpr → IDENT
            | IDENT ( ArgListOpt )
            | NEW Type [ Expr ]
            | Const
            | ( Expr )

ArgListOpt → ε | ArgList
ArgList → Expr | ArgList , Expr

Const → INT_CONST | CHAR_CONST | STRING_CONST | T | F | NULL
StringConst → StringSection+
StringSection → STRING_TEXT | $QUOT | STRING_CTRL
```

## Программная реализация

```python
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
        'PrimaryExpr ArgListOpt ArgList Const StringConst StringSections StringSection '
        'CmpOp AddOp MulOp NTerExpr'
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
    lambda ret_type, name, params, body: FunctionDef(
        None if ret_type is ABSENT else ret_type,
        name,
        params,
        body,
    ),
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
    lambda cond, then_body, elifs, else_body: IfStatement(
        [IfBranch(cond, then_body)] + elifs,
        None if else_body is ABSENT else else_body,
    ),
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
    lambda init, start, end, step, body: ForStatement(
        init,
        start,
        end,
        None if step is ABSENT else step,
        body,
    ),
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
```

# Тестирование

## Входные данные

```
* Полнострочный комментарий

define int array MakeRange(int n)
int array a := new int[n];
int i := 0 to n - 1 do
  a[i] := i ** 2
end;
return a
end

define Log(char array text)
assert text <> NULL
end

define int Main(char array array args)
int x := {16}1F, y := 2, z;
char nl := #LF, quote := '''', letter := 'A';
char array msg := "We say " $QUOT "Hello" $QUOT $LF;
bool ok := T xor F;
int array a := MakeRange(5);
z := a[1] + x mod y; *** хвостовой комментарий
Log(msg);
if x > y then
  z := z + 1
elsif x = y then
  z := 0
else
  z := z - 1
end;
while z > 0 do
  z := z - 1
end;
int i := 0 to 4 step 1 do
  a[i] := a[i] + i
end;
char ch := 'A' to 'C' do
  letter := ch
end;
do
  x := x - 1
while x > 0;
assert args <> NULL and ok = T;
int abs := (x > 0) ? x : -x;
int sign := (x < 0) ? -1 : (x > 0) ? 1 : 0;
*** Тернарная операция имеет приоритет выше, чем у сравнений, ниже, чем у + и -
*** Ассоциативность - правая
int z := 1 > 2 + 5 ? 3 : 4 + 4;
return 0
end

define int array SumVectors(int array A, int array B)
    int size := Length(A);
    assert size = Length(B);
    int array C := new int[size];
    int i := 0 to size - 1 do
        C[i] := A[i] + B[i]
    end;
    return C
end

define int Main(char array array args)
    *** какие-то действия
    return 0
end

define int UseAllReserved(char array array Args)
    int x := 10, y := 3, i := 0;
    char c := 'A';
    bool p := T, q := F, r := not F;
    int array A := new int[10];
    char array S := NULL;

    assert (p and not q) or (p xor q);

    if x mod y = 1 then
        A[0] := x + y
    elsif x < y then
        A[0] := x - y
    else
        A[0] := x ** 2 / y
    end;

    while i < 3 do
        A[i] := A[i] + 1;
        i := i + 1
    end;

    int j := 0 to 5 step 2 do
        A[j] := j
    end;

    do
        x := x - 1
    while x > 0;

    if S = NULL then
        S := "ok"
    else
        S := "bad"
    end;

    return A[0]
end
```

## Вывод на `stdout`

```
=== input.txt ===
Program(functions=[FunctionDef(return_type=ArrayType(element_type=PrimitiveType(kind=<PrimitiveKind.INT:
  'int'>)),
                               name='MakeRange',
                               params=[Param(type=PrimitiveType(kind=<PrimitiveKind.INT: 'int'>),
                                             name='n',
                                             init=None)],
body=[DeclStatement(type=ArrayType(element_type=PrimitiveType(kind=<PrimitiveKind.INT: 'int'>)),
                                                   declarators=[VarInit(name='a',
init=NewExpr(element_type=PrimitiveType(kind=<PrimitiveKind.INT: 'int'>),
size=VariableExpr(name='n')))]),
                                     ForStatement(init=ForDecl(type=PrimitiveType(kind=<PrimitiveKind.INT:
                                       'int'>),
                                                               name='i'),
                                                  start=IntConstExpr(value=0,
                                                                     base=10,
                                                                     image='0'),
                                                  end=BinaryOpExpr(left=VariableExpr(name='n'),
                                                                   op='-',
                                                                   right=IntConstExpr(value=1,
                                                                                      base=10,
                                                                                      image='1')),
                                                  step=None,
body=[AssignStatement(target=IndexExpr(array=VariableExpr(name='a'),
index=VariableExpr(name='i')),
value=BinaryOpExpr(left=VariableExpr(name='i'),
                                                                                           op='**',
right=IntConstExpr(value=2,
base=10,
image='2')))]),
                                     ReturnStatement(value=VariableExpr(name='a'))]),
                   FunctionDef(return_type=None,
                               name='Log',
params=[Param(type=ArrayType(element_type=PrimitiveType(kind=<PrimitiveKind.CHAR: 'char'>)),
                                             name='text',
                                             init=None)],
                               body=[AssertStatement(condition=BinaryOpExpr(left=VariableExpr(name='text'),
                                                                            op='<>',
                                                                            right=NullConstExpr()))]),
                   FunctionDef(return_type=PrimitiveType(kind=<PrimitiveKind.INT: 'int'>),
                               name='Main',
params=[Param(type=ArrayType(element_type=ArrayType(element_type=PrimitiveType(kind=<PrimitiveKind.CHAR:
                                 'char'>))),
                                             name='args',
                                             init=None)],
                               body=[DeclStatement(type=PrimitiveType(kind=<PrimitiveKind.INT: 'int'>),
                                                   declarators=[VarInit(name='x',
                                                                        init=IntConstExpr(value=31,
                                                                                          base=16,
                                                                                          image='{16}1F')),
                                                                VarInit(name='y',
                                                                        init=IntConstExpr(value=2,
                                                                                          base=10,
                                                                                          image='2')),
                                                                VarInit(name='z',
                                                                        init=None)]),
                                     DeclStatement(type=PrimitiveType(kind=<PrimitiveKind.CHAR: 'char'>),
                                                   declarators=[VarInit(name='nl',
                                                                        init=CharConstExpr(value='\n',
                                                                                           image='#LF')),
                                                                VarInit(name='quote',
                                                                        init=CharConstExpr(value="'",
                                                                                           image="''''")),
                                                                VarInit(name='letter',
                                                                        init=CharConstExpr(value='A',
                                                                                           image="'A'"))]),
DeclStatement(type=ArrayType(element_type=PrimitiveType(kind=<PrimitiveKind.CHAR: 'char'>)),
                                                   declarators=[VarInit(name='msg',
                                                                        init=StringConstExpr(value='We '
                                                                                                   'say '
'"Hello"\n',
                                                                                             sections=['We '
                                                                                                       'say
                                                                                                         ',
                                                                                                       '"',
'Hello',
                                                                                                       '"',
'\n']))]),
                                     DeclStatement(type=PrimitiveType(kind=<PrimitiveKind.BOOL: 'bool'>),
                                                   declarators=[VarInit(name='ok',
init=BinaryOpExpr(left=BoolConstExpr(value=True),
                                                                                          op='xor',
right=BoolConstExpr(value=False)))]),
DeclStatement(type=ArrayType(element_type=PrimitiveType(kind=<PrimitiveKind.INT: 'int'>)),
                                                   declarators=[VarInit(name='a',
                                                                        init=CallExpr(function='MakeRange',
args=[IntConstExpr(value=5,
base=10,
image='5')]))]),
                                     AssignStatement(target=VariableExpr(name='z'),
value=BinaryOpExpr(left=IndexExpr(array=VariableExpr(name='a'),
index=IntConstExpr(value=1,
base=10,
image='1')),
                                                                        op='+',
right=BinaryOpExpr(left=VariableExpr(name='x'),
                                                                                           op='mod',
right=VariableExpr(name='y')))),
                                     CallStatement(call=CallExpr(function='Log',
                                                                 args=[VariableExpr(name='msg')])),
IfStatement(branches=[IfBranch(condition=BinaryOpExpr(left=VariableExpr(name='x'),
                                                                                           op='>',
right=VariableExpr(name='y')),
body=[AssignStatement(target=VariableExpr(name='z'),
value=BinaryOpExpr(left=VariableExpr(name='z'),
op='+',
right=IntConstExpr(value=1,
base=10,
image='1')))]),
IfBranch(condition=BinaryOpExpr(left=VariableExpr(name='x'),
                                                                                           op='=',
right=VariableExpr(name='y')),
body=[AssignStatement(target=VariableExpr(name='z'),
value=IntConstExpr(value=0,
base=10,
image='0'))])],
                                                 else_body=[AssignStatement(target=VariableExpr(name='z'),
value=BinaryOpExpr(left=VariableExpr(name='z'),
                                                                                               op='-',
right=IntConstExpr(value=1,
base=10,
image='1')))]),
                                     WhileStatement(condition=BinaryOpExpr(left=VariableExpr(name='z'),
                                                                           op='>',
                                                                           right=IntConstExpr(value=0,
                                                                                              base=10,
                                                                                              image='0')),
                                                    body=[AssignStatement(target=VariableExpr(name='z'),
value=BinaryOpExpr(left=VariableExpr(name='z'),
                                                                                             op='-',
right=IntConstExpr(value=1,
base=10,
image='1')))]),
                                     ForStatement(init=ForDecl(type=PrimitiveType(kind=<PrimitiveKind.INT:
                                       'int'>),
                                                               name='i'),
                                                  start=IntConstExpr(value=0,
                                                                     base=10,
                                                                     image='0'),
                                                  end=IntConstExpr(value=4,
                                                                   base=10,
                                                                   image='4'),
                                                  step=IntConstExpr(value=1,
                                                                    base=10,
                                                                    image='1'),
body=[AssignStatement(target=IndexExpr(array=VariableExpr(name='a'),
index=VariableExpr(name='i')),
value=BinaryOpExpr(left=IndexExpr(array=VariableExpr(name='a'),
index=VariableExpr(name='i')),
                                                                                           op='+',
right=VariableExpr(name='i')))]),
                                     ForStatement(init=ForDecl(type=PrimitiveType(kind=<PrimitiveKind.CHAR:
                                       'char'>),
                                                               name='ch'),
                                                  start=CharConstExpr(value='A',
                                                                      image="'A'"),
                                                  end=CharConstExpr(value='C',
                                                                    image="'C'"),
                                                  step=None,
                                                  body=[AssignStatement(target=VariableExpr(name='letter'),
                                                                        value=VariableExpr(name='ch'))]),
                                     DoWhileStatement(body=[AssignStatement(target=VariableExpr(name='x'),
value=BinaryOpExpr(left=VariableExpr(name='x'),
                                                                                               op='-',
right=IntConstExpr(value=1,
base=10,
image='1')))],
                                                      condition=BinaryOpExpr(left=VariableExpr(name='x'),
                                                                             op='>',
                                                                             right=IntConstExpr(value=0,
                                                                                                base=10,
image='0'))),
AssertStatement(condition=BinaryOpExpr(left=BinaryOpExpr(left=VariableExpr(name='args'),
                                                                                              op='<>',
right=NullConstExpr()),
                                                                            op='and',
right=BinaryOpExpr(left=VariableExpr(name='ok'),
                                                                                               op='=',
right=BoolConstExpr(value=True)))),
                                     DeclStatement(type=PrimitiveType(kind=<PrimitiveKind.INT: 'int'>),
                                                   declarators=[VarInit(name='abs',
init=TernOperation(condition=BinaryOpExpr(left=VariableExpr(name='x'),
op='>',
right=IntConstExpr(value=0,
base=10,
image='0')),
value1=VariableExpr(name='x'),
value2=UnaryOpExpr(op='-',
expr=VariableExpr(name='x'))))]),
                                     DeclStatement(type=PrimitiveType(kind=<PrimitiveKind.INT: 'int'>),
                                                   declarators=[VarInit(name='sign',
init=TernOperation(condition=BinaryOpExpr(left=VariableExpr(name='x'),
op='<',
right=IntConstExpr(value=0,
base=10,
image='0')),
value1=UnaryOpExpr(op='-',
expr=IntConstExpr(value=1,
base=10,
image='1')),
value2=TernOperation(condition=BinaryOpExpr(left=VariableExpr(name='x'),
op='>',
right=IntConstExpr(value=0,
base=10,
image='0')),
value1=IntConstExpr(value=1,
base=10,
image='1'),
value2=IntConstExpr(value=0,
base=10,
image='0'))))]),
                                     DeclStatement(type=PrimitiveType(kind=<PrimitiveKind.INT: 'int'>),
                                                   declarators=[VarInit(name='z',
init=BinaryOpExpr(left=IntConstExpr(value=1,
base=10,
image='1'),
                                                                                          op='>',
right=TernOperation(condition=BinaryOpExpr(left=IntConstExpr(value=2,
base=10,
image='2'),
op='+',
right=IntConstExpr(value=5,
base=10,
image='5')),
value1=IntConstExpr(value=3,
base=10,
image='3'),
value2=BinaryOpExpr(left=IntConstExpr(value=4,
base=10,
image='4'),
op='+',
right=IntConstExpr(value=4,
base=10,
image='4')))))]),
                                     ReturnStatement(value=IntConstExpr(value=0,
                                                                        base=10,
                                                                        image='0'))]),
                   FunctionDef(return_type=ArrayType(element_type=PrimitiveType(kind=<PrimitiveKind.INT:
                     'int'>)),
                               name='SumVectors',
params=[Param(type=ArrayType(element_type=PrimitiveType(kind=<PrimitiveKind.INT: 'int'>)),
                                             name='A',
                                             init=None),
Param(type=ArrayType(element_type=PrimitiveType(kind=<PrimitiveKind.INT: 'int'>)),
                                             name='B',
                                             init=None)],
                               body=[DeclStatement(type=PrimitiveType(kind=<PrimitiveKind.INT: 'int'>),
                                                   declarators=[VarInit(name='size',
                                                                        init=CallExpr(function='Length',
args=[VariableExpr(name='A')]))]),
                                     AssertStatement(condition=BinaryOpExpr(left=VariableExpr(name='size'),
                                                                            op='=',
right=CallExpr(function='Length',
args=[VariableExpr(name='B')]))),
DeclStatement(type=ArrayType(element_type=PrimitiveType(kind=<PrimitiveKind.INT: 'int'>)),
                                                   declarators=[VarInit(name='C',
init=NewExpr(element_type=PrimitiveType(kind=<PrimitiveKind.INT: 'int'>),
size=VariableExpr(name='size')))]),
                                     ForStatement(init=ForDecl(type=PrimitiveType(kind=<PrimitiveKind.INT:
                                       'int'>),
                                                               name='i'),
                                                  start=IntConstExpr(value=0,
                                                                     base=10,
                                                                     image='0'),
                                                  end=BinaryOpExpr(left=VariableExpr(name='size'),
                                                                   op='-',
                                                                   right=IntConstExpr(value=1,
                                                                                      base=10,
                                                                                      image='1')),
                                                  step=None,
body=[AssignStatement(target=IndexExpr(array=VariableExpr(name='C'),
index=VariableExpr(name='i')),
value=BinaryOpExpr(left=IndexExpr(array=VariableExpr(name='A'),
index=VariableExpr(name='i')),
                                                                                           op='+',
right=IndexExpr(array=VariableExpr(name='B'),
index=VariableExpr(name='i'))))]),
                                     ReturnStatement(value=VariableExpr(name='C'))]),
                   FunctionDef(return_type=PrimitiveType(kind=<PrimitiveKind.INT: 'int'>),
                               name='Main',
params=[Param(type=ArrayType(element_type=ArrayType(element_type=PrimitiveType(kind=<PrimitiveKind.CHAR:
                                 'char'>))),
                                             name='args',
                                             init=None)],
                               body=[ReturnStatement(value=IntConstExpr(value=0,
                                                                        base=10,
                                                                        image='0'))]),
                   FunctionDef(return_type=PrimitiveType(kind=<PrimitiveKind.INT: 'int'>),
                               name='UseAllReserved',
params=[Param(type=ArrayType(element_type=ArrayType(element_type=PrimitiveType(kind=<PrimitiveKind.CHAR:
                                 'char'>))),
                                             name='Args',
                                             init=None)],
                               body=[DeclStatement(type=PrimitiveType(kind=<PrimitiveKind.INT: 'int'>),
                                                   declarators=[VarInit(name='x',
                                                                        init=IntConstExpr(value=10,
                                                                                          base=10,
                                                                                          image='10')),
                                                                VarInit(name='y',
                                                                        init=IntConstExpr(value=3,
                                                                                          base=10,
                                                                                          image='3')),
                                                                VarInit(name='i',
                                                                        init=IntConstExpr(value=0,
                                                                                          base=10,
                                                                                          image='0'))]),
                                     DeclStatement(type=PrimitiveType(kind=<PrimitiveKind.CHAR: 'char'>),
                                                   declarators=[VarInit(name='c',
                                                                        init=CharConstExpr(value='A',
                                                                                           image="'A'"))]),
                                     DeclStatement(type=PrimitiveType(kind=<PrimitiveKind.BOOL: 'bool'>),
                                                   declarators=[VarInit(name='p',
                                                                        init=BoolConstExpr(value=True)),
                                                                VarInit(name='q',
                                                                        init=BoolConstExpr(value=False)),
                                                                VarInit(name='r',
                                                                        init=UnaryOpExpr(op='not',
expr=BoolConstExpr(value=False)))]),
DeclStatement(type=ArrayType(element_type=PrimitiveType(kind=<PrimitiveKind.INT: 'int'>)),
                                                   declarators=[VarInit(name='A',
init=NewExpr(element_type=PrimitiveType(kind=<PrimitiveKind.INT: 'int'>),
size=IntConstExpr(value=10,
base=10,
image='10')))]),
DeclStatement(type=ArrayType(element_type=PrimitiveType(kind=<PrimitiveKind.CHAR: 'char'>)),
                                                   declarators=[VarInit(name='S',
                                                                        init=NullConstExpr())]),
AssertStatement(condition=BinaryOpExpr(left=BinaryOpExpr(left=VariableExpr(name='p'),
                                                                                              op='and',
right=UnaryOpExpr(op='not',
expr=VariableExpr(name='q'))),
                                                                            op='or',
right=BinaryOpExpr(left=VariableExpr(name='p'),
                                                                                               op='xor',
right=VariableExpr(name='q')))),
IfStatement(branches=[IfBranch(condition=BinaryOpExpr(left=BinaryOpExpr(left=VariableExpr(name='x'),
op='mod',
right=VariableExpr(name='y')),
                                                                                           op='=',
right=IntConstExpr(value=1,
base=10,
image='1')),
body=[AssignStatement(target=IndexExpr(array=VariableExpr(name='A'),
index=IntConstExpr(value=0,
base=10,
image='0')),
value=BinaryOpExpr(left=VariableExpr(name='x'),
op='+',
right=VariableExpr(name='y')))]),
IfBranch(condition=BinaryOpExpr(left=VariableExpr(name='x'),
                                                                                           op='<',
right=VariableExpr(name='y')),
body=[AssignStatement(target=IndexExpr(array=VariableExpr(name='A'),
index=IntConstExpr(value=0,
base=10,
image='0')),
value=BinaryOpExpr(left=VariableExpr(name='x'),
op='-',
right=VariableExpr(name='y')))])],
else_body=[AssignStatement(target=IndexExpr(array=VariableExpr(name='A'),
index=IntConstExpr(value=0,
base=10,
image='0')),
value=BinaryOpExpr(left=BinaryOpExpr(left=VariableExpr(name='x'),
op='**',
right=IntConstExpr(value=2,
base=10,
image='2')),
                                                                                               op='/',
right=VariableExpr(name='y')))]),
                                     WhileStatement(condition=BinaryOpExpr(left=VariableExpr(name='i'),
                                                                           op='<',
                                                                           right=IntConstExpr(value=3,
                                                                                              base=10,
                                                                                              image='3')),
body=[AssignStatement(target=IndexExpr(array=VariableExpr(name='A'),
index=VariableExpr(name='i')),
value=BinaryOpExpr(left=IndexExpr(array=VariableExpr(name='A'),
index=VariableExpr(name='i')),
                                                                                             op='+',
right=IntConstExpr(value=1,
base=10,
image='1'))),
                                                          AssignStatement(target=VariableExpr(name='i'),
value=BinaryOpExpr(left=VariableExpr(name='i'),
                                                                                             op='+',
right=IntConstExpr(value=1,
base=10,
image='1')))]),
                                     ForStatement(init=ForDecl(type=PrimitiveType(kind=<PrimitiveKind.INT:
                                       'int'>),
                                                               name='j'),
                                                  start=IntConstExpr(value=0,
                                                                     base=10,
                                                                     image='0'),
                                                  end=IntConstExpr(value=5,
                                                                   base=10,
                                                                   image='5'),
                                                  step=IntConstExpr(value=2,
                                                                    base=10,
                                                                    image='2'),
body=[AssignStatement(target=IndexExpr(array=VariableExpr(name='A'),
index=VariableExpr(name='j')),
                                                                        value=VariableExpr(name='j'))]),
                                     DoWhileStatement(body=[AssignStatement(target=VariableExpr(name='x'),
value=BinaryOpExpr(left=VariableExpr(name='x'),
                                                                                               op='-',
right=IntConstExpr(value=1,
base=10,
image='1')))],
                                                      condition=BinaryOpExpr(left=VariableExpr(name='x'),
                                                                             op='>',
                                                                             right=IntConstExpr(value=0,
                                                                                                base=10,
image='0'))),
IfStatement(branches=[IfBranch(condition=BinaryOpExpr(left=VariableExpr(name='S'),
                                                                                           op='=',
right=NullConstExpr()),
body=[AssignStatement(target=VariableExpr(name='S'),
value=StringConstExpr(value='ok',
sections=['ok']))])],
                                                 else_body=[AssignStatement(target=VariableExpr(name='S'),
value=StringConstExpr(value='bad',
sections=['bad']))]),
                                     ReturnStatement(value=IndexExpr(array=VariableExpr(name='A'),
                                                                     index=IntConstExpr(value=0,
                                                                                        base=10,
                                                                                        image='0')))])])
```

# Вывод
В ходе выполнения лабораторной работы были освоены принципы составления грамматик и проектирования
синтаксического дерева для языка программирования.