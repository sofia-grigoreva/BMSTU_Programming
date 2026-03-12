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
    int rem = N_total % size;
    RowRange r;
    if (rank < rem) {
        r.start = rank * (base + 1);
        r.end = r.start + (base + 1);
    } else {
        r.start = rem * (base + 1) + (rank - rem) * base;
        r.end = r.start + base;
    }
    return r;
}

int main(int argc, char** argv) {
    MPI_Init(&argc, &argv);

    int rank, size;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);

    if(rank == 0) std::cout << "Метод минимальных невязок\n";

    RowRange range = get_range(rank, size, N);
    int local_rows = range.end - range.start;

    std::vector<double> x_local(local_rows, 0.0);
    std::vector<double> b_local(local_rows);
    std::vector<double> y_local(local_rows);
    std::vector<double> Ay_local(local_rows);
    std::vector<double> x_full(N);
    std::vector<double> y_full(N);

    if (rank == 0) {
        std::mt19937 gen(42);
        std::uniform_real_distribution<double> dist(0.0, 1.0);

        std::vector<double> b_full(N);
        for (int i = 0; i < N; ++i)
            b_full[i] = dist(gen);

        std::vector<int> counts(size), displs(size);
        for (int r = 0; r < size; ++r) {
            RowRange rr = get_range(r, size, N);
            counts[r] = rr.end - rr.start;
            displs[r] = rr.start;
        }

        MPI_Scatterv(b_full.data(), counts.data(), displs.data(),
                     MPI_DOUBLE, b_local.data(), local_rows,
                     MPI_DOUBLE, 0, MPI_COMM_WORLD);
    } else {
        std::vector<int> counts(size), displs(size);
        for (int r = 0; r < size; ++r) {
            RowRange rr = get_range(r, size, N);
            counts[r] = rr.end - rr.start;
            displs[r] = rr.start;
        }

        MPI_Scatterv(nullptr, counts.data(), displs.data(),
                     MPI_DOUBLE, b_local.data(), local_rows,
                     MPI_DOUBLE, 0, MPI_COMM_WORLD);
    }

    double local_b2 = 0;
    for (double bi : b_local) local_b2 += bi * bi;
    double b2 = 0;
    MPI_Allreduce(&local_b2, &b2, 1, MPI_DOUBLE, MPI_SUM, MPI_COMM_WORLD);
    double b_norm = sqrt(b2);

    int iter = 0;
    double rel_res = 0;
    double t_start = MPI_Wtime();

    while (iter < MAX_ITER) {
        MPI_Allgather(x_local.data(), local_rows, MPI_DOUBLE,
                      x_full.data(), local_rows, MPI_DOUBLE,
                      MPI_COMM_WORLD);

        for (int li = 0; li < local_rows; ++li) {
            int i = range.start + li;
            double s = 2.0 * x_full[i];
            for (int j = 0; j < N; ++j) if (i != j) s += x_full[j];
            y_local[li] = s - b_local[li];
        }

        double local_r2 = 0;
        for (double yi : y_local) local_r2 += yi * yi;
        double r2 = 0;
        MPI_Allreduce(&local_r2, &r2, 1, MPI_DOUBLE, MPI_SUM, MPI_COMM_WORLD);

        rel_res = sqrt(r2) / b_norm;
        if (rel_res < EPS) break;

        MPI_Allgather(y_local.data(), local_rows, MPI_DOUBLE,
                      y_full.data(), local_rows, MPI_DOUBLE,
                      MPI_COMM_WORLD);

        for (int li = 0; li < local_rows; ++li) {
            int i = range.start + li;
            double s = 2.0 * y_full[i];
            for (int j = 0; j < N; ++j) if (i != j) s += y_full[j];
            Ay_local[li] = s;
        }

        double local_num = 0, local_den = 0;
        for (int li = 0; li < local_rows; ++li) {
            local_num += y_local[li] * Ay_local[li];
            local_den += Ay_local[li] * Ay_local[li];
        }

        double num = 0, den = 0;
        MPI_Allreduce(&local_num, &num, 1, MPI_DOUBLE, MPI_SUM, MPI_COMM_WORLD);
        MPI_Allreduce(&local_den, &den, 1, MPI_DOUBLE, MPI_SUM, MPI_COMM_WORLD);

        double tau = num / den;

        for (int li = 0; li < local_rows; ++li)
            x_local[li] -= tau * y_local[li];

        iter++;
    }

    double t_end = MPI_Wtime();

    if (rank == 0) {
        std::cout << "Время: " << std::fixed << t_end - t_start << " сек\n";
        std::cout << "Количество итераций: " << iter << "\n";
    }

    MPI_Finalize();
    return 0;
}
