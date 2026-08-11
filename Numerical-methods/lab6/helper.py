import math

def cbrt(x):
    return math.copysign(abs(x) ** (1 / 3), x)


def phi(c):
    return -0.1 * cbrt(0.025 * c) - 0.2 * cbrt(0.05 * c)


def F(c):
    return c - math.cos(phi(c))

def dF(c):
    if c == 0:
        raise ZeroDivisionError("Производная не определена при c = 0")

    p = phi(c)

    dphi = (
        -0.1 * 0.025 / (3 * cbrt(0.025 * c) ** 2)
        -0.2 * 0.05 / (3 * cbrt(0.05 * c) ** 2)
    )

    return 1 + math.sin(p) * dphi


def newton_method_c(c0=1, eps=1e-8, max_iter=100):
    c = c0

    for k in range(max_iter):
        Fc = F(c)

        if abs(Fc) < eps:
            return c, k

        dFc = dF(c)

        if abs(dFc) < 1e-14:
            raise ZeroDivisionError("метод Ньютона не применим")

        c -= Fc / dFc

    return c, max_iter


c, iters = newton_method_c(1)

print("c =", c)