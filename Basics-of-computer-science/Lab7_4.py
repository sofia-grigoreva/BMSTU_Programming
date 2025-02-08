#!/usr/bin/python3

def memo(f):
    known_res = {}

    def loop(*n):
        if n in known_res:
                return known_res[n]
        else:
                known_res[n] = f(*n)
                return known_res[n]
                
    return loop


def fibonacchi(n):
    if n <= 1:
        return 0
    elif n == 2 or n == 3:
        return 1
    else:
        return fibonacchi(n - 2) + fibonacchi(n - 1)

memo_fibonacchi=memo(fibonacchi)
