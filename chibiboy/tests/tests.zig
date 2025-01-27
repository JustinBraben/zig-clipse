const std = @import("std");
const testing = std.testing;
const Allocator = std.mem.Allocator;
const Chibiboy = @import("chibiboy");
const GameBoy = Chibiboy.GameBoy;
const Cartridge = Chibiboy.Cartridge;

test "chibiboy test suite" {
    _ = @import("cartridge_test.zig");
}

pub const TestResult = struct {
    passed: bool,
    message: []const u8,
};

pub const BlarggTest = struct {
    // Serial output buffer for test results
    serial_output: std.ArrayList(u8),
    allocator: Allocator,

    pub fn init(allocator: Allocator) !BlarggTest {
        return BlarggTest{
            .serial_output = std.ArrayList(u8).init(allocator),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *BlarggTest) void {
        self.serial_output.deinit();
    }

    // Handle serial output from the test ROM
    pub fn handleSerialOutput(self: *BlarggTest, byte: u8) !void {
        try self.serial_output.append(byte);
    }

    // Check if test has completed
    pub fn isTestComplete(self: *const BlarggTest) bool {
        const output = self.serial_output.items;
        return std.mem.indexOf(u8, output, "Passed") != null or
                std.mem.indexOf(u8, output, "Failed") != null;
    }

    // Get the test result
    pub fn getResult(self: *const BlarggTest) TestResult {
        const output = self.serial_output.items;
        const passed = std.mem.indexOf(u8, output, "Passed") != null;
        return TestResult{
            .passed = passed,
            .message = output,
        };
    }
};

// Example usage in your emulator:
pub fn runBlarggTest(allocator: Allocator, rom_path: []const u8) !TestResult {
    var blargg_test = try BlarggTest.init(allocator);
    defer blargg_test.deinit();

    // Initialize your emulator here
    var emu = try GameBoy.init(allocator);
    defer emu.deinit();

    // Load the test ROM
    try emu.loadROM(rom_path);

    // Run the emulator until the test completes
    while (!blargg_test.isTestComplete()) {
        try emu.step();
        
        // If there's serial output, handle it
        if (emu.hasSerialOutput()) {
            const byte = emu.readSerial();
            try blargg_test.handleSerialOutput(byte);
        }
    }

    return blargg_test.getResult();
}