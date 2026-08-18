#!/usr/bin/env bash
# Verify that every language produces the agreed checksum for each AI benchmark.
#
# All eleven languages here are designed to be bit-exact: the shared 64-bit LCG
# (seed 42) and transcendental-free kernels make every output reproducible to
# the last printed digit. The reference strings below were established on
# x86-64 with gcc -O3. COBOL has been retired from this repo.
#
# NOTE: this runs every benchmark at FULL size. The interpreted/scalar tiers
# (Python, Julia, R) are slow — a full verification of all languages takes a
# while. Pass languages to restrict, e.g.:
#   bash verify_checksums.sh c cpp rust go fortran java   # the fast compiled set
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(dirname "$SCRIPT_DIR")"
B="$ROOT/benchmarks"
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
[ -d "$HOME/.juliaup/bin" ] && export PATH="$HOME/.juliaup/bin:$PATH"

declare -A REF=(
    [b9_kmeans]="559268 20.004093"
    [b10_knn]="8603"
    [b11_mlp]="0.085671 7.648975"
    [b12_ga]="24.460672 4.216343"
    [b13_fuzzy]="999999.524374"
)
BENCHES=(b9_kmeans b10_knn b11_mlp b12_ga b13_fuzzy)

ALL_LANGS=(c cpp rust go fortran java zig swift kotlin python julia r)
if [ "$#" -gt 0 ]; then LANGS=("$@"); else LANGS=("${ALL_LANGS[@]}"); fi

jclass() { case "$1" in b9_kmeans) echo B9Kmeans;; b10_knn) echo B10Knn;; b11_mlp) echo B11Mlp;; b12_ga) echo B12Ga;; b13_fuzzy) echo B13Fuzzy;; esac; }

run_lang() {  # $1=lang $2=bench -> echoes program output
    local lang="$1" bench="$2"
    case "$lang" in
        c)       "$B/c/$bench" ;;
        cpp)     "$B/cpp/$bench" ;;
        rust)    "$B/rust/target/release/$bench" ;;
        go)      "$B/go/$bench" ;;
        fortran) "$B/fortran/$bench" ;;
        java)    java -cp "$B/java" "$(jclass "$bench")" ;;
        zig)     "$B/zig/zig-out/bin/$bench" ;;
        swift)   "$B/swift/$bench" ;;
        kotlin)  java -jar "$B/kotlin/$bench.jar" ;;
        python)  python3 "$B/python/$bench.py" ;;
        julia)   julia "$B/julia/$bench.jl" ;;
        r)       Rscript "$B/r/$bench.R" ;;
    esac
}

fail=0
for bench in "${BENCHES[@]}"; do
    echo "── $bench  (reference: ${REF[$bench]}) ──"
    for lang in "${LANGS[@]}"; do
        out="$(run_lang "$lang" "$bench" 2>/dev/null)" || { printf "  %-8s ERROR (not built / toolchain missing)\n" "$lang"; fail=1; continue; }
        if [ "$out" = "${REF[$bench]}" ]; then
            printf "  %-8s \xe2\x9c\x93  %s\n" "$lang" "$out"
        else
            printf "  %-8s \xe2\x9c\x97  %s\n" "$lang" "$out"; fail=1
        fi
    done
done

if [ "$fail" -eq 0 ]; then
    echo "All checked languages agree bit-for-bit."
else
    echo "Some languages diverged or were not built — see ✗ / ERROR rows above."
fi
exit "$fail"
