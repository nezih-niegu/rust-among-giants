// K-Means (Lloyd's) — Data Mining benchmark (MICAI). Shared 64-bit LCG (seed 42),
// squared Euclidean distance, ties to lowest centroid. Kotlin ULong wraps mod
// 2^64 like the C unsigned LCG; floats printed via BigDecimal HALF_EVEN to match
// C printf's round-to-nearest-even.
import java.math.BigDecimal
import java.math.RoundingMode
const val N = 100000; const val D = 4; const val K = 10; const val ITERS = 1000
var state = 42uL
fun nextDouble(): Double {
    state = state * 6364136223846793005uL + 1442695040888963407uL
    return (state shr 33).toDouble() / (1uL shl 31).toDouble()
}
fun f6(v: Double) = BigDecimal(v).setScale(6, RoundingMode.HALF_EVEN).toPlainString()
fun main() {
    val points = DoubleArray(N * D)
    for (i in 0 until N) for (d in 0 until D) points[i*D+d] = nextDouble()
    val centroids = DoubleArray(K * D)
    for (k in 0 until K) for (d in 0 until D) centroids[k*D+d] = points[k*D+d]
    val assign = IntArray(N); val counts = LongArray(K); val sums = DoubleArray(K * D)
    for (it in 0 until ITERS) {
        for (i in 0 until N) {
            var best = 1e300; var bestk = 0
            for (k in 0 until K) {
                var dist = 0.0
                for (d in 0 until D) { val diff = points[i*D+d] - centroids[k*D+d]; dist += diff * diff }
                if (dist < best) { best = dist; bestk = k }
            }
            assign[i] = bestk
        }
        for (k in 0 until K) { counts[k] = 0; for (d in 0 until D) sums[k*D+d] = 0.0 }
        for (i in 0 until N) { val k = assign[i]; counts[k]++; for (d in 0 until D) sums[k*D+d] += points[i*D+d] }
        for (k in 0 until K) if (counts[k] > 0) for (d in 0 until D) centroids[k*D+d] = sums[k*D+d] / counts[k].toDouble()
    }
    var fingerprint = 0L; var centroidSum = 0.0
    for (k in 0 until K) { fingerprint += counts[k] * (k + 1).toLong(); for (d in 0 until D) centroidSum += centroids[k*D+d] }
    println("$fingerprint " + f6(centroidSum))
}
