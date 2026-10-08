const std = @import("std");
const testing = std.testing;
const Chibiboy = @import("chibiboy");
const CPU = Chibiboy.CPU;
const RAM = Chibiboy.RAM;
const Cartridge = Chibiboy.Cartridge;
const Mem = Chibiboy.consts.Mem;
const Interrupt = Chibiboy.consts.Interrupt;

/// Programs run from work RAM, so the cartridge is never touched.
const CODE_START: u16 = 0xC000;

/// A CPU + RAM with no cartridge, for testing small hand-written programs.
/// Heap-allocated because RAM is 64KB and `cpu.ram` / `ram.cart` are pointers into it.
const Machine = struct {
    /// Never read: `RAM` only uses the cartridge for 0x0000-0x7FFF and 0xA000-0xBFFF,
    /// and these tests stay out of both.
    cart: Cartridge = undefined,
    ram: RAM,
    cpu: CPU,

    fn create(code: []const u8) !*Machine {
        const self = try testing.allocator.create(Machine);
        self.* = .{ .ram = undefined, .cpu = undefined };
        self.ram = RAM.init(testing.allocator, &self.cart, false);
        self.cpu = CPU.init(&self.ram, false);

        @memcpy(self.ram.data[CODE_START..][0..code.len], code);
        self.ram.data[Mem.BOOT] = 1; // boot ROM off
        self.cpu.PC = CODE_START;
        self.cpu.SP = 0xDFFE;
        return self;
    }

    fn destroy(self: *Machine) void {
        self.ram.deinit();
        testing.allocator.destroy(self);
    }

    fn step(self: *Machine, n: usize) !void {
        for (0..n) |_| _ = try self.cpu.step();
    }

    /// Mark an interrupt as both enabled (IE) and requested (IF).
    fn requestInterrupt(self: *Machine, flag: u8) void {
        self.ram.data[Mem.IE] |= flag;
        self.ram.data[Mem.IF] |= flag;
    }

    fn peek16(self: *Machine, addr: u16) u16 {
        return @as(u16, self.ram.data[addr +% 1]) << 8 | self.ram.data[addr];
    }
};

// ---- the halt bug: IME=0 and an interrupt already pending ----

test "halt bug: operand fetch re-reads the opcode byte" {
    // HALT; LD A,$14
    const m = try Machine.create(&.{ 0x76, 0x3E, 0x14 });
    defer m.destroy();
    m.cpu.ime = false;
    m.requestInterrupt(Interrupt.VBLANK);

    try m.step(2); // HALT, then LD A,d8 with the bugged fetch

    // The opcode fetch didn't advance PC, so the operand read got 0x3E, not 0x14.
    try testing.expectEqual(@as(u8, 0x3E), m.cpu.registers.R8.A);
    // PC now points at the 0x14 byte, which will run next as INC D.
    try testing.expectEqual(@as(u16, CODE_START + 2), m.cpu.PC);
    try testing.expect(!m.cpu.halted);
}

test "halt bug: a 1-byte instruction runs twice" {
    // HALT; INC A; NOP
    const m = try Machine.create(&.{ 0x76, 0x3C, 0x00 });
    defer m.destroy();
    m.cpu.ime = false;
    m.cpu.registers.R8.A = 0;
    m.requestInterrupt(Interrupt.VBLANK);

    try m.step(3); // HALT, INC A (bugged), INC A (again)

    try testing.expectEqual(@as(u8, 2), m.cpu.registers.R8.A);
    try testing.expectEqual(@as(u16, CODE_START + 2), m.cpu.PC);
}

test "halt bug: CALL reads its address from the wrong bytes" {
    // HALT; CALL $D000
    const m = try Machine.create(&.{ 0x76, 0xCD, 0x00, 0xD0 });
    defer m.destroy();
    m.cpu.ime = false;
    m.requestInterrupt(Interrupt.VBLANK);

    try m.step(2); // HALT, then CALL a16 with the bugged fetch

    // Address bytes are read from C001 (0xCD) and C002 (0x00): the call goes to $00CD.
    try testing.expectEqual(@as(u16, 0x00CD), m.cpu.PC);
    // The pushed return address is just past those two bytes.
    try testing.expectEqual(@as(u16, 0xDFFC), m.cpu.SP);
    try testing.expectEqual(@as(u16, CODE_START + 3), m.peek16(m.cpu.SP));
}

// ---- normal HALT behaviour (must keep working after the fix) ----

test "halt: IME=0, nothing pending -> halts, then wakes without servicing" {
    // HALT; LD A,$14
    const m = try Machine.create(&.{ 0x76, 0x3E, 0x14 });
    defer m.destroy();
    m.cpu.ime = false;

    try m.step(1); // HALT
    try testing.expect(m.cpu.halted);

    try m.step(3); // nothing pending: stays halted
    try testing.expect(m.cpu.halted);
    try testing.expectEqual(@as(u16, CODE_START + 1), m.cpu.PC);

    m.requestInterrupt(Interrupt.TIMER);
    try m.step(1); // wakes; IME=0 so no handler, just runs LD A,$14 normally

    try testing.expect(!m.cpu.halted);
    try testing.expectEqual(@as(u8, 0x14), m.cpu.registers.R8.A);
    try testing.expectEqual(@as(u16, CODE_START + 3), m.cpu.PC);
}

test "halt: IME=1 -> halts, then services the interrupt" {
    // HALT; NOP
    const m = try Machine.create(&.{ 0x76, 0x00 });
    defer m.destroy();
    m.cpu.ime = true;

    try m.step(1); // HALT
    try testing.expect(m.cpu.halted);

    m.requestInterrupt(Interrupt.TIMER);
    try m.step(1); // wakes and jumps to the timer handler

    try testing.expect(!m.cpu.halted);
    try testing.expect(!m.cpu.ime);
    try testing.expectEqual(Mem.TimerHandler, m.cpu.PC);
    // Returns to the instruction after HALT.
    try testing.expectEqual(@as(u16, CODE_START + 1), m.peek16(m.cpu.SP));
}
