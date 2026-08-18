package main
import ("fmt"; "os")
func main() {
    const CHUNK = 1024 * 1024; const CHUNKS = 4096
    fname := "../../data/fileio_test_go.tmp"
    if len(os.Args) > 1 { fname = os.Args[1] }
    buf := make([]byte, CHUNK)
    for i := range buf { buf[i] = 'A' }
    f, _ := os.Create(fname)
    for i := 0; i < CHUNKS; i++ { f.Write(buf) }
    f.Sync()
    f.Close()
    f, _ = os.Open(fname)
    total := int64(0)
    for { n, err := f.Read(buf); total += int64(n); if err != nil { break } }
    f.Close()
    fmt.Println(total)
    os.Remove(fname)
}
