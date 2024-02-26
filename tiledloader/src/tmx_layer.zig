const std = @import("std");
const xml = @import("xml.zig");
const zlib = std.compress.zlib;

const native_endian = @import("builtin").target.cpu.arch.endian();

const log = std.log.scoped(.Tmx_Layer);

pub const Data = struct {
    backing_allocator: std.mem.Allocator,
    encoding: []const u8,
    compression: ?[]const u8,
    contents: std.ArrayList(u32),

    pub fn loadFromXmlDataNode(backing_allocator: std.mem.Allocator, data_node: *xml.Element) !Data {
        const char_data = data_node.elements().inner.items[0].char_data;
        const first_new_line = std.mem.indexOfScalar(u8, char_data, '\n') orelse return error.NoNewLine;
        _ = first_new_line; // autofix
        const last_new_line = std.mem.lastIndexOfScalar(u8, char_data, '\n') orelse return error.NoNewLine;
        _ = last_new_line; // autofix
        const trim_data = std.mem.trim(u8, char_data, "\r\n  ");

        //std.debug.print("Number of items for data : {}\n", .{data_node.elements().inner.items.len});
        //std.debug.print("first new line : {d}\n", .{first_new_line});
        //std.debug.print("last new line : {d}\n", .{last_new_line});
        //std.debug.print("Data elems inner : {s}\n", .{trim_data});

        const compression = data_node.getAttribute("compression");
        const encoding = data_node.getAttribute("encoding") orelse return error.NoEncoding;

        if (std.mem.eql(u8, encoding, "csv")) {
            // TODO: Implement CSV decoding
            // Init u32 list, and append each csv value to it
            return .{
                .backing_allocator = backing_allocator,
                .encoding = data_node.getAttribute("encoding") orelse return error.NoEncoding,
                .compression = data_node.getAttribute("compression"),
                .contents = std.ArrayList(u32).init(backing_allocator),
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

                    var uint_32_list = std.ArrayList(u32).init(backing_allocator);
                    try uint_32_list.append(decompressed_data[0..][0]);
                    var index: usize = 1;
                    while (index < decompressed_data.len) : (index += 4) {
                        const full_slice = decompressed_data[index..];
                        if (full_slice.len < 4) {
                            break;
                        }
                        const slic = (decompressed_data[index..])[0..4];
                        const uint_32 = bytesToU32(slic.*);
                        try uint_32_list.append(uint_32);
                        //std.debug.print("u = {d}\n", .{uint_32});
                    }
                    //var items_string: []const u8 = undefined;
                    //items_string = try std.fmt.allocPrint(backing_allocator, "{d}\n", .{uint_32_list.items});

                    //std.debug.print("Decoded, zlib compressed : {s}\n", .{decoded_bytes});
                    //std.debug.print("Decoded, Decompressed zlib : {any}\n", .{decompressed_data});
                    //std.debug.print("u32 list : {any}\n", .{uint_32_list.items});

                    return .{
                        .backing_allocator = backing_allocator,
                        .encoding = data_node.getAttribute("encoding") orelse return error.NoEncoding,
                        .compression = data_node.getAttribute("compression"),
                        .contents = uint_32_list,
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
            .contents = std.ArrayList(u32).init(backing_allocator),
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

fn bytesToU32(bytes: [4]u8) u32 {
    if (native_endian == .big) {
        return bytes[0] | (@as(u32, bytes[1]) << 8) | (@as(u32, bytes[2]) << 16) | (@as(u32, bytes[3]) << 24);
    } else {
        return (@as(u32, bytes[0]) << 24) | (@as(u32, bytes[1]) << 16) | (@as(u32, bytes[2]) << 8) | bytes[3];
    }
}
