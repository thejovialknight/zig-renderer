const std = @import("std");
const Allocator = std.mem.Allocator;
const zlm = @import("zlm/src/zlm-generic.zig").SpecializeOn(f32);
const obj = @import("obj_loader.zig");
const sdl = @cImport(@cInclude("SDL.h"));

const Canvas = @import("draw.zig").Canvas;
const Mesh = @import("mesh.zig").Mesh;
const clear_canvas = @import("draw.zig").clear;

const MAX_SCANCODE_CHECK = 256;

pub const Platform = struct {
    // SDL stuff
    window: *sdl.SDL_Window = undefined,
    surface: *sdl.SDL_Surface = undefined,
    renderer: *sdl.SDL_Renderer = undefined,
    // Input state
    keydowns: [MAX_SCANCODE_CHECK]sdl.SDL_Scancode = std.mem.zeroes([256]c_uint),
    keyups: [MAX_SCANCODE_CHECK]sdl.SDL_Scancode = std.mem.zeroes([256]c_uint),
    num_keydowns: usize = 0,
    num_keyups: usize = 0,
    mouse_delta_x: f32 = 0, 
    mouse_delta_y: f32 = 0, 
    quit: bool = false,
    // Resources
    arena_allocator: std.heap.ArenaAllocator = undefined,
    resource_allocator: std.mem.Allocator = undefined, 
    columns: Mesh = undefined,
};

pub fn init(platform: *Platform, canvas: *Canvas) void {
_ = sdl.SDL_Init(sdl.SDL_INIT_VIDEO);

    platform.window = sdl.SDL_CreateWindow("SDL Test", sdl.SDL_WINDOWPOS_CENTERED, sdl.SDL_WINDOWPOS_CENTERED, canvas.*.width, canvas.*.height, 0).?;
    platform.surface = sdl.SDL_GetWindowSurface(platform.window);
    platform.renderer = sdl.SDL_CreateRenderer(platform.window, 0, sdl.SDL_RENDERER_PRESENTVSYNC).?;

    platform.arena_allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    platform.resource_allocator = platform.arena_allocator.allocator(); 

    const model: obj.Model = obj.loadFile(platform.resource_allocator, "column.obj") catch undefined;
    platform.columns = load_mesh(&model, platform.resource_allocator) catch undefined;

    _ = sdl.SDL_SetRelativeMouseMode(sdl.SDL_TRUE);
}

pub fn present_canvas_to_surface(canvas: *Canvas, window: *sdl.SDL_Window, surface: *sdl.SDL_Surface) void {
    _ = sdl.SDL_LockSurface(surface);
    var y: i32 = 0;
    while(y < canvas.height) : (y += 1) {
        var x: i32 = 0;
        while(x < canvas.height) : (x += 1) {
            var pixel_index: usize = @intCast(y * canvas.width + x);
            var c: @Vector(4, u8) = canvas.pixels[pixel_index];
            var sdl_color: u32 = sdl.SDL_MapRGBA(surface.format, c[0], c[1], c[2], c[3]);

            var surface_pointer: [*]u32 = @ptrCast(@alignCast(surface.*.pixels)); // cast c pointer to [*]u32
            surface_pointer[pixel_index] = sdl_color;
        }
    }
    _ = sdl.SDL_UnlockSurface(surface);
    _ = sdl.SDL_UpdateWindowSurface(window);
    clear_canvas(canvas);
}

pub fn cleanup(platform: *Platform) void {
    sdl.SDL_DestroyWindow(platform.window);
    sdl.SDL_DestroyRenderer(platform.renderer);
    sdl.SDL_Quit();
    platform.arena_allocator.deinit();
}

pub fn poll_events(platform: *Platform) void {
    platform.num_keydowns = 0;
    platform.num_keyups = 0;
    platform.mouse_delta_y = 0;
    platform.mouse_delta_x = 0;

    var event: sdl.SDL_Event = undefined;
    while(sdl.SDL_PollEvent(&event) != 0) {
        switch(event.type) {
            sdl.SDL_QUIT => platform.quit = true,
            sdl.SDL_KEYDOWN => {
                    platform.keydowns[platform.num_keydowns] = event.key.keysym.scancode;
                    platform.num_keydowns += 1;
            },
            sdl.SDL_KEYUP => {
                    platform.keyups[platform.num_keyups] = event.key.keysym.scancode;
                    platform.num_keyups += 1;
            },
            sdl.SDL_MOUSEMOTION => {
                platform.mouse_delta_x = @floatFromInt(event.motion.xrel);
                platform.mouse_delta_y = @floatFromInt(event.motion.yrel);
            },
            else => {},
        }
    }
}

pub fn load_mesh(model: *const obj.Model, allocator: Allocator) !Mesh {
    const memory = try allocator.alloc([3]@Vector(3, f32), model.faces.len);
    var mesh: Mesh = .{ .tris = memory };

    for(0..model.faces.len) |i| {
        for(0..3) |j| {
            const v: zlm.Vec4 = model.positions[model.faces[i].vertices[j].position];
            mesh.tris[i][j] = .{ v.x, v.y, v.z };
        }
    }
    return mesh;
}
