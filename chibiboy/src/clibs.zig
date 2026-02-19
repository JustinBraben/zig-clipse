// pub usingnamespace @cImport({
//     @cInclude("SDL2/SDL.h");
// });

const std = @import("std");
const c = @cImport({
    // REQUIRED only for GLFW CreateWindowSurface.
    // @cDefine("GLFW_INCLUDE_VULKAN", {});
    // @cInclude("GLFW/glfw3.h");
    // @cDefine("STB_IMAGE_IMPLEMENTATION", {});
    // @cInclude("stb/stb_image.h");
    @cInclude("SDL3/SDL.h");
});
