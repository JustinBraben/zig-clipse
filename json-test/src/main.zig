const std = @import("std");
const LinkedList = @import("linked_list.zig").LinkedList;

const JSONFrame = struct {
    id: u8,
    pos: []f32,
};
const JSONAnimation = struct {
    id: []const u8,
    size: []f32,
    world_pos: []f32,
    speed: f32,
    loop: bool,
    frames: []JSONFrame,
};
const SpriteSheet = struct {
    width: f32,
    height: f32,
};
const JSONData = struct {
    sheet: SpriteSheet,
    animations: []JSONAnimation,
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});

    const json_path = try std.fs.cwd().realpathAlloc(allocator, "./src/example.json");

    std.debug.print("example json path : {s}\n", .{json_path});

    const json_file = try std.fs.openFileAbsolute(json_path, .{ .mode = .read_only });
    defer json_file.close();
    const file_size = (try json_file.stat()).size;
    const buffer = try allocator.alloc(u8, file_size);
    defer allocator.free(buffer);
    try json_file.reader().readNoEof(buffer);
    const root = try std.json.parseFromSlice(JSONData, allocator, buffer, .{});
    defer root.deinit();

    const L = LinkedList(u32);
    var list = L{};

    var one = L.Node{ .data = 1 };
    var two = L.Node{ .data = 2 };
    var three = L.Node{ .data = 3 };
    var four = L.Node{ .data = 4 };
    var five = L.Node{ .data = 5 };

    list.prepend(&two); // {2}
    two.insertAfter(&five); // {2, 5}
    list.prepend(&one); // {1, 2, 5}
    two.insertAfter(&three); // {1, 2, 3, 5}
    three.insertAfter(&four); // {1, 2, 3, 4, 5}

    {
        var it = list.first;
        var index: u32 = 1;
        while (it) |node| : (it = node.next) {
            std.debug.print("node : {any}\n", .{node.data});
            index += 1;
        }
    }

    for (root.value.animations) |animation| {
        std.debug.print("animation id : {s}, total animations : {}\n", .{animation.id, animation.frames.len});
        for (animation.frames) |frame| {
            std.debug.print("\tframe id : {d}\n", .{frame.id});
        }
    }
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
