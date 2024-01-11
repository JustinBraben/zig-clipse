const std = @import("std");
const Person = @import("person.zig").Person;
const print = std.debug.print;

const StructInfo = struct {
    name: []const u8,
    field_properties: [][]const u8,
};

pub fn main() !void {
    print("Hello\n", .{});

    const p1 = Person{
        .name = "Landon",
        .age = 22,
        .isStudent = true,
    };

    comptime var p2 = Person{
        .name = "Steve",
        .age = 27,
        .isStudent = false,
    };
    p2.age = 28;

    // print("TypeOf p1 : {}\n", .{@TypeOf(p1)});

    // const person_type = @TypeOf(p2);
    // switch (@typeInfo(person_type)) {
    //     .Struct => print("person is a struct\n", .{}),
    //     else => print("person is not a struct\n"),
    // }

    // print("Type of : {}\n", .{person_type});

    // printTypeName(@TypeOf(p1));

    // printFields(@TypeOf(p1));

    // const my_struct_info = getStructInfo(@TypeOf(p1));
    // printFields(@TypeOf(my_struct_info));

    const serial_data = try serialize(@TypeOf(p1), p1);
    print("serial data : {any}\n", .{serial_data});

    // const deserial_data = deserialize(@TypeOf(p1), serial_data);
    // _ = deserial_data; // autofix
}

fn getStructInfo(comptime T: type) StructInfo {
    var result: StructInfo = undefined;

    result.name = @typeName(T);

    return result;
}

fn printTypeName(comptime T: type) void {
    std.debug.print("Type name for object is {s}\n", .{@typeName(T)});
}

fn printFields(comptime T: type) void {
    inline for (std.meta.fields(T)) |field| {
        std.debug.print("Field Name \t: {s}\n", .{field.name});
        std.debug.print("Field type \t: {}\n", .{field.type});
        std.debug.print("\n", .{});
    }
}

fn serialize(comptime T: type, value: T) ![]const u8 {
    var buf: [255]u8 = undefined;
    var fbs = std.io.fixedBufferStream(&buf);
    const stream = fbs.writer();

    // var buffer: [1024]u8 = undefined;
    // var fbs = std.io.fixedBufferStream(&buffer);
    // const stream = fbs.writer();

    const info = @typeInfo(T);
    switch (info) {
        .Struct => |struct_info| {
            inline for (struct_info.fields) |field| {
                const field_value = @field(value, field.name);
                try stream.print("{s}: {any}\n", .{ field.name, field_value });
                print("serializing {s}: {any}\n", .{ field.name, field_value });
            }
        },
        else => {},
    }

    return stream.context.getWritten();
}

fn deserialize(comptime T: type, serialized: []const u8) T {
    var value: T = undefined;
    var it = std.mem.splitScalar(u8, serialized, '\n');

    while (it.next()) |line| {
        var parts = std.mem.splitSequence(u8, line, ": ");
        const field_name = parts.next() orelse "";
        const field_value_str = parts.next() orelse "";

        const field_value = @as(@TypeOf(@field(value, field_name)), @intCast(std.fmt.parseInt(i32, field_value_str, 10) catch 0));
        @field(value, field_name) = field_value;
    }

    return value;
}
