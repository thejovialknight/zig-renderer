const std = @import("std");
const i_math = @import("zlm/src/zlm-generic.zig").SpecializeOn(i32);
const f_math = @import("zlm/src/zlm-generic.zig").SpecializeOn(f32);

const obj = @import("obj_loader.zig");
const draw = @import("draw.zig");
const colors = @import("colors.zig");
const screen = @import("screen.zig");

pub fn rasterize_model(model: *const obj.Model, canvas: *draw.Canvas, offset: [2]f32, scale: [2]f32) void {
    const width: f32 = @floatFromInt(canvas.width);
    const height: f32 = @floatFromInt(canvas.height);

    var i: usize = 0;
    for(model.faces) |face| {
        if(i > 1000) return;

        var screen_coords: [3][2]f32 = .{ .{ 0, 0 }, .{ 0, 0 }, .{ 0, 0 } };
        var world_coords: [3][2]f32 = .{ .{ 0, 0 }, .{ 0, 0 }, .{ 0, 0 } };

        for(0..3) |j| {
            const v: f_math.Vec4 = model.positions[face.vertices[j].position];
            screen_coords[j] = .{ (v.x) * width * scale[0] + offset[0], (v.y) * height * scale[1] + offset[1]};
            world_coords[j] = .{ v.x, v.y };
        }

        const v0: [2]f32 = screen_coords[0];
        const v1: [2]f32 = screen_coords[1];
        const v2: [2]f32 = screen_coords[2];
        
        const color: colors.Color = .{ .r = 250, .g = 250, .b = 250, .a = 250 };
        draw.draw_triangle_wire(v0, v1, v2, color, canvas);
        i += 1;
    }
}
