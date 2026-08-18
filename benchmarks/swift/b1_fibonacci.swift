func fib(_ n: Int) -> Int {
    if n <= 1 { return n }
    return fib(n - 1) + fib(n - 2)
}
let n = CommandLine.arguments.count > 1 ? Int(CommandLine.arguments[1])! : 45
print(fib(n))
