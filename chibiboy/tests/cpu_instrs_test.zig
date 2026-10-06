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
    const path = try std.fs.path.join(allocator, &.{ build_options.roms_dir, "cpu_instrs", rom });
    defer allocator.free(path);

    const emu = try Emu.create(allocator, std.testing.io, path, .{});
    defer emu.destroy();

    const result = try emu.runUntilSerialResult(max_cycles);
    if (!result.passed) {
        std.debug.print("\n--- serial output ---\n{s}\n---------------------\n", .{result.output});
        return error.TestFailed;
    }
}

test "01-special" {
    try runRom("individual/01-special.gb", MAX_CYCLES_SINGLE);
}

test "02-interrupts" {
    try runRom("individual/02-interrupts.gb", MAX_CYCLES_SINGLE);
}

test "03-op sp,hl" {
    try runRom("individual/03-op sp,hl.gb", MAX_CYCLES_SINGLE);
}

test "04-op r,imm" {
    try runRom("individual/04-op r,imm.gb", MAX_CYCLES_SINGLE);
}

test "05-op rp" {
    try runRom("individual/05-op rp.gb", MAX_CYCLES_SINGLE);
}

test "06-ld r,r" {
    try runRom("individual/06-ld r,r.gb", MAX_CYCLES_SINGLE);
}

test "07-jr,jp,call,ret,rst" {
    try runRom("individual/07-jr,jp,call,ret,rst.gb", MAX_CYCLES_SINGLE);
}

test "08-misc instrs" {
    try runRom("individual/08-misc instrs.gb", MAX_CYCLES_SINGLE);
}

test "09-op r,r" {
    try runRom("individual/09-op r,r.gb", MAX_CYCLES_SINGLE);
}

test "10-bit ops" {
    try runRom("individual/10-bit ops.gb", MAX_CYCLES_SINGLE);
}

test "11-op a,(hl)" {
    try runRom("individual/11-op a,(hl).gb", MAX_CYCLES_SINGLE);
}

test "cpu_instrs (all)" {
    try runRom("cpu_instrs.gb", MAX_CYCLES_ALL);
}
