const std = @import("std");

pub fn parseArgs(allocator: *std.mem.Allocator) !std.ArrayList(!u8) {
    // Parse args into string array (error union needs 'try')
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    return args;
}
