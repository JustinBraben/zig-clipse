const std = @import("std");

pub fn build(b: *std.Build) void {
    const reflect_mod = b.addModule("reflect", .{ .root_source_file = .{ .path = "reflect.zig" } });
    _ = reflect_mod; // autofix

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const test_step = b.step("test", "Run all tests in all modes.");
    const tests = b.addTest(.{
        .root_source_file = .{ .path = "reflect.zig" },
        .target = target,
        .optimize = optimize,
    });
    const run_tests = b.addRunArtifact(tests);
    test_step.dependOn(&run_tests.step);

    // TODO: make examples to run
    // const example_step = b.step("examples", "Build examples.");
    // for ([_][]const u8{
    //     "basic.zig",
    //     "complex.zig",
    //     "enum.zig",
    //     "flag.zig",
    //     "positional.zig",
    //     "required.zig",
    //     "subcommand.zig",
    //     "usage.zig",
    // }) |example_name| {
    //     const example = b.addExecutable(.{
    //         .name = example_name,
    //         .root_source_file = .{ .path = b.fmt("example/{s}.zig", .{example_name}) },
    //         .target = target,
    //         .optimize = optimize,
    //     });
    //     const install_example = b.addInstallArtifact(example, .{});
    //     example.root_module.addImport("reflect", reflect_mod);
    //     example_step.dependOn(&example.step);
    //     example_step.dependOn(&install_example.step);
    // }

    const docs_step = b.step("docs", "Generate docs.");
    const install_docs = b.addInstallDirectory(.{
        .source_dir = tests.getEmittedDocs(),
        .install_dir = .prefix,
        .install_subdir = "docs",
    });
    docs_step.dependOn(&install_docs.step);

    // TODO: make readme step
    // const readme_step = b.step("readme", "Remake README.");
    // const readme = readMeStep(b);
    // readme.dependOn(example_step);
    // readme_step.dependOn(readme);

    const all_step = b.step("all", "Build everything and runs all tests");
    all_step.dependOn(test_step);
    //all_step.dependOn(example_step);
    //all_step.dependOn(readme_step);

    b.default_step.dependOn(all_step);
}

fn readMeStep(b: *std.Build) *std.Build.Step {
    const s = b.allocator.create(std.Build.Step) catch unreachable;
    s.* = std.Build.Step.init(.{
        .id = .custom,
        .name = "ReadMeStep",
        .owner = b,
        .makeFn = struct {
            fn make(step: *std.Build.Step, _: *std.Progress.Node) anyerror!void {
                @setEvalBranchQuota(10000);
                _ = step;
                const file = try std.fs.cwd().createFile("README.md", .{});
                const stream = file.writer();
                try stream.print(@embedFile("example/README.md.template"), .{
                    @embedFile("example/basic.zig"),
                    @embedFile("example/complex.zig"),
                    @embedFile("example/enum.zig"),
                    @embedFile("example/flag.zig"),
                    @embedFile("example/positional.zig"),
                    @embedFile("example/required.zig"),
                    @embedFile("example/subcommand.zig"),
                    @embedFile("example/usage.zig"),
                });
            }
        }.make,
    });
    return s;
}
