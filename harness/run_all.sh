#!/bin/bash
# Master orchestrator for the merged suite: 8 systems benchmarks (b1-b8, the
# ICSE study) + 5 AI benchmarks (b9-b13: kmeans/knn/mlp/ga/fuzzy, the MICAI study),
# across up to 12 languages. Delegates each benchmark to run_single.sh, which
# resolves the per-suite language set, runs a toolchain preflight, splits the
# slow tier (R) onto a reduced budget, and merges per-language JSON.
#
# Env knobs:
#   BENCHES="b9_kmeans b10_knn"      limit to specific benchmarks (default: all 13)
#   LANGS="c rust java"       restrict languages (default: per-suite set)
#   INCLUDE_SLOW=1            (default) keep R; it always runs in the slow tier
#   RUNS / WARMUP             fast-tier hyperfine budget (default 10 / 3)
#   SLOW_RUNS / SLOW_WARMUP   slow-tier budget (default 2 / 0)
#   RUN_TIMEOUT=300           per-run wall cap for the slow tier (0 = off)
set -uo pipefail

# macOS: brew keg-only formulae (openjdk, zig@0.14) aren't on a default PATH.
for p in /opt/homebrew/opt/openjdk/bin /opt/homebrew/opt/zig@0.14/bin \
         /usr/local/opt/openjdk/bin /usr/local/opt/zig@0.14/bin; do
    [ -d "$p" ] && export PATH="$p:$PATH"
done
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
[ -d "$HOME/.juliaup/bin" ] && export PATH="$HOME/.juliaup/bin:$PATH"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
chmod +x "$SCRIPT_DIR"/*.sh 2>/dev/null || true   # self-heal exec bit stripped by unzip
ROOT="$(dirname "$SCRIPT_DIR")"
DATA="$ROOT/data"

SYSTEMS_BENCHMARKS=(b1_fibonacci b2_bubble_sort b3_matrix_mul b4_monte_carlo b5_regex b6_file_io b7_concurrent b8_json_parse)
AI_BENCHMARKS=(b9_kmeans b10_knn b11_mlp b12_ga b13_fuzzy)
ALL_BENCHMARKS=("${SYSTEMS_BENCHMARKS[@]}" "${AI_BENCHMARKS[@]}")

# Which benchmarks to run this invocation.
if [ -n "${BENCHES:-}" ]; then
    read -r -a RUN_LIST <<< "$BENCHES"
else
    RUN_LIST=("${ALL_BENCHMARKS[@]}")
fi

echo "=== Merged Benchmark Suite (systems b1-b8 + AI b9-b13) ==="
echo "Date:    $(date)"
echo "Machine: $(uname -srm)"
echo "Runs:    ${RUNS:-10} (warmup ${WARMUP:-3}); slow tier ${SLOW_RUNS:-2} (warmup ${SLOW_WARMUP:-0})"
echo "Benches: ${RUN_LIST[*]}"
[ -n "${LANGS:-}" ] && echo "Langs:   $LANGS (override)"
echo ""

# The two systems benchmarks that read generated data still need it present.
need_data=0
for b in "${RUN_LIST[@]}"; do
    [ "$b" = "b5_regex" ] && need_data=1
    [ "$b" = "b8_json_parse" ] && need_data=1
done
if [ "$need_data" -eq 1 ] && { [ ! -f "$DATA/regex_input.txt" ] || [ ! -f "$DATA/json_input.json" ]; }; then
    echo "ERROR: test data missing. Run: python3 harness/generate_data.py"
    exit 1
fi

fail=0
for bench in "${RUN_LIST[@]}"; do
    echo ""
    echo "########## $bench ##########"
    if [ -n "${LANGS:-}" ]; then
        # shellcheck disable=SC2086
        bash "$SCRIPT_DIR/run_single.sh" "$bench" $LANGS || { echo "WARNING: $bench had failures"; fail=1; }
    else
        bash "$SCRIPT_DIR/run_single.sh" "$bench" || { echo "WARNING: $bench had failures"; fail=1; }
    fi
done

echo ""
echo "=== ALL BENCHMARKS COMPLETE ==="
echo "Results in: $ROOT/results/"
[ "$fail" -eq 0 ] || echo "(some benchmarks reported failures — see warnings above)"
