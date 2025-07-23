const std = @import("std");
const Args = @import("args.zig").Args;
const Cartridge = @import("cartridge.zig").Cartridge;
const RAM = @import("ram.zig").RAM;
const CPU = @import("cpu.zig").CPU;
const GPU = @import("gpu.zig").GPU;

const print = std.debug.print;

pub const EmuContext = struct {
    paused: bool = false,
    running: bool = true,
    ticks: u64 = 0,
};

pub const Emu = struct {
    allocator: std.mem.Allocator,

    ctx: EmuContext = .{},

    cartridge: Cartridge,
    ram: RAM,
    cpu: CPU,

    pub fn init(allocator: std.mem.Allocator, args: Args) !Emu {
        var cartridge = try Cartridge.init(allocator, args.rom);
        var ram = RAM.init(&cartridge, args.debug_ram);
        const cpu = CPU.init(&ram, args.debug_cpu);
        return Emu{
            .allocator = allocator,
            .cartridge = cartridge,
            .ram = ram,
            .cpu = cpu,
        };
    }

    pub fn deinit(self: *Emu) void {
        print("Emu deinit called\n", .{});
        self.cartridge.deinit();
    }

    pub fn run(self: *Emu) !void {
        print("Emu is now running\n", .{});
        while (true) {
            try self.tick();
        }
    }

    pub fn tick(self: *Emu) !void {
        try self.cpu.tick();
    }
};
