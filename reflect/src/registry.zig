const std = @import("std");
const builtin = @import("builtin");
const assert = std.debug.assert;

const Init = @import("init.zig").Init;
const Property = @import("property.zig").Property;
const Method = @import("method.zig").Method;

const Registry = struct {
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) !Registry {
        return .{
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Registry) void {
        _ = self; // autofix
        // TODO: free all the things
    }
};
