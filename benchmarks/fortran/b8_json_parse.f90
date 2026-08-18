! B8: JSON node counting matching cJSON semantics (objects '{', arrays '[',
! string VALUES — a string followed by ':' is a key and is NOT counted —
! numbers, true/false bools, nulls). Reads the whole file via stream I/O and
! scans tokens. Output: objects=.. arrays=.. strings=.. numbers=.. bools=.. nulls=..
program b8_json_parse
  implicit none
  character(len=:), allocatable :: fname, buf
  integer :: u, ios, ln
  integer(8) :: fsize, i, j, k
  integer(8) :: obj, arr, strv, num, boo, nul
  character :: c
  fname = "../../data/json_input.json"
  if (command_argument_count() >= 1) then
     call get_command_argument(1, length=ln); deallocate(fname); allocate(character(len=ln)::fname)
     call get_command_argument(1, fname)
  end if
  open(newunit=u, file=fname, access='stream', form='unformatted', status='old', action='read', iostat=ios)
  if (ios/=0) then; write(0,*)'cannot open ',fname; stop 1; end if
  inquire(unit=u, size=fsize)
  allocate(character(len=fsize) :: buf)
  read(u) buf
  close(u)
  obj=0; arr=0; strv=0; num=0; boo=0; nul=0
  i = 1
  do while (i <= fsize)
     c = buf(i:i)
     select case (c)
     case ('{'); obj = obj + 1; i = i + 1
     case ('['); arr = arr + 1; i = i + 1
     case ('"')
        j = i + 1
        do while (j <= fsize)
           if (buf(j:j) == '\') then; j = j + 2; cycle; end if
           if (buf(j:j) == '"') exit
           j = j + 1
        end do
        ! j points at closing quote; skip whitespace after
        k = j + 1
        do while (k <= fsize)
           if (buf(k:k)==' '.or.buf(k:k)==char(9).or.buf(k:k)==char(10).or.buf(k:k)==char(13)) then
              k = k + 1
           else
              exit
           end if
        end do
        if (k <= fsize .and. buf(k:k) == ':') then
           ! key — not counted
        else
           strv = strv + 1
        end if
        i = j + 1
     case ('t')
        if (i+3 <= fsize .and. buf(i:i+3)=='true') then; boo=boo+1; i=i+4; else; i=i+1; end if
     case ('f')
        if (i+4 <= fsize .and. buf(i:i+4)=='false') then; boo=boo+1; i=i+5; else; i=i+1; end if
     case ('n')
        if (i+3 <= fsize .and. buf(i:i+3)=='null') then; nul=nul+1; i=i+4; else; i=i+1; end if
     case ('-','0','1','2','3','4','5','6','7','8','9')
        j = i + 1
        do while (j <= fsize)
           c = buf(j:j)
           if ((c>='0'.and.c<='9').or.c=='.'.or.c=='e'.or.c=='E'.or.c=='+'.or.c=='-') then
              j = j + 1
           else
              exit
           end if
        end do
        num = num + 1; i = j
     case default
        i = i + 1
     end select
  end do
  write(*,'(A,I0,A,I0,A,I0,A,I0,A,I0,A,I0)') &
       'objects=',obj,' arrays=',arr,' strings=',strv,' numbers=',num,' bools=',boo,' nulls=',nul
end program b8_json_parse
