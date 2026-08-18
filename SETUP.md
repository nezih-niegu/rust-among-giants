# Setup — Rust Among Giants reproducibility recipe

This document explains how to reproduce the benchmarks on an Apple
M1 Mac. The repo is intentionally **not** containerised: a Docker
build on M1 runs inside a Linux VM under Rosetta, which would
invalidate every M1-ARM64 wall-time and RSS measurement reported
in the paper. The artifact track of the paper (separate) includes
a Linux `Dockerfile` for methodology checks only, not for
reproducing the numbers.

## Hardware

- Apple MacBook (M1, M1 Pro, M1 Max, M2, or M3) with 16 GB+ unified memory
- ≥ 50 GB free SSD (B6 writes a 4 GiB checkpoint file; the toolchain caches together occupy ~20 GiB)
- macOS Sonoma (14.x) or later

x86-64 macOS and Linux are **not** validated. The paper's reported
numbers are M1 ARM64 specific.

## One-shot install

```bash
# Xcode command-line tools (C, C++, Swift come pre-installed with this)
xcode-select --install

# Homebrew (skip if already installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Compiled and JIT-compiled languages — pinned versions in versions.txt
brew install \
    go \
    zig@0.14 \
    openjdk \
    kotlin \
    julia \
    gcc \
    r \
    hyperfine

# Rust via rustup (brew rust lags multiple stable releases)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source "$HOME/.cargo/env"
rustup install stable
rustup default stable

# Python venv for analysis/plots only (no benchmark depends on Python)
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

## Pinned versions used in the paper

See `versions.txt` for the exact versions. Re-running `brew install`
without version pins picks up upgrades automatically; if you need
the exact versions from the paper, pin via Homebrew's
`brew extract` workflow or use the artifact-track Dockerfile.

## PATH setup

Some Homebrew formulae are keg-only on M1. The harness scripts
already prepend these in their `PATH`, but if you run binaries
manually:

```bash
export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"
export PATH="/opt/homebrew/opt/zig@0.14/bin:$PATH"
```

## Running the suite

```bash
# Generate B5/B8 data (LCG-driven; deterministic)
python3 harness/generate_data.py

# Full sweep across both suites. R runs in a reduced-budget slow tier so it
# can't stall warmups; cap any slow run with RUN_TIMEOUT=<seconds> if needed.
bash harness/run_all.sh

# Limit scope, e.g. just the AI suite on the fast native set:
BENCHES='kmeans knn mlp ga fuzzy' LANGS='c cpp rust go fortran java' bash harness/run_all.sh

# A single benchmark on a single language
bash harness/run_single.sh mlp c fortran java

# Static metrics (M3 binary size, M4 LOC, M5 compile time)
python3 harness/collect_static_metrics.py

# Figures
python3 analysis/plots.py
```

## Smoke tests

```bash
# AI-kernel checksums — confirm bit-exactness across languages
bash harness/verify_checksums.sh c cpp fortran java   # the fast verified set
# expected: kmeans 559268 20.004093 | knn 8603 | mlp 0.085671 7.648975
#           ga 24.460672 4.216343   | fuzzy 999999.524374
```

## Known platform limitations

- `b6_file_io` `fsync` on APFS flushes to the SSD device-cache,
  not to physical media. Linux ext4 `fsync` is stricter; expect
  ~2× wall time on Linux. Relative rankings across languages are
  unchanged.
- The Swift B6 4 GiB RSS spike is a property of Foundation's
  `FileHandle.readData(ofLength:)` and reproduces on any Apple
  hardware; it is documented as a finding in the paper, not as a
  measurement bug.
- The AI kernels are intentionally scalar (no BLAS), so the
  interpreted tiers are slow at full scale: R is routed to a
  reduced-budget slow tier automatically, and Python takes minutes
  per kernel. Use `RUNS=3 WARMUP=1` (and `RUN_TIMEOUT=<s>` for the
  slow tier) during development.
- Zig, Swift, and Kotlin AI kernels are written to the shared
  contract but were not verified on this build host; run
  `bash harness/verify_checksums.sh zig swift kotlin` once those
  toolchains are installed to confirm bit-exactness.

## Optional: Docker for artifact-track methodology check

If the ICSE artifact reviewer wants to verify the methodology on
Linux without M1 hardware, see `artifact/Dockerfile` (Linux
x86\_64). The numbers in that environment will not match the
paper; only the structural correctness of the harness, scripts,
and outputs is verified.
