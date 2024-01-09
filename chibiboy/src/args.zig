const clap = @import("clap");
const std = @import("std");
const builtin = @import("builtin");

const fmt = std.fmt;
const io = std.io;

const assert = std.debug.assert;

const errors = @import("Errors.zig");

pub const Args = struct {
    args_allocated: std.process.ArgIterator,
    rom: []const u8 = undefined,
    headless: bool = false,
    silent: bool = false,
    debug_cpu: bool = false,
    debug_gpu: bool = false,
    debug_apu: bool = false,
    debug_ram: bool = false,
    frames: u32 = undefined,
    profile: u32 = undefined,
    turbo: bool = false,

    pub fn init(allocator: std.mem.Allocator) !Args {
        var args = try std.process.argsWithAllocator(allocator);
        errdefer args.deinit();

        // Skip argv[0] which is the name of this executable
        assert(args.skip());

        var final_args = Args{
            .args_allocated = args,
            .rom = undefined,
            .headless = false,
            .silent = false,
            .debug_cpu = false,
            .debug_gpu = false,
            .debug_apu = false,
            .debug_ram = false,
            .frames = 0,
            .profile = 0,
            .turbo = false,
        };

        while (args.next()) |arg| {
            if (std.mem.eql(u8, "--rom", arg)) {
                if (args.next()) |inner_arg| {
                    final_args.rom = inner_arg;
                }
            } else if (std.mem.eql(u8, "-H", arg)) {
                final_args.headless = true;
            } else if (std.mem.eql(u8, "-S", arg)) {
                final_args.silent = true;
            } else if (std.mem.eql(u8, "-c", arg)) {
                final_args.debug_cpu = true;
            } else if (std.mem.eql(u8, "-g", arg)) {
                final_args.debug_gpu = true;
            } else if (std.mem.eql(u8, "-a", arg)) {
                final_args.debug_apu = true;
            } else if (std.mem.eql(u8, "-r", arg)) {
                final_args.debug_ram = true;
            } else if (std.mem.eql(u8, "-f", arg)) {
                if (args.next()) |inner_arg| {
                    final_args.frames = try std.fmt.parseInt(u32, inner_arg, 10);
                }
            } else if (std.mem.eql(u8, "-p", arg)) {
                if (args.next()) |inner_arg| {
                    final_args.profile = try std.fmt.parseInt(u32, inner_arg, 10);
                }
            } else if (std.mem.eql(u8, "-t", arg)) {
                final_args.turbo = true;
            }
        }

        return final_args;
    }

    pub fn deinit(self: *Args) void {
        self.args_allocated.deinit();
    }

    pub fn parse_arguments() !Args {
        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        defer _ = gpa.deinit();

        const params = (
            \\-h, --help             Display this help and exit
            \\-H, --headless         Disable GUI
            \\-S, --silent           Disable Sound
            \\-c, --debug-cpu        Debug CPU
            \\-g, --debug-gpu        Debug GPU
            \\-a, --debug-apu        Debug APU
            \\-r, --debug-ram        Debug RAM
            \\-f, --frames <u32>     Exit after N frames
            \\-p, --profile <u32>    Exit after N seconds
            \\-t, --turbo            No sleep
            \\-v, --version          Show build info
            \\-s, --string <str>     ROM filename
            \\
        );
        _ = params; // autofix

        var final_args = Args{};

        final_args.rom = "default";

        return final_args;
    }
};

const splitSeq = std.mem.splitSequence;
