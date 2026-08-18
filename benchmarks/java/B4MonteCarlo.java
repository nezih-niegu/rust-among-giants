public class B4MonteCarlo {
    static final long ITERATIONS = 1000000000L;
    public static void main(String[] args) {
        long state = 42;
        long inside = 0;
        for (long i = 0; i < ITERATIONS; i++) {
            state = state * 6364136223846793005L + 1442695040888963407L;
            double x = (double)(state >>> 33) / (double)(1L << 31);
            state = state * 6364136223846793005L + 1442695040888963407L;
            double y = (double)(state >>> 33) / (double)(1L << 31);
            if (x * x + y * y <= 1.0) inside++;
        }
        System.out.printf("%.10f%n", 4.0 * inside / ITERATIONS);
    }
}
