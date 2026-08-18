#include <iostream>
#include <cstdint>
constexpr long long ITERATIONS = 1000000000;
struct SimpleRNG {
    uint64_t state;
    double next() {
        state = state * 6364136223846793005ULL + 1442695040888963407ULL;
        return static_cast<double>(state >> 33) / static_cast<double>(1ULL << 31);
    }
};
int main() {
    SimpleRNG rng{42};
    long long inside = 0;
    for (long long i = 0; i < ITERATIONS; i++) {
        double x = rng.next(), y = rng.next();
        if (x*x + y*y <= 1.0) inside++;
    }
    std::cout.precision(10); std::cout << std::fixed << 4.0 * inside / ITERATIONS << "\n";
}
