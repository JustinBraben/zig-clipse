const std = @import("std");
const xml = @import("xml.zig");

pub const Data = struct {
    backing_allocator: std.mem.Allocator,
    encoding: []const u8,
    compression: ?[]const u8,
    contents: []const u8,

    pub fn loadFromXmlDataNode(backing_allocator: std.mem.Allocator, data_node: *xml.Element) !Data {
        //std.debug.print("Data inner : {}\n", .{data_node.tag});
        //std.debug.print("Data elems inner : {s}\n", .{data_node.elements().inner.items[0].char_data});
        return .{
            .backing_allocator = backing_allocator,
            .encoding = data_node.getAttribute("encoding") orelse return error.NoEncoding,
            .compression = data_node.getAttribute("compression"),
            .contents = data_node.elements().inner.items[0].char_data,
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
