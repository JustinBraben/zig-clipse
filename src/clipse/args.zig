const std = @import("std");
const Allocator = std.mem.Allocator;

const print = std.debug.print;

pub const args = struct {
    allocator: std.mem.Allocator,
    arguments: [][]u8,

    pub fn init(allocator: Allocator) !args {
        return .{
            .allocator = allocator,
            .arguments = undefined,
        };
    }

    pub fn deinit(self: *args) void {
        _ = self; // autofix

        // Free any resources associated with arguments if needed
    }

    pub fn parseCommandLine(self: *args) !void {
        const argv = try std.process.argsAlloc(self.allocator);
        defer std.process.argsFree(self.allocator, argv);

        // Start on index 1, as index 0 will be the program itself
        var i: usize = 1;

        while (i < argv.len) : (i += 1) {
            const arg = argv[i];
            //self.arguments.append(arg);
            print("Arg {} is : {s}\n", .{ i, arg });
        }
    }
};
