#!/usr/bin/env python3
"""Collect the three non-runtime metrics (M3, M4, M5) for all 9 languages × 8 benchmarks.

Outputs three JSON files in results/:
  - m3_binary_size.json   : per (lang, bench) compiled-artifact size in bytes
  - m4_loc.json           : per (lang, bench) implementation lines of code
  - m5_compile_time.json  : per language total clean-build wall time in seconds

All outputs use the same {"results": [{"command": "<lang>", ...}, ...]} shape as
the hyperfine JSONs (and our wrap_rss aggregator), so downstream analysis can
look entries up by language name rather than by position — robust against the
fact that some prior runs had julia in the middle of the language list and
others (post-2026-05-30) have it at the end.

Methodology:
  M3: stat() of the executable / .class / .jar produced by each toolchain.
      Julia has no compiled artifact; reported as null.
  M4: wc -l of the *implementation* source file only. Excludes vendor/ (cJSON,
      nlohmann::json), Cargo.toml/Makefile/build.zig, and Java's per-bench
      class file references. For Rust, counts `src/<bench>.rs` only — not the
      shared dependency manifest.
  M5: total wall time of a clean build of all 8 benchmarks per language,
      measured via /usr/bin/time on the build command after wiping the
      language's build cache. Per-bench timing is not reported because Rust
      and Zig share dependency compilation across benchmarks (would make
      per-bench numbers misleading); the total-clean-build figure is the
      honest measure of "developer iteration speed" claimed by the README.
      Julia has no build step (interpreted) → reported as null.
"""
import json
import os
import subprocess
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
BENCHMARKS = ROOT / "benchmarks"
RESULTS = ROOT / "results"
RESULTS.mkdir(exist_ok=True)

LANGUAGES = ["c", "cpp", "rust", "go", "fortran", "java", "zig", "swift", "kotlin", "python", "julia", "r"]
SYSTEMS_BENCHES = [
    "b1_fibonacci", "b2_bubble_sort", "b3_matrix_mul", "b4_monte_carlo",
    "b5_regex", "b6_file_io", "b7_concurrent", "b8_json_parse",
]
AI_BENCHES = ["b9_kmeans", "b10_knn", "b11_mlp", "b12_ga", "b13_fuzzy"]
BENCHES = SYSTEMS_BENCHES + AI_BENCHES

# Which (language, benchmark) cells exist. The systems suite (b1-b8) is the
# ICSE nine; the AI suite adds Fortran, Python, and R (COBOL is retired).
ALL_TWELVE = {"c", "cpp", "rust", "go", "fortran", "java", "zig", "swift", "kotlin", "python", "julia", "r"}
SYSTEMS_LANGS = ALL_TWELVE
AI_LANGS = ALL_TWELVE

def implements(lang: str, bench: str) -> bool:
    # Every language now implements every benchmark.
    return lang in ALL_TWELVE

# bench id -> Java class basename
JAVA_CLASS = {
    "b1_fibonacci": "B1Fibonacci", "b2_bubble_sort": "B2BubbleSort",
    "b3_matrix_mul": "B3MatrixMul", "b4_monte_carlo": "B4MonteCarlo",
    "b5_regex": "B5Regex", "b6_file_io": "B6FileIO",
    "b7_concurrent": "B7Concurrent", "b8_json_parse": "B8JsonParse",
    "b9_kmeans": "B9Kmeans", "b10_knn": "B10Knn", "b11_mlp": "B11Mlp", "b12_ga": "B12Ga", "b13_fuzzy": "B13Fuzzy",
}


def artifact_path(lang: str, bench: str) -> Path | None:
    """Return the path to the compiled/distributable artifact, or None if N/A."""
    if not implements(lang, bench):
        return None
    if lang == "c":
        return BENCHMARKS / "c" / bench
    if lang == "cpp":
        return BENCHMARKS / "cpp" / bench
    if lang == "rust":
        return BENCHMARKS / "rust" / "target" / "release" / bench
    if lang == "go":
        return BENCHMARKS / "go" / bench
    if lang == "fortran":
        return BENCHMARKS / "fortran" / bench
    if lang == "java":
        return BENCHMARKS / "java" / f"{JAVA_CLASS[bench]}.class"
    if lang == "zig":
        return BENCHMARKS / "zig" / "zig-out" / "bin" / bench
    if lang == "swift":
        return BENCHMARKS / "swift" / bench
    if lang == "kotlin":
        return BENCHMARKS / "kotlin" / f"{bench}.jar"
    if lang in ("julia", "python", "r"):
        return None  # interpreted
    raise ValueError(lang)


def source_path(lang: str, bench: str) -> Path | None:
    """Return the path to the *implementation* source file (excludes vendored deps)."""
    if not implements(lang, bench):
        return None
    if lang == "c":
        return BENCHMARKS / "c" / f"{bench}.c"
    if lang == "cpp":
        return BENCHMARKS / "cpp" / f"{bench}.cpp"
    if lang == "rust":
        return BENCHMARKS / "rust" / "src" / f"{bench}.rs"
    if lang == "go":
        return BENCHMARKS / "go" / f"{bench}.go"
    if lang == "fortran":
        return BENCHMARKS / "fortran" / f"{bench}.f90"
    if lang == "java":
        return BENCHMARKS / "java" / f"{JAVA_CLASS[bench]}.java"
    if lang == "julia":
        return BENCHMARKS / "julia" / f"{bench}.jl"
    if lang == "zig":
        return BENCHMARKS / "zig" / f"{bench}.zig"
    if lang == "swift":
        return BENCHMARKS / "swift" / f"{bench}.swift"
    if lang == "kotlin":
        return BENCHMARKS / "kotlin" / f"{bench}.kt"
    if lang == "python":
        return BENCHMARKS / "python" / f"{bench}.py"
    if lang == "r":
        return BENCHMARKS / "r" / f"{bench}.R"
    raise ValueError(lang)


def count_lines(path: Path) -> int:
    with open(path, "rb") as f:
        return sum(1 for _ in f)


# ─── M3: binary size ─────────────────────────────────────────────────────
def collect_m3():
    print("=== M3 binary size ===")
    results = []
    for lang in LANGUAGES:
        entry = {"command": lang, "bytes_per_bench": {}}
        for bench in BENCHES:
            p = artifact_path(lang, bench)
            if p is None:
                entry["bytes_per_bench"][bench] = None
                continue
            if not p.exists():
                if implements(lang, bench):
                    print(f"  ⚠ missing {lang}/{bench}: {p}")
                entry["bytes_per_bench"][bench] = None
                continue
            sz = p.stat().st_size
            entry["bytes_per_bench"][bench] = sz
        sizes = [v for v in entry["bytes_per_bench"].values() if v is not None]
        entry["bytes_mean"] = sum(sizes) / len(sizes) if sizes else None
        entry["bytes_min"] = min(sizes) if sizes else None
        entry["bytes_max"] = max(sizes) if sizes else None
        print(f"  {lang:<7} mean={entry['bytes_mean']!s:>12}  min={entry['bytes_min']!s:>10}  max={entry['bytes_max']!s:>10}")
        results.append(entry)
    out = RESULTS / "m3_binary_size.json"
    with open(out, "w") as f:
        json.dump({"metric": "M3 binary size (bytes)",
                   "tool": "stat -f%z (macOS bytes)",
                   "notes": "julia has no compiled artifact (interpreted); reported as null. "
                            "Java reports the per-bench .class file; Kotlin reports the per-bench "
                            ".jar including the bundled kotlin-stdlib.",
                   "results": results}, f, indent=2)
    print(f"  → {out}\n")


# ─── M4: LOC ─────────────────────────────────────────────────────────────
def collect_m4():
    print("=== M4 lines of code ===")
    results = []
    for lang in LANGUAGES:
        entry = {"command": lang, "loc_per_bench": {}}
        for bench in BENCHES:
            p = source_path(lang, bench)
            if p is None:
                entry["loc_per_bench"][bench] = None
                continue
            if not p.exists():
                print(f"  ⚠ missing {lang}/{bench}: {p}")
                entry["loc_per_bench"][bench] = None
                continue
            entry["loc_per_bench"][bench] = count_lines(p)
        locs = [v for v in entry["loc_per_bench"].values() if v is not None]
        entry["loc_mean"] = sum(locs) / len(locs) if locs else None
        entry["loc_total"] = sum(locs) if locs else None
        print(f"  {lang:<7} total={entry['loc_total']!s:>5}  mean={entry['loc_mean']!s:>6}")
        results.append(entry)
    out = RESULTS / "m4_loc.json"
    with open(out, "w") as f:
        json.dump({"metric": "M4 lines of code (implementation only)",
                   "tool": "wc -l",
                   "notes": "Counts the per-benchmark implementation file only. Excludes vendored "
                            "deps (benchmarks/c/vendor/cJSON.{c,h} and benchmarks/cpp/vendor/json.hpp "
                            "for B8), build manifests (Cargo.toml, Makefile, build.zig), and any "
                            "shared/utility code. Comments and blank lines are counted as in any "
                            "wc-based LOC measurement — relative ranking across languages is what "
                            "matters, not absolute style-corrected SLOC.",
                   "results": results}, f, indent=2)
    print(f"  → {out}\n")


# ─── M5: compile time ───────────────────────────────────────────────────
def time_cmd(cmd: list[str] | str, cwd: Path) -> float:
    """Return wall time of `cmd` in seconds. Raises if cmd fails."""
    t0 = time.perf_counter()
    r = subprocess.run(cmd, cwd=cwd, shell=isinstance(cmd, str),
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    t1 = time.perf_counter()
    if r.returncode != 0:
        raise RuntimeError(f"build failed: {cmd}")
    return t1 - t0


def collect_m5():
    """Total cold-build wall time per language (all 8 benchmarks from clean cache)."""
    print("=== M5 compile time (cold build, all 8 benchmarks per language) ===")
    # ensure tools on PATH (same as harness/run_*.sh)
    env_path = os.environ.get("PATH", "")
    for d in ["/opt/homebrew/opt/openjdk/bin", "/opt/homebrew/opt/zig@0.14/bin"]:
        if os.path.isdir(d) and d not in env_path:
            os.environ["PATH"] = f"{d}:{env_path}"
            env_path = os.environ["PATH"]

    results = []

    def add(lang: str, seconds: float | None, notes: str = ""):
        print(f"  {lang:<7} {seconds!s:>10}s  {notes}")
        results.append({"command": lang,
                        "compile_time_s": seconds,
                        "notes": notes})

    # C — make clean && make all
    try:
        subprocess.run(["make", "clean"], cwd=BENCHMARKS / "c",
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        t = time_cmd(["make", "-j1", "all"], BENCHMARKS / "c")
        add("c", round(t, 3), "make -j1 all (clean), 8 benches")
    except Exception as e:
        add("c", None, f"FAILED: {e}")

    # C++ — make clean && make all
    try:
        subprocess.run(["make", "clean"], cwd=BENCHMARKS / "cpp",
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        t = time_cmd(["make", "-j1", "all"], BENCHMARKS / "cpp")
        add("cpp", round(t, 3), "make -j1 all (clean), 8 benches")
    except Exception as e:
        add("cpp", None, f"FAILED: {e}")

    # Rust — cargo clean && cargo build --release (all 8 bins, includes deps)
    try:
        subprocess.run(["cargo", "clean"], cwd=BENCHMARKS / "rust",
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        t = time_cmd(["cargo", "build", "--release"], BENCHMARKS / "rust")
        add("rust", round(t, 3), "cargo build --release (clean, includes regex/serde_json deps)")
    except Exception as e:
        add("rust", None, f"FAILED: {e}")

    # Go — remove binaries, build each
    try:
        go_dir = BENCHMARKS / "go"
        for b in BENCHES:
            (go_dir / b).unlink(missing_ok=True)
        # also clear Go's per-package build cache to make this a true cold build
        subprocess.run(["go", "clean", "-cache"], cwd=go_dir,
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        t0 = time.perf_counter()
        for b in BENCHES:
            r = subprocess.run(["go", "build", "-o", b, f"{b}.go"], cwd=go_dir,
                               stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            if r.returncode != 0:
                raise RuntimeError(f"go build failed for {b}")
        t = time.perf_counter() - t0
        add("go", round(t, 3), "go clean -cache + per-bench go build, 8 benches")
    except Exception as e:
        add("go", None, f"FAILED: {e}")

    # Java — rm *.class && javac per file
    try:
        java_dir = BENCHMARKS / "java"
        for p in java_dir.glob("*.class"):
            p.unlink()
        t0 = time.perf_counter()
        for b in BENCHES:
            r = subprocess.run(["javac", f"{JAVA_CLASS[b]}.java"], cwd=java_dir,
                               stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            if r.returncode != 0:
                raise RuntimeError(f"javac failed for {b}")
        t = time.perf_counter() - t0
        add("java", round(t, 3), "javac per file (clean), 8 benches")
    except Exception as e:
        add("java", None, f"FAILED: {e}")

    # Zig — wipe cache, zig build (builds all)
    try:
        zig_dir = BENCHMARKS / "zig"
        import shutil
        shutil.rmtree(zig_dir / "zig-out", ignore_errors=True)
        shutil.rmtree(zig_dir / ".zig-cache", ignore_errors=True)
        t = time_cmd(["zig", "build"], zig_dir)
        add("zig", round(t, 3), "zig build (clean cache), 8 benches whole-project")
    except Exception as e:
        add("zig", None, f"FAILED: {e}")

    # Swift — rm binaries, swiftc per file
    try:
        swift_dir = BENCHMARKS / "swift"
        for b in BENCHES:
            (swift_dir / b).unlink(missing_ok=True)
        t0 = time.perf_counter()
        for b in BENCHES:
            r = subprocess.run(["swiftc", "-O", "-o", b, f"{b}.swift"], cwd=swift_dir,
                               stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            if r.returncode != 0:
                raise RuntimeError(f"swiftc failed for {b}")
        t = time.perf_counter() - t0
        add("swift", round(t, 3), "swiftc -O per file (clean), 8 benches")
    except Exception as e:
        add("swift", None, f"FAILED: {e}")

    # Kotlin — rm jars, kotlinc per file (slow)
    try:
        kt_dir = BENCHMARKS / "kotlin"
        for b in BENCHES:
            (kt_dir / f"{b}.jar").unlink(missing_ok=True)
        t0 = time.perf_counter()
        for b in BENCHES:
            r = subprocess.run(
                ["kotlinc", f"{b}.kt", "-include-runtime", "-d", f"{b}.jar"],
                cwd=kt_dir, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            if r.returncode != 0:
                raise RuntimeError(f"kotlinc failed for {b}")
        t = time.perf_counter() - t0
        add("kotlin", round(t, 3), "kotlinc per file with -include-runtime (clean), 8 benches")
    except Exception as e:
        add("kotlin", None, f"FAILED: {e}")

    # Fortran — make clean && make all (AI benchmarks only)
    try:
        fortran_dir = BENCHMARKS / "fortran"
        subprocess.run(["make", "clean"], cwd=fortran_dir,
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        t = time_cmd(["make", "-j1", "all"], fortran_dir)
        add("fortran", round(t, 3), "make -j1 all (clean), 5 AI benches (gfortran -O3 -ffp-contract=off)")
    except Exception as e:
        add("fortran", None, f"FAILED: {e}")

    # Interpreted tiers — no compile step
    add("julia", None, "interpreted; no AOT compile step (JIT cost included in M1 wall time)")
    add("python", None, "interpreted; no compile step")
    add("r", None, "interpreted; no compile step")

    out = RESULTS / "m5_compile_time.json"
    with open(out, "w") as f:
        json.dump({"metric": "M5 cold-build wall time (seconds, total per language for all 8 benchmarks)",
                   "tool": "time.perf_counter wrapping subprocess.run on the build command",
                   "notes": "Per-language totals rather than per-benchmark because Rust and Zig share "
                            "dependency compilation across benchmarks — per-benchmark figures would "
                            "be dominated by where each dep happened to land in the build order. The "
                            "total cold-build measurement matches the developer-experience claim of "
                            "the M5 metric (cargo clean / make clean / zig cache wipe between runs).",
                   "results": results}, f, indent=2)
    print(f"  → {out}\n")


if __name__ == "__main__":
    collect_m3()
    collect_m4()
    collect_m5()
    print("Done.")
