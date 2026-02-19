const std = @import("std");
const builtin = @import("builtin");
const tty = std.io.tty;

// Ansi escape codes
const RED = "\x1b[31;1m";
const GREEN = "\x1b[32;1m";
const CYAN = "\x1b[36;1m";
const WHITE = "\x1b[37;1m";
const BOLD = "\x1b[1m";
const DIM = "\x1b[2m";
const RESET = "\x1b[0m";

pub fn main() !void {
    var stdout_buf: [1024]u8 = undefined;
    var stdout_file = std.fs.File.stdout();
    var stdout_writer = stdout_file.writer(&stdout_buf);
    const out: *std.io.Writer = &stdout_writer.interface;

    const config: tty.Config = .detect(stdout_file);

    for (builtin.test_functions) |t| {
        const start = std.time.milliTimestamp();
        std.testing.allocator_instance = .{};
        const result = t.func();
        const elapsed = std.time.milliTimestamp() - start;

        const name = extractName(t);

        if (result) |_| {
            try config.setColor(out, .green);
            try out.print("{s} passed - ({d}ms)\n", .{name, elapsed});
            try config.setColor(out, .bright_yellow);
        } else |err| {
            try config.setColor(out, .red);
            try out.print("{s} failed - {}\n", .{name, err});
            try config.setColor(out, .bright_yellow);
        }

        if (std.testing.allocator_instance.deinit() == .leak) {
            try config.setColor(out, .red);
            try out.print("{s} leaked memory\n", .{name});
            try config.setColor(out, .bright_yellow);
        }
    }

    try out.flush();
}

fn extractName(t: std.builtin.TestFn) []const u8 {
    const marker = std.mem.lastIndexOf(u8, t.name, ".test.") orelse return t.name;
    return t.name[marker+6..];
}