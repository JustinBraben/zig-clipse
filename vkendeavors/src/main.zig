const std = @import("std");
const VkEngine = @import("VkEngine.zig").VkEngine;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() == .leak) {
        @panic("Leaked memory");
    };

    var buf: [std.fs.max_path_bytes]u8 = undefined;
	const path = try std.fs.realpath(".", &buf);
	std.log.info("Running from: {s}", .{ path });

    var engine = try VkEngine.init(gpa.allocator());
    defer engine.deinit();

    engine.run();
}
