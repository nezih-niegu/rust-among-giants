/* B7: Concurrent Counter (8 threads, 10M ops each) — measures thread sync */
#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <stdatomic.h>

#define NUM_THREADS 8
#define OPS_PER_THREAD 10000000

static atomic_long counter = 0;

void *worker(void *arg) {
    (void)arg;
    for (int i = 0; i < OPS_PER_THREAD; i++) {
        atomic_fetch_add_explicit(&counter, 1, memory_order_relaxed);
    }
    return NULL;
}

int main(void) {
    pthread_t threads[NUM_THREADS];

    for (int i = 0; i < NUM_THREADS; i++) {
        pthread_create(&threads[i], NULL, worker, NULL);
    }
    for (int i = 0; i < NUM_THREADS; i++) {
        pthread_join(threads[i], NULL);
    }

    printf("%ld\n", atomic_load(&counter));
    return 0;
}
