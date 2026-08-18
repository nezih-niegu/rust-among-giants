# B3: 2000x2000 FP64 matmul (ijk), LCG fill. Scalar (no BLAS) — slow tier.
# shared 64-bit LCG (seed 42) via 16-bit limbs — bit-identical to C/Python
.s0 <- 42; .s1 <- 0; .s2 <- 0; .s3 <- 0
.M0 <- 32557; .M1 <- 19605; .M2 <- 62509; .M3 <- 22609
.C0 <- 33103; .C1 <- 63335; .C2 <- 31614; .C3 <- 5125
.B16 <- 65536; .B32 <- 4294967296; .P15 <- 32768; .P33 <- 8589934592; .P31 <- 2147483648
next_double <- function() {
  p0 <- .s0*.M0; p1 <- .s0*.M1 + .s1*.M0
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
SZ <- 2000L
A <- numeric(SZ*SZ); B <- numeric(SZ*SZ); C <- numeric(SZ*SZ)
for (i in 0:(SZ-1)) for (j in 0:(SZ-1)) { A[i*SZ+j+1] <- next_double(); B[i*SZ+j+1] <- next_double() }
for (i in 0:(SZ-1)) for (k in 0:(SZ-1)) {
  a_ik <- A[i*SZ+k+1]
  for (j in 0:(SZ-1)) C[i*SZ+j+1] <- C[i*SZ+j+1] + a_ik * B[k*SZ+j+1]
}
cat(sprintf("%.6f\n", sum(C)))
