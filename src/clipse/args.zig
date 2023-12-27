const std = @import("std");
const Allocator = std.mem.Allocator;

const print = std.debug.print;

pub const args = struct {
    allocator: std.mem.Allocator,
    //arguments: []u8,
    arguments_list: std.ArrayList(u8),

    pub fn init(allocator: Allocator) !args {
        return .{ .allocator = allocator, .arguments_list = std.ArrayList(u8).init(allocator) };
    }

    pub fn deinit(self: *args) void {
        // Free any resources associated with arguments if needed
        //self.allocator.free(self.arguments);
        self.arguments_list.deinit();
    }

    pub fn parseCommandLine(self: *args) !void {
        const argv = try std.process.argsAlloc(self.allocator);
        defer std.process.argsFree(self.allocator, argv);

        // Start on index 1, as index 0 will be the program itself
        var i: usize = 1;

        //print("argv : {any}\n", .{argv});

        while (i < argv.len) : (i += 1) {
            const arg = argv[i];
            //self.arguments.append(arg);
            try self.arguments_list.appendSlice(argv[i]);
            print("Arg {} is : {s}\n", .{ i, arg });
        }
    }

    pub fn printArgumentsList(self: *args) void {
        var i: usize = 0;
        while (i < self.arguments_list.items.len) : (i += 1) {
            print("Arg {any} is : {s}\n", .{ i, self.arguments_list.items[i] });
        }
    }
};
