const std = @import("std");
const mem = std.mem;
const Allocator = std.mem.Allocator;

pub fn Queue(comptime T: type) type {
    return QueueAligned(T, null);
}

pub fn QueueAligned(comptime T: type, comptime alignment: ?u29) type {
    if (alignment) |a| {
        if (a == @alignOf(T)) {
            return QueueAligned(T, null);
        }
    }

    return struct {
        const Self = @This();
        pub const Slice = if (alignment) |a| ([]align(a) T) else []T;

        items: Slice,
        capacity: usize,
        allocator: Allocator,

        pub fn init(allocator: Allocator) Self {
            return Self{
                .items = &[_]T{},
                .capacity = 0,
                .allocator = allocator,
            };
        }

        pub fn deinit(self: Self) void {
            if (@sizeOf(T) > 0) {
                self.allocator.free(self.allocatedSlice());
            }
        }

        /// Returns a slice of all the items plus the extra capacity, whose memory
        /// contents are `undefined`.
        fn allocatedSlice(self: Self) []T {
            // `items.len` is the length, not the capacity.
            return self.items.ptr[0..self.capacity];
        }

        fn siftDown(self: *Self) void {
            const target_element = self.front();

            if (target_element) |target_elem| {
                var index: usize = 0;
                while (index < self.items.len) : (index += 1) {
                    const new_val = if (index + 1 >= self.items.len) break else self.items[index + 1];
                    self.items[index] = new_val;
                }

                // sets last element in items to the first element
                // first element set to last in pop()
                self.items[self.items.len - 1] = target_elem;
            }
        }

        pub fn front(self: *Self) ?T {
            return if (self.items.len > 0) self.items[0] else null;
        }

        pub fn back(self: *Self) ?T {
            return if (self.items.len > 0) self.items[self.items.len - 1] else null;
        }

        pub fn empty(self: *Self) bool {
            return self.items.len == 0;
        }

        pub fn size(self: *Self) usize {
            return self.items.len;
        }

        pub fn push(self: *Self, item: T) Allocator.Error!void {
            try self.ensureUnusedCapacity(1);

            self.addUnchecked(item);
        }

        fn addUnchecked(self: *Self, item: T) void {
            self.items.len += 1;
            self.items[self.items.len - 1] = item;
        }

        /// Add each element in `items` to the queue.
        pub fn push_slice(self: *Self, items: []const T) !void {
            try self.ensureUnusedCapacity(items.len);
            for (items) |entry| {
                self.addUnchecked(entry);
            }
        }

        pub fn pop(self: *Self) ?T {
            if (self.items.len < 1) {
                return null;
            }

            const last = self.items[self.items.len - 1];
            const item = self.front();

            // Put the last element at the front
            // since items.len is being cleaved
            self.items[0] = last;
            self.items.len -= 1;

            siftDown(self);

            return item;
        }

        pub fn pop_back(self: *Self) ?T {
            if (self.items.len < 1) {
                return null;
            }
            const last = self.items[self.items.len - 1];
            self.items.len -= 1;

            return last;
        }

        /// Ensure that the queue can fit at least `new_capacity` items.
        pub fn ensureTotalCapacity(self: *Self, new_capacity: usize) !void {
            var better_capacity = self.capacity;
            if (better_capacity >= new_capacity) return;
            while (true) {
                better_capacity += better_capacity / 2 + 8;
                if (better_capacity >= new_capacity) break;
            }
            const old_memory = self.allocatedSlice();
            const new_memory = try self.allocator.realloc(old_memory, better_capacity);
            self.items.ptr = new_memory.ptr;
            self.capacity = new_memory.len;
        }

        /// Ensure that the queue can fit at least `additional_count` **more** item.
        pub fn ensureUnusedCapacity(self: *Self, additional_count: usize) !void {
            return self.ensureTotalCapacity(self.items.len + additional_count);
        }
    };
}