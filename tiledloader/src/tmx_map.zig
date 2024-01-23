const std = @import("std");
const xml = @import("xml.zig");

pub const Version = struct {
    major: u16 = 0,
    minor: u16 = 0,
    //patch: u32,
};

pub const Orientation = enum {
    Orthogonal,
    Isometric,
    Staggered,
    Hexagonal,
    None,
};

pub const RenderOrder = enum {
    RightDown,
    RightUp,
    LeftDown,
    LeftUp,
    None,
};

pub const StaggerAxis = enum {
    X,
    Y,
    None,
};

pub const StaggerIndex = enum {
    Even,
    Odd,
    None,
};

pub const Map = struct {
    allocator: std.mem.Allocator,
    version: ?Version = null,
    class: ?[]const u8 = null,
    orientation: ?Orientation = null,
    renderorder: ?RenderOrder = null,
    infinite: bool = false,

    //tile_count: []u32,
    //tile_size: []u32,

    //hex_side_length: f32,
    stagger_axis: StaggerAxis = .None,
    stagger_index: StaggerIndex = .None,

    //parallax_origin: []f32,

    //background_color: Color,

    working_dir: ?[]const u8 = null,

    //tilesets: []Tileset,
    //layers: []Layer,
    //properties: []Property,
    //anim_tiles: std.AutoHashMap(u32, Tile),

    //template_objects: std.AutoHashMap(u32, Object),
    //template_tilesets: std.AutoHashMap(u32, Tileset),

    pub fn load_from_string(self: *Map, backing_allocator: std.mem.Allocator, tmxContents: []const u8, tmxPath: []const u8) !Map {
        self.reset();

        // TODO: open doc
        const doc = xml.parse(backing_allocator, tmxContents) catch |err| switch (err) {
            error.InvalidDocument,
            error.UnexpectedEof,
            error.UnexpectedCharacter,
            error.IllegalCharacter,
            error.InvalidEntity,
            error.InvalidName,
            error.InvalidStandaloneValue,
            error.NonMatchingClosingTag,
            error.UnclosedComment,
            error.UnclosedValue,
            => return error.InvalidXml,
            error.OutOfMemory => return error.OutOfMemory,
        };

        // TODO: make sure we have consistent path seperators
        self.working_dir = tmxPath;

        // Find the map node and bail if DNE
        const map_node = doc.root;
        _ = map_node; // autofix

        return .{
            .allocator = backing_allocator,
            .version = self.version,
            .class = self.class,
            .orientation = self.orientation,
            .renderorder = self.renderorder,
            .infinite = self.infinite,

            //.tile_count = self.tile_count,
            //.tile_size = self.tile_size,

            //.hex_side_length = self.hex_side_length,
            .stagger_axis = self.stagger_axis,
            .stagger_index = self.stagger_index,

            //.parallax_origin = self.parallax_origin,

            //.background_color = self.background_color,

            .working_dir = self.working_dir,

            //.tilesets = self.tilesets,
            //.layers = self.layers,
            //.properties = self.properties,
            //.anim_tiles = self.anim_tiles,

            //.template_objects = self.template_objects,
            //.template_tilesets = self.template_tilesets,
        };
    }

    pub fn reset(self: *Map) void {
        self.version = null;
        self.class = null;
        self.orientation = null;
        self.renderorder = null;
        self.infinite = false;

        //self.tile_count = null;
        //self.tile_size = null;

        //self.hex_side_length = 0.0;
        self.stagger_axis = .None;
        self.stagger_index = .None;

        //self.parallax_origin = null;

        //self.background_color = Color{};

        self.working_dir = null;

        //self.tilesets = null;
        //self.layers = null;
        //self.properties = null;
        //self.anim_tiles = null;

        //self.template_objects = null;
        //self.template_tilesets = null;
    }
};
