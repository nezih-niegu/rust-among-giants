const std = @import("std");
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize: std.builtin.OptimizeMode = .ReleaseFast;
    const targets = [_][]const u8{
        "b1_fibonacci", "b2_bubble_sort", "b3_matrix_mul", "b4_monte_carlo",
        "b5_regex", "b6_file_io", "b7_concurrent", "b8_json_parse",
        "b9_kmeans", "b10_knn", "b11_mlp", "b12_ga", "b13_fuzzy",
    };
    for (targets) |name| {
        const exe = b.addExecutable(.{
            .name = name,
            .root_source_file = b.path(b.fmt("{s}.zig", .{name})),
            .target = target,
            .optimize = optimize,
        });
        b.installArtifact(exe);
    }
}
