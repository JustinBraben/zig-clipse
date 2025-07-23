const std = @import("std");

pub fn build(b: *std.Build) void {
    const chibiboy_mod = b.addModule("chibiboy", .{ .root_source_file = b.path("src/chibiboy.zig") });
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const test_step = b.step("test", "Run all tests in all modes.");
    const tests = b.addTest(.{
        .root_source_file = b.path("tests/tests.zig"),
        .test_runner = .{
            .path = b.path("test_runner.zig"),
            .mode = .simple,
        },
        .target = target,
        .optimize = optimize,
    });
    tests.root_module.addImport("chibiboy", chibiboy_mod);
    const run_tests = b.addRunArtifact(tests);
    test_step.dependOn(&run_tests.step);

    const exe = b.addExecutable(.{
        .name = "chibiboy",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const clap_dep = b.dependency("clap", .{ .target = target, .optimize = optimize });
    exe.root_module.addImport("clap", clap_dep.module("clap"));

    if (target.query.isNativeOs() and target.result.os.tag == .linux) {
        exe.linkSystemLibrary("SDL2");
        exe.linkSystemLibrary("SDL2_ttf");
        exe.linkLibC();
    } else {
        const sdl_dep = b.dependency("SDL", .{ .target = target, .optimize = optimize });
        exe.linkLibrary(sdl_dep.artifact("SDL2"));

        const sdl2_ttf_dep = b.dependency("SDL2_ttf", .{ .target = target, .optimize = optimize });
        exe.linkLibrary(sdl2_ttf_dep.artifact("SDL2_ttf"));
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
