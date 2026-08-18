! K-Means clustering (Lloyd's algorithm) — Data Mining benchmark (MICAI).
! Same algorithm as the other languages; shared 64-bit LCG (seed 42);
! SQUARED Euclidean distance (no sqrt) keeps the inner loop bit-exact.
! Assignment ties break to the lowest centroid index (strict `<`).
!
! The 64-bit LCG uses INTEGER(8) (two's-complement wraps modulo 2^64 exactly as
! the unsigned C version does) and ISHFT(state,-33) for the *logical* (zero-fill)
! right shift, so every draw is bit-identical to the C/Python reference.
! Arrays are column-major (points(d,i) contiguous per point) and the LCG is
! consumed in (point i, dim d) order to match the row-major languages exactly.
program kmeans
  implicit none
  integer, parameter :: N = 100000, D = 4, K = 10, ITERS = 1000

  integer(8) :: rng_state
  real(8) :: points(D, N), centroids(D, K), sums(D, K)
  integer(8) :: counts(K)
  integer :: assign(N)
  integer :: i, dd, kk, it, bestk
  integer(8) :: fingerprint
  real(8) :: best, dist, diff, centroid_sum
  character(len=64) :: fbuf

  rng_state = 42_8
  do i = 1, N
     do dd = 1, D
        points(dd, i) = next_double()
     end do
  end do

  do kk = 1, K
     do dd = 1, D
        centroids(dd, kk) = points(dd, kk)
     end do
  end do

  do it = 1, ITERS
     ! assignment step
     do i = 1, N
        best = 1.0d300
        bestk = 1
        do kk = 1, K
           dist = 0.0d0
           do dd = 1, D
              diff = points(dd, i) - centroids(dd, kk)
              dist = dist + diff * diff
           end do
           if (dist < best) then
              best = dist
              bestk = kk
           end if
        end do
        assign(i) = bestk
     end do
     ! update step
     do kk = 1, K
        counts(kk) = 0_8
        do dd = 1, D
           sums(dd, kk) = 0.0d0
        end do
     end do
     do i = 1, N
        kk = assign(i)
        counts(kk) = counts(kk) + 1_8
        do dd = 1, D
           sums(dd, kk) = sums(dd, kk) + points(dd, i)
        end do
     end do
     do kk = 1, K
        if (counts(kk) > 0_8) then
           do dd = 1, D
              centroids(dd, kk) = sums(dd, kk) / real(counts(kk), 8)
           end do
        end if
     end do
  end do

  fingerprint = 0_8
  centroid_sum = 0.0d0
  do kk = 1, K
     fingerprint = fingerprint + counts(kk) * int(kk, 8)  ! 1-based kk == (k+1) weight
     do dd = 1, D
        centroid_sum = centroid_sum + centroids(dd, kk)
     end do
  end do

  write(fbuf, '(F30.6)') centroid_sum
  write(*, '(I0,1X,A)') fingerprint, trim(adjustl(fbuf))

contains

  function next_double() result(v)
    real(8) :: v
    rng_state = rng_state * 6364136223846793005_8 + 1442695040888963407_8
    v = real(ishft(rng_state, -33), 8) / real(ishft(1_8, 31), 8)
  end function next_double

end program kmeans
