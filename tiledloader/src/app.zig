const std = @import("std");
const c = @import("clibs.zig");

const log = std.log.scoped(.App);

pub const App = struct {
    window: ?*c.SDL_Window,
    renderer: ?*c.SDL_Renderer,
    framebuffer: ?*c.SDL_Texture,
};
