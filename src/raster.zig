const std = @import("std");
const i_math = @import("zlm/src/zlm-generic.zig").SpecializeOn(i32);
const f_math = @import("zlm/src/zlm-generic.zig").SpecializeOn(f32);

const obj = @import("obj_loader.zig");
const draw = @import("draw.zig");
const colors = @import("colors.zig");
const screen = @import("screen.zig");

pub fn rasterize_model(model: *const obj.Model, canvas: *draw.Canvas, offset: f_math.Vec2) void {
    const width: f32 = @floatFromInt(canvas.width);
    const height: f32 = @floatFromInt(canvas.height);

    var i: usize = 0;
    for(model.faces) |face| {
        if(i > 1000) return;

        var triangle: [3]f_math.Vec2 = undefined;
        var normal: f_math.Vec3 = model.normals[i];
        normal = f_math.Vec3.normalize(normal);

        if(normal.x < 0) normal.x = 0;
        if(normal.y < 0) normal.y = 0;
        if(normal.z < 0) normal.z = 0;

        var color: colors.Color = .{ 
            .r = @intFromFloat(normal.x * 254), 
            .g = @intFromFloat(normal.y * 254),
            .b = @intFromFloat(normal.z * 254),
            .a = 255,
        };

        for(0..3) |j| {
            const corner: f_math.Vec4 = model.positions[face.vertices[j].position];
            triangle[j] = .{ .x = (corner.x + offset.x) * width, .y = (corner.y + offset.y) * height };
            draw.draw_triangle(&triangle, color, canvas);
        }

        i += 1;
    }
}
