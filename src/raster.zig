const Canvas = @import("draw.zig").Canvas;
const min_in_array = @import("cm_math.zig").min_in_array;
const max_in_array = @import("cm_math.zig").max_in_array;
const dot_v3 = @import("cm_math.zig").dot_v3;
const draw_pixel = @import("draw.zig").draw_pixel;

pub fn rasterize_triangle(coords: [3]@Vector(3, f32), canvas: *Canvas) void {
    const x0: f32 = (coords[0][0]);
    const x1: f32 = (coords[1][0]);
    const x2: f32 = (coords[2][0]);
    const y0: f32 = (coords[0][1]);
    const y1: f32 = (coords[1][1]);
    const y2: f32 = (coords[2][1]);
    // Bounding rect
    var xvals: [3]f32 = .{ x0, x1, x2 };
    var yvals: [3]f32 = .{ y0, y1, y2 };
    const xmin: f32 = (min_in_array(f32, &xvals) ) ;
    const xmax: f32 = (max_in_array(f32, &xvals) ) ;
    const ymin: f32 = (min_in_array(f32, &yvals) ) ;
    const ymax: f32 = (max_in_array(f32, &yvals) ) ;
    // Factored out of barycentric calculation in loop
    const v0: @Vector(3, f32) = coords[1] - coords[0];
    const v1: @Vector(3, f32) = coords[2] - coords[0];
    const dot00: f32 = dot_v3(f32, v0, v0);
    const dot01: f32 = dot_v3(f32, v0, v1);
    const dot11: f32 = dot_v3(f32, v1, v1);
    const det: f32 = dot00 * dot11 - dot01 * dot01;

    var py: f32 = ymin;
    while(py < ymax) : (py += 1) {
        const upper_y_bound: f32 = @floatFromInt(canvas.height);
        if(py < 0 or py > upper_y_bound) continue;

        var px: f32 = xmin;
        while(px < xmax) : (px += 1) {
            const upper_x_bound: f32 = @floatFromInt(canvas.width);
            if(px < 0 or px > upper_x_bound) continue;

            // Get barycentric coordinates
            const v2: @Vector(3, f32) = @Vector(3, f32) { px, py, 0 } - coords[0];
            const dot20: f32 = dot_v3(f32, v2, v0);
            const dot21: f32 = dot_v3(f32, v2, v1);
            const v: f32 = (dot11 * dot20 - dot01 * dot21) / det;
            const w: f32 = (dot00 * dot21 - dot01 * dot20) / det;
            const u: f32 = 1 - v - w;
            if(u > 0 and v > 0 and w > 0) {
                const color = @Vector(4, u8) {
                    @intFromFloat(u * 250),
                    @intFromFloat(v * 250),
                    @intFromFloat(w * 250),
                    255
                };

                draw_pixel(@intFromFloat(px), @intFromFloat(py), color, canvas);
            }
        }
    }
}

