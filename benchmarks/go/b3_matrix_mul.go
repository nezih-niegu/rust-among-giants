package main
import "fmt"
const SIZE = 2000

var rngState uint64 = 42
func nextDouble() float64 {
    rngState = rngState*6364136223846793005 + 1442695040888963407
    return float64(rngState>>33) / float64(uint64(1)<<31)
}

func main() {
    A := make([]float64, SIZE*SIZE)
    B := make([]float64, SIZE*SIZE)
    C := make([]float64, SIZE*SIZE)
    for i := range A { A[i] = nextDouble(); B[i] = nextDouble() }
    for i := 0; i < SIZE; i++ {
        for k := 0; k < SIZE; k++ {
            aik := A[i*SIZE+k]
            for j := 0; j < SIZE; j++ { C[i*SIZE+j] += aik * B[k*SIZE+j] }
        }
    }
    sum := 0.0
    for _, v := range C { sum += v }
    fmt.Printf("%.6f\n", sum)
}
