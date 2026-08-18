// B6: durable checkpoint I/O — write 4 GiB in 1 MiB chunks, flush, fsync, read
// back, print total bytes, delete. 0.16 Io-based file API. Output: 4294967296.
const std = @import("std");
const CHUNK: usize = 1024 * 1024;
const CHUNKS: usize = 4096; // 4 GiB
pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const arena = init.arena.allocator();
    const args = try init.minimal.args.toSlice(arena);
    const fname = if (args.len > 1) args[1] else "../../data/fileio_test_zig.tmp";
    const buf = try arena.alloc(u8, CHUNK);
    @memset(buf, 'A');
    const cwd = std.Io.Dir.cwd();
    {
        const f = try cwd.createFile(io, fname, .{});
        defer f.close(io);
        var wbuf: [4096]u8 = undefined;
        var fw = f.writer(io, &wbuf);
        const w = &fw.interface;
        for (0..CHUNKS) |_| try w.writeAll(buf);
        try w.flush();
        try f.sync(io);
    }
    var total: u64 = 0;
    {
        const f = try cwd.openFile(io, fname, .{});
        defer f.close(io);
        var rbuf: [4096]u8 = undefined;
        var fr = f.reader(io, &rbuf);
        const r = &fr.interface;
        while (true) {
            const n = r.readSliceShort(buf) catch break;
            if (n == 0) break;
            total += n;
        }
    }
    try cwd.deleteFile(io, fname);
    var stdout_buffer: [64]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;
    try stdout.print("{d}\n", .{total});
    try stdout.flush();
}
