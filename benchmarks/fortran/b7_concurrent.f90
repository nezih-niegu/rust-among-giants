! B7: concurrent counter — 8 threads x 1e7 atomic increments (OpenMP).
! num_threads(8) is fixed so the total is 80000000 regardless of core count,
! matching the C reference. Requires -fopenmp. Output: final counter.
program b7_concurrent
  use omp_lib
  implicit none
  integer(8) :: counter
  counter = 0_8
  !$omp parallel num_threads(8)
  block
    integer(8) :: i
    do i = 1, 10000000_8
       !$omp atomic
       counter = counter + 1_8
    end do
  end block
  !$omp end parallel
  print '(I0)', counter
end program b7_concurrent
