use std::io::{Read, Write, BufWriter, BufReader};
use std::fs;
fn main() {
    let chunk = 1024 * 1024;
    let chunks = 4096;
    let fname = std::env::args().nth(1)
        .unwrap_or_else(|| "../../data/fileio_test_rust.tmp".to_string());
    let buf = vec![b'A'; chunk];
    {
        let f = fs::File::create(&fname).unwrap();
        let mut w = BufWriter::new(f);
        for _ in 0..chunks { w.write_all(&buf).unwrap(); }
        w.flush().unwrap();
        w.into_inner().unwrap().sync_all().unwrap();
    }
    let mut total: u64 = 0;
    {
        let f = fs::File::open(&fname).unwrap();
        let mut r = BufReader::new(f);
        let mut rbuf = vec![0u8; chunk];
        loop {
            match r.read(&mut rbuf) {
                Ok(0) => break,
                Ok(n) => total += n as u64,
                Err(_) => break,
            }
        }
    }
    println!("{}", total);
    fs::remove_file(&fname).ok();
}
