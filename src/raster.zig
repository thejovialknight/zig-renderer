// INCLUDES 
const std = @import("std");
const i_math = @import("zlm/src/zlm-generic.zig").SpecializeOn(i32);
const f_math = @import("zlm/src/zlm-generic.zig").SpecializeOn(f32);

const Mesh = @import("mesh.zig").Mesh;
const World = @import("world.zig").World;

const draw = @import("draw.zig");
const colors = @import("colors.zig");
const screen = @import("screen.zig");
const utils = @import("cm_utils.zig");    

// STRUCTS 
pub const Projection = enum {
    Perspective,
    Orthogonal
};

pub fn render_world(world: *World, canvas: *draw.Canvas) void {
    // TODO: Define matrix for camera
    //
    // From online documentation, it seems like the basic idea
    // is that we have a camera with a pos and rot, and we
    // calculate a world transform from it (meaning we will
    // have to factor out the world transformation calcs
    // here)
    //
    // The world transform is going to be the same calculations
    // as the ones used below, but using the inverse pos and rot
    //
    // When each mesh's world transform is calculated it will be
    // the calculated matrix below multiplied by the camera matrix
    // we calculate up here
    //
    // I'm thinking this function will be less
    // lines rather than more by the end, seeing as the transform
    // will be factored out
    //
    // A remaining question is how exactly to factor out the scale
    // transform. Should be easy to answer with just a few seconds
    // thought

    for(0..world.meshes_num) |mesh_index| {
        const mesh: *Mesh = &world.meshes[mesh_index];

        // Calculate view matrix
        const trans_mat: [4][4]f32 = .{
            .{ 1, 0, 0, mesh.pos[0] },
            .{ 0, 1, 0, mesh.pos[1] },
            .{ 0, 0, 1, mesh.pos[2] },
            .{ 0, 0, 0, 1 },
        };
        const scale_mat: [4][4]f32 = .{
            .{ mesh.scale[0], 0, 0, 0 },
            .{ 0, mesh.scale[1], 0, 0 },
            .{ 0, 0, mesh.scale[2], 0 },
            .{ 0, 0, 0, 1 },
        };

        const cos_rx: f32 = @cos(mesh.rot[0]);
        const sin_rx: f32 = @sin(mesh.rot[0]);
        const cos_ry: f32 = @cos(mesh.rot[1]);
        const sin_ry: f32 = @sin(mesh.rot[1]);
        const cos_rz: f32 = @cos(mesh.rot[2]);
        const sin_rz: f32 = @sin(mesh.rot[2]);

        const xr_mat: [4][4]f32 = .{
            .{ 1, 0, 0, 0 },
            .{ 0, cos_rx, -sin_rx, 0 },
            .{ 0, sin_rx, cos_rx, 0 },
            .{ 0, 0, 0, 1 }
        };
        const yr_mat: [4][4]f32 = .{
            .{ cos_ry, 0, sin_ry, 0 },
            .{ 0, 1, 0, 0 },
            .{ -sin_ry, 0, cos_ry, 0 },
            .{ 0, 0, 0, 1 }
        };
        const zr_mat: [4][4]f32 = .{
            .{ cos_rz, -sin_rz, 0, 0 },
            .{ sin_rz, cos_rz, 0, 0 },
            .{ 0, 0, 1, 0 },
            .{ 0, 0, 0, 1 }
        };
        const yrzr_mat: [4][4]f32 = utils.multmat_44_44(f32, &yr_mat, &zr_mat);
        const rot_mat: [4][4]f32 = utils.multmat_44_44(f32, &xr_mat, &yrzr_mat);
        const rottrans_mat: [4][4]f32 = utils.multmat_44_44(f32, &trans_mat, &rot_mat);
        const transform_mat: [4][4]f32 = utils.multmat_44_44(f32, &rottrans_mat, &scale_mat);

        // Render triangles
        for(mesh.tris) |tri_loc| { // triangle_local space
            var tri_world: [3]@Vector(3, f32) = undefined;
            var i: usize = 0;
            while(i < 3) : (i += 1) {
                tri_world[i] = utils.multmat_44_3(f32, &transform_mat, &tri_loc[i]);
            }
            render_triangle(&tri_world, canvas);
        }
    }
}

// FUNCTIONS 
pub fn render_triangle(triangle: *[3]@Vector(3, f32), canvas: *draw.Canvas) void {
    const projection: Projection = Projection.Perspective;
    const fov: f32 = 1.5; // radians
    const znear: f32 = 0.1;
    const zfar: f32 = 100;

    const width: f32 = @floatFromInt(canvas.width);
    const height: f32 = @floatFromInt(canvas.height);
    const aspect: f32 = height / width;
    const aspect_scalar: @Vector(3, f32) = @splat(aspect);

    var screen_coords: [3]@Vector(3, f32) = .{ .{ 0, 0, 0 }, .{ 0, 0, 0 }, .{ 0, 0, 0 } };
    for(0..3) |j| {
        const world_pos: @Vector(3, f32) = triangle[j];
        
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
            const clip: @Vector(4, f32) = utils.multmat_44_4(f32, &proj_mat, &world_pos_mat);
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

