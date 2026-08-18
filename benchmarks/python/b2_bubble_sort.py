import random
N = 100_000; random.seed(42)
arr = [random.randint(0, N) for _ in range(N)]
for i in range(N - 1):
    swapped = False
    for j in range(N - i - 1):
        if arr[j] > arr[j+1]: arr[j], arr[j+1] = arr[j+1], arr[j]; swapped = True
    if not swapped: break
print(arr[0], arr[-1])
