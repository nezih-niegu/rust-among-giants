// MLP training (forward + backprop, full-batch GD) — Neural Network benchmark
// (MICAI). D->H->O, ReLU hidden, linear output, MSE; only +,-,*,/ and max, so
// bit-exact. The JVM does not contract a*b+c into an FMA (JLS strict FP).
import java.math.BigDecimal
import java.math.RoundingMode
const val N = 10000; const val D = 16; const val H = 64; const val O = 4; const val E = 150
const val LR = 0.01
var state = 42uL
fun nextDouble(): Double {
    state = state * 6364136223846793005uL + 1442695040888963407uL
    return (state shr 33).toDouble() / (1uL shl 31).toDouble()
}
fun f6(v: Double) = BigDecimal(v).setScale(6, RoundingMode.HALF_EVEN).toPlainString()
fun main() {
    val W1 = DoubleArray(H * D); val b1 = DoubleArray(H)
    val W2 = DoubleArray(O * H); val b2 = DoubleArray(O)
    for (h in 0 until H) for (d in 0 until D) W1[h*D+d] = (nextDouble() * 2 - 1) * 0.1
    for (o in 0 until O) for (h in 0 until H) W2[o*H+h] = (nextDouble() * 2 - 1) * 0.1
    val x = DoubleArray(N * D); val target = DoubleArray(N * O)
    for (n in 0 until N) { for (d in 0 until D) x[n*D+d] = nextDouble(); for (o in 0 until O) target[n*O+o] = nextDouble() }
    val gW1 = DoubleArray(H * D); val gb1 = DoubleArray(H)
    val gW2 = DoubleArray(O * H); val gb2 = DoubleArray(O)
    val z1 = DoubleArray(H); val a1 = DoubleArray(H); val y = DoubleArray(O); val dy = DoubleArray(O)
    val scale = LR / N.toDouble()
    var finalLoss = 0.0
    for (e in 0 until E) {
        for (h in 0 until H) { gb1[h] = 0.0; for (d in 0 until D) gW1[h*D+d] = 0.0 }
        for (o in 0 until O) { gb2[o] = 0.0; for (h in 0 until H) gW2[o*H+h] = 0.0 }
        var epochLoss = 0.0
        for (n in 0 until N) {
            for (h in 0 until H) {
                var s = b1[h]
                for (d in 0 until D) s += W1[h*D+d] * x[n*D+d]
                z1[h] = s; a1[h] = if (s > 0.0) s else 0.0
            }
            for (o in 0 until O) {
                var s = b2[o]
                for (h in 0 until H) s += W2[o*H+h] * a1[h]
                y[o] = s
            }
            for (o in 0 until O) { val diff = y[o] - target[n*O+o]; epochLoss += diff * diff; dy[o] = 2 * diff }
            for (o in 0 until O) { gb2[o] += dy[o]; for (h in 0 until H) gW2[o*H+h] += dy[o] * a1[h] }
            for (h in 0 until H) {
                var da = 0.0
                for (o in 0 until O) da += W2[o*H+h] * dy[o]
                val dz = if (z1[h] > 0.0) da else 0.0
                gb1[h] += dz
                for (d in 0 until D) gW1[h*D+d] += dz * x[n*D+d]
            }
        }
        for (h in 0 until H) { b1[h] -= scale * gb1[h]; for (d in 0 until D) W1[h*D+d] -= scale * gW1[h*D+d] }
        for (o in 0 until O) { b2[o] -= scale * gb2[o]; for (h in 0 until H) W2[o*H+h] -= scale * gW2[o*H+h] }
        finalLoss = epochLoss / (N * O).toDouble()
    }
    var wsum = 0.0
    for (h in 0 until H) { wsum += b1[h]; for (d in 0 until D) wsum += W1[h*D+d] }
    for (o in 0 until O) { wsum += b2[o]; for (h in 0 until H) wsum += W2[o*H+h] }
    println(f6(finalLoss) + " " + f6(wsum))
}
