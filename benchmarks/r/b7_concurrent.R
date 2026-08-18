# B7: concurrent counter. Base R has no shared-memory threads, so the faithful
# single-process equivalent is a sequential count to 8*1e7 (same checksum).
counter <- 0
for (i in 1:80000000) counter <- counter + 1
cat(sprintf("%.0f\n", counter))
