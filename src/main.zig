const std = @import("std");
const draw = @import("draw.zig");
const sdl = @cImport(@cInclude("SDL.h"));
const raster = @import("raster.zig");
const utils = @import("cm_utils.zig");
const colors = @import("colors.zig");
const obj = @import("obj_loader.zig");

pub fn main() !void {
    _ = sdl.SDL_Init(sdl.SDL_INIT_VIDEO);
    defer sdl.SDL_Quit();

    var window: *sdl.SDL_Window = sdl.SDL_CreateWindow("SDL Test", sdl.SDL_WINDOWPOS_CENTERED, sdl.SDL_WINDOWPOS_CENTERED, draw.WIDTH, draw.HEIGHT, 0).?;
    defer sdl.SDL_DestroyWindow(window);

    var renderer: *sdl.SDL_Renderer = sdl.SDL_CreateRenderer(window, 0, sdl.SDL_RENDERER_PRESENTVSYNC).?;
    defer sdl.SDL_DestroyRenderer(renderer);

    var canvas: draw.Canvas = .{};
    draw.clear(&canvas);

    var allocator: std.mem.Allocator = std.heap.page_allocator;
    const model: obj.Model = try obj.loadFile(allocator, "head.obj");

    var offset: [2]f32 = .{ 300, 300 };
    loop: while (true) {
        offset[0] += 1;
        var event: sdl.SDL_Event = undefined;
        while (sdl.SDL_PollEvent(&event) != 0) {
            switch (event.type) {
                sdl.SDL_QUIT => break :loop,
                else => {},
            }
        }

        raster.rasterize_model(&model, &canvas, offset);
        draw.present(&canvas, window);
    }
}
