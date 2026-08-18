// k-NN classification — Machine Learning benchmark (MICAI). Shared LCG (seed 42),
// squared Euclidean distance, vote ties to lowest class. Checksum = sum of labels.
const std = @import("std");
const M = 50000;
const Q = 10000;
const D = 8;
const K = 15;
const C = 3;
var state: u64 = 42;
fn nextDouble() f64 {
    state = state *% 6364136223846793005 +% 1442695040888963407;
    return @as(f64, @floatFromInt(state >> 33)) / @as(f64, @floatFromInt(@as(u64, 1) << 31));
}
var train: [M * D]f64 = undefined;
var label: [M]i64 = undefined;
var query: [Q * D]f64 = undefined;
pub fn main(init: std.process.Init) !void {
    const io = init.io;
    for (0..M) |t| {
        for (0..D) |d| {
            train[t * D + d] = nextDouble();
        }
        label[t] = @intFromFloat(nextDouble() * C);
    }
    for (0..Q) |q| for (0..D) |d| {
        query[q * D + d] = nextDouble();
    };
    var checksum: i64 = 0;
    var best_d: [K]f64 = undefined;
    var best_l: [K]i64 = undefined;
    for (0..Q) |q| {
        for (0..K) |j| {
            best_d[j] = 1e300;
            best_l[j] = 0;
        }
        for (0..M) |t| {
            var dist: f64 = 0.0;
            for (0..D) |d| {
                const diff = query[q * D + d] - train[t * D + d];
                dist += diff * diff;
            }
            if (dist < best_d[K - 1]) {
                var p: usize = K - 1;
                while (p > 0 and dist < best_d[p - 1]) : (p -= 1) {
                    best_d[p] = best_d[p - 1];
                    best_l[p] = best_l[p - 1];
                }
                best_d[p] = dist;
                best_l[p] = label[t];
            }
        }
        var votes: [C]i64 = .{0} ** C;
        for (0..K) |j| {
            votes[@as(usize, @intCast(best_l[j]))] += 1;
        }
        var pred: usize = 0;
        for (1..C) |c| {
            if (votes[c] > votes[pred]) pred = c;
        }
        checksum += @as(i64, @intCast(pred));
    }
    var stdout_buffer: [256]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;
    try stdout.print("{d}\n", .{checksum});
    try stdout.flush();
}
