import math

def gauss(A, b):
    n = len(b)

    for k in range(n):
        maxRow = k
        for i in range(k + 1, n):
            if abs(A[i][k]) > abs(A[maxRow][k]):
                maxRow = i

        A[k], A[maxRow] = A[maxRow], A[k]
        b[k], b[maxRow] = b[maxRow], b[k]

        for i in range(k + 1, n):
            m = A[i][k] / A[k][k]
            for j in range(k, n):
                A[i][j] -= m * A[k][j]
            b[i] -= m * b[k]

    x = [0.0] * n
    for i in range(n - 1, -1, -1):
        s = 0.0
        for j in range(i + 1, n):
            s += A[i][j] * x[j]
        x[i] = (b[i] - s) / A[i][i]

    return x

# Вариант 8:
# {
#   2y - cos(x + 4) = 0
#   x + sin y = -0.4
# }

# -0.0585884, -0.348418

def f1(x1, x2): return 2 * x2 - math.cos(x1 + 4)
def f2(x1, x2): return x1 + math.sin(x2) + 0.4

def main():
    e = 0.01

    x01 = 0.1
    x02 = 0.3
    k = 0

    x1 = x01
    x2= x02

    while True:

        J = [
            [math.sin(x1 + 4), 2],
            [1, math.cos(x2)]
        ]

        F = [-f1(x1, x2), -f2(x1, x2)]

        y1, y2 = gauss(J, F)

        x1 = x1 + y1
        x2 = x2 + y2

        k += 1

        if max(abs(y1), abs(y2)) < e:
            break

    print(f"Начальное приближение: x1={x01} x2={x02}")
    print(f"x1 = {x1:.10f}")
    print(f"x2 = {x2:.10f}")
    print(f"Количество итераций: {k}")
    print( abs(abs(x1) - 0.0585884), abs(abs(x2) - 0.348418))

if __name__ == "__main__":
    main()
