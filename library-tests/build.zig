const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "library-tests",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    exe.root_module.addAnonymousImport("clap", .{
        .root_source_file = .{ .path = "thirdparty/zig-clap/clap.zig" },
    });

    if (target.query.isNativeOs() and target.result.os.tag == .linux) {
        exe.linkSystemLibrary("SDL2");
        exe.linkLibC();
    } else {
        const sdl_dep = b.dependency("sdl", .{ .target = target, .optimize = optimize });
        exe.linkLibrary(sdl_dep.artifact("SDL2"));
    }

    // Good practice with reflection
    // std.debug.print("Type of root module: {}\n", .{@TypeOf(exe.root_module)});
    // std.debug.print("exe root module : {}\n", .{exe.root_module});
    // inline for (std.meta.fields(@TypeOf(exe.root_module))) |field| {
    //     std.debug.print("Field Name \t:\t {s}\n", .{field.name});
    //     std.debug.print("Field type \t:\t {}\n", .{field.type});
    //     std.debug.print("Field defval \t:\t {any}\n", .{field.default_value});
    //     std.debug.print("\n", .{});
    // }

    // inline for (std.meta.fields(std.Build.Dependency)) |field| {
    //     std.debug.print("{}\n", .{field});
    // }

    // for (std.meta.fields(b.available_deps)) |field| {
    //     std.debug.print("Field : {}", .{field});
    // }

    // for (b.available_deps) |dep_one| {
    //     std.debug.print("dep \t: {any}\n", .{dep_one});
    //     std.debug.print("val : {}\n", .{dep_one.ptr});
    // }

    // const hell = [_]u8{ 49, 50, 50, 48, 48, 54, 102, 49, 100, 50, 53, 100, 100, 49, 49, 50, 54, 48, 53, 97, 100, 48, 48, 57, 50, 57, 102, 48, 53, 101, 48, 53, 100, 97, 56, 52, 52, 100, 101, 99, 100, 52, 98, 99, 50, 53, 57, 57, 54, 57, 57, 56, 56, 49, 52, 55, 48, 52, 51, 52, 52, 98, 101, 56, 55, 97, 48, 57 };
    // std.debug.print("output : {s}\n", .{hell});

    // This declares intent for the executable to be installed into the
    // standard location when the user invokes the "install" step (the default
    // step when running `zig build`).
    b.installArtifact(exe);

    // This *creates* a Run step in the build graph, to be executed when another
    // step is evaluated that depends on it. The next line below will establish
    // such a dependency.
    const run_cmd = b.addRunArtifact(exe);

    // By making the run step depend on the install step, it will be run from the
    // installation directory rather than directly from within the cache directory.
    // This is not necessary, however, if the application depends on other installed
    // files, this ensures they will be present and in the expected location.
    run_cmd.step.dependOn(b.getInstallStep());

    // This allows the user to pass arguments to the application in the build
    // command itself, like this: `zig build run -- arg1 arg2 etc`
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    // This creates a build step. It will be visible in the `zig build --help` menu,
    // and can be selected like this: `zig build run`
    // This will evaluate the `run` step rather than the default, which is "install".
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // Creates a step for unit testing. This only builds the test executable
    // but does not run it.
    const lib_unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/root.zig" },
        .target = target,
        .optimize = optimize,
    });

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    const exe_unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/main.zig" },
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
