! B1: recursive Fibonacci (n=45) — function-call overhead. Output: fib(n).
program b1_fibonacci
  implicit none
  integer :: n
  character(len=32) :: arg
  n = 45
  if (command_argument_count() >= 1) then
     call get_command_argument(1, arg); read(arg, *) n
  end if
  print '(I0)', fib(n)
contains
  recursive function fib(m) result(r)
    integer, intent(in) :: m
    integer(8) :: r
    if (m <= 1) then
       r = int(m, 8)
    else
       r = fib(m-1) + fib(m-2)
    end if
  end function fib
end program b1_fibonacci
