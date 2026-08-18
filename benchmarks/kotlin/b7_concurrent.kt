import java.util.concurrent.atomic.AtomicLong
fun main() {
    val counter = AtomicLong(0)
    val threads = Array(8) {
        Thread { repeat(10_000_000) { counter.incrementAndGet() } }.also { it.start() }
    }
    threads.forEach { it.join() }
    println(counter.get())
}
