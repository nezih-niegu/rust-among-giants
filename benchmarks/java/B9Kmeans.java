import java.math.BigDecimal;
import java.math.RoundingMode;

// K-Means clustering (Lloyd's algorithm) — Data Mining benchmark (MICAI).
// Shared 64-bit LCG (seed 42); SQUARED Euclidean distance (no sqrt) for
// bit-exactness; assignment ties break to the lowest centroid index.
// Java `long` is two's-complement 64-bit, so the LCG multiply/add wrap exactly
// as the C unsigned version. Floats are printed via BigDecimal HALF_EVEN to
// match C printf's round-to-nearest-even, keeping the checksum bit-identical.
public class B9Kmeans {
    static final int N = 100000, D = 4, K = 10, ITERS = 1000;
    static long state = 42;
    static double nextDouble() {
        state = state * 6364136223846793005L + 1442695040888963407L;
        return (double)(state >>> 33) / (double)(1L << 31);
    }
    static String f6(double v) { return new BigDecimal(v).setScale(6, RoundingMode.HALF_EVEN).toPlainString(); }

    public static void main(String[] args) {
        double[][] points = new double[N][D];
        for (int i = 0; i < N; i++)
            for (int d = 0; d < D; d++) points[i][d] = nextDouble();
        double[][] centroids = new double[K][D];
        for (int k = 0; k < K; k++)
            for (int d = 0; d < D; d++) centroids[k][d] = points[k][d];

        int[] assign = new int[N];
        long[] counts = new long[K];
        double[][] sums = new double[K][D];
        for (int it = 0; it < ITERS; it++) {
            for (int i = 0; i < N; i++) {
                double best = 1e300; int bestk = 0;
                for (int k = 0; k < K; k++) {
                    double dist = 0.0;
                    for (int d = 0; d < D; d++) { double diff = points[i][d] - centroids[k][d]; dist += diff * diff; }
                    if (dist < best) { best = dist; bestk = k; }
                }
                assign[i] = bestk;
            }
            for (int k = 0; k < K; k++) { counts[k] = 0; for (int d = 0; d < D; d++) sums[k][d] = 0.0; }
            for (int i = 0; i < N; i++) {
                int k = assign[i]; counts[k]++;
                for (int d = 0; d < D; d++) sums[k][d] += points[i][d];
            }
            for (int k = 0; k < K; k++)
                if (counts[k] > 0)
                    for (int d = 0; d < D; d++) centroids[k][d] = sums[k][d] / (double)counts[k];
        }
        long fingerprint = 0; double centroidSum = 0.0;
        for (int k = 0; k < K; k++) {
            fingerprint += counts[k] * (long)(k + 1);
            for (int d = 0; d < D; d++) centroidSum += centroids[k][d];
        }
        System.out.println(fingerprint + " " + f6(centroidSum));
    }
}
