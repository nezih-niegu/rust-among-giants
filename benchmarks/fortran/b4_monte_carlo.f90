! B4: Monte Carlo pi, 1e9 iterations, shared LCG. Output: pi (%.10f).
program b4_monte_carlo
  implicit none
  integer(8), parameter :: ITERS = 1000000000_8
  integer(8) :: state, inside, i
  real(8) :: x, y, pi
  character(len=64) :: buf
  state = 42_8
  inside = 0_8
  do i = 1, ITERS
     x = next_double()
     y = next_double()
     if (x*x + y*y <= 1.0d0) inside = inside + 1_8
  end do
  pi = 4.0d0 * real(inside, 8) / real(ITERS, 8)
  write(buf, '(F30.10)') pi
  print '(A)', trim(adjustl(buf))
contains
  function next_double() result(v)
    real(8) :: v
    state = state * 6364136223846793005_8 + 1442695040888963407_8
    v = real(ishft(state, -33), 8) / real(ishft(1_8, 31), 8)
  end function
end program b4_monte_carlo
