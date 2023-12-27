const std = @import("std");
const args = @import("clipse/args.zig").args;
const User = @import("clipse/data_structures/user.zig").User;
const IntList = @import("clipse/data_structures/IntList.zig").IntList;
const print = std.debug.print;

const testing = std.testing;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.testing.expect(gpa.deinit() != .leak) catch @panic("memory leak");
    const allocator = gpa.allocator();

    var argObject = try args.init(allocator);
    defer argObject.deinit();

    try argObject.parseCommandLine();

    // var list = try IntList.init(allocator);
    // defer list.deinit();

    // for (0..10) |i| {
    //     try list.add(@intCast(i));
    // }

    // std.debug.print("{any}\n", .{list.items[0..list.pos]});
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}

test "IntList: add" {
    // We're using testing.allocator here!
    var list = try IntList.init(testing.allocator);
    defer list.deinit();

    for (0..5) |i| {
        try list.add(@intCast(i + 10));
    }

    try testing.expectEqual(@as(usize, 5), list.pos);
    try testing.expectEqual(@as(i64, 10), list.items[0]);
    try testing.expectEqual(@as(i64, 11), list.items[1]);
    try testing.expectEqual(@as(i64, 12), list.items[2]);
    try testing.expectEqual(@as(i64, 13), list.items[3]);
    try testing.expectEqual(@as(i64, 14), list.items[4]);
}
