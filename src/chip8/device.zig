const std = @import("std");

const DEFAULT_FONT = [80]u8{
    0xF0, 0x90, 0x90, 0x90, 0xF0, // 0
    0x20, 0x60, 0x20, 0x20, 0x70, // 1
    0xF0, 0x10, 0xF0, 0x80, 0xF0, // 2
    0xF0, 0x10, 0xF0, 0x10, 0xF0, // 3
    0x90, 0x90, 0xF0, 0x10, 0x10, // 4
    0xF0, 0x80, 0xF0, 0x10, 0xF0, // 5
    0xF0, 0x80, 0xF0, 0x90, 0xF0, // 6
    0xF0, 0x10, 0x20, 0x40, 0x40, // 7
    0xF0, 0x90, 0xF0, 0x90, 0xF0, // 8
    0xF0, 0x90, 0xF0, 0x10, 0xF0, // 9
    0xF0, 0x90, 0xF0, 0x90, 0x90, // A
    0xE0, 0x90, 0xE0, 0x90, 0xE0, // B
    0xF0, 0x80, 0x80, 0x80, 0xF0, // C
    0xE0, 0x90, 0x90, 0x90, 0xE0, // D
    0xF0, 0x80, 0xF0, 0x80, 0xF0, // E
    0xF0, 0x80, 0xF0, 0x80, 0x80, // F
};

pub const Device = struct {
    const Self = @This();

    allocator: std.mem.Allocator,
    memory: []u8, // RAM memory for emulator

    /// Create the device
    pub fn init(allocator: std.mem.Allocator) !Self {
        var memory = try allocator.alloc(u8, 4096);
        @memcpy(memory[0x000..0x050], DEFAULT_FONT[0..80]);

        return Self{
            .allocator = allocator,
            .memory = memory,
        };
    }

    /// Free the device
    pub fn deinit(self: *Self) void {
        self.allocator.free(self.memory);
    }

    /// Load raw ROM data into memory
    pub fn loadProgramIntoMemory(self: *Self, program: []u8) void {
        @memcpy(self.memory[0x200 .. 0x200 + program.len], program[0..program.len]);
    }

    /// Load the ROM data from a file
    pub fn loadROM(self: *Self, path: []const u8) bool {
        const file = std.fs.cwd().openFile(path, .{}) catch return false;
        defer file.close();

        const stat = file.stat() catch return false;
        if (stat.size > self.memory.len - 0x200) return false;

        const buffer = self.allocator.alloc(u8, stat.size) catch return false;
        defer self.allocator.free(buffer);

        file.reader().readNoEof(buffer) catch return false;

        self.loadProgramIntoMemory(buffer);

        return true;
    }
};
