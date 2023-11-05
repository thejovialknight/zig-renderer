const Platform = @import("platform.zig").Platform;
const Input = @import("input.zig").Input;
const Mesh = @import("mesh.zig").Mesh;
const Camera = @import("camera.zig").Camera;

const control_camera = @import("camera.zig").control;

pub const World = struct {
    camera: Camera = .{},
    meshes: [1]*Mesh = undefined,
    meshes_num: usize = 1
};

pub fn init(world: *World, platform: *Platform) void {
    world.meshes = .{ &platform.columns };
    world.meshes[0].pos = .{ 0, 0, 0 };
    world.camera.pos = .{ 0, 0, 5 };
}

pub fn update(world: *World, input: *Input) void {
    control_camera(&world.camera, input);
}
