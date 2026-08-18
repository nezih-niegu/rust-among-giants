/* B3: Matrix Multiplication (1000×1000) — measures FP compute, vectorization */
#include <stdio.h>
#include <stdlib.h>

#define SIZE 2000

static unsigned long long rng_state = 42;
static double next_double(void) {
    rng_state = rng_state * 6364136223846793005ULL + 1442695040888963407ULL;
    return (double)(rng_state >> 33) / (double)(1ULL << 31);
}

static double A[SIZE][SIZE];
static double B[SIZE][SIZE];
static double C[SIZE][SIZE];

int main(void) {
    /* Interleaved A/B fill — same LCG sequence in all 9 languages */
    for (int i = 0; i < SIZE; i++) {
        for (int j = 0; j < SIZE; j++) {
            A[i][j] = next_double();
            B[i][j] = next_double();
        }
    }

    /* Multiply: C = A × B (ijk order) */
    for (int i = 0; i < SIZE; i++) {
        for (int k = 0; k < SIZE; k++) {
            double a_ik = A[i][k];
            for (int j = 0; j < SIZE; j++) {
                C[i][j] += a_ik * B[k][j];
            }
        }
    }

    /* Print checksum to prevent dead code elimination */
    double sum = 0.0;
    for (int i = 0; i < SIZE; i++)
        for (int j = 0; j < SIZE; j++)
            sum += C[i][j];
    printf("%.6f\n", sum);
    return 0;
}
