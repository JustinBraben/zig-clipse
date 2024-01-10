const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "chibiboy",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    if (target.query.isNativeOs() and target.result.os.tag == .linux) {
        exe.linkSystemLibrary("SDL2");
        exe.linkLibC();
    } else {
        const sdl_dep = b.dependency("sdl", .{ .target = target, .optimize = optimize });
        exe.linkLibrary(sdl_dep.artifact("SDL2"));
    }

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
