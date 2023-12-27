const std = @import("std");
const assert = std.debug.assert;
const fmt = std.fmt;

pub const Args = struct {
    args_allocated: std.process.ArgIterator,

    pub fn deinit(self: *Args, allocator: std.mem.Allocator) void {
        _ = allocator; // autofix

        self.args_allocated.deinit();
    }

    pub fn init(allocator: std.mem.Allocator) !Args {
        var args = try std.process.argsWithAllocator(allocator);
        errdefer args.deinit(allocator);

        // Skip argv[0] which is the name of this executable
        assert(args.skip());

        return Args{ .args_allocated = args };
    }
};
