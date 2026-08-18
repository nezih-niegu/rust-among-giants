function fib(n::Int)::Int64
    n <= 1 && return n
    return fib(n - 1) + fib(n - 2)
end
n = length(ARGS) > 0 ? parse(Int, ARGS[1]) : 45
println(fib(n))
