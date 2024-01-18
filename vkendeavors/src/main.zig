const std = @import("std");
const VkEngine = @import("VkEngine.zig").VkEngine;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() == .leak) {
        @panic("Leaked memory");
    };

    var engine = try VkEngine.init(gpa.allocator());
    defer engine.deinit();

    engine.run();
}
