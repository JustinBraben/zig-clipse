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

        const real_path_buffer: *[98302]u8 = undefined;

        const real_path = try std.fs.realpath(pos, real_path_buffer);

        debug.print("Real path is {s}, outputting contents\n", .{real_path});

        const buff = try readFile(allocator, real_path);
        defer allocator.free(buff);

        var lines = std.mem.splitSequence(u8, buff, "\n");

        debug.print("First line is {s}\n", .{lines.first()});

        while (lines.next()) |line| {
            // debug.print("{s}\n", .{line});
            // debug.print("newline\n", .{});
            debug.print("Line size is {}\n", .{line.len});
        }

        //debug.print("{any}\n", .{lines});

        // while (lines.next()) |line| {
        //     //debug.print("{s}\n", .{line});

        //     var tokens = std.mem.tokenizeScalar(u8, line, '\n');
        //     while (tokens.next()) |token| {
        //         debug.print("{s}\n", .{token});
        //         if (std.mem.startsWith(u8, token, "//")) {
        //             debug.print("{s}\n", .{token});
        //         }
        //     }

        //     // if (std.mem.startsWith(u8, line, "#include")) {
        //     //     debug.print("Found a line that starts with #include !\n", .{});
        //     // }

        //     //debug.print("All of line is {s}\n", .{line[0..]});

        //     // var tokens = std.mem.splitScalar(u8, line, '#');
        //     // while (tokens.next()) |token| {
        //     //     debug.print("{s}\n", .{token});
        //     // }

        //     // var tokens = std.mem.tokenizeSequence(u8, line, "#");

        //     // while (tokens.next()) |token| {
        //     //     debug.print("{s}\n", .{token});
        //     // }
        // }

        // var file = try std.fs.openFileAbsolute(real_path, .{});
        // defer file.close();

        // const stat = try file.stat();
        // var buff = try file.readToEndAlloc(allocator, max_bytes: usize)

        // var buf_reader = io.bufferedReader(file.reader());
        // var in_stream = buf_reader.reader();

        // var lines_to_zig = std.ArrayList([]u8).init(allocator);
        // defer lines_to_zig.deinit();

        // var buf: [1024]u8 = undefined;
        // while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        //     debug.print("{s}\n", .{line});
        //     try lines_to_zig.append(line);
        // }
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
