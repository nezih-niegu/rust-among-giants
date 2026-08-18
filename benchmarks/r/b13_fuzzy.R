# Mamdani fuzzy inference system — Fuzzy Systems benchmark (MICAI).
# Two inputs -> 3 triangular sets each; 9-rule base; max-min aggregation;
# centroid defuzzification over a discretized output domain. Triangular MFs +
# centroid use only +,-,*,/,min,max, so the result is bit-exact across
# languages. Q input pairs drawn from the shared 64-bit LCG (seed 42).
# Checksum = sum of defuzzified outputs (6 dp). Scalar loops only.
Q <- 2000000L
NP <- 100L
NSET <- 3L
NRULE <- 9L

# set parameters (a, b, c) for Low, Med, High over [0,1] with shoulders
SETP <- matrix(c(-0.5, 0.0, 0.5,
                  0.0, 0.5, 1.0,
                  0.5, 1.0, 1.5), nrow = NSET, ncol = 3, byrow = TRUE)

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

# triangular membership: peak at b, zero outside (a, c)
tri <- function(v, a, b, c) {
  left <- (v - a) / (b - a)
  right <- (c - v) / (c - b)
  m <- if (left < right) left else right
  if (m > 0) m else 0
}

main <- function() {
  zval <- numeric(NP)
  os <- matrix(0, nrow = NSET, ncol = NP)   # os[s, j]
  for (j in 1:NP) {
    z <- (j - 1) / (NP - 1)
    zval[j] <- z
    for (s in 1:NSET)
      os[s, j] <- tri(z, SETP[s, 1], SETP[s, 2], SETP[s, 3])
  }
  outset <- integer(NRULE)
  for (xi in 1:NSET)
    for (yi in 1:NSET) {
      sm <- (xi - 1) + (yi - 1)
      outset[(xi - 1) * NSET + (yi - 1) + 1] <- if (sm <= 1) 1L else if (sm == 2) 2L else 3L
    }

  checksum <- 0
  mu_x <- numeric(NSET); mu_y <- numeric(NSET); fs <- numeric(NRULE)
  for (q in 1:Q) {
    x <- next_double()
    y <- next_double()
    for (s in 1:NSET) {
      mu_x[s] <- tri(x, SETP[s, 1], SETP[s, 2], SETP[s, 3])
      mu_y[s] <- tri(y, SETP[s, 1], SETP[s, 2], SETP[s, 3])
    }
    for (xi in 1:NSET)
      for (yi in 1:NSET) {
        a <- mu_x[xi]; b <- mu_y[yi]
        fs[(xi - 1) * NSET + (yi - 1) + 1] <- if (a < b) a else b
      }
    num <- 0; den <- 0
    for (j in 1:NP) {
      agg <- 0
      for (r in 1:NRULE) {
        osv <- os[outset[r], j]
        fr <- fs[r]
        m <- if (fr < osv) fr else osv
        if (m > agg) agg <- m
      }
      num <- num + zval[j] * agg
      den <- den + agg
    }
    out <- if (den > 0) num / den else 0
    checksum <- checksum + out
  }
  cat(sprintf("%.6f\n", checksum))
}

main()
