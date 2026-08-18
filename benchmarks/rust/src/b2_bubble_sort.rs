fn main() {
    let n = 100_000usize;
    let mut rng: u64 = 42;
    let mut arr: Vec<i32> = (0..n).map(|_| {
        rng = rng.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
        (rng >> 33) as i32 % n as i32
    }).collect();
    for i in 0..n - 1 {
        let mut swapped = false;
        for j in 0..n - i - 1 {
            if arr[j] > arr[j + 1] {
                arr.swap(j, j + 1);
                swapped = true;
            }
        }
        if !swapped { break; }
    }
    println!("{} {}", arr[0], arr[n - 1]);
}
