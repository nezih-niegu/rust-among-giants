! B3: 2000x2000 dense FP64 matmul (ijk), shared LCG fill (interleaved A/B).
! Flat 0-based indexing and loop order mirror the C reference exactly; with
! -ffp-contract=off the accumulation is bit-identical. Output: sum of C (%.6f).
program b3_matrix_mul
  implicit none
  integer, parameter :: SZ = 2000
  integer(8) :: state
  real(8), allocatable :: A(:), B(:), C(:)
  real(8) :: a_ik, sm
  integer :: i, j, k
  character(len=64) :: buf
  allocate(A(SZ*SZ), B(SZ*SZ), C(SZ*SZ))
  state = 42_8
  do i = 0, SZ-1
     do j = 0, SZ-1
        A(i*SZ+j+1) = next_double()
        B(i*SZ+j+1) = next_double()
     end do
  end do
  C = 0.0d0
  do i = 0, SZ-1
     do k = 0, SZ-1
        a_ik = A(i*SZ+k+1)
        do j = 0, SZ-1
           C(i*SZ+j+1) = C(i*SZ+j+1) + a_ik * B(k*SZ+j+1)
        end do
     end do
  end do
  sm = 0.0d0
  do i = 0, SZ-1
     do j = 0, SZ-1
        sm = sm + C(i*SZ+j+1)
     end do
  end do
  write(buf, '(F30.6)') sm
  print '(A)', trim(adjustl(buf))
contains
  function next_double() result(v)
    real(8) :: v
    state = state * 6364136223846793005_8 + 1442695040888963407_8
    v = real(ishft(state, -33), 8) / real(ishft(1_8, 31), 8)
  end function
end program b3_matrix_mul
