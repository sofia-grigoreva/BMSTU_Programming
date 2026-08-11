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

def main():
    a = list(map(int, input().split()))
    b = list(map(int, input().split()))
    c = list(map(int, input().split()))
    d = list(map(int, input().split()))

    # a = [1, 1, 1]   
    # b = [4, 4, 4, 4]    
    # c = [1, 1, 1]  
    # d = [5, 6, 6, 5]
    
    x = solve(a, b, c, d)
    print(x)

if __name__ == "__main__":
    main()