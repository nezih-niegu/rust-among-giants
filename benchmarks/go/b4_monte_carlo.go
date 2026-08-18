package main
import "fmt"
const ITERATIONS = 1000000000
type SimpleRNG struct{ state uint64 }
func (r *SimpleRNG) next() float64 {
    r.state = r.state*6364136223846793005 + 1442695040888963407
    return float64(r.state>>33) / float64(uint64(1)<<31)
}
func main() {
    rng := SimpleRNG{42}
    inside := int64(0)
    for i := 0; i < ITERATIONS; i++ {
        x, y := rng.next(), rng.next()
        if x*x+y*y <= 1.0 { inside++ }
    }
    fmt.Printf("%.10f\n", 4.0*float64(inside)/float64(ITERATIONS))
}
