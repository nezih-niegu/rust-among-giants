var rngState: ULong = 42UL
fun nextDouble(): Double {
    rngState = rngState * 6364136223846793005UL + 1442695040888963407UL
    return (rngState shr 33).toDouble() / (1UL shl 31).toDouble()
}

fun main() {
    val SIZE = 2000
    val A = DoubleArray(SIZE * SIZE)
    val B = DoubleArray(SIZE * SIZE)
    val C = DoubleArray(SIZE * SIZE)
    for (i in 0 until SIZE * SIZE) { A[i] = nextDouble(); B[i] = nextDouble() }
    for (i in 0 until SIZE)
        for (k in 0 until SIZE) {
            val aik = A[i * SIZE + k]
            for (j in 0 until SIZE) C[i * SIZE + j] += aik * B[k * SIZE + j]
        }
    println("%.6f".format(C.sum()))
}
