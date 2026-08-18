import java.math.BigDecimal;
import java.math.RoundingMode;

// Mamdani fuzzy inference system — Fuzzy Systems benchmark (MICAI).
// 3 triangular sets/input, 9-rule base, max-min aggregation, centroid
// defuzzification. Only +,-,*,/,min,max, so bit-exact across IEEE-754.
// Shared 64-bit LCG (seed 42). Checksum = sum of defuzzified outputs.
public class B13Fuzzy {
    static final int Q = 2000000, NP = 100, NSET = 3, NRULE = 9;
    static final double[][] SETP = { { -0.5, 0.0, 0.5 }, { 0.0, 0.5, 1.0 }, { 0.5, 1.0, 1.5 } };
    static long state = 42;
    static double nextDouble() {
        state = state * 6364136223846793005L + 1442695040888963407L;
        return (double)(state >>> 33) / (double)(1L << 31);
    }
    static String f6(double v) { return new BigDecimal(v).setScale(6, RoundingMode.HALF_EVEN).toPlainString(); }
    static double tri(double v, double a, double b, double c) {
        double left = (v - a) / (b - a), right = (c - v) / (c - b);
        double m = left < right ? left : right;
        return m > 0.0 ? m : 0.0;
    }
    public static void main(String[] args) {
        double[] zval = new double[NP];
        double[][] os = new double[NSET][NP];
        for (int j = 0; j < NP; j++) {
            double z = (double)j / (double)(NP - 1); zval[j] = z;
            for (int s = 0; s < NSET; s++) os[s][j] = tri(z, SETP[s][0], SETP[s][1], SETP[s][2]);
        }
        int[] outset = new int[NRULE];
        for (int xi = 0; xi < NSET; xi++)
            for (int yi = 0; yi < NSET; yi++) { int sum = xi + yi; outset[xi * NSET + yi] = sum <= 1 ? 0 : (sum == 2 ? 1 : 2); }

        double checksum = 0.0;
        double[] muX = new double[NSET], muY = new double[NSET], fs = new double[NRULE];
        for (int q = 0; q < Q; q++) {
            double x = nextDouble(), y = nextDouble();
            for (int s = 0; s < NSET; s++) { muX[s] = tri(x, SETP[s][0], SETP[s][1], SETP[s][2]); muY[s] = tri(y, SETP[s][0], SETP[s][1], SETP[s][2]); }
            for (int xi = 0; xi < NSET; xi++)
                for (int yi = 0; yi < NSET; yi++) { double f = muX[xi] < muY[yi] ? muX[xi] : muY[yi]; fs[xi * NSET + yi] = f; }
            double num = 0.0, den = 0.0;
            for (int j = 0; j < NP; j++) {
                double agg = 0.0;
                for (int r = 0; r < NRULE; r++) { double osv = os[outset[r]][j]; double m = fs[r] < osv ? fs[r] : osv; if (m > agg) agg = m; }
                num += zval[j] * agg; den += agg;
            }
            checksum += den > 0.0 ? num / den : 0.0;
        }
        System.out.println(f6(checksum));
    }
}
