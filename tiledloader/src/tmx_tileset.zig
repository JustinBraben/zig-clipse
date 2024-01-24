const std = @import("std");

pub const Tileset = struct {
    working_dir: []const u8,
    first_gid: u32,
    name: []const u8,
    tile_width: u32,
    tile_height: u32,
    tile_count: u32,
    columns: u32,
};
