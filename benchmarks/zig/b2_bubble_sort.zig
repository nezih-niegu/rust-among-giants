const std = @import("std");
pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const N: usize = 100_000;
    var prng = std.Random.DefaultPrng.init(42);
    const rand = prng.random();
    const allocator = std.heap.page_allocator;
    const arr = try allocator.alloc(i32, N);
    defer allocator.free(arr);
    for (arr) |*x| x.* = @intCast(@mod(rand.int(i32), @as(i32, @intCast(N))));
    // Bubble sort
    for (0..N - 1) |i| {
        var swapped = false;
        for (0..N - i - 1) |j| {
            if (arr[j] > arr[j + 1]) {
                const tmp = arr[j]; arr[j] = arr[j + 1]; arr[j + 1] = tmp;
                swapped = true;
            }
        }
        if (!swapped) break;
    }
    var stdout_buffer: [256]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;
    try stdout.print("{d} {d}\n", .{ arr[0], arr[N - 1] });
    try stdout.flush();
}
