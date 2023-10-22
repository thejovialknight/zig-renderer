// IMPORTS 

const std = @import("std");
const Allocator = std.mem.Allocator;

const zlm = @import("zlm/src/zlm-generic.zig").SpecializeOn(f32);

const obj = @import("obj_loader.zig");

// DATA

pub const Mesh = struct {
    tris: [][3]@Vector(3, f32) = undefined,
    pos: @Vector(3, f32) = .{ 0, 0, 0 },
    rot: @Vector(4, f32) = .{ 0, 0, 0, 0 },
    scale: @Vector(3, f32) = .{ 1, -1, 1 }
};

// FUNCTIONS

pub fn load_mesh(model: *const obj.Model, allocator: Allocator) !Mesh {
    const memory = try allocator.alloc([3]@Vector(3, f32), model.faces.len);
    var mesh: Mesh = .{ .tris = memory };

    for(0..model.faces.len) |i| {
        for(0..3) |j| {
            const v: zlm.Vec4 = model.positions[model.faces[i].vertices[j].position];
            mesh.tris[i][j] = .{ v.x, v.y, v.z };
        }
    }
    std.debug.print("{}\n", .{mesh.tris.len});
    std.debug.print("{}\n", .{model.faces.len});
    return mesh;
}
