import java.math.BigDecimal;
import java.math.RoundingMode;

// Genetic Algorithm minimizing Rosenbrock — Computational Intelligence
// benchmark (MICAI). Tournament selection, uniform crossover, uniform mutation.
// All arithmetic is +,-,*,/ so the search is bit-exact; every random decision
// draws from the shared 64-bit LCG (seed 42) in identical order across languages.
// Checksum = best fitness + sum of the best individual's genes.
public class B12Ga {
    static final int D = 30, P = 5000, G = 1200, T = 3;
    static final double MUT_RATE = 0.1, MUT_STEP = 0.1;
    static long state = 42;
    static double nextDouble() {
        state = state * 6364136223846793005L + 1442695040888963407L;
        return (double)(state >>> 33) / (double)(1L << 31);
    }
    static String f6(double v) { return new BigDecimal(v).setScale(6, RoundingMode.HALF_EVEN).toPlainString(); }
    static double rosenbrock(double[] x) {
        double f = 0.0;
        for (int i = 0; i < D - 1; i++) { double a = x[i + 1] - x[i] * x[i]; double b = 1.0 - x[i]; f += 100.0 * a * a + b * b; }
        return f;
    }
    public static void main(String[] args) {
        double[][] pop = new double[P][D];
        double[][] newpop = new double[P][D];
        double[] fitness = new double[P];
        double[] bestGenes = new double[D];
        for (int p = 0; p < P; p++) for (int d = 0; d < D; d++) pop[p][d] = (nextDouble() * 2.0 - 1.0) * 5.0;

        double bestFit = 1e300;
        for (int g = 0; g < G; g++) {
            for (int p = 0; p < P; p++) {
                double f = rosenbrock(pop[p]); fitness[p] = f;
                if (f < bestFit) { bestFit = f; for (int d = 0; d < D; d++) bestGenes[d] = pop[p][d]; }
            }
            for (int d = 0; d < D; d++) newpop[0][d] = bestGenes[d];
            for (int i = 1; i < P; i++) {
                int a = (int)(nextDouble() * P);
                for (int t = 1; t < T; t++) { int idx = (int)(nextDouble() * P); if (fitness[idx] < fitness[a]) a = idx; }
                int b = (int)(nextDouble() * P);
                for (int t = 1; t < T; t++) { int idx = (int)(nextDouble() * P); if (fitness[idx] < fitness[b]) b = idx; }
                for (int d = 0; d < D; d++) newpop[i][d] = (nextDouble() < 0.5) ? pop[a][d] : pop[b][d];
                for (int d = 0; d < D; d++) if (nextDouble() < MUT_RATE) newpop[i][d] += (nextDouble() * 2.0 - 1.0) * MUT_STEP;
            }
            for (int p = 0; p < P; p++) for (int d = 0; d < D; d++) pop[p][d] = newpop[p][d];
        }
        double gsum = 0.0;
        for (int d = 0; d < D; d++) gsum += bestGenes[d];
        System.out.println(f6(bestFit) + " " + f6(gsum));
    }
}
