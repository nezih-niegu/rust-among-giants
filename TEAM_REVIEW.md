# Team Review — Reading Guide

Welcome. This document is an orientation for the team member reviewing
the code and paper. JP wrote it explicitly to help you make decisions
faster, not to advocate for any particular conclusion.

## What this repo is

An empirical benchmark study comparing **10 candidate languages** for
the Tier-2 (performance-critical backend) layer of AI/ML
infrastructure. Target venue: **ICSE 2027** (abstract due 2026-06-23,
submission due 2026-06-30). Format: 10-page IEEE conference paper.

## What you should look at, in order

### 1. Skim the paper (15 min)

```
paper/main.tex
```

Skim the abstract, §1 Intro, §6 Discussion. Skip §3 Methodology and
§5 Results detail on first pass — you'll come back to those. The
paper compiles in Overleaf with the IEEEtran 10pt conference class;
no extra packages beyond what's in the preamble.

### 2. Verify your environment can reproduce (5 min + dependency install)

```bash
# If you're missing toolchains, follow SETUP.md first.
bash harness/smoke.sh
```

This runs in ~2 minutes once toolchains are installed. It verifies
all 10 languages compile B1 and B6, and that B1 produces the canonical
output (`6765` for fib(20)). Green output = good; red output points
you at the broken toolchain.

### 3. Read these in this order

| File | Why |
|------|-----|
| `README.md` (full) | Highest-level project context, the two-suite overview, and the methodology summary. |
| `SETUP.md` | Pinned toolchain versions and reproducibility caveats. Note: explicitly **no Docker**, and why. |
| `harness/run_all.sh` | The reference orchestrator. Anyone reproducing the paper runs this. |
| `harness/run_single.sh` | Per-benchmark / per-language dispatcher; useful for iterating. |
| `harness/wrap_rss.sh` | RSS capture wrapper — cross-platform (`/usr/bin/time -l` on macOS, `-v` on Linux). |
| `analysis/plots.py` | Generates the 6 paper figures from `results/*.json`. |
| `benchmarks/<lang>/` | One folder per language: systems (b1-b8) and/or AI (b9–b13 (kmeans/knn/mlp/ga/fuzzy)) implementation files plus build glue. |

### 4. COBOL decision — RESOLVED (dropped)

The COBOL open question is closed: **COBOL is dropped, R is kept.**
Rationale — COBOL was slow to complete (recursive Fibonacci ~20 min/run
under GnuCOBOL) and its decimal-arithmetic RNG broke the bit-exact
checksum claim. All COBOL sources and harness/paper references have been
removed. The repository now ships two suites: the nine-language systems
suite (b1-b8) and a five-kernel **AI suite** (b9–b13 (kmeans/knn/mlp/ga/fuzzy))
across a 12-language scientific superset (adds Fortran, Python, R).

**New review item:** the AI kernels for **Zig, Swift, and Kotlin** were
written to the shared LCG/bit-exact contract but not verified on this
build host (Java is verified). Please run
`bash harness/verify_checksums.sh zig swift kotlin` on a machine with
those toolchains and confirm they match the reference checksums.

## High-leverage things to look at

These are where a competent code reviewer can catch real problems:

1. **`benchmarks/*/b7_concurrent.*`** — the atomic memory ordering
   story is the paper's most subtle finding. Verify that each
   language really is using its most-relaxed available ordering
   (relaxed/monotonic in C/C++/Rust/Zig/Swift/Julia; SC by force in
   Go/Java/Kotlin).

2. **`benchmarks/*/b8_json_parse.*`** — all 9 modern langs must
   materialise a full JSON tree and walk only the values (not keys)
   to produce the 6-tuple checksum `(772432, 386217, 2586760,
   1158648, 386216, 116125)`. JP fixed a subtle Swift NSNumber bug
   here; verify the Swift fix is correct.

3. **`harness/wrap_rss.sh`** — every hyperfine run goes through this.
   If the wrapper is wrong, every memory number is wrong. Sanity-check
   the byte-count parsing against macOS's `/usr/bin/time -l` output.

4. **`harness/collect_static_metrics.py`** — defines M3/M4/M5.
   Check the source-path and artifact-path logic for each language,
   especially the `implements(lang, bench)` suite matrix and the
   Fortran/R/Python paths (interpreted tiers return `None` for artifacts).

5. **`paper/main.tex` §3.5(a)** — the cross-language checksum claim.
   This is the methodological backbone; if it's overstated, the paper
   is fragile.

6. **`paper/main.tex` Bibliography** — particularly `amazon2024rust`,
   `microsoft2023rust`, and `ojeda2022kernel`. JP
   wrote these from memory and **has not verified** they exist as
   cited. ICSE desk-rejects on hallucinated refs. **This is the
   highest-risk item on the paper.**

## Known issues / WIP

- `results/*.json` holds the systems-suite sweep (9 languages,
  2026-05-30) plus the AI-suite timing/memory for the seven languages
  whose runs have completed (c, cpp, rust, go, fortran, python, julia).
  Re-run `harness/run_all.sh` to add Java/Zig/Swift/Kotlin AI timings and
  regenerate static metrics for the merged suite on your hardware.
- The AI kernels for **Zig, Swift, Kotlin** are written but unverified
  on this host (Java verified). Confirm with
  `bash harness/verify_checksums.sh zig swift kotlin` on a machine with
  those toolchains before relying on their numbers.

## How to give feedback

Whatever workflow your team uses (PRs, comments on a Google Doc,
Slack). If you want to leave inline comments on the paper, the
LaTeX source is the source of truth — review `paper/main.tex`
rather than a rendered PDF.

For the COBOL A/B/C decision specifically, please react in the next
team review per the voting protocol at the end of the "Open question"
section in `README.md`.

## Contact

JP (`jplicona@themaic.com`). Async preferred; please leave comments
where you find them rather than holding for a sync meeting.
