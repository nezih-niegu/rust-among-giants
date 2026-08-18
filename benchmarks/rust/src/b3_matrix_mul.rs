const SIZE: usize = 2000;
fn main() {
    let mut rng: u64 = 42;
    let mut next = || -> f64 {
        rng = rng.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
        (rng >> 33) as f64 / (1u64 << 31) as f64
    };
    let mut a = vec![0.0f64; SIZE * SIZE];
    let mut b = vec![0.0f64; SIZE * SIZE];
    let mut c = vec![0.0f64; SIZE * SIZE];
    for i in 0..SIZE * SIZE { a[i] = next(); b[i] = next(); }
    for i in 0..SIZE {
        for k in 0..SIZE {
            let a_ik = a[i * SIZE + k];
            for j in 0..SIZE {
                c[i * SIZE + j] += a_ik * b[k * SIZE + j];
            }
        }
    }
    println!("{:.6}", c.iter().sum::<f64>());
}
