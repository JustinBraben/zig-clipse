const std = @import("std");
const Allocator = std.mem.Allocator;

pub const IntList = struct {
    pos: usize,
    items: []i64,
    allocator: Allocator,

    pub fn init(allocator: Allocator) !IntList {
        return .{
            .pos = 0,
            .allocator = allocator,
            .items = try allocator.alloc(i64, 4),
        };
    }

    pub fn deinit(self: IntList) void {
        self.allocator.free(self.items);
    }

    pub fn add(self: *IntList, value: i64) !void {
        const pos = self.pos;
        const len = self.items.len;

        if (pos == len) {
            // we've run out of space
            // create a new slice that's twice as large
            var larger = try self.allocator.alloc(i64, len * 2);

            // copy the items we previously added to our new space
            @memcpy(larger[0..len], self.items);

            // Added code
            // free the previous allocation
            self.allocator.free(self.items);

            self.items = larger;
        }

        self.items[pos] = value;
        self.pos = pos + 1;
    }
};
