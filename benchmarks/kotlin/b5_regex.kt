import java.io.File
fun main(args: Array<String>) {
    val fn = if (args.isNotEmpty()) args[0] else "../../data/regex_input.txt"
    val pat = Regex("[a-zA-Z0-9._%+\\-]+@[a-zA-Z0-9.\\-]+\\.[a-zA-Z]{2,}")
    var count = 0
    File(fn).forEachLine { if (pat.containsMatchIn(it)) count++ }
    println(count)
}
