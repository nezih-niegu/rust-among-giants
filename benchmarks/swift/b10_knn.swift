// k-NN classification — Machine Learning benchmark (MICAI). Shared LCG (seed 42),
// squared Euclidean distance, vote ties to lowest class. Checksum = sum of labels.
import Foundation
let M = 50000, Q = 10000, D = 8, K = 15, C = 3
var state: UInt64 = 42
@inline(__always) func nextDouble() -> Double {
    state = state &* 6364136223846793005 &+ 1442695040888963407
    return Double(state >> 33) / Double(UInt64(1) << 31)
}
var train = [Double](repeating: 0, count: M * D)
var label = [Int](repeating: 0, count: M)
for t in 0..<M { for d in 0..<D { train[t*D+d] = nextDouble() }; label[t] = Int(nextDouble() * Double(C)) }
var query = [Double](repeating: 0, count: Q * D)
for q in 0..<Q { for d in 0..<D { query[q*D+d] = nextDouble() } }
var checksum = 0
var bestD = [Double](repeating: 0, count: K)
var bestL = [Int](repeating: 0, count: K)
for q in 0..<Q {
    for j in 0..<K { bestD[j] = 1e300; bestL[j] = 0 }
    for t in 0..<M {
        var dist = 0.0
        for d in 0..<D { let diff = query[q*D+d] - train[t*D+d]; dist += diff * diff }
        if dist < bestD[K-1] {
            var p = K - 1
            while p > 0 && dist < bestD[p-1] { bestD[p] = bestD[p-1]; bestL[p] = bestL[p-1]; p -= 1 }
            bestD[p] = dist; bestL[p] = label[t]
        }
    }
    var votes = [Int](repeating: 0, count: C)
    for j in 0..<K { votes[bestL[j]] += 1 }
    var pred = 0
    for c in 1..<C where votes[c] > votes[pred] { pred = c }
    checksum += pred
}
print(checksum)
