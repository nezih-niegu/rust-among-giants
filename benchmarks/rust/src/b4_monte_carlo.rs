const ITERATIONS: u64 = 1_000_000_000;
fn main() {
    let mut state: u64 = 42;
    let mut next_double = || -> f64 {
        state = state.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
        (state >> 33) as f64 / (1u64 << 31) as f64
    };
    let mut inside: u64 = 0;
    for _ in 0..ITERATIONS {
        let x = next_double();
        let y = next_double();
        if x * x + y * y <= 1.0 { inside += 1; }
    }
    println!("{:.10}", 4.0 * inside as f64 / ITERATIONS as f64);
}
