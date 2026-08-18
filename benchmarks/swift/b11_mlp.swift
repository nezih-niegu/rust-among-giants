// MLP training (forward + backprop, full-batch GD) — Neural Network benchmark
// (MICAI). D->H->O, ReLU hidden, linear output, MSE; only +,-,*,/ and max, so
// bit-exact. swiftc -O does not contract a*b+c into an FMA (strict FP default).
import Foundation
let N = 10000, D = 16, H = 64, O = 4, E = 150
let LR = 0.01
var state: UInt64 = 42
@inline(__always) func nextDouble() -> Double {
    state = state &* 6364136223846793005 &+ 1442695040888963407
    return Double(state >> 33) / Double(UInt64(1) << 31)
}
var W1 = [Double](repeating: 0, count: H * D), b1 = [Double](repeating: 0, count: H)
var W2 = [Double](repeating: 0, count: O * H), b2 = [Double](repeating: 0, count: O)
for h in 0..<H { for d in 0..<D { W1[h*D+d] = (nextDouble() * 2 - 1) * 0.1 } }
for o in 0..<O { for h in 0..<H { W2[o*H+h] = (nextDouble() * 2 - 1) * 0.1 } }
var x = [Double](repeating: 0, count: N * D), target = [Double](repeating: 0, count: N * O)
for n in 0..<N { for d in 0..<D { x[n*D+d] = nextDouble() }; for o in 0..<O { target[n*O+o] = nextDouble() } }
var gW1 = [Double](repeating: 0, count: H * D), gb1 = [Double](repeating: 0, count: H)
var gW2 = [Double](repeating: 0, count: O * H), gb2 = [Double](repeating: 0, count: O)
var z1 = [Double](repeating: 0, count: H), a1 = [Double](repeating: 0, count: H)
var y = [Double](repeating: 0, count: O), dy = [Double](repeating: 0, count: O)
let scale = LR / Double(N)
var finalLoss = 0.0
for _ in 0..<E {
    for h in 0..<H { gb1[h] = 0; for d in 0..<D { gW1[h*D+d] = 0 } }
    for o in 0..<O { gb2[o] = 0; for h in 0..<H { gW2[o*H+h] = 0 } }
    var epochLoss = 0.0
    for n in 0..<N {
        for h in 0..<H {
            var s = b1[h]
            for d in 0..<D { s += W1[h*D+d] * x[n*D+d] }
            z1[h] = s; a1[h] = s > 0 ? s : 0
        }
        for o in 0..<O {
            var s = b2[o]
            for h in 0..<H { s += W2[o*H+h] * a1[h] }
            y[o] = s
        }
        for o in 0..<O { let diff = y[o] - target[n*O+o]; epochLoss += diff * diff; dy[o] = 2 * diff }
        for o in 0..<O { gb2[o] += dy[o]; for h in 0..<H { gW2[o*H+h] += dy[o] * a1[h] } }
        for h in 0..<H {
            var da = 0.0
            for o in 0..<O { da += W2[o*H+h] * dy[o] }
            let dz = z1[h] > 0 ? da : 0
            gb1[h] += dz
            for d in 0..<D { gW1[h*D+d] += dz * x[n*D+d] }
        }
    }
    for h in 0..<H { b1[h] -= scale * gb1[h]; for d in 0..<D { W1[h*D+d] -= scale * gW1[h*D+d] } }
    for o in 0..<O { b2[o] -= scale * gb2[o]; for h in 0..<H { W2[o*H+h] -= scale * gW2[o*H+h] } }
    finalLoss = epochLoss / Double(N * O)
}
var wsum = 0.0
for h in 0..<H { wsum += b1[h]; for d in 0..<D { wsum += W1[h*D+d] } }
for o in 0..<O { wsum += b2[o]; for h in 0..<H { wsum += W2[o*H+h] } }
print(String(format: "%.6f %.6f", finalLoss, wsum))
