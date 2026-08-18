import kotlin.random.Random
fun main() {
    val N = 100_000
    val rng = Random(42)
    val arr = IntArray(N) { rng.nextInt(N) }
    for (i in 0 until N - 1) {
        var swapped = false
        for (j in 0 until N - i - 1) {
            if (arr[j] > arr[j + 1]) { val t = arr[j]; arr[j] = arr[j+1]; arr[j+1] = t; swapped = true }
        }
        if (!swapped) break
    }
    println("${arr[0]} ${arr[N-1]}")
}
