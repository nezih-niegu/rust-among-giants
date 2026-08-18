# Paper Plan: Rust Among Giants

## Full Title
**Rust Among Giants: An Empirical Benchmark of Ten Programming Languages Across Performance, Safety, and Developer Productivity**

## Target
- **Conference:** MICAI 2026 (25th Mexican International Conference on AI)
- **Deadline:** June 14, 2026
- **Format:** Springer LNCS, 12 pages max (20 absolute max)
- **Review:** Double-blind
- **Submission:** CMT (https://cmt3.research.microsoft.com/MICAI2026)
- **Templates:** https://www.springer.com/gp/computer-science/lncs/conference-proceedings-guidelines

---

## Research Questions

**RQ1:** How does Rust compare to nine other prominent programming languages in raw execution performance across diverse computational tasks?

**RQ2:** Does Rust's memory safety model impose a measurable performance penalty compared to unsafe systems languages (C, C++)?

**RQ3:** What is the trade-off between developer productivity (lines of code, compilation time) and runtime performance across the ten languages?

**RQ4:** Which language offers the best overall balance of performance, memory efficiency, safety, and developer experience for building modern software systems?

---

## Section-by-Section Writing Guide

### 1. Introduction (~1.5 pages)

**Paragraph 1:** Motivation — modern software demands both performance and safety. C/C++ give performance but not safety. Python/Java give safety (GC) but not performance. Rust claims to give both.

**Paragraph 2:** Gap — existing benchmarks are limited. Bugden (2022) only used 3 benchmarks and 2 metrics on 6 languages. The Computer Language Benchmarks Game is synthetic. No comprehensive comparison exists with modern languages like Zig, Swift, Kotlin alongside classics.

**Paragraph 3:** Contribution — we present the most comprehensive multi-language benchmark to date: 10 languages × 8 benchmarks × 5 metrics. We extend Bugden (2022) with 4 new languages, 5 new benchmarks, and 3 new metrics. All code is publicly available.

**Paragraph 4:** Key findings preview (1-2 sentences per finding).

**Paragraph 5:** Paper structure roadmap.

### 2. Background & Related Work (~1.5 pages)

**2.1 Language Performance Benchmarks**
- Computer Language Benchmarks Game (Gouy, ongoing)
- Prechelt's empirical studies on programmer productivity
- Bugden & Alahmar (2022) — our direct predecessor, describe in detail
- Energy Efficiency of Programming Languages (Pereira et al., 2017)

**2.2 Rust in the Literature**
- Jung et al. (2021) — Safe systems programming in Rust (CACM)
- Jung (2020) — PhD dissertation on Rust type system (RustBelt)
- Uzlu & Şaykol (2017) — Rust for IoT
- Emre et al. (2021) — Translating C to safer Rust

**2.3 Rust Adoption (2022-2026)**
- Linux kernel: permanent adoption (December 2025, Tokyo summit)
- Microsoft: Windows components in Rust
- Stack Overflow: most admired 9 consecutive years (72.4% in 2025)
- Rust 2024 edition (released February 2025 with Rust 1.85)

### 3. Rust: Safety, Performance, and Ecosystem (~2 pages)

**3.1 Safety Features**
- Ownership and borrowing (prevent use-after-free, double free)
- No null pointers (Option type)
- Automatic bounds checking (prevent buffer overflow/overread)
- Data race prevention at compile time
- Compare: C (none), C++ (partial with smart pointers), Go (GC + race detector), Java (GC), etc.

**Safety comparison table** (qualitative):
| Feature | C | C++ | Rust | Go | Java | Python | Julia | Zig | Swift | Kotlin |
|---------|---|-----|------|----|------|--------|-------|-----|-------|--------|
| Memory safety | ✗ | Partial | ✓ | ✓(GC) | ✓(GC) | ✓(GC) | ✓(GC) | Partial | ✓(ARC) | ✓(GC) |
| Null safety | ✗ | ✗ | ✓ | ✗ | ✗ | N/A | N/A | ✓ | ✓ | ✓ |
| Data race prevention | ✗ | ✗ | ✓ | Partial | Partial | N/A(GIL) | ✗ | ✗ | Partial | Partial |
| Bounds checking | ✗ | ✗ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |

**3.2 Performance Features**
- Zero-cost abstractions (monomorphization)
- No garbage collector (ownership-based deallocation)
- LLVM backend (same optimizer as C/C++/Swift/Zig)
- Rayon for easy parallelism

**3.3 Ecosystem (2026)**
- Cargo: build, test, bench, doc, publish — all in one
- crates.io: 150,000+ crates (cite actual number)
- Tooling: rust-analyzer (LSP), Clippy (linter), Miri (UB detector), rustfmt
- Compare with pip, npm, go mod, Maven, etc.

### 4. Experimental Methodology (~2 pages)

**4.1 Hardware and Software**
- Machine: Apple MacBook M1, 16GB RAM, macOS [version]
- All compiler/interpreter versions in a table
- Optimization flags: -O3 for C/C++, --release for Rust, etc.

**4.2 Languages and Versions** (table)

**4.3 Benchmark Descriptions** (one paragraph each for B1-B8)

**4.4 Measurement Protocol**
- hyperfine configuration (10 runs, 3 warmup)
- How peak RSS is measured
- How LOC is counted
- How compilation time is measured
- How binary size is measured

**4.5 Implementation Principles**
- All implementations are idiomatic (no "straw man")
- No external libraries except for regex and JSON (where the standard library is insufficient)
- Same algorithm in all languages (describe each)

### 5. Results (~3 pages)

**Table 1:** Wall-clock time for all 8 benchmarks × 10 languages (mean ± stddev)
**Table 2:** Peak RSS memory for all 8 benchmarks × 10 languages
**Table 3:** Binary size, LOC, and compilation time per language
**Table 4:** Speedup relative to Python (the slowest baseline)
**Table 5:** Overall ranking across all dimensions

**Figure 1:** Grouped bar chart — time per benchmark (log scale)
**Figure 2:** Heatmap — speedup relative to Python
**Figure 3:** Scatter plot — LOC vs mean execution time (productivity vs performance)
**Figure 4:** Bar chart — memory usage comparison

### 6. Discussion (~1.5 pages)

**6.1 When the Language Matters**
- Compute-bound tasks (Fibonacci, Monte Carlo, Matrix): C ≈ C++ ≈ Rust ≈ Zig >> Go > Java ≈ Kotlin >> Python
- Rust matches C/C++ within X%

**6.2 When the Library Matters**
- Regex: library quality dominates (Rust regex crate is excellent)
- JSON: serde (Rust) vs standard libraries

**6.3 The Newcomers**
- Zig: comparable to C in performance, better safety than C, worse than Rust
- Julia: excellent for numeric, poor for general computing
- Swift: ARC overhead shows in allocation-heavy benchmarks
- Kotlin: Java-like performance (same JVM), much less verbose

**6.4 Developer Productivity Trade-off**
- Python: fewest LOC but 100× slower
- Rust: more LOC than Go/Python but close to C/C++ performance with safety
- The "Rust tax": compilation time is 5-10× longer than Go/Zig

**6.5 Implications for AI/ML Infrastructure**
- For data preprocessing: Rust matches C++ performance, already adopted (Polars, HuggingFace Tokenizers)
- For inference serving: Rust's concurrency model is ideal
- For training: Python will remain dominant (PyTorch/JAX ecosystem)
- The future is polyglot: Python for interface, Rust for performance-critical components

**6.6 Threats to Validity**
- Single hardware platform (ARM M1, not x86)
- Implementation quality may vary (mitigation: idiomatic, reviewed)
- Library versions change over time
- Small benchmark set (8) may not represent all workloads

### 7. Conclusion (~0.5 pages)

- Summary of findings
- Rust offers the best balance of safety + performance in 2026
- Practical recommendation: use Rust for performance-critical, safety-critical systems; Python for rapid prototyping; choose based on workload profile
- Future work: more benchmarks, x86 comparison, GPU benchmarks, larger datasets

---

## References to Include (minimum 20-25)

### Core references
1. Bugden & Alahmar (2022) — IGSCONG'22
2. Bugden & Alahmar (2022) — IJSEKE (the journal version with benchmarks)
3. Jung et al. (2021) — Safe systems programming in Rust, CACM
4. Jung (2020) — PhD dissertation
5. Jung et al. (2018) — RustBelt, POPL
6. Uzlu & Şaykol (2017) — Rust for IoT
7. Klabnik & Nichols (2019) — The Rust Programming Language (book)

### Language benchmarks
8. Pereira et al. (2017) — Energy efficiency of programming languages, SLE
9. Computer Language Benchmarks Game (cite website)
10. Prechelt (2000) — An empirical comparison of seven programming languages

### Rust adoption
11. Linux kernel Rust adoption — Corbet/LWN.net (2025)
12. Microsoft Rust adoption — official blog
13. Stack Overflow Developer Survey 2025
14. Rust Foundation Annual Survey 2025

### Language references
15. Bezanson et al. (2017) — Julia: A fresh approach to numerical computing
16. Go specification — golang.org
17. Zig language reference
18. Swift programming language — Apple
19. Kotlin specification — JetBrains

### Tools
20. hyperfine (Peter, GitHub)

---

## Timeline

| Date | Milestone |
|------|-----------|
| May 28-30 | Run all benchmarks on M1, collect results |
| May 31-June 2 | Generate figures, fill in results tables |
| June 3-8 | Write full paper draft |
| June 9-11 | Review, polish, format check |
| June 12-13 | Final proofread, prepare submission |
| June 14 | **SUBMIT** |
