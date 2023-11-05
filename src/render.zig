const std = @import("std");
const i_math = @import("zlm/src/zlm-generic.zig").SpecializeOn(i32);
const f_math = @import("zlm/src/zlm-generic.zig").SpecializeOn(f32);

const Mesh = @import("mesh.zig").Mesh;
const World = @import("world.zig").World;
const Canvas = @import("draw.zig").Canvas;

const multmat_44_44 = @import("cm_math.zig").multmat_44_44;
const multmat_44_3 = @import("cm_math.zig").multmat_44_3;
const multmat_44_4 = @import("cm_math.zig").multmat_44_4;
const cross_v3 = @import("cm_math.zig").cross_v3;
const get_view_transform = @import("transform.zig").get_view_transform;
const get_world_transform = @import("transform.zig").get_world_transform;
const rasterize_triangle = @import("raster.zig").rasterize_triangle;

const Projection = enum {
    Perspective,
    Orthogonal
};

pub fn render_world_to_canvas(world: *World, canvas: *Canvas) void {
    // Calculate view transform
    const view_transform: [4][4]f32 = get_view_transform(-world.camera.pos, world.camera.pitch, world.camera.yaw); 
    
    // Render meshes
    for(0..world.meshes_num) |mesh_index| {
        const mesh: *Mesh = world.meshes[mesh_index];
        
        // Calculate world transform
        const world_transform: [4][4]f32 = get_world_transform(mesh.pos, mesh.rot, mesh.scale);
        const mwv_transform: [4][4]f32 = multmat_44_44(f32, &view_transform, &world_transform);

        // Render triangles
        for(mesh.tris) |tri_loc| { // triangle_local space
            var tri_mwv: [3]@Vector(3, f32) = undefined;
            var i: usize = 0;
            while(i < 3) : (i += 1) {
                tri_mwv[i] = multmat_44_3(f32, &mwv_transform, &tri_loc[i]);
            }
            render_triangle(&tri_mwv, canvas);
        }
    }
}

pub fn render_triangle(triangle: *[3]@Vector(3, f32), canvas: *Canvas) void {
    const projection: Projection = Projection.Perspective;
    const fov: f32 = 2; // radians
    const znear: f32 = 0.1;
    const zfar: f32 = 100;

    const width: f32 = @floatFromInt(canvas.width);
    const height: f32 = @floatFromInt(canvas.height);
    const aspect: f32 = height / width;
    const aspect_scalar: @Vector(3, f32) = @splat(aspect);

    const proj_mat: [4]@Vector(4, f32) = .{
        .{ 1 / (@tan(fov / 2) * aspect), 0, 0, 0 },
        .{ 0, 1 / @tan(fov / 2), 0, 0 },
        .{ 0, 0, (zfar + znear) / (znear - zfar), -1 },
        .{ 0, 0, (znear * zfar * 2) / (znear - zfar), 0}
    };

    var screen_coords: [3]@Vector(3, f32) = .{ .{ 0, 0, 0 }, .{ 0, 0, 0 }, .{ 0, 0, 0 } };
    for(0..3) |j| {
        const world_pos: @Vector(3, f32) = triangle[j];
        
        var norm_device_pos: @Vector(3, f32) = .{ 0, 0, 0 };
        if(projection == Projection.Orthogonal) {   
            norm_device_pos = world_pos * aspect_scalar;
        }
        else {
            const world_pos_mat: @Vector(4, f32) = .{ world_pos[0], world_pos[1], world_pos[2], 1 };
            const clip: @Vector(4, f32) = multmat_44_4(f32, &proj_mat, &world_pos_mat);
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
