package main
import ("encoding/json"; "fmt"; "os")
func count(v interface{}) (int64, int64, int64, int64, int64, int64) {
    var o, a, s, n, b, nl int64
    switch val := v.(type) {
    case map[string]interface{}:
        o = 1
        for _, vv := range val {
            ro, ra, rs, rn, rb, rnl := count(vv)
            o += ro; a += ra; s += rs; n += rn; b += rb; nl += rnl
        }
    case []interface{}:
        a = 1
        for _, vv := range val {
            ro, ra, rs, rn, rb, rnl := count(vv)
            o += ro; a += ra; s += rs; n += rn; b += rb; nl += rnl
        }
    case string: s = 1
    case float64: n = 1
    case bool: b = 1
    case nil: nl = 1
    }
    return o, a, s, n, b, nl
}
func main() {
    fn := "../../data/json_input.json"
    if len(os.Args) > 1 { fn = os.Args[1] }
    data, _ := os.ReadFile(fn)
    var v interface{}
    json.Unmarshal(data, &v)
    o, a, s, n, b, nl := count(v)
    fmt.Printf("objects=%d arrays=%d strings=%d numbers=%d bools=%d nulls=%d\n", o, a, s, n, b, nl)
}
