/* B8: JSON Parsing (100MB file) — measures full JSON parse + tree walk.
 *
 * Uses cJSON (vendored under vendor/cJSON.{c,h}, MIT-licensed) to match the
 * "full-parse" semantics used by the other 8 languages' implementations
 * (serde_json, encoding/json, java.util / hand-rolled, JSON.jl,
 * JSONSerialization, std.json, nlohmann::json). The previous single-pass
 * byte-scanner implementation was ~30x faster but solved a different
 * problem (token counting without parsing), making cross-language results
 * incomparable. See README §"Known limitations (B8)".
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "vendor/cJSON.h"

typedef struct {
    long objects, arrays, strings, numbers, booleans, nulls;
} JsonStats;

static void count(const cJSON *v, JsonStats *st) {
    if (v == NULL) return;
    if (cJSON_IsObject(v)) {
        st->objects++;
        const cJSON *child;
        cJSON_ArrayForEach(child, v) count(child, st);
    } else if (cJSON_IsArray(v)) {
        st->arrays++;
        const cJSON *child;
        cJSON_ArrayForEach(child, v) count(child, st);
    } else if (cJSON_IsString(v)) {
        st->strings++;
    } else if (cJSON_IsBool(v)) {
        st->booleans++;
    } else if (cJSON_IsNumber(v)) {
        st->numbers++;
    } else if (cJSON_IsNull(v)) {
        st->nulls++;
    }
}

int main(int argc, char *argv[]) {
    const char *filename = argc > 1 ? argv[1] : "../../data/json_input.json";

    FILE *fp = fopen(filename, "rb");
    if (!fp) { perror("fopen"); return 1; }
    fseek(fp, 0, SEEK_END);
    long fsize = ftell(fp);
    fseek(fp, 0, SEEK_SET);
    char *buf = malloc(fsize + 1);
    fread(buf, 1, fsize, fp);
    buf[fsize] = '\0';
    fclose(fp);

    cJSON *root = cJSON_Parse(buf);
    if (!root) {
        fprintf(stderr, "cJSON parse failed near: %s\n", cJSON_GetErrorPtr());
        free(buf);
        return 1;
    }

    JsonStats stats = {0};
    count(root, &stats);

    printf("objects=%ld arrays=%ld strings=%ld numbers=%ld bools=%ld nulls=%ld\n",
           stats.objects, stats.arrays, stats.strings, stats.numbers,
           stats.booleans, stats.nulls);

    cJSON_Delete(root);
    free(buf);
    return 0;
}
