! Genetic Algorithm minimizing the Rosenbrock function —
! Computational Intelligence benchmark (MICAI). Tournament selection, uniform
! crossover, uniform mutation. Rosenbrock + uniform mutation use only +,-,*,/,
! so the search is bit-exact across languages. Every random decision draws from
! the shared 64-bit LCG (seed 42) in identical order in all languages.
! Checksum = best fitness found + sum of the best individual's genes (6 dp).
!
! The mutation loop draws ONE LCG value per gene unconditionally and a SECOND
! only when that gene mutates; this conditional draw order is reproduced exactly
! so the RNG stream stays aligned with the reference. Selection indices are kept
! 0-based (as in C) and offset by +1 only when indexing 1-based Fortran arrays.
! Loop variables are multi-character to avoid aliasing the D/P/G/T parameters.
program ga
  implicit none
  integer, parameter :: D = 30, P = 5000, G = 1200, T = 3
  real(8), parameter :: MUT_RATE = 0.1d0, MUT_STEP = 0.1d0

  integer(8) :: rng_state
  real(8) :: pop(D, P), newpop(D, P), fitness(P), best_genes(D)
  real(8) :: best_fit, f, gsum
  integer :: dimn, pp, gg, tt, aidx, bidx, idx, ii
  character(len=64) :: fbuf, gbuf

  rng_state = 42_8
  do pp = 1, P
     do dimn = 1, D
        pop(dimn, pp) = (next_double() * 2.0d0 - 1.0d0) * 5.0d0   ! genes in [-5, 5]
     end do
  end do

  best_fit = 1.0d300
  do gg = 1, G
     do pp = 1, P
        f = rosenbrock(pop(:, pp))
        fitness(pp) = f
        if (f < best_fit) then
           best_fit = f
           do dimn = 1, D
              best_genes(dimn) = pop(dimn, pp)
           end do
        end if
     end do
     do dimn = 1, D                          ! elitism: newpop(0) = best
        newpop(dimn, 1) = best_genes(dimn)
     end do
     do ii = 2, P
        aidx = int(next_double() * real(P, 8))            ! 0-based
        do tt = 2, T
           idx = int(next_double() * real(P, 8))
           if (fitness(idx + 1) < fitness(aidx + 1)) aidx = idx
        end do
        bidx = int(next_double() * real(P, 8))
        do tt = 2, T
           idx = int(next_double() * real(P, 8))
           if (fitness(idx + 1) < fitness(bidx + 1)) bidx = idx
        end do
        do dimn = 1, D                        ! uniform crossover (D draws)
           if (next_double() < 0.5d0) then
              newpop(dimn, ii) = pop(dimn, aidx + 1)
           else
              newpop(dimn, ii) = pop(dimn, bidx + 1)
           end if
        end do
        do dimn = 1, D                        ! uniform mutation (1 draw, +1 if it fires)
           if (next_double() < MUT_RATE) then
              newpop(dimn, ii) = newpop(dimn, ii) + (next_double() * 2.0d0 - 1.0d0) * MUT_STEP
           end if
        end do
     end do
     do pp = 1, P
        do dimn = 1, D
           pop(dimn, pp) = newpop(dimn, pp)
        end do
     end do
  end do

  gsum = 0.0d0
  do dimn = 1, D
     gsum = gsum + best_genes(dimn)
  end do

  write(fbuf, '(F30.6)') best_fit
  write(gbuf, '(F30.6)') gsum
  write(*, '(A,1X,A)') trim(adjustl(fbuf)), trim(adjustl(gbuf))

contains

  function rosenbrock(xx) result(fval)
    real(8), intent(in) :: xx(D)
    real(8) :: fval, a, b
    integer :: jj
    fval = 0.0d0
    do jj = 1, D - 1
       a = xx(jj + 1) - xx(jj) * xx(jj)
       b = 1.0d0 - xx(jj)
       fval = fval + 100.0d0 * a * a + b * b
    end do
  end function rosenbrock

  function next_double() result(v)
    real(8) :: v
    rng_state = rng_state * 6364136223846793005_8 + 1442695040888963407_8
    v = real(ishft(rng_state, -33), 8) / real(ishft(1_8, 31), 8)
  end function next_double

end program ga
