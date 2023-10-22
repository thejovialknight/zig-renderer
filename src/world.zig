const mesh = @import("mesh.zig");

pub const World = struct {
    meshes: [1]mesh.Mesh = undefined,
    meshes_num: usize = 1
};
