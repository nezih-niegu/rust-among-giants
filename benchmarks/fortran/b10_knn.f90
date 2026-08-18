! k-NN classification — Machine Learning benchmark (MICAI).
! Same algorithm as the other languages; shared 64-bit LCG (seed 42);
! SQUARED Euclidean distance (no sqrt) for bit-exactness; vote ties break to
! the lowest class label. Checksum = sum of predicted labels (integer).
!
! NOTE on Fortran case-insensitivity: the parameters M, Q, D, K, C share their
! spelling with any same-letter loop variable, so all loop indices below use
! multi-character names (tt, qq, dimn, jj, cls, pp) to avoid silently aliasing a
! parameter. Sorted-insert into the k-best list is written with an explicit
! exit test (Fortran .and. is not guaranteed to short-circuit, unlike C's &&).
program knn
  implicit none
  integer, parameter :: M = 50000, Q = 10000, D = 8, K = 15, C = 3

  integer(8) :: rng_state
  real(8) :: train(D, M), query(D, Q)
  integer :: label(M)
  real(8) :: best_d(K), dist, diff
  integer :: best_l(K), votes(C)
  integer :: tt, qq, dimn, jj, cls, pp, pred
  integer(8) :: checksum

  rng_state = 42_8
  do tt = 1, M
     do dimn = 1, D
        train(dimn, tt) = next_double()
     end do
     label(tt) = int(next_double() * real(C, 8))
  end do
  do qq = 1, Q
     do dimn = 1, D
        query(dimn, qq) = next_double()
     end do
  end do

  checksum = 0_8
  do qq = 1, Q
     do jj = 1, K
        best_d(jj) = 1.0d300
        best_l(jj) = 0
     end do
     do tt = 1, M
        dist = 0.0d0
        do dimn = 1, D
           diff = query(dimn, qq) - train(dimn, tt)
           dist = dist + diff * diff
        end do
        if (dist < best_d(K)) then        ! sorted-insert into ascending k-best
           pp = K
           do
              if (pp <= 1) exit
              if (.not. (dist < best_d(pp - 1))) exit
              best_d(pp) = best_d(pp - 1)
              best_l(pp) = best_l(pp - 1)
              pp = pp - 1
           end do
           best_d(pp) = dist
           best_l(pp) = label(tt)
        end if
     end do
     do cls = 1, C
        votes(cls) = 0
     end do
     do jj = 1, K
        votes(best_l(jj) + 1) = votes(best_l(jj) + 1) + 1
     end do
     pred = 0                              ! 0-based predicted class
     do cls = 1, C - 1
        if (votes(cls + 1) > votes(pred + 1)) pred = cls
     end do
     checksum = checksum + int(pred, 8)
  end do

  write(*, '(I0)') checksum

contains

  function next_double() result(v)
    real(8) :: v
    rng_state = rng_state * 6364136223846793005_8 + 1442695040888963407_8
    v = real(ishft(rng_state, -33), 8) / real(ishft(1_8, 31), 8)
  end function next_double

end program knn
