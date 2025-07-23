const std = @import("std");
const testing = std.testing;
const Chibiboy = @import("chibiboy");
const Cartridge = Chibiboy.Cartridge;

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