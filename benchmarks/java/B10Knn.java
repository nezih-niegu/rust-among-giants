// k-NN classification — Machine Learning benchmark (MICAI).
// Shared 64-bit LCG (seed 42); SQUARED Euclidean distance; vote ties break to
// the lowest class label. Checksum = sum of predicted labels (integer).
public class B10Knn {
    static final int M = 50000, Q = 10000, D = 8, K = 15, C = 3;
    static long state = 42;
    static double nextDouble() {
        state = state * 6364136223846793005L + 1442695040888963407L;
        return (double)(state >>> 33) / (double)(1L << 31);
    }
    public static void main(String[] args) {
        double[][] train = new double[M][D];
        int[] label = new int[M];
        for (int t = 0; t < M; t++) {
            for (int d = 0; d < D; d++) train[t][d] = nextDouble();
            label[t] = (int)(nextDouble() * C);
        }
        double[][] query = new double[Q][D];
        for (int q = 0; q < Q; q++)
            for (int d = 0; d < D; d++) query[q][d] = nextDouble();

        long checksum = 0;
        double[] bestD = new double[K];
        int[] bestL = new int[K];
        for (int q = 0; q < Q; q++) {
            for (int j = 0; j < K; j++) { bestD[j] = 1e300; bestL[j] = 0; }
            for (int t = 0; t < M; t++) {
                double dist = 0.0;
                for (int d = 0; d < D; d++) { double diff = query[q][d] - train[t][d]; dist += diff * diff; }
                if (dist < bestD[K - 1]) {
                    int p = K - 1;
                    while (p > 0 && dist < bestD[p - 1]) { bestD[p] = bestD[p - 1]; bestL[p] = bestL[p - 1]; p--; }
                    bestD[p] = dist; bestL[p] = label[t];
                }
            }
            int[] votes = new int[C];
            for (int j = 0; j < K; j++) votes[bestL[j]]++;
            int pred = 0;
            for (int c = 1; c < C; c++) if (votes[c] > votes[pred]) pred = c;
            checksum += pred;
        }
        System.out.println(checksum);
    }
}
