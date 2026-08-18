# K-Means clustering (Lloyd's algorithm) — Data Mining benchmark (MICAI).
# Same algorithm as the other languages; shared 64-bit LCG (seed 42);
# SQUARED Euclidean distance (no sqrt) keeps the inner loop bit-exact.
# Assignment ties break to the lowest centroid index (strict `<`).
#
# R has no native 64-bit unsigned integer, so the LCG is emulated with four
# 16-bit limbs held in doubles: every partial product stays below 2^53 and is
# therefore exact, making each draw bit-identical to the C/Python reference.
# Implemented with scalar loops (no vectorised/BLAS shortcuts) so the benchmark
# measures the R language itself, consistent with the other implementations.
N <- 100000L
D <- 4L
K <- 10L
ITERS <- 1000L  # sized so C ~0.8s

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

main <- function() {
  points <- matrix(0, nrow = N, ncol = D)
  for (i in 1:N)
    for (d in 1:D)
      points[i, d] <- next_double()

  centroids <- matrix(0, nrow = K, ncol = D)
  for (k in 1:K)
    for (d in 1:D)
      centroids[k, d] <- points[k, d]

  assign <- integer(N)
  counts <- numeric(K)

  for (it in 1:ITERS) {
    for (i in 1:N) {
      best <- 1e300
      bestk <- 1L
      for (k in 1:K) {
        dist <- 0
        for (d in 1:D) {
          diff <- points[i, d] - centroids[k, d]
          dist <- dist + diff * diff
        }
        if (dist < best) {
          best <- dist
          bestk <- k
        }
      }
      assign[i] <- bestk
    }
    for (k in 1:K) counts[k] <- 0
    sums <- matrix(0, nrow = K, ncol = D)
    for (i in 1:N) {
      k <- assign[i]
      counts[k] <- counts[k] + 1
      for (d in 1:D)
        sums[k, d] <- sums[k, d] + points[i, d]
    }
    for (k in 1:K) {
      if (counts[k] > 0) {
        for (d in 1:D)
          centroids[k, d] <- sums[k, d] / counts[k]
      }
    }
  }

  fingerprint <- 0
  centroid_sum <- 0
  for (k in 1:K) {
    fingerprint <- fingerprint + counts[k] * k   # 1-based k == (k+1) weight
    for (d in 1:D)
      centroid_sum <- centroid_sum + centroids[k, d]
  }
  cat(sprintf("%.0f %.6f\n", fingerprint, centroid_sum))
}

main()
