import java.util.concurrent.atomic.AtomicLong;
public class B7Concurrent {
    public static void main(String[] args) throws Exception {
        AtomicLong counter = new AtomicLong(0);
        Thread[] threads = new Thread[8];
        for (int i = 0; i < 8; i++) {
            threads[i] = new Thread(() -> {
                for (int j = 0; j < 10000000; j++) counter.incrementAndGet();
            });
            threads[i].start();
        }
        for (Thread t : threads) t.join();
        System.out.println(counter.get());
    }
}
