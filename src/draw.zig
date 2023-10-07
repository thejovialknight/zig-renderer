const sdl = @cImport(@cInclude("SDL.h"));
const std = @import("std");
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

pub fn clear(canvas: *Canvas, color: colors.Color) void {
    var i: usize = 0;
    while(i < canvas.pixels.len) : (i += 1) {
        canvas.pixels[i] = color;
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

    clear(canvas, colors.black());
}

pub fn draw_pixel(x: i32, y: i32, color: colors.Color, canvas: *Canvas) void {
    if(x < 0 or y < 0 or x > canvas.width or y > canvas.height or
    y * canvas.width + x > canvas.pixels.len) return;

    canvas.pixels[@intCast(y * canvas.width + x)] = color;
}

pub fn draw_triangle(v0: [2]f32, v1: [2]f32, v2: [2]f32, color: colors.Color, canvas: *Canvas) void {
    const y0: f32 = v0[1];
    const y1: f32 = v1[1];
    const y2: f32 = v2[1];

    const x0: f32 = v0[0];
    const x1: f32 = v1[0];
    const x2: f32 = v2[0];

    // Bounding rect
    var xvals: [3]f32 = .{ x0, x1, x2 }; // Declaration because min_in_array and max_...
    var yvals: [3]f32 = .{ y0, y1, y2 }; // require already initialized array
    const xmin: f32 = (utils.min_in_array( f32, &xvals));
    const xmax: f32 = (utils.max_in_array( f32, &xvals));
    const ymin: f32 = (utils.min_in_array( f32, &yvals));
    const ymax: f32 = (utils.max_in_array( f32, &yvals));

    // Deltas for line equation precalculation
    const dx01: f32 = x0 - x1;
    const dx12: f32 = x1 - x2;
    const dx20: f32 = x2 - x0;
    const dy01: f32 = y0 - y1;
    const dy12: f32 = y1 - y2;
    const dy20: f32 = y2 - y0;

    // c = constant parts of line equation
    const c0: f32 = dy01 * x0 - dx01 * y0;
    const c1: f32 = dy12 * x1 - dx12 * y1;
    const c2: f32 = dy20 * x2 - dx20 * y2;

    // Starting values of function at top of bounding rect
    var cy0: f32 = c0 + dx01 * ymin - dy01 * xmin;
    var cy1: f32 = c1 + dx12 * ymin - dy12 * xmin;
    var cy2: f32 = c2 + dx20 * ymin - dy20 * xmin;

    var py: f32 = ymin;
    while(py < ymax) : (py += 1) {
        // Starting values of function per horizontal scan
        var cx0: f32 = cy0;
        var cx1: f32 = cy1;
        var cx2: f32 = cy2;

        var px: f32 = xmin;
        while(px < xmax) : (px += 1) {
            if(cx0 > 0 and cx1 > 0 and cx2 > 0) {
                draw_pixel(@intFromFloat(px), @intFromFloat(py), color, canvas);
            }

            cx0 -= dy01;
            cx1 -= dy12;
            cx2 -= dy20;
        }

        cy0 += dx01;
        cy1 += dx12;
        cy2 += dx20;
    }
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
