const std = @import("std");
const App = @import("app.zig").App;

const xml_document = @import("xml.zig").xml_document;
const xml_parse_result = @import("xml.zig").xml_parse_result;
const xml_test = @import("xml_test.zig").Xml;

const print = std.debug.print;

pub fn main() !void {
    print("\n", .{});

    var gpa_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.testing.expect(gpa_allocator.deinit() != .leak) catch @panic("memory leak");
    const gpa = gpa_allocator.allocator();

    // TODO: read the contents of a .tmx file (such as "assets/demo.tmx") and print it out
    //var doc = try xml_document.init(gpa, "assets/demo.tmx");
    //defer doc.deinit();

    var doc: xml_document = undefined;
    const result = try doc.load_file(gpa, "assets/demo.tmx");
    defer doc.deinit();

    //print("{s}\n", .{doc.contents});
    print("encoding : {any}, status : {any}\n", .{ result.encoding, result.status });

    var xml: xml_test = .{ .bytes = doc.contents };
    var token = xml.next();

    while (token.tag != .invalid and token.tag != .eof) {
        switch (token.tag) {
            .invalid => unreachable,
            .eof => unreachable,
            .doctype => {
                print("{s}: {s}\n", .{ @tagName(token.tag), token.bytes });
            },
            .tag_open => {
                print("{s}: {s}\n", .{ @tagName(token.tag), token.bytes });
            },
            .tag_close => {
                print("{s}: {s}\n", .{ @tagName(token.tag), token.bytes });
            },
            .tag_close_empty => {},
            .attr_key => {},
            .attr_value => {},
            .content => {},
        }
        //print("{s}: {s}\n", .{ @tagName(token.tag), token.bytes });
        token = xml.next();
    }

    //print("{s}\n", .{xml.line});

    // print("doctype : {any}\n", .{xml.next().tag});
    // print("{any}\n", .{xml.next().tag});

    // TODO: Get iterator for doc.child

    // TODO: Tokenize the contents of the .tmx file by '\n' character
    // var lines = std.mem.tokenizeScalar(u8, file_contents, '\n');

    // while (lines.next()) |line| {
    //     //print("{s}\n", .{line});

    //     // TODO: Tokenize the contents of the .tmx file by '<' and '>' characters
    //     var line_tokens = std.mem.tokenizeAny(u8, line, "<>\n");

    //     while (line_tokens.next()) |token| {
    //         print("{s}\n", .{token});
    //     }
    // }

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
