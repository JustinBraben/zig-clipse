const std = @import("std");
const Args = @import("args.zig").Args;
const GameBoy = @import("gameboy.zig").GameBoy;

const c = @import("clibs.zig");

const print = std.debug.print;

pub fn main() !void {
    print("\n", .{});

    var gpa_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.testing.expect(gpa_allocator.deinit() != .leak) catch @panic("memory leak");
    const gpa = gpa_allocator.allocator();

    var parse_args = try Args.init(gpa);
    defer parse_args.deinit();
    // print("Rom arg : {s}\n", .{parse_args.rom});

    // var gameboy: GameBoy = undefined;
    // gameboy = try GameBoy.init(gpa, parse_args);
    // defer gameboy.deinit();
}
