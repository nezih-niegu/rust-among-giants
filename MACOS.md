# Running on macOS

This is the macOS-tuned edition. It targets Apple Silicon (M-series) and Intel
Macs with Homebrew, and is the platform the paper's headline numbers come from.

## One-shot setup + build

```bash
bash install.sh          # installs every toolchain via Homebrew, then builds all
bash install.sh --verify # ...and confirms the AI checksums after building
```

`install.sh` detects macOS, bootstraps Homebrew if needed, installs all twelve
toolchains, and (because `brew install openjdk` / `zig@0.14` are keg-only) puts
`javac` and `zig` on `PATH` for the build phase automatically.

## Manual setup (if you prefer)

```bash
# C/C++ and Swift ship with the Xcode command-line tools
xcode-select --install

# Rust via rustup (brew's rust lags stable)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# Everything else
brew install go zig@0.14 openjdk kotlin julia gcc r hyperfine
#   gcc      → provides gfortran for the AI suite
#   openjdk  → keg-only; the harness adds /opt/homebrew/opt/openjdk/bin to PATH
#   zig@0.14 → keg-only; pinned (0.15+ changed the build API)
```

## Run

```bash
# Generate the data the systems benchmarks B5/B8 need
python3 harness/generate_data.py

# Full sweep (both suites). R is auto-routed to a reduced-budget slow tier.
bash harness/run_all.sh

# Scope it down, e.g. the AI suite on the fast native set:
BENCHES='kmeans knn mlp ga fuzzy' LANGS='c cpp rust go fortran java swift zig kotlin' \
  bash harness/run_all.sh

# Confirm cross-language bit-exactness of the AI kernels
bash harness/verify_checksums.sh
```

## macOS-specific notes

- **Peak memory** is captured with BSD `/usr/bin/time -l`, which reports
  `maximum resident set size` in **bytes**; the harness selects this
  automatically on Darwin (Linux uses GNU `time -v`, kbytes×1024).
- **Apple Silicon Fortran:** Homebrew GCC rejects `-march=native` on arm64, so
  `benchmarks/fortran/Makefile` switches to `-mcpu=native` when `uname -m` is
  `arm64`. Bit-exactness comes from `-ffp-contract=off`, which is unconditional.
- **`RUN_TIMEOUT`** (slow-tier wall cap) uses `gtimeout` if present
  (`brew install coreutils`) and otherwise no-ops gracefully — macOS has no
  built-in `timeout`.
- **Swift `FileHandle` B6 anomaly** (the ~4 GiB resident spike) is a documented
  Foundation behaviour on Apple platforms, reported as a finding, not a bug.

## AI-kernel verification status

C, C++, Rust, Go, Fortran, Java, Python, Julia, and R are checksum-verified
bit-exact. The **Zig, Swift, and Kotlin** AI kernels were written to the same
LCG/IEEE-754 contract but have not yet been verified on their native
toolchains. On your Mac, confirm them with:

```bash
bash harness/verify_checksums.sh zig swift kotlin
```

Expected outputs: `kmeans 559268 20.004093` · `knn 8603` ·
`mlp 0.085671 7.648975` · `ga 24.460672 4.216343` · `fuzzy 999999.524374`.
The most likely place for a last-digit difference is Zig's `{d:.6}` float
formatting; Swift uses C `printf` and Kotlin uses `BigDecimal` HALF_EVEN, both
of which match C's rounding.
