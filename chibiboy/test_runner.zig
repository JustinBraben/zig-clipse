const std = @import("std");
const builtin = @import("builtin");
const Terminal = std.Io.Terminal;

// Ansi escape codes
const RED = "\x1b[31;1m";
const GREEN = "\x1b[32;1m";
const CYAN = "\x1b[36;1m";
const WHITE = "\x1b[37;1m";
const BOLD = "\x1b[1m";
const DIM = "\x1b[2m";
const RESET = "\x1b[0m";

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    var stdout_buf: [1024]u8 = undefined;
    const stdout_file = std.Io.File.stdout();
    var stdout_writer = stdout_file.writer(io, &stdout_buf);
    const out: *std.Io.Writer = &stdout_writer.interface;

    const term: Terminal = .{ .writer = out, .mode = try .detect(io, stdout_file, false, false) };

    for (builtin.test_functions) |t| {
        const start = std.Io.Clock.awake.now(io);
        std.testing.allocator_instance = .{};
        std.testing.io_instance = .init(std.testing.allocator, .{});
        const result = t.func();
        const elapsed = start.untilNow(io, .awake).toMilliseconds();
        std.testing.io_instance.deinit();

        const name = extractName(t);

        if (result) |_| {
            try term.setColor(.green);
            try out.print("{s} passed - ({d}ms)\n", .{name, elapsed});
            try term.setColor(.bright_yellow);
        } else |err| {
            try term.setColor(.red);
            try out.print("{s} failed - {}\n", .{name, err});
            try term.setColor(.bright_yellow);
        }

        if (std.testing.allocator_instance.deinit() == .leak) {
            try term.setColor(.red);
            try out.print("{s} leaked memory\n", .{name});
            try term.setColor(.bright_yellow);
        }
    }

    try out.flush();
}

fn extractName(t: std.builtin.TestFn) []const u8 {
    const marker = std.mem.lastIndexOf(u8, t.name, ".test.") orelse return t.name;
    return t.name[marker+6..];
}