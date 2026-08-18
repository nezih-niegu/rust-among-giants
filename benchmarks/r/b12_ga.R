# Genetic Algorithm minimizing the Rosenbrock function —
# Computational Intelligence benchmark (MICAI). Tournament selection, uniform
# crossover, uniform mutation. Rosenbrock + uniform mutation use only +,-,*,/,
# so the search is bit-exact across languages. Every random decision draws from
# the shared 64-bit LCG (seed 42) in identical order in all languages.
# Checksum = best fitness found + sum of the best individual's genes (6 dp).
# The mutation loop draws one value per gene and a second only when the gene
# mutates, reproducing the conditional draw order exactly. Scalar loops only.
D <- 30L
P <- 5000L
G <- 1200L
T <- 3L
MUT_RATE <- 0.1
MUT_STEP <- 0.1

# ── shared 64-bit LCG (seed 42) via 16-bit limbs ────────────────────────
.s0 <- 42; .s1 <- 0; .s2 <- 0; .s3 <- 0
.M0 <- 32557; .M1 <- 19605; .M2 <- 62509; .M3 <- 22609
.C0 <- 33103; .C1 <- 63335; .C2 <- 31614; .C3 <- 5125
.B16 <- 65536; .B32 <- 4294967296; .P15 <- 32768; .P33 <- 8589934592; .P31 <- 2147483648

next_double <- function() {
  p0 <- .s0*.M0
  p1 <- .s0*.M1 + .s1*.M0
  p2 <- .s0*.M2 + .s1*.M1 + .s2*.M0
  p3 <- .s0*.M3 + .s1*.M2 + .s2*.M1 + .s3*.M0
  r0 <- p0 %% .B16; cy <- (p0 - r0)/.B16
  t1 <- p1 + cy; r1 <- t1 %% .B16; cy <- (t1 - r1)/.B16
  t2 <- p2 + cy; r2 <- t2 %% .B16; cy <- (t2 - r2)/.B16
  t3 <- p3 + cy; r3 <- t3 %% .B16
  u0 <- r0 + .C0; n0 <- u0 %% .B16; cy <- (u0 - n0)/.B16
  u1 <- r1 + .C1 + cy; n1 <- u1 %% .B16; cy <- (u1 - n1)/.B16
  u2 <- r2 + .C2 + cy; n2 <- u2 %% .B16; cy <- (u2 - n2)/.B16
  u3 <- r3 + .C3 + cy; n3 <- u3 %% .B16
  .s0 <<- n0; .s1 <<- n1; .s2 <<- n2; .s3 <<- n3
  L <- n2*.B32 + n1*.B16 + n0
  (n3*.P15 + (L - (L %% .P33))/.P33) / .P31
}

rosenbrock <- function(x) {
  f <- 0
  for (i in 1:(D - 1)) {
    a <- x[i + 1] - x[i] * x[i]
    b <- 1 - x[i]
    f <- f + 100 * a * a + b * b
  }
  f
}

main <- function() {
  pop <- matrix(0, nrow = P, ncol = D)
  for (p in 1:P)
    for (d in 1:D)
      pop[p, d] <- (next_double() * 2 - 1) * 5   # genes in [-5, 5]
  newpop <- matrix(0, nrow = P, ncol = D)
  fitness <- numeric(P)
  best_genes <- numeric(D)

  best_fit <- 1e300
  for (g in 1:G) {
    for (p in 1:P) {
      f <- rosenbrock(pop[p, ])
      fitness[p] <- f
      if (f < best_fit) {
        best_fit <- f
        for (d in 1:D) best_genes[d] <- pop[p, d]
      }
    }
    for (d in 1:D) newpop[1, d] <- best_genes[d]   # elitism
    for (i in 2:P) {
      a <- as.integer(next_double() * P)            # 0-based
      for (t in 2:T) {
        idx <- as.integer(next_double() * P)
        if (fitness[idx + 1] < fitness[a + 1]) a <- idx
      }
      b <- as.integer(next_double() * P)
      for (t in 2:T) {
        idx <- as.integer(next_double() * P)
        if (fitness[idx + 1] < fitness[b + 1]) b <- idx
      }
      for (d in 1:D) {                               # uniform crossover (D draws)
        if (next_double() < 0.5) newpop[i, d] <- pop[a + 1, d]
        else newpop[i, d] <- pop[b + 1, d]
      }
      for (d in 1:D) {                               # uniform mutation (1 draw, +1 if fires)
        if (next_double() < MUT_RATE)
          newpop[i, d] <- newpop[i, d] + (next_double() * 2 - 1) * MUT_STEP
      }
    }
    for (p in 1:P)
      for (d in 1:D)
        pop[p, d] <- newpop[p, d]
  }

  gsum <- 0
  for (d in 1:D) gsum <- gsum + best_genes[d]
  cat(sprintf("%.6f %.6f\n", best_fit, gsum))
}

main()
