const std = @import("std");
const c = @cImport({
    @cInclude("SDL2/SDL.h");
});

pub const Display = struct {
    const Self = @This();

    window: *c.SDL_Window,
    open: bool,

    pub fn init(title: [*]const u8, width: i32, height: i32) !Self {
        if (c.SDL_Init(c.SDL_INIT_VIDEO | c.SDL_INIT_AUDIO) != 0) {
            return error.SDLInitializationFailed;
        }

        const window = c.SDL_CreateWindow(
            title,
            c.SDL_WINDOWPOS_UNDEFINED,
            c.SDL_WINDOWPOS_UNDEFINED,
            width,
            height,
            c.SDL_WINDOW_SHOWN,
        ) orelse {
            c.SDL_Quit();
            return error.SDLWindowCreationFailed;
        };

        return Self{
            .window = window,
            .open = true,
        };
    }

    pub fn deinit(self: *Self) void {
        std.debug.print("Display quit has been called\n", .{});
        c.SDL_DestroyWindow(self.window);
        c.SDL_Quit();
    }

    pub fn input(self: *Self) void {
        var event: c.SDL_Event = undefined;
        while (c.SDL_PollEvent(&event) != 0) {
            switch (event.type) {
                c.SDL_QUIT => {
                    self.open = false;
                },
                else => {},
            }
        }
    }
};
