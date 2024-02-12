const std = @import("std");
const c = @import("clibs.zig");

const vki = @import("VkInitializers.zig");

const log = std.log.scoped(.VkEngine);

const window_extent = c.VkExtent2D{ .width = 1600, .height = 900 };
const window_flags = c.SDL_WINDOW_VULKAN | c.SDL_WINDOW_RESIZABLE;

const VK_NULL_HANDLE = null;

const vk_alloc_cbs: ?*c.VkAllocationCallbacks = null;

pub const VkEngine = struct {
    allocator: std.mem.Allocator = undefined,

    // Vulkan data
    instance: c.VkInstance = VK_NULL_HANDLE,
    debug_messenger: c.VkDebugUtilsMessengerEXT = VK_NULL_HANDLE,

    physical_device: c.VkPhysicalDevice = VK_NULL_HANDLE,
    physical_device_properties: c.VkPhysicalDeviceProperties = undefined,

    device: c.VkDevice = VK_NULL_HANDLE,
    surface: c.VkSurfaceKHR = VK_NULL_HANDLE,

    window: *c.SDL_Window = undefined,

    frame_number: u64 = 0,

    is_initialized: bool = false,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) !VkEngine {
        check_sdl(c.SDL_Init(c.SDL_INIT_VIDEO));

        // Init SDL
        if (c.SDL_Init(c.SDL_INIT_VIDEO) != 0) {
            std.debug.print("Detected SDL error: {s}", .{c.SDL_GetError()});
            @panic("SDL error");
        }

        const window = c.SDL_CreateWindow(
            "Vulkan",
            window_extent.width,
            window_extent.height,
            window_flags
        ) orelse @panic("Failed to create SDL window");

        _ = c.SDL_ShowWindow(window);

        var engine = Self{
            .window = window,
            .allocator = allocator,
            .frame_number = 0,
            .is_initialized = false,
        };

        try engine.init_instance();

        // Create the window surface
        check_sdl_bool(c.SDL_Vulkan_CreateSurface(window, engine.instance, vk_alloc_cbs, &engine.surface));

        try engine.init_device();

        return engine;
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

    fn init_instance(self: *VkEngine) !void {
        var sdl_required_extension_count: u32 = undefined;
        const sdl_extensions = c.SDL_Vulkan_GetInstanceExtensions(&sdl_required_extension_count);
        const sdl_extension_slice = sdl_extensions[0..sdl_required_extension_count];

        // Instance creation, and optional debug utils
        const instance = vki.create_instance(std.heap.page_allocator, .{
            .application_name = "VkEndeavors",
            .application_version = c.VK_MAKE_VERSION(0, 1, 0),
            .engine_name = "VkEndeavors",
            .engine_version = c.VK_MAKE_VERSION(0, 1, 0),
            .api_version = c.VK_MAKE_VERSION(1, 1, 0),
            .debug = true,
            .required_extensions = sdl_extension_slice,
        }) catch |err| {
            log.err("Failed to create vulkan instance with error: {s}", .{@errorName(err)});
            unreachable;
        };

        self.instance = instance.handle;
        self.debug_messenger = instance.debug_messenger;
    }

    fn init_device(self: *VkEngine) !void {
        // Physical device selection
        const required_device_extensions: []const [*c]const u8 = &.{
            "VK_KHR_swapchain"
        };

        const physical_device = vki.select_physical_device(std.heap.page_allocator, self.instance, .{
            .min_api_version = c.VK_MAKE_VERSION(1, 1, 0),
            .required_extensions = required_device_extensions,
            .surface = self.surface,
            .criteria = .PreferDiscrete,
        }) catch |err| {
            log.err("Failed to select physical device with error: {s}\n", .{@errorName(err)});
            unreachable;
        };

        self.physical_device = physical_device.handle;
        self.physical_device_properties = physical_device.properties;

        // });
    }
};

fn check_sdl(res: c_int) void {
    if (res != 0) {
        log.err("Detected SDL error: {s}\n", .{c.SDL_GetError()});
        @panic("SDL error");
    }
}

fn check_sdl_bool(res: c.SDL_bool) void {
    if (res != c.SDL_TRUE) {
        log.err("Detected SDL error: {s}\n", .{c.SDL_GetError()});
        @panic("SDL error");
    }
}
