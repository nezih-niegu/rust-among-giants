! B6: durable checkpoint I/O — write 4 GiB in 1 MiB chunks, flush, read back,
! print total bytes, delete. Stream (unformatted) I/O; flush+close approximates
! the C fsync. Output: total bytes read (4294967296).
program b6_file_io
  implicit none
  integer, parameter :: CHUNK = 1024*1024
  integer(8), parameter :: TOTAL = 4_8*1024_8*1024_8*1024_8
  integer(8), parameter :: NCHUNKS = TOTAL / CHUNK
  character(len=1) :: buf(CHUNK)
  character(len=:), allocatable :: fname
  integer :: ios, ln, i, u
  integer(8) :: total_read, c
  character(len=1) :: rb(CHUNK)
  fname = "../../data/fileio_test_fortran.tmp"
  if (command_argument_count() >= 1) then
     call get_command_argument(1, length=ln); deallocate(fname); allocate(character(len=ln)::fname)
     call get_command_argument(1, fname)
  end if
  buf = 'A'
  open(newunit=u, file=fname, access='stream', form='unformatted', status='replace', action='write', iostat=ios)
  if (ios/=0) then; write(0,*)'open write fail'; stop 1; end if
  do i = 1, int(NCHUNKS)
     write(u) buf
  end do
  flush(u); close(u)
  open(newunit=u, file=fname, access='stream', form='unformatted', status='old', action='read', iostat=ios)
  if (ios/=0) then; write(0,*)'open read fail'; stop 1; end if
  total_read = 0_8
  do
     read(u, iostat=ios) rb
     if (ios /= 0) exit
     total_read = total_read + CHUNK
  end do
  close(u, status='delete')
  print '(I0)', total_read
end program b6_file_io
