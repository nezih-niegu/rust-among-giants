// Mamdani fuzzy inference system — Fuzzy Systems benchmark (MICAI).
// 3 triangular sets/input, 9-rule base, max-min aggregation, centroid
// defuzzification; only +,-,*,/,min,max so bit-exact. Shared LCG (seed 42).
import java.math.BigDecimal
import java.math.RoundingMode
const val Q = 2000000; const val NP = 100; const val NSET = 3; const val NRULE = 9
val SETP = arrayOf(doubleArrayOf(-0.5, 0.0, 0.5), doubleArrayOf(0.0, 0.5, 1.0), doubleArrayOf(0.5, 1.0, 1.5))
var state = 42uL
fun nextDouble(): Double {
    state = state * 6364136223846793005uL + 1442695040888963407uL
    return (state shr 33).toDouble() / (1uL shl 31).toDouble()
}
fun f6(v: Double) = BigDecimal(v).setScale(6, RoundingMode.HALF_EVEN).toPlainString()
fun tri(v: Double, a: Double, b: Double, c: Double): Double {
    val left = (v - a) / (b - a); val right = (c - v) / (c - b)
    val m = if (left < right) left else right
    return if (m > 0.0) m else 0.0
}
fun main() {
    val zval = DoubleArray(NP); val os = DoubleArray(NSET * NP)
    for (j in 0 until NP) {
        val z = j.toDouble() / (NP - 1).toDouble(); zval[j] = z
        for (s in 0 until NSET) os[s*NP+j] = tri(z, SETP[s][0], SETP[s][1], SETP[s][2])
    }
    val outset = IntArray(NRULE)
    for (xi in 0 until NSET) for (yi in 0 until NSET) { val sum = xi + yi; outset[xi*NSET+yi] = if (sum <= 1) 0 else if (sum == 2) 1 else 2 }
    var checksum = 0.0
    val muX = DoubleArray(NSET); val muY = DoubleArray(NSET); val fs = DoubleArray(NRULE)
    for (q in 0 until Q) {
        val x = nextDouble(); val y = nextDouble()
        for (s in 0 until NSET) { muX[s] = tri(x, SETP[s][0], SETP[s][1], SETP[s][2]); muY[s] = tri(y, SETP[s][0], SETP[s][1], SETP[s][2]) }
        for (xi in 0 until NSET) for (yi in 0 until NSET) { val f = if (muX[xi] < muY[yi]) muX[xi] else muY[yi]; fs[xi*NSET+yi] = f }
        var num = 0.0; var den = 0.0
        for (j in 0 until NP) {
            var agg = 0.0
            for (r in 0 until NRULE) { val osv = os[outset[r]*NP+j]; val m = if (fs[r] < osv) fs[r] else osv; if (m > agg) agg = m }
            num += zval[j] * agg; den += agg
        }
        checksum += if (den > 0.0) num / den else 0.0
    }
    println(f6(checksum))
}
