const std = @import("std");
const VkEngine = @import("VkEngine.zig").VkEngine;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() == .leak) {
        @panic("Leaked memory");
    };

    var cwd_buff: [1024]u8 = undefined;
    const cwd = std.os.getcwd(cwd_buff[0..]) catch @panic("cwd_buff too small");
    std.log.info("Running from: {s}", .{ cwd });

    var engine = try VkEngine.init(gpa.allocator());
    defer engine.deinit();

    engine.run();
}
