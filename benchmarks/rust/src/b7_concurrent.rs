use std::sync::atomic::{AtomicU64, Ordering};
use std::sync::Arc;
use std::thread;
fn main() {
    let counter = Arc::new(AtomicU64::new(0));
    let handles: Vec<_> = (0..8).map(|_| {
        let c = Arc::clone(&counter);
        thread::spawn(move || {
            for _ in 0..10_000_000u64 { c.fetch_add(1, Ordering::Relaxed); }
        })
    }).collect();
    for h in handles { h.join().unwrap(); }
    println!("{}", counter.load(Ordering::SeqCst));
}
