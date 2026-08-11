import math

def f(x1, x2):
    return x1**4 + x2**4 + math.sin(0.1 * x1 + 0.2 * x2)

def df_dx1(x1, x2):
    return 4 * x1**3 + 0.1 * math.cos(0.1 * x1 + 0.2 * x2)

def df_dx2(x1, x2):
    return 4 * x2**3 + 0.2 * math.cos(0.1 * x1 + 0.2 * x2)

def df2_dx1dx1(x1, x2):
    return 12 * x1**2 - 0.01 * math.sin(0.1 * x1 + 0.2 * x2)

def df2_dx1dx2(x1, x2):
    return -0.02 * math.sin(0.1 * x1 + 0.2 * x2)

def df2_dx2dx2(x1, x2):
    return 12 * x2**2 - 0.04 * math.sin(0.1 * x1 + 0.2 * x2)

def find(x1, x2, e):

    k = 0

    while True:
        fx = f(x1, x2)
        fdx1 = df_dx1(x1, x2)
        fdx2 = df_dx2(x1, x2)

        if max(abs(fdx1), abs(fdx2)) < e:
            return x1, x2, k, fx

        f11 = df2_dx1dx1(x1, x2)
        f12 = df2_dx1dx2(x1, x2)
        f22 = df2_dx2dx2(x1, x2)

        num = fdx1**2 + fdx2**2
        den = f11 * fdx1**2 + 2 * f12 * fdx1 * fdx2 + f22 * fdx2**2

        if den == 0:
            t = 0.1
        else:
            t = num / den

        x1 = x1 - t * fdx1
        x2 = x2 - t * fdx2

        k += 1


def main():
    e = 0.001
    x10 = 0
    x20 = 0

    x1, x2, k, f = find(x10, x20, e)

    fa = -0.077009
    x1a = -0.291887
    x2a = -0.367754
    print("Аналитически:")
    print("Минимум:", fa)
    print("В точке:", (x1a, x2a))

    print("\nМетод наискорейшего спуска:")
    print("Минимум:", f)
    print("В точке:", (x1, x2))
    print("Количество итераций:", k)

if __name__ == "__main__":
    main()