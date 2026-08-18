/* B4: Monte Carlo Pi estimation (1B iterations) — measures FP arithmetic, RNG */
#include <stdio.h>
#include <stdlib.h>

#define ITERATIONS 1000000000

/* Simple LCG RNG for fairness across languages */
typedef struct { unsigned long long state; } SimpleRNG;

double next_double(SimpleRNG *rng) {
    rng->state = rng->state * 6364136223846793005ULL + 1442695040888963407ULL;
    return (double)(rng->state >> 33) / (double)(1ULL << 31);
}

int main(void) {
    SimpleRNG rng = { .state = 42 };
    long long inside = 0;

    for (long long i = 0; i < ITERATIONS; i++) {
        double x = next_double(&rng);
        double y = next_double(&rng);
        if (x * x + y * y <= 1.0) {
            inside++;
        }
    }

    double pi = 4.0 * (double)inside / (double)ITERATIONS;
    printf("%.10f\n", pi);
    return 0;
}
