const std = @import("std");
const App = @import("app.zig").App;

const xml = @import("xml.zig");
const Map = @import("tmx_map.zig").Map;

const print = std.debug.print;

pub fn main() !void {
    const stderr = std.io.getStdErr();

    print("\n", .{});

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // TODO: read the contents of a .tmx file (such as "assets/demo.tmx") and print it out
    //var doc = try xml_document.init(gpa, "assets/demo.tmx");
    //defer doc.deinit();

    const cwd = std.fs.cwd();
    const xml_path = "assets/demo.tmx";
    const xml_src = cwd.readFileAlloc(allocator, xml_path, std.math.maxInt(usize)) catch |err| {
        try stderr.writer().print("Error: Failed to open input file '{s}' ({s})\n", .{ xml_path, @errorName(err) });
        return;
    };

    const doc = try xml.parse(allocator, xml_src);
    // print("xml_decl tag: {s}\n", .{doc.xml_decl.?.tag});
    // print("doc root tag: {s}\n", .{doc.root.tag});
    // print("elements in root: {any}\n", .{doc.root.elements()});
    // const version_num = doc.root.getAttribute("version").?;
    // print("version: {s}\n", .{version_num});
    // const tileset_elem = doc.root.findChildByTag("tileset").?;
    // print("tileset_elem: {s}\n", .{tileset_elem.tag});

    const attribs = doc.root.attributes;
    var index: u8 = 0;
    while (index < attribs.len) : (index += 1) {
        const attrib = attribs[index];
        _ = attrib; // autofix
        //print("{s}: {s}\n", .{ attrib.name, attrib.value });
    }

    //print("{s} - {s}\n", .{ doc.root.getAttribute("renderorder").? });

    var map: Map = undefined;
    map = try map.loadFromString(allocator, xml_src, xml_path);
    // print("map working dir : {?s}\n", .{map.working_dir});
    // print("map : {any}\n", .{map});
    // print("map orientation : {any}\n", .{map.orientation});
    // print("map render order: {any}\n", .{map.renderorder});
    // print("map version : {any}\n", .{map.version});

    // TODO: Create a Map struct that can hold the contents of a .tmx file

    // TODO: Save the contents of the .tmx file to a Map struct

    // TODO: create an SDL window

    // TODO: render the map to the SDL window
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
