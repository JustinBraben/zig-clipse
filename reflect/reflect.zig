const std = @import("std");

const builtin = std.builtin;
const debug = std.debug;
const heap = std.heap;
const io = std.io;
const math = std.math;
const mem = std.mem;
const meta = std.meta;
const process = std.process;
const testing = std.testing;

test "reflect" {
    testing.refAllDecls(@This());
}

pub fn printObject(comptime T: type, value: T) !void {
    _ = value; // autofix
    validateType(T);
}

fn validateType(comptime T: type) void {
    switch (@typeInfo(T)) {
        .ErrorSet, .ErrorUnion => @compileError("Unsupported top level type " ++ @typeName(T) ++ ". Wrap into struct to serialize these."),
        else => {},
    }
}

test "type validating" {
    const MyNumberError = error{ TooSmall, TooBig };
    const errset = error{ A, B, C };
    var errunion: MyNumberError!u8 = 5;
    errunion = MyNumberError.TooSmall;

    std.debug.print("Type of errorset : {}\n", .{@TypeOf(errset)});
    std.debug.print("Type of errunion : {}\n", .{@TypeOf(errunion)});

    debug.assert(@typeInfo(errset) == .ErrorSet);
    debug.assert(@typeInfo(@TypeOf(errunion)) == .ErrorUnion);
}
