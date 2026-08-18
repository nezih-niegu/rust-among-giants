// Genetic Algorithm minimizing Rosenbrock — Computational Intelligence
// benchmark (MICAI). Tournament selection, uniform crossover/mutation; all
// +,-,*,/ so bit-exact. Shared LCG (seed 42) drives every random decision.
import java.math.BigDecimal
import java.math.RoundingMode
const val D = 30; const val P = 5000; const val G = 1200; const val T = 3
const val MUT_RATE = 0.1; const val MUT_STEP = 0.1
var state = 42uL
fun nextDouble(): Double {
    state = state * 6364136223846793005uL + 1442695040888963407uL
    return (state shr 33).toDouble() / (1uL shl 31).toDouble()
}
fun f6(v: Double) = BigDecimal(v).setScale(6, RoundingMode.HALF_EVEN).toPlainString()
fun rosenbrock(x: DoubleArray, off: Int): Double {
    var f = 0.0
    for (i in 0 until D - 1) { val a = x[off+i+1] - x[off+i] * x[off+i]; val b = 1.0 - x[off+i]; f += 100.0 * a * a + b * b }
    return f
}
fun main() {
    val pop = DoubleArray(P * D); val newpop = DoubleArray(P * D)
    val fitness = DoubleArray(P); val bestGenes = DoubleArray(D)
    for (p in 0 until P) for (d in 0 until D) pop[p*D+d] = (nextDouble() * 2 - 1) * 5.0
    var bestFit = 1e300
    for (g in 0 until G) {
        for (p in 0 until P) {
            val f = rosenbrock(pop, p*D); fitness[p] = f
            if (f < bestFit) { bestFit = f; for (d in 0 until D) bestGenes[d] = pop[p*D+d] }
        }
        for (d in 0 until D) newpop[0*D+d] = bestGenes[d]
        for (i in 1 until P) {
            var a = (nextDouble() * P).toInt()
            for (t in 1 until T) { val idx = (nextDouble() * P).toInt(); if (fitness[idx] < fitness[a]) a = idx }
            var b = (nextDouble() * P).toInt()
            for (t in 1 until T) { val idx = (nextDouble() * P).toInt(); if (fitness[idx] < fitness[b]) b = idx }
            for (d in 0 until D) newpop[i*D+d] = if (nextDouble() < 0.5) pop[a*D+d] else pop[b*D+d]
            for (d in 0 until D) if (nextDouble() < MUT_RATE) newpop[i*D+d] += (nextDouble() * 2 - 1) * MUT_STEP
        }
        for (p in 0 until P) for (d in 0 until D) pop[p*D+d] = newpop[p*D+d]
    }
    var gsum = 0.0
    for (d in 0 until D) gsum += bestGenes[d]
    println(f6(bestFit) + " " + f6(gsum))
}
