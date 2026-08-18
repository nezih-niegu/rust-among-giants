# k-NN classification — Machine Learning benchmark (MICAI).
# Same algorithm as the other languages; shared 64-bit LCG (seed 42);
# SQUARED Euclidean distance (no sqrt) for bit-exactness; vote ties break to
# the lowest class label. Checksum = sum of predicted labels (integer).
# Scalar loops only (the limb-based LCG keeps every draw bit-exact in doubles).
M <- 50000L
Q <- 10000L
D <- 8L
K <- 15L
C <- 3L

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
  train <- matrix(0, nrow = M, ncol = D)
  label <- integer(M)
  for (t in 1:M) {
    for (d in 1:D)
      train[t, d] <- next_double()
    label[t] <- as.integer(next_double() * C)
  }
  query <- matrix(0, nrow = Q, ncol = D)
  for (q in 1:Q)
    for (d in 1:D)
      query[q, d] <- next_double()

  checksum <- 0
  best_d <- numeric(K)
  best_l <- integer(K)
  for (q in 1:Q) {
    for (j in 1:K) { best_d[j] <- 1e300; best_l[j] <- 0L }
    for (t in 1:M) {
      dist <- 0
      for (d in 1:D) {
        diff <- query[q, d] - train[t, d]
        dist <- dist + diff * diff
      }
      if (dist < best_d[K]) {              # sorted-insert into ascending k-best
        p <- K
        while (p > 1 && dist < best_d[p - 1]) {
          best_d[p] <- best_d[p - 1]
          best_l[p] <- best_l[p - 1]
          p <- p - 1
        }
        best_d[p] <- dist
        best_l[p] <- label[t]
      }
    }
    votes <- integer(C)
    for (j in 1:K) votes[best_l[j] + 1] <- votes[best_l[j] + 1] + 1
    pred <- 0L                              # 0-based predicted class
    for (c in 1:(C - 1)) if (votes[c + 1] > votes[pred + 1]) pred <- c
    checksum <- checksum + pred
  }
  cat(sprintf("%.0f\n", checksum))
}

main()
