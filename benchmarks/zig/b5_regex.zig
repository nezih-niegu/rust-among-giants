// Zig has no stdlib regex — manual email detection matching the POSIX ERE
//   [a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}
const std = @import("std");
fn isLocal(c: u8) bool {
    return std.ascii.isAlphanumeric(c) or c == '.' or c == '_' or c == '%' or c == '+' or c == '-';
}
fn isDom(c: u8) bool {
    return std.ascii.isAlphanumeric(c) or c == '.' or c == '-';
}
fn hasEmail(line: []const u8) bool {
    for (line, 0..) |c, i| {
        if (c != '@' or i == 0 or i + 1 >= line.len) continue;
        if (!isLocal(line[i - 1])) continue;
        // maximal domain run after '@'
        var e: usize = i;
        while (e + 1 < line.len and isDom(line[e + 1])) e += 1;
        if (e < i + 2) continue; // need >=1 domain char then a '.'
        var d: usize = i + 2;
        while (d + 2 <= e) : (d += 1) {
            if (line[d] == '.' and std.ascii.isAlphabetic(line[d + 1]) and std.ascii.isAlphabetic(line[d + 2])) return true;
        }
    }
    return false;
}
pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const arena = init.arena.allocator();
    const args = try init.minimal.args.toSlice(arena);
    const path = if (args.len > 1) args[1] else "../../data/regex_input.txt";
    const data = try std.Io.Dir.cwd().readFileAlloc(io, path, arena, .unlimited);
    var count: u64 = 0;
    var it = std.mem.splitScalar(u8, data, '\n');
    while (it.next()) |line| {
        if (hasEmail(line)) count += 1;
    }
    var stdout_buffer: [64]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;
    try stdout.print("{d}\n", .{count});
    try stdout.flush();
}
