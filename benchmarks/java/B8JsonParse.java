import java.io.*;
import java.util.*;
// Simple recursive JSON stats counter using built-in tokenizer approach
public class B8JsonParse {
    static long[] count(Object v) {
        long[] r = new long[6]; // o,a,s,n,b,nl
        if (v instanceof Map) {
            r[0] = 1;
            for (Object val : ((Map<?,?>)v).values()) {
                long[] c = count(val);
                for (int i = 0; i < 6; i++) r[i] += c[i];
            }
        } else if (v instanceof List) {
            r[1] = 1;
            for (Object val : (List<?>)v) {
                long[] c = count(val);
                for (int i = 0; i < 6; i++) r[i] += c[i];
            }
        } else if (v instanceof String) r[2] = 1;
        else if (v instanceof Number) r[3] = 1;
        else if (v instanceof Boolean) r[4] = 1;
        else if (v == null) r[5] = 1;
        return r;
    }
    // Minimal JSON parser (no external deps)
    static int pos;
    static String json;
    static Object parse() {
        skipWS();
        char c = json.charAt(pos);
        if (c == '{') return parseObj();
        if (c == '[') return parseArr();
        if (c == '"') return parseStr();
        if (c == 't') { pos += 4; return Boolean.TRUE; }
        if (c == 'f') { pos += 5; return Boolean.FALSE; }
        if (c == 'n') { pos += 4; return null; }
        return parseNum();
    }
    static void skipWS() { while (pos < json.length() && " \t\n\r".indexOf(json.charAt(pos)) >= 0) pos++; }
    static Map<String,Object> parseObj() {
        Map<String,Object> m = new LinkedHashMap<>();
        pos++; skipWS();
        if (json.charAt(pos) == '}') { pos++; return m; }
        while (true) {
            skipWS(); String key = parseStr(); skipWS(); pos++; // :
            skipWS(); m.put(key, parse()); skipWS();
            if (json.charAt(pos) == '}') { pos++; return m; }
            pos++; // ,
        }
    }
    static List<Object> parseArr() {
        List<Object> a = new ArrayList<>();
        pos++; skipWS();
        if (json.charAt(pos) == ']') { pos++; return a; }
        while (true) {
            skipWS(); a.add(parse()); skipWS();
            if (json.charAt(pos) == ']') { pos++; return a; }
            pos++; // ,
        }
    }
    static String parseStr() {
        pos++; // opening "
        StringBuilder sb = new StringBuilder();
        while (json.charAt(pos) != '"') {
            if (json.charAt(pos) == '\\') { pos++; sb.append(json.charAt(pos)); }
            else sb.append(json.charAt(pos));
            pos++;
        }
        pos++; // closing "
        return sb.toString();
    }
    static Number parseNum() {
        int start = pos;
        while (pos < json.length() && "0123456789.eE+-".indexOf(json.charAt(pos)) >= 0) pos++;
        String s = json.substring(start, pos);
        if (s.contains(".") || s.contains("e") || s.contains("E")) return Double.parseDouble(s);
        return Long.parseLong(s);
    }
    public static void main(String[] args) throws Exception {
        String fn = args.length > 0 ? args[0] : "../../data/json_input.json";
        json = new String(java.nio.file.Files.readAllBytes(java.nio.file.Path.of(fn)));
        pos = 0;
        Object v = parse();
        long[] r = count(v);
        System.out.printf("objects=%d arrays=%d strings=%d numbers=%d bools=%d nulls=%d%n", r[0],r[1],r[2],r[3],r[4],r[5]);
    }
}
