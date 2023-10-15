// INCLUDES 
const std = @import("std");
const i_math = @import("zlm/src/zlm-generic.zig").SpecializeOn(i32);
const f_math = @import("zlm/src/zlm-generic.zig").SpecializeOn(f32);

const Mesh = @import("mesh.zig").Mesh;

const draw = @import("draw.zig");
const colors = @import("colors.zig");
const screen = @import("screen.zig");
const utils = @import("cm_utils.zig");    

// STRUCTS 
pub const Projection = enum {
    Perspective,
    Orthogonal
};

// FUNCTIONS 
pub fn rasterize_mesh(mesh: *const Mesh, canvas: *draw.Canvas, offset: @Vector(3, f32), scale: @Vector(3, f32), projection: Projection) void {
    const width: f32 = @floatFromInt(canvas.width);
    const height: f32 = @floatFromInt(canvas.height);
    const aspect: f32 = height / width;
    const aspect_scalar: @Vector(3, f32) = @splat(aspect);
    const fov: f32 = 1.5; // radians
    const znear: f32 = 0.1;
    const zfar: f32 = 100;

    for(mesh.tris) |t| {
        var screen_coords: [3]@Vector(3, f32) = .{ .{ 0, 0, 0 }, .{ 0, 0, 0 }, .{ 0, 0, 0 } };

        for(0..3) |j| {
            const world_pos: @Vector(3, f32) = t[j] * scale + offset;
            
            var norm_device_pos: @Vector(3, f32) = .{ 0, 0, 0 };
            if(projection == Projection.Orthogonal) {   
                norm_device_pos = world_pos * aspect_scalar;
            }
            else {
                const proj_mat: [4]@Vector(4, f32) = .{
                    .{ 1 / (@tan(fov / 2) * aspect), 0, 0, 0 },
                    .{ 0, 1 / @tan(fov / 2), 0, 0 },
                    .{ 0, 0, (zfar + znear) / (znear - zfar), -1 },
                    .{ 0, 0, (znear * zfar * 2) / (znear - zfar), 0}
                };

                const world_pos_mat: @Vector(4, f32) = .{ world_pos[0], world_pos[1], world_pos[2], 1 };
                const clip: @Vector(4, f32) = utils.multmat_44_4(f32, proj_mat, world_pos_mat);
                norm_device_pos[0] = clip[0] / clip[2];
                norm_device_pos[1] = clip[1] / clip[2];
                norm_device_pos[2] = clip[2] / clip[2];
            }

            screen_coords[j] = .{ 
                (norm_device_pos[0] + 1) * width / 2, 
                (norm_device_pos[1] + 1) * height / 2,
                norm_device_pos[2]
            };
        }

        rasterize_triangle(screen_coords, canvas);
    }
}

pub fn rasterize_triangle(coords: [3]@Vector(3, f32), canvas: *draw.Canvas) void {
    const x0: f32 = (coords[0][0]);
    const x1: f32 = (coords[1][0]);
    const x2: f32 = (coords[2][0]);
    const y0: f32 = (coords[0][1]);
    const y1: f32 = (coords[1][1]);
    const y2: f32 = (coords[2][1]);
    // Bounding rect
    var xvals: [3]f32 = .{ x0, x1, x2 }; // Declaration because min_in_array and max_...
    var yvals: [3]f32 = .{ y0, y1, y2 }; // require already initialized array
    const xmin: f32 = (utils.min_in_array(f32, &xvals) ) ;
    const xmax: f32 = (utils.max_in_array(f32, &xvals) ) ;
    const ymin: f32 = (utils.min_in_array(f32, &yvals) ) ;
    const ymax: f32 = (utils.max_in_array(f32, &yvals) ) ;
    // Factored out of barycentric calculation in loop
    const v0: @Vector(3, f32) = coords[1] - coords[0];
    const v1: @Vector(3, f32) = coords[2] - coords[0];
    const dot00: f32 = utils.dot_v3(f32, v0, v0);
    const dot01: f32 = utils.dot_v3(f32, v0, v1);
    const dot11: f32 = utils.dot_v3(f32, v1, v1);
    const det: f32 = dot00 * dot11 - dot01 * dot01;

    var py: f32 = ymin;
    while(py < ymax) : (py += 1) {
        var px: f32 = xmin;
        while(px < xmax) : (px += 1) {
            // Get barycentric coordinates
            const v2: @Vector(3, f32) = @Vector(3, f32) { px, py, 0 } - coords[0];
            const dot20: f32 = utils.dot_v3(f32, v2, v0);
            const dot21: f32 = utils.dot_v3(f32, v2, v1);
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

                draw.draw_pixel(@intFromFloat(px), @intFromFloat(py), color, canvas);
            }
        }
    }
}

