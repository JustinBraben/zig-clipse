const std = @import("std");
const RAM = @import("ram.zig").RAM;
const consts = @import("consts.zig");
const errors = @import("errors.zig");

const print = std.debug.print;

/// Base T-cycle cost of each opcode, with conditional branches *not* taken.
/// Taken branches add extra cycles in `execute`; CB-prefixed ops are costed in `cb`.
const OP_CYCLES = [256]u8{
    // 0  1   2   3   4   5   6   7   8   9   A   B   C   D   E   F
    4, 12, 8, 8, 4, 4, 8, 4, 20, 8, 8, 8, 4, 4, 8, 4, // 0
    4, 12, 8, 8, 4, 4, 8, 4, 12, 8, 8, 8, 4, 4, 8, 4, // 1
    8, 12, 8, 8, 4, 4, 8, 4, 8, 8, 8, 8, 4, 4, 8, 4, // 2
    8, 12, 8, 8, 12, 12, 12, 4, 8, 8, 8, 8, 4, 4, 8, 4, // 3
    4, 4, 4, 4, 4, 4, 8, 4, 4, 4, 4, 4, 4, 4, 8, 4, // 4
    4, 4, 4, 4, 4, 4, 8, 4, 4, 4, 4, 4, 4, 4, 8, 4, // 5
    4, 4, 4, 4, 4, 4, 8, 4, 4, 4, 4, 4, 4, 4, 8, 4, // 6
    8, 8, 8, 8, 8, 8, 4, 8, 4, 4, 4, 4, 4, 4, 8, 4, // 7
    4, 4, 4, 4, 4, 4, 8, 4, 4, 4, 4, 4, 4, 4, 8, 4, // 8
    4, 4, 4, 4, 4, 4, 8, 4, 4, 4, 4, 4, 4, 4, 8, 4, // 9
    4, 4, 4, 4, 4, 4, 8, 4, 4, 4, 4, 4, 4, 4, 8, 4, // A
    4, 4, 4, 4, 4, 4, 8, 4, 4, 4, 4, 4, 4, 4, 8, 4, // B
    8, 12, 12, 16, 12, 16, 8, 16, 8, 16, 12, 4, 12, 24, 8, 16, // C
    8, 12, 12, 0, 12, 16, 8, 16, 8, 16, 12, 0, 12, 0, 8, 16, // D
    12, 12, 8, 0, 0, 16, 8, 16, 16, 4, 16, 0, 0, 0, 8, 16, // E
    12, 12, 8, 4, 0, 16, 8, 16, 12, 8, 16, 4, 0, 0, 8, 16, // F
};

pub const CPU = struct {
    debug: bool,
    registers: packed union {
        R16: packed struct {
            AF: u16,
            BC: u16,
            DE: u16,
            HL: u16,
        },
        R8: packed struct {
            F: u8,
            A: u8,
            C: u8,
            B: u8,
            E: u8,
            D: u8,
            L: u8,
            H: u8,
        },
        flags: packed struct {
            _p1: u4,
            c: bool,
            h: bool,
            n: bool,
            z: bool,
            _p2: u56,
        },
    },
    SP: u16,
    PC: u16,
    ram: *RAM,

    /// Interrupt master enable.
    ime: bool = false,
    /// Set by EI: IME turns on after the instruction *following* EI.
    ime_pending: bool = false,
    /// Set by HALT: the CPU idles until an enabled interrupt is requested.
    halted: bool = false,
    /// Set by STOP (read by the GPU). Not used by the CPU yet.
    stop: bool = false,

    pub fn init(ram: *RAM, debug_cpu: bool) CPU {
        return .{
            .debug = debug_cpu,
            .registers = .{
                .R16 = .{
                    .AF = 0,
                    .BC = 0,
                    .DE = 0,
                    .HL = 0,
                },
            },
            .SP = 0,
            .PC = 0,
            .ram = ram
        };
    }

    /// Request an interrupt by setting its bit in IF (see `consts.Interrupt`).
    pub fn interrupt(self: *CPU, flag: u8) void {
        self.ram.data[consts.Mem.IF] |= flag;
    }

    /// Run one instruction (or service one interrupt). Returns the T-cycles it took.
    pub fn step(self: *CPU) errors.GameException!u8 {
        const pending = self.ram.data[consts.Mem.IE] & self.ram.data[consts.Mem.IF] & 0x1F;
        if (pending != 0) {
            self.halted = false;
            if (self.ime) return self.serviceInterrupt(pending);
        }
        if (self.halted) return 4;

        const enable_ime = self.ime_pending;
        if (self.debug) self.trace();

        const op = self.fetch8();
        const cycles = try self.execute(op);

        // EI takes effect after the next instruction, unless that instruction was DI.
        if (enable_ime and self.ime_pending) {
            self.ime = true;
            self.ime_pending = false;
        }
        return cycles;
    }

    fn serviceInterrupt(self: *CPU, pending: u8) u8 {
        const bit: u3 = @intCast(@ctz(pending));
        self.ram.data[consts.Mem.IF] &= ~(@as(u8, 1) << bit);
        self.ime = false;
        self.push(self.PC);
        self.PC = consts.Mem.VBlankHandler + @as(u16, bit) * 8;
        return 20;
    }

    /// Gameboy Doctor format: https://github.com/robert/gameboy-doctor
    fn trace(self: *CPU) void {
        const r = self.registers.R8;
        print("A:{X:0>2} F:{X:0>2} B:{X:0>2} C:{X:0>2} D:{X:0>2} E:{X:0>2} H:{X:0>2} L:{X:0>2} SP:{X:0>4} PC:{X:0>4} PCMEM:{X:0>2},{X:0>2},{X:0>2},{X:0>2}\n", .{
            r.A,                         r.F,                         r.B,                         r.C,
            r.D,                         r.E,                         r.H,                         r.L,
            self.SP,                     self.PC,                     self.ram.get(self.PC),       self.ram.get(self.PC +% 1),
            self.ram.get(self.PC +% 2), self.ram.get(self.PC +% 3),
        });
    }

    fn unimplemented(self: *CPU, op: u8) errors.GameException {
        print("unimplemented opcode 0x{X:0>2} at PC=0x{X:0>4}\n", .{ op, self.PC -% 1 });
        return error.UnimplementedOpcode;
    }

    // ---- memory helpers ----

    fn fetch8(self: *CPU) u8 {
        const val = self.ram.get(self.PC);
        self.PC +%= 1;
        return val;
    }

    fn fetch16(self: *CPU) u16 {
        const lo: u16 = self.fetch8();
        const hi: u16 = self.fetch8();
        return hi << 8 | lo;
    }

    fn push(self: *CPU, val: u16) void {
        self.SP -%= 1;
        self.ram.set(self.SP, @truncate(val >> 8));
        self.SP -%= 1;
        self.ram.set(self.SP, @truncate(val));
    }

    fn pop(self: *CPU) u16 {
        const lo: u16 = self.ram.get(self.SP);
        self.SP +%= 1;
        const hi: u16 = self.ram.get(self.SP);
        self.SP +%= 1;
        return hi << 8 | lo;
    }

    // ---- register helpers ----

    /// 8-bit register by opcode index: B, C, D, E, H, L, (HL), A
    fn getR8(self: *CPU, i: u3) u8 {
        return switch (i) {
            0 => self.registers.R8.B,
            1 => self.registers.R8.C,
            2 => self.registers.R8.D,
            3 => self.registers.R8.E,
            4 => self.registers.R8.H,
            5 => self.registers.R8.L,
            6 => self.ram.get(self.registers.R16.HL),
            7 => self.registers.R8.A,
        };
    }

    fn setR8(self: *CPU, i: u3, val: u8) void {
        switch (i) {
            0 => self.registers.R8.B = val,
            1 => self.registers.R8.C = val,
            2 => self.registers.R8.D = val,
            3 => self.registers.R8.E = val,
            4 => self.registers.R8.H = val,
            5 => self.registers.R8.L = val,
            6 => self.ram.set(self.registers.R16.HL, val),
            7 => self.registers.R8.A = val,
        }
    }

    /// 16-bit register by opcode index: BC, DE, HL, SP
    fn getR16(self: *CPU, i: u2) u16 {
        return switch (i) {
            0 => self.registers.R16.BC,
            1 => self.registers.R16.DE,
            2 => self.registers.R16.HL,
            3 => self.SP,
        };
    }

    fn setR16(self: *CPU, i: u2, val: u16) void {
        switch (i) {
            0 => self.registers.R16.BC = val,
            1 => self.registers.R16.DE = val,
            2 => self.registers.R16.HL = val,
            3 => self.SP = val,
        }
    }

    /// 16-bit register for PUSH/POP: BC, DE, HL, AF
    fn getR16Stack(self: *CPU, i: u2) u16 {
        return if (i == 3) self.registers.R16.AF else self.getR16(i);
    }

    fn setR16Stack(self: *CPU, i: u2, val: u16) void {
        // The low nibble of F always reads as zero
        if (i == 3) self.registers.R16.AF = val & 0xFFF0 else self.setR16(i, val);
    }

    /// Branch condition by opcode index: NZ, Z, NC, C
    fn cond(self: *CPU, i: u2) bool {
        const f = self.registers.flags;
        return switch (i) {
            0 => !f.z,
            1 => f.z,
            2 => !f.c,
            3 => f.c,
        };
    }

    fn setFlags(self: *CPU, z: bool, n: bool, h: bool, c: bool) void {
        self.registers.R8.F = @as(u8, @intFromBool(z)) << 7 |
            @as(u8, @intFromBool(n)) << 6 |
            @as(u8, @intFromBool(h)) << 5 |
            @as(u8, @intFromBool(c)) << 4;
    }

    // ---- ALU ----

    /// ADD, ADC, SUB, SBC, AND, XOR, OR, CP of A with `val`
    fn alu(self: *CPU, op: u3, val: u8) void {
        const a = self.registers.R8.A;
        const carry: u8 = @intFromBool(self.registers.flags.c);
        switch (op) {
            0, 1 => { // ADD, ADC
                const c_in: u8 = if (op == 1) carry else 0;
                const sum = @as(u16, a) + val + c_in;
                const r: u8 = @truncate(sum);
                self.setFlags(r == 0, false, (a & 0xF) + (val & 0xF) + c_in > 0xF, sum > 0xFF);
                self.registers.R8.A = r;
            },
            2, 3, 7 => { // SUB, SBC, CP
                const c_in: u8 = if (op == 3) carry else 0;
                const r = a -% val -% c_in;
                self.setFlags(r == 0, true, (a & 0xF) < (val & 0xF) + c_in, @as(u16, a) < @as(u16, val) + c_in);
                if (op != 7) self.registers.R8.A = r;
            },
            4 => { // AND
                self.registers.R8.A = a & val;
                self.setFlags(self.registers.R8.A == 0, false, true, false);
            },
            5 => { // XOR
                self.registers.R8.A = a ^ val;
                self.setFlags(self.registers.R8.A == 0, false, false, false);
            },
            6 => { // OR
                self.registers.R8.A = a | val;
                self.setFlags(self.registers.R8.A == 0, false, false, false);
            },
        }
    }

    fn inc8(self: *CPU, val: u8) u8 {
        const r = val +% 1;
        self.registers.flags.z = r == 0;
        self.registers.flags.n = false;
        self.registers.flags.h = (val & 0xF) == 0xF;
        return r;
    }

    fn dec8(self: *CPU, val: u8) u8 {
        const r = val -% 1;
        self.registers.flags.z = r == 0;
        self.registers.flags.n = true;
        self.registers.flags.h = (val & 0xF) == 0;
        return r;
    }

    fn addHL(self: *CPU, val: u16) void {
        const hl = self.registers.R16.HL;
        self.registers.flags.n = false;
        self.registers.flags.h = (hl & 0xFFF) + (val & 0xFFF) > 0xFFF;
        self.registers.flags.c = @as(u32, hl) + val > 0xFFFF;
        self.registers.R16.HL = hl +% val;
    }

    /// RLC, RRC, RL, RR, SLA, SRA, SWAP, SRL. Sets all flags (Z from the result).
    fn rotate(self: *CPU, kind: u3, val: u8) u8 {
        const c_in: u8 = @intFromBool(self.registers.flags.c);
        var c_out: u8 = 0;
        const r: u8 = switch (kind) {
            0 => blk: { // RLC
                c_out = val >> 7;
                break :blk val << 1 | c_out;
            },
            1 => blk: { // RRC
                c_out = val & 1;
                break :blk val >> 1 | c_out << 7;
            },
            2 => blk: { // RL
                c_out = val >> 7;
                break :blk val << 1 | c_in;
            },
            3 => blk: { // RR
                c_out = val & 1;
                break :blk val >> 1 | c_in << 7;
            },
            4 => blk: { // SLA
                c_out = val >> 7;
                break :blk val << 1;
            },
            5 => blk: { // SRA
                c_out = val & 1;
                break :blk val >> 1 | (val & 0x80);
            },
            6 => val << 4 | val >> 4, // SWAP
            7 => blk: { // SRL
                c_out = val & 1;
                break :blk val >> 1;
            },
        };
        self.setFlags(r == 0, false, false, c_out != 0);
        return r;
    }

    /// SP + e8, shared by ADD SP,e8 and LD HL,SP+e8. Fetches the immediate, sets flags
    /// (Z=0 N=0, H/C from an *unsigned* add of the byte to SP's low byte) and returns the
    /// result; the caller decides where it goes.
    fn spPlusE8(self: *CPU) u16 {
        const byte = self.fetch8();
        const sp = self.SP;
        self.setFlags(
            false,
            false,
            (sp & 0x0F) + (byte & 0x0F) > 0x0F,
            (sp & 0xFF) + byte > 0xFF,
        );
        // Sign-extend the byte (0xFE -> -2) and do the actual 16-bit add
        const offset: i8 = @bitCast(byte);
        return sp +% @as(u16, @bitCast(@as(i16, offset)));
    }

    // ---- control flow ----

    fn jr(self: *CPU) void {
        const offset: i8 = @bitCast(self.fetch8());
        self.PC +%= @bitCast(@as(i16, offset));
    }

    fn call(self: *CPU, addr: u16) void {
        self.push(self.PC);
        self.PC = addr;
    }

    // ---- decode / execute ----

    fn execute(self: *CPU, op: u8) errors.GameException!u8 {
        const cycles = OP_CYCLES[op];
        // Register indices encoded in the opcode bits: xx yyy zzz
        const y: u3 = @truncate(op >> 3);
        const z: u3 = @truncate(op);
        const p: u2 = @truncate(op >> 4);
        const cc: u2 = @truncate(op >> 3);

        switch (op) {
            0x00 => {}, // NOP
            0x10 => _ = self.fetch8(), // STOP (treated as a 2-byte NOP for now)

            // ---- 8-bit loads ----
            0x40...0x75, 0x77...0x7F => self.setR8(y, self.getR8(z)), // LD r,r'
            0x06, 0x0E, 0x16, 0x1E, 0x26, 0x2E, 0x36, 0x3E => self.setR8(y, self.fetch8()), // LD r,d8
            0x02 => self.ram.set(self.registers.R16.BC, self.registers.R8.A), // LD (BC),A
            0x12 => self.ram.set(self.registers.R16.DE, self.registers.R8.A), // LD (DE),A
            0x22 => { // LD (HL+),A
                self.ram.set(self.registers.R16.HL, self.registers.R8.A);
                self.registers.R16.HL +%= 1;
            },
            0x32 => { // LD (HL-),A
                self.ram.set(self.registers.R16.HL, self.registers.R8.A);
                self.registers.R16.HL -%= 1;
            },
            0x0A => self.registers.R8.A = self.ram.get(self.registers.R16.BC), // LD A,(BC)
            0x1A => self.registers.R8.A = self.ram.get(self.registers.R16.DE), // LD A,(DE)
            0x2A => { // LD A,(HL+)
                self.registers.R8.A = self.ram.get(self.registers.R16.HL);
                self.registers.R16.HL +%= 1;
            },
            0x3A => { // LD A,(HL-)
                self.registers.R8.A = self.ram.get(self.registers.R16.HL);
                self.registers.R16.HL -%= 1;
            },
            0xE0 => self.ram.set(0xFF00 + @as(u16, self.fetch8()), self.registers.R8.A), // LDH (a8),A
            0xF0 => self.registers.R8.A = self.ram.get(0xFF00 + @as(u16, self.fetch8())), // LDH A,(a8)
            0xE2 => self.ram.set(0xFF00 + @as(u16, self.registers.R8.C), self.registers.R8.A), // LD (C),A
            0xF2 => self.registers.R8.A = self.ram.get(0xFF00 + @as(u16, self.registers.R8.C)), // LD A,(C)
            0xEA => self.ram.set(self.fetch16(), self.registers.R8.A), // LD (a16),A
            0xFA => self.registers.R8.A = self.ram.get(self.fetch16()), // LD A,(a16)

            // ---- 16-bit loads ----
            0x01, 0x11, 0x21, 0x31 => self.setR16(p, self.fetch16()), // LD rr,d16
            0x08 => { // LD (a16),SP
                const addr = self.fetch16();
                self.ram.set(addr, @truncate(self.SP));
                self.ram.set(addr +% 1, @truncate(self.SP >> 8));
            },
            0xF9 => self.SP = self.registers.R16.HL, // LD SP,HL
            0xC1, 0xD1, 0xE1, 0xF1 => self.setR16Stack(p, self.pop()), // POP rr
            0xC5, 0xD5, 0xE5, 0xF5 => self.push(self.getR16Stack(p)), // PUSH rr

            // ---- 8-bit arithmetic ----
            0x80...0xBF => self.alu(y, self.getR8(z)), // ALU A,r
            0xC6, 0xCE, 0xD6, 0xDE, 0xE6, 0xEE, 0xF6, 0xFE => self.alu(y, self.fetch8()), // ALU A,d8
            0x04, 0x0C, 0x14, 0x1C, 0x24, 0x2C, 0x34, 0x3C => self.setR8(y, self.inc8(self.getR8(y))), // INC r
            0x05, 0x0D, 0x15, 0x1D, 0x25, 0x2D, 0x35, 0x3D => self.setR8(y, self.dec8(self.getR8(y))), // DEC r
            0x2F => { // CPL
                self.registers.R8.A = ~self.registers.R8.A;
                self.registers.flags.n = true;
                self.registers.flags.h = true;
            },
            0x37 => { // SCF
                self.registers.flags.n = false;
                self.registers.flags.h = false;
                self.registers.flags.c = true;
            },
            0x3F => { // CCF
                self.registers.flags.n = false;
                self.registers.flags.h = false;
                self.registers.flags.c = !self.registers.flags.c;
            },
            // TODO(you): DAA -- decimal-adjust A after a BCD add/sub. Tested by 01-special.
            0x27 => {
                const byte = self.fetch8();
                // const a = self.registers.R8.A;
                if (self.registers.flags.n == false) {
                    if (self.registers.flags.h or (byte & 0x0F) > 9) {
                        self.registers.R8.A +%= 0x06;
                        self.registers.flags.c = (self.registers.R8.A > 0x99);
                    }
                }

                if (self.registers.flags.n == true) {
                    if (self.registers.flags.h or self.registers.flags.c) {
                        self.registers.R8.A -%= 0x06;
                    }
                }

                self.registers.flags.z = (self.registers.R8.A == 0);

                self.registers.flags.h = false;
            },

            // ---- 16-bit arithmetic ----
            0x03, 0x13, 0x23, 0x33 => self.setR16(p, self.getR16(p) +% 1), // INC rr
            0x0B, 0x1B, 0x2B, 0x3B => self.setR16(p, self.getR16(p) -% 1), // DEC rr
            0x09, 0x19, 0x29, 0x39 => self.addHL(self.getR16(p)), // ADD HL,rr
            0xE8 => self.SP = self.spPlusE8(), // ADD SP,e8
            0xF8 => self.registers.R16.HL = self.spPlusE8(), // LD HL,SP+e8 (SP unchanged)

            // ---- rotates on A (like the CB versions, but Z is always cleared) ----
            0x07, 0x0F, 0x17, 0x1F => {
                self.registers.R8.A = self.rotate(y, self.registers.R8.A);
                self.registers.flags.z = false;
            },

            // ---- jumps / calls ----
            0x18 => self.jr(), // JR e8
            0x20, 0x28, 0x30, 0x38 => { // JR cc,e8
                if (self.cond(cc)) {
                    self.jr();
                    return cycles + 4;
                }
                self.PC +%= 1;
            },
            0xC3 => self.PC = self.fetch16(), // JP a16
            0xC2, 0xCA, 0xD2, 0xDA => { // JP cc,a16
                const addr = self.fetch16();
                if (self.cond(cc)) {
                    self.PC = addr;
                    return cycles + 4;
                }
            },
            0xE9 => self.PC = self.registers.R16.HL, // JP HL
            0xCD => self.call(self.fetch16()), // CALL a16
            0xC4, 0xCC, 0xD4, 0xDC => { // CALL cc,a16
                const addr = self.fetch16();
                if (self.cond(cc)) {
                    self.call(addr);
                    return cycles + 12;
                }
            },
            0xC9 => self.PC = self.pop(), // RET
            0xC0, 0xC8, 0xD0, 0xD8 => { // RET cc
                if (self.cond(cc)) {
                    self.PC = self.pop();
                    return cycles + 12;
                }
            },
            0xC7, 0xCF, 0xD7, 0xDF, 0xE7, 0xEF, 0xF7, 0xFF => self.call(op & 0x38), // RST
            // TODO(you): RETI -- RET, and enable IME immediately. Tested by 02-interrupts.
            0xD9 => {
                self.PC = self.pop();
                self.ime = true;
            },

            // ---- interrupts / misc ----
            0xF3 => { // DI
                self.ime = false;
                self.ime_pending = false;
            },
            // TODO(you): EI -- set `ime_pending`; `step` turns IME on after the next
            // instruction. Tested by 02-interrupts.
            0xFB => {
                self.ime_pending = true;
            },
            // TODO(you): HALT -- set `halted`; `step` wakes the CPU when IE & IF != 0.
            // Tested by 02-interrupts.
            0x76 => {
                self.halted = true;
            },

            0xCB => return self.cb(),

            0xD3, 0xDB, 0xDD, 0xE3, 0xE4, 0xEB, 0xEC, 0xED, 0xF4, 0xFC, 0xFD => {
                print("invalid opcode 0x{X:0>2} at PC=0x{X:0>4}\n", .{ op, self.PC -% 1 });
                return error.InvalidOpcode;
            },
        }
        return cycles;
    }

    /// CB-prefixed ops: xx bbb rrr -> rotate/shift (xx=0), BIT (1), RES (2), SET (3)
    fn cb(self: *CPU) u8 {
        const op = self.fetch8();
        const b: u3 = @truncate(op >> 3);
        const r: u3 = @truncate(op);
        const group: u2 = @truncate(op >> 6);
        const mask = @as(u8, 1) << b;

        switch (group) {
            0 => self.setR8(r, self.rotate(b, self.getR8(r))),
            1 => { // BIT b,r
                self.registers.flags.z = self.getR8(r) & mask == 0;
                self.registers.flags.n = false;
                self.registers.flags.h = true;
            },
            2 => self.setR8(r, self.getR8(r) & ~mask), // RES b,r
            3 => self.setR8(r, self.getR8(r) | mask), // SET b,r
        }

        if (r != 6) return 8;
        return if (group == 1) 12 else 16;
    }
};
