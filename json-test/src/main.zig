const std = @import("std");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});

    const json_path = try std.fs.cwd().realpathAlloc(alloc, "./src/example.json");

    std.debug.print("example json path : {s}\n", .{json_path});

    const json_file = try std.fs.openFileAbsolute(json_path, .{ .mode = .read_only });
    defer json_file.close();
    const file_size = (try json_file.stat()).size;
    const buffer = try alloc.alloc(u8, file_size);
    defer alloc.free(buffer);
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
