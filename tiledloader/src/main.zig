const std = @import("std");
const App = @import("app.zig").App;

const print = std.debug.print;

pub fn main() !void {
    print("\n", .{});

    var gpa_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.testing.expect(gpa_allocator.deinit() != .leak) catch @panic("memory leak");
    const gpa = gpa_allocator.allocator();

    // TODO: read the contents of a .tmx file (such as "assets/demo.tmx") and print it out
    const filename = "assets/demo.tmx";
    const file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    const file_contents = try file.reader().readAllAlloc(gpa, 2048);
    defer gpa.free(file_contents);

    // Debug print the contents of the file
    //print("{s}\n", .{file_contents});

    // TODO: Tokenize the contents of the .tmx file by '\n' character
    var lines = std.mem.tokenizeScalar(u8, file_contents, '\n');

    while (lines.next()) |line| {
        //print("{s}\n", .{line});

        // TODO: Tokenize the contents of the .tmx file by '<' and '>' characters
        var line_tokens = std.mem.tokenizeAny(u8, line, "<? >");
        print("type : {s}\n", .{line_tokens.peek().?});
        while (line_tokens.next()) |token| {
            _ = token; // autofix
            //print("{s}\n", .{token});
        }
    }

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