const std = @import("std");

pub const Person = struct {
    name: []const u8,
    age: u32,
    isStudent: bool,
};
