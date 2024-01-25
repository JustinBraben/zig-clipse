const std = @import("std");
const xml = @import("xml.zig");
const zlib = std.compress.zlib;

pub const Data = struct {
    backing_allocator: std.mem.Allocator,
    encoding: []const u8,
    compression: ?[]const u8,
    contents: []const u8,

    pub fn loadFromXmlDataNode(backing_allocator: std.mem.Allocator, data_node: *xml.Element) !Data {
        const char_data = data_node.elements().inner.items[0].char_data;
        const trim_data = std.mem.trim(u8, char_data, "\r\n  ");
        const first_new_line = std.mem.indexOfScalar(u8, char_data, '\n') orelse return error.NoNewLine;
        const last_new_line = std.mem.lastIndexOfScalar(u8, char_data, '\n') orelse return error.NoNewLine;

        if (std.mem.startsWith(u8, char_data, "\r")) {
            std.debug.print("char data starts with new line\n", .{});
        }

        std.debug.print("Number of items for data : {}\n", .{data_node.elements().inner.items.len});
        std.debug.print("first new line : {d}\n", .{first_new_line});
        std.debug.print("last new line : {d}\n", .{last_new_line});
        std.debug.print("Data elems inner : {s}\n", .{trim_data});

        return .{
            .backing_allocator = backing_allocator,
            .encoding = data_node.getAttribute("encoding") orelse return error.NoEncoding,
            .compression = data_node.getAttribute("compression"),
            .contents = trim_data,
        };
    }
};

pub const Layer = struct {
    backing_allocator: std.mem.Allocator,
    id: u32,
    name: []const u8,
    width: u32,
    height: u32,
    data: Data,

    pub fn loadFromXmlLayerNode(backing_allocator: std.mem.Allocator, layer_node: *xml.Element) !Layer {
        const data_node = layer_node.findChildByTag("data") orelse return error.NoData;
        const data = try Data.loadFromXmlDataNode(backing_allocator, data_node);
        return .{
            .backing_allocator = backing_allocator,
            .id = try layer_node.getAttributeAsInt("id", u32),
            .name = layer_node.getAttribute("name") orelse return error.NoNameLayer,
            .width = try layer_node.getAttributeAsInt("width", u32),
            .height = try layer_node.getAttributeAsInt("height", u32),
            .data = data,
        };
    }
};
