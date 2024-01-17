const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "vkendeavors",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    const vk_lib_name = if (target.result.os.tag == .windows) "vulkan-1" else "vulkan";

    exe.linkSystemLibrary("SDL3");
    exe.linkSystemLibrary(vk_lib_name);
    exe.addLibraryPath(.{ .cwd_relative = "thirdparty/SDL3/lib" });
    exe.addIncludePath(.{ .cwd_relative = "thirdparty/sdl3/include" });

    if (b.env_map.get("VK_SDK_PATH")) |path| {
        // VK_SDK_PATH is set, you can use it
        std.debug.print("VK_SDK_PATH is set: {s}\n", .{path});

        exe.addLibraryPath(.{ .cwd_relative = std.fmt.allocPrint(b.allocator, "{s}/Lib", .{path}) catch @panic("OOM") });
        exe.addIncludePath(.{ .cwd_relative = std.fmt.allocPrint(b.allocator, "{s}/Include", .{path}) catch @panic("OOM") });
    } else {
        // VK_SDK_PATH is not set
        std.debug.print("VK_SDK_PATH environment variable is not set. Vulkan headers may not be found.\n", .{});
        // You may want to handle this case or provide instructions to the user
    }
    exe.addCSourceFile(.{ .file = .{ .path = "src/vk_mem_alloc.cpp" }, .flags = &.{""} });
    exe.addIncludePath(.{ .path = "thirdparty/vma/" });
    exe.addCSourceFile(.{ .file = .{ .path = "src/stb_image.c" }, .flags = &.{""} });
    exe.addIncludePath(.{ .path = "thirdparty/stb/" });
    exe.addIncludePath(.{ .path = "thirdparty/imgui/" });

    exe.linkLibCpp();

    // TODO: compile shaders here

    b.installArtifact(exe);
    switch (target.result.os.tag) {
        .windows => {
            b.installBinFile("thirdparty/sdl3/lib/SDL3.dll", "SDL3.dll");
        },
        else => {
            b.installBinFile("thirdparty/sdl3/lib/libSDL3.so", "libSDL3.so.0");
            exe.root_module.addRPathSpecial("$ORIGIN");
        },
    }

    // Imgui (with cimgui and vulkan + sdl3 backends)
    const imgui_lib = b.addStaticLibrary(.{
        .name = "cimgui",
        .target = target,
        .optimize = optimize,
    });
    imgui_lib.addIncludePath(.{ .path = "thirdparty/imgui/" });
    imgui_lib.addIncludePath(.{ .path = "thirdparty/sdl3/include/" });
    if (b.env_map.get("VK_SDK_PATH")) |path| {
        imgui_lib.addLibraryPath(.{ .cwd_relative = std.fmt.allocPrint(b.allocator, "{s}/Lib", .{path}) catch @panic("OOM") });
        imgui_lib.addIncludePath(.{ .cwd_relative = std.fmt.allocPrint(b.allocator, "{s}/Include", .{path}) catch @panic("OOM") });
    } else {
        // VK_SDK_PATH is not set
        std.debug.print("VK_SDK_PATH environment variable is not set. Vulkan headers may not be found.\n", .{});
        // You may want to handle this case or provide instructions to the user
    }
    imgui_lib.linkLibCpp();
    imgui_lib.addCSourceFiles(.{
        .files = &.{
            "thirdparty/imgui/imgui.cpp",
            "thirdparty/imgui/imgui_demo.cpp",
            "thirdparty/imgui/imgui_draw.cpp",
            "thirdparty/imgui/imgui_tables.cpp",
            "thirdparty/imgui/imgui_widgets.cpp",
            "thirdparty/imgui/imgui_impl_sdl3.cpp",
            "thirdparty/imgui/imgui_impl_vulkan.cpp",
            "thirdparty/imgui/cimgui.cpp",
            "thirdparty/imgui/cimgui_impl_sdl3.cpp",
            "thirdparty/imgui/cimgui_impl_vulkan.cpp",
        },
    });
    exe.linkLibrary(imgui_lib);

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

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

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
    test_step.dependOn(&run_exe_unit_tests.step);
}
