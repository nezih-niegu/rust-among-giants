#include <iostream>
#include <vector>
#include <algorithm>
#include <cstdlib>
int main() {
    constexpr int N = 100000;
    std::srand(42);
    std::vector<int> arr(N);
    for (auto& x : arr) x = std::rand() % N;
    for (int i = 0; i < N - 1; i++) {
        bool swapped = false;
        for (int j = 0; j < N - i - 1; j++) {
            if (arr[j] > arr[j+1]) { std::swap(arr[j], arr[j+1]); swapped = true; }
        }
        if (!swapped) break;
    }
    std::cout << arr[0] << " " << arr[N-1] << "\n";
}
