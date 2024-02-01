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

    exe.root_module.addAnonymousImport("reflect", .{
        .root_source_file = .{ .path = "thirdparty/reflect/reflect.zig" },
    });

    if (target.query.isNativeOs() and target.result.os.tag == .linux) {
        exe.linkSystemLibrary("SDL2");
        exe.linkLibC();
    } else {
        const sdl_dep = b.dependency("sdl", .{ .target = target, .optimize = optimize });
        exe.linkLibrary(sdl_dep.artifact("SDL2"));
    }

    const mach_glfw_dep = b.dependency("mach-glfw", .{});
    exe.root_module.addImport("mach-glfw", mach_glfw_dep.module("mach-glfw"));

    const zgl_dep = b.dependency("zgl", .{});
    exe.root_module.addImport("zgl", zgl_dep.module("zgl"));

    // exe.linkSystemLibrary("pugixml");
    // exe.addIncludePath(.{ .path = "thirdparty/pugixml/src/" });
    // exe.addCSourceFiles(.{
    //     .files = &.{
    //         "thirdparty/pugixml/src/pugixml.cpp",
    //     },
    // });
    // exe.linkLibCpp();

    b.installArtifact(exe);

    // Add pugixml as a static library
    // const pugixml_lib = b.addStaticLibrary(.{
    //     .name = "pugixml",
    //     .target = target,
    //     .optimize = optimize,
    // });
    // pugixml_lib.addIncludePath(.{ .path = "thirdparty/pugixml/src/" });
    // pugixml_lib.linkLibCpp();
    // pugixml_lib.addCSourceFiles(.{
    //     .files = &.{
    //         "thirdparty/pugixml/src/pugixml.cpp",
    //     },
    // });
    // exe.linkLibrary(pugixml_lib);

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
