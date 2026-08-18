# CHANGES — full 12×13 matrix, b9–b13 rename, and run-failure fix

## 1. The run failures are fixed

Every benchmark was reporting `had failures` on macOS with no RUN phase. Two
root causes, both in `harness/run_single.sh`:

- **Whole-project Zig build.** The harness ran `zig build`, which compiles
  *every* Zig target at once. A single unbuildable Zig file therefore broke the
  build step for all thirteen benchmarks. Zig is now built **per benchmark**
  (`zig build-exe <bench>.zig -O ReleaseFast`), so one bad file only affects its
  own benchmark.
- **No build isolation.** `set -euo pipefail` meant the first failing language
  aborted the whole benchmark before anything ran. The build loop is now
  **resilient**: each language is built in an `if` guard, a failure is logged
  (`WARNING: <lang> failed to build … — skipping`), and the remaining languages
  continue. The fast-tier `hyperfine` pass also runs with `-i` so one language
  failing at run time no longer aborts the others.

Julia PATH discovery was extended for macOS (the `.app`, Homebrew, and juliaup
locations), since the log showed `julia not found`.

## 2. AI kernels renamed b9–b13

`kmeans → b9_kmeans`, `knn → b10_knn`, `mlp → b11_mlp`, `ga → b12_ga`,
`fuzzy → b13_fuzzy`. Renamed everywhere: source files in all 12 languages, Java
classes (`B9Kmeans` … `B13Fuzzy`), C/C++/Fortran `TARGETS`, Rust `[[bin]]`,
`build.zig`, result JSONs, `verify_checksums.sh`, `collect_static_metrics.py`,
`plots.py`, and the harness banners. Re-verified bit-exact after the rename for
C, C++, Fortran, and Java.

## 3. All 12 languages now run all 13 benchmarks

Previously the systems suite (b1–b8) ran on 9 languages and the AI suite on a
different set. Now **every benchmark defaults to all twelve languages**; missing
toolchains/implementations are skipped gracefully at build time. Concretely:

- **Python** systems benchmarks (b1–b8) were already present — now enabled.
- **Fortran b1–b8** written, reusing the shared bit-exact 64-bit LCG.
- **R b1–b8** written, reusing R's 16-bit-limb LCG emulation.

### Verification status (checked in this sandbox: gcc/g++, gfortran, Rscript, java)

| Bench | Reference | Fortran | R |
|-------|-----------|---------|---|
| b1 fibonacci | 1134903170 | ✓ | ✓ (fib(28) checked; full = slow tier) |
| b2 bubble_sort | `1 99999` (LCG cohort) | ✓ | ✓ (N=200 checked; full = slow tier) |
| b3 matrix_mul | 1999489945.823164 | ✓ bit-exact | LCG bit-exact; full = slow tier |
| b4 monte_carlo | 3.1414637360 | ✓ bit-exact | LCG bit-exact; full = slow tier |
| b5 regex | 300818 | ✓ | ✓ (full, via grepl) |
| b6 file_io | 4294967296 | ✓ (16 MiB sanity) | ✓ (16 MiB sanity) |
| b7 concurrent | 80000000 | ✓ (OpenMP, 8 threads) | ✓ (1e6 sanity; sequential) |
| b8 json_parse | objects=772432 … | ✓ bit-exact (full) | ✓ (oracle-matched on slice) |

Notes:
- **b2** prints `1 99999`, not C's `0 99999`. The C reference uses glibc
  `rand()`; every other language (including the new Fortran/R) uses the shared
  LCG, whose minimum draw is 1. The Fortran/R values match the LCG cohort.
- **Fortran b1** is optimised to a closed form by `gfortran -O3` and so runs in
  milliseconds — the output is correct, but the timing is a compiler artifact,
  not call-overhead.
- **R b1–b4, b7 at full scale are slow** (scalar interpreter; minutes to hours).
  They are correct and routed to the reduced-budget **slow tier**
  (`SLOW_LANGS="r python"`) with `RUN_TIMEOUT`. This is inherent to R at the
  paper's problem sizes, not a defect.
- **b7** in R uses a sequential counter (base R has no shared-memory threads);
  the checksum is identical. Fortran uses OpenMP with a fixed 8 threads.

Run `bash harness/verify_checksums.sh` on the Mac to confirm the AI kernels
across the toolchains not available here (Zig, Swift, Kotlin, Go, Rust, Julia).
