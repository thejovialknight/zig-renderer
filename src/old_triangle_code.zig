const math = @import("zlm/src/zlm-generic.zig").SpecializeOn(i32);
const colors = @import("colors.zig");
const Canvas = @import("draw.zig").Canvas;
const utils = @import("cm_utils.zig");

pub fn draw_triangle(triangle: *[3]math.Vec2, color: colors.Color, canvas: *Canvas) void {
    var t0 = triangle[0];
    var t1 = triangle[1];
    var t2 = triangle[2];
    // Ignore degenerate triangles
    if(t0.y == t1.y and t0.y == t2.y) return;
    // Sort vertices lower to upper
    if(t0.y > t1.y) utils.swap(math.Vec2, &t0, &t1);
    if(t0.y > t2.y) utils.swap(math.Vec2, &t0, &t2);
    if(t1.y > t2.y) utils.swap(math.Vec2, &t1, &t2);

    const total_height: f32 = t2.y - t0.y;
    var i: f32 = 0;
    while(i < total_height) : ( i += 1 ) {
        const second_half: bool = i > t1.y - t0.y or t1.y == t0.y;
        var segment_height: f32 = t1.y - t0.y; 
        if(second_half) segment_height = t2.y - t1.y;

        const alpha: f32 = i / total_height;
        var beta_sub: f32 = 0;
        if(second_half) beta_sub = t1.y - t0.y; // not currently needed with the fully f32 implementation
        const beta: f32 = (i - beta_sub) / segment_height;

        var a: math.Vec2 = math.Vec2.add(t0, math.Vec2.scale(math.Vec2.sub(t2, t0), alpha));
        var b: math.Vec2 = math.Vec2.add(t0, math.Vec2.scale(math.Vec2.sub(t1, t0), beta));
        if(second_half) b = math.Vec2.add(t1, math.Vec2.scale(math.Vec2.sub(t2, t1), beta));
        if(a.x > b.x) utils.swap(math.Vec2, &a, &b);

        var x: f32 = a.x;
        while(x < b.x) : (x += 1) {
            draw_pixel(@intFromFloat(x), @intFromFloat(t0.y + i), color, canvas);
        }
    }
}

pub fn draw_triangle(triangle: [3]imath.Vec2, color: colors.Color, canvas: *Canvas) void {
    _ = canvas;
    _ = color;
    var t0 = triangle[0];
    var t1 = triangle[1];
    var t2 = triangle[2];
    // Ignore degenerate triangles
    if(t0.y == t1.y and t0.y == t2.y) return;
    // Sort vertices lower to upper
    if(t0.y > t1.y) utils.swap(imath.Vec2, &t0, &t1);
    if(t0.y > t2.y) utils.swap(imath.Vec2, &t0, &t2);
    if(t1.y > t2.y) utils.swap(imath.Vec2, &t1, &t2);

    // TODO: Adapt this using integers instead of floats according to tutorial

    const total_height: i32 = t2.y - t0.y;
    var i: i32 = 0;
    while(i < total_height) : ( i += 1 ) {
        const second_half: bool = i > t1.y - t0.y or t1.y == t0.y;
        var segment_height: i32 = t1.y - t0.y; 
        if(second_half) segment_height = t2.y - t1.y;

        const f_index: f32 = @floatFromInt(i);
        const f_total_height: f32 = @floatFromInt(total_height);
        const alpha: f32 = f_index / f_total_height;
        var beta_sub: f32 = 0;
        if(second_half) beta_sub = @floatFromInt(t1.y - t0.y);
        const f_i: f32 = @floatFromInt(i);
        const f_segment_height: f32 = @floatFromInt(segment_height);
        const beta: f32 = (f_i - beta_sub) / f_segment_height;

        var a: imath.Vec2 = imath.Vec2.add(t0, imath.Vec2.scale(imath.Vec2.sub(t2, t0), alpha));
        var b: imath.Vec2 = imath.Vec2.add(t0, imath.Vec2.scale(imath.Vec2.sub(t1, t0), beta));
        if(second_half) b = imath.Vec2.add(t1, imath.Vec2.scale(imath.Vec2.sub(t2, t1), beta));
        if(a.x > b.x) utils.swap(imath.Vec2, &a, &b);

        var x: i32 = a.x;
        while(x < b.x) : (x += 1) {
            // draw_pixel(x, t0.y + i, color, canvas);
        }
    }
}

pub fn barycentric_draw_triangle(triangle: [3]math.Vec2, color: colors.Color, canvas: *Canvas) void {

    var bounding_box_min: math.Vec2 = .{ .x = canvas.width - 1, .y = canvas.height - 1 };
    var bounding_box_max: math.Vec2 = .{ .x = 0, .y = 0 };

    for(0..3) |i| {
        bounding_box_min.x = utils.max(i32, 0, utils.min(i32, bounding_box_min.x, triangle[i].x));
        bounding_box_min.y = utils.max(i32, 0, utils.min(i32, bounding_box_min.x, triangle[i].x));

        bounding_box_max.x = utils.min(i32, canvas.width - 1, utils.max(i32, bounding_box_max.x, triangle[i].x));
        bounding_box_max.y = utils.min(i32, canvas.height - 1, utils.max(i32, bounding_box_max.y, triangle[i].y));
    }

    var pixel: math.Vec2 = .{ .x = bounding_box_min.x, .y = bounding_box_min.y };
    while(pixel.x <= bounding_box_max.x) : (pixel.x += 1) {
        while(pixel.y <= bounding_box_max.y) : (pixel.y += 1) {
            const barycentric_screen: f_math.Vec3 = undefined;
            const u: f_math.Vec3 = .{ 
                .x = triangle[2][0]-triangle[0][0], 
                .y = triangle[1][0]-triangle[0][0], 
                .z = triangle[0][0]-pixel[0] 
            } 
            ^ // XOR two Vec3s
            .{ 
                .x = triangle[2][1]-triangle[0][1], 
                .y = triangle[1][1]-triangle[0][1], 
                .z = triangle[0][1]-pixel[1] 
            };
            if(utils.abs(f32, (u.z)) < 1) barycentric_screen = .{ .x = -1, .y = 1, .z = 1 };
            barycentric_screen = .{ .x = 1 - (u.x + u.y) / u.z, .y = u.y / u.z, .z = u.x / u.x };

            if(barycentric_screen.x < 0 or barycentric_screen.y < 0 or barycentric_screen.z < 0) continue;
            draw_pixel(pixel.x, pixel.y, color, canvas);
        }
    }
}
