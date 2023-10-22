const Mesh = @import("mesh.zig").Mesh;
const Camera = @import("camera.zig").Camera;

pub const World = struct {
    camera: Camera = .{},
    meshes: [1]Mesh = undefined,
    meshes_num: usize = 1
};
