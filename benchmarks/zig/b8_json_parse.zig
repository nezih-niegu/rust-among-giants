// Zig std.json — count cJSON-style node types. Object keys are NOT counted as
// strings (only values are), matching the C reference and the other languages.
const std = @import("std");
const Stats = struct { o: u64 = 0, a: u64 = 0, s: u64 = 0, n: u64 = 0, b: u64 = 0, nl: u64 = 0 };
fn countValue(v: std.json.Value) Stats {
    var st = Stats{};
    switch (v) {
        .object => |obj| {
            st.o = 1;
            var it = obj.iterator();
            while (it.next()) |entry| {
                const c = countValue(entry.value_ptr.*);
                st.o += c.o; st.a += c.a; st.s += c.s; st.n += c.n; st.b += c.b; st.nl += c.nl;
            }
        },
        .array => |arr| {
            st.a = 1;
            for (arr.items) |item| {
                const c = countValue(item);
                st.o += c.o; st.a += c.a; st.s += c.s; st.n += c.n; st.b += c.b; st.nl += c.nl;
            }
        },
        .string => st.s = 1,
        .integer, .float, .number_string => st.n = 1,
        .bool => st.b = 1,
        .null => st.nl = 1,
    }
    return st;
}
pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const arena = init.arena.allocator();
    const args = try init.minimal.args.toSlice(arena);
    const path = if (args.len > 1) args[1] else "../../data/json_input.json";
    const data = try std.Io.Dir.cwd().readFileAlloc(io, path, arena, .unlimited);
    const parsed = try std.json.parseFromSlice(std.json.Value, arena, data, .{});
    const r = countValue(parsed.value);
    var stdout_buffer: [256]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;
    try stdout.print("objects={d} arrays={d} strings={d} numbers={d} bools={d} nulls={d}\n", .{ r.o, r.a, r.s, r.n, r.b, r.nl });
    try stdout.flush();
}
