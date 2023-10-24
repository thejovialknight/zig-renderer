const raster = @import("raster.zig");
const utils = @import("cm_utils.zig");

pub const Camera = struct {
    pos: @Vector(3, f32) = .{ 0, 0, 0 },
    pitch: f32 = 0,
    yaw: f32 = 0
};

// NOTE: Seeing as we don't actually need the camera position here, this
// can probably be factored out easily into a generic "forward" function
// that can be used for other objects?
pub fn forward(camera: *Camera) @Vector(3, f32) {
    // So we have a "world" definition of forward. It's [0,0,1] or perhaps the inverse of that.
    // We will need to calculate a rotation about the origin from this point based on the pitch
    // and yaw of the camera.
    //
    // To do this, we will use our world_transform function to transform a point at [0,0,1] with
    // a rotation about the local origin.
    //
    // This will mean that eventually this notion of getting a world transform will have to be
    // factored out of the rasterization code and into something else. That might be first
    // priority tomorrow.

    // TODO: the step from a transform to a position can maybe be factored out of
    // the raster function 
    const rotation: [4][4]f32 = raster.get_world_transform(
        @Vector(3, f32){ 0, 0, 1 },
        @Vector(4, f32){ camera.pitch, camera.yaw, 0, 1 },
        .{ 1, 1, 1 }
    );
    const local_forward: [3]f32 = .{ 0, 0, -1 };
    return utils.multmat_44_3(f32, &rotation, &local_forward);
}

// TODO: This is obviously a disgusting copypasta. 
pub fn right(camera: *Camera) @Vector(3, f32) {
    const rotation: [4][4]f32 = raster.get_world_transform(
        @Vector(3, f32){ 0, 0, 0 },
        @Vector(4, f32){ camera.pitch, camera.yaw, 0, 1 },
        .{ 1, 1, 1 }
    );
    const local_right: [3]f32 = .{ 1, 0, 0 };
    return utils.multmat_44_3(f32, &rotation, &local_right);
}
