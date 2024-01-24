const std = @import("std");

pub const Frame = struct {
    tile_id: u32,
    duration: u32,
};

pub const Animation = struct {
    frames: []Frame,
};

pub const Tile = struct {
    id: u32 = 0,
    animation: ?Animation,
};

pub const Image = struct {
    source: []const u8,
    width: u32,
    height: u32,
};

pub const Tileset = struct {
    working_dir: []const u8,
    first_gid: u32,
    name: []const u8,
    tile_width: u32,
    tile_height: u32,
    tile_count: u32,
    columns: u32,
    //image: Image,
    //tiles: []Tile,
};
