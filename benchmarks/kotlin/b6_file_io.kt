import java.io.*
fun main(args: Array<String>) {
    val CHUNK = 1024 * 1024; val CHUNKS = 4096
    val fname = if (args.isNotEmpty()) args[0] else "../../data/fileio_test_kotlin.tmp"
    val buf = ByteArray(CHUNK) { 65 } // 'A'
    val fos = FileOutputStream(fname)
    BufferedOutputStream(fos).use { os ->
        repeat(CHUNKS) { os.write(buf) }
        os.flush()
        fos.fd.sync()
    }
    var total = 0L
    BufferedInputStream(FileInputStream(fname)).use { ins ->
        while (true) { val n = ins.read(buf); if (n < 0) break; total += n }
    }
    println(total)
    File(fname).delete()
}
