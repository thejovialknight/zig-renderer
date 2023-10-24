// TODO: Oh dear, we got the camera stuff working and everything,
// but now the rotations of the actual object are screwed up.
// 
// This means we fucked with something. What did we change about the
// pipeline, when everything on the camera side is unchanging?
//
// Haven't we only changed the method of camera movement? Confusing without
// more investigation.
//
// It could be the switcharoo of translation and rotation matrices in
// get_world_transform?
//
// UPDATE: Yep, it's the change. So, the camera rotation code is the thing that's wrong.
// Perhaps we will need another version of get_world_transform that works for the camera,
// this probably has to do with whatever the proper way of inverting a matrix is.
// See if the switch in get_world_transform for just the camera works properly.

const std = @import("std");
const draw = @import("draw.zig");
const sdl = @cImport(@cInclude("SDL.h"));
const raster = @import("raster.zig");
const utils = @import("cm_utils.zig");
const colors = @import("colors.zig");
const obj = @import("obj_loader.zig");
const mesh = @import("mesh.zig");
const World = @import("world.zig").World;
const cam = @import("camera.zig");

pub fn main() !void {
    _ = sdl.SDL_Init(sdl.SDL_INIT_VIDEO);
    defer sdl.SDL_Quit();

    var window: *sdl.SDL_Window = sdl.SDL_CreateWindow("SDL Test", sdl.SDL_WINDOWPOS_CENTERED, sdl.SDL_WINDOWPOS_CENTERED, draw.WIDTH, draw.HEIGHT, 0).?;
    defer sdl.SDL_DestroyWindow(window);

    var surface: *sdl.SDL_Surface = sdl.SDL_GetWindowSurface(window);

    var renderer: *sdl.SDL_Renderer = sdl.SDL_CreateRenderer(window, 0, sdl.SDL_RENDERER_PRESENTVSYNC).?;
    defer sdl.SDL_DestroyRenderer(renderer);

    var canvas: draw.Canvas = .{};
    draw.clear(&canvas, colors.black());

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    var allocator: std.mem.Allocator = arena.allocator(); 
    defer arena.deinit();

    const model: obj.Model = try obj.loadFile(allocator, "column.obj");
    var world: World = .{ .meshes = .{ try mesh.load_mesh(&model, allocator) } };
    world.meshes[0].pos = .{ 0, 0, -5 };

    const cam_speed_scalar: @Vector(3, f32) = @splat(0.1);
    const cam_rot_speed: f32 = 0.033;
    var w: bool = false;
    var a: bool = false;
    var s: bool = false;
    var d: bool = false;
    var up: bool = false;
    var left: bool = false;
    var down: bool = false;
    var right: bool = false;

    loop: while (true) {
        //world.meshes[0].rot[0] += 0.05;
        //world.meshes[0].rot[1] += 0.05;
        //world.meshes[0].rot[2] += 0.05;
        //world.meshes[0].pos[2] += 0.05;

        var event: sdl.SDL_Event = undefined;
        while (sdl.SDL_PollEvent(&event) != 0) {
            switch (event.type) {
                sdl.SDL_QUIT => break :loop,
                sdl.SDL_KEYDOWN => {
                    switch(event.key.keysym.scancode) {
                        sdl.SDL_SCANCODE_W => w = true,
                        sdl.SDL_SCANCODE_A => a = true,
                        sdl.SDL_SCANCODE_S => s = true,
                        sdl.SDL_SCANCODE_D => d = true,
                        sdl.SDL_SCANCODE_UP => up = true,
                        sdl.SDL_SCANCODE_LEFT => left = true,
                        sdl.SDL_SCANCODE_DOWN => down = true,
                        sdl.SDL_SCANCODE_RIGHT => right = true,
                        else => {}
                    }
                },
                sdl.SDL_KEYUP => {
                    switch(event.key.keysym.scancode) {
                        sdl.SDL_SCANCODE_W => w = false,
                        sdl.SDL_SCANCODE_A => a = false,
                        sdl.SDL_SCANCODE_S => s = false,
                        sdl.SDL_SCANCODE_D => d = false,
                        sdl.SDL_SCANCODE_UP => up = false,
                        sdl.SDL_SCANCODE_LEFT => left = false,
                        sdl.SDL_SCANCODE_DOWN => down = false,
                        sdl.SDL_SCANCODE_RIGHT => right = false,
                        else => {}
                    }
                },
                else => {},
            }
        }

        // if(w) world.camera.pos[2] += cam_speed;
        // if(a) world.camera.pos[0] -= cam_speed;
        // if(s) world.camera.pos[2] -= cam_speed;
        // if(d) world.camera.pos[0] += cam_speed;
        if(w) world.camera.pos += cam.forward(&world.camera) * cam_speed_scalar;
        if(a) world.camera.pos -= cam.right(&world.camera) * cam_speed_scalar;
        if(s) world.camera.pos -= cam.forward(&world.camera) * cam_speed_scalar;
        if(d) world.camera.pos += cam.right(&world.camera) * cam_speed_scalar;
        if(up) world.camera.pitch -= cam_rot_speed;
        if(left) world.camera.yaw += cam_rot_speed;
        if(down) world.camera.pitch += cam_rot_speed;
        if(right) world.camera.yaw -= cam_rot_speed;

        raster.render_world(&world, &canvas);
        draw.present(&canvas, window, surface);
    }
}
