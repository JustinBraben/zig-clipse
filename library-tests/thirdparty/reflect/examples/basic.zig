const reflect = @import("reflect");
const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const num_u8_example: u8 = 2;
    const bool_example: bool = true;
    const float_f32_example: f32 = 2.0;

    try reflect.printObject(@TypeOf(num_u8_example), num_u8_example);
    try reflect.printObject(@TypeOf(bool_example), bool_example);
    try reflect.printObject(@TypeOf(float_f32_example), float_f32_example);
}
