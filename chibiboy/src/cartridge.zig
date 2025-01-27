const std = @import("std");
const testing = std.testing;
const fs = std.fs;

const errors = @import("errors.zig");

const KB: u32 = 1024;

fn parse_rom_size(val: u8) u32 {
    return (32 * KB) << @as(u5, @intCast(val));
}

fn parse_ram_size(val: u8) u32 {
    return switch (val) {
        0 => 0,
        2 => 8 * KB,
        3 => 32 * KB,
        4 => 128 * KB,
        5 => 64 * KB,
        else => 0,
    };
}

pub const Cartridge = struct {
    allocator: std.mem.Allocator,

    data: []const u8,
    ram: []u8,

    logo: []u8,
    name: []const u8,
    is_gbc: bool,
    licensee: u16,
    is_sgb: bool,
    cart_type: u8,
    rom_size: u32,
    ram_size: u32,
    destination: u8,
    old_licensee: u8,
    rom_version: u8,
    complement_check: u8,
    checksum: u16,

    pub fn init(allocator: std.mem.Allocator, fileName: []const u8) !Cartridge {
        var file = try fs.cwd().openFile(fileName, fs.File.OpenFlags{ .mode = .read_only });
        defer file.close();

        const data = try file.readToEndAlloc(allocator, (try file.stat()).size);
        errdefer allocator.free(data);

        return Cartridge{
            .allocator = allocator,
            .data = data,
            .ram = try allocator.alloc(u8, parse_ram_size(data[0x0149])),
            .logo = data[0x0104 .. 0x0104 + 48],
            .name = data[0x0134 .. 0x0134 + 15],
            .is_gbc = data[0x0143] == 0x80,
            .licensee = @as(u16, @intCast(data[0x0144])) << 8 | @as(u16, @intCast(data[0x0145])),
            .is_sgb = data[0x0146] == 0x03,
            .cart_type = data[0x0147],
            .rom_size = parse_rom_size(data[0x0148]),
            .ram_size = parse_ram_size(data[0x0149]),
            .destination = data[0x014A],
            .old_licensee = data[0x014B],
            .rom_version = data[0x014C],
            .complement_check = data[0x014D],
            .checksum = @as(u16, @intCast(data[0x014E])) << 8 | @as(u16, @intCast(data[0x14F])),
        };
    }

    pub fn deinit(self: *Cartridge) void {
        self.allocator.free(self.data);
        self.allocator.free(self.ram);
    }
};

test "Cartridge logo" {
    const testing_allocator = std.testing.allocator;
    var cart = try Cartridge.init(testing_allocator, "C:/Users/Justin/source/repos/zig-clipse/chibiboy/roms/cgb_sound/cgb_sound.gb");
    defer cart.deinit();

    const expected_logo = [_]u8{ 
        0xce, 0xed, 0x66, 0x66, 0xcc, 0x0d, 0x00, 0x0b, 0x03, 0x73, 0x00, 0x83, 0x00, 0x0c, 0x00, 0x0d, 
        0x00, 0x08, 0x11, 0x1f, 0x88, 0x89, 0x00, 0x0e, 0xdc, 0xcc, 0x6e, 0xe6, 0xdd, 0xdd, 0xd9, 0x99, 
        0xbb, 0xbb, 0x67, 0x63, 0x6e, 0x0e, 0xec, 0xcc, 0xdd, 0xdc, 0x99, 0x9f, 0xbb, 0xb9, 0x33, 0x3e 
    };

    for (expected_logo, cart.logo) |expected, actual| {
        try testing.expectEqual(expected, actual);
    }
}

test "Cartridge name" {
    const testing_allocator = std.testing.allocator;
    var cart = try Cartridge.init(testing_allocator, "C:/Users/Justin/source/repos/zig-clipse/chibiboy/roms/cgb_sound/cgb_sound.gb");
    defer cart.deinit();
    
    var idx: usize = 0;
    const expected_name = "CGB_SOUND";
    while (idx < cart.name.len) : (idx += 1) {
        if (idx < expected_name.len) {
            try testing.expectEqual(expected_name[idx], cart.name[idx]);
        }
    }
}