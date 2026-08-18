! MLP training (forward + backprop, full-batch gradient descent) —
! Neural Network benchmark (MICAI). D->H->O, ReLU hidden, linear output, MSE.
! ReLU + MSE use only +,-,*,/ and max (no exp/softmax), so the result is
! bit-exact across languages. Shared 64-bit LCG (seed 42) for identical init.
! Checksum = final-epoch loss + sum of all weights (both 6 dp).
!
! Every dot-product accumulation below preserves the same operand order as the
! C reference, and the suite compiles with -ffp-contract=off so no accumulation
! is fused into an FMA (which would change the rounding versus the interpreted
! languages). Arrays are stored so the inner-loop index is contiguous; loop
! variables are multi-character to avoid aliasing the N/D/H/O/E parameters.
program mlp
  implicit none
  integer, parameter :: N = 10000, D = 16, H = 64, O = 4, E = 150
  real(8), parameter :: LR = 0.01d0

  integer(8) :: rng_state
  real(8) :: x(D, N), target(O, N)
  real(8) :: W1(D, H), b1(H), W2(H, O), b2(O)
  real(8) :: gW1(D, H), gb1(H), gW2(H, O), gb2(O)
  real(8) :: z1(H), a1(H), y(O), dy(O)
  real(8) :: scale, final_loss, epoch_loss, s, da, dz, diff, wsum
  integer :: nn, dimn, hh, oo, ee
  character(len=64) :: lbuf, wbuf

  rng_state = 42_8
  do hh = 1, H
     do dimn = 1, D
        W1(dimn, hh) = (next_double() * 2.0d0 - 1.0d0) * 0.1d0
     end do
     b1(hh) = 0.0d0
  end do
  do oo = 1, O
     do hh = 1, H
        W2(hh, oo) = (next_double() * 2.0d0 - 1.0d0) * 0.1d0
     end do
     b2(oo) = 0.0d0
  end do
  do nn = 1, N
     do dimn = 1, D
        x(dimn, nn) = next_double()
     end do
     do oo = 1, O
        target(oo, nn) = next_double()
     end do
  end do

  scale = LR / real(N, 8)
  final_loss = 0.0d0
  do ee = 1, E
     do hh = 1, H
        gb1(hh) = 0.0d0
        do dimn = 1, D
           gW1(dimn, hh) = 0.0d0
        end do
     end do
     do oo = 1, O
        gb2(oo) = 0.0d0
        do hh = 1, H
           gW2(hh, oo) = 0.0d0
        end do
     end do
     epoch_loss = 0.0d0
     do nn = 1, N
        do hh = 1, H
           s = b1(hh)
           do dimn = 1, D
              s = s + W1(dimn, hh) * x(dimn, nn)
           end do
           z1(hh) = s
           if (s > 0.0d0) then
              a1(hh) = s
           else
              a1(hh) = 0.0d0
           end if
        end do
        do oo = 1, O
           s = b2(oo)
           do hh = 1, H
              s = s + W2(hh, oo) * a1(hh)
           end do
           y(oo) = s
        end do
        do oo = 1, O
           diff = y(oo) - target(oo, nn)
           epoch_loss = epoch_loss + diff * diff
           dy(oo) = 2.0d0 * diff
        end do
        do oo = 1, O
           gb2(oo) = gb2(oo) + dy(oo)
           do hh = 1, H
              gW2(hh, oo) = gW2(hh, oo) + dy(oo) * a1(hh)
           end do
        end do
        do hh = 1, H
           da = 0.0d0
           do oo = 1, O
              da = da + W2(hh, oo) * dy(oo)
           end do
           if (z1(hh) > 0.0d0) then
              dz = da
           else
              dz = 0.0d0
           end if
           gb1(hh) = gb1(hh) + dz
           do dimn = 1, D
              gW1(dimn, hh) = gW1(dimn, hh) + dz * x(dimn, nn)
           end do
        end do
     end do
     do hh = 1, H
        b1(hh) = b1(hh) - scale * gb1(hh)
        do dimn = 1, D
           W1(dimn, hh) = W1(dimn, hh) - scale * gW1(dimn, hh)
        end do
     end do
     do oo = 1, O
        b2(oo) = b2(oo) - scale * gb2(oo)
        do hh = 1, H
           W2(hh, oo) = W2(hh, oo) - scale * gW2(hh, oo)
        end do
     end do
     final_loss = epoch_loss / real(N * O, 8)
  end do

  wsum = 0.0d0
  do hh = 1, H
     wsum = wsum + b1(hh)
     do dimn = 1, D
        wsum = wsum + W1(dimn, hh)
     end do
  end do
  do oo = 1, O
     wsum = wsum + b2(oo)
     do hh = 1, H
        wsum = wsum + W2(hh, oo)
     end do
  end do

  write(lbuf, '(F30.6)') final_loss
  write(wbuf, '(F30.6)') wsum
  write(*, '(A,1X,A)') trim(adjustl(lbuf)), trim(adjustl(wbuf))

contains

  function next_double() result(v)
    real(8) :: v
    rng_state = rng_state * 6364136223846793005_8 + 1442695040888963407_8
    v = real(ishft(rng_state, -33), 8) / real(ishft(1_8, 31), 8)
  end function next_double

end program mlp
