pub const SDL = @cImport({
    @cDefine("SDL_USE_BUILTIN_OPENGL_DEFINITIONS", "1");
    @cInclude("SDL2/SDL.h");
});