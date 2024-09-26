const std = @import("std");

const examples = [_][]const u8 {
    "basic",
    "complex",
};

pub fn build(b: *std.Build) void {
    const example_step = addExamples(b);

    const all_step = b.step("all", "Build everything and runs all tests");
    all_step.dependOn(example_step);

    b.default_step.dependOn(all_step);
}

fn addExamples(b: *std.Build) *std.Build.Step {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const example_step = b.step("examples", "Build examples");

    inline for (examples) |example_name| {
        const example = b.addExecutable(.{
            .name = example_name,
            .root_source_file = b.path("examples/" ++ example_name ++ ".zig"),
            .target = target,
            .optimize = optimize,
        });

        const reflect_mod = b.addModule("reflect", .{ .root_source_file = b.path("reflect.zig") });
        example.root_module.addImport("reflect", reflect_mod);

        const compile_step = b.step(example_name, "Build " ++ example_name);
        compile_step.dependOn(&b.addInstallArtifact(example, .{}).step);
        b.getInstallStep().dependOn(compile_step);

        const run_cmd = b.addRunArtifact(example);
        run_cmd.step.dependOn(compile_step);

        const run_step = b.step("run-" ++ example_name, "Run " ++ example_name);
        run_step.dependOn(&run_cmd.step);
    }

    return example_step;
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
