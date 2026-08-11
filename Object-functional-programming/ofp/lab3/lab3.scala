class Vector[T <: Product](val value: T) {
  def +[S](other: Vector[T])(implicit ops: VectorOps[T, S]): Vector[T] = {
    new Vector(ops.add(value, other.value))
  }

  def smul[S](other: Vector[T])(implicit ops: VectorOps[T, S]): S = {
    ops.smul(value, other.value)
  }

  def vmul(other: Vector[T])(implicit ops: VmulOp[T]): Vector[T] = {
    new Vector(ops.vmul(value, other.value))
  }

  override def toString: String = value.toString
}

trait VectorOps[T, S] {
  def add(a: T, b: T): T
  def smul(a: T, b: T): S
}

trait VmulOp[T] {
  def vmul(a: T, b: T): T
}

object VectorOps {
  implicit def pair_ops[N](implicit num: Numeric[N]): VectorOps[(N, N), N] =
    new VectorOps[(N, N), N] {
      def add(a: (N, N), b: (N, N)): (N, N) =
        (
          num.plus(a._1, b._1),
          num.plus(a._2, b._2)
        )

      def smul(a: (N, N), b: (N, N)): N =
        num.plus(
          num.times(a._1, b._1),
          num.times(a._2, b._2)
        )
    }

  implicit def triple_ops[N](implicit num: Numeric[N]): VectorOps[(N, N, N), N] =
    new VectorOps[(N, N, N), N] {
      def add(a: (N, N, N), b: (N, N, N)): (N, N, N) =
        (
          num.plus(a._1, b._1),
          num.plus(a._2, b._2),
          num.plus(a._3, b._3)
        )

      def smul(a: (N, N, N), b: (N, N, N)): N =
        num.plus(
          num.plus(
            num.times(a._1, b._1),
            num.times(a._2, b._2)
          ),
          num.times(a._3, b._3)
        )
    }
}

object VmulOp {
  implicit def triple_vmul_ops[N](implicit num: Numeric[N]): VmulOp[(N, N, N)] =
    new VmulOp[(N, N, N)] {
      def vmul(a: (N, N, N), b: (N, N, N)): (N, N, N) =
        (
          num.minus(num.times(a._2, b._3), num.times(a._3, b._2)),
          num.minus(num.times(a._3, b._1), num.times(a._1, b._3)),
          num.minus(num.times(a._1, b._2), num.times(a._2, b._1))
        )
    }
}

object Main extends App {
  val v1 = new Vector((1, 2))
  val v2 = new Vector((3, 4))
  println(v1 + v2)
  println(v1.smul(v2))

  val v3 = new Vector((1.0, 2.0, 3.0))
  val v4 = new Vector((4.0, 5.0, 6.0))
  println(v3 + v4)
  println(v3.smul(v4))
  println(v3.vmul(v4))
}