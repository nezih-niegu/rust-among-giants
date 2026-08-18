CXX = c++
CXXFLAGS = -O3 -march=native -std=c++17 -Wall -Wextra
LDFLAGS = -lpthread

# MICAI AI suite: b9_kmeans b10_knn b11_mlp b12_ga b13_fuzzy. Legacy CS suite (b1-b8) kept for the
# ICSE paper reference; both build via the generic `%: %.cpp` pattern rule below.
TARGETS = b1_fibonacci b2_bubble_sort b3_matrix_mul b4_monte_carlo \
          b5_regex b6_file_io b7_concurrent b8_json_parse \
          b9_kmeans b10_knn b11_mlp b12_ga b13_fuzzy

all: $(TARGETS)

%: %.cpp
	$(CXX) $(CXXFLAGS) -o $@ $< $(LDFLAGS)

clean:
	rm -f $(TARGETS)
