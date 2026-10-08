test "chibiboy test suite" {
    _ = @import("cartridge_test.zig");
    _ = @import("cpu_instrs_test.zig");
    _ = @import("instr_timing_test.zig");
}
