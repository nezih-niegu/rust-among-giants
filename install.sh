#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════════════════════
# install.sh — one-shot toolchain installer + builder for the merged benchmark
# suite: 8 systems benchmarks (b1-b8) + 5 AI benchmarks (kmeans/knn/mlp/ga/fuzzy).
#
# After this script, `bash harness/run_all.sh` works on a clean machine.
#
# Twelve languages, four tiers:
#   native compiled : C, C++, Rust, Go, Zig, Fortran
#   JVM             : Java, Kotlin
#   reference-count : Swift
#   interpreted/JIT : Python, Julia, R
# (COBOL has been retired from this repo.)
#
# Supported hosts:
#   - macOS (Homebrew)            — the platform the paper's timings come from
#   - Debian/Ubuntu Linux (apt)   — for CI / portable re-verification
#
# Usage:
#   bash install.sh                # install all toolchains, then build all
#   bash install.sh --no-build     # install toolchains only (skip compilation)
#   bash install.sh --verify       # after building, check every checksum
#
# Idempotent: anything already present is skipped. On Linux a few toolchains
# (Zig, Swift, Kotlin) are not always packaged in apt; the script makes a
# best effort and prints a clear hint if it cannot install one automatically.
# ════════════════════════════════════════════════════════════════════════════
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BENCHMARKS="$ROOT/benchmarks"

DO_BUILD=1
DO_VERIFY=0
for arg in "$@"; do
    case "$arg" in
        --no-build) DO_BUILD=0 ;;
        --verify)   DO_VERIFY=1 ;;
        -h|--help)  sed -n '2,34p' "$0"; exit 0 ;;
        *) echo "unknown option: $arg" >&2; exit 1 ;;
    esac
done

say()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m  \xe2\x9c\x93\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m  ! \033[0m%s\n' "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }

OS="$(uname -s)"
PKG=""
if [ "$OS" = "Darwin" ]; then PKG="brew"
elif [ "$OS" = "Linux" ] && have apt-get; then PKG="apt"
else
    echo "Unsupported platform: $OS (need macOS+Homebrew or Debian/Ubuntu+apt)." >&2
    echo "Install the twelve toolchains manually; see SETUP.md." >&2
    exit 1
fi
say "Platform: $OS  (package manager: $PKG)"

SUDO=""
if [ "$PKG" = "apt" ] && [ "$(id -u)" -ne 0 ]; then
    have sudo && SUDO="sudo" || { echo "Need root or sudo for apt." >&2; exit 1; }
fi

if [ "$PKG" = "brew" ] && ! have brew; then
    say "Installing Homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    [ -d /opt/homebrew/bin ] && eval "$(/opt/homebrew/bin/brew shellenv)"
fi
apt_install() { $SUDO apt-get install -y --no-install-recommends "$@"; }
[ "$PKG" = "apt" ] && $SUDO apt-get update -qq || true

# ── C / C++ ─────────────────────────────────────────────────────────────────
say "C / C++ toolchain"
if [ "$PKG" = "brew" ]; then
    have cc && have c++ || xcode-select --install || true
    ok "Apple Clang (Xcode command-line tools)"
else
    apt_install build-essential && ok "gcc / g++ (build-essential)"
fi

# ── Fortran ─────────────────────────────────────────────────────────────────
say "Fortran (gfortran)"
if have gfortran; then ok "gfortran present"
elif [ "$PKG" = "brew" ]; then brew install gcc && ok "gfortran (Homebrew gcc)"
else apt_install gfortran && ok "gfortran"; fi

# ── R ───────────────────────────────────────────────────────────────────────
say "R (Rscript)"
if have Rscript; then ok "Rscript present"
elif [ "$PKG" = "brew" ]; then brew install r && ok "R (Homebrew)"
else apt_install r-base-core && ok "r-base-core"; fi

# ── Go ──────────────────────────────────────────────────────────────────────
say "Go"
if have go; then ok "go present"
elif [ "$PKG" = "brew" ]; then brew install go && ok "go (Homebrew)"
else apt_install golang-go && ok "golang-go"; fi

# ── Java (JDK) ──────────────────────────────────────────────────────────────
say "Java (JDK)"
if have javac; then ok "javac present"
elif [ "$PKG" = "brew" ]; then brew install openjdk && ok "openjdk (Homebrew)"
else apt_install default-jdk && ok "default-jdk"; fi

# ── Kotlin ──────────────────────────────────────────────────────────────────
say "Kotlin (kotlinc)"
if have kotlinc; then ok "kotlinc present"
elif [ "$PKG" = "brew" ]; then brew install kotlin && ok "kotlin (Homebrew)"
elif have snap; then $SUDO snap install --classic kotlin && ok "kotlin (snap)"
else warn "Install Kotlin manually (SDKMAN: 'sdk install kotlin') — not in apt."; fi

# ── Zig ─────────────────────────────────────────────────────────────────────
say "Zig"
if have zig; then ok "zig present"
elif [ "$PKG" = "brew" ]; then brew install zig && ok "zig (Homebrew)"
else warn "Install Zig manually from https://ziglang.org/download (0.14.x) — not in apt."; fi

# ── Swift ───────────────────────────────────────────────────────────────────
say "Swift (swiftc)"
if have swiftc; then ok "swiftc present"
elif [ "$PKG" = "brew" ]; then brew install swift 2>/dev/null && ok "swift (Homebrew)" || ok "Swift ships with Xcode on macOS"
else warn "Install Swift manually from https://swift.org/install (or 'swiftly') — not in apt."; fi

# ── Rust (rustup — brew's rust lags several stable releases) ─────────────────
say "Rust"
if have cargo; then ok "cargo present"
else
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    # shellcheck disable=SC1091
    . "$HOME/.cargo/env"; rustup default stable; ok "rust (rustup)"
fi

# ── hyperfine ───────────────────────────────────────────────────────────────
say "hyperfine (benchmark timer)"
if have hyperfine; then ok "hyperfine present"
elif [ "$PKG" = "brew" ]; then brew install hyperfine && ok "hyperfine (Homebrew)"
else
    apt_install hyperfine 2>/dev/null && ok "hyperfine" || {
        have cargo && cargo install hyperfine && ok "hyperfine (cargo)" \
            || warn "Install hyperfine manually to run timing sweeps."; }
fi

# ── GNU time (for inline RSS capture on Linux) ──────────────────────────────
say "GNU time (peak-RSS capture)"
if [ -x /usr/bin/time ]; then ok "/usr/bin/time present"
elif [ "$PKG" = "apt" ]; then apt_install time && ok "time"; fi

# ── Python venv for analysis/plots ──────────────────────────────────────────
say "Python analysis environment"
if have python3; then
    python3 -m venv "$ROOT/.venv"
    # shellcheck disable=SC1091
    . "$ROOT/.venv/bin/activate"
    pip install --quiet --upgrade pip
    [ -f "$ROOT/requirements.txt" ] && pip install --quiet -r "$ROOT/requirements.txt"
    deactivate
    ok "Python venv at .venv (matplotlib/numpy for plots)"
else
    warn "python3 not found; install it for the AI Python benchmarks and plots."
fi

# ── On macOS, brew openjdk and zig@0.14 are keg-only: put them on PATH so the
#    build phase (and later run_all.sh) can find javac / zig.
if [ "$PKG" = "brew" ]; then
    [ -d /opt/homebrew/opt/openjdk/bin ] && export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"
    [ -d /opt/homebrew/opt/zig@0.14/bin ] && export PATH="/opt/homebrew/opt/zig@0.14/bin:$PATH"
    [ -d /usr/local/opt/openjdk/bin ] && export PATH="/usr/local/opt/openjdk/bin:$PATH"   # Intel Macs
    [ -d /usr/local/opt/zig@0.14/bin ] && export PATH="/usr/local/opt/zig@0.14/bin:$PATH"
fi

# ── Build every compiled benchmark (verifies each toolchain) ────────────────
if [ "$DO_BUILD" -eq 1 ]; then
    say "Building all compiled benchmarks (systems b1-b8 + AI)"
    ( cd "$BENCHMARKS/c"   && make all >/dev/null && ok "C" ) || warn "C build had issues"
    ( cd "$BENCHMARKS/cpp" && make all >/dev/null && ok "C++" ) || warn "C++ build had issues"
    ( cd "$BENCHMARKS/fortran" && make all >/dev/null && ok "Fortran (AI)" ) || warn "Fortran build had issues"
    if have cargo; then ( cd "$BENCHMARKS/rust" && cargo build --release >/dev/null 2>&1 && ok "Rust" ); else warn "cargo missing; skipped Rust"; fi
    if have go; then ( cd "$BENCHMARKS/go" && for f in *.go; do [ "$f" = "go.mod" ] || go build -o "${f%.go}" "$f"; done && ok "Go" ); else warn "go missing; skipped Go"; fi
    if have javac; then ( cd "$BENCHMARKS/java" && javac *.java && ok "Java" ); else warn "javac missing; skipped Java"; fi
    if have zig; then ( cd "$BENCHMARKS/zig" && zig build >/dev/null 2>&1 && ok "Zig" ); else warn "zig missing; skipped Zig"; fi
    if have swiftc; then ( cd "$BENCHMARKS/swift" && for f in *.swift; do swiftc -O -o "${f%.swift}" "$f"; done && ok "Swift" ); else warn "swiftc missing; skipped Swift"; fi
    if have kotlinc; then ( cd "$BENCHMARKS/kotlin" && for f in *.kt; do kotlinc "$f" -include-runtime -d "${f%.kt}.jar" 2>/dev/null; done && ok "Kotlin" ); else warn "kotlinc missing; skipped Kotlin"; fi
    ok "Interpreted tiers (Python, Julia, R) need no build"
fi

if [ "$DO_VERIFY" -eq 1 ]; then
    say "Verifying AI cross-language checksums"
    bash "$ROOT/harness/verify_checksums.sh" || warn "checksum verification reported differences"
fi

say "Done."
echo "Next:  bash harness/run_all.sh                       # full sweep (13 benchmarks)"
echo "       bash harness/run_all.sh   (BENCHES='kmeans mlp' LANGS='c rust java')"
echo "       bash harness/run_single.sh mlp c fortran java # quick subset"
echo "       bash harness/verify_checksums.sh              # confirm identical AI outputs"
