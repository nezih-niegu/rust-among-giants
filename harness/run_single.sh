#!/bin/bash
# Run a single benchmark across all 10 languages (or a subset).
#
# Usage:
#   bash run_single.sh <benchmark_id> [lang1 lang2 ...]
#
# Examples:
#   bash run_single.sh b1_fibonacci                # all 10 languages
#   bash run_single.sh b1_fibonacci rust           # just rust
#   bash run_single.sh b3_matrix_mul c rust zig    # only these three
#
# Output: results/<benchmark_id>.json (hyperfine JSON, overwrites prior)
#
# Behavior:
#   - Builds only the languages it will run (lazy)
#   - Uses same hyperfine config as run_all.sh (10 runs, 3 warmup)
#   - Skips build for interpreted languages (Python, Julia)
#   - Errors out if test data is missing for b5_regex / b8_json_parse
set -euo pipefail

# Tool path setup — brew keg-only formulae aren't on the default PATH.
# Java/javac live under openjdk; we pin Zig to 0.14 (0.16 broke benchmark APIs).
[ -d /opt/homebrew/opt/openjdk/bin ] && export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"
[ -d /opt/homebrew/opt/zig@0.14/bin ] && export PATH="/opt/homebrew/opt/zig@0.14/bin:$PATH"
[ -d /usr/local/opt/openjdk/bin ] && export PATH="/usr/local/opt/openjdk/bin:$PATH"        # Intel Macs
[ -d /usr/local/opt/zig@0.14/bin ] && export PATH="/usr/local/opt/zig@0.14/bin:$PATH"      # Intel Macs

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
chmod +x "$SCRIPT_DIR"/*.sh 2>/dev/null || true   # self-heal exec bit stripped by unzip
ROOT="$(dirname "$SCRIPT_DIR")"
RESULTS="$ROOT/results"
BENCHMARKS="$ROOT/benchmarks"
DATA="$ROOT/data"

RUNS="${RUNS:-10}"
WARMUP="${WARMUP:-3}"

# rustup (cargo) and juliaup install per-user under $HOME and aren't on a fresh
# non-login PATH; source them so the sweep works without a manual `source`.
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
[ -d "$HOME/.cargo/bin" ] && export PATH="$HOME/.cargo/bin:$PATH"
[ -d "$HOME/.juliaup/bin" ] && export PATH="$HOME/.juliaup/bin:$PATH"
# Julia is often the macOS .app or a brew/Linux install rather than juliaup.
for jb in /Applications/Julia-*.app/Contents/Resources/julia/bin \
          /opt/homebrew/bin /usr/local/bin /opt/julia/bin; do
    [ -x "$jb/julia" ] && export PATH="$jb:$PATH" && break
done

# Thirteen benchmarks in two families. Systems suite b1-b8 (the ICSE study) and
# the AI-kernel suite b9-b13 (renamed from kmeans/knn/mlp/ga/fuzzy). COBOL retired.
SYSTEMS_BENCHMARKS=(b1_fibonacci b2_bubble_sort b3_matrix_mul b4_monte_carlo b5_regex b6_file_io b7_concurrent b8_json_parse)
AI_BENCHMARKS=(b9_kmeans b10_knn b11_mlp b12_ga b13_fuzzy)
ALL_BENCHMARKS=("${SYSTEMS_BENCHMARKS[@]}" "${AI_BENCHMARKS[@]}")

# Every benchmark is now attempted across all twelve languages. Languages that
# lack an implementation of a given benchmark, or whose toolchain is absent, are
# skipped gracefully at build time (see the resilient BUILD loop below).
ALL_TWELVE=(c cpp rust go fortran java zig swift kotlin python julia r)
SYSTEMS_LANGUAGES=("${ALL_TWELVE[@]}")
AI_LANGUAGES=("${ALL_TWELVE[@]}")

# Languages whose full-scale runs are slow (interpreted/scalar). They get a
# reduced hyperfine budget (see RUN section) so the sweep can't hang in warmups.
SLOW_LANGS="${SLOW_LANGS-r python}"

# Flat union of every language (for arg validation and the usage banner).
ALL_LANGUAGES=("${ALL_TWELVE[@]}")

is_ai_bench() { case " ${AI_BENCHMARKS[*]} " in *" $1 "*) return 0 ;; *) return 1 ;; esac; }

default_langs_for() {  # every benchmark defaults to all twelve languages
    echo "${ALL_TWELVE[@]}"
}

# bench id -> Java class name. Hardcoded (BSD sed lacks \u).
java_class() {
    case "$1" in
        b1_fibonacci)   echo "B1Fibonacci" ;;
        b2_bubble_sort) echo "B2BubbleSort" ;;
        b3_matrix_mul)  echo "B3MatrixMul" ;;
        b4_monte_carlo) echo "B4MonteCarlo" ;;
        b5_regex)       echo "B5Regex" ;;
        b6_file_io)     echo "B6FileIO" ;;
        b7_concurrent)  echo "B7Concurrent" ;;
        b8_json_parse)  echo "B8JsonParse" ;;
        b9_kmeans) echo "B9Kmeans" ;; b10_knn) echo "B10Knn" ;; b11_mlp) echo "B11Mlp" ;;
        b12_ga) echo "B12Ga" ;; b13_fuzzy) echo "B13Fuzzy" ;;
        *) echo "UNKNOWN_CLASS_FOR_$1" ;;
    esac
}

mkdir -p "$RESULTS"

# ── Argument parsing ──────────────────────────────────────────────────
if [ $# -lt 1 ]; then
    echo "Usage: bash $(basename "$0") <benchmark_id> [lang1 lang2 ...]"
    echo ""
    echo "Benchmarks: ${ALL_BENCHMARKS[*]}"
    echo "Languages:  ${ALL_LANGUAGES[*]}"
    exit 1
fi

BENCH="$1"
shift

# Validate benchmark
if [[ ! " ${ALL_BENCHMARKS[*]} " == *" $BENCH "* ]]; then
    echo "ERROR: unknown benchmark '$BENCH'"
    echo "Valid: ${ALL_BENCHMARKS[*]}"
    exit 1
fi

# Pick languages: per-suite defaults if no args, else just the listed ones.
if [ $# -eq 0 ]; then
    read -r -a LANGUAGES <<< "$(default_langs_for "$BENCH")"
else
    LANGUAGES=("$@")
    for lang in "${LANGUAGES[@]}"; do
        if [[ ! " ${ALL_LANGUAGES[*]} " == *" $lang "* ]]; then
            echo "ERROR: unknown language '$lang'"
            echo "Valid: ${ALL_LANGUAGES[*]}"
            exit 1
        fi
    done
fi

# Restrict to languages that actually implement this benchmark family. The
# systems suite (b1-b8) has no Fortran/R/Python implementations; the AI suite
# has no COBOL (retired). default_langs_for() already encodes the right set, so
# intersect any explicit selection against it.
read -r -a _AVAIL_LANGS <<< "$(default_langs_for "$BENCH")"
FILTERED=()
for lang in "${LANGUAGES[@]}"; do
    if [[ " ${_AVAIL_LANGS[*]} " == *" $lang "* ]]; then
        FILTERED+=("$lang")
    else
        echo "NOTE: $lang has no implementation for $BENCH; skipping."
    fi
done
LANGUAGES=("${FILTERED[@]}")

# ── Toolchain preflight: skip (don't abort on) languages whose compiler or
#    interpreter isn't installed, so a partial toolchain still runs a sweep.
lang_tool() {
    case "$1" in
        c) echo cc ;; cpp) echo c++ ;; rust) echo cargo ;; go) echo go ;;
        fortran) echo gfortran ;; java) echo java ;; zig) echo zig ;;
        swift) echo swiftc ;; kotlin) echo kotlinc ;; python) echo python3 ;;
        julia) echo julia ;; r) echo Rscript ;;
    esac
}
AVAILABLE=()
for lang in "${LANGUAGES[@]}"; do
    tool="$(lang_tool "$lang")"
    if command -v "$tool" >/dev/null 2>&1; then
        AVAILABLE+=("$lang")
    else
        echo "NOTE: toolchain '$tool' for $lang not found; skipping $lang."
    fi
done
LANGUAGES=("${AVAILABLE[@]}")
if [ ${#LANGUAGES[@]} -eq 0 ]; then
    echo "ERROR: no available toolchains for $BENCH. Nothing to run."
    exit 1
fi


# ── Data files needed by some benchmarks ──────────────────────────────
case "$BENCH" in
    b5_regex)
        if [ ! -f "$DATA/regex_input.txt" ]; then
            echo "ERROR: $DATA/regex_input.txt missing. Run: python3 harness/generate_data.py"
            exit 1
        fi
        ;;
    b8_json_parse)
        if [ ! -f "$DATA/json_input.json" ]; then
            echo "ERROR: $DATA/json_input.json missing. Run: python3 harness/generate_data.py"
            exit 1
        fi
        ;;
esac

echo "=== run_single — $BENCH on: ${LANGUAGES[*]} ==="
echo "Runs: $RUNS, Warmup: $WARMUP"
echo ""

# ── Build only what we need ───────────────────────────────────────────
echo "=== BUILD ==="

# Build one language for $BENCH. Returns non-zero on failure so the caller can
# skip just that language instead of aborting the whole sweep. Building is
# isolated per language; in particular Zig is built per-benchmark (not the whole
# project) so one bad file can't break the other twelve benchmarks.
build_lang() {
    local lang="$1"
    case "$lang" in
        c)       echo "[C] building $BENCH...";       (cd "$BENCHMARKS/c"   && make "$BENCH" >/dev/null) ;;
        cpp)     echo "[C++] building $BENCH...";     (cd "$BENCHMARKS/cpp" && make "$BENCH" >/dev/null) ;;
        rust)    echo "[Rust] building $BENCH...";    (cd "$BENCHMARKS/rust" && cargo build --release --bin "$BENCH" 2>&1 | tail -1) ;;
        go)      echo "[Go] building $BENCH...";      (cd "$BENCHMARKS/go" && go build -o "$BENCH" "$BENCH.go") ;;
        java)    local CLASS; CLASS=$(java_class "$BENCH"); echo "[Java] building $CLASS...";
                 (cd "$BENCHMARKS/java" && javac "${CLASS}.java") ;;
        zig)     echo "[Zig] building $BENCH (per-benchmark)...";
                 (cd "$BENCHMARKS/zig" && mkdir -p zig-out/bin && zig build-exe "${BENCH}.zig" -O ReleaseFast -femit-bin="zig-out/bin/${BENCH}" 2>&1 | tail -8) ;;
        swift)   echo "[Swift] building $BENCH...";   (cd "$BENCHMARKS/swift" && swiftc -O -o "$BENCH" "${BENCH}.swift") ;;
        kotlin)  echo "[Kotlin] building $BENCH...";  (cd "$BENCHMARKS/kotlin" && kotlinc "${BENCH}.kt" -include-runtime -d "${BENCH}.jar" 2>/dev/null) ;;
        fortran) echo "[Fortran] building $BENCH..."; (cd "$BENCHMARKS/fortran" && make "$BENCH" >/dev/null) ;;
        python|julia|r) ;; # interpreted, no build
        *) echo "WARNING: no build rule for $lang"; return 1 ;;
    esac
}

BUILT=()
for lang in "${LANGUAGES[@]}"; do
    if build_lang "$lang"; then
        BUILT+=("$lang")
    else
        echo "WARNING: $lang failed to build $BENCH — skipping this language (others continue)."
    fi
done
if [ ${#BUILT[@]} -eq 0 ]; then
    echo "ERROR: no language built successfully for $BENCH; nothing to run."
    exit 1
fi
LANGUAGES=("${BUILT[@]}")

# ── Build per-language command strings ────────────────────────────────
build_cmd() {
    local lang="$1"
    local bench="$2"
    local java_cls
    java_cls=$(java_class "$bench")

    local extra=""
    case "$bench" in
        b5_regex)      extra=" $DATA/regex_input.txt" ;;
        b8_json_parse) extra=" $DATA/json_input.json" ;;
        b6_file_io)    extra=" $DATA/fileio_test_${lang}.tmp" ;;
    esac

    case "$lang" in
        c)      echo "$BENCHMARKS/c/$bench$extra" ;;
        cpp)    echo "$BENCHMARKS/cpp/$bench$extra" ;;
        rust)   echo "$BENCHMARKS/rust/target/release/$bench$extra" ;;
        go)     echo "$BENCHMARKS/go/$bench$extra" ;;
        java)   echo "java -cp $BENCHMARKS/java $java_cls$extra" ;;
        python) echo "python3 $BENCHMARKS/python/${bench}.py$extra" ;;
        julia)
            # b7 needs real OS threads; -t 8 matches the C version's pthread count
            if [ "$bench" = "b7_concurrent" ]; then
                echo "julia -t 8 $BENCHMARKS/julia/${bench}.jl$extra"
            else
                echo "julia $BENCHMARKS/julia/${bench}.jl$extra"
            fi
            ;;
        zig)    echo "$BENCHMARKS/zig/zig-out/bin/$bench$extra" ;;
        swift)  echo "$BENCHMARKS/swift/$bench$extra" ;;
        kotlin) echo "java -jar $BENCHMARKS/kotlin/${bench}.jar$extra" ;;
        fortran) echo "$BENCHMARKS/fortran/$bench$extra" ;;
        r)      echo "Rscript $BENCHMARKS/r/${bench}.R$extra" ;;
    esac
}

# ── Run hyperfine with RSS-capturing wrapper (M1 timing + M2 memory in one pass)
echo ""
echo "=== RUN (M1 + M2 in one pass) ==="

RESULT_FILE="$RESULTS/${BENCH}.json"
RSS_DIR="$ROOT/.rss-tmp"
mkdir -p "$RSS_DIR"

# Partition into a fast tier (full hyperfine budget) and a slow tier (R, and any
# language listed in $SLOW_LANGS) that gets a reduced budget so a single
# pathologically slow interpreter can't stall the whole sweep in warmups.
FAST_LANGS=(); SLOW_TIER=()
for lang in "${LANGUAGES[@]}"; do
    if [[ " $SLOW_LANGS " == *" $lang "* ]]; then SLOW_TIER+=("$lang"); else FAST_LANGS+=("$lang"); fi
done

SLOW_WARMUP="${SLOW_WARMUP:-0}"
SLOW_RUNS="${SLOW_RUNS:-2}"
RUN_TIMEOUT="${RUN_TIMEOUT:-0}"   # seconds; 0 = no timeout
TIMEOUT_BIN=""
if [ "$RUN_TIMEOUT" -gt 0 ]; then
    if command -v timeout >/dev/null 2>&1; then TIMEOUT_BIN="timeout ${RUN_TIMEOUT}"
    elif command -v gtimeout >/dev/null 2>&1; then TIMEOUT_BIN="gtimeout ${RUN_TIMEOUT}"; fi
fi

FAST_JSON="$RSS_DIR/${BENCH}.fast.json"
SLOW_JSON="$RSS_DIR/${BENCH}.slow.json"
rm -f "$FAST_JSON" "$SLOW_JSON"

if [ ${#FAST_LANGS[@]} -gt 0 ]; then
    HYPERFINE_ARGS=(--warmup "$WARMUP" --runs "$RUNS" -i --export-json "$FAST_JSON")
    for lang in "${FAST_LANGS[@]}"; do
        cmd=$(build_cmd "$lang" "$BENCH")
        log_file="$RSS_DIR/${BENCH}_${lang}.log"; rm -f "$log_file"
        HYPERFINE_ARGS+=(-n "$lang" "bash $SCRIPT_DIR/wrap_rss.sh $log_file $cmd")
    done
    hyperfine "${HYPERFINE_ARGS[@]}" || echo "NOTE: fast-tier hyperfine reported a failing language (ignored; others kept)."
fi

if [ ${#SLOW_TIER[@]} -gt 0 ]; then
    echo ""
    echo "=== SLOW TIER (reduced budget: warmup=$SLOW_WARMUP runs=$SLOW_RUNS${RUN_TIMEOUT:+ timeout=${RUN_TIMEOUT}s}) : ${SLOW_TIER[*]} ==="
    HYPERFINE_ARGS=(--warmup "$SLOW_WARMUP" --runs "$SLOW_RUNS" -i --export-json "$SLOW_JSON")
    for lang in "${SLOW_TIER[@]}"; do
        cmd=$(build_cmd "$lang" "$BENCH")
        log_file="$RSS_DIR/${BENCH}_${lang}.log"; rm -f "$log_file"
        HYPERFINE_ARGS+=(-n "$lang" "$TIMEOUT_BIN bash $SCRIPT_DIR/wrap_rss.sh $log_file $cmd")
    done
    hyperfine "${HYPERFINE_ARGS[@]}" || echo "NOTE: slow-tier hyperfine returned non-zero (ignored)."
fi

# Merge fast + slow result arrays into the canonical <bench>.json.
# With MERGE=1, existing entries for languages NOT in this run are preserved, so
# you can re-run a single language (e.g. rust) without discarding the others.
MERGE="${MERGE:-0}" python3 - "$RESULT_FILE" "${LANGUAGES[*]}" "$FAST_JSON" "$SLOW_JSON" << 'PY'
import json, os, sys
out, langs_str = sys.argv[1], sys.argv[2]
parts = sys.argv[3:]
cur_langs = set(langs_str.split())
results = []
if os.environ.get("MERGE") == "1" and os.path.exists(out):
    try:
        existing = json.load(open(out)).get("results", [])
        results += [r for r in existing if r.get("command") not in cur_langs]
    except Exception: pass
for p in parts:
    if p and os.path.exists(p):
        try: results += json.load(open(p)).get("results", [])
        except Exception: pass
json.dump({"results": results}, open(out, "w"), indent=2)
print(f"merged {len(results)} language result(s) -> {out}"
      + (" (merge mode: preserved other languages)" if os.environ.get("MERGE")=="1" else ""))
PY

# ── Aggregate RSS logs into <bench>_memory.json ───────────────────────
echo ""
echo "=== MEMORY (aggregated from inline RSS capture) ==="
MERGE_FLAG=""; [ "${MERGE:-0}" = "1" ] && MERGE_FLAG="--merge"
python3 "$SCRIPT_DIR/rss_log_to_json.py" "$BENCH" --rss-dir "$RSS_DIR" --langs "${LANGUAGES[@]}" $MERGE_FLAG

echo ""
echo "=== DONE ==="
echo "M1 timing: $RESULT_FILE"
echo "M2 memory: $RESULTS/${BENCH}_memory.json"

