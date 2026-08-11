import math

n = 10

def solve(a, b, c, d):
    
    n = len(b)

    if n < 2:
        raise ValueError("Small size")

    if len(a) != n - 1 or len(c) != n - 1 or len(d) != n:
        raise ValueError("Incorrect size")

    alpha = [0.0] * (n - 1)
    beta = [0.0] * (n - 1)
    x = [0.0] * n

    if b[0] == 0:
        raise ValueError("Incorrect b1, division by 0")

    alpha[0] = -c[0] / b[0]
    beta[0] = d[0] / b[0]
    
    for i in range(1, n - 1):
        den = b[i] + a[i-1] * alpha[i-1]

        if den == 0:
            raise ValueError("Division by 0")
        
        alpha[i] = -c[i] / den
        beta[i] = (d[i] - a[i-1] * beta[i-1]) / den
    

    den = b[n-1] + a[n-2] * alpha[n-2]
    if den == 0:
        raise ValueError("Division by 0")
    
    x[n-1] = (d[n-1] - a[n-2] * beta[n-2]) / den

    for i in range(n, 0, -1):
        x[i-2] = alpha[i-2] * x[i-1] + beta[i-2]

    return x


def getFunction(a, h, func):
    funcTable = []
    for i in range (0, n + 1):
        xi = a + h*i
        funcTable.append([xi, func(xi)])
    
    return funcTable


def find(funcTable, h):

    dm = []

    for i in range(1, n):
        dm.append((3 / h**2) * (funcTable[i + 1][1] - 2 * funcTable[i][1] + funcTable[i - 1][1]))

    am = [1 for i in range(n - 2)]   
    bm = [4 for i in range(n - 1)]    
    cm = [1 for i in range(n - 2)]  

    c = [0, 0] + solve(am, bm, cm, dm) + [0]

    b = [0]
    for i in range(1, n + 1):
        b.append(((funcTable[i][1] - funcTable[i - 1][1]) / h) - (h / 3) * (c[i + 1] + 2 * c[i]))

    d = [0]
    for i in range(1, n + 1):
        d.append((c[i + 1] - c[i]) / (3 * h))

    a = [0] + [funcTable[i - 1][1] for i in range(1,n + 1)]

    return a, b, c, d


def count(a, b, c, d, xi, x):
    dx = x - xi
    return a + b * dx + c * dx * dx + d * dx * dx * dx


def main():
    a = 0
    b = 1
    h = (b - a) / n
    func = math.exp
    funcTable = getFunction(a, h, func)
    a_coef, b_coef, c_coef, d_coef = find(funcTable, h)

    for i in range(n):
        x0 = funcTable[i][0]
        x1 = funcTable[i + 1][0]
        xm = (x0 + x1) / 2

        y0 = func(x0)
        ym = func(xm)

        s0 = count(a_coef[i + 1], b_coef[i + 1], c_coef[i + 1], d_coef[i + 1], x0, x0)
        sm = count(a_coef[i + 1], b_coef[i + 1], c_coef[i + 1], d_coef[i + 1], x0, xm)

        print(f"{x0:.2f} {y0:.6f} {s0:.6f} {abs(y0 - s0):.8f}")
        print(f"{xm:.2f} {ym:.6f} {sm:.6f} {abs(ym - sm):.8f}")

    x_last = funcTable[n][0]
    x_prev = funcTable[n - 1][0]
    y_last = funcTable[n][1]
    s_last = count(a_coef[n], b_coef[n], c_coef[n], d_coef[n], x_prev, x_last)
    print(f"{x_last:.2f} {y_last:.6f} {s_last:.6f} {abs(y_last - s_last):.8f}")

if __name__ == "__main__":
    main()