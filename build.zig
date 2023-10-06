const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{ .preferred_optimize_mode = std.builtin.OptimizeMode.Debug });

    const exe = b.addExecutable(.{
        .name = "gametest",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    const sdl_path = "C:\\Dev\\sdl\\SDL2-2.26.5\\";
    exe.addIncludePath(.{ .cwd_relative = sdl_path ++ "include" });
    exe.addLibraryPath(.{ .cwd_relative = sdl_path ++ "lib\\x64" });
    b.installBinFile(sdl_path ++ "lib\\x64\\SDL2.dll", "SDL2.dll");
    exe.linkSystemLibrary("sdl2");

    exe.linkLibC();
    b.installArtifact(exe);
}
