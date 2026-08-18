/* B6: Checkpoint I/O (durable write + read 4GB) — models PyTorch/Flax
 * model-checkpoint save+load pattern: write weights, fsync to guarantee
 * the checkpoint survives a crash, then read back. */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#define CHUNK_SIZE (1024 * 1024)  /* 1MB */
#define TOTAL_SIZE (4LL * 1024 * 1024 * 1024)  /* 4GB */
#define NUM_CHUNKS (TOTAL_SIZE / CHUNK_SIZE)

int main(int argc, char *argv[]) {
    char *buf = malloc(CHUNK_SIZE);
    memset(buf, 'A', CHUNK_SIZE);

    const char *filename = argc > 1 ? argv[1] : "../../data/fileio_test_c.tmp";

    /* Write phase */
    FILE *fp = fopen(filename, "wb");
    if (!fp) { perror("fopen write"); return 1; }
    for (int i = 0; i < NUM_CHUNKS; i++) {
        fwrite(buf, 1, CHUNK_SIZE, fp);
    }
    fflush(fp);
    fsync(fileno(fp));
    fclose(fp);

    /* Read phase */
    fp = fopen(filename, "rb");
    if (!fp) { perror("fopen read"); return 1; }
    long long total = 0;
    while (1) {
        size_t n = fread(buf, 1, CHUNK_SIZE, fp);
        if (n == 0) break;
        total += (long long)n;
    }
    fclose(fp);

    printf("%lld\n", total);
    remove(filename);
    free(buf);
    return 0;
}
