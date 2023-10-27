// WE DID IT!!! 10/26/23
// TODO: Here's a broad overview agenda for what to do next.
// 1. Clean up current flow. Think about where each thing should go and trim fat
//
// 2. Refactor based on including data structures directly (maybe flat in file)
//    and separating structs from functions into their own files
//
// 3. Implement better triangle renderer. Perhaps doesn't need to be final,
//    but should at least stop the freezes if possible
//
// 4. Implement depth buffer
//
// 5. Try out alternate coordinate systems to try to gain more intuitive understanding.
//    This means seeing what changes require changes in other places. Make sure that
//    the above refactor takes into account how to make this change the easiest, which
//    will mean defining constants or something for repeated numbers, or something.
//
// 6. Speed up triangle rasterization enough to be performant. Hopefully no threading
//    required, as that would be nice to do later.
//
// 7. Implement texture maps
//
// 8. Take stock of performance and see if we can implement threading and other techniques
//    to get things to a playable game state of any kind.
//
// 9? At some point in here figure out whether aspect ratios are still fucking up
//    the projection.

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
    world.meshes[0].pos = .{ 0, 0, 0 };
    world.camera.pos = .{ 0, 0, 5 };

    var w: bool = false;
    var a: bool = false;
    var s: bool = false;
    var d: bool = false;
    var up: bool = false;
    var left: bool = false;
    var down: bool = false;
    var right: bool = false;

    _ = sdl.SDL_SetRelativeMouseMode(sdl.SDL_TRUE);

    loop: while (true) {
        //world.meshes[0].rot[0] += 0.05;
        //world.meshes[0].rot[1] += 0.05;
        //world.meshes[0].rot[2] += 0.05;
        //world.meshes[0].pos[2] += 0.05;

        var mouse_xrel: f32 = 0;
        var mouse_yrel: f32 = 0;
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
                sdl.SDL_MOUSEMOTION => {
                    mouse_xrel = @floatFromInt(event.motion.xrel);
                    mouse_yrel = @floatFromInt(event.motion.yrel);
                },
                else => {},
            }
        }

        const cam_speed_scalar: @Vector(3, f32) = @splat(0.1);
        const cam_rot_speed: f32 = 0.0025;

        //if(w) world.camera.pos[2] += cam_speed;
        //if(a) world.camera.pos[0] -= cam_speed;
        //if(s) world.camera.pos[2] -= cam_speed;
        //if(d) world.camera.pos[0] += cam_speed;
        if(w) world.camera.pos += cam.forward(&world.camera) * cam_speed_scalar;
        if(a) world.camera.pos -= cam.right(&world.camera) * cam_speed_scalar;
        if(s) world.camera.pos -= cam.forward(&world.camera) * cam_speed_scalar;
        if(d) world.camera.pos += cam.right(&world.camera) * cam_speed_scalar;

        //if(up) pitch -= cam_rot_speed;
        //if(left) yaw += cam_rot_speed;
        //if(down) pitch += cam_rot_speed;
        //if(right) yaw -= cam_rot_speed;
        cam.rotate(&world.camera, mouse_yrel * cam_rot_speed, -mouse_xrel * cam_rot_speed);

        raster.render_world(&world, &canvas);
        draw.present(&canvas, window, surface);
    }
}
