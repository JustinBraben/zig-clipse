const std = @import("std");
const c = @import("clibs.zig");

pub const VkEngine = struct {
    allocator: std.mem.Allocator = undefined,
    window: *c.SDL_Window = undefined,

    pub fn init(allocator: std.mem.Allocator) !VkEngine {
        // Init SDL
        if (c.SDL_Init(c.SDL_INIT_VIDEO) != 0) {
            std.debug.print("Detected SDL error: {s}", .{c.SDL_GetError()});
            @panic("SDL error");
        }

        const window_flags = c.SDL_WINDOW_VULKAN | c.SDL_WINDOW_RESIZABLE;

        const window_extent = c.VkExtent2D{ .width = 1600, .height = 900 };

        const window = c.SDL_CreateWindow("Vulkan Engine", window_extent.width, window_extent.width, window_flags) orelse @panic("Failed to create SDL window");

        _ = c.SDL_ShowWindow(window);

        return VkEngine{ .allocator = allocator, .window = window };
    }

    pub fn deinit(self: *VkEngine) void {
        c.SDL_DestroyWindow(self.window);
    }
};
