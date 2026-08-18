ITERATIONS = 100_000_000
class SimpleRNG:
    def __init__(s, seed=42): s.state = seed
    def next_double(s):
        s.state = (s.state * 6364136223846793005 + 1442695040888963407) & 0xFFFFFFFFFFFFFFFF
        return (s.state >> 33) / (1 << 31)
rng = SimpleRNG(42); inside = 0
for _ in range(ITERATIONS):
    x = rng.next_double(); y = rng.next_double()
    if x*x + y*y <= 1.0: inside += 1
print(f"{4.0 * inside / ITERATIONS:.10f}")
