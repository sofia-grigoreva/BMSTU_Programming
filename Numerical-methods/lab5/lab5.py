import math
import numpy as np

x = np.array([1, 1.5, 2, 2.5, 3, 3.5, 4, 4.5, 5], dtype=float)
y = np.array([1.55, 1.80, 1.66, 0.73, 0.69, 1.30, 0.38, 0.72, 0.70], dtype=float)

n = len(x)

X = np.log(x)
Y = y

Sx = np.sum(X)
Sx2 = np.sum(X ** 2)
SY = np.sum(Y)
SxY = np.sum(X * Y)

a = (n * SxY - Sx * SY) / (n * Sx2 - Sx ** 2)
b = (SY - a * Sx) / n

z = a * np.log(x) + b

print("a =", a)
print("b =", b)

s = np.sum(((z - y)**2 / n))

print("sku = ", s)

delta = math.sqrt(s / n)

print("sko =", delta)

rel = delta / math.sqrt(np.sum(y**2))

print("relative =", rel)