#include <cstdlib>
#include <iostream>
long long fib(int n) {
    if (n <= 1) return n;
    return fib(n - 1) + fib(n - 2);
}
int main(int argc, char* argv[]) {
    int n = argc > 1 ? std::atoi(argv[1]) : 45;
    std::cout << fib(n) << "\n";
}
