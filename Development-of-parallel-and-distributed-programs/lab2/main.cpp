#include <mpi.h>
#include <cmath>
#include <vector>
#include <iostream>
#include <random>

constexpr int N = 60000;
constexpr double EPS = 1e-5;
constexpr int MAX_ITER = 100;

struct RowRange {
    int start;
    int end;
};

RowRange get_range(int rank, int size, int N_total) {
    int base = N_total / size;
    int rem  = N_total % size;
    RowRange r;
    if (rank < rem) {
        r.start = rank * (base + 1);
        r.end   = r.start + (base + 1);
    } else {
        r.start = rem * (base + 1) + (rank - rem) * base;
        r.end   = r.start + base;
    }
    return r;
}

int main(int argc, char** argv) {
    MPI_Init(&argc, &argv);

    int rank, size;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);

    if (rank == 0) std::cout << "Метод минимальных невязок (MPI)\n";

    RowRange range = get_range(rank, size, N);
    int local_rows = range.end - range.start;

    std::vector<double> x(N, 0.0);
    std::vector<double> b(N, 0.0);
    std::vector<double> y(N, 0.0);
    std::vector<double> tmpY(local_rows);
    std::vector<double> Ay_local(local_rows);
    std::vector<double> Ay(N);

    if (rank == 0) {
        std::mt19937 gen(42);
        std::uniform_real_distribution<double> dist(0.0, 1.0);
        for (int i = 0; i < N; ++i) b[i] = dist(gen);
    }

    MPI_Bcast(b.data(), N, MPI_DOUBLE, 0, MPI_COMM_WORLD);

    double local_b2 = 0.0;
    for (int i = range.start; i < range.end; ++i) local_b2 += b[i] * b[i];
    double b2 = 0.0;
    MPI_Allreduce(&local_b2, &b2, 1, MPI_DOUBLE, MPI_SUM, MPI_COMM_WORLD);
    double b_norm = std::sqrt(b2);
    if (b_norm == 0.0) {
        MPI_Finalize();
        return 0;
    }

    std::vector<int> counts(size), displs(size);
    for (int p = 0; p < size; ++p) {
        RowRange r = get_range(p, size, N);
        counts[p] = r.end - r.start;
        displs[p] = r.start;
    }

    int iter = 0;
    double rel_res = 0.0;
    double t_start = MPI_Wtime();

    while (iter < MAX_ITER) {
        for (int li = 0; li < local_rows; ++li) {
            int i = range.start + li;
            double sum = 2.0 * x[i];
            for (int j = 0; j < N; ++j) if (i != j) sum += x[j];
            tmpY[li] = sum - b[i];
        }

        MPI_Allgatherv(tmpY.data(), local_rows, MPI_DOUBLE,
                       y.data(), counts.data(), displs.data(), MPI_DOUBLE, MPI_COMM_WORLD);

        double local_r2 = 0.0;
        for (int li = 0; li < local_rows; ++li) local_r2 += tmpY[li] * tmpY[li];
        double r2 = 0.0;
        MPI_Allreduce(&local_r2, &r2, 1, MPI_DOUBLE, MPI_SUM, MPI_COMM_WORLD);
        rel_res = std::sqrt(r2) / b_norm;
        if (rel_res < EPS) break;

        for (int li = 0; li < local_rows; ++li) {
            int i = range.start + li;
            double sum = 2.0 * y[i];
            for (int j = 0; j < N; ++j) if (i != j) sum += y[j];
            Ay_local[li] = sum;
        }

        MPI_Allgatherv(Ay_local.data(), local_rows, MPI_DOUBLE,
                       Ay.data(), counts.data(), displs.data(), MPI_DOUBLE, MPI_COMM_WORLD);

        double local_num = 0.0, local_den = 0.0;
        for (int li = 0; li < local_rows; ++li) {
            int i = range.start + li;
            local_num += y[i] * Ay[i];
            local_den += Ay[i] * Ay[i];
        }
        double num = 0.0, den = 0.0;
        MPI_Allreduce(&local_num, &num, 1, MPI_DOUBLE, MPI_SUM, MPI_COMM_WORLD);
        MPI_Allreduce(&local_den, &den, 1, MPI_DOUBLE, MPI_SUM, MPI_COMM_WORLD);

        if (den == 0.0) break;
        double tau = num / den;

        for (int i = 0; i < N; ++i) x[i] -= tau * y[i];

        ++iter;
    }

    double t_end = MPI_Wtime();

    if (rank == 0) {
        std::cout << "Время: " << (t_end - t_start) << " сек\n";
        std::cout << "Количество итераций: " << iter << "\n";
    }

    MPI_Finalize();
    return 0;
}
