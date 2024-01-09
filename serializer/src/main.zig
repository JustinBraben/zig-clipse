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

    const person_type = @TypeOf(p2);
    switch (@typeInfo(person_type)) {
        .Struct => print("person is a struct\n", .{}),
        else => print("person is not a struct\n"),
    }

    print("Type of : {}\n", .{person_type});

    printTypeName(@TypeOf(p1));

    printFields(@TypeOf(p1));

    const my_struct_info = getStructInfo(@TypeOf(p1));
    printFields(@TypeOf(my_struct_info));

    // const s_info = getStructInfo(@TypeOf(p1));
    // _ = s_info; // autofix

    // const p1_name_field_info = std.meta.fieldInfo(@TypeOf(p1), .name);
    // std.debug.print("p1 name field info : {}\n", .{p1_name_field_info});

    // const p1_field_info = std.meta.fieldIndex(@TypeOf(p1), "age");
    // std.debug.print("Field_info : {any}\n", .{p1_field_info});
}

fn getStructInfo(comptime T: type) StructInfo {
    var result: StructInfo = undefined;

    result.name = @typeName(T);

    // inline for (std.meta.fields(T)) |field| {
    //     const field_info: [][]const u8 = .{ field.name, field.type };
    //     result.field_properties = field_info;
    // }

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
