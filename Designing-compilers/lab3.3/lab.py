from __future__ import annotations

import abc
import enum
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
class NullType(TypeNode):
    pass


INT_TYPE = PrimitiveType(PrimitiveKind.INT)
CHAR_TYPE = PrimitiveType(PrimitiveKind.CHAR)
BOOL_TYPE = PrimitiveType(PrimitiveKind.BOOL)
NULL_TYPE = NullType()


def type_to_str(type_: TypeNode | None) -> str:
    if type_ is None:
        return 'void'
    if isinstance(type_, PrimitiveType):
        return type_.kind.value
    if isinstance(type_, ArrayType):
        return f'{type_to_str(type_.element_type)} array'
    if isinstance(type_, NullType):
        return 'NULL'
    return str(type_)


def is_int_or_char(type_: TypeNode) -> bool:
    return type_ in (INT_TYPE, CHAR_TYPE)


def is_assignable(dst: TypeNode, src: TypeNode) -> bool:
    if dst == INT_TYPE:
        return src in (INT_TYPE, CHAR_TYPE)
    if dst == CHAR_TYPE:
        return src == CHAR_TYPE
    if dst == BOOL_TYPE:
        return src == BOOL_TYPE
    if isinstance(dst, ArrayType):
        return src == NULL_TYPE or src == dst
    return False


@dataclass
class VariableSymbol:
    name: str
    type: TypeNode
    coord: pe.Position


@dataclass
class FunctionSymbol:
    name: str
    return_type: TypeNode | None
    param_types: list[TypeNode]
    coord: pe.Position


@dataclass
class Scope:
    parent: Scope | None = None
    variables: dict[str, VariableSymbol] | None = None

    def __post_init__(self):
        if self.variables is None:
            self.variables = {}

    def define(self, symbol: VariableSymbol) -> None:
        assert self.variables is not None
        self.variables[symbol.name] = symbol

    def lookup(self, name: str) -> VariableSymbol | None:
        assert self.variables is not None
        if name in self.variables:
            return self.variables[name]
        if self.parent is not None:
            return self.parent.lookup(name)
        return None


@dataclass
class SemanticContext:
    functions: dict[str, FunctionSymbol]


class SemanticError(pe.Error):
    def __init__(self, pos: pe.Position, message: str):
        self.pos = pos
        self._message = message

    @property
    def message(self) -> str:
        return self._message


@dataclass
class Program:
    functions: list['FunctionDef']
    def check(self) -> None:
        functions: dict[str, FunctionSymbol] = {}

        for function in self.functions:
            functions[function.name] = FunctionSymbol(
                name=function.name,
                return_type=function.return_type,
                param_types=[param.type for param in function.params],
                coord=function.name_coord,
            )

        context = SemanticContext(functions=functions)
        for function in self.functions:
            function.check(context)


@dataclass
class FunctionDef:
    return_type: TypeNode | None
    name: str
    name_coord: pe.Position
    params: list['Param']
    body: list['Statement']
    coord: pe.Fragment
    @pe.ExAction
    def create(attrs, coords, res_coord):
        ret_type, name, params, body = attrs
        return FunctionDef(
            return_type=None if ret_type is ABSENT else ret_type,
            name=name,
            name_coord=coords[2].start,
            params=params,
            body=body,
            coord=res_coord,
        )

    def check(self, context: SemanticContext) -> None:
        scope = Scope()

        for param in self.params:
            if param.init is not None:
                init_type = param.init.check(scope, context)
                if not is_assignable(param.type, init_type):
                    raise SemanticError(
                        param.name_coord,
                        f'Несовместимые типы присваивания: {type_to_str(param.type)} := {type_to_str(init_type)}',
                    )
            scope.define(VariableSymbol(param.name, param.type, param.name_coord))

        check_statement_sequence(self.body, scope, context)


@dataclass
class Param:
    type: TypeNode
    name: str
    name_coord: pe.Position
    init: 'Expr | None' = None
    coord: pe.Fragment | None = None

    @pe.ExAction
    def create(attrs, coords, res_coord):
        typ, name, init = attrs
        return Param(typ, name, coords[1].start, None if init is ABSENT else init, res_coord)


class Statement(abc.ABC):
    coord: pe.Fragment

    @abc.abstractmethod
    def check(self, scope: Scope, context: SemanticContext) -> None:
        pass


@dataclass
class VarInit:
    name: str
    name_coord: pe.Position
    init: 'Expr | None' = None
    coord: pe.Fragment | None = None

    @pe.ExAction
    def create(attrs, coords, res_coord):
        name, init = attrs
        return VarInit(name, coords[0].start, None if init is ABSENT else init, res_coord)


@dataclass
class DeclStatement(Statement):
    type: TypeNode
    declarators: list[VarInit]
    coord: pe.Fragment

    @pe.ExAction
    def create(attrs, coords, res_coord):
        typ, declarators = attrs
        return DeclStatement(typ, declarators, res_coord)

    def check(self, scope: Scope, context: SemanticContext) -> None:
        for declarator in self.declarators:
            if declarator.init is not None:
                init_type = declarator.init.check(scope, context)
                if not is_assignable(self.type, init_type):
                    raise SemanticError(
                        declarator.name_coord,
                        f'Несовместимые типы присваивания: {type_to_str(self.type)} := {type_to_str(init_type)}',
                    )
            scope.define(VariableSymbol(declarator.name, self.type, declarator.name_coord))


@dataclass
class AssignStatement(Statement):
    target: 'Expr'
    op_coord: pe.Position
    value: 'Expr'
    coord: pe.Fragment

    @pe.ExAction
    def create(attrs, coords, res_coord):
        target, value = attrs
        return AssignStatement(target, coords[1].start, value, res_coord)

    def check(self, scope: Scope, context: SemanticContext) -> None:
        target_type = self.target.check(scope, context)
        value_type = self.value.check(scope, context)
        if not is_assignable(target_type, value_type):
            raise SemanticError(
                self.op_coord,
                f'Несовместимые типы присваивания: {type_to_str(target_type)} := {type_to_str(value_type)}',
            )


@dataclass
class CallStatement(Statement):
    call: 'CallExpr'
    coord: pe.Fragment

    @pe.ExAction
    def create(attrs, coords, res_coord):
        name, args = attrs
        return CallStatement(CallExpr(name, coords[0].start, args, res_coord), res_coord)

    def check(self, scope: Scope, context: SemanticContext) -> None:
        self.call.check_call(scope, context, require_value=False)


@dataclass
class IfBranch:
    condition: 'Expr'
    condition_coord: pe.Fragment
    body: list['Statement']
    coord: pe.Fragment | None = None
    @pe.ExAction
    def create_elsif(attrs, coords, res_coord):
        cond, body = attrs
        return IfBranch(cond, coords[1], body, res_coord)


@dataclass
class IfStatement(Statement):
    branches: list[IfBranch]
    else_body: list['Statement'] | None
    coord: pe.Fragment
    @pe.ExAction
    def create(attrs, coords, res_coord):
        cond, then_body, elifs, else_body = attrs
        first = IfBranch(cond, coords[1], then_body)
        return IfStatement([first] + elifs, None if else_body is ABSENT else else_body, res_coord)

    def check(self, scope: Scope, context: SemanticContext) -> None:
        for branch in self.branches:
            branch.condition.check(scope, context)
            branch_scope = Scope(parent=scope)
            check_statement_sequence(branch.body, branch_scope, context)

        if self.else_body is not None:
            else_scope = Scope(parent=scope)
            check_statement_sequence(self.else_body, else_scope, context)


@dataclass
class WhileStatement(Statement):
    condition: 'Expr'
    condition_coord: pe.Fragment
    body: list['Statement']
    coord: pe.Fragment
    @pe.ExAction
    def create(attrs, coords, res_coord):
        cond, body = attrs
        return WhileStatement(cond, coords[1], body, res_coord)

    def check(self, scope: Scope, context: SemanticContext) -> None:
        self.condition.check(scope, context)
        body_scope = Scope(parent=scope)
        check_statement_sequence(self.body, body_scope, context)


class ForInit(abc.ABC):
    coord: pe.Fragment
    name_coord: pe.Position
    name: str


@dataclass
class ForVar(ForInit):
    name: str
    name_coord: pe.Position
    coord: pe.Fragment

    @pe.ExAction
    def create(attrs, coords, res_coord):
        name, = attrs
        return ForVar(name, coords[0].start, res_coord)


@dataclass
class ForDecl(ForInit):
    type: TypeNode
    name: str
    name_coord: pe.Position
    coord: pe.Fragment

    @pe.ExAction
    def create(attrs, coords, res_coord):
        typ, name = attrs
        return ForDecl(typ, name, coords[1].start, res_coord)


@dataclass
class ForStatement(Statement):
    init: ForInit
    start: 'Expr'
    start_coord: pe.Fragment
    end: 'Expr'
    end_coord: pe.Fragment
    step: 'Expr | None'
    step_coord: pe.Fragment | None
    body: list['Statement']
    coord: pe.Fragment
    @pe.ExAction
    def create(attrs, coords, res_coord):
        init, start, end, step, body = attrs
        return ForStatement(
            init=init,
            start=start,
            start_coord=coords[2],
            end=end,
            end_coord=coords[4],
            step=None if step is ABSENT else step,
            step_coord=None if step is ABSENT else coords[5],
            body=body,
            coord=res_coord,
        )

    def check(self, scope: Scope, context: SemanticContext) -> None:
        body_scope = Scope(parent=scope)

        if isinstance(self.init, ForVar):
            symbol = scope.lookup(self.init.name)
            if symbol is None:
                raise SemanticError(self.init.name_coord, f'Переменная {self.init.name} не определена')
            loop_type = symbol.type
        else:
            loop_type = self.init.type
            body_scope.define(VariableSymbol(self.init.name, loop_type, self.init.name_coord))

        start_type = self.start.check(scope, context)
        if not is_assignable(loop_type, start_type):
            raise SemanticError(
                self.start_coord.start,
                f'Несовместимые типы присваивания: {type_to_str(loop_type)} := {type_to_str(start_type)}',
            )

        end_type = self.end.check(scope, context)
        if not is_assignable(loop_type, end_type):
            raise SemanticError(
                self.end_coord.start,
                f'Несовместимые типы присваивания: {type_to_str(loop_type)} := {type_to_str(end_type)}',
            )

        if self.step is not None:
            self.step.check(scope, context)

        check_statement_sequence(self.body, body_scope, context)


@dataclass
class DoWhileStatement(Statement):
    body: list['Statement']
    condition: 'Expr'
    condition_coord: pe.Fragment
    coord: pe.Fragment
    @pe.ExAction
    def create(attrs, coords, res_coord):
        body, cond = attrs
        return DoWhileStatement(body, cond, coords[3], res_coord)

    def check(self, scope: Scope, context: SemanticContext) -> None:
        body_scope = Scope(parent=scope)
        check_statement_sequence(self.body, body_scope, context)
        self.condition.check(scope, context)


@dataclass
class ReturnStatement(Statement):
    value: 'Expr | None'
    op_coord: pe.Position
    coord: pe.Fragment

    @pe.ExAction
    def create_empty(attrs, coords, res_coord):
        return ReturnStatement(None, coords[0].start, res_coord)

    @pe.ExAction
    def create_value(attrs, coords, res_coord):
        value, = attrs
        return ReturnStatement(value, coords[0].start, res_coord)

    def check(self, scope: Scope, context: SemanticContext) -> None:
        if self.value is not None:
            self.value.check(scope, context)


@dataclass
class AssertStatement(Statement):
    condition: 'Expr'
    op_coord: pe.Position
    coord: pe.Fragment

    @pe.ExAction
    def create(attrs, coords, res_coord):
        condition, = attrs
        return AssertStatement(condition, coords[0].start, res_coord)

    def check(self, scope: Scope, context: SemanticContext) -> None:
        self.condition.check(scope, context)


class Expr(abc.ABC):
    coord: pe.Fragment

    @abc.abstractmethod
    def check(self, scope: Scope, context: SemanticContext) -> TypeNode:
        pass


@dataclass
class VariableExpr(Expr):
    name: str
    name_coord: pe.Position
    coord: pe.Fragment

    @pe.ExAction
    def create(attrs, coords, res_coord):
        name, = attrs
        return VariableExpr(name, coords[0].start, res_coord)

    def check(self, scope: Scope, context: SemanticContext) -> TypeNode:
        symbol = scope.lookup(self.name)
        if symbol is None:
            raise SemanticError(self.name_coord, f'Переменная {self.name} не определена')
        return symbol.type


@dataclass
class IntConstExpr(Expr):
    value: int
    base: int
    image: str
    coord: pe.Fragment | None = None

    @pe.ExAction
    def create(attrs, coords, res_coord):
        const, = attrs
        const.coord = res_coord
        return const

    def check(self, scope: Scope, context: SemanticContext) -> TypeNode:
        return INT_TYPE


@dataclass
class CharConstExpr(Expr):
    value: str
    image: str
    coord: pe.Fragment | None = None

    @pe.ExAction
    def create(attrs, coords, res_coord):
        const, = attrs
        const.coord = res_coord
        return const

    def check(self, scope: Scope, context: SemanticContext) -> TypeNode:
        return CHAR_TYPE


@dataclass
class StringConstExpr(Expr):
    value: str
    sections: list[str]
    coord: pe.Fragment

    @pe.ExAction
    def create(attrs, coords, res_coord):
        sections, = attrs
        return StringConstExpr(''.join(sections), sections, res_coord)

    def check(self, scope: Scope, context: SemanticContext) -> TypeNode:
        return ArrayType(CHAR_TYPE)


@dataclass
class BoolConstExpr(Expr):
    value: bool
    coord: pe.Fragment | None = None

    @staticmethod
    def create(value: bool):
        @pe.ExAction
        def action(attrs, coords, res_coord):
            return BoolConstExpr(value, res_coord)
        return action

    def check(self, scope: Scope, context: SemanticContext) -> TypeNode:
        return BOOL_TYPE


@dataclass
class NullConstExpr(Expr):
    coord: pe.Fragment | None = None

    @pe.ExAction
    def create(attrs, coords, res_coord):
        return NullConstExpr(res_coord)

    def check(self, scope: Scope, context: SemanticContext) -> TypeNode:
        return NULL_TYPE



def check_builtin_call(
    function: str,
    function_coord: pe.Position,
    args: list['Expr'],
    scope: Scope,
    context: SemanticContext,
) -> TypeNode | None:
    if function != 'Length':
        return None

    if len(args) != 1:
        raise SemanticError(
            function_coord,
            f'Неверное количество аргументов функции Length: ожидалось 1, получено {len(args)}',
        )

    arg_type = args[0].check(scope, context)
    if not isinstance(arg_type, ArrayType):
        raise SemanticError(
            args[0].coord.start,
            f'Неверный тип аргумента функции Length: ожидался массив, получен {type_to_str(arg_type)}',
        )

    return INT_TYPE


@dataclass
class CallExpr(Expr):
    function: str
    function_coord: pe.Position
    args: list['Expr']
    coord: pe.Fragment

    @pe.ExAction
    def create(attrs, coords, res_coord):
        name, args = attrs
        return CallExpr(name, coords[0].start, args, res_coord)

    def check_call(self, scope: Scope, context: SemanticContext, require_value: bool) -> TypeNode | None:
        builtin_type = check_builtin_call(
            self.function,
            self.function_coord,
            self.args,
            scope,
            context
        )
        if builtin_type is not None:
            return builtin_type

        symbol = context.functions.get(self.function)
        if symbol is None:
            raise SemanticError(self.function_coord, f'Функция {self.function} не определена')

        if len(self.args) != len(symbol.param_types):
            raise SemanticError(
                self.function_coord,
                f'Неверное количество аргументов функции {self.function}: ожидалось {len(symbol.param_types)}, получено {len(self.args)}',
            )

        for i, (arg, expected_type) in enumerate(zip(self.args, symbol.param_types), start=1):
            actual_type = arg.check(scope, context)
            if actual_type != expected_type:
                raise SemanticError(
                    arg.coord.start,
                    f'Неверный тип аргумента {i} функции {self.function}: ожидался {type_to_str(expected_type)}, получен {type_to_str(actual_type)}',
                )

        if require_value and symbol.return_type is None:
            raise SemanticError(self.function_coord, f'Функция {self.function} не возвращает значение')

        return symbol.return_type

    def check(self, scope: Scope, context: SemanticContext) -> TypeNode:
        result = self.check_call(scope, context, require_value=True)
        assert result is not None
        return result


@dataclass
class NewExpr(Expr):
    element_type: TypeNode
    size: 'Expr'
    op_coord: pe.Position
    coord: pe.Fragment

    @pe.ExAction
    def create(attrs, coords, res_coord):
        typ, size = attrs
        return NewExpr(typ, size, coords[0].start, res_coord)

    def check(self, scope: Scope, context: SemanticContext) -> TypeNode:
        self.size.check(scope, context)
        return ArrayType(self.element_type)


@dataclass
class IndexExpr(Expr):
    array: 'Expr'
    index: 'Expr'
    op_coord: pe.Position
    coord: pe.Fragment

    @pe.ExAction
    def create(attrs, coords, res_coord):
        array, index = attrs
        return IndexExpr(array, index, coords[1].start, res_coord)

    def check(self, scope: Scope, context: SemanticContext) -> TypeNode:
        array_type = self.array.check(scope, context)
        index_type = self.index.check(scope, context)
        if not isinstance(array_type, ArrayType):
            raise SemanticError(self.op_coord, f'Недопустимый тип операнда: индексация {type_to_str(array_type)}')
        if index_type not in (INT_TYPE, CHAR_TYPE):
            raise SemanticError(
                self.op_coord,
                f'Недопустимые типы операндов: {type_to_str(array_type)} индекс {type_to_str(index_type)}',
            )
        return array_type.element_type


@dataclass
class UnaryOpExpr(Expr):
    op: str
    op_coord: pe.Position
    expr: 'Expr'
    coord: pe.Fragment

    @staticmethod
    def create(op: str):
        @pe.ExAction
        def action(attrs, coords, res_coord):
            expr, = attrs
            return UnaryOpExpr(op, coords[0].start, expr, res_coord)
        return action

    def check(self, scope: Scope, context: SemanticContext) -> TypeNode:
        expr_type = self.expr.check(scope, context)
        if self.op == '-':
            if expr_type in (INT_TYPE, CHAR_TYPE):
                return INT_TYPE
        elif self.op == 'not':
            if expr_type == BOOL_TYPE:
                return BOOL_TYPE
        else:
            raise AssertionError(f'Unknown unary operator: {self.op}')

        raise SemanticError(self.op_coord, f'Недопустимый тип операнда: {self.op} {type_to_str(expr_type)}')


@dataclass
class BinaryOpExpr(Expr):
    left: 'Expr'
    op: str
    op_coord: pe.Position
    right: 'Expr'
    coord: pe.Fragment

    @staticmethod
    def create_named(op: str):
        @pe.ExAction
        def action(attrs, coords, res_coord):
            left, right = attrs
            return BinaryOpExpr(left, op, coords[1].start, right, res_coord)
        return action

    @pe.ExAction
    def create_with_op(attrs, coords, res_coord):
        left, op, right = attrs
        return BinaryOpExpr(left, op, coords[1].start, right, res_coord)

    def check(self, scope: Scope, context: SemanticContext) -> TypeNode:
        left_type = self.left.check(scope, context)
        right_type = self.right.check(scope, context)
        result_type = self.infer_type(left_type, right_type)
        if result_type is None:
            raise SemanticError(
                self.op_coord,
                f'Недопустимые типы операндов: {type_to_str(left_type)} {self.op} {type_to_str(right_type)}',
            )
        return result_type

    def infer_type(self, left_type: TypeNode, right_type: TypeNode) -> TypeNode | None:
        if self.op == '+':
            if left_type == INT_TYPE and right_type == INT_TYPE:
                return INT_TYPE
            if left_type == INT_TYPE and right_type == CHAR_TYPE:
                return CHAR_TYPE
            if left_type == CHAR_TYPE and right_type == INT_TYPE:
                return CHAR_TYPE
            return None

        if self.op == '-':
            if left_type == INT_TYPE and right_type == INT_TYPE:
                return INT_TYPE
            if left_type == CHAR_TYPE and right_type == CHAR_TYPE:
                return INT_TYPE
            if left_type == CHAR_TYPE and right_type == INT_TYPE:
                return CHAR_TYPE
            return None

        if self.op in ('**', '*', '/', 'mod'):
            if left_type == INT_TYPE and right_type == INT_TYPE:
                return INT_TYPE
            return None

        if self.op in ('<', '>', '<=', '>='):
            if is_int_or_char(left_type) and is_int_or_char(right_type):
                return BOOL_TYPE
            return None

        if self.op in ('=', '<>'):
            if is_int_or_char(left_type) and is_int_or_char(right_type):
                return BOOL_TYPE
            if left_type == BOOL_TYPE and right_type == BOOL_TYPE:
                return BOOL_TYPE
            if isinstance(left_type, ArrayType) and isinstance(right_type, ArrayType) and left_type == right_type:
                return BOOL_TYPE
            if isinstance(left_type, ArrayType) and right_type == NULL_TYPE:
                return BOOL_TYPE
            if left_type == NULL_TYPE and isinstance(right_type, ArrayType):
                return BOOL_TYPE
            return None

        if self.op in ('and', 'or', 'xor'):
            if left_type == BOOL_TYPE and right_type == BOOL_TYPE:
                return BOOL_TYPE
            return None

        raise AssertionError(f'Unknown binary operator: {self.op}')


def check_statement_sequence(statements: list[Statement], scope: Scope, context: SemanticContext) -> None:
    for statement in statements:
        statement.check(scope, context)


ABSENT = object()

CONTROL_CODES = {
    'NUL': 0, 'SOH': 1, 'STX': 2, 'ETX': 3, 'EOT': 4, 'ENQ': 5, 'ACK': 6, 'BEL': 7,
    'BS': 8, 'TAB': 9, 'LF': 10, 'VT': 11, 'FF': 12, 'CR': 13, 'SO': 14, 'SI': 15,
    'DLE': 16, 'DC1': 17, 'DC2': 18, 'DC3': 19, 'DC4': 20, 'NAK': 21, 'SYN': 22,
    'ETB': 23, 'CAN': 24, 'EM': 25, 'SUB': 26, 'ESC': 27, 'FS': 28, 'GS': 29,
    'RS': 30, 'US': 31,
}

CONTROL_ALT_NAMES = '|'.join(sorted(CONTROL_CODES, key=len, reverse=True))
HEX_RE = re.compile(r'^\{([0-9A-Fa-f]+)\}$')


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


def decode_control_name(name: str) -> str:
    if name.startswith('{'):
        match = HEX_RE.match(name)
        assert match is not None
        return chr(int(match.group(1), 16))
    return chr(CONTROL_CODES[name])


def parse_char_quoted(image: str) -> CharConstExpr:
    inner = image[1:-1]
    value = "'" if inner == "''" else inner
    return CharConstExpr(value=value, image=image)


def parse_char_control(image: str) -> CharConstExpr:
    return CharConstExpr(value=decode_control_name(image[1:]), image=image)


def parse_string_text(image: str) -> str:
    return image[1:-1]


def parse_string_ctrl(image: str) -> str:
    return decode_control_name(image[1:])


IDENT = pe.Terminal('IDENT', r'[A-Za-zА-Яа-яЁё][A-Za-zА-Яа-яЁё0-9_]*', str)

INT_CONST = pe.Terminal(
    'INT_CONST',
    r'(?:\{[0-9]+\}[0-9A-Za-z]+|[0-9]+)',
    parse_int_literal,
    priority=7,
)

CHAR_QUOTED = pe.Terminal('CHAR_QUOTED', r"'(?:[^'\r\n]|'')'", parse_char_quoted, priority=7)
CHAR_CTRL = pe.Terminal('CHAR_CTRL', rf'#(?:{CONTROL_ALT_NAMES}|\{{[0-9A-Fa-f]+\}})', parse_char_control, priority=7)
STRING_TEXT = pe.Terminal('STRING_TEXT', r'"[^"\r\n]*"', parse_string_text, priority=7)
STRING_QUOT = pe.Terminal('$QUOT', r'\$QUOT', lambda _: '"', priority=10)
STRING_CTRL = pe.Terminal('STRING_CTRL', rf'\$(?:{CONTROL_ALT_NAMES}|\{{[0-9A-Fa-f]+\}})', parse_string_ctrl, priority=7)


def kw(image: str) -> pe.Terminal:
    return pe.Terminal(image, re.escape(image), lambda _: None, priority=10)


(
    KW_DEFINE, KW_INT, KW_CHAR, KW_BOOL, KW_ARRAY, KW_IF, KW_ELSIF, KW_ELSE,
    KW_THEN, KW_WHILE, KW_DO, KW_TO, KW_STEP, KW_RETURN, KW_ASSERT, KW_NEW,
    KW_MOD, KW_AND, KW_OR, KW_XOR, KW_NOT, KW_NULL, KW_T, KW_F, KW_END,
) = map(
    kw,
    'define int char bool array if elsif else then while do to step return assert new mod and or xor not NULL T F end'.split(),
)

(
    NProgram, NFuncDefs, NFuncDef, NOptType, NType, NBaseType, NParamListOpt,
    NParamList, NParam, NOptInit, NStmtListOpt, NStmtList, NStmt, NDeclItems,
    NDeclItem, NElseIfList, NElseIf, NElseOpt, NForInit, NStepOpt, NExpr,
    NOrExpr, NAndExpr, NCmpExpr, NAddExpr, NMulExpr, NPowExpr, NUnaryExpr,
    NPostfixExpr, NPrimaryExpr, NArgListOpt, NArgList, NConst, NStringConst,
    NStringSections, NStringSection, NCmpOp, NAddOp, NMulOp,
) = map(
    pe.NonTerminal,
    '''Program FuncDefs FuncDef OptType Type BaseType ParamListOpt ParamList Param OptInit
       StmtListOpt StmtList Stmt DeclItems DeclItem ElseIfList ElseIf ElseOpt ForInit StepOpt
       Expr OrExpr AndExpr CmpExpr AddExpr MulExpr PowExpr UnaryExpr PostfixExpr PrimaryExpr
       ArgListOpt ArgList Const StringConst StringSections StringSection CmpOp AddOp MulOp'''.split(),
)

NProgram |= NFuncDefs, Program

NFuncDefs |= NFuncDef, lambda fd: [fd]
NFuncDefs |= NFuncDefs, NFuncDef, lambda fds, fd: fds + [fd]

NOptType |= lambda: ABSENT
NOptType |= NType

NFuncDef |= KW_DEFINE, NOptType, IDENT, '(', NParamListOpt, ')', NStmtListOpt, KW_END, FunctionDef.create

NBaseType |= KW_INT, lambda: INT_TYPE
NBaseType |= KW_CHAR, lambda: CHAR_TYPE
NBaseType |= KW_BOOL, lambda: BOOL_TYPE

NType |= NBaseType
NType |= NType, KW_ARRAY, ArrayType

NParamListOpt |= lambda: []
NParamListOpt |= NParamList
NParamList |= NParam, lambda p: [p]
NParamList |= NParamList, ',', NParam, lambda ps, p: ps + [p]

NOptInit |= lambda: ABSENT
NOptInit |= ':=', NExpr, lambda expr: expr
NParam |= NType, IDENT, NOptInit, Param.create

NStmtListOpt |= lambda: []
NStmtListOpt |= NStmtList
NStmtList |= NStmt, lambda s: [s]
NStmtList |= NStmtList, ';', NStmt, lambda ss, s: ss + [s]

NDeclItems |= NDeclItem, lambda d: [d]
NDeclItems |= NDeclItems, ',', NDeclItem, lambda ds, d: ds + [d]
NDeclItem |= IDENT, NOptInit, VarInit.create

NElseIfList |= lambda: []
NElseIfList |= NElseIfList, NElseIf, lambda xs, x: xs + [x]
NElseIf |= KW_ELSIF, NExpr, KW_THEN, NStmtListOpt, IfBranch.create_elsif

NElseOpt |= lambda: ABSENT
NElseOpt |= KW_ELSE, NStmtListOpt, lambda body: body

NForInit |= IDENT, ForVar.create
NForInit |= NType, IDENT, ForDecl.create

NStepOpt |= lambda: ABSENT
NStepOpt |= KW_STEP, NExpr, lambda expr: expr

NStmt |= NType, NDeclItems, DeclStatement.create
NStmt |= NExpr, ':=', NExpr, AssignStatement.create
NStmt |= IDENT, '(', NArgListOpt, ')', CallStatement.create
NStmt |= KW_IF, NExpr, KW_THEN, NStmtListOpt, NElseIfList, NElseOpt, KW_END, IfStatement.create
NStmt |= KW_WHILE, NExpr, KW_DO, NStmtListOpt, KW_END, WhileStatement.create
NStmt |= NForInit, ':=', NExpr, KW_TO, NExpr, NStepOpt, KW_DO, NStmtListOpt, KW_END, ForStatement.create
NStmt |= KW_DO, NStmtListOpt, KW_WHILE, NExpr, DoWhileStatement.create
NStmt |= KW_RETURN, ReturnStatement.create_empty
NStmt |= KW_RETURN, NExpr, ReturnStatement.create_value
NStmt |= KW_ASSERT, NExpr, AssertStatement.create

NExpr |= NOrExpr

NOrExpr |= NAndExpr
NOrExpr |= NOrExpr, KW_OR, NAndExpr, BinaryOpExpr.create_named('or')
NOrExpr |= NOrExpr, KW_XOR, NAndExpr, BinaryOpExpr.create_named('xor')

NAndExpr |= NCmpExpr
NAndExpr |= NAndExpr, KW_AND, NCmpExpr, BinaryOpExpr.create_named('and')

NCmpExpr |= NAddExpr
NCmpExpr |= NCmpExpr, NCmpOp, NAddExpr, BinaryOpExpr.create_with_op

for _op in ('=', '<>', '<', '>', '<=', '>='):
    NCmpOp |= _op, (lambda op=_op: op)

NAddExpr |= NMulExpr
NAddExpr |= NAddExpr, NAddOp, NMulExpr, BinaryOpExpr.create_with_op
NAddOp |= '+', lambda: '+'
NAddOp |= '-', lambda: '-'

NMulExpr |= NPowExpr
NMulExpr |= NMulExpr, NMulOp, NPowExpr, BinaryOpExpr.create_with_op
NMulOp |= '*', lambda: '*'
NMulOp |= '/', lambda: '/'
NMulOp |= KW_MOD, lambda: 'mod'

NPowExpr |= NUnaryExpr
NPowExpr |= NUnaryExpr, '**', NPowExpr, BinaryOpExpr.create_named('**')

NUnaryExpr |= NPostfixExpr
NUnaryExpr |= '-', NUnaryExpr, UnaryOpExpr.create('-')
NUnaryExpr |= KW_NOT, NUnaryExpr, UnaryOpExpr.create('not')

NPostfixExpr |= NPrimaryExpr
NPostfixExpr |= NPostfixExpr, '[', NExpr, ']', IndexExpr.create

NPrimaryExpr |= IDENT, VariableExpr.create
NPrimaryExpr |= IDENT, '(', NArgListOpt, ')', CallExpr.create
NPrimaryExpr |= KW_NEW, NType, '[', NExpr, ']', NewExpr.create
NPrimaryExpr |= NConst
NPrimaryExpr |= '(', NExpr, ')'

NArgListOpt |= lambda: []
NArgListOpt |= NArgList
NArgList |= NExpr, lambda e: [e]
NArgList |= NArgList, ',', NExpr, lambda es, e: es + [e]

NConst |= INT_CONST, IntConstExpr.create
NConst |= CHAR_QUOTED, CharConstExpr.create
NConst |= CHAR_CTRL, CharConstExpr.create
NConst |= NStringConst
NConst |= KW_T, BoolConstExpr.create(True)
NConst |= KW_F, BoolConstExpr.create(False)
NConst |= KW_NULL, NullConstExpr.create

NStringConst |= NStringSections, StringConstExpr.create
NStringSections |= NStringSection, lambda s: [s]
NStringSections |= NStringSections, NStringSection, lambda ss, s: ss + [s]
NStringSection |= STRING_TEXT
NStringSection |= STRING_QUOT
NStringSection |= STRING_CTRL

parser = pe.Parser(NProgram, method=pe.EARLEY)
parser.add_skipped_domain(r'[ \t\r\n]+')
parser.add_skipped_domain(r'(?m)^\*[^\n]*(?:\n|$)')
parser.add_skipped_domain(r'\*\*\*[^\n]*(?:\n|$)')


def main() -> None:
    if len(sys.argv) == 1:
        print('Usage: python l1_semantic_lab_2_2.py <file1> [file2 ...]')
        raise SystemExit(0)

    for filename in sys.argv[1:]:
        try:
            with open(filename, 'r', encoding='utf-8') as f:
                tree = parser.parse(f.read())
            tree.check()
            print('Программа корректна')
        except pe.Error as e:
            print(f'Ошибка {e.pos}: {e.message}')
        except Exception as e:
            print(f'Ошибка: {e}')


if __name__ == '__main__':
    main()