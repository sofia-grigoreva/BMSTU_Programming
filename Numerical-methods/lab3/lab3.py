import math

def midRect(f, a, b, n):
    h = (b - a) / n
    res = 0
    for i in range(1, n + 1): 
        x = a + (i - 0.5) * h
        res += f(x)
    return res * h

def trap(f, a, b, n):
    h = (b - a) / n
    res = (f(a) + f(b)) / 2
    for i in range(1, n):
        x = a + i * h
        res += f(x)
    return res * h

def simpson(f, a, b, n):
    h = (b - a) / n
    res = f(a) + f(b)
    for i in range(1, n):
        x = a + i * h
        if i % 2 == 0:
            res += 2 * f(x)
        else:
            res += 4 * f(x)
    return res * h / 3

def solve(name, meth, k, e, a, b, f):
    n = 2
    
    while True:
        I1 = meth(f, a, b, n)
        I2 = meth(f, a, b, n * 2)
        R = (I2 - I1) / (2**k - 1)
        I3 = I2 + R
        
        if abs(R) < e:
            print(f"{name:30} {n * 2:5d} {I2:15.8f} {R:15.8f} {I3:15.8f}")
            return
        
        n *= 2

def main():
    e = 0.001
    def f(x): return x*x + x*x*x 
    a, b = 0, 1 

    print(f"{'Метод':30} {'n':>5} {'I*':>15} {'R':>15} {'I* + R':>15}")
    solve("Метод средних прямоугольников", midRect, 2, e, a, b, f)
    solve("Метод трапеций", trap, 2, e, a, b, f)
    solve("Метод Симпсона", simpson, 4, e, a, b, f)

if __name__ == "__main__":
    main()