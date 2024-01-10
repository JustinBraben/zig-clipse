const std = @import("std");
const clap = @import("clap");

const debug = std.debug;
const io = std.io;

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

    for (res.positionals) |pos| {
        debug.print("Checking positional : {s}\n", .{pos});

        const real_path_buff: *[std.fs.MAX_PATH_BYTES]u8 = undefined;

        const real_path = try std.fs.realpath(pos, real_path_buff);

        debug.print("Real path is {s}, outputting contents\n", .{real_path});

        const buff = try readFile(allocator, real_path);
        defer allocator.free(buff);

        var lines = std.mem.splitScalar(u8, buff, '\n');

        //debug.print("First line is {s}\n", .{lines.first()});

        while (lines.next()) |line| {
            //debug.print("{s}\n", .{line});
            // debug.print("newline\n", .{});
            //debug.print("Line size is {}\n", .{line.len});
            var tokens = std.mem.tokenizeScalar(u8, line, ' ');

            while (tokens.next()) |token| {
                debug.print("{s}\n", .{token});
                if (std.mem.startsWith(u8, token, "#include")) {
                    debug.print("Found #include token!\n", .{});
                } else {
                    debug.print("No #include token!\n", .{});
                }
            }
            // if (std.mem.startsWith(u8, line, "//")) {
            //     debug.print("{s}\n", .{line});
            // }
        }
    }
}

fn readFile(allocator: std.mem.Allocator, filename: []const u8) ![]u8 {
    const file = try std.fs.cwd().openFile(
        filename,
        .{ .mode = .read_only },
    );
    defer file.close();

    const stat = try file.stat();
    const buff = try file.readToEndAlloc(allocator, stat.size);
    return buff;
}

test "replace" {
    var output: [29]u8 = undefined;
    const replacements = std.mem.replace(u8, "All your base are belong to us", "base", "Zig", output[0..]);
    const expected: []const u8 = "All your Zig are belong to us";
    try std.testing.expect(replacements == 1);
    try std.testing.expectEqualStrings(expected, output[0..expected.len]);
}

test "starts_with" {
    //var output: [21]u8 = undefined;
    const line = "// #include <cstring>";
    const include_line = "#include \"cpu.h\"";
    try std.testing.expect(std.mem.startsWith(u8, line, "//"));
    try std.testing.expect(std.mem.startsWith(u8, include_line, "#include"));
}
