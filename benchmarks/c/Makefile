CC = cc
CFLAGS = -O3 -march=native -Wall -Wextra
LDFLAGS = -lpthread -lm

# MICAI AI suite: b9_kmeans b10_knn b11_mlp b12_ga b13_fuzzy. Legacy CS suite (b1-b8) kept for the
# ICSE paper reference; both build via the generic `%: %.c` pattern rule below.
TARGETS = b1_fibonacci b2_bubble_sort b3_matrix_mul b4_monte_carlo \
          b5_regex b6_file_io b7_concurrent b8_json_parse \
          b9_kmeans b10_knn b11_mlp b12_ga b13_fuzzy

all: $(TARGETS)

# b8 uses vendored cJSON (vendor/cJSON.{c,h}, MIT) for full-parse semantics.
b8_json_parse: b8_json_parse.c vendor/cJSON.c vendor/cJSON.h
	$(CC) $(CFLAGS) -o $@ b8_json_parse.c vendor/cJSON.c $(LDFLAGS)

%: %.c
	$(CC) $(CFLAGS) -o $@ $< $(LDFLAGS)

clean:
	rm -f $(TARGETS)

.PHONY: all clean
