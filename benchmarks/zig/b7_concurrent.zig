const std = @import("std");
const NUM_THREADS = 8;
const OPS = 10_000_000;
pub fn main(init: std.process.Init) !void {
    const io = init.io;
    var counter = std.atomic.Value(i64).init(0);
    var threads: [NUM_THREADS]std.Thread = undefined;
    for (&threads) |*t| {
        t.* = try std.Thread.spawn(.{}, worker, .{&counter});
    }
    for (threads) |t| t.join();
    var stdout_buffer: [256]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;
    try stdout.print("{d}\n", .{counter.load(.seq_cst)});
    try stdout.flush();
}
fn worker(counter: *std.atomic.Value(i64)) void {
    for (0..OPS) |_| { _ = counter.fetchAdd(1, .monotonic); }
}
