#include <iostream>
#include <thread>
#include <atomic>
#include <vector>
int main() {
    std::atomic<long long> counter{0};
    constexpr int T = 8, OPS = 10000000;
    std::vector<std::thread> threads;
    for (int i = 0; i < T; i++)
        threads.emplace_back([&]{ for (int j = 0; j < OPS; j++) counter.fetch_add(1, std::memory_order_relaxed); });
    for (auto& t : threads) t.join();
    std::cout << counter.load() << "\n";
}
