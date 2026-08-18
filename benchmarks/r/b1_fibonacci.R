# B1: recursive Fibonacci (n=45). Scalar recursion — slow tier in R.
fib <- function(n) if (n <= 1) n else fib(n-1) + fib(n-2)
args <- commandArgs(trailingOnly=TRUE)
n <- if (length(args) >= 1) as.integer(args[1]) else 45L
cat(sprintf("%.0f\n", fib(n)))
