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
    orientation: ?Orientation = null,
    renderorder: ?RenderOrder = null,

    width: u32 = 0,
    height: u32 = 0,

    tile_width: u32 = 0,
    tile_height: u32 = 0,

    infinite: bool = false,

    next_layer_id: u32 = 0,
    next_object_id: u32 = 0,

    stagger_axis: StaggerAxis = .None,
    stagger_index: StaggerIndex = .None,

    working_dir: ?[]const u8 = null,

    pub fn load_from_string(self: *Map, backing_allocator: std.mem.Allocator, tmxContents: []const u8, tmxPath: []const u8) !Map {
        self.reset();

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

        self.working_dir = try std.fs.realpathAlloc(backing_allocator, tmxPath);

        // Find the map node and bail if DNE
        const map_node = doc.root;
        if (!std.mem.eql(u8, map_node.tag, "map")) {
            return error.InvalidXml;
        }

        return try parse_map_node(backing_allocator, map_node, self.working_dir);
    }

    fn parse_map_node(backing_allocator: std.mem.Allocator, map_node: *xml.Element, workingDir: ?[]const u8) !Map {

        // parse map attributes
        var map_version: ?[]const u8 = undefined;
        map_version = map_node.getAttribute("version");
        if (map_version == null) {
            return error.InvalidXml;
        }

        std.debug.print("map version : {?s}\n", .{map_version});
        var split_tokens = std.mem.tokenizeScalar(u8, map_version.?, '.');
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

        var map_orientation: ?[]const u8 = undefined;
        map_orientation = map_node.getAttribute("orientation");
        if (map_orientation == null) {
            return error.InvalidXml;
        }
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

        if (std.mem.eql(u8, map_orientation.?, "orthogonal")) {
            map_orientation_enum = .Orthogonal;
        } else if (std.mem.eql(u8, map_orientation.?, "isometric")) {
            map_orientation_enum = .Isometric;
        } else if (std.mem.eql(u8, map_orientation.?, "staggered")) {
            map_orientation_enum = .Staggered;
        } else if (std.mem.eql(u8, map_orientation.?, "hexagonal")) {
            map_orientation_enum = .Hexagonal;
        } else {
            map_orientation_enum = .None;
        }

        var map_renderorder: ?[]const u8 = undefined;
        map_renderorder = map_node.getAttribute("renderorder");
        if (map_renderorder == null) {
            return error.InvalidXml;
        }
        var map_renderorder_enum: RenderOrder = undefined;
        if (std.mem.eql(u8, map_renderorder.?, "right-down")) {
            map_renderorder_enum = .@"right-down";
        } else if (std.mem.eql(u8, map_renderorder.?, "right-up")) {
            map_renderorder_enum = .@"right-up";
        } else if (std.mem.eql(u8, map_renderorder.?, "left-down")) {
            map_renderorder_enum = .@"left-down";
        } else if (std.mem.eql(u8, map_renderorder.?, "left-up")) {
            map_renderorder_enum = .@"left-up";
        } else {
            map_renderorder_enum = .None;
        }

        var map_width: ?[]const u8 = undefined;
        map_width = map_node.getAttribute("width");
        if (map_width == null) {
            return error.InvalidXml;
        }
        const map_width_int = std.fmt.parseInt(u32, map_width.?, 10) catch |err| switch (err) {
            error.InvalidCharacter => return error.InvalidXml,
            error.Overflow => return error.InvalidXml,
        };

        var map_height: ?[]const u8 = undefined;
        map_height = map_node.getAttribute("height");
        if (map_height == null) {
            return error.InvalidXml;
        }
        const map_height_int = std.fmt.parseInt(u32, map_height.?, 10) catch |err| switch (err) {
            error.InvalidCharacter => return error.InvalidXml,
            error.Overflow => return error.InvalidXml,
        };

        var map_infinite: ?[]const u8 = undefined;
        map_infinite = map_node.getAttribute("infinite");
        if (map_infinite == null) {
            return error.InvalidXml;
        }
        var map_infinite_bool = false;
        if (std.mem.eql(u8, map_infinite.?, "1")) {
            map_infinite_bool = true;
        } else if (std.mem.eql(u8, map_infinite.?, "0")) {
            map_infinite_bool = false;
        } else {
            return error.InvalidXml;
        }

        var next_layer_id: ?[]const u8 = undefined;
        next_layer_id = map_node.getAttribute("nextlayerid");
        if (next_layer_id == null) {
            return error.InvalidXml;
        }
        const next_layer_id_int = std.fmt.parseInt(u32, next_layer_id.?, 10) catch |err| switch (err) {
            error.InvalidCharacter => return error.InvalidXml,
            error.Overflow => return error.InvalidXml,
        };

        var next_object_id: ?[]const u8 = undefined;
        next_object_id = map_node.getAttribute("nextlayerid");
        if (next_layer_id == null) {
            return error.InvalidXml;
        }
        const next_object_id_int = std.fmt.parseInt(u32, next_layer_id.?, 10) catch |err| switch (err) {
            error.InvalidCharacter => return error.InvalidXml,
            error.Overflow => return error.InvalidXml,
        };

        return .{
            .allocator = backing_allocator,
            .version = .{
                .major = major_int,
                .minor = minor_int,
            },
            .orientation = map_orientation_enum,
            .renderorder = map_renderorder_enum,
            .width = map_width_int,
            .height = map_height_int,
            .infinite = map_infinite_bool,
            .next_layer_id = next_layer_id_int,
            .next_object_id = next_object_id_int,
            .stagger_axis = .None,
            .stagger_index = .None,
            .working_dir = workingDir,
        };
    }

    pub fn reset(self: *Map) void {
        self.version = null;
        self.orientation = null;
        self.renderorder = null;

        self.width = 0;
        self.height = 0;

        self.infinite = false;

        self.stagger_axis = .None;
        self.stagger_index = .None;

        self.working_dir = null;
    }
};
