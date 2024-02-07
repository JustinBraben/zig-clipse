const std = @import("std");
const assert = @import("std").debug.assert;
const App = @import("app.zig").App;

const xml = @import("xml.zig");
const Map = @import("tmx_map.zig").Map;

const c = @import("clibs.zig");

const zigimg = @import("zigimg");

const print = std.debug.print;

pub fn main() !void {
    const stderr = std.io.getStdErr();

    print("\n", .{});

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // TODO: read the contents of a .tmx file (such as "assets/demo.tmx") and print it out
    //var doc = try xml_document.init(gpa, "assets/demo.tmx");
    //defer doc.deinit();

    const cwd = std.fs.cwd();
    const xml_path = "assets/demo.tmx";
    const xml_src = cwd.readFileAlloc(allocator, xml_path, std.math.maxInt(usize)) catch |err| {
        try stderr.writer().print("Error: Failed to open input file '{s}' ({s})\n", .{ xml_path, @errorName(err) });
        return;
    };

    const doc = try xml.parse(allocator, xml_src);

    const attribs = doc.root.attributes;
    var index: u8 = 0;
    while (index < attribs.len) : (index += 1) {
        const attrib = attribs[index];
        _ = attrib; // autofix
        //print("{s}: {s}\n", .{ attrib.name, attrib.value });
    }

    //print("{s} - {s}\n", .{ doc.root.getAttribute("renderorder").? });

    // print("map working dir : {?s}\n", .{map.working_dir});
    // print("map : {any}\n", .{map});
    // print("map orientation : {any}\n", .{map.orientation});
    // print("map render order: {any}\n", .{map.renderorder});
    // print("map version : {any}\n", .{map.version});

    // TODO: Create a Map struct that can hold the contents of a .tmx file
    var map: Map = undefined;

    // TODO: Save the contents of the .tmx file to a Map struct
    map = try map.loadFromString(allocator, xml_src, xml_path);

    print("Map layer 3\n", .{});
    print("id : {any}\n", .{map.layers.items[2].id});
    print("name : {any}\n", .{map.layers.items[2].name});
    print("width : {any}\n", .{map.layers.items[2].width});
    print("height : {any}\n", .{map.layers.items[2].height});
    print("{any}\n", .{map.layers.items[2].data.contents.items});

    // TODO: create an SDL window
    // Create SDL window
    if (c.SDL_Init(c.SDL_INIT_VIDEO) != 0) {
        c.SDL_Log("Unable to initialize SDL: %s", c.SDL_GetError());
        return error.SDLInitializationFailed;
    }
    defer c.SDL_Quit();

    const screen = c.SDL_CreateWindow("My Game Window", c.SDL_WINDOWPOS_UNDEFINED, c.SDL_WINDOWPOS_UNDEFINED, 960, 512, c.SDL_WINDOW_OPENGL) orelse
        {
        c.SDL_Log("Unable to create window: %s", c.SDL_GetError());
        return error.SDLInitializationFailed;
    };
    defer c.SDL_DestroyWindow(screen);

    const renderer = c.SDL_CreateRenderer(screen, -1, 0) orelse {
        c.SDL_Log("Unable to create renderer: %s", c.SDL_GetError());
        return error.SDLInitializationFailed;
    };
    defer c.SDL_DestroyRenderer(renderer);

    // TODO: Load a png file into an SDL texture

    // const surface = c.IMG_Load("assets/images/tileset.png") orelse {
    //     c.SDL_Log("Unable to load image: %s", c.SDL_GetError());
    //     return error.SDLInitializationFailed;
    // };
    // _ = surface; // autofix

    // TODO: render the map to the SDL window
    var quit = false;
    while (!quit) {
        var event: c.SDL_Event = undefined;
        while (c.SDL_PollEvent(&event) != 0) {
            switch (event.type) {
                c.SDL_QUIT => {
                    quit = true;
                },
                else => {},
            }
        }

        _ = c.SDL_RenderClear(renderer);
        //_ = c.SDL_RenderCopy(renderer, zig_texture, null, null);
        c.SDL_RenderPresent(renderer);

        c.SDL_Delay(17);
    }
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
