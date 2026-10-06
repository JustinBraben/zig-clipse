const std = @import("std");
const CPU = @import("cpu.zig").CPU;
const consts = @import("consts.zig");

/// The Game Boy timer. `Emu.step` calls `tick` with the T-cycles of every instruction.
///
/// Registers (all live in `cpu.ram.data`):
///   DIV  (0xFF04) increments at 16384 Hz, i.e. once every 256 T-cycles.
///                 Any write resets it to 0 (`RAM.set` already does that; reset
///                 `div_counter` too if you track it here).
///   TIMA (0xFF05) increments at the rate selected by TAC, when TAC bit 2 is set.
///                 When it overflows past 0xFF it is reloaded from TMA and a timer
///                 interrupt is requested: `self.cpu.interrupt(consts.Interrupt.TIMER)`.
///   TMA  (0xFF06) the reload value for TIMA.
///   TAC  (0xFF07) bit 2 = enable, bits 0-1 = rate:
///                 00 = 4096 Hz (every 1024 T-cycles), 01 = 262144 Hz (every 16),
///                 10 = 65536 Hz (every 64),           11 = 16384 Hz (every 256).
///
/// 02-interrupts only needs this level of accuracy; the exact DIV-bit falling-edge
/// behaviour matters for later timing tests, not for cpu_instrs.
pub const Timer = struct {
    cpu: *CPU,
    div_counter: u16 = 0,
    tima_counter: u16 = 0,

    pub fn init(cpu: *CPU) Timer {
        return .{ .cpu = cpu };
    }

    pub fn tick(self: *Timer, cycles: u8) void {
        // TODO(you): advance DIV and TIMA as described above.
        _ = self;
        _ = cycles;
    }
};
