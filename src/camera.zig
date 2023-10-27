const raster = @import("raster.zig");
const utils = @import("cm_utils.zig");

pub const Camera = struct {
    pos: @Vector(3, f32) = .{ 0, 0, 0 },
    pitch: f32 = 0,
    yaw: f32 = 0
};

pub fn forward(camera: *Camera) @Vector(3, f32) {
    const rotation_matrix: [4][4]f32 = raster.get_rotation_matrix_cam_2(camera.pitch, camera.yaw);
    const local_forward: @Vector(3, f32) = .{ 0, 0, 1 };
    const backward: @Vector(3, f32) = utils.multmat_44_3(f32, &rotation_matrix, &local_forward);
    return -backward;
}

// TODO: Faster presumably for this to be a cross product of the forward vector
pub fn right(camera: *Camera) @Vector(3, f32) {
    const rotation_matrix: [4][4]f32 = raster.get_rotation_matrix_cam_2(camera.pitch, camera.yaw);
    const local_right: @Vector(3, f32) = .{ 1, 0, 0 };
    return utils.multmat_44_3(f32, &rotation_matrix, &local_right);
}

pub fn rotate(camera: *Camera, pitch: f32, yaw: f32) void {
    camera.pitch += pitch;
    camera.yaw += yaw;
}
