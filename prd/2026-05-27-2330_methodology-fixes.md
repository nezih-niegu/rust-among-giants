# Methodology Fixes Before First Benchmark Run

**Date:** 2026-05-27
**Status:** Implemented (pre-smoke-test)

## Goal

Resolve four methodology defects in the benchmark suite that would either bias results or render them indefensible at peer review, before committing to a multi-hour benchmark sweep that would otherwise have to be re-run.

## Background

Project: Rust Among Giants — MICAI 2026 paper benchmarking 10 languages × 8 tasks × 5 metrics, submission deadline 2026-06-14. PAPER_PLAN.md budgets 2026-05-28 through 2026-05-30 for running benchmarks. Discovered four defects during initial code review of the benchmark implementations:

1. **B7 (concurrent counter) was not measuring equivalent work across languages.** C, C++, Rust, Go, Java, Kotlin, Julia did a real hardware atomic add per iteration (80M contended atomic ops). Swift and Python instead accumulated into a per-thread local variable and acquired a mutex only once at the end — measuring 80M local adds + 8 mutex acquisitions. Different work, unfair comparison, a reviewer would catch this immediately.

2. **B2 (bubble sort) was sized at N=10⁶ integers.** O(N²) = ~5×10¹¹ comparisons. C measured at 7.5s with N=10⁵; extrapolated, Python at N=10⁶ would have taken many hours per run, ×13 hyperfine runs = days. Even Bugden & Alahmar (2022) reported Python at 654s for their bubble sort, suggesting they used a smaller N.

3. **`Cargo.toml` declared `edition = "2021"`** while the README and paper both claimed Rust 2024 edition (released Feb 2025 with Rust 1.85).

4. **`aggregate_results.py` parsed language names by string-splitting the hyperfine command field.** This misparses any command with arguments or path slashes — e.g. `python3 /full/path/b1_fibonacci.py` extracted as `b1_fibonacci.py`. Since `run_all.sh` already passes `-n <lang>` to hyperfine, the bare name is already in the JSON `command` field; the parser is unnecessary.

## Requirements (acceptance criteria)

- All 10 B7 implementations must measure equivalent work: each iteration performs one synchronization operation on a shared counter.
- All 10 B2 implementations use the same N constant; total runtime per benchmark run is bounded (target: <30 min for the slowest language).
- `Cargo.toml` edition matches the documentation claim.
- `aggregate_results.py` produces a CSV where the `language` column contains the canonical language slug (`c`, `cpp`, `rust`, …) for every row produced by `run_all.sh` and `run_single.sh`.
- All affected docs (README benchmark table, paper Table 2) reflect the new N.

## Technical approach

### B7 fairness

- **Swift:** `OSAtomicAdd64(1, &counter)` per iteration. From `libkern/OSAtomic.h`, deprecated since macOS 10.12 but still functional on Swift 6.2 (verified at smoke test). Produces a hardware atomic add equivalent to Java `AtomicLong.incrementAndGet()`, Rust `AtomicU64::fetch_add`, C `atomic_fetch_add`. Chosen over alternatives because:
  - `swift-atomics` package would require converting the Swift directory to a SwiftPM project, breaking the per-file `swiftc -O` build flow.
  - `Synchronization.Atomic` is Swift 6+ only — works on this toolchain but trading portability for nothing meaningful.
  - `NSLock`-per-op would measure mutex performance instead of atomic instruction performance — diverges from the work shape of the other 9 languages.
- **Python:** `with lock: counter += 1` per iteration. CPython's GIL serializes anyway; the per-op mutex acquisition is the idiomatic shared-state pattern. Smoke test measured 10.2s — well within budget. This is the *honest* representation of Python's concurrency story.

### B2 sizing

N = 10⁵ across all 10 implementations. 100× less work than the prior N=10⁶. C measured at 7.5s; projected: compiled languages 5–10s, JVM 15–30s, Python 5–10 min. Hyperfine 13-run sweep budget: ~2 hours for the slowest language.

### Rust edition

`Cargo.toml`: `edition = "2024"`. Local toolchain is rustc 1.93.0 (well above the 1.85 minimum).

### Aggregator

`harness/aggregate_results.py` line 25 simplified to `"language": result["command"]`. Verified at smoke test that hyperfine writes the `-n` name as the `command` field in the exported JSON.

## Workflow / action plan

1. Read all 10 B2 implementations to confirm identifier names (`N`, `n`, `SIZE`, …) — done.
2. Apply 10 single-constant edits to B2 files — done.
3. Rewrite Swift B7 and Python B7 — done.
4. Update `Cargo.toml`, `aggregate_results.py`, `README.md`, `paper/main.tex` — done.
5. Smoke test:
   - C builds + B2 runs (7.5s ✓)
   - Rust builds on 2024 edition (22s build ✓)
   - Swift B7 compiles with `OSAtomicAdd64`, prints `80000000`, shows contention (15s user / 2.9s wall ✓)
   - Python B7 prints `80000000` in 10.2s ✓
   - hyperfine `-n` puts language name in JSON `command` field ✓
   - aggregator produces correct CSV ✓

## Definition of done

- [x] All 15 file edits applied.
- [x] Smoke test passes for C, C++, Rust, Swift, Python.
- [ ] Smoke test passes for Go, Java, Zig, Kotlin, Julia (after toolchain install).
- [ ] `run_single.sh` written and tested.
- [ ] First real `run_single.sh b1_fibonacci` run produces sane numbers across all 10 languages.

## Explicitly deferred (separate work)

- **B3 different RNGs across languages** — runtime is unaffected since work amount is identical (10⁹ FMAs in all languages); checksum outputs will differ but that's only a paper-side note. → Document in §6.6 Threats to Validity.
- **B5 Zig hand-rolled regex** — already commented in `benchmarks/zig/b5_regex.zig`. → One sentence in §6.6.
- **JVM startup overhead in short benchmarks** — partially mitigated by hyperfine's `--warmup 3`. → Document in §4.4 Measurement Protocol.

## References

- Plan file: `/Users/jp/.claude/plans/reactive-roaming-bumblebee.md`
- PAPER_PLAN.md timeline
- README.md prerequisites section
- Bugden & Alahmar (2022) reference table — `docs/BUGDEN_TRANSCRIPT.md` Fig. 1
