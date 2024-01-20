const std = @import("std");
const c = @import("clibs.zig");

pub const App = struct {
    window: ?*c.SDL_Window,
    renderer: ?*c.SDL_Renderer,
    framebuffer: ?*c.SDL_Texture,
};
