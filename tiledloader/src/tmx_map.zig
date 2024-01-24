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
    @"right-down",
    @"right-up",
    @"left-down",
    @"left-up",
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
    //class: ?[]const u8 = null,
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
        self.working_dir = try std.fs.realpathAlloc(backing_allocator, tmxPath);

        // Find the map node and bail if DNE
        const map_node = doc.root;
        if (!std.mem.eql(u8, map_node.tag, "map")) {
            return error.InvalidXml;
        }

        return try parse_map_node(backing_allocator, map_node, self.working_dir);

        // return .{
        //     .allocator = backing_allocator,
        //     .version = self.version,
        //     //.class = self.class,
        //     .orientation = self.orientation,
        //     .renderorder = self.renderorder,
        //     .infinite = self.infinite,

        //     //.tile_count = self.tile_count,
        //     //.tile_size = self.tile_size,

        //     //.hex_side_length = self.hex_side_length,
        //     .stagger_axis = self.stagger_axis,
        //     .stagger_index = self.stagger_index,

        //     //.parallax_origin = self.parallax_origin,

        //     //.background_color = self.background_color,

        //     .working_dir = self.working_dir,

        //     //.tilesets = self.tilesets,
        //     //.layers = self.layers,
        //     //.properties = self.properties,
        //     //.anim_tiles = self.anim_tiles,

        //     //.template_objects = self.template_objects,
        //     //.template_tilesets = self.template_tilesets,
        // };
    }

    fn parse_map_node(backing_allocator: std.mem.Allocator, map_node: *xml.Element, workingDir: ?[]const u8) !Map {

        // parse map attributes
        var map_version: []const u8 = undefined;
        map_version = map_node.getAttribute("version").?;

        std.debug.print("map version : {?s}\n", .{map_version});
        var split_tokens = std.mem.tokenizeScalar(u8, map_version, '.');
        const major = split_tokens.next().?;
        const minor = split_tokens.next().?;
        const major_int = std.fmt.parseInt(u16, major, 10) catch |err| switch (err) {
            error.InvalidCharacter => return error.InvalidXml,
            error.Overflow => return error.InvalidXml,
        };
        const minor_int = std.fmt.parseInt(u16, minor, 10) catch |err| switch (err) {
            error.InvalidCharacter => return error.InvalidXml,
            error.Overflow => return error.InvalidXml,
        };

        const map_orientation = map_node.getAttribute("orientation").?;
        var map_orientation_enum: Orientation = undefined;

        // TODO: find a way to use stringToEnum with optional values
        // const orientation_case = std.meta.stringToEnum(Orientation, map_orientation);
        // _ = orientation_case; // autofix
        // map_orientation_enum = switch (orientation_case) {
        //     .Orthogonal => .Orthogonal,
        //     .Isometric => .Isometric,
        //     .Staggered => .Staggered,
        //     .Hexagonal => .Hexagonal,
        //     else => .None,
        // };

        if (std.mem.eql(u8, map_orientation, "orthogonal")) {
            map_orientation_enum = .Orthogonal;
        } else if (std.mem.eql(u8, map_orientation, "isometric")) {
            map_orientation_enum = .Isometric;
        } else if (std.mem.eql(u8, map_orientation, "staggered")) {
            map_orientation_enum = .Staggered;
        } else if (std.mem.eql(u8, map_orientation, "hexagonal")) {
            map_orientation_enum = .Hexagonal;
        } else {
            map_orientation_enum = .None;
        }

        const map_renderorder = map_node.getAttribute("renderorder").?;
        var map_renderorder_enum: RenderOrder = undefined;
        if (std.mem.eql(u8, map_renderorder, "right-down")) {
            map_renderorder_enum = .@"right-down";
        } else if (std.mem.eql(u8, map_renderorder, "right-up")) {
            map_renderorder_enum = .@"right-up";
        } else if (std.mem.eql(u8, map_renderorder, "left-down")) {
            map_renderorder_enum = .@"left-down";
        } else if (std.mem.eql(u8, map_renderorder, "left-up")) {
            map_renderorder_enum = .@"left-up";
        } else {
            map_renderorder_enum = .None;
        }

        const map_infinite = map_node.getAttribute("infinite").?;
        var map_infinite_bool = false;
        if (std.mem.eql(u8, map_infinite, "1")) {
            map_infinite_bool = true;
        }

        //const map_staggeraxis = map_node.getAttribute("staggeraxis");

        // const attribs = map_node.attributes;
        // var index: u8 = 0;
        // while (index < attribs.len) : (index += 1) {
        //     const attrib = attribs[index];
        //     std.debug.print("{s}: {s}\n", .{ attrib.name, attrib.value });
        // }

        return .{
            .allocator = backing_allocator,
            .version = .{
                .major = major_int,
                .minor = minor_int,
            },
            //.class = self.class,
            .orientation = map_orientation_enum,
            .renderorder = map_renderorder_enum,
            .infinite = map_infinite_bool,
            .stagger_axis = .None,
            .stagger_index = .None,
            .working_dir = workingDir,
        };
    }

    pub fn reset(self: *Map) void {
        self.version = null;
        //self.class = null;
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
