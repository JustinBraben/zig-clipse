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
    validateType(T);
    try printObjectRecursive(T, value);
}

fn printObjectRecursive(comptime T: type, value: T) !void {
    //const typeInfo = @typeInfo(T);
    switch (@typeInfo(T)) {
        //.Void => std.debug.print("{s} : void\n", .{@typeName(T)}),
        .Int,
        .Bool,
        .Float,
        => std.debug.print("{s}\t: {}\n", .{ @typeName(T), value }),
        else => std.debug.print("Did not recognize type\n", .{}),
        // .Void => std.debug.print("{s} : void\n", .{@typeName(typeInfo), }),
        // .Bool => std.debug.print("{s} : {}\n", .{@typeName(typeInfo), value}),
        // .Int => std.debug.print("{s} : {}\n", .{@typeName(typeInfo), value}),
        // .Float => std.debug.print("{}", .{value}),
        // .Pointer => std.debug.print("{}", .{value}),
        // .Fn => std.debug.print("{}", .{value}),
        // .Enum => std.debug.print("{}", .{value}),
        // .Struct => printStruct(T, value),
        // .Union => printUnion(T, value),
        // .ErrorSet => printErrorSet(T, value),
        // .ErrorUnion => printErrorUnion(T, value),
        // .Array => printArray(T, value),
        // .Vector => printVector(T, value),
        // .Maybe => printMaybe(T, value),
        // .Slice => printSlice(T, value),
        // .AnyFrame => std.debug.print("{}", .{value}),
        // .AnyError => std.debug.print("{}", .{value}),
        // .Type => std.debug.print("{}", .{value}),
        // .Opaque => std.debug.print("{}", .{value}),
        // .Unreachable => std.debug.print("{}", .{value}),
        // .PureError => std.debug.print("{}", .{value}),
        // .CompileError => std.debug.print("{}", .{value}),
        // .EnumTag => std.debug.print("{}", .{value}),
        // .ArgTuple => std.debug.print("{}", .{value}),
        // .Other => std.debug.print("{}", .{value}),
    }
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

    //std.log.info("Type of errorset : {}\n", .{@TypeOf(errset)});
    //std.debug.print("Type of errorset : {}\n", .{@TypeOf(errset)});
    //std.debug.print("Type of errunion : {}\n", .{@TypeOf(errunion)});

    debug.assert(@typeInfo(errset) == .ErrorSet);
    debug.assert(@typeInfo(@TypeOf(errunion)) == .ErrorUnion);
}
