const std = @import("std");
const c = @import("clibs.zig");

const vki = @import("VkInitializers.zig");

const log = std.log.scoped(.vulkan_engine);

pub const VkEngine = struct {
    allocator: std.mem.Allocator = undefined,

    window: *c.SDL_Window = undefined,

    frame_number: u64 = 0,

    is_initialized: bool = false,

    pub fn init(allocator: std.mem.Allocator) !VkEngine {
        // Init SDL
        if (c.SDL_Init(c.SDL_INIT_VIDEO) != 0) {
            std.debug.print("Detected SDL error: {s}", .{c.SDL_GetError()});
            @panic("SDL error");
        }

        const window_flags = c.SDL_WINDOW_VULKAN | c.SDL_WINDOW_RESIZABLE;

        const window_extent = c.VkExtent2D{ .width = 1600, .height = 900 };

        const window = c.SDL_CreateWindow("Vulkan Engine", window_extent.width, window_extent.height, window_flags) orelse @panic("Failed to create SDL window");

        _ = c.SDL_ShowWindow(window);

        // init_instance();

        return VkEngine{ .allocator = allocator, .window = window, .frame_number = 0, .is_initialized = true };
    }

    pub fn draw(self: *VkEngine) void {
        // TODO: draw function
        _ = self; // autofix
    }

    pub fn run(self: *VkEngine) void {
        _ = self; // autofix
        var quit = false;
        var event: c.SDL_Event = undefined;
        while (!quit) {
            while (c.SDL_PollEvent(&event) != 0) {
                if (event.type == c.SDL_EVENT_QUIT) {
                    quit = true;
                } else if (event.type == c.SDL_EVENT_KEY_DOWN) {
                    switch (event.key.keysym.scancode) {
                        c.SDL_SCANCODE_SPACE => {
                            std.debug.print("Space pressed\n", .{});
                        },
                        c.SDL_SCANCODE_ESCAPE => {
                            quit = true;
                        },
                        else => {},
                    }
                }
            }
        }
    }

    pub fn deinit(self: *VkEngine) void {
        c.SDL_DestroyWindow(self.window);
    }

    fn init_instance(self: *VkEngine) void {
        _ = self; // autofix
    }
};
