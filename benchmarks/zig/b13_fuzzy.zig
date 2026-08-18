// Mamdani fuzzy inference system — Fuzzy Systems benchmark (MICAI).
// 3 triangular sets/input, 9-rule base, max-min aggregation, centroid
// defuzzification; only +,-,*,/,min,max so bit-exact. Shared LCG (seed 42).
const std = @import("std");
const Q = 2000000;
const NP = 100;
const NSET = 3;
const NRULE = 9;
const setp = [NSET][3]f64{
    .{ -0.5, 0.0, 0.5 },
    .{ 0.0, 0.5, 1.0 },
    .{ 0.5, 1.0, 1.5 },
};
var state: u64 = 42;
fn nextDouble() f64 {
    state = state *% 6364136223846793005 +% 1442695040888963407;
    return @as(f64, @floatFromInt(state >> 33)) / @as(f64, @floatFromInt(@as(u64, 1) << 31));
}
fn tri(v: f64, a: f64, b: f64, c: f64) f64 {
    const left = (v - a) / (b - a);
    const right = (c - v) / (c - b);
    const m = if (left < right) left else right;
    return if (m > 0.0) m else 0.0;
}
var zval: [NP]f64 = undefined;
var os: [NSET * NP]f64 = undefined;
var outset: [NRULE]usize = undefined;
pub fn main(init: std.process.Init) !void {
    const io = init.io;
    for (0..NP) |j| {
        const z = @as(f64, @floatFromInt(j)) / @as(f64, @floatFromInt(NP - 1));
        zval[j] = z;
        for (0..NSET) |s| {
            os[s * NP + j] = tri(z, setp[s][0], setp[s][1], setp[s][2]);
        }
    }
    for (0..NSET) |xi| for (0..NSET) |yi| {
        const sum = xi + yi;
        outset[xi * NSET + yi] = if (sum <= 1) 0 else (if (sum == 2) 1 else 2);
    };
    var checksum: f64 = 0.0;
    var mu_x: [NSET]f64 = undefined;
    var mu_y: [NSET]f64 = undefined;
    var fs: [NRULE]f64 = undefined;
    for (0..Q) |_| {
        const x = nextDouble();
        const y = nextDouble();
        for (0..NSET) |s| {
            mu_x[s] = tri(x, setp[s][0], setp[s][1], setp[s][2]);
            mu_y[s] = tri(y, setp[s][0], setp[s][1], setp[s][2]);
        }
        for (0..NSET) |xi| for (0..NSET) |yi| {
            fs[xi * NSET + yi] = if (mu_x[xi] < mu_y[yi]) mu_x[xi] else mu_y[yi];
        };
        var num: f64 = 0.0;
        var den: f64 = 0.0;
        for (0..NP) |j| {
            var agg: f64 = 0.0;
            for (0..NRULE) |r| {
                const osv = os[outset[r] * NP + j];
                const m = if (fs[r] < osv) fs[r] else osv;
                if (m > agg) agg = m;
            }
            num += zval[j] * agg;
            den += agg;
        }
        checksum += if (den > 0.0) num / den else 0.0;
    }
    var stdout_buffer: [256]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;
    try stdout.print("{d:.6}\n", .{checksum});
    try stdout.flush();
}
