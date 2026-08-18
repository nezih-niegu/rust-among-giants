// Genetic Algorithm minimizing Rosenbrock — Computational Intelligence
// benchmark (MICAI). Tournament selection, uniform crossover/mutation; all
// +,-,*,/ so bit-exact. Shared LCG (seed 42) drives every random decision.
import Foundation
let D = 30, P = 5000, G = 1200, T = 3
let MUT_RATE = 0.1, MUT_STEP = 0.1
var state: UInt64 = 42
@inline(__always) func nextDouble() -> Double {
    state = state &* 6364136223846793005 &+ 1442695040888963407
    return Double(state >> 33) / Double(UInt64(1) << 31)
}
func rosenbrock(_ x: [Double], _ off: Int) -> Double {
    var f = 0.0
    for i in 0..<(D - 1) { let a = x[off+i+1] - x[off+i] * x[off+i]; let b = 1.0 - x[off+i]; f += 100.0 * a * a + b * b }
    return f
}
var pop = [Double](repeating: 0, count: P * D)
var newpop = [Double](repeating: 0, count: P * D)
var fitness = [Double](repeating: 0, count: P)
var bestGenes = [Double](repeating: 0, count: D)
for p in 0..<P { for d in 0..<D { pop[p*D+d] = (nextDouble() * 2 - 1) * 5.0 } }
var bestFit = 1e300
for _ in 0..<G {
    for p in 0..<P {
        let f = rosenbrock(pop, p*D); fitness[p] = f
        if f < bestFit { bestFit = f; for d in 0..<D { bestGenes[d] = pop[p*D+d] } }
    }
    for d in 0..<D { newpop[0*D+d] = bestGenes[d] }
    for i in 1..<P {
        var a = Int(nextDouble() * Double(P))
        for _ in 1..<T { let idx = Int(nextDouble() * Double(P)); if fitness[idx] < fitness[a] { a = idx } }
        var b = Int(nextDouble() * Double(P))
        for _ in 1..<T { let idx = Int(nextDouble() * Double(P)); if fitness[idx] < fitness[b] { b = idx } }
        for d in 0..<D { newpop[i*D+d] = (nextDouble() < 0.5) ? pop[a*D+d] : pop[b*D+d] }
        for d in 0..<D { if nextDouble() < MUT_RATE { newpop[i*D+d] += (nextDouble() * 2 - 1) * MUT_STEP } }
    }
    for p in 0..<P { for d in 0..<D { pop[p*D+d] = newpop[p*D+d] } }
}
var gsum = 0.0
for d in 0..<D { gsum += bestGenes[d] }
print(String(format: "%.6f %.6f", bestFit, gsum))
