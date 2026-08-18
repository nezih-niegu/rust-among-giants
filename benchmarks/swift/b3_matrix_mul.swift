import Foundation
let SIZE = 2000

var rngState: UInt64 = 42
@inline(__always)
func nextDouble() -> Double {
    rngState = rngState &* 6364136223846793005 &+ 1442695040888963407
    return Double(rngState >> 33) / Double(UInt64(1) << 31)
}

// ContiguousArray + UnsafeBufferPointer: idiomatic Swift escape hatch for the
// hot loop. Plain [Double] keeps bounds checks and may dispatch through
// CoreFoundation bridging on every access — ~14x slower than this version
// without changing what the algorithm actually does.
var A = ContiguousArray<Double>(repeating: 0.0, count: SIZE*SIZE)
var B = ContiguousArray<Double>(repeating: 0.0, count: SIZE*SIZE)
var C = ContiguousArray<Double>(repeating: 0.0, count: SIZE*SIZE)

for i in 0..<SIZE*SIZE { A[i] = nextDouble(); B[i] = nextDouble() }

A.withUnsafeBufferPointer { aPtr in
    B.withUnsafeBufferPointer { bPtr in
        C.withUnsafeMutableBufferPointer { cPtr in
            for i in 0..<SIZE {
                for k in 0..<SIZE {
                    let a_ik = aPtr[i*SIZE+k]
                    for j in 0..<SIZE {
                        cPtr[i*SIZE+j] += a_ik * bPtr[k*SIZE+j]
                    }
                }
            }
        }
    }
}

var sum: Double = 0
for x in C { sum += x }
print(String(format: "%.6f", sum))
