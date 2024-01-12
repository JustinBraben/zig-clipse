const reflect = @import("reflect");
const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const Person = struct {
        name: []const u8,
        age: u8,
    };

    const p1 = Person{
        .name = "John",
        .age = 20,
    };

    try reflect.printObject(@TypeOf(p1), p1);
}
