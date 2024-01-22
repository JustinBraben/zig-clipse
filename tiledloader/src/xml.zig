const std = @import("std");
const mem = std.mem;
const testing = std.testing;
const fs = std.fs;
const Allocator = mem.Allocator;
const ArenaAllocator = std.heap.ArenaAllocator;

pub const xml_document = struct {
    allocator: Allocator,
    file_path: []const u8,
    contents: []const u8,

    pub fn init(allocator: Allocator, filePath: []const u8) !xml_document {

        // TODO: read the contents of a .tmx file (such as "assets/demo.tmx") and print it out
        const file = try std.fs.cwd().openFile(filePath, .{});
        defer file.close();

        const file_contents = try file.reader().readAllAlloc(allocator, 2048);

        return .{
            .allocator = allocator,
            .file_path = filePath,
            .contents = file_contents,
        };
    }

    pub fn deinit(self: *xml_document) void {
        self.allocator.free(self.contents);
    }
};

pub const xml_parse_result = struct {
    status: xml_parse_status,
    encoding: xml_encoding,

    pub fn load_file(doc: *xml_document) xml_parse_result {

        // get file size
        var file = try fs.cwd().openFile(doc.file_path, .{});
        defer file.close();

        const file_size = try file.stat().size;
        const size_status: xml_parse_status = parse_file_size(file_size);

        if (size_status != xml_parse_status.success) {
            return .{
                .status = size_status,
                .encoding = xml_encoding.utf8,
            };
        }

        const real_encoding = get_buffer_encoding(doc.contents, file_size);

        return .{
            .status = xml_parse_status.success,
            .encoding = real_encoding,
        };
    }

    fn parse_file_size(file_size: u64) xml_parse_status {
        if (file_size == 0) {
            return xml_parse_status.file_not_found;
        }
        return xml_parse_status.success;
    }

    fn get_buffer_encoding(buffer: []const u8, buffer_size: u64) xml_encoding {
        if (buffer_size < 2) {
            return xml_encoding.utf8;
        }

        if (buffer[0] == 0xFF and buffer[1] == 0xFE) {
            return xml_encoding.utf16;
        }

        if (buffer[0] == 0xFE and buffer[1] == 0xFF) {
            return xml_encoding.utf16;
        }

        if (buffer_size < 4) {
            return xml_encoding.utf8;
        }

        if (buffer[0] == 0x00 and buffer[1] == 0x00 and buffer[2] == 0xFE and buffer[3] == 0xFF) {
            return xml_encoding.utf32;
        }

        if (buffer[0] == 0xFF and buffer[1] == 0xFE and buffer[2] == 0x00 and buffer[3] == 0x00) {
            return xml_encoding.utf32;
        }

        return xml_encoding.utf8;
    }
};

pub const xml_parse_status = enum {
    success,
    file_not_found,
    file_read_error,
    parse_error,
};

pub const xml_encoding = enum {
    auto, // Auto-detect input encoding using BOM or < / <? detection; use UTF8 if BOM is not found
    utf8,
    utf16,
    utf32,
};
