/* B2: Bubble Sort (1M integers) — measures memory access patterns, cache behavior */
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#define N 100000

void bubble_sort(int *arr, int n) {
    for (int i = 0; i < n - 1; i++) {
        int swapped = 0;
        for (int j = 0; j < n - i - 1; j++) {
            if (arr[j] > arr[j + 1]) {
                int tmp = arr[j];
                arr[j] = arr[j + 1];
                arr[j + 1] = tmp;
                swapped = 1;
            }
        }
        if (!swapped) break;
    }
}

int main(void) {
    srand(42);
    int *arr = malloc(N * sizeof(int));
    for (int i = 0; i < N; i++) {
        arr[i] = rand() % N;
    }
    bubble_sort(arr, N);
    printf("%d %d\n", arr[0], arr[N - 1]);
    free(arr);
    return 0;
}
