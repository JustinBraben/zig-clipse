const std = @import("std");
const xml = @import("xml.zig");

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
    allocator: std.mem.Allocator,
    working_dir: []const u8,
    first_gid: u32,
    name: []const u8,
    tile_width: u32,
    tile_height: u32,
    tile_count: u32,
    columns: u32,
    //image: Image,
    //tiles: []Tile,

    pub fn loadFromXmlTileNode(backing_allocator: std.mem.Allocator, tile_node: *xml.Element, workingDir: ?[]const u8) !Tileset {
        return .{
            .allocator = backing_allocator,
            .working_dir = workingDir orelse return error.EmptyWorkingDir,
            .first_gid = try tile_node.getAttributeAsInt("firstgid", u32),
            .name = tile_node.getAttribute("name") orelse return error.NameMissing,
            .tile_width = try tile_node.getAttributeAsInt("tilewidth", u32),
            .tile_height = try tile_node.getAttributeAsInt("tileheight", u32),
            .tile_count = try tile_node.getAttributeAsInt("tilecount", u32),
            .columns = try tile_node.getAttributeAsInt("columns", u32),
        };
    }
};
