import math

z_xa = 0.75
z_xg = 1.1
z_xh = 1.25

x0, xn = 1, 5
y0, yn = 1.55, 0.70

y_a = (y0 + yn) / 2
y_g = math.sqrt(y0 * yn)
y_h = 2 / (1 / y0 + 1 / yn)

delta = {
    1: abs(z_xa - y_a),
    2: abs(z_xg - y_g),
    3: abs(z_xa - y_g),
    4: abs(z_xg - y_a),
    5: abs(z_xh - y_a),
    6: abs(z_xa - y_h),
    7: abs(z_xh - y_h),
    8: abs(z_xh - y_g),
    9: abs(z_xg - y_h),
}

best_k = min(delta, key=delta.get)
print(best_k)