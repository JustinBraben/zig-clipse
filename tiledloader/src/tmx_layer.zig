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
        const first_new_line = std.mem.indexOfScalar(u8, char_data, '\n') orelse return error.NoNewLine;
        const last_new_line = std.mem.lastIndexOfScalar(u8, char_data, '\n') orelse return error.NoNewLine;
        const trim_data = std.mem.trim(u8, char_data, "\r\n  ");

        std.debug.print("Number of items for data : {}\n", .{data_node.elements().inner.items.len});
        std.debug.print("first new line : {d}\n", .{first_new_line});
        std.debug.print("last new line : {d}\n", .{last_new_line});
        std.debug.print("Data elems inner : {s}\n", .{trim_data});

        const compression = data_node.getAttribute("compression");
        const encoding = data_node.getAttribute("encoding") orelse return error.NoEncoding;

        if (std.mem.eql(u8, encoding, "csv")) {
            return .{
                .backing_allocator = backing_allocator,
                .encoding = data_node.getAttribute("encoding") orelse return error.NoEncoding,
                .compression = data_node.getAttribute("compression"),
                .contents = trim_data,
            };
        } else if (std.mem.eql(u8, encoding, "base64")) {
            if (compression != null) {
                if (std.mem.eql(u8, compression.?, "zlib")) {
                    const codecs = std.base64.standard;
                    var buffer2: [0x500]u8 = undefined;
                    const decoded_bytes = buffer2[0..try codecs.Decoder.calcSizeForSlice(trim_data)];
                    try codecs.Decoder.decode(decoded_bytes, trim_data);

                    var in_stream = std.io.fixedBufferStream(decoded_bytes);
                    var zlib_stream = try std.compress.zlib.decompressStream(backing_allocator, in_stream.reader());
                    defer zlib_stream.deinit();

                    const decompressed_data = try zlib_stream.reader().readAllAlloc(backing_allocator, std.math.maxInt(usize));
                    std.debug.print("Decoded, zlib compressed : {s}\n", .{decoded_bytes});
                    std.debug.print("Decoded, Decompressed zlib : {any}\n", .{decompressed_data});
                    return .{
                        .backing_allocator = backing_allocator,
                        .encoding = data_node.getAttribute("encoding") orelse return error.NoEncoding,
                        .compression = data_node.getAttribute("compression"),
                        .contents = decompressed_data,
                    };
                } else {}
            }
        } else {
            return error.UnsupportedEncoding;
        }

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
