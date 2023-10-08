const std = @import("std");
const i_math = @import("zlm/src/zlm-generic.zig").SpecializeOn(i32);
const f_math = @import("zlm/src/zlm-generic.zig").SpecializeOn(f32);

const obj = @import("obj_loader.zig");
const draw = @import("draw.zig");
const colors = @import("colors.zig");
const screen = @import("screen.zig");
const utils = @import("cm_utils.zig");    

pub const Projection = enum {
    Perspective,
    Orthogonal
};

pub fn rasterize_model(model: *const obj.Model, canvas: *draw.Canvas, offset: [3]f32, scale: [3]f32, projection: Projection) void {
    const width: f32 = @floatFromInt(canvas.width);
    const height: f32 = @floatFromInt(canvas.height);
    const fov: f32 = 1.5; // radians
    const znear: f32 = 0.1;
    const zfar: f32 = 100;

    var i: usize = 0;
    for(model.faces) |face| {
        if(i > 1000) return;

        var world_coords: [3][4]f32 = .{ .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }};
        var normalized_device_coords: [3][3]f32 = .{ .{ 0, 0, 0 }, .{ 0, 0, 0 }, .{ 0, 0, 0 } };
        var screen_coords: [3][2]f32 = .{ .{ 0, 0 }, .{ 0, 0 }, .{ 0, 0 } };

        const aspect: f32 = height / width;
        for(0..3) |j| {
            const v: f_math.Vec4 = model.positions[face.vertices[j].position];

            world_coords[j] = .{ 
                v.x * scale[0] + offset[0], 
                v.y * scale[1] + offset[1],
                v.z * scale[2] + offset[2],
                1
            };

            if(projection == Projection.Orthogonal) {   
                normalized_device_coords[j] = .{
                    world_coords[j][0] * aspect,
                    world_coords[j][1] * aspect,
                    world_coords[j][2] * aspect
                };
            }
            else {
                const proj_mat: [4][4]f32 = .{
                    .{ 1 / (@tan(fov / 2) * aspect), 0, 0, 0 },
                    .{ 0, 1 / @tan(fov / 2), 0, 0 },
                    .{ 0, 0, (zfar + znear) / (znear - zfar), -1 },
                    .{ 0, 0, (znear * zfar * 2) / (znear - zfar), 0}
                };

                const clip: [4]f32 = utils.multmat_44_4(f32, proj_mat, world_coords[j]);
                normalized_device_coords[j][0] = clip[0] / clip[2];
                normalized_device_coords[j][1] = clip[1] / clip[2];
                normalized_device_coords[j][2] = clip[2] / clip[2];
            }

            screen_coords[j] = .{ 
                (normalized_device_coords[j][0] + 1) * width / 2, 
                (normalized_device_coords[j][1] + 1) * height / 2 
            };
        }

        const v0: [2]f32 = screen_coords[0];
        const v1: [2]f32 = screen_coords[1];
        const v2: [2]f32 = screen_coords[2];
        
        const color: colors.Color = .{ .r = 250, .g = 250, .b = 250, .a = 250 };
        draw.draw_triangle_wire(v0, v1, v2, color, canvas);
        i += 1;
    }
}
