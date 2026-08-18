const std = @import("std");
const ITERATIONS: u64 = 1_000_000_000;
pub fn main(init: std.process.Init) !void {
    const io = init.io;
    var state: u64 = 42;
    var inside: u64 = 0;
    for (0..ITERATIONS) |_| {
        state = state *% 6364136223846793005 +% 1442695040888963407;
        const x: f64 = @as(f64, @floatFromInt(state >> 33)) / @as(f64, @floatFromInt(@as(u64, 1) << 31));
        state = state *% 6364136223846793005 +% 1442695040888963407;
        const y: f64 = @as(f64, @floatFromInt(state >> 33)) / @as(f64, @floatFromInt(@as(u64, 1) << 31));
        if (x * x + y * y <= 1.0) inside += 1;
    }
    var stdout_buffer: [256]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;
    try stdout.print("{d:.10}\n", .{4.0 * @as(f64, @floatFromInt(inside)) / @as(f64, @floatFromInt(ITERATIONS))});
    try stdout.flush();
}
