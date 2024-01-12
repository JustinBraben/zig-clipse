const reflect = @import("reflect");
const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const num1: u8 = 2;

    try reflect.printObject(@TypeOf(num1), num1);
}
