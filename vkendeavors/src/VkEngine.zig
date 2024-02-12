const std = @import("std");
const c = @import("clibs.zig");

const vki = @import("VkInitializers.zig");
const check_vk = vki.check_vk;

const log = std.log.scoped(.VkEngine);

const window_extent = c.VkExtent2D{ .width = 1600, .height = 900 };
const window_flags = c.SDL_WINDOW_VULKAN | c.SDL_WINDOW_RESIZABLE;

const VK_NULL_HANDLE = null;

const vk_alloc_cbs: ?*c.VkAllocationCallbacks = null;

pub const AllocatedBuffer = struct {
    buffer: c.VkBuffer,
    allocation: c.VmaAllocation,
};

pub const AllocatedImage = struct {
    image: c.VkImage,
    allocation: c.VmaAllocation,
};

pub const VkEngine = struct {
    allocator: std.mem.Allocator = undefined,

    // Vulkan data
    instance: c.VkInstance = VK_NULL_HANDLE,
    debug_messenger: c.VkDebugUtilsMessengerEXT = VK_NULL_HANDLE,

    physical_device: c.VkPhysicalDevice = VK_NULL_HANDLE,
    physical_device_properties: c.VkPhysicalDeviceProperties = undefined,

    device: c.VkDevice = VK_NULL_HANDLE,
    surface: c.VkSurfaceKHR = VK_NULL_HANDLE,

    swapchain: c.VkSwapchainKHR = VK_NULL_HANDLE,
    swapchain_format: c.VkFormat = undefined,
    swapchain_extent: c.VkExtent2D = undefined,
    swapchain_images: []c.VkImage = undefined,
    swapchain_image_views: []c.VkImageView = undefined,

    graphics_queue: c.VkQueue = VK_NULL_HANDLE,
    graphics_queue_family: u32 = undefined,
    present_queue: c.VkQueue = VK_NULL_HANDLE,
    present_queue_family: u32 = undefined,

    window: *c.SDL_Window = undefined,

    frame_number: u64 = 0,

    is_initialized: bool = false,

    vma_allocator: c.VmaAllocator = undefined,

    deletion_queue: std.ArrayList(VulkanDeleter) = undefined,
    buffer_deletion_queue: std.ArrayList(VmaBufferDeleter) = undefined,
    image_deletion_queue: std.ArrayList(VmaImageDeleter) = undefined,

    const Self = @This();

    pub const VulkanDeleter = struct {
        object: ?*anyopaque,
        delete_fn: *const fn(entry: *VulkanDeleter, self: *Self) void,

        fn delete(self: *VulkanDeleter, engine: *Self) void {
            self.delete_fn(self, engine);
        }

        fn make(object: anytype, func: anytype) VulkanDeleter {
            const T = @TypeOf(object);
            comptime {
                std.debug.assert(@typeInfo(T) == .Optional);
                const Ptr = @typeInfo(T).Optional.child;
                std.debug.assert(@typeInfo(Ptr) == .Pointer);
                std.debug.assert(@typeInfo(Ptr).Pointer.size == .One);

                const Fn = @TypeOf(func);
                std.debug.assert(@typeInfo(Fn) == .Fn);
            }

            return VulkanDeleter {
                .object = object,
                .delete_fn = struct {
                    fn destroy_impl(entry: *VulkanDeleter, self: *Self) void {
                        const obj: @TypeOf(object) = @ptrCast(entry.object);
                        func(self.device, obj, vk_alloc_cbs);
                    }
                }.destroy_impl,
            };
        }
    };

    pub const VmaBufferDeleter = struct {
        buffer: AllocatedBuffer,

        fn delete(self: *VmaBufferDeleter, engine: *Self) void {
            c.vmaDestroyBuffer(engine.vma_allocator, self.buffer.buffer, self.buffer.allocation);
        }
    };

    pub const VmaImageDeleter = struct {
        image: AllocatedImage,

        fn delete(self: *VmaImageDeleter, engine: *Self) void {
            c.vmaDestroyImage(engine.vma_allocator, self.image.image, self.image.allocation);
        }
    };

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

        // Create a VMA allocator
        const allocator_ci = std.mem.zeroInit(c.VmaAllocatorCreateInfo, .{
            .physicalDevice = engine.physical_device,
            .device = engine.device,
            .instance = engine.instance,
        });

        check_vk(c.vmaCreateAllocator(&allocator_ci, &engine.vma_allocator))
            catch @panic("Failed to create VMA allocator");
        
        // TODO create swapchain
        try engine.init_swapchain();

        // TODO create commands

        // TODO create default render pass

        // TODO create framebuffers

        // TODO create sync structures

        // TODO create descriptors

        // TODO create pipelines

        // TODO load textures

        // TODO load meshes

        // TODO create scene

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

        log.info("The GPU has a minimum buffer alignment of {} bytes", .{physical_device.properties.limits.minUniformBufferOffsetAlignment});

        self.graphics_queue_family = physical_device.graphics_queue_family;
        self.present_queue_family = physical_device.present_queue_family;

        const shader_draw_parameters_features = std.mem.zeroInit(c.VkPhysicalDeviceShaderDrawParametersFeatures, .{
            .sType = c.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_DRAW_PARAMETERS_FEATURES,
            .shaderDrawParameters = c.VK_TRUE,
        });

        // Create a logical device
        const device = vki.create_logical_device(self.allocator, .{
            .physical_device = physical_device,
            .features = std.mem.zeroInit(c.VkPhysicalDeviceFeatures, .{}),
            .alloc_cb = vk_alloc_cbs,
            .pnext = &shader_draw_parameters_features,
        }) catch @panic("Failed to create logical device");

        self.device = device.handle;
        self.graphics_queue = device.graphics_queue;
        self.present_queue = device.present_queue;
    }

    fn init_swapchain(self: *VkEngine) !void {
        var win_width: c_int = undefined;
        var win_height: c_int = undefined;
        check_sdl(c.SDL_GetWindowSize(self.window, &win_width, &win_height));

        // Create a swapchain
        // const swapchain = vki.create_swapchain(self.allocator, .{
        //     .physical_device = self.physical_device,
        //     .graphics_queue_family = self.graphics_queue_family,
        //     .present_queue_family = self.graphics_queue_family,
        //     .device = self.device,
        //     .surface = self.surface,
        //     .old_swapchain = null ,
        //     .vsync = true,
        //     .window_width = @intCast(win_width),
        //     .window_height = @intCast(win_height),
        //     .alloc_cb = vk_alloc_cbs,
        // }) catch @panic("Failed to create swapchain");

        // self.swapchain = swapchain.handle;
        // self.swapchain_format = swapchain.format;
        // self.swapchain_extent = swapchain.extent;
        // self.swapchain_images = swapchain.images;
        // self.swapchain_image_views = swapchain.image_views;

        // for (self.swapchain_image_views) |view|{
        //     self.deletion_queue.append(VulkanDeleter.make(view, c.vkDestroyImageView)) catch @panic("Out of memory");
        // }
        // self.deletion_queue.append(VulkanDeleter.make(swapchain.handle, c.vkDestroySwapchainKHR)) catch @panic("Out of memory");

        //log.info("Created swapchain", .{});
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
