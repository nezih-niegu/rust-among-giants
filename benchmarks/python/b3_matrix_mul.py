import random
SIZE = 1000; random.seed(42)
A = [[random.random() for _ in range(SIZE)] for _ in range(SIZE)]
B = [[random.random() for _ in range(SIZE)] for _ in range(SIZE)]
C = [[0.0]*SIZE for _ in range(SIZE)]
for i in range(SIZE):
    for k in range(SIZE):
        a_ik = A[i][k]
        for j in range(SIZE): C[i][j] += a_ik * B[k][j]
print(f"{sum(C[i][j] for i in range(SIZE) for j in range(SIZE)):.6f}")
