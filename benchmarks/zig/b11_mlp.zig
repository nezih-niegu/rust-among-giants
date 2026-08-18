// MLP training (forward + backprop, full-batch GD) — Neural Network benchmark
// (MICAI). D->H->O, ReLU hidden, linear output, MSE; only +,-,*,/ and max, so
// bit-exact. ReleaseFast keeps strict IEEE FP (no FMA contraction).
const std = @import("std");
const N = 10000;
const D = 16;
const H = 64;
const O = 4;
const E = 150;
const LR = 0.01;
var state: u64 = 42;
fn nextDouble() f64 {
    state = state *% 6364136223846793005 +% 1442695040888963407;
    return @as(f64, @floatFromInt(state >> 33)) / @as(f64, @floatFromInt(@as(u64, 1) << 31));
}
var W1: [H * D]f64 = undefined;
var b1: [H]f64 = undefined;
var W2: [O * H]f64 = undefined;
var b2: [O]f64 = undefined;
var x: [N * D]f64 = undefined;
var target: [N * O]f64 = undefined;
var gW1: [H * D]f64 = undefined;
var gb1: [H]f64 = undefined;
var gW2: [O * H]f64 = undefined;
var gb2: [O]f64 = undefined;
var z1: [H]f64 = undefined;
var a1: [H]f64 = undefined;
var y: [O]f64 = undefined;
var dy: [O]f64 = undefined;
pub fn main(init: std.process.Init) !void {
    const io = init.io;
    for (0..H) |h| {
        for (0..D) |d| {
            W1[h * D + d] = (nextDouble() * 2.0 - 1.0) * 0.1;
        }
        b1[h] = 0.0;
    }
    for (0..O) |o| {
        for (0..H) |h| {
            W2[o * H + h] = (nextDouble() * 2.0 - 1.0) * 0.1;
        }
        b2[o] = 0.0;
    }
    for (0..N) |n| {
        for (0..D) |d| {
            x[n * D + d] = nextDouble();
        }
        for (0..O) |o| {
            target[n * O + o] = nextDouble();
        }
    }
    const scale: f64 = LR / @as(f64, N);
    var final_loss: f64 = 0.0;
    for (0..E) |_| {
        for (0..H) |h| {
            gb1[h] = 0.0;
            for (0..D) |d| {
                gW1[h * D + d] = 0.0;
            }
        }
        for (0..O) |o| {
            gb2[o] = 0.0;
            for (0..H) |h| {
                gW2[o * H + h] = 0.0;
            }
        }
        var epoch_loss: f64 = 0.0;
        for (0..N) |n| {
            for (0..H) |h| {
                var s: f64 = b1[h];
                for (0..D) |d| {
                    s += W1[h * D + d] * x[n * D + d];
                }
                z1[h] = s;
                a1[h] = if (s > 0.0) s else 0.0;
            }
            for (0..O) |o| {
                var s: f64 = b2[o];
                for (0..H) |h| {
                    s += W2[o * H + h] * a1[h];
                }
                y[o] = s;
            }
            for (0..O) |o| {
                const diff = y[o] - target[n * O + o];
                epoch_loss += diff * diff;
                dy[o] = 2.0 * diff;
            }
            for (0..O) |o| {
                gb2[o] += dy[o];
                for (0..H) |h| {
                    gW2[o * H + h] += dy[o] * a1[h];
                }
            }
            for (0..H) |h| {
                var da: f64 = 0.0;
                for (0..O) |o| {
                    da += W2[o * H + h] * dy[o];
                }
                const dz = if (z1[h] > 0.0) da else 0.0;
                gb1[h] += dz;
                for (0..D) |d| {
                    gW1[h * D + d] += dz * x[n * D + d];
                }
            }
        }
        for (0..H) |h| {
            b1[h] -= scale * gb1[h];
            for (0..D) |d| {
                W1[h * D + d] -= scale * gW1[h * D + d];
            }
        }
        for (0..O) |o| {
            b2[o] -= scale * gb2[o];
            for (0..H) |h| {
                W2[o * H + h] -= scale * gW2[o * H + h];
            }
        }
        final_loss = epoch_loss / @as(f64, N * O);
    }
    var wsum: f64 = 0.0;
    for (0..H) |h| {
        wsum += b1[h];
        for (0..D) |d| {
            wsum += W1[h * D + d];
        }
    }
    for (0..O) |o| {
        wsum += b2[o];
        for (0..H) |h| {
            wsum += W2[o * H + h];
        }
    }
    var stdout_buffer: [256]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;
    try stdout.print("{d:.6} {d:.6}\n", .{ final_loss, wsum });
    try stdout.flush();
}
