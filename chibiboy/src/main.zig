const std = @import("std");
const debug = std.debug;
const io = std.io;
const builtin = std.builtin;

const Args = @import("args.zig").Args;
const clap = @import("clap");
const Emu = @import("emu.zig").Emu;
const errors = @import("errors.zig");

const c = @import("clibs.zig");

const print = std.debug.print;

pub fn main() !void {
    var gpa_impl = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa_impl.deinit();
    const gpa = gpa_impl.allocator();

    var args = try Args.parse_args(gpa);
    defer args.deinit();

    print("args.rom: {s}\n", .{args.rom});

    var emu = try Emu.init(gpa, args);
    defer emu.deinit();

    print("emu.cartridge.name: {s} , len: {d}\n", .{emu.cartridge.name, emu.cartridge.name.len});

    try emu.run();
}
