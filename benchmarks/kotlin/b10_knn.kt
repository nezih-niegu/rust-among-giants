// k-NN classification — Machine Learning benchmark (MICAI). Shared LCG (seed 42),
// squared Euclidean distance, vote ties to lowest class. Checksum = sum of labels.
const val M = 50000; const val Q = 10000; const val D = 8; const val K = 15; const val C = 3
var state = 42uL
fun nextDouble(): Double {
    state = state * 6364136223846793005uL + 1442695040888963407uL
    return (state shr 33).toDouble() / (1uL shl 31).toDouble()
}
fun main() {
    val train = DoubleArray(M * D); val label = IntArray(M)
    for (t in 0 until M) { for (d in 0 until D) train[t*D+d] = nextDouble(); label[t] = (nextDouble() * C).toInt() }
    val query = DoubleArray(Q * D)
    for (q in 0 until Q) for (d in 0 until D) query[q*D+d] = nextDouble()
    var checksum = 0L
    val bestD = DoubleArray(K); val bestL = IntArray(K)
    for (q in 0 until Q) {
        for (j in 0 until K) { bestD[j] = 1e300; bestL[j] = 0 }
        for (t in 0 until M) {
            var dist = 0.0
            for (d in 0 until D) { val diff = query[q*D+d] - train[t*D+d]; dist += diff * diff }
            if (dist < bestD[K-1]) {
                var p = K - 1
                while (p > 0 && dist < bestD[p-1]) { bestD[p] = bestD[p-1]; bestL[p] = bestL[p-1]; p-- }
                bestD[p] = dist; bestL[p] = label[t]
            }
        }
        val votes = IntArray(C)
        for (j in 0 until K) votes[bestL[j]]++
        var pred = 0
        for (c in 1 until C) if (votes[c] > votes[pred]) pred = c
        checksum += pred
    }
    println(checksum)
}
