const std = @import("std");
const Chibiboy = @import("chibiboy");
const build_options = @import("build_options");
const Emu = Chibiboy.Emu;

/// Plenty for any single cpu_instrs ROM (the slowest takes ~30s of emulated time).
const MAX_CYCLES_SINGLE: u64 = 300_000_000;
/// The combined ROM runs all 11 sub-tests back to back.
const MAX_CYCLES_ALL: u64 = 1_000_000_000;

fn runRom(rom: []const u8, max_cycles: u64) !void {
    const allocator = std.testing.allocator;
    const path = try std.fs.path.join(allocator, &.{ build_options.roms_dir, "instr_timing", rom });
    defer allocator.free(path);

    const emu = try Emu.create(allocator, std.testing.io, path, .{});
    defer emu.destroy();

    const result = try emu.runUntilSerialResult(max_cycles);
    if (!result.passed) {
        std.debug.print("\n--- serial output ---\n{s}\n---------------------\n", .{result.output});
        return error.TestFailed;
    }
}

test "instr_timing" {
    try runRom("instr_timing.gb", MAX_CYCLES_SINGLE);
}