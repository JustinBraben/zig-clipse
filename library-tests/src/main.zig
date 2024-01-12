const std = @import("std");

// Third party libs
const clap = @import("clap");
const reflect = @import("reflect");

const debug = std.debug;
const io = std.io;
const fs = std.fs;
const mem = std.mem;
const process = std.process;

const c = @import("clibs.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.testing.expect(gpa.deinit() != .leak) catch @panic("memory leak");
    const allocator = gpa.allocator();

    // First we specify what parameters our program can take.
    // We can use `parseParamsComptime` to parse a string into an array of `Param(Help)`
    const params = comptime clap.parseParamsComptime(
        \\-h,  --help                       Display this help and exit.
        \\-t,  --target         <str>       Clang target tuple, e.g. x86_86-windows-gnu
        \\-R,  --recurse                    An option parameter for recursive transpiling, use to also parse includes
        \\-g,  --no-glue                    An option parameter for no c++ glue code, bindings will be target specific
        \\-c,  --no-comments                An option parameter for not writing comments
        \\-l,  --clang-args     <str>...    Pass any clang arguments, e.g. -DNDEBUG -I.\include -target x86-linux-gnu
        \\<str>...                          Input files, .h, .hpp, .c, .cpp
        \\
    );

    // Initialize our diagnostics, which can be used for reporting useful errors.
    // This is optional. You can also pass `.{}` to `clap.parse` if you don't
    // care about the extra information `Diagnostics` provides.
    var diag = clap.Diagnostic{};
    var res = clap.parse(clap.Help, &params, clap.parsers.default, .{
        .diagnostic = &diag,
        .allocator = allocator,
    }) catch |err| {
        // Report useful error and exit
        diag.report(io.getStdErr().writer(), err) catch {};
        return err;
    };
    defer res.deinit();

    const cwd = try std.fs.cwd().realpathAlloc(allocator, ".");
    defer allocator.free(cwd);

    debug.print("cwd is {s}\n", .{cwd});

    const num_u8_example: u8 = 2;
    const bool_example: bool = true;
    const float_f32_example: f32 = 2.0;

    try reflect.printObject(@TypeOf(num_u8_example), num_u8_example);
    try reflect.printObject(@TypeOf(bool_example), bool_example);
    try reflect.printObject(@TypeOf(float_f32_example), float_f32_example);
}
