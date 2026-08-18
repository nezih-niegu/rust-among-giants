/* B1: Fibonacci recursive (n=45) — measures function call overhead */
#include <stdio.h>
#include <stdlib.h>

long long fib(int n) {
    if (n <= 1) return n;
    return fib(n - 1) + fib(n - 2);
}

int main(int argc, char *argv[]) {
    int n = argc > 1 ? atoi(argv[1]) : 45;
    printf("%lld\n", fib(n));
    return 0;
}
