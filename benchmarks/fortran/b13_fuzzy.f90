! Mamdani fuzzy inference system — Fuzzy Systems benchmark (MICAI).
! Two inputs -> 3 triangular sets each; 9-rule base; max-min aggregation;
! centroid defuzzification over a discretized output domain. Triangular MFs +
! centroid use only +,-,*,/,min,max, so the result is bit-exact across
! languages. Q input pairs drawn from the shared 64-bit LCG (seed 42).
! Checksum = sum of defuzzified outputs (6 dp).
!
! NP, NSET and NRULE are spelled out (not single letters) to dodge Fortran's
! case-insensitive aliasing; loop variables jj/ss/xi/yi/rr/qq are likewise
! multi-character. Compiled with -ffp-contract=off so the centroid accumulation
! matches the interpreted reference operation-for-operation.
program fuzzy
  implicit none
  integer, parameter :: Q = 2000000, NP = 100, NSET = 3, NRULE = 9

  ! set parameters (a, b, c) for Low, Med, High over [0,1] with shoulders
  real(8), parameter :: SETP(3, NSET) = reshape( &
       [ -0.5d0, 0.0d0, 0.5d0, &
          0.0d0, 0.5d0, 1.0d0, &
          0.5d0, 1.0d0, 1.5d0 ], [3, NSET])

  integer(8) :: rng_state
  real(8) :: zval(NP), os(NP, NSET)
  integer :: outset(NRULE)
  real(8) :: mu_x(NSET), mu_y(NSET), fs(NRULE)
  real(8) :: z, xv, yv, num, den, agg, osv, mval, fval, checksum
  integer :: jj, ss, xi, yi, rr, qq, summ
  character(len=64) :: cbuf

  do jj = 1, NP
     z = real(jj - 1, 8) / real(NP - 1, 8)
     zval(jj) = z
     do ss = 1, NSET
        os(jj, ss) = tri(z, SETP(1, ss), SETP(2, ss), SETP(3, ss))
     end do
  end do
  do xi = 1, NSET
     do yi = 1, NSET
        summ = (xi - 1) + (yi - 1)
        if (summ <= 1) then
           outset((xi - 1) * NSET + (yi - 1) + 1) = 1
        else if (summ == 2) then
           outset((xi - 1) * NSET + (yi - 1) + 1) = 2
        else
           outset((xi - 1) * NSET + (yi - 1) + 1) = 3
        end if
     end do
  end do

  rng_state = 42_8
  checksum = 0.0d0
  do qq = 1, Q
     xv = next_double()
     yv = next_double()
     do ss = 1, NSET
        mu_x(ss) = tri(xv, SETP(1, ss), SETP(2, ss), SETP(3, ss))
        mu_y(ss) = tri(yv, SETP(1, ss), SETP(2, ss), SETP(3, ss))
     end do
     do xi = 1, NSET
        do yi = 1, NSET
           if (mu_x(xi) < mu_y(yi)) then
              fs((xi - 1) * NSET + (yi - 1) + 1) = mu_x(xi)
           else
              fs((xi - 1) * NSET + (yi - 1) + 1) = mu_y(yi)
           end if
        end do
     end do
     num = 0.0d0
     den = 0.0d0
     do jj = 1, NP
        agg = 0.0d0
        do rr = 1, NRULE
           osv = os(jj, outset(rr))
           fval = fs(rr)
           if (fval < osv) then
              mval = fval
           else
              mval = osv
           end if
           if (mval > agg) agg = mval
        end do
        num = num + zval(jj) * agg
        den = den + agg
     end do
     if (den > 0.0d0) then
        checksum = checksum + num / den
     end if
  end do

  write(cbuf, '(F30.6)') checksum
  write(*, '(A)') trim(adjustl(cbuf))

contains

  ! triangular membership: peak at b, zero outside (a, c)
  function tri(v, a, b, c) result(m)
    real(8), intent(in) :: v, a, b, c
    real(8) :: m, left, right
    left = (v - a) / (b - a)
    right = (c - v) / (c - b)
    if (left < right) then
       m = left
    else
       m = right
    end if
    if (m <= 0.0d0) m = 0.0d0
  end function tri

  function next_double() result(v)
    real(8) :: v
    rng_state = rng_state * 6364136223846793005_8 + 1442695040888963407_8
    v = real(ishft(rng_state, -33), 8) / real(ishft(1_8, 31), 8)
  end function next_double

end program fuzzy
