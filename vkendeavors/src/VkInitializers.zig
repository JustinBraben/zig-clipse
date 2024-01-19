const std = @import("std");
const c = @import("clibs.zig");

const log = std.log.scoped(.vulkan_init);

// TODO: Vulkan initialization code will be here

/// Instance init settings
///
pub const VkiInstanceOptions = struct {
    application_name: []const u8 = "vki",
    application_version: u32 = c.VK_MAKE_VERSION(1, 0, 0),
    engine_name: []const u8 = "My Vk engine",
    api_version: u32 = c.VK_MAKE_VERSION(1, 0, 0),
    debug: bool = false,
    debug_callback: ?c.PFN_vkDebugUtilsMessengerCallbackEXT = null,
    required_extensions: []const [*c]const u8 = &.{},
    alloc_rb: ?*c.VkAllocationCallbacks = null,
};

/// Result for create_instance
/// Contains Vulkan instance handle and debug messenger handle
pub const Instance = struct {
    handle: c.VkInstance = null,
    debug_messenger: c.VkDebugUtilsMessengerEXT = null,
};

pub fn create_instance(allocator: std.mem.Allocator, options: VkiInstanceOptions) !Instance {
    _ = allocator; // autofix
    _ = options; // autofix

    return .{ .handle = null, .debug_messenger = null };
}
