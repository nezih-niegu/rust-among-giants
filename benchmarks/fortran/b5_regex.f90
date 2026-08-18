! B5: count lines containing an email-like match for the POSIX ERE
!   [a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}
! Hand-rolled scanner (Fortran has no stdlib regex). For each '@': require a
! local-part char immediately before, and in the maximal [A-Za-z0-9.-] run after
! it a '.' (with >=1 domain char before it) followed by >=2 letters.
program b5_regex
  implicit none
  character(len=:), allocatable :: fname
  character(len=8192) :: line
  integer :: ios, nargs, ln, count
  fname = "../../data/regex_input.txt"
  nargs = command_argument_count()
  if (nargs >= 1) then
     call get_command_argument(1, length=ln)
     deallocate(fname); allocate(character(len=ln) :: fname)
     call get_command_argument(1, fname)
  end if
  open(10, file=fname, status='old', action='read', iostat=ios)
  if (ios /= 0) then; write(0,*) 'cannot open ', fname; stop 1; end if
  count = 0
  do
     read(10, '(A)', iostat=ios) line
     if (ios /= 0) exit
     if (line_matches(trim(line))) count = count + 1
  end do
  close(10)
  print '(I0)', count
contains
  logical function is_local(c)
    character, intent(in) :: c
    is_local = (c>='a'.and.c<='z').or.(c>='A'.and.c<='Z').or.(c>='0'.and.c<='9') &
               .or. c=='.'.or.c=='_'.or.c=='%'.or.c=='+'.or.c=='-'
  end function
  logical function is_dom(c)
    character, intent(in) :: c
    is_dom = (c>='a'.and.c<='z').or.(c>='A'.and.c<='Z').or.(c>='0'.and.c<='9') &
             .or. c=='.'.or.c=='-'
  end function
  logical function is_alpha(c)
    character, intent(in) :: c
    is_alpha = (c>='a'.and.c<='z').or.(c>='A'.and.c<='Z')
  end function
  logical function line_matches(s)
    character(len=*), intent(in) :: s
    integer :: p, e, d, L
    line_matches = .false.
    L = len(s)
    do p = 2, L
       if (s(p:p) /= '@') cycle
       if (.not. is_local(s(p-1:p-1))) cycle
       ! maximal domain run [p+1, e]
       e = p
       do while (e < L)
          if (.not. is_dom(s(e+1:e+1))) exit
          e = e + 1
       end do
       if (e < p+2) cycle        ! need >=1 domain char then a '.'
       ! find a '.' at d in [p+2, e] with >=2 letters after, within run
       do d = p+2, e-2
          if (s(d:d)=='.' .and. is_alpha(s(d+1:d+1)) .and. is_alpha(s(d+2:d+2))) then
             line_matches = .true.; return
          end if
       end do
    end do
  end function
end program b5_regex
