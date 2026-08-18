import Synchronization
import Dispatch

let OPS = 10_000_000
let counter = Atomic<Int>(0)
DispatchQueue.concurrentPerform(iterations: 8) { _ in
    for _ in 0..<OPS {
        counter.wrappingAdd(1, ordering: .relaxed)
    }
}
print(counter.load(ordering: .sequentiallyConsistent))
