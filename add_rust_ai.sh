#!/bin/bash
# Self-contained: rebuilds the Rust AI bins (b9-b13) and merges their timing +
# memory into the existing results/, WITHOUT re-running the other languages.
# Run from the ICSE root:  bash add_rust_ai.sh
set -uo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
RUST="$ROOT/benchmarks/rust"
RESULTS="$ROOT/results"
RSS="$ROOT/.rss-tmp"; mkdir -p "$RSS"
WARMUP="${WARMUP:-3}"; RUNS="${RUNS:-10}"

# 1) Ensure Cargo.toml is correct (AI bins point at the renamed sources).
cat > "$RUST/Cargo.toml" <<'TOML'
[package]
name = "rust-benchmarks"
version = "0.1.0"
edition = "2024"

[[bin]]
name = "b1_fibonacci"
path = "src/b1_fibonacci.rs"
[[bin]]
name = "b2_bubble_sort"
path = "src/b2_bubble_sort.rs"
[[bin]]
name = "b3_matrix_mul"
path = "src/b3_matrix_mul.rs"
[[bin]]
name = "b4_monte_carlo"
path = "src/b4_monte_carlo.rs"
[[bin]]
name = "b5_regex"
path = "src/b5_regex.rs"
[[bin]]
name = "b6_file_io"
path = "src/b6_file_io.rs"
[[bin]]
name = "b7_concurrent"
path = "src/b7_concurrent.rs"
[[bin]]
name = "b8_json_parse"
path = "src/b8_json_parse.rs"

[[bin]]
name = "b9_kmeans"
path = "src/b9_kmeans.rs"
[[bin]]
name = "b10_knn"
path = "src/b10_knn.rs"
[[bin]]
name = "b11_mlp"
path = "src/b11_mlp.rs"
[[bin]]
name = "b12_ga"
path = "src/b12_ga.rs"
[[bin]]
name = "b13_fuzzy"
path = "src/b13_fuzzy.rs"

[dependencies]
regex = "1"
serde = { version = "1", features = ["derive"] }
serde_json = "1"

[profile.release]
opt-level = 3
lto = true
codegen-units = 1
TOML

for b in b9_kmeans b10_knn b11_mlp b12_ga b13_fuzzy; do
    echo "=== $b (rust) ==="
    if ! ( cd "$RUST" && cargo build --release --bin "$b" 2>&1 | tail -2 ); then
        echo "  build FAILED for $b; skipping."; continue
    fi
    BIN="$RUST/target/release/$b"
    LOG="$RSS/${b}_rust.log"; : > "$LOG"
    JSON="$RSS/${b}.rust.json"
    hyperfine --warmup "$WARMUP" --runs "$RUNS" -i --export-json "$JSON" \
        -n rust "bash $ROOT/harness/wrap_rss.sh $LOG $BIN"
    # merge timing (replace any existing rust entry, keep all other languages)
    python3 - "$RESULTS/$b.json" "$JSON" <<'PY'
import json,sys,os
out,newp=sys.argv[1],sys.argv[2]
res=[]
if os.path.exists(out):
    res=[r for r in json.load(open(out)).get("results",[]) if r.get("command")!="rust"]
res+=json.load(open(newp)).get("results",[])
json.dump({"results":res},open(out,"w"),indent=2)
print(f"  timing merged -> {out} ({len(res)} languages)")
PY
    # merge memory
    python3 - "$RESULTS/${b}_memory.json" "$LOG" <<'PY'
import json,sys,os,statistics
out,log=sys.argv[1],sys.argv[2]
res=[]
if os.path.exists(out):
    res=[r for r in json.load(open(out)).get("results",[]) if r.get("command")!="rust"]
s=[int(x) for x in open(log) if x.strip()]
if s:
    res.append({"command":"rust","rss_bytes_mean":statistics.mean(s),
                "rss_bytes_stdev":(statistics.stdev(s) if len(s)>1 else 0.0),
                "rss_bytes_min":min(s),"rss_bytes_max":max(s),
                "n_samples":len(s),"samples_bytes":s})
    json.dump({"results":res},open(out,"w"),indent=2)
    print(f"  memory merged -> {out} ({len(res)} languages)")
else:
    print("  (no RSS samples captured for rust)")
PY
done
echo "=== DONE: rust b9-b13 merged into results/ ==="
