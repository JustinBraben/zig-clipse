const std = @import("std");

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

    pub fn load_from_string(self: *Map, tmxContents: []const u8, tmxPath: []const u8) !Map {
        _ = tmxContents;
        self.reset();

        // TODO: make sure we have consistent path seperators
        self.working_dir = tmxPath;

        // Find the map node and bail if DNE

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
