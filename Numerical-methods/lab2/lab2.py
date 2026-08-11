import math

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

    for i in range(n - 1, 0, -1):
        x[i-1] = alpha[i-1] * x[i] + beta[i-1]

    return x

def solveShooting(n, a, b, A, B, p, q, f):

    h = (b - a) / n 

    y0 = [0] * (n + 1) 
    y1 = [0] * (n + 1)
    
    y0[0] = A
    y0[1] = A + h * 3
    
    y1[0] = 0
    y1[1] = h * 3
    
    for i in range(1, n):
        x = a + i * h
        y0[i + 1] = (f(x) * h * h + (2 - q(x)* h * h) * y0[i] - ( 1 - p(x) * (h /2)) * y0[i - 1]) / (1 + p(x) * (h / 2))

    for i in range(1, n):
        x = a + i * h
        y1[i + 1] = ((2 - q(x) * h * h) * y1[i] - (1 - p(x) * (h/2)) * y1[i-1]) / (1 + p(x) * (h/2))
        
    y = [0] * (n + 1)

    for i in range(n + 1):
        y[i] = y0[i] + ((B - y0[n]) / y1[n]) * y1[i]

    return y
    

def solveRunning(n, a, b, A, B, p, q, f):
    h = (b - a) / n

    am = [0] * (n - 1)  
    bm = [0] * (n - 1)  
    cm = [0] * (n - 1)  
    dm = [0] * (n - 1)  

    for i in range(1, n):  
        x = a + i * h

        ai = 1 - p(x) * h / 2
        bi = -2 + q(x) * h * h
        ci = 1 + p(x) * h / 2
        di = f(x) * h * h

        k = i - 1  

        am[k] = ai
        bm[k] = bi
        cm[k] = ci
        dm[k] = di

    dm[0] -= am[0] * A
    dm[n - 2] -= cm[n - 2] * B
    am = am[:-1]
    cm = cm[:-1]

    solution = solve(am, bm, cm, dm)

    return [A] + solution + [B]

def main():
    def p(x): return 0
    def q(x): return 1
    def f(x): return 5 * math.sin(2 * x)
    def y(x): return math.cos(x) + 4 * math.sin(x) - (5 / 3) * math.sin(2 * x)

    a, b = 0, 1
    n = 10
    h = (b - a) / n 
    A = 1
    B = y(1)

    resRunning = solveRunning(n, a, b, A, B, p, q, f)
    resShooting = solveShooting(n, a, b, A, B, p, q, f)
    
    print(f"{'x':^11} {'y':^14} {'y1':^15} {'y2':^15}")
    
    for i in range(n + 1):
        x = a + h * i
        print(f"{x:3.4f} {y(x):15.15f} {resRunning[i]:15.15f} {resShooting[i]:15.15f}")

    print()
    print(f"{'|y - y1|':^18} {'|y - y2|':^12}")

    for i in range(n + 1):
        x = a + h * i
        print(f"{abs(y(x) - resRunning[i]):15.15f} {abs(y(x) - resShooting[i]):15.15f}")


if __name__ == "__main__":
    main()