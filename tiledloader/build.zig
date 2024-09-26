const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "tiledloader",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    if (target.result.os.tag == .linux) {
        // The SDL package doesn't work for Linux yet, so we rely on system
        // packages for now.
        exe.linkSystemLibrary("SDL2");
    } else {
        const sdl_dep = b.dependency("SDL2", .{
            .optimize = .ReleaseFast,
            .target = target,
        });
        const sdl_image_dep = b.dependency("SDL_Image", .{
            .optimize = .ReleaseFast,
            .target = target,
        });
        exe.linkLibrary(sdl_dep.artifact("SDL2"));
        exe.linkLibrary(sdl_image_dep.artifact("SDL_Image"));
    }

    exe.linkLibC();

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
