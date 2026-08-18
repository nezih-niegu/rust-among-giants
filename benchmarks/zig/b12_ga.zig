// Genetic Algorithm minimizing Rosenbrock — Computational Intelligence
// benchmark (MICAI). Tournament selection, uniform crossover/mutation; all
// +,-,*,/ so bit-exact. Shared LCG (seed 42) drives every random decision.
const std = @import("std");
const D = 30;
const P = 5000;
const G = 1200;
const T = 3;
const MUT_RATE = 0.1;
const MUT_STEP = 0.1;
var state: u64 = 42;
fn nextDouble() f64 {
    state = state *% 6364136223846793005 +% 1442695040888963407;
    return @as(f64, @floatFromInt(state >> 33)) / @as(f64, @floatFromInt(@as(u64, 1) << 31));
}
var pop: [P * D]f64 = undefined;
var newpop: [P * D]f64 = undefined;
var fitness: [P]f64 = undefined;
var best_genes: [D]f64 = undefined;
fn rosenbrock(off: usize) f64 {
    var f: f64 = 0.0;
    for (0..D - 1) |i| {
        const a = pop[off + i + 1] - pop[off + i] * pop[off + i];
        const b = 1.0 - pop[off + i];
        f += 100.0 * a * a + b * b;
    }
    return f;
}
pub fn main(init: std.process.Init) !void {
    const io = init.io;
    for (0..P) |p| for (0..D) |d| {
        pop[p * D + d] = (nextDouble() * 2.0 - 1.0) * 5.0;
    };
    var best_fit: f64 = 1e300;
    for (0..G) |_| {
        for (0..P) |p| {
            const f = rosenbrock(p * D);
            fitness[p] = f;
            if (f < best_fit) {
                best_fit = f;
                for (0..D) |d| {
                    best_genes[d] = pop[p * D + d];
                }
            }
        }
        for (0..D) |d| {
            newpop[d] = best_genes[d];
        }
        for (1..P) |i| {
            var a: usize = @intFromFloat(nextDouble() * P);
            for (1..T) |_| {
                const idx: usize = @intFromFloat(nextDouble() * P);
                if (fitness[idx] < fitness[a]) a = idx;
            }
            var b: usize = @intFromFloat(nextDouble() * P);
            for (1..T) |_| {
                const idx: usize = @intFromFloat(nextDouble() * P);
                if (fitness[idx] < fitness[b]) b = idx;
            }
            for (0..D) |d| {
                newpop[i * D + d] = if (nextDouble() < 0.5) pop[a * D + d] else pop[b * D + d];
            }
            for (0..D) |d| {
                if (nextDouble() < MUT_RATE)
                    newpop[i * D + d] += (nextDouble() * 2.0 - 1.0) * MUT_STEP;
            }
        }
        for (0..P) |p| for (0..D) |d| {
            pop[p * D + d] = newpop[p * D + d];
        };
    }
    var gsum: f64 = 0.0;
    for (0..D) |d| {
        gsum += best_genes[d];
    }
    var stdout_buffer: [256]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;
    try stdout.print("{d:.6} {d:.6}\n", .{ best_fit, gsum });
    try stdout.flush();
}
