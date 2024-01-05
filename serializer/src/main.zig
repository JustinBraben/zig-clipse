const std = @import("std");
const Person = @import("person.zig").Person;
const print = std.debug.print;

pub fn main() !void {
    print("Hello\n", .{});

    const p1 = Person{
        .name = "Landon",
        .age = 22,
        .isStudent = true,
    };

    //const typeInfo = @typeInfo(@TypeOf(p1));

    print("TypeOf p1 : {}\n", .{@TypeOf(p1)});

    const p1TypeInfo = @typeInfo(Person);
    _ = p1TypeInfo; // autofix

    //print("p1 type info : {any}\n", .{p1TypeInfo});

    // // Iterate over each field in the struct
    // for (typeInfo.fields) |field| {
    //     print("  - {} ({s})\n", .{ field.name, field.type.name });
    // }
}
