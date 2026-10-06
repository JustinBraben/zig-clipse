const std = @import("std");
const Cartridge = @import("cartridge.zig").Cartridge;
const RAM = @import("ram.zig").RAM;
const CPU = @import("cpu.zig").CPU;
const GPU = @import("gpu.zig").GPU;
const Timer = @import("timer.zig").Timer;
const consts = @import("consts.zig");

const print = std.debug.print;

const CLOCK_HZ: u64 = 4_194_304;
const CYCLES_PER_FRAME: u64 = 70_224;

pub const EmuContext = struct {
    paused: bool = false,
    running: bool = true,
    ticks: u64 = 0,
};

pub const Options = struct {
    debug_cpu: bool = false,
    debug_ram: bool = false,
};

pub const RunLimits = struct {
    /// Stop after this many frames' worth of cycles (0 = no limit).
    frames: u32 = 0,
    /// Stop after this many seconds of emulated time (0 = no limit).
    profile: u32 = 0,
};

pub const TestResult = struct {
    passed: bool,
    /// Everything the ROM printed over serial. Owned by the Emu.
    output: []const u8,
};

/// Blargg test ROMs print "Passed" or "Failed" over serial when they finish.
fn blarggResult(serial: []const u8) ?bool {
    if (std.mem.indexOf(u8, serial, "Passed") != null) return true;
    if (std.mem.indexOf(u8, serial, "Failed") != null) return false;
    return null;
}

pub const Emu = struct {
    allocator: std.mem.Allocator,

    ctx: EmuContext = .{},
    cycles: u64 = 0,

    cartridge: Cartridge,
    ram: RAM,
    cpu: CPU,
    timer: Timer,

    /// Heap-allocated so the internal pointers (ram -> cartridge, cpu -> ram, ...) stay valid.
    pub fn create(allocator: std.mem.Allocator, io: std.Io, rom_path: []const u8, opts: Options) !*Emu {
        const self = try allocator.create(Emu);
        errdefer allocator.destroy(self);

        self.* = .{
            .allocator = allocator,
            .cartridge = try Cartridge.init(allocator, io, rom_path),
            .ram = undefined,
            .cpu = undefined,
            .timer = undefined,
        };
        self.ram = RAM.init(allocator, &self.cartridge, opts.debug_ram);
        self.cpu = CPU.init(&self.ram, opts.debug_cpu);
        self.timer = Timer.init(&self.cpu);

        // No PPU yet: park LY at the start of vblank so ROMs waiting for it don't stall.
        self.ram.data[consts.Mem.LY] = 0x90;

        return self;
    }

    pub fn destroy(self: *Emu) void {
        self.ram.deinit();
        self.cartridge.deinit();
        self.allocator.destroy(self);
    }

    /// Run one CPU instruction and advance the rest of the hardware by the same cycles.
    pub fn step(self: *Emu) !u8 {
        const cycles = try self.cpu.step();
        self.timer.tick(cycles);
        self.cycles += cycles;
        return cycles;
    }

    /// Run until a limit is hit or a test ROM reports a result, echoing serial output.
    pub fn run(self: *Emu, limits: RunLimits) !void {
        var max_cycles: u64 = std.math.maxInt(u64);
        if (limits.frames > 0) max_cycles = limits.frames * CYCLES_PER_FRAME;
        if (limits.profile > 0) max_cycles = @min(max_cycles, limits.profile * CLOCK_HZ);

        var printed: usize = 0;
        while (self.ctx.running and self.cycles < max_cycles) {
            _ = try self.step();

            const serial = self.ram.serial.items;
            if (serial.len != printed) {
                print("{s}", .{serial[printed..]});
                printed = serial.len;
                if (blarggResult(serial) != null) self.ctx.running = false;
            }
        }
    }

    /// Run a blargg test ROM until it reports Passed/Failed, or `max_cycles` elapse.
    pub fn runUntilSerialResult(self: *Emu, max_cycles: u64) !TestResult {
        var checked: usize = 0;
        while (self.cycles < max_cycles) {
            _ = try self.step();

            const serial = self.ram.serial.items;
            if (serial.len != checked) {
                checked = serial.len;
                if (blarggResult(serial)) |passed| return .{ .passed = passed, .output = serial };
            }
        }
        return .{ .passed = false, .output = self.ram.serial.items };
    }
};
