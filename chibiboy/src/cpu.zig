const std = @import("std");
const RAM = @import("ram.zig").RAM;

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

    pub fn tick(self: *CPU) !void {
        _ = self;
    }
};