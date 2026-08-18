# MLP training (forward + backprop, full-batch gradient descent) —
# Neural Network benchmark (MICAI). D->H->O, ReLU hidden, linear output, MSE.
# ReLU + MSE use only +,-,*,/ and max (no exp/softmax), so the result is
# bit-exact across languages. Shared 64-bit LCG (seed 42) for identical init.
# Checksum = final-epoch loss + sum of all weights (both 6 dp).
# Scalar loops only; every dot-product accumulates in the same order as the
# C/Python reference, so no reassociation changes the rounding.
N <- 10000L
D <- 16L
H <- 64L
O <- 4L
E <- 150L
LR <- 0.01

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
  W1 <- matrix(0, nrow = H, ncol = D)
  b1 <- numeric(H)
  W2 <- matrix(0, nrow = O, ncol = H)
  b2 <- numeric(O)
  for (h in 1:H)
    for (d in 1:D)
      W1[h, d] <- (next_double() * 2 - 1) * 0.1
  for (o in 1:O)
    for (h in 1:H)
      W2[o, h] <- (next_double() * 2 - 1) * 0.1
  x <- matrix(0, nrow = N, ncol = D)
  target <- matrix(0, nrow = N, ncol = O)
  for (n in 1:N) {
    for (d in 1:D) x[n, d] <- next_double()
    for (o in 1:O) target[n, o] <- next_double()
  }

  z1 <- numeric(H); a1 <- numeric(H); y <- numeric(O); dy <- numeric(O)
  scale <- LR / N
  final_loss <- 0
  for (e in 1:E) {
    gW1 <- matrix(0, nrow = H, ncol = D); gb1 <- numeric(H)
    gW2 <- matrix(0, nrow = O, ncol = H); gb2 <- numeric(O)
    epoch_loss <- 0
    for (n in 1:N) {
      for (h in 1:H) {
        s <- b1[h]
        for (d in 1:D) s <- s + W1[h, d] * x[n, d]
        z1[h] <- s
        a1[h] <- if (s > 0) s else 0
      }
      for (o in 1:O) {
        s <- b2[o]
        for (h in 1:H) s <- s + W2[o, h] * a1[h]
        y[o] <- s
      }
      for (o in 1:O) {
        diff <- y[o] - target[n, o]
        epoch_loss <- epoch_loss + diff * diff
        dy[o] <- 2 * diff
      }
      for (o in 1:O) {
        gb2[o] <- gb2[o] + dy[o]
        for (h in 1:H) gW2[o, h] <- gW2[o, h] + dy[o] * a1[h]
      }
      for (h in 1:H) {
        da <- 0
        for (o in 1:O) da <- da + W2[o, h] * dy[o]
        dz <- if (z1[h] > 0) da else 0
        gb1[h] <- gb1[h] + dz
        for (d in 1:D) gW1[h, d] <- gW1[h, d] + dz * x[n, d]
      }
    }
    for (h in 1:H) {
      b1[h] <- b1[h] - scale * gb1[h]
      for (d in 1:D) W1[h, d] <- W1[h, d] - scale * gW1[h, d]
    }
    for (o in 1:O) {
      b2[o] <- b2[o] - scale * gb2[o]
      for (h in 1:H) W2[o, h] <- W2[o, h] - scale * gW2[o, h]
    }
    final_loss <- epoch_loss / (N * O)
  }

  wsum <- 0
  for (h in 1:H) {
    wsum <- wsum + b1[h]
    for (d in 1:D) wsum <- wsum + W1[h, d]
  }
  for (o in 1:O) {
    wsum <- wsum + b2[o]
    for (h in 1:H) wsum <- wsum + W2[o, h]
  }
  cat(sprintf("%.6f %.6f\n", final_loss, wsum))
}

main()
