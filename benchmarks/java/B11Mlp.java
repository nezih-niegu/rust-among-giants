import java.math.BigDecimal;
import java.math.RoundingMode;

// MLP training (forward + backprop, full-batch GD) — Neural Network benchmark
// (MICAI). D->H->O, ReLU hidden, linear output, MSE. ReLU+MSE use only
// +,-,*,/ and max (no transcendental), bit-exact across IEEE-754. The JVM does
// not contract a*b+c into an FMA (JLS strict FP), so dot products match C.
// Checksum = final-epoch loss + sum of all weights.
public class B11Mlp {
    static final int N = 10000, D = 16, H = 64, O = 4, E = 150;
    static final double LR = 0.01;
    static long state = 42;
    static double nextDouble() {
        state = state * 6364136223846793005L + 1442695040888963407L;
        return (double)(state >>> 33) / (double)(1L << 31);
    }
    static String f6(double v) { return new BigDecimal(v).setScale(6, RoundingMode.HALF_EVEN).toPlainString(); }

    public static void main(String[] args) {
        double[][] W1 = new double[H][D]; double[] b1 = new double[H];
        double[][] W2 = new double[O][H]; double[] b2 = new double[O];
        for (int h = 0; h < H; h++) for (int d = 0; d < D; d++) W1[h][d] = (nextDouble() * 2.0 - 1.0) * 0.1;
        for (int o = 0; o < O; o++) for (int h = 0; h < H; h++) W2[o][h] = (nextDouble() * 2.0 - 1.0) * 0.1;
        double[][] x = new double[N][D]; double[][] target = new double[N][O];
        for (int n = 0; n < N; n++) {
            for (int d = 0; d < D; d++) x[n][d] = nextDouble();
            for (int o = 0; o < O; o++) target[n][o] = nextDouble();
        }
        double[][] gW1 = new double[H][D]; double[] gb1 = new double[H];
        double[][] gW2 = new double[O][H]; double[] gb2 = new double[O];
        double[] z1 = new double[H], a1 = new double[H], y = new double[O], dy = new double[O];

        double scale = LR / (double)N;
        double finalLoss = 0.0;
        for (int e = 0; e < E; e++) {
            for (int h = 0; h < H; h++) { gb1[h] = 0.0; for (int d = 0; d < D; d++) gW1[h][d] = 0.0; }
            for (int o = 0; o < O; o++) { gb2[o] = 0.0; for (int h = 0; h < H; h++) gW2[o][h] = 0.0; }
            double epochLoss = 0.0;
            for (int n = 0; n < N; n++) {
                for (int h = 0; h < H; h++) {
                    double s = b1[h];
                    for (int d = 0; d < D; d++) s += W1[h][d] * x[n][d];
                    z1[h] = s; a1[h] = s > 0.0 ? s : 0.0;
                }
                for (int o = 0; o < O; o++) {
                    double s = b2[o];
                    for (int h = 0; h < H; h++) s += W2[o][h] * a1[h];
                    y[o] = s;
                }
                for (int o = 0; o < O; o++) { double diff = y[o] - target[n][o]; epochLoss += diff * diff; dy[o] = 2.0 * diff; }
                for (int o = 0; o < O; o++) {
                    gb2[o] += dy[o];
                    for (int h = 0; h < H; h++) gW2[o][h] += dy[o] * a1[h];
                }
                for (int h = 0; h < H; h++) {
                    double da = 0.0;
                    for (int o = 0; o < O; o++) da += W2[o][h] * dy[o];
                    double dz = z1[h] > 0.0 ? da : 0.0;
                    gb1[h] += dz;
                    for (int d = 0; d < D; d++) gW1[h][d] += dz * x[n][d];
                }
            }
            for (int h = 0; h < H; h++) { b1[h] -= scale * gb1[h]; for (int d = 0; d < D; d++) W1[h][d] -= scale * gW1[h][d]; }
            for (int o = 0; o < O; o++) { b2[o] -= scale * gb2[o]; for (int h = 0; h < H; h++) W2[o][h] -= scale * gW2[o][h]; }
            finalLoss = epochLoss / (double)(N * O);
        }
        double wsum = 0.0;
        for (int h = 0; h < H; h++) { wsum += b1[h]; for (int d = 0; d < D; d++) wsum += W1[h][d]; }
        for (int o = 0; o < O; o++) { wsum += b2[o]; for (int h = 0; h < H; h++) wsum += W2[o][h]; }
        System.out.println(f6(finalLoss) + " " + f6(wsum));
    }
}
