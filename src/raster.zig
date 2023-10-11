// INCLUDES 
const std = @import("std");
const i_math = @import("zlm/src/zlm-generic.zig").SpecializeOn(i32);
const f_math = @import("zlm/src/zlm-generic.zig").SpecializeOn(f32);

const Mesh = @import("mesh.zig").Mesh;

const draw = @import("draw.zig");
const colors = @import("colors.zig");
const screen = @import("screen.zig");
const utils = @import("cm_utils.zig");    

// CONSTANTS
pub const enable_trace = true;

// STRUCTS 
pub const Projection = enum {
    Perspective,
    Orthogonal
};

// FUNCTIONS 
pub fn rasterize_mesh(mesh: *const Mesh, canvas: *draw.Canvas, offset: [3]f32, scale: [3]f32, projection: Projection) void {
    const width: f32 = @floatFromInt(canvas.width);
    const height: f32 = @floatFromInt(canvas.height);
    const fov: f32 = 1.5; // radians
    const znear: f32 = 0.1;
    const zfar: f32 = 100;

    var i: usize = 0;
    for(mesh.tris) |t| {
        if(i > 2000) return;

        var world_coords: [3][4]f32 = .{ .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }};
        var normalized_device_coords: [3][3]f32 = .{ .{ 0, 0, 0 }, .{ 0, 0, 0 }, .{ 0, 0, 0 } };
        var screen_coords: [3][3]f32 = .{ .{ 0, 0, 0 }, .{ 0, 0, 0 }, .{ 0, 0, 0 } };

        const aspect: f32 = height / width;
        for(0..3) |j| {
            const v: [3]f32 = t[j];

            world_coords[j] = .{ 
                v[0] * scale[0] + offset[0], 
                v[1] * scale[1] + offset[1],
                v[2] * scale[2] + offset[2],
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
                (normalized_device_coords[j][1] + 1) * height / 2,
                normalized_device_coords[j][2]
            };
        }

        rasterize_triangle(screen_coords, canvas);
        i += 1;
    }
}

pub fn rasterize_triangle(coords: [3][3]f32, canvas: *draw.Canvas) void {
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
    const v0: [3]f32 = utils.v3_sub(f32, coords[1], coords[0]);
    const v1: [3]f32 = utils.v3_sub(f32, coords[2], coords[0]);
    const dot00: f32 = utils.v3_dot(f32, v0, v0);
    const dot01: f32 = utils.v3_dot(f32, v0, v1);
    const dot11: f32 = utils.v3_dot(f32, v1, v1);
    const det: f32 = dot00 * dot11 - dot01 * dot01;

    var py: f32 = ymin;
    while(py < ymax) : (py += 1) {
        var px: f32 = xmin;
        while(px < xmax) : (px += 1) {
            // Get barycentric coordinates
            const v2: [3]f32 = utils.v3_sub(f32, .{ px, py, 0 }, coords[0]);
            const dot20: f32 = utils.v3_dot(f32, v2, v0);
            const dot21: f32 = utils.v3_dot(f32, v2, v1);
            const v: f32 = (dot11 * dot20 - dot01 * dot21) / det;
            const w: f32 = (dot00 * dot21 - dot01 * dot20) / det;
            const u: f32 = 1 - v - w;
            if(u > 0 and v > 0 and w > 0) {
                const color: colors.Color = .{
                    .r = @intFromFloat(u * 250),
                    .g = @intFromFloat(v * 250),
                    .b = @intFromFloat(w * 250),
                    .a = 255
                };
                draw.draw_pixel(@intFromFloat(px), @intFromFloat(py), color, canvas);
            }
        }
    }
}

