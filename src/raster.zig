const std = @import("std");
const i_math = @import("zlm/src/zlm-generic.zig").SpecializeOn(i32);
const f_math = @import("zlm/src/zlm-generic.zig").SpecializeOn(f32);

const obj = @import("obj_loader.zig");
const draw = @import("draw.zig");
const colors = @import("colors.zig");
const screen = @import("screen.zig");

pub fn rasterize_model(model: *const obj.Model, canvas: *draw.Canvas, offset: [2]f32) void {
    const width: f32 = @floatFromInt(canvas.width);
    const height: f32 = @floatFromInt(canvas.height);

    var i: usize = 0;
    for(model.faces) |face| {
        if(i > 1200) return;

        var triangle: [3][2]f32 = .{ .{ 0, 0 }, .{ 0, 0 }, .{ 0, 0 } };

        var normal: f_math.Vec3 = model.normals[i];
        normal = f_math.Vec3.normalize(normal);

        if(normal.x < 0) normal.x = 0;
        if(normal.y < 0) normal.y = 0;
        if(normal.z < 0) normal.z = 0;

        var color: colors.Color = .{ 
            .r = @intFromFloat(normal.x * 255), 
            .g = @intFromFloat(normal.y * 255),
            .b = @intFromFloat(normal.z * 255),
            .a = 255,
        };

        for(0..3) |j| {
            const corner: f_math.Vec4 = model.positions[face.vertices[j].position];
            triangle[j] = .{ (corner.x) * width + offset[0], (corner.y) * height + offset[1]};
        }

        const v0: [2]f32 = triangle[0];
        const v1: [2]f32 = triangle[1];
        const v2: [2]f32 = triangle[2];
        
        draw.draw_triangle(v0, v1, v2, color, canvas);
        i += 1;
    }
}
