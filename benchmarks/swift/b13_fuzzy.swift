// Mamdani fuzzy inference system — Fuzzy Systems benchmark (MICAI).
// 3 triangular sets/input, 9-rule base, max-min aggregation, centroid
// defuzzification; only +,-,*,/,min,max so bit-exact. Shared LCG (seed 42).
import Foundation
let Q = 2000000, NP = 100, NSET = 3, NRULE = 9
let SETP: [[Double]] = [[-0.5, 0.0, 0.5], [0.0, 0.5, 1.0], [0.5, 1.0, 1.5]]
var state: UInt64 = 42
@inline(__always) func nextDouble() -> Double {
    state = state &* 6364136223846793005 &+ 1442695040888963407
    return Double(state >> 33) / Double(UInt64(1) << 31)
}
@inline(__always) func tri(_ v: Double, _ a: Double, _ b: Double, _ c: Double) -> Double {
    let left = (v - a) / (b - a), right = (c - v) / (c - b)
    let m = left < right ? left : right
    return m > 0 ? m : 0
}
var zval = [Double](repeating: 0, count: NP)
var os = [Double](repeating: 0, count: NSET * NP)
for j in 0..<NP {
    let z = Double(j) / Double(NP - 1); zval[j] = z
    for s in 0..<NSET { os[s*NP+j] = tri(z, SETP[s][0], SETP[s][1], SETP[s][2]) }
}
var outset = [Int](repeating: 0, count: NRULE)
for xi in 0..<NSET { for yi in 0..<NSET { let sum = xi + yi; outset[xi*NSET+yi] = sum <= 1 ? 0 : (sum == 2 ? 1 : 2) } }
var checksum = 0.0
var muX = [Double](repeating: 0, count: NSET), muY = [Double](repeating: 0, count: NSET)
var fs = [Double](repeating: 0, count: NRULE)
for _ in 0..<Q {
    let x = nextDouble(), y = nextDouble()
    for s in 0..<NSET { muX[s] = tri(x, SETP[s][0], SETP[s][1], SETP[s][2]); muY[s] = tri(y, SETP[s][0], SETP[s][1], SETP[s][2]) }
    for xi in 0..<NSET { for yi in 0..<NSET { let f = muX[xi] < muY[yi] ? muX[xi] : muY[yi]; fs[xi*NSET+yi] = f } }
    var num = 0.0, den = 0.0
    for j in 0..<NP {
        var agg = 0.0
        for r in 0..<NRULE { let osv = os[outset[r]*NP+j]; let m = fs[r] < osv ? fs[r] : osv; if m > agg { agg = m } }
        num += zval[j] * agg; den += agg
    }
    checksum += den > 0 ? num / den : 0
}
print(String(format: "%.6f", checksum))
