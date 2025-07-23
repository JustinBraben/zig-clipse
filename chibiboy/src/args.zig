const clap = @import("clap");
const std = @import("std");
const Allocator = std.mem.Allocator;
const builtin = @import("builtin");

const errors = @import("errors.zig");

const io = std.io;

pub const Args = struct {
    allocator: Allocator,
    rom: []const u8,
    headless: bool,
    silent: bool,
    debug_cpu: bool,
    debug_gpu: bool,
    debug_apu: bool,
    debug_ram: bool,
    frames: u32,
    profile: u32,
    turbo: bool,

    pub fn parse_args(ally: Allocator) !Args {
        const params = comptime clap.parseParamsComptime(
            \\-h, --help             Display this help and exit.
            \\-H, --headless         Disable GUI.
            \\-S, --silent           Disable Sound.
            \\-c, --debug-cpu        Debug CPU.
            \\-g, --debug-gpu        Debug GPU.
            \\-a, --debug-apu        Debug APU.
            \\-r, --debug-ram        Debug RAM.
            \\-f, --frames <U32>     Exit after N frames.
            \\-p, --profile <U32>    Exit after N seconds.
            \\-t, --turbo            No sleep().
            \\-v, --version          Show build info.
            \\<STR>...               ROM filename.
        );

        // Declare our own parsers which are used to map the argument strings to other
        // types.
        const parsers = comptime .{
            .STR = clap.parsers.string,
            .FILE = clap.parsers.string,
            .U32 = clap.parsers.int(u32, 10),
        };

        var diag = clap.Diagnostic{};
        var res = clap.parse(clap.Help, &params, parsers, .{
            .diagnostic = &diag,
            .allocator = ally,
        }) catch |err| {
            // Report useful error and exit
            diag.report(io.getStdErr().writer(), err) catch {};
            return err;
        };
        defer res.deinit();

        if (res.args.version != 0) {
            return errors.ControlledExit.Help;
        }
        
        if (res.args.help != 0) {
            try clap.help(std.io.getStdErr().writer(), clap.Help, &params, .{});
            return errors.ControlledExit.Help;
        }

        var frames: u32 = 0;
        if (res.args.frames) |n|
            frames = n;

        var profile: u32 = 0;
        if (res.args.profile) |n|
            profile = n;

        var rom: []const u8 = "";
        for (res.positionals[0]) |pos|{
            rom = try ally.dupe(u8, pos);
            // _ = &rom;
            // std.debug.print("{s}\n", .{pos});
        }

        return Args{
            .allocator = ally,
            .rom = rom,
            .headless = res.args.headless != 0,
            .silent = res.args.silent != 0,
            .debug_cpu = res.args.@"debug-cpu" != 0,
            .debug_gpu = res.args.@"debug-gpu" != 0,
            .debug_apu = res.args.@"debug-apu" != 0,
            .debug_ram = res.args.@"debug-ram" != 0,
            .frames = frames,
            .profile = profile,
            .turbo = res.args.turbo != 0,
        };
    }

    pub fn deinit(self: *Args) void {
        self.allocator.free(self.rom);
    }
};