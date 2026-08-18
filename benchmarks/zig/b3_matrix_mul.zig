const std = @import("std");
const SIZE: usize = 2000;

var rng_state: u64 = 42;
fn nextDouble() f64 {
    @setFloatMode(.strict);
    rng_state = rng_state *% 6364136223846793005 +% 1442695040888963407;
    return @as(f64, @floatFromInt(rng_state >> 33)) / @as(f64, @floatFromInt(@as(u64, 1) << 31));
}

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    @setFloatMode(.strict);
    const allocator = std.heap.page_allocator;
    const A = try allocator.alloc(f64, SIZE * SIZE);
    const B = try allocator.alloc(f64, SIZE * SIZE);
    const C = try allocator.alloc(f64, SIZE * SIZE);
    defer { allocator.free(A); allocator.free(B); allocator.free(C); }
    @memset(C, 0.0);
    for (0..SIZE * SIZE) |i| { A[i] = nextDouble(); B[i] = nextDouble(); }
    for (0..SIZE) |i| {
        for (0..SIZE) |k| {
            const a_ik = A[i * SIZE + k];
            for (0..SIZE) |j| {
                const p = a_ik * B[k * SIZE + j];   // explicit temp: separate mul+add (no FMA), matches C
                C[i * SIZE + j] += p;
            }
        }
    }
    var sum: f64 = 0;
    for (C) |v| sum += v;
    var stdout_buffer: [256]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;
    try stdout.print("{d:.6}\n", .{sum});
    try stdout.flush();
}
