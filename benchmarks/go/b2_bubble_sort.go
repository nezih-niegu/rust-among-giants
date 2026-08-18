package main
import ("fmt"; "math/rand")
func main() {
    N := 100000
    r := rand.New(rand.NewSource(42))
    arr := make([]int, N)
    for i := range arr { arr[i] = r.Intn(N) }
    for i := 0; i < N-1; i++ {
        swapped := false
        for j := 0; j < N-i-1; j++ {
            if arr[j] > arr[j+1] { arr[j], arr[j+1] = arr[j+1], arr[j]; swapped = true }
        }
        if !swapped { break }
    }
    fmt.Println(arr[0], arr[N-1])
}
