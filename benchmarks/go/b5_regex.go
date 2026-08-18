package main
import ("bufio"; "fmt"; "os"; "regexp")
func main() {
    fn := "../../data/regex_input.txt"
    if len(os.Args) > 1 { fn = os.Args[1] }
    re := regexp.MustCompile(`[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}`)
    f, _ := os.Open(fn)
    defer f.Close()
    scanner := bufio.NewScanner(f)
    scanner.Buffer(make([]byte, 4096), 4096)
    count := 0
    for scanner.Scan() { if re.MatchString(scanner.Text()) { count++ } }
    fmt.Println(count)
}
