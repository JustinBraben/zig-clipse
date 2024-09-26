const std = @import("std");
const debug = std.debug;
const io = std.io;
const builtin = std.builtin;

const Args = @import("args.zig").Args;
const clap = @import("clap");
const GameBoy = @import("gameboy.zig").GameBoy;
const errors = @import("errors.zig");

const c = @import("clibs.zig");

const print = std.debug.print;

pub fn main() !void {
    var gpa_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.testing.expect(gpa_allocator.deinit() != .leak) catch @panic("memory leak");
    const gpa = gpa_allocator.allocator();

    var args = try Args.parse_args(gpa);
    defer args.deinit();

    print("args.rom: {s}\n", .{args.rom});

    var gameboy = try GameBoy.init(gpa, args);
    defer gameboy.deinit();

    print("gameboy.cartridge.name: {s}, len: {d}\n", .{gameboy.cartridge.name, gameboy.cartridge.name.len});
}
