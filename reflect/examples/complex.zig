const reflect = @import("reflect");
const std = @import("std");

const Vehicle = struct {
    allocator: std.mem.Allocator,
    name: []const u8,
    wheels: u8,
    pub fn init(allocator: std.mem.Allocator, name: []const u8, wheels: u8) !Vehicle {
        return Vehicle{
            .allocator = allocator,
            .name = allocator.dupe(u8, name),
            .wheels = wheels,
        };
    }
    pub fn deinit(self: *Vehicle) void {
        std.debug.assert(self.allocator != null);
        self.allocator.free(self.name);
    }
};

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
