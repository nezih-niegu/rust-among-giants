#include <iostream>
#include <vector>
#include <cstdint>
constexpr int SIZE = 2000;

static uint64_t rng_state = 42;
static double next_double() {
    rng_state = rng_state * 6364136223846793005ULL + 1442695040888963407ULL;
    return (double)(rng_state >> 33) / (double)(1ULL << 31);
}

int main() {
    std::vector<double> A(SIZE*SIZE), B(SIZE*SIZE), C(SIZE*SIZE, 0.0);
    for (int i = 0; i < SIZE*SIZE; i++) { A[i] = next_double(); B[i] = next_double(); }
    for (int i = 0; i < SIZE; i++)
        for (int k = 0; k < SIZE; k++) {
            double a_ik = A[i*SIZE+k];
            for (int j = 0; j < SIZE; j++)
                C[i*SIZE+j] += a_ik * B[k*SIZE+j];
        }
    double sum = 0; for (auto x : C) sum += x;
    std::cout.precision(6); std::cout << std::fixed << sum << "\n";
}
