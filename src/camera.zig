const Input = @import("input.zig").Input;
const get_rotation_matrix_cam= @import("transform.zig").get_rotation_matrix_cam;
const multmat_44_3 = @import("cm_math.zig").multmat_44_3;

pub const Camera = struct {
    pos: @Vector(3, f32) = .{ 0, 0, 0 },
    pitch: f32 = 0,
    yaw: f32 = 0,
};

pub fn control(camera: *Camera, input: *Input) void {
    const cam_speed_scalar: @Vector(3, f32) = @splat(0.1);
    const cam_rot_speed: f32 = 0.0025;

    if(input.cam_forward.held)
        camera.pos += forward(camera) * cam_speed_scalar;
    if(input.cam_back.held)
        camera.pos -= forward(camera) * cam_speed_scalar;
    if(input.cam_right.held)
        camera.pos += right(camera) * cam_speed_scalar;
    if(input.cam_left.held)
        camera.pos -= right(camera) * cam_speed_scalar;
    if(input.cam_raise.held)
        camera.pos += up(camera) * cam_speed_scalar;
    if(input.cam_lower.held)
        camera.pos -= up(camera) * cam_speed_scalar;

    rotate(camera, input.camera_delta_pitch * cam_rot_speed, -input.camera_delta_yaw * cam_rot_speed);
}

pub fn direction_relative_to_look(camera: *Camera, relative_direction: @Vector(3, f32)) @Vector(3, f32) {
    const rotation_matrix: [4][4]f32 = get_rotation_matrix_cam(camera.pitch, camera.yaw, true);
    return multmat_44_3(f32, &rotation_matrix, &relative_direction);
}

pub fn forward(camera: *Camera) @Vector(3, f32) {
    return direction_relative_to_look(camera, .{ 0, 0, -1 });
}

pub fn right(camera: *Camera) @Vector(3, f32) {
    return direction_relative_to_look(camera, .{ 1, 0, 0 });
}

pub fn up(camera: *Camera) @Vector(3, f32) {
    return direction_relative_to_look(camera, .{ 0, -1, 0 });
}

pub fn rotate(camera: *Camera, pitch: f32, yaw: f32) void {
    camera.pitch += pitch;
    camera.yaw += yaw;
}
