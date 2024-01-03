const std = @import("std");
const Display = @import("chip8/display.zig").Display;
const BitMap = @import("chip8/bitmap.zig").Bitmap;
const Device = @import("chip8/device.zig").Device;
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

    var device = try Device.init(gpa);
    defer device.deinit();

    if (!device.loadROM("./roms/blitz.rom")) {
        std.debug.print("Failed to load CHIP-8 ROM\n", .{});
        return;
    }

    var bitmap = try BitMap.init(gpa, 64, 32);
    defer bitmap.deinit();
    _ = bitmap.setPixel(5, 5);

    var display = try Display.init("CHIP-8", 800, 400, bitmap.width, bitmap.height);
    defer display.deinit();

    while (display.open) {
        display.input();
        display.draw(&bitmap);
    }
}
