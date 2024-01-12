const reflect = @import("reflect");
const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var num_i32_example: i32 = 0;
    num_i32_example = 1;

    const num_u8_example: u8 = 2;
    const bool_example: bool = true;
    const float_f32_example: f32 = 2.0;
    const string_example: []const u8 = "hello world";
    const slice_u64_example: []const u64 = &[_]u64{ 1, 2, 3 };
    const ptr_i32_example: *i32 = &num_i32_example;
    const arr_u64_example: [3]u64 = [_]u64{ 1, 2, 3 };
    const arr_u8_example: [3]u8 = [_]u8{ 1, 2, 3 };

    const Person = struct {
        name: []const u8,
        age: u8,
    };

    const p1 = Person{
        .name = "John",
        .age = 20,
    };

    try reflect.printObject(@TypeOf(num_u8_example), num_u8_example);
    try reflect.printObject(@TypeOf(bool_example), bool_example);
    try reflect.printObject(@TypeOf(float_f32_example), float_f32_example);
    try reflect.printObject(@TypeOf(string_example), string_example);
    try reflect.printObject(@TypeOf(slice_u64_example), slice_u64_example);
    try reflect.printObject(@TypeOf(ptr_i32_example), ptr_i32_example);
    try reflect.printObject(@TypeOf(arr_u64_example), arr_u64_example);
    try reflect.printObject(@TypeOf(arr_u8_example), arr_u8_example);
    try reflect.printObject(@TypeOf(p1), p1);
}
