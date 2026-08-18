// K-Means (Lloyd's) — Data Mining benchmark (MICAI). Shared 64-bit LCG (seed 42),
// squared Euclidean distance, ties to lowest centroid index. Wrapping ops (*% +%)
// reproduce the C unsigned LCG. Strict IEEE FP (no FMA contraction in ReleaseFast).
const std = @import("std");
const N = 100000;
const D = 4;
const K = 10;
const ITERS = 1000;
var state: u64 = 42;
fn nextDouble() f64 {
    state = state *% 6364136223846793005 +% 1442695040888963407;
    return @as(f64, @floatFromInt(state >> 33)) / @as(f64, @floatFromInt(@as(u64, 1) << 31));
}
var points: [N * D]f64 = undefined;
var centroids: [K * D]f64 = undefined;
var sums: [K * D]f64 = undefined;
var counts: [K]i64 = undefined;
var assign: [N]usize = undefined;
pub fn main(init: std.process.Init) !void {
    const io = init.io;
    for (0..N) |i| for (0..D) |d| {
        points[i * D + d] = nextDouble();
    };
    for (0..K) |k| for (0..D) |d| {
        centroids[k * D + d] = points[k * D + d];
    };
    for (0..ITERS) |_| {
        for (0..N) |i| {
            var best: f64 = 1e300;
            var bestk: usize = 0;
            for (0..K) |k| {
                var dist: f64 = 0.0;
                for (0..D) |d| {
                    const diff = points[i * D + d] - centroids[k * D + d];
                    dist += diff * diff;
                }
                if (dist < best) {
                    best = dist;
                    bestk = k;
                }
            }
            assign[i] = bestk;
        }
        for (0..K) |k| {
            counts[k] = 0;
            for (0..D) |d| {
                sums[k * D + d] = 0.0;
            }
        }
        for (0..N) |i| {
            const k = assign[i];
            counts[k] += 1;
            for (0..D) |d| {
                sums[k * D + d] += points[i * D + d];
            }
        }
        for (0..K) |k| {
            if (counts[k] > 0) for (0..D) |d| {
                centroids[k * D + d] = sums[k * D + d] / @as(f64, @floatFromInt(counts[k]));
            };
        }
    }
    var fingerprint: i64 = 0;
    var centroid_sum: f64 = 0.0;
    for (0..K) |k| {
        fingerprint += counts[k] * @as(i64, @intCast(k + 1));
        for (0..D) |d| {
            centroid_sum += centroids[k * D + d];
        }
    }
    var stdout_buffer: [256]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;
    try stdout.print("{d} {d:.6}\n", .{ fingerprint, centroid_sum });
    try stdout.flush();
}
