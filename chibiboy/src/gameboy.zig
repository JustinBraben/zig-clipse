const std = @import("std");
const Args = @import("args.zig").Args;
const Cartridge = @import("cartridge.zig").Cartridge;
const RAM = @import("ram.zig").RAM;
const CPU = @import("cpu.zig").CPU;
const GPU = @import("gpu.zig").GPU;

const print = std.debug.print;

pub const GameBoy = struct {
    allocator: std.mem.Allocator,

    cartridge: Cartridge,
    ram: RAM,
    cpu: CPU,

    pub fn init(allocator: std.mem.Allocator, args: Args) !GameBoy {
        var cartridge = try Cartridge.init(allocator, args.rom);
        var ram = RAM.init(&cartridge, args.debug_ram);
        const cpu = CPU.init(&ram, args.debug_cpu);
        return GameBoy{
            .allocator = allocator,
            .cartridge = cartridge,
            .ram = ram,
            .cpu = cpu,
        };
    }

    pub fn deinit(self: *GameBoy) void {
        self.cartridge.deinit();
    }

    pub fn run(self: *GameBoy) !void {
        print("GameBoy is now running\n", .{});
        while (true) {
            try self.tick();
        }
    }

    pub fn tick(self: *GameBoy) !void {
        try self.cpu.tick();
    }
};
