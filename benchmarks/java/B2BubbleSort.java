import java.util.Random;
public class B2BubbleSort {
    public static void main(String[] args) {
        int N = 100000;
        Random rng = new Random(42);
        int[] arr = new int[N];
        for (int i = 0; i < N; i++) arr[i] = rng.nextInt(N);
        for (int i = 0; i < N - 1; i++) {
            boolean swapped = false;
            for (int j = 0; j < N - i - 1; j++) {
                if (arr[j] > arr[j + 1]) {
                    int tmp = arr[j]; arr[j] = arr[j + 1]; arr[j + 1] = tmp;
                    swapped = true;
                }
            }
            if (!swapped) break;
        }
        System.out.println(arr[0] + " " + arr[N - 1]);
    }
}
