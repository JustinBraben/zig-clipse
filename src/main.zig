const std = @import("std");
const Display = @import("chip8/display.zig").Display;
const BitMap = @import("chip8/bitmap.zig").Bitmap;
const assert = std.debug.assert;

const User = @import("clipse/data_structures/user.zig").User;
const Args = @import("clipse/args.zig").Args;
const print = std.debug.print;

const testing = std.testing;

pub fn main() !void {
    var gpa_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.testing.expect(gpa_allocator.deinit() != .leak) catch @panic("memory leak");
    const gpa = gpa_allocator.allocator();

    var parse_args = try Args.init(gpa);
    defer parse_args.deinit();

    while (parse_args.args_allocated.next()) |arg| {
        print("arg : {s}\n", .{arg});
    }

    var bitmap = try BitMap.init(gpa, 64, 32);
    defer bitmap.deinit();

    var display = try Display.init("CHIP-8", 800, 400);
    defer display.deinit();

    while (display.open) {
        display.input();
    }
}
