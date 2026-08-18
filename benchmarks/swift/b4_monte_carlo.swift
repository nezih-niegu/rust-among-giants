import Foundation
let ITERATIONS: UInt64 = 1_000_000_000
var state: UInt64 = 42
func nextDouble() -> Double {
    state = state &* 6364136223846793005 &+ 1442695040888963407
    return Double(state >> 33) / Double(UInt64(1) << 31)
}
var inside: UInt64 = 0
for _ in 0..<ITERATIONS {
    let x = nextDouble(), y = nextDouble()
    if x*x + y*y <= 1.0 { inside += 1 }
}
let pi: Double = 4.0 * Double(inside) / Double(ITERATIONS)
print(String(format: "%.10f", pi))
