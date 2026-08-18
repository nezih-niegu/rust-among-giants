fun fib(n: Int): Long = if (n <= 1) n.toLong() else fib(n - 1) + fib(n - 2)
fun main(args: Array<String>) {
    val n = if (args.isNotEmpty()) args[0].toInt() else 45
    println(fib(n))
}
