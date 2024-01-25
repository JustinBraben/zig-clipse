const std = @import("std");
const xml = @import("xml.zig");

pub const Frame = struct {
    tile_id: u32,
    duration: u32,

    pub fn loadFromXmlFrameNode(frame_node: *xml.Element) !Frame {
        return .{
            .tile_id = try frame_node.getAttributeAsInt("tileid", u32),
            .duration = try frame_node.getAttributeAsInt("duration", u32),
        };
    }
};

pub const Animation = struct {
    backing_allocator: std.mem.Allocator,
    frames: std.ArrayList(Frame),

    pub fn loadFromXmlAnimationNode(backing_allocator: std.mem.Allocator, animation_node: *xml.Element) !Animation {
        var frame_nodes = animation_node.findChildrenByTag("frame");
        var frames = std.ArrayList(Frame).init(backing_allocator);
        while (frame_nodes.next()) |frame_node| {
            const frame = try Frame.loadFromXmlFrameNode(frame_node);
            frames.append(frame) catch |err| {
                return err;
            };
        }

        return .{
            .backing_allocator = backing_allocator,
            .frames = frames,
        };
    }
};

pub const Tile = struct {
    backing_allocator: std.mem.Allocator,
    id: u32 = 0,
    animation: ?Animation,

    pub fn loadFromXmlTileNode(backing_allocator: std.mem.Allocator, tile_node: *xml.Element) !Tile {
        const animation_node = tile_node.findChildByTag("animation") orelse return error.AnimationMissing;
        const animation = try Animation.loadFromXmlAnimationNode(backing_allocator, animation_node);

        return .{
            .backing_allocator = backing_allocator,
            .id = try tile_node.getAttributeAsInt("id", u32),
            .animation = animation,
        };
    }
};

pub const Image = struct {
    source: []const u8,
    width: u32,
    height: u32,

    pub fn loadFromXmlImageNode(backing_allocator: std.mem.Allocator, image_node: *xml.Element, workingDir: ?[]const u8) !Image {
        const source = image_node.getAttribute("source") orelse return error.SourceMissing;
        const working_dir = workingDir orelse return error.EmptyWorkingDir;
        const concat_path = "{s}/{s}";
        const source_full_path = try std.fmt.allocPrint(backing_allocator, concat_path, .{ working_dir, source });

        // TODO: use builtin and check if windows vs linux
        // change the file path to the appropriate format
        // this currently works for windows
        std.mem.replaceScalar(u8, source_full_path, '/', '\\');

        return .{
            .source = source_full_path,
            .width = try image_node.getAttributeAsInt("width", u32),
            .height = try image_node.getAttributeAsInt("height", u32),
        };
    }
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
    image: Image,
    tiles: std.ArrayList(Tile),

    pub fn loadFromXmlTilesetNode(backing_allocator: std.mem.Allocator, tileset_node: *xml.Element, workingDir: ?[]const u8) !Tileset {
        const image_node = tileset_node.findChildByTag("image") orelse return error.ImageMissing;

        var tiles = std.ArrayList(Tile).init(backing_allocator);
        var tile_nodes = tileset_node.findChildrenByTag("tile");
        while (tile_nodes.next()) |tile_node| {
            const tile = try Tile.loadFromXmlTileNode(backing_allocator, tile_node);
            tiles.append(tile) catch |err| {
                return err;
            };
        }

        return .{
            .allocator = backing_allocator,
            .working_dir = workingDir orelse return error.EmptyWorkingDir,
            .first_gid = try tileset_node.getAttributeAsInt("firstgid", u32),
            .name = tileset_node.getAttribute("name") orelse return error.NameMissing,
            .tile_width = try tileset_node.getAttributeAsInt("tilewidth", u32),
            .tile_height = try tileset_node.getAttributeAsInt("tileheight", u32),
            .tile_count = try tileset_node.getAttributeAsInt("tilecount", u32),
            .columns = try tileset_node.getAttributeAsInt("columns", u32),
            .image = try Image.loadFromXmlImageNode(backing_allocator, image_node, workingDir),
            .tiles = tiles,
        };
    }
};
