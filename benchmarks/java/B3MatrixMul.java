public class B3MatrixMul {
    static final int SIZE = 2000;
    static long rngState = 42L;
    static double nextDouble() {
        rngState = rngState * 6364136223846793005L + 1442695040888963407L;
        return (double)(rngState >>> 33) / (double)(1L << 31);
    }
    public static void main(String[] args) {
        double[] A = new double[SIZE * SIZE], B = new double[SIZE * SIZE], C = new double[SIZE * SIZE];
        for (int i = 0; i < SIZE * SIZE; i++) { A[i] = nextDouble(); B[i] = nextDouble(); }
        for (int i = 0; i < SIZE; i++)
            for (int k = 0; k < SIZE; k++) {
                double aik = A[i * SIZE + k];
                for (int j = 0; j < SIZE; j++) C[i * SIZE + j] += aik * B[k * SIZE + j];
            }
        double sum = 0; for (double v : C) sum += v;
        System.out.printf("%.6f%n", sum);
    }
}
