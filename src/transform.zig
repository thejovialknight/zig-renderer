const multmat_44_44 = @import("cm_math.zig").multmat_44_44;
const cross_v3 = @import("cm_math.zig").cross_v3;
const swap = @import("swap.zig").swap;

// Gets a transformation matrix to go from model to world space
pub fn get_world_transform(pos: @Vector(3, f32), rot: @Vector(4, f32), scale: @Vector(3, f32)) [4][4]f32 {
    const translation_matrix: [4][4]f32 = get_translation_matrix(pos);
    const rotation_matrix: [4][4]f32 = get_rotation_matrix(rot);
    const scale_matrix: [4][4]f32 = get_scale_matrix(scale);
    const tr_matrix = multmat_44_44(f32, &translation_matrix, &rotation_matrix);
    return multmat_44_44(f32, &scale_matrix, &tr_matrix);
}

// Gets a transformation matrix to go from world to view space
pub fn get_view_transform(pos: @Vector(3, f32), pitch: f32, yaw: f32) [4][4]f32 {
    const translation_matrix: [4][4]f32 = get_translation_matrix(pos);
    const rotation_matrix: [4][4]f32 = get_rotation_matrix_cam(pitch, yaw, false);
    return multmat_44_44(f32, &rotation_matrix, &translation_matrix);
}

// Gets a matrix representing a translation
pub fn get_translation_matrix(pos: @Vector(3, f32)) [4][4]f32 {
    return .{
        .{ 1, 0, 0, pos[0] },
        .{ 0, 1, 0, pos[1] },
        .{ 0, 0, 1, pos[2] },
        .{ 0, 0, 0, 1 },
    };
}

// Returns a matrix representing a rotation
pub fn get_rotation_matrix(rot: @Vector(4, f32)) [4][4]f32 {
    const cos_rx: f32 = @cos(rot[0]);
    const sin_rx: f32 = @sin(rot[0]);
    const cos_ry: f32 = @cos(rot[1]);
    const sin_ry: f32 = @sin(rot[1]);
    const cos_rz: f32 = @cos(rot[2]);
    const sin_rz: f32 = @sin(rot[2]);

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
    const yrxr_mat: [4][4]f32 = multmat_44_44(f32, &yr_mat, &xr_mat);
    return multmat_44_44(f32, &zr_mat, &yrxr_mat);
}

// Returns a rotation matrix using pitch and yaw
pub fn get_rotation_matrix_cam(pitch: f32, yaw: f32, inverse: bool) [4][4]f32 {
    var p: f32 = pitch;
    var y: f32 = yaw;
    if(inverse) {
        p *= -1;
        y *= -1;
    }

    const cos_rx: f32 = @cos(-p);
    const sin_rx: f32 = @sin(-p);
    const cos_ry: f32 = @cos(-y);
    const sin_ry: f32 = @sin(-y);

    var xr_mat: [4][4]f32 = .{
        .{ 1, 0, 0, 0 },
        .{ 0, cos_rx, -sin_rx, 0 },
        .{ 0, sin_rx, cos_rx, 0 },
        .{ 0, 0, 0, 1 }
    };
    var yr_mat: [4][4]f32 = .{
        .{ cos_ry, 0, sin_ry, 0 },
        .{ 0, 1, 0, 0 },
        .{ -sin_ry, 0, cos_ry, 0 },
        .{ 0, 0, 0, 1 }
    };

    if(inverse) swap([4][4]f32, &xr_mat, &yr_mat);

    return multmat_44_44(f32, &xr_mat, &yr_mat);
}

// Returns a matrix representing a scale
pub fn get_scale_matrix(scale: @Vector(3, f32)) [4][4]f32 {
    return .{
        .{ scale[0], 0, 0, 0 },
        .{ 0, scale[1], 0, 0 },
        .{ 0, 0, scale[2], 0 },
        .{ 0, 0, 0, 1 },
    };
}
