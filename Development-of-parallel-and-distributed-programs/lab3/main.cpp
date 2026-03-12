#include <cmath>
#include <vector>
#include <iostream>
#include <random>
#include <omp.h>

constexpr int N = 60000;
constexpr double EPS = 1e-5;
constexpr int MAX_ITER = 100;

int main() {
    std::cout << "Метод минимальных невязок (OpenMP)\n";

    std::vector<double> x(N, 0.0);
    std::vector<double> b(N, 0.0);
    std::vector<double> y(N, 0.0);
    std::vector<double> Ay(N, 0.0);

    std::mt19937 gen(42);
    std::uniform_real_distribution<double> dist(0.0, 1.0);
    for (int i = 0; i < N; ++i) b[i] = dist(gen);

    double b2 = 0.0;
    #pragma omp parallel for reduction(+:b2)
    for (int i = 0; i < N; ++i) b2 += b[i] * b[i];
    double b_norm = std::sqrt(b2);
    if (b_norm == 0.0) return 0;

    int iter = 0;
    double rel_res = 0.0;
    double t_start = omp_get_wtime();

    while (iter < MAX_ITER) {
        #pragma omp parallel for
        for (int i = 0; i < N; ++i) {
            double sum = 2.0 * x[i];
            for (int j = 0; j < N; ++j) if (i != j) sum += x[j];
            y[i] = sum - b[i];
        }

        double r2 = 0.0;
        #pragma omp parallel for reduction(+:r2)
        for (int i = 0; i < N; ++i) r2 += y[i] * y[i];
        rel_res = std::sqrt(r2) / b_norm;
        if (rel_res < EPS) break;

        #pragma omp parallel for
        for (int i = 0; i < N; ++i) {
            double sum = 2.0 * y[i];
            for (int j = 0; j < N; ++j) if (i != j) sum += y[j];
            Ay[i] = sum;
        }

        double num = 0.0, den = 0.0;
        #pragma omp parallel for reduction(+:num, den)
        for (int i = 0; i < N; ++i) {
            num += y[i] * Ay[i];
            den += Ay[i] * Ay[i];
        }

        if (den == 0.0) break;
        double tau = num / den;

        #pragma omp parallel for
        for (int i = 0; i < N; ++i) x[i] -= tau * y[i];

        ++iter;
    }

    double t_end = omp_get_wtime();

    std::cout << "Время: " << (t_end - t_start) << " сек\n";
    std::cout << "Количество итераций: " << iter << "\n";

    return 0;
}
