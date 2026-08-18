# Rust Among Giants

## An Empirical Comparison of Programming Languages for High-Performance AI Infrastructure
### Two suites: 9 systems languages × 8 benchmarks, and an AI-kernel suite × 5 benchmarks across a 12-language scientific superset

**Target venues (under consideration):** PLDI 2027, OOPSLA 2026, ICSE 2027, or arXiv + technical blog
**Status:** Pivoted from v1 (`rust-among-giants/`) on 2026-05-28 — see `prd/2026-05-28_v2-pivot.md`
**Format:** Conference paper (12–20 pages depending on venue), artifact-track ready

---

## Motivation

Modern AI/ML systems consistently follow a **two-tier architecture**:

- **Tier 1 (orchestration):** Python — for rapid iteration, ecosystem (PyTorch, JAX, scikit-learn), researcher productivity
- **Tier 2 (compute-critical):** C/C++/CUDA traditionally; increasingly Rust, Go, Zig, JVM languages

The performance of Tier 1 (Python) is not the question — it is well-established that interpreted Python is 40–100× slower than compiled languages on CPU-bound work [Bugden 2022, Pereira 2017, CLBG]. **The contested question is which language minimizes Tier 2 cost**: Should HuggingFace Tokenizers be in Rust or C++? Should an inference server be in Go or Java? Is Zig a credible C replacement for embedded ML?

This project benchmarks **nine candidate systems languages** for the Tier-2 role across eight systems workloads, and adds a second **AI-kernel suite** (five from-scratch numerical algorithms) implemented across a scientific superset that also includes Fortran, Python, and R. (An earlier draft carried COBOL as a tenth systems language; it has since been retired — see *Two benchmark suites* below.)


---

## Languages (up to 12)

| # | Language | Tier-2 role | Why included |
|---|----------|-------------|--------------|
| 1 | **C** | Legacy backend (NumPy, scikit-learn) | The 50-year baseline, maximum hardware control |
| 2 | **C++** | Standard backend (PyTorch, JAX, vLLM) | Industry incumbent for AI compute |
| 3 | **Rust** | Emerging backend (HuggingFace, Polars) | **Focal point** — memory safety + native speed |
| 4 | **Go** | Inference servers, data pipelines | Google's systems-grade GC language |
| 5 | **Java** | JVM ecosystem (Spark, Flink, ONNX runtime) | Enterprise-scale data infrastructure |
| 6 | **Julia** | Scientific computing, ML research (Flux.jl) | Designed for numeric work |
| 7 | **Zig** | Emerging C replacement | Modern systems language, used in Bun runtime |
| 8 | **Swift** | Apple ecosystem, CoreML backend | Server-side adoption growing |
| 9 | **Kotlin** | JVM evolution, Android ML | Modern Java successor |

### Selection rationale

- **C, C++, Java, Go, Rust** — established or emerging in real AI infrastructure
- **Zig** — credible C replacement; production use in Bun, growing
- **Julia** — fills the scientific/numeric computing niche; cited as a candidate for ML/AI
- **Swift** — Apple/CoreML ecosystem; server-side momentum
- **Kotlin** — JVM modernization story; Android ML deployment

**AI-suite-only additions** (numerical tier, used for the five AI kernels): **Fortran** (numeric incumbent), **Python** (Tier-1 orchestration, pure-scalar reference), and **R** (statistical-computing tier). The AI kernels are also implemented in all nine systems languages above.

---

## Two benchmark suites

This repository now contains **two** complementary suites that share one harness, one LCG-based determinism contract, and one analysis pipeline:

1. **Systems suite (`b1`–`b8`).** The original eight workloads (recursion, sort, matmul, Monte Carlo, regex, durable I/O, atomics, JSON) across nine languages: C, C++, Rust, Go, Java, Zig, Swift, Kotlin, Julia.
2. **AI-kernel suite (`kmeans`, `knn`, `mlp`, `ga`, `fuzzy`).** Five from-scratch AI algorithms — K-Means, k-NN, an MLP training loop, a genetic algorithm, and a Mamdani fuzzy system — implemented across a 12-language scientific superset (the nine above **plus Fortran, Python, R**). Every kernel is transcendental-free and consumes the shared 64-bit LCG (seed 42), so outputs are **bit-exact** across languages and verified by `harness/verify_checksums.sh`.

**COBOL has been retired.** It was slow to complete (recursive Fibonacci alone ran ~20 min/iteration under GnuCOBOL) and its decimal-arithmetic RNG broke the bit-exact contract. The decision was to drop it and keep R in the scientific tier. No COBOL sources remain in the tree.

**Verification status of the AI kernels.** C, C++, Rust, Go, Fortran, Python, Julia, R, and **Java** are checksum-verified bit-exact. The Java, Zig, Swift, and Kotlin kernels were added to the contract; Java is verified here, while **Zig, Swift, and Kotlin are pending a verification run on their native toolchains** (run `bash harness/verify_checksums.sh zig swift kotlin` once those toolchains are installed).

## Benchmarks (13 — 8 systems + 5 AI)

| # | Benchmark | What it measures | Relevance to AI infrastructure |
|---|-----------|------------------|-------------------------------|
| B1 | **Fibonacci (recursive)** | Function call overhead, recursion, JIT warmup | Tree search algorithms, recursive parsing |
| B2 | **Bubble Sort** | Bounds-check overhead, branch prediction, tight inner-loop cost | Data preprocessing, sorting in pipelines |
| B3 | **Matrix Multiplication** | FP compute, cache hierarchy, vectorization | Core operation in neural networks |
| B4 | **Monte Carlo Pi** | FP arithmetic, RNG throughput | Stochastic methods, MCMC sampling |
| B5 | **Regex Processing** | String handling, library quality | NLP text preprocessing, tokenization |
| B6 | **Checkpoint I/O** | Durable write + read throughput (fsync semantics), per-language sync API | PyTorch / Flax model-checkpoint save+load pattern |
| B7 | **Concurrent Counter** | Thread synchronization, atomic ops, contention | Parallel data loading, multi-threaded inference |
| B8 | **JSON Parsing** | Serialization, allocation patterns | API communication, config, log processing |

Each benchmark targets a different computational profile so the comparison surfaces language-specific strengths rather than rewarding a single niche.

Problem sizes are calibrated to ensure all languages produce statistically meaningful measurements (mean ≫ measurement noise) while keeping total suite runtime tractable.


### Benchmark parameters

The same problem size and input are used across all nine languages for a given benchmark. Constants below are defined at the top of each source file (e.g. `#define N` in C, `const N` in Rust, etc.).

| # | Benchmark | Problem size | Key constants / config | Input | Output (checksum) | RNG seed |
|---|-----------|--------------|------------------------|-------|-------------------|----------|
| B1 | Fibonacci | `n = 45` | recursive `fib(n-1) + fib(n-2)`; no memoization | CLI arg, default 45 | `fib(45) = 1_134_903_170` | n/a |
| B2 | Bubble Sort | `N = 100_000` ints | classic O(N²) with early-exit `swapped` flag; values in `[0, N)`. **Working set ≈ 400 KB fits in L2 (12 MB on M1)** — this is a tight-loop / bounds-check test, not a memory-hierarchy test (cache-spillover is exercised by B3 matmul and B6 file I/O). | in-memory, generated | first + last element after sort | `srand(42)` |
| B3 | Matrix Multiplication | `2000 × 2000` (`double`) — 32 MB per matrix, 96 MB working set | `ikj` loop order with `a_ik` hoist (cache-friendly on row-major). **Shared LCG (state₀=42, mul=6364136223846793005, add=1442695040888963407) in all 9 languages, so matrices and checksum are bit-for-bit identical across languages.** Flat 1D layout in 8 languages; row-major static 2D in C (identical layout). Julia uses `Vector{Float64}` rather than its native column-major `Matrix` to keep the ikj access pattern fair. **At N=2000 a single matrix (32 MB) exceeds M1 L2 (12 MB) — DRAM bandwidth becomes a real factor, not just compute throughput.** | in-memory, generated | sum of all `C[i,j]` (6 dp) — same value in all 9 languages | LCG state₀ = 42 |
| B4 | Monte Carlo Pi | `1_000_000_000` iterations (1 B) | LCG RNG (constants `6364136223846793005`, `1442695040888963407`); count `(x²+y² ≤ 1.0)` | in-memory | π estimate (10 dp) | LCG state = 42 |
| B5 | Regex | `1_000_000` lines, ~30% contain emails | POSIX-extended pattern `[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}`; `REG_NOSUB`; line-by-line, fixed buffer 4096 B. **Each language uses its idiomatic regex engine** (POSIX in C, `<regex>` in C++, `regexp`/RE2 in Go, `java.util.regex` in Java/Kotlin, PCRE2 via `Regex` in Julia, `NSRegularExpression`/ICU in Swift, the canonical `regex` crate in Rust) — engines differ in DFA vs backtracking strategy, so a fraction of the cross-language gap reflects engine choice rather than runtime quality. **Zig has no stdlib regex** and uses a hand-rolled char-class scanner for the same email pattern; see "Known limitations (B5)" below. | `data/regex_input.txt` (~61 MB, 1 M lines, generated) | match count | `random.seed(42)` (generator) |
| B6 | Checkpoint I/O | write **4 GiB** + **fsync** + read **4 GiB** | `CHUNK_SIZE = 1 MiB`, `NUM_CHUNKS = 4096`; payload = `'A'`. Sized to dominate measurement noise (at 1 GiB σ ≈ 20% of mean on M1; at 4 GiB σ drops to <10% because absolute wall-time is ~4× larger while OS/scheduling noise stays constant). fsync between write and read guarantees the data is durable on disk before the read phase begins — mirrors PyTorch / Flax checkpoint save (`torch.save` followed by `os.fsync` to survive crashes). Without fsync, this benchmark would only measure OS page cache throughput (~RAM speed) on a 16 GB M1, not real durable I/O. Per-language fsync API: C `fsync(fileno(fp))`, C++ **drops to POSIX `open`/`write`/`fsync`** (`std::ofstream` doesn't expose its file descriptor — an idiomatic-C++ limitation worth noting), Rust `File::sync_all`, Go `f.Sync`, Java `FileOutputStream.getFD().sync()`, Julia `ccall(:fsync, …)` (no high-level wrapper in stdlib), Zig `f.sync()`, Swift `FileHandle.synchronizeFile()`, Kotlin same as Java. Per-language temp file `fileio_test_<lang>.tmp` then `remove()`. | `data/fileio_test_<lang>.tmp` (transient) | total bytes read = `4_294_967_296` | n/a |
| B7 | Concurrent Counter | `8` threads × `10_000_000` ops = `80_000_000` ops | atomic `fetch_add(1)` on one shared 64-bit counter; no locks; maximum contention on a single cache line. **Memory ordering is split across languages** (see §"Known limitations (B7)" below): C/C++/Rust/Zig/Swift/Julia use `relaxed`/`monotonic`; Go/Java/Kotlin are forced to sequentially-consistent by their stdlib atomic APIs. | n/a | final counter (= `80_000_000`) | n/a |
| B8 | JSON Parse | `~100 MB` input | **Full parse + recursive tree walk** in all 9 languages (no byte-scanner shortcut). Each language uses its idiomatic single-file/stdlib JSON parser: cJSON (C, vendored), nlohmann::json (C++, vendored), `serde_json` (Rust), `encoding/json` (Go), hand-rolled recursive-descent (Java/Kotlin), `JSON.jl` (Julia), `JSONSerialization` / Foundation (Swift), `std.json` (Zig). Counts `(objects, arrays, strings, numbers, booleans, nulls)` walking only object values (not keys) so all 9 implementations produce bit-exact identical output. See "Known limitations (B8)" below for the methodology decision and Swift-specific NSNumber caveat. | `data/json_input.json` (~100 MB, generated) | 6-tuple `(772432, 386217, 2586760, 1158648, 386216, 116125)` | `random.seed(42)` (generator) |

**Methodology constants** (same for every benchmark):

- `hyperfine --warmup 3 --runs 10` → 13 process executions per (benchmark, language); 10 measured.
- Each invocation is wrapped in `/usr/bin/time -l` (`harness/wrap_rss.sh`) so M1 (wall time) and M2 (peak RSS in bytes) are captured in the same process.
- Stdout of each benchmark is redirected to `/dev/null` (keeps hyperfine clean and prevents tty buffering effects); benchmarks still compute and print a checksum to defeat dead-code elimination.
- Compiler flags: C/C++ via `Makefile` (`-O3`); Rust via `Cargo.toml` (`opt-level=3`, `lto=true`, `codegen-units=1`); Go default `go build`; Swift `swiftc -O`; Zig via `build.zig`; Java/Kotlin via `javac` / `kotlinc -include-runtime`; Julia interpreted from source per run.

**Reproducing the inputs:** all generated test data is deterministic given the seeds above. Regenerate with `python3 harness/generate_data.py`.

### Known limitations (B5 Regex)

B5 is the only benchmark in the suite where the languages do *not* all run the same algorithm against the same primitive — they each use whichever regex engine their idiomatic toolbox provides. The pattern string is byte-for-byte identical (`[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}`), but what runs underneath differs:

| Language | Engine | Strategy | Notes |
|---|---|---|---|
| C | POSIX `regex.h` (libc) | NFA / backtracking | macOS uses BSD libc regex; Linux uses GNU regex. Compiled with `REG_NOSUB`. |
| C++ | `<regex>` | NFA / backtracking | libc++ implementation on macOS; historically slow vs RE2/PCRE. |
| Rust | `regex` crate (NOT stdlib) | DFA (lazy) | The canonical crate maintained by a Rust-core member; no stdlib regex exists in Rust by design. |
| Go | `regexp` (stdlib) | RE2 (Thompson NFA, linear time) | Guarantees no catastrophic backtracking; can be slower than PCRE on simple patterns. |
| Java | `java.util.regex.Pattern` | NFA / backtracking | Pre-compiled `Pattern`, reused via `Matcher.find()`. |
| Kotlin | `kotlin.text.Regex` | NFA / backtracking | Thin wrapper over `java.util.regex`; same engine as Java. |
| Julia | `Regex` (stdlib) | **PCRE2** (JIT compiled) | Julia's `r"…"` literal compiles to PCRE2 with JIT enabled by default. |
| Swift | `NSRegularExpression` (Foundation) | **ICU regex** | Backtracking NFA with Unicode-aware char classes. |
| **Zig** | **hand-rolled char-class scanner** | manual single-pass | **No regex in `std` — see paragraph below.** |

**Why Zig is special.** Zig's standard library deliberately omits a regex engine (the language design favours small, dependency-free stdlibs; regex is considered application-layer). Adding a third-party Zig regex package (`zig-regex`, `regez`, `tigerbeetle/regex`) would (a) introduce a non-stdlib dependency that none of the other eight languages need and (b) measure that specific library, not "what Zig gives you out of the box." We therefore implement the email check in `benchmarks/zig/b5_regex.zig` as a single-pass scan that mirrors the same accept/reject set as the regex pattern (alphanumeric + `._%+-` on the local part, an `@`, then alphanumeric + `.-` containing at least one dot followed by ≥2 alphabetic chars). This produces the same match count on `data/regex_input.txt` as the other eight implementations, verified by checksum equality during validation. The Zig number on B5 should therefore be read as "stdlib-only text scanning throughput," not "regex engine performance."

**Cross-language validation.** All nine implementations report exactly the same match count — `300_818` out of `1_000_000` lines (30.08%) — when run against `data/regex_input.txt`. This was verified by running every binary against the same input and diff'ing stdout: identical byte-for-byte across POSIX libc regex, libc++ `<regex>`, Rust's `regex` crate, Go's RE2, `java.util.regex` (Java and Kotlin), PCRE2-JIT (Julia), `NSRegularExpression`/ICU (Swift), and the hand-rolled Zig scanner. The 162× spread in wall-clock time across these nine implementations is therefore a measurement of **algorithmic and implementation throughput on an identical workload**, not a consequence of any engine missing or under-counting matches. Reviewers can reproduce this check with `for lang in c cpp rust go java zig swift kotlin julia; do bash harness/run_single.sh b5_regex $lang; done` followed by reading the stdout of any single invocation — every language prints `300818`.

**Why Rust is footnoted.** The Rust stdlib also has no regex, but the `regex` crate is the de-facto standard (maintained by a Rust-core member, used by `cargo`, `rustfmt`, and the compiler itself), so the gap between "stdlib-only" and "idiomatic" is much smaller than for Zig. We use the crate; this is documented but not flagged as a methodological limitation.

**What B5 actually measures.** Given the engine heterogeneity, B5 should be interpreted as a *toolchain-level* benchmark — "how fast can a developer find emails in 60 MB of text using whatever their language ships with?" — not a controlled measurement of any single regex algorithm. The cross-language ranking on B5 reflects the combined effect of (i) the engine's algorithm (DFA vs backtracking), (ii) JIT vs interpreted compilation of the pattern, (iii) Unicode awareness overhead (ICU does extra work), and (iv) I/O & string-handling primitives. We report the engine each language uses alongside the timing so readers can attribute differences correctly.

### Known limitations (B6 Checkpoint I/O)

Two methodology caveats specific to B6 that reviewers should know about:

1. **macOS `fsync` is weaker than Linux `fsync`.** APFS implements `fsync` as a flush to the SSD's device-level write cache, *not* to the physical media. True media-durable writes on macOS require `fcntl(fd, F_FULLFSYNC)`, which is non-portable and not exposed by 7 of the 9 languages' standard libraries. For cross-language fairness we use `fsync` everywhere; the absolute write throughput numbers would be ~2× slower on Linux/ext4 where `fsync` is strict (Apple documents this in [TN1241](https://developer.apple.com/library/archive/documentation/Performance/Conceptual/FileSystem/Articles/TrackingChanges.html)). The *relative* ranking across languages is unaffected because all 9 face the same OS semantics.

2. **The read phase is cache-warm.** After `fsync`, the file's pages remain in the OS page cache; the immediately-following read pulls from RAM, not from the SSD. This faithfully models the common case where checkpoint-load happens shortly after checkpoint-save (typical during training resumption), but it does *not* measure cold-cache load latency. Modelling cold load would require flushing the page cache between phases (`purge` on macOS, requires admin), which is out of scope for an unprivileged benchmark.

### Known limitations (B7 Concurrent Counter)

B7 is a pure atomic-contention micro-benchmark: 8 OS threads pound `fetch_add(1)` on one shared 64-bit counter, so the single cache line holding the counter ping-pongs constantly between the M1's 8 performance cores. The wall-clock time is dominated by (a) thread spawn/join overhead and (b) the per-operation cost of the atomic RMW primitive each language's standard library exposes. The latter splits the nine languages into two camps:

| Language | API used | Memory ordering | ARM64 lowering |
|---|---|---|---|
| C | `atomic_fetch_add_explicit(…, memory_order_relaxed)` | **relaxed** | `ldxr/stxr` loop, no barriers |
| C++ | `std::atomic::fetch_add(1, std::memory_order_relaxed)` | **relaxed** | `ldxr/stxr` loop, no barriers |
| Rust | `AtomicU64::fetch_add(1, Ordering::Relaxed)` | **relaxed** | `ldxr/stxr` loop, no barriers |
| Zig | `Value(i64).fetchAdd(1, .monotonic)` | **relaxed** (`monotonic` ≡ relaxed in LLVM) | `ldxr/stxr` loop, no barriers |
| Swift | `Synchronization.Atomic<Int>.wrappingAdd(1, ordering: .relaxed)` (Swift 6+) | **relaxed** | `ldxr/stxr` loop, no barriers |
| Julia | `@atomic :monotonic c.value += 1` (Julia 1.7+) | **relaxed** (`:monotonic` ≡ relaxed) | `ldxr/stxr` loop, no barriers |
| Go | `atomic.AddInt64(&counter, 1)` | **sequentially consistent** (forced) | `ldaxr/stlxr` + `dmb ish` barriers |
| Java | `AtomicLong.incrementAndGet()` | **sequentially consistent** (forced) | `ldaxr/stlxr` + `dmb ish` barriers |
| Kotlin | `AtomicLong.incrementAndGet()` (JVM) | **sequentially consistent** (forced) | `ldaxr/stlxr` + `dmb ish` barriers |

Why three languages cannot opt out: **Go**'s `sync/atomic` package exposes no ordering parameter — every atomic operation is sequentially consistent by language specification. **Java**'s `VarHandle.getAndAdd*` family offers only sequentially-consistent, acquire, or release RMW (no "plain"/relaxed RMW exists in the JMM). **Kotlin** on the JVM inherits the same constraint.

On ARM64 (Apple M1) this is not a small difference: the SC variant emits an acquire-load / store-release pair plus a full `dmb ish` barrier per increment, while the relaxed variant emits only the bare `ldxr/stxr` exclusive pair. Under heavy single-line contention the SC path typically costs ~2–3× more wall time per operation than the relaxed path on M1. Readers of the B7 results should therefore *not* interpret a higher Go/Java/Kotlin number as a runtime-quality deficit — it reflects the language's atomic memory model choice, which is itself a deliberate design decision (Go's spec prioritises programmer simplicity; the JVM standardised on SC for AtomicLong long before relaxed atomics had broad hardware support). We report each language using its idiomatic, stdlib-only atomic API; using `VarHandle.getAndAddRelease` on JVM or hand-rolled C-interop on Go would change "what the language gives you out of the box," which is the population this paper is measuring.

A secondary note: **Julia's startup cost is included in B7's wall time** (≈300–500 ms for runtime init plus JIT compilation of `@threads` and the atomic field accessor). On other benchmarks this is amortised by long compute phases; on B7 it is visible because 80 M contended atomic adds finish in ~3 s on the fast languages.

### Known limitations (B8 JSON Parse)

B8 measures end-to-end JSON parsing throughput: read 100 MB of JSON from disk, parse it to a fully-materialised in-memory tree (object/array/string/number/bool/null nodes), then walk the tree counting nodes by type. The output is a 6-tuple `(objects, arrays, strings, numbers, booleans, nulls)` used as the cross-language checksum.

| Language | Parser | Type | Vendoring |
|---|---|---|---|
| C | **cJSON v1.7.18** | single-header (sort of), recursive descent | vendored at `benchmarks/c/vendor/cJSON.{c,h}` (MIT) |
| C++ | **nlohmann::json v3.11.3** | single-header, recursive descent | vendored at `benchmarks/cpp/vendor/json.hpp` (MIT) |
| Rust | `serde_json` (crates.io) | recursive descent → `Value` enum | normal Cargo dep |
| Go | `encoding/json` (stdlib) | recursive descent → `interface{}` tree | stdlib |
| Java | hand-rolled recursive-descent | builds `Map`/`List`/`String`/`Number`/`Boolean`/`null` tree | no deps (`String.indexOf`-based) |
| Kotlin | hand-rolled recursive-descent (same algorithm as Java) | builds Kotlin stdlib types | no deps |
| Julia | `JSON.jl` (general registry) | recursive descent → `Dict`/`Vector`/`String`/`Number`/`Bool`/`nothing` | `Pkg.add("JSON")` |
| Swift | `JSONSerialization` (Foundation) | recursive descent → `[String: Any]`/`[Any]` | stdlib (Foundation) |
| Zig | `std.json` (stdlib) | recursive descent → `std.json.Value` | stdlib |

**Methodology decision: full parse, not byte-scan.** An earlier version of B8 (v1) used a hand-written single-pass byte scanner in C and C++ that counted tokens (`{`, `[`, `"`, `true`, `false`, `null`, digits) using an in-string state machine, without actually parsing JSON to a tree. That implementation was ~30× faster than `serde_json` on the same input, but it was solving a different problem: it did not validate JSON syntax, did not allocate the tree, and crucially counted *every* `"` as a "string" — including object keys, which inflated the string count by ~150% relative to all other implementations. We rejected this approach because it would have made B8 unpublishable: the C/C++ numbers would not have been comparable to any of the other seven languages' numbers, and any reviewer would flag it as comparing different workloads. The current implementation forces all nine languages to do the same thing: parse to a fully materialised tree, then walk it. cJSON and nlohmann::json are vendored single-file MIT-licensed libraries that ship in many Linux distributions' package repositories and are the closest C/C++ equivalents to "what the language gives you for JSON" in the absence of a stdlib parser. Verified output: all nine implementations produce `(772432, 386217, 2586760, 1158648, 386216, 116125)` on `data/json_input.json`.

**Counting convention: object values only, not keys.** Object keys in JSON are syntactically strings, but the universal convention in tree-based parsers is to count them as structural metadata rather than as `string` nodes. All nine implementations iterate `object.values()` (or its language equivalent) during the walk, so a JSON document like `{"foo": "bar"}` counts as `(1 object, 0 arrays, 1 string, …)` — *not* 2 strings. This convention was chosen because it matches what `serde_json::Value`, `encoding/json`, `std.json.Value`, etc. natively expose; forcing keys to be counted would require special-casing every language's walker.

**Swift NSNumber caveat (fixed).** `JSONSerialization` on Apple platforms bridges both JSON booleans *and* JSON numbers to Objective-C `NSNumber`, with no native discriminator visible to Swift's type system — `v is NSNumber` returns true for both. A naive Swift implementation will therefore double-count booleans as numbers (`bools=0, numbers=number+bool`). The current implementation uses `CFGetTypeID(v as CFTypeRef) == CFBooleanGetTypeID()` to disambiguate before the `is NSNumber` check, recovering the correct counts. This is a known Foundation quirk and a recurring footgun in Swift JSON code; we document it here because it almost cost us cross-language checksum equality.

**What B8 actually measures.** Full-tree JSON parsing throughput on a representative AI-infrastructure workload (config files, model metadata, telemetry payloads). The dominant costs are (i) UTF-8 decoding, (ii) allocation of the AST nodes, (iii) hash-map insertion for object construction, and (iv) the recursive walker. The cross-language ranking reflects parser implementation quality (allocator strategy, SIMD use, branchiness of the tokenizer) more than language runtime quality — exactly as in B5. Languages that ship a fast stdlib JSON parser (Go, Zig) and Rust's de-facto-standard `serde_json` will tend to cluster at the top; older or feature-heavy libraries (`JSONSerialization` Foundation, nlohmann::json) will trail. None of the nine implementations use a SIMD-accelerated parser (simdjson, RapidJSON-SIMD), which would skew results in C++'s favour and would not represent "what a developer reaches for first."

---

## Metrics (5)

| # | Metric | Tool | Why it matters for Tier-2 selection |
|---|--------|------|-------------------------------------|
| M1 | **Wall-clock time** | `hyperfine` (10 runs, 3 warmup) | Throughput per inference, training step time |
| M2 | **Peak RSS memory** | `/usr/bin/time -l` (via wrapper) | Cost/instance, containerization density |
| M3 | **Binary size** | `stat` | Deployment footprint, embedded/edge |
| M4 | **Lines of code** | `wc -l` (implementation only) | Maintenance burden, onboarding |
| M5 | **Compilation time** | `time` on build command | Developer iteration speed |

### Measurement methodology

- **hyperfine 1.20.0**: 10 measured runs after 3 warmup runs. Reports mean, stddev, median, min, max.
- **Inline RSS capture**: each hyperfine run is wrapped in `/usr/bin/time -l` via `harness/wrap_rss.sh`, so M2 is captured simultaneously with M1 (single benchmark execution per run). 13 RSS samples per language.
- **macOS RSS units**: `ru_maxrss` is reported in **bytes** on macOS (unlike Linux which uses KiB).
- **Wrapper overhead** (~10–30 ms uniform across languages) is documented in the paper's methodology section.
- **Language ordering**: `harness/run_single.sh` and `harness/run_all.sh` run languages in the order `c, cpp, rust, go, java, zig, swift, kotlin, julia`. Julia is intentionally last because its JIT runtime resident set (~210 MB on M1) can evict the M1's 12 MB shared L2 between sweeps; placing it at the end protects the wall-time measurement of every other language from cold-cache contamination on the first hyperfine warmup run.

#### Authoritative source for M2 (peak RSS)

**Read M2 from `results/<bench>_memory.json`, not from the `memory_usage_byte` field of `results/<bench>.json`.**

Hyperfine's own memory tracking on macOS is documented as unreliable — it can report stale or shared-process values, and in this repository's runs we have observed it returning identical RSS readings across consecutive language commands after a Julia run (i.e. the Swift/Zig/Kotlin entries in `b7_concurrent.json` showed `220938240` bytes verbatim, which is Julia's RSS, not theirs). This is the exact failure mode that motivated `harness/wrap_rss.sh`: it interposes `/usr/bin/time -l` per invocation, captures `ru_maxrss` in bytes from each child process independently, and the aggregator (`rss_log_to_json.py`) writes the correct per-language samples to `<bench>_memory.json`. Treat the hyperfine `memory_usage_byte` field as a known-bad legacy column and ignore it; the `_memory.json` companion file is the only correct source for peak RSS in this dataset.

---

## Project structure

```
rust-among-giants-v2/
├── README.md                            # this file
├── docs/
│   ├── PAPER_PLAN.md                    # paper outline, section-by-section writing guide
│   └── BUGDEN_TRANSCRIPT.md             # reference work transcript
├── prd/
│   └── 2026-05-28_v2-pivot.md           # decision record for the v1→v2 pivot
├── benchmarks/
│   ├── c/                               # systems (b1-b8) + AI (b9–b13 (kmeans/knn/mlp/ga/fuzzy))
│   ├── cpp/
│   ├── rust/
│   ├── go/
│   ├── java/
│   ├── julia/
│   ├── zig/
│   ├── swift/
│   ├── kotlin/
│   └── python/                          # preserved as reference; not invoked by v2 harness
├── harness/
│   ├── run_single.sh                    # one benchmark across the 9 languages
│   ├── run_all.sh                       # all 13 benchmarks
│   ├── wrap_rss.sh                      # inline RSS capture wrapper
│   ├── rss_log_to_json.py               # aggregates RSS logs to JSON
│   ├── collect_metrics.sh               # M3 (binary), M4 (LOC), M5 (compile)
│   ├── generate_data.py                 # B5/B8 test data
│   └── aggregate_results.py             # combine all results into CSV/JSON
├── analysis/
│   └── plots.py                         # paper figures
├── paper/
│   ├── main.tex                         # LaTeX paper (format depends on chosen venue)
│   └── draft.md                         # working findings document
├── results/                             # benchmark output (gitignored)
└── data/                                # generated test data (gitignored)
```

---

## Hardware & software environment

### Tested on

- Apple MacBook with M1 chip (8 cores: 4 performance + 4 efficiency)
- 16 GB unified memory
- macOS Sonoma
- All compiler/interpreter versions documented in `paper/draft.md`

### Prerequisites

```bash
# C/C++: Xcode command line tools (preinstalled on macOS)
xcode-select --install

# Rust (rustup official): 1.85+ required for 2024 edition
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Compiled languages
brew install go zig@0.14 openjdk kotlin julia gcc r   # gcc provides gfortran; gnucobol removed

# Swift: preinstalled on macOS

# Benchmark tools
brew install hyperfine
```

See `SETUP.md` for a complete pinned-version setup recipe.

---

## Running the benchmarks

```bash
# 1. Generate test data (B5 regex, B8 JSON)
cd harness
python3 generate_data.py

# 2. Run all benchmarks across all languages
cd ..
bash harness/run_all.sh

# OR run one benchmark at a time (recommended; allows incremental QC)
bash harness/run_single.sh b3_matrix_mul

# OR a subset of languages
bash harness/run_single.sh b3_matrix_mul c rust zig

# 3. Aggregate timing + memory into CSV
python3 harness/aggregate_results.py

# 4. Generate figures
cd analysis
python3 plots.py
```

Each benchmark produces two JSON files in `results/`:
- `<bench>.json` — hyperfine timing (M1)
- `<bench>_memory.json` — peak RSS aggregated from `wrap_rss.sh` (M2)

M3, M4, M5 are collected once after all benchmarks via `harness/collect_metrics.sh`.

---

## License

Code: MIT
Paper: All rights reserved until publication
