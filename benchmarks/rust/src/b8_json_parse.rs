use serde_json::Value;
use std::fs;
fn count(v: &Value) -> (u64, u64, u64, u64, u64, u64) {
    match v {
        Value::Object(m) => {
            let (mut o, mut a, mut s, mut n, mut b, mut nl) = (1, 0, 0, 0, 0, 0);
            for val in m.values() {
                let r = count(val);
                o += r.0; a += r.1; s += r.2; n += r.3; b += r.4; nl += r.5;
            }
            (o, a, s, n, b, nl)
        }
        Value::Array(arr) => {
            let (mut o, mut a, mut s, mut n, mut b, mut nl) = (0, 1, 0, 0, 0, 0);
            for val in arr {
                let r = count(val);
                o += r.0; a += r.1; s += r.2; n += r.3; b += r.4; nl += r.5;
            }
            (o, a, s, n, b, nl)
        }
        Value::String(_) => (0, 0, 1, 0, 0, 0),
        Value::Number(_) => (0, 0, 0, 1, 0, 0),
        Value::Bool(_)   => (0, 0, 0, 0, 1, 0),
        Value::Null      => (0, 0, 0, 0, 0, 1),
    }
}
fn main() {
    let filename = std::env::args().nth(1).unwrap_or("../../data/json_input.json".into());
    let data = fs::read_to_string(&filename).expect("Cannot read file");
    let v: Value = serde_json::from_str(&data).expect("Invalid JSON");
    let r = count(&v);
    println!("objects={} arrays={} strings={} numbers={} bools={} nulls={}", r.0, r.1, r.2, r.3, r.4, r.5);
}
