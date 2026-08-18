package main
import ("fmt"; "os"; "strconv")
func fib(n int) int64 {
    if n <= 1 { return int64(n) }
    return fib(n-1) + fib(n-2)
}
func main() {
    n := 45
    if len(os.Args) > 1 { n, _ = strconv.Atoi(os.Args[1]) }
    fmt.Println(fib(n))
}
