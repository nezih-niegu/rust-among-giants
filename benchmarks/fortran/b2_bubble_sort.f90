! B2: bubble sort of 100000 ints — memory-access/cache behaviour.
! Values come from the shared 64-bit LCG (seed 42), matching the other
! LCG-based languages: arr(i) = (state>>33) mod N. Output: min and max.
program b2_bubble_sort
  implicit none
  integer, parameter :: N = 100000
  integer(8) :: state
  integer :: arr(N), i, j, tmp
  logical :: swapped
  state = 42_8
  do i = 1, N
     state = state * 6364136223846793005_8 + 1442695040888963407_8
     arr(i) = int(mod(ishft(state, -33), int(N, 8)), 4)
  end do
  do i = 1, N - 1
     swapped = .false.
     do j = 1, N - i
        if (arr(j) > arr(j+1)) then
           tmp = arr(j); arr(j) = arr(j+1); arr(j+1) = tmp; swapped = .true.
        end if
     end do
     if (.not. swapped) exit
  end do
  print '(I0,1X,I0)', arr(1), arr(N)
end program b2_bubble_sort
