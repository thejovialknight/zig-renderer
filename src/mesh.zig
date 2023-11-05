pub const Mesh = struct {
    tris: [][3]@Vector(3, f32) = undefined,
    pos: @Vector(3, f32) = .{ 0, 0, 0 },
    rot: @Vector(4, f32) = .{ 0, 0, 0, 0 },
    scale: @Vector(3, f32) = .{ 1, -1, 1 }
};
