import Foundation
let N = 100_000
srand48(42)
var arr = (0..<N).map { _ in Int(drand48() * Double(N)) }
for i in 0..<N-1 {
    var swapped = false
    for j in 0..<N-i-1 {
        if arr[j] > arr[j+1] { arr.swapAt(j, j+1); swapped = true }
    }
    if !swapped { break }
}
print("\(arr[0]) \(arr[N-1])")
