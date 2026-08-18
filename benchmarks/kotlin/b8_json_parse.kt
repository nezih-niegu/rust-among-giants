// Use same hand-rolled parser approach as Java
import java.io.File
var pos = 0
lateinit var json: String
fun skipWS() { while (pos < json.length && json[pos] in " \t\n\r") pos++ }
fun parse(): Any? {
    skipWS(); val c = json[pos]
    return when {
        c == '{' -> parseObj()
        c == '[' -> parseArr()
        c == '"' -> parseStr()
        c == 't' -> { pos += 4; true }
        c == 'f' -> { pos += 5; false }
        c == 'n' -> { pos += 4; null }
        else -> parseNum()
    }
}
fun parseObj(): Map<String, Any?> {
    val m = mutableMapOf<String, Any?>(); pos++; skipWS()
    if (json[pos] == '}') { pos++; return m }
    while (true) {
        skipWS(); val k = parseStr(); skipWS(); pos++ // :
        skipWS(); m[k] = parse(); skipWS()
        if (json[pos] == '}') { pos++; return m }; pos++ // ,
    }
}
fun parseArr(): List<Any?> {
    val a = mutableListOf<Any?>(); pos++; skipWS()
    if (json[pos] == ']') { pos++; return a }
    while (true) {
        skipWS(); a.add(parse()); skipWS()
        if (json[pos] == ']') { pos++; return a }; pos++ // ,
    }
}
fun parseStr(): String {
    pos++; val sb = StringBuilder()
    while (json[pos] != '"') {
        if (json[pos] == '\\') { pos++; sb.append(json[pos]) } else sb.append(json[pos]); pos++
    }; pos++; return sb.toString()
}
fun parseNum(): Number {
    val start = pos
    while (pos < json.length && json[pos] in "0123456789.eE+-") pos++
    val s = json.substring(start, pos)
    return if ('.' in s || 'e' in s || 'E' in s) s.toDouble() else s.toLong()
}
fun count(v: Any?): LongArray {
    val r = LongArray(6)
    when (v) {
        is Map<*, *> -> { r[0] = 1; v.values.forEach { c -> val x = count(c); for (i in 0..5) r[i] += x[i] } }
        is List<*> -> { r[1] = 1; v.forEach { c -> val x = count(c); for (i in 0..5) r[i] += x[i] } }
        is String -> r[2] = 1
        is Number -> r[3] = 1
        is Boolean -> r[4] = 1
        null -> r[5] = 1
    }; return r
}
fun main(args: Array<String>) {
    val fn = if (args.isNotEmpty()) args[0] else "../../data/json_input.json"
    json = File(fn).readText(); pos = 0
    val v = parse(); val r = count(v)
    println("objects=${r[0]} arrays=${r[1]} strings=${r[2]} numbers=${r[3]} bools=${r[4]} nulls=${r[5]}")
}
