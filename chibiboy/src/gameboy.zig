const std = @import("std");
const Cartridge = @import("cartridge.zig").Cartridge;
const Args = @import("args.zig").Args;

const print = std.debug.print;

pub const GameBoy = struct {
    allocator: std.mem.Allocator,

    cartridge: Cartridge,

    pub fn init(allocator: std.mem.Allocator, args: Args) !GameBoy {
        return GameBoy{
            .allocator = allocator,
            .cartridge = try Cartridge.init(allocator, args.rom),
        };
    }

    pub fn deinit(self: *GameBoy) void {
        self.cartridge.deinit();
    }

    pub fn run(self: *GameBoy) !void {
        _ = self; // autofix
        print("GameBoy is now running\n", .{});
    }

    pub fn tick(self: *GameBoy) !void {
        _ = self; // autofix
    }
};
