use regex::Regex;
use std::io::{BufRead, BufReader};
use std::fs::File;
fn main() {
    let filename = std::env::args().nth(1).unwrap_or("../../data/regex_input.txt".into());
    let re = Regex::new(r"[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}").unwrap();
    let file = File::open(&filename).expect("Cannot open file");
    let reader = BufReader::new(file);
    let mut count = 0u64;
    for line in reader.lines() {
        if let Ok(l) = line {
            if re.is_match(&l) { count += 1; }
        }
    }
    println!("{}", count);
}
