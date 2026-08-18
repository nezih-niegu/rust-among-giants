# B6: durable checkpoint I/O — write 4 GiB in 1 MiB chunks, read back, print
# total bytes, delete. Output: 4294967296.
args <- commandArgs(trailingOnly=TRUE)
fname <- if (length(args) >= 1) args[1] else "../../data/fileio_test_r.tmp"
chunk <- rep(as.raw(65L), 1024L*1024L)   # 'A'
NCH <- 4L*1024L
con <- file(fname, "wb")
for (i in 1:NCH) writeBin(chunk, con)
flush(con); close(con)
con <- file(fname, "rb")
total <- 0
repeat {
  r <- readBin(con, "raw", n=1024L*1024L)
  if (length(r) == 0) break
  total <- total + length(r)
}
close(con); invisible(file.remove(fname))
cat(sprintf("%.0f\n", total))
