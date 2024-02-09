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
    engine_version: u32 = c.VK_MAKE_VERSION(1, 0, 0),
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
    // Check the api version is supported
    if (options.api_version > c.VK_MAKE_VERSION(1, 0, 0)) {
        var api_requested = options.api_version;
        try check_vk(c.vkEnumerateInstanceVersion(@ptrCast(&api_requested)));
    }

    var enable_validation = options.debug;

    var arena_state = std.heap.ArenaAllocator.init(allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    var layer_count: u32 = undefined;
    try check_vk(c.vkEnumerateInstanceLayerProperties(&layer_count, null));
    const layer_props = try arena.alloc(c.VkLayerProperties, layer_count);
    try check_vk(c.vkEnumerateInstanceLayerProperties(&layer_count, layer_props.ptr));

    var layers = std.ArrayListUnmanaged([*c]const u8){};
    if (enable_validation) {
        enable_validation = blk: for (layer_props) |layer_prop| {
            const layer_name: [*c]const u8 = @ptrCast(layer_prop.layerName[0..]);
            const validation_layer_name: [*c]const u8 = "VK_LAYER_KHRONOS_validation";
            if (std.mem.eql(u8, std.mem.span(validation_layer_name), std.mem.span(layer_name))) {
                try layers.append(arena, validation_layer_name);
                break :blk true;
            }
        } else false;
    }

    return .{ .handle = null, .debug_messenger = null };
}

pub fn check_vk(result: c.VkResult) !void {
    return switch (result) {
        c.VK_SUCCESS => {},
        c.VK_NOT_READY => error.vk_not_ready,
        c.VK_TIMEOUT => error.vk_timeout,
        c.VK_EVENT_SET => error.vk_event_set,
        c.VK_EVENT_RESET => error.vk_event_reset,
        c.VK_INCOMPLETE => error.vk_incomplete,
        c.VK_ERROR_OUT_OF_HOST_MEMORY => error.vk_error_out_of_host_memory,
        c.VK_ERROR_OUT_OF_DEVICE_MEMORY => error.vk_error_out_of_device_memory,
        c.VK_ERROR_INITIALIZATION_FAILED => error.vk_error_initialization_failed,
        c.VK_ERROR_DEVICE_LOST => error.vk_error_device_lost,
        c.VK_ERROR_MEMORY_MAP_FAILED => error.vk_error_memory_map_failed,
        c.VK_ERROR_LAYER_NOT_PRESENT => error.vk_error_layer_not_present,
        c.VK_ERROR_EXTENSION_NOT_PRESENT => error.vk_error_extension_not_present,
        c.VK_ERROR_FEATURE_NOT_PRESENT => error.vk_error_feature_not_present,
        c.VK_ERROR_INCOMPATIBLE_DRIVER => error.vk_error_incompatible_driver,
        c.VK_ERROR_TOO_MANY_OBJECTS => error.vk_error_too_many_objects,
        c.VK_ERROR_FORMAT_NOT_SUPPORTED => error.vk_error_format_not_supported,
        c.VK_ERROR_FRAGMENTED_POOL => error.vk_error_fragmented_pool,
        c.VK_ERROR_UNKNOWN => error.vk_error_unknown,
        c.VK_ERROR_OUT_OF_POOL_MEMORY => error.vk_error_out_of_pool_memory,
        c.VK_ERROR_INVALID_EXTERNAL_HANDLE => error.vk_error_invalid_external_handle,
        c.VK_ERROR_FRAGMENTATION => error.vk_error_fragmentation,
        c.VK_ERROR_INVALID_OPAQUE_CAPTURE_ADDRESS => error.vk_error_invalid_opaque_capture_address,
        c.VK_PIPELINE_COMPILE_REQUIRED => error.vk_pipeline_compile_required,
        c.VK_ERROR_SURFACE_LOST_KHR => error.vk_error_surface_lost_khr,
        c.VK_ERROR_NATIVE_WINDOW_IN_USE_KHR => error.vk_error_native_window_in_use_khr,
        c.VK_SUBOPTIMAL_KHR => error.vk_suboptimal_khr,
        c.VK_ERROR_OUT_OF_DATE_KHR => error.vk_error_out_of_date_khr,
        c.VK_ERROR_INCOMPATIBLE_DISPLAY_KHR => error.vk_error_incompatible_display_khr,
        c.VK_ERROR_VALIDATION_FAILED_EXT => error.vk_error_validation_failed_ext,
        c.VK_ERROR_INVALID_SHADER_NV => error.vk_error_invalid_shader_nv,
        c.VK_ERROR_IMAGE_USAGE_NOT_SUPPORTED_KHR => error.vk_error_image_usage_not_supported_khr,
        c.VK_ERROR_VIDEO_PICTURE_LAYOUT_NOT_SUPPORTED_KHR => error.vk_error_video_picture_layout_not_supported_khr,
        c.VK_ERROR_VIDEO_PROFILE_OPERATION_NOT_SUPPORTED_KHR => error.vk_error_video_profile_operation_not_supported_khr,
        c.VK_ERROR_VIDEO_PROFILE_FORMAT_NOT_SUPPORTED_KHR => error.vk_error_video_profile_format_not_supported_khr,
        c.VK_ERROR_VIDEO_PROFILE_CODEC_NOT_SUPPORTED_KHR => error.vk_error_video_profile_codec_not_supported_khr,
        c.VK_ERROR_VIDEO_STD_VERSION_NOT_SUPPORTED_KHR => error.vk_error_video_std_version_not_supported_khr,
        c.VK_ERROR_INVALID_DRM_FORMAT_MODIFIER_PLANE_LAYOUT_EXT => error.vk_error_invalid_drm_format_modifier_plane_layout_ext,
        c.VK_ERROR_NOT_PERMITTED_KHR => error.vk_error_not_permitted_khr,
        c.VK_ERROR_FULL_SCREEN_EXCLUSIVE_MODE_LOST_EXT => error.vk_error_full_screen_exclusive_mode_lost_ext,
        c.VK_THREAD_IDLE_KHR => error.vk_thread_idle_khr,
        c.VK_THREAD_DONE_KHR => error.vk_thread_done_khr,
        c.VK_OPERATION_DEFERRED_KHR => error.vk_operation_deferred_khr,
        c.VK_OPERATION_NOT_DEFERRED_KHR => error.vk_operation_not_deferred_khr,
        c.VK_ERROR_COMPRESSION_EXHAUSTED_EXT => error.vk_error_compression_exhausted_ext,
        c.VK_ERROR_INCOMPATIBLE_SHADER_BINARY_EXT => error.vk_error_incompatible_shader_binary_ext,
        else => error.vk_errror_unknown,
    };
}
