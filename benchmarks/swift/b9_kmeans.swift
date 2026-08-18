// K-Means (Lloyd's) — Data Mining benchmark (MICAI). Shared 64-bit LCG (seed 42),
// squared Euclidean distance, ties to lowest centroid index. Flat arrays mirror
// the C reference layout. String(format:) uses the C library printf, so the
// checksum matches the other languages bit-for-bit.
import Foundation
let N = 100000, D = 4, K = 10, ITERS = 1000
var state: UInt64 = 42
@inline(__always) func nextDouble() -> Double {
    state = state &* 6364136223846793005 &+ 1442695040888963407
    return Double(state >> 33) / Double(UInt64(1) << 31)
}
var points = [Double](repeating: 0, count: N * D)
for i in 0..<N { for d in 0..<D { points[i*D+d] = nextDouble() } }
var centroids = [Double](repeating: 0, count: K * D)
for k in 0..<K { for d in 0..<D { centroids[k*D+d] = points[k*D+d] } }
var assign = [Int](repeating: 0, count: N)
var counts = [Int](repeating: 0, count: K)
var sums = [Double](repeating: 0, count: K * D)
for _ in 0..<ITERS {
    for i in 0..<N {
        var best = 1e300, bestk = 0
        for k in 0..<K {
            var dist = 0.0
            for d in 0..<D { let diff = points[i*D+d] - centroids[k*D+d]; dist += diff * diff }
            if dist < best { best = dist; bestk = k }
        }
        assign[i] = bestk
    }
    for k in 0..<K { counts[k] = 0; for d in 0..<D { sums[k*D+d] = 0 } }
    for i in 0..<N { let k = assign[i]; counts[k] += 1; for d in 0..<D { sums[k*D+d] += points[i*D+d] } }
    for k in 0..<K where counts[k] > 0 { for d in 0..<D { centroids[k*D+d] = sums[k*D+d] / Double(counts[k]) } }
}
var fingerprint = 0; var centroidSum = 0.0
for k in 0..<K { fingerprint += counts[k] * (k + 1); for d in 0..<D { centroidSum += centroids[k*D+d] } }
print("\(fingerprint) " + String(format: "%.6f", centroidSum))
