const std = @import("std");
const Display = @import("display.zig").Display;
const BitMap = @import("bitmap.zig").Bitmap;
const Device = @import("device.zig").Device;
const CPU = @import("cpu.zig").CPU;
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

    if (!device.loadROM("./roms/breakout.rom")) {
        std.debug.print("Failed to load CHIP-8 ROM\n", .{});
        return;
    }

    var bitmap = try BitMap.init(gpa, 64, 32);
    defer bitmap.deinit();

    var display = try Display.init("CHIP-8", 800, 400, bitmap.width, bitmap.height);
    defer display.deinit();

    // CPU does not allocate any memory, so no deinit is needed
    var cpu = CPU.init(&device.memory, &bitmap, &display);

    const fps: f32 = 60.0;
    const fps_interval = 1000.0 / fps;
    var previous_time = std.time.milliTimestamp();
    var current_time = std.time.milliTimestamp();

    while (display.open) {
        display.input();

        current_time = std.time.milliTimestamp();

        if (@as(f32, @floatFromInt(current_time - previous_time)) > fps_interval) {
            previous_time = current_time;

            cpu.tick();
        }

        display.draw(&bitmap);
    }
}
