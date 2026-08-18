/* B5: Regex Processing (1M lines) — measures string handling */
/* Uses POSIX regex (regex.h) — standard on macOS/Linux */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <regex.h>

int main(int argc, char *argv[]) {
    const char *filename = argc > 1 ? argv[1] : "../../data/regex_input.txt";
    /* Pattern: email-like addresses */
    const char *pattern = "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}";

    regex_t re;
    if (regcomp(&re, pattern, REG_EXTENDED | REG_NOSUB) != 0) {
        fprintf(stderr, "Failed to compile regex\n");
        return 1;
    }

    FILE *fp = fopen(filename, "r");
    if (!fp) { perror("fopen"); return 1; }

    char line[4096];
    int match_count = 0;

    while (fgets(line, sizeof(line), fp)) {
        if (regexec(&re, line, 0, NULL, 0) == 0) {
            match_count++;
        }
    }

    fclose(fp);
    regfree(&re);
    printf("%d\n", match_count);
    return 0;
}
