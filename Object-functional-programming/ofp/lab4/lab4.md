% Лабораторная работа № 4 «Case-классы и сопоставление с образцом в Scala»
% 27 мая 2026 г.
% Софья Григорьева, ИУ9-61Б

# Цель работы

Целью данной работы является приобретение навыков разработки case-классов на языке Scala
для представления абстрактных синтаксических деревьев.

# Индивидуальный вариант

Абстрактный синтаксис арифметических выражений:

Expr → Expr + Expr | Expr - Expr | Expr \* Expr | Expr / Expr | VARNAME
Написать функцию ratioPolynomns : Expr => Expr, которая преобразует выражение в полином
(если в нём нет операции деления) или в отношение двух полиномов (если операция деления есть).

# Реализация

```scala
abstract class Expr

case class Var(name: String) extends Expr
case class Add(a: Expr, b: Expr) extends Expr
case class Sub(a: Expr, b: Expr) extends Expr
case class Mul(a: Expr, b: Expr) extends Expr
case class Div(a: Expr, b: Expr) extends Expr

object Main {
    def ratioPolynomns(e: Expr): Expr = {
        def ratio(e: Expr): (Expr, Option[Expr]) =
            e match {
                case Var(name) => (Var(name), None)

                case Add(a, b) =>
                    (ratio(a), ratio(b)) match {
                        case ((pa, None), (pb, None)) =>
                            (Add(pa, pb), None)

                        case ((pa, Some(qa)), (pb, None)) =>
                            (Add(pa, Mul(pb, qa)), Some(qa))

                        case ((pa, None), (pb, Some(qb))) =>
                            (Add(Mul(pa, qb), pb), Some(qb))

                        case ((pa, Some(qa)), (pb, Some(qb))) =>
                            (Add(Mul(pa, qb), Mul(pb, qa)), Some(Mul(qa, qb)))
                    }

                case Sub(a, b) =>
                    (ratio(a), ratio(b)) match {
                        case ((pa, None), (pb, None)) =>
                            (Sub(pa, pb), None)

                        case ((pa, Some(qa)), (pb, None)) =>
                            (Sub(pa, Mul(pb, qa)), Some(qa))

                        case ((pa, None), (pb, Some(qb))) =>
                            (Sub(Mul(pa, qb), pb), Some(qb))

                        case ((pa, Some(qa)), (pb, Some(qb))) =>
                            (Sub(Mul(pa, qb), Mul(pb, qa)), Some(Mul(qa, qb)))
                    }

                case Mul(a, b) =>
                    (ratio(a), ratio(b)) match {
                        case ((pa, None), (pb, None)) =>
                            (Mul(pa, pb), None)

                        case ((pa, Some(qa)), (pb, None)) =>
                            (Mul(pa, pb), Some(qa))

                        case ((pa, None), (pb, Some(qb))) =>
                            (Mul(pa, pb), Some(qb))

                        case ((pa, Some(qa)), (pb, Some(qb))) =>
                            (Mul(pa, pb), Some(Mul(qa, qb)))
                    }

                case Div(a, b) =>
                    (ratio(a), ratio(b)) match {
                        case ((pa, None), (pb, None)) =>
                            (pa, Some(pb))

                        case ((pa, Some(qa)), (pb, None)) =>
                            (pa, Some(Mul(qa, pb)))

                        case ((pa, None), (pb, Some(qb))) =>
                            (Mul(pa, qb), Some(pb))

                        case ((pa, Some(qa)), (pb, Some(qb))) =>
                            (Mul(pa, qb), Some(Mul(qa, pb)))
                    }
            }

        ratio(e) match {
            case (p, None) => p
            case (p, Some(q)) => Div(p, q)
        }
    }

    def main(args: Array[String]): Unit = {
        val x = Var("x")
        val y = Var("y")
        val z = Var("z")
        val t = Var("t")

        // x * y + z
        val f1 = Add(Mul(x, y), z)
        println(ratioPolynomns(f1))

        // x / y + z
        val f2 = Add(Div(x, y), z)
        println(ratioPolynomns(f2))

        // x + y / y * z
        val f3 = Add(x, Mul(Div(y, y), z))
        println(ratioPolynomns(f3))

        // x / t + y / z
        val f4 = Add(Div(x, t), Div(y, z))
        println(ratioPolynomns(f4))
    }
}
```

# Тестирование

Результат запуска программы:

```
Add(Mul(Var(x),Var(y)),Var(z))
Div(Add(Var(x),Mul(Var(z),Var(y))),Var(y))
Div(Add(Mul(Var(x),Var(y)),Mul(Var(y),Var(z))),Var(y))
Div(Add(Mul(Var(x),Var(z)),Mul(Var(y),Var(t))),Mul(Var(t),Var(z)))
```

# Вывод

В ходе лабораторной работы были освоены case-классы Scala и сопоставление с образцом,
а также закреплены навыки работы с `case class`, `Option`, `Some`, `None` и конструкцией `match`.
