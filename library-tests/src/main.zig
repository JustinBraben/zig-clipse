const std = @import("std");
const clap = @import("clap");
const io = std.io;
const fs = std.fs;
const mem = std.mem;
const process = std.process;

const c = @import("clibs.zig");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    var args_it = try std.process.ArgIterator.initWithAllocator(allocator);
    defer args_it.deinit();

    _ = args_it.skip(); // skip exe name

    std.debug.print("\nHello\n", .{});
}
