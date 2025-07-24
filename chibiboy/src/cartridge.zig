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

pub const CartContext = struct {
    file_name: []const u8,
    rom_size: u32,
    rom_data: []const u8,
};

pub const Cartridge = struct {
    allocator: std.mem.Allocator,

    data: []const u8,
    ram: []u8,

    logo: []u8,
    name: []const u8,
    is_gbc: bool,
    new_lic_code: u16,
    is_sgb: bool,
    cart_type: u8,
    rom_size: u32,
    ram_size: u32,
    dest_code: u8,
    lic_code: u8,
    version: u8,
    checksum: u8,
    global_checksum: u16,

    pub fn init(allocator: std.mem.Allocator, file_name: []const u8) !Cartridge {
        const input_file = try std.fs.cwd().openFile(file_name, .{}); 
        defer input_file.close();
        const file_stat = try input_file.stat();

        const file_contents = try input_file.readToEndAlloc(allocator, file_stat.size);
        errdefer allocator.free(file_contents);

        // Print file contents
        // std.debug.print("{s}", .{file_contents});

        return Cartridge{
            .allocator = allocator,
            .data = file_contents,
            .ram = try allocator.alloc(u8, parse_ram_size(file_contents[0x0149])),
            .logo = file_contents[0x0104 .. 0x0104 + 48],
            .name = file_contents[0x0134 .. 0x0134 + 15],
            .is_gbc = file_contents[0x0143] == 0x80,
            .new_lic_code = @as(u16, @intCast(file_contents[0x0144])) << 8 | @as(u16, @intCast(file_contents[0x0145])),
            .is_sgb = file_contents[0x0146] == 0x03,
            .cart_type = file_contents[0x0147],
            .rom_size = parse_rom_size(file_contents[0x0148]),
            .ram_size = parse_ram_size(file_contents[0x0149]),
            .dest_code = file_contents[0x014A],
            .lic_code = file_contents[0x014B],
            .version = file_contents[0x014C],
            .checksum = file_contents[0x014D],
            .global_checksum = @as(u16, @intCast(file_contents[0x014E])) << 8 | @as(u16, @intCast(file_contents[0x14F])),
        };
    }

    pub fn deinit(self: *Cartridge) void {
        self.allocator.free(self.data);
        self.allocator.free(self.ram);
    }
};

test "Cartridge logo" {
    const testing_allocator = std.testing.allocator;
    var cart = try Cartridge.init(testing_allocator, "roms/cgb_sound/cgb_sound.gb");
    defer cart.deinit();

    const expected_logo = [_]u8{ 
        0xce, 0xed, 0x66, 0x66, 0xcc, 0x0d, 0x00, 0x0b, 0x03, 0x73, 0x00, 0x83, 0x00, 0x0c, 0x00, 0x0d, 
        0x00, 0x08, 0x11, 0x1f, 0x88, 0x89, 0x00, 0x0e, 0xdc, 0xcc, 0x6e, 0xe6, 0xdd, 0xdd, 0xd9, 0x99, 
        0xbb, 0xbb, 0x67, 0x63, 0x6e, 0x0e, 0xec, 0xcc, 0xdd, 0xdc, 0x99, 0x9f, 0xbb, 0xb9, 0x33, 0x3e 
    };

    try testing.expectEqualSlices(u8, expected_logo[0..], cart.logo);
}

test "Cartridge name" {
    const testing_allocator = std.testing.allocator;
    var cart = try Cartridge.init(testing_allocator, "roms/cgb_sound/cgb_sound.gb");
    defer cart.deinit();
    
    const expected_name = "CGB_SOUND";
    try testing.expectEqualSlices(u8, expected_name, cart.name[0..expected_name.len]);
}