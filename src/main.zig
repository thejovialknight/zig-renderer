const std = @import("std");
const draw = @import("draw.zig");
const sdl = @cImport(@cInclude("SDL.h"));
const raster = @import("raster.zig");
const utils = @import("cm_utils.zig");
const colors = @import("colors.zig");
const obj = @import("obj_loader.zig");
const mesh = @import("mesh.zig");
const World = @import("world.zig").World;

pub fn main() !void {
    _ = sdl.SDL_Init(sdl.SDL_INIT_VIDEO);
    defer sdl.SDL_Quit();

    var window: *sdl.SDL_Window = sdl.SDL_CreateWindow("SDL Test", sdl.SDL_WINDOWPOS_CENTERED, sdl.SDL_WINDOWPOS_CENTERED, draw.WIDTH, draw.HEIGHT, 0).?;
    defer sdl.SDL_DestroyWindow(window);

    var surface: *sdl.SDL_Surface = sdl.SDL_GetWindowSurface(window);

    var renderer: *sdl.SDL_Renderer = sdl.SDL_CreateRenderer(window, 0, sdl.SDL_RENDERER_PRESENTVSYNC).?;
    defer sdl.SDL_DestroyRenderer(renderer);

    var canvas: draw.Canvas = .{};
    draw.clear(&canvas, colors.black());

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    var allocator: std.mem.Allocator = arena.allocator(); 
    defer arena.deinit();

    const model: obj.Model = try obj.loadFile(allocator, "column.obj");
    var world: World = .{ .meshes = .{ try mesh.load_mesh(&model, allocator) } };
    world.meshes[0].pos = .{ 0, 0, -10 };

    loop: while (true) {
        world.meshes[0].rot[0] += 0.05;
        world.meshes[0].rot[1] += 0.05;
        world.meshes[0].rot[2] += 0.05;
        var event: sdl.SDL_Event = undefined;
        while (sdl.SDL_PollEvent(&event) != 0) {
            switch (event.type) {
                sdl.SDL_QUIT => break :loop,
                else => {},
            }
        }

        raster.render_world(&world, &canvas);
        draw.present(&canvas, window, surface);
    }
}
