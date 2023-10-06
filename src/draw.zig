pub const sdl = @cImport({ @cInclude("SDL.h"); });
const std = @import("std");
const math = @import("zlm/src/zlm-generic.zig").SpecializeOn(f32);
const utils = @import("cm_utils.zig");
const colors = @import("colors.zig");

// NOTE: Might want to end up making this configurable when Canvas is initialized.
//       This would just require a slight refactor, as when it becomes needed, there will
//       only be once canvas initialized anyway.

pub const WIDTH: i32 = 1200;
pub const HEIGHT: i32 = 1200;
const CANVAS_NUM_PIXELS: u32 = WIDTH * HEIGHT;

pub const Canvas = struct {
    pixels: [CANVAS_NUM_PIXELS]colors.Color = undefined,
    width: i32 = WIDTH,
    height: i32 = HEIGHT,
};

pub fn init_canvas(canvas: *Canvas) void {
    var i: usize = 0;
    while(i < canvas.pixels.len) : (i += 1) {
        canvas.pixels[i] = colors.black();
    }
}

pub fn present(canvas: *Canvas, window: *sdl.SDL_Window) void {
    var surface: *sdl.SDL_Surface = sdl.SDL_GetWindowSurface(window);
    _ = sdl.SDL_LockSurface(surface);

    var y: i32 = 0;
    while(y < canvas.height) : (y += 1) {
        var x: i32 = 0;
        while(x < canvas.height) : (x += 1) {
            var pixel_index: usize = @intCast(y * canvas.width + x);
            var c: colors.Color = canvas.pixels[pixel_index];
            var sdl_color: u32 = sdl.SDL_MapRGBA(surface.format, c.r, c.g, c.b, c.a);

            var surface_pointer: [*]u32 = @ptrCast(@alignCast(surface.*.pixels)); // cast c pointer to [*]u32
            surface_pointer[pixel_index] = sdl_color;
        }
    }

    _ = sdl.SDL_UnlockSurface(surface);
    _ = sdl.SDL_UpdateWindowSurface(window);
}

pub fn draw_pixel(x: i32, y: i32, color: colors.Color, canvas: *Canvas) void {
    if(x < 0 or y < 0 or x > canvas.width or y > canvas.height or
    y * canvas.width + x > canvas.pixels.len) return;

    canvas.pixels[@intCast(y * canvas.width + x)] = color;
}

pub fn draw_triangle(triangle: [3]math.Vec2, color: colors.Color, canvas: *Canvas) void {
    _ = canvas;
    _ = color;
    // Coordinates
    const y0: f32 = triangle[0].y;
    const y1: f32 = triangle[1].y;
    const y2: f32 = triangle[2].y;Vec3f(pts[2][0]-pts[0][0], pts[1][0]-pts[0][0], pts[0][0]-P[0])^Vec3f(pts[2][1]-pts[0][1], pts[1][1]-pts[0][1], pts[0][1]-P[1]);
    const x0: f32 = triangle[0].x;
    const x1: f32 = triangle[1].x;
    const x2: f32 = triangle[2].x;
    // Deltas
    const dx_01 = x0 - x1;
    _ = dx_01;
    const dx_12 = x1 - x2;
    _ = dx_12;
    const dx_20 = x2 - x0;
    _ = dx_20;
    const dy_01 = y0 - y1;
    _ = dy_01;
    const dy_12 = y1 - y2;
    _ = dy_12;
    const dy_20 = y2 - y0;
    _ = dy_20;
    // Bounding rectangle
    // TODO: Finish following tutorial from web.archive.org sourceforge archive
    // Eventually they will do an integer only version, very exciting!
    // Also, might as well take the time to actually read them over.
}

pub fn draw_line(xa: i32, ya: i32, xb: i32, yb: i32, color: colors.Color, canvas: *Canvas) void {
    var x1 = xa;
    var y1 = ya;
    var x2 = xb;
    var y2 = yb;

    var steep: bool = false;
    if(std.math.absCast(x1 - x2) < std.math.absCast(y1 - y2)) {
        steep = true;
    }

    if(x1 > x2) {
        utils.swap(i32, &x1, &x2);
        utils.swap(i32, &y1, &y2);
    }

    const dx: i32 = x2 - x1;
    const dy: i32 = y2 - y1;

    var x: i32 = x1;
    while(x < x2) : (x += 1) {
        const y: i32 = y1 + @divTrunc(dy * (x - x1), dx);
        draw_pixel(x, y, color, canvas);
    }
}
