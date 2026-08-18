# B5: count lines matching an email-like POSIX ERE. Vectorised grepl — fast.
args <- commandArgs(trailingOnly=TRUE)
fname <- if (length(args) >= 1) args[1] else "../../data/regex_input.txt"
pat <- "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}"
lines <- readLines(fname, warn=FALSE)
cat(sum(grepl(pat, lines)), "\n", sep="")
