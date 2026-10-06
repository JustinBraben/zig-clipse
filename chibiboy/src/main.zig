const std = @import("std");
const debug = std.debug;
const builtin = std.builtin;

const Args = @import("args.zig").Args;
const clap = @import("clap");
const Emu = @import("emu.zig").Emu;
const errors = @import("errors.zig");

const print = std.debug.print;

pub fn main(init: std.process.Init) !void {
    const gpa = init.gpa;
    const io = init.io;

    var args = try Args.parse_args(gpa, io, init.minimal.args);
    defer args.deinit();

    print("args.rom: {s}\n", .{args.rom});

    const emu = try Emu.create(gpa, io, args.rom, .{
        .debug_cpu = args.debug_cpu,
        .debug_ram = args.debug_ram,
    });
    defer emu.destroy();

    print("emu.cartridge.name: {s} , len: {d}\n", .{emu.cartridge.name, emu.cartridge.name.len});

    try emu.run(.{ .frames = args.frames, .profile = args.profile });
}
