fun main() {
    val ITERATIONS = 1_000_000_000L
    var state = 42uL
    var inside = 0L
    for (i in 0 until ITERATIONS) {
        state = state * 6364136223846793005uL + 1442695040888963407uL
        val x = (state shr 33).toDouble() / (1uL shl 31).toDouble()
        state = state * 6364136223846793005uL + 1442695040888963407uL
        val y = (state shr 33).toDouble() / (1uL shl 31).toDouble()
        if (x * x + y * y <= 1.0) inside++
    }
    println("%.10f".format(4.0 * inside / ITERATIONS))
}
