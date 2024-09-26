const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "library-tests",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const clap_dep = b.dependency("clap", .{});
    exe.root_module.addImport("clap", clap_dep.module("clap"));

    const zgl_dep = b.dependency("zgl", .{});
    exe.root_module.addImport("zgl", zgl_dep.module("zgl"));

    const reflect_dep = b.dependency("reflect", .{});
    exe.root_module.addImport("reflect", reflect_dep.module("reflect"));

    if (target.query.isNativeOs() and target.result.os.tag == .linux) {
        exe.linkSystemLibrary("SDL2");
        exe.linkLibC();
    } else {
        const sdl_dep = b.dependency("SDL2", .{ .target = target, .optimize = optimize });
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

    // Creates a step for unit testing. This only builds the test executable
    // but does not run it.
    const lib_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    const exe_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    // Similar to creating the run step earlier, this exposes a `test` step to
    // the `zig build --help` menu, providing a way for the user to request
    // running the unit tests.
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
    test_step.dependOn(&run_exe_unit_tests.step);
}
