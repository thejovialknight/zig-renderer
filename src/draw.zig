const sdl = @cImport(@cInclude("SDL.h"));
const std = @import("std");
const utils = @import("cm_utils.zig");
const colors = @import("colors.zig");

// NOTE: Might want to end up making this configurable when Canvas is initialized.
//       This would just require a slight refactor, as when it becomes needed, there will
//       only be once canvas initialized anyway.

pub const WIDTH: i32 = 640;
pub const HEIGHT: i32 = 640;
const CANVAS_NUM_PIXELS: u32 = WIDTH * HEIGHT;

pub const Canvas = struct {
    pixels: [CANVAS_NUM_PIXELS]colors.Color = undefined,
    width: i32 = WIDTH,
    height: i32 = HEIGHT,
};

pub fn clear(canvas: *Canvas, color: colors.Color) void {
    var i: usize = 0;
    while(i < canvas.pixels.len) : (i += 1) {
        canvas.pixels[i] = color;
    }
}

pub fn present(canvas: *Canvas, window: *sdl.SDL_Window, surface: *sdl.SDL_Surface) void {
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

    clear(canvas, colors.black());
}

pub fn draw_pixel(x: i32, y: i32, color: colors.Color, canvas: *Canvas) void {
    if(x < 0 or y < 0 or x >= canvas.width or y >= canvas.height) return;

    canvas.pixels[@intCast(y * canvas.width + x)] = color;
}

pub fn draw_triangle_wire(v0: [2]f32, v1: [2]f32, v2: [2]f32, color: colors.Color, canvas: *Canvas) void {
    const x0: i32 = @intFromFloat(v0[0]);
    const x1: i32 = @intFromFloat(v1[0]);
    const x2: i32 = @intFromFloat(v2[0]);
    const y0: i32 = @intFromFloat(v0[1]);
    const y1: i32 = @intFromFloat(v1[1]);
    const y2: i32 = @intFromFloat(v2[1]);

    draw_line(x0, y0, x1, y1, color, canvas);
    draw_line(x1, y1, x2, y2, color, canvas);
    draw_line(x2, y2, x0, y0, color, canvas);
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
